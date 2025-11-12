import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/detected_sms_transaction.dart';
import '../../utils/new_sms_parser.dart';

class NewNboxProvider extends ChangeNotifier {
  bool _isLoading = false;
  List<DetectedSmsTransaction> _pendingTransactions = [];
  List<DetectedSmsTransaction> _rejectedTransactions = [];
  Set<String> _approvedSmsIds = {};
  Set<String> _rejectedSmsIds = {};

  bool get isLoading => _isLoading;
  List<DetectedSmsTransaction> get pendingTransactions => List.unmodifiable(_pendingTransactions);
  List<DetectedSmsTransaction> get rejectedTransactions => List.unmodifiable(_rejectedTransactions);

  NewNboxProvider() {
    _loadProcessedIds();
  }

  Future<void> scanSmsInbox() async {
    _setLoading(true);

    if (!await _checkSmsPermission()) {
      _setLoading(false);
      return;
    }

    final smsQuery = SmsQuery();
    final messages = await smsQuery.querySms(kinds: [SmsQueryKind.inbox], count: 500);

    final freshPending = <DetectedSmsTransaction>[];
    final freshRejected = <DetectedSmsTransaction>[];

    for (final sms in messages) {
      if (sms.id == null) continue;
      final smsId = sms.id.toString();

      if (_approvedSmsIds.contains(smsId)) {
        continue;
      }

      final transaction = NewSmsParser.parse(
        smsId,
        sms.body ?? '',
        sms.sender ?? 'Unknown',
        sms.date ?? DateTime.now(),
      );

      if (transaction != null) {
        if (_rejectedSmsIds.contains(smsId)) {
          freshRejected.add(transaction);
        } else {
          freshPending.add(transaction);
        }
      }
    }

    _pendingTransactions = _applyDeDuplication(freshPending);
    _rejectedTransactions = freshRejected;

    _sortLists();
    _setLoading(false);
  }

  Future<void> markAsApproved(String smsId) async {
    _approvedSmsIds.add(smsId);
    if (_rejectedSmsIds.contains(smsId)) {
      _rejectedSmsIds.remove(smsId);
    }
    await _persistIds();
    await scanSmsInbox();
  }

  Future<void> rejectTransaction(String smsId) async {
    _rejectedSmsIds.add(smsId);
    await _persistIds();
    await scanSmsInbox();
  }

  Future<void> rejectTransactions(List<String> smsIds) async {
    _rejectedSmsIds.addAll(smsIds);
    await _persistIds();
    await scanSmsInbox();
  }

  Future<void> restoreTransaction(String smsId) async {
    _rejectedSmsIds.remove(smsId);
    await _persistIds();
    await scanSmsInbox();
  }

  List<DetectedSmsTransaction> _applyDeDuplication(List<DetectedSmsTransaction> list) {
    final cleanList = <DetectedSmsTransaction>[];
    final definitive = list.where((t) => t.isDefinitive).toList();
    final nonDefinitive = list.where((t) => !t.isDefinitive).toList();

    cleanList.addAll(definitive);

    for (final request in nonDefinitive) {
      final hasConfirmation = definitive.any((confirm) =>
          confirm.amount == request.amount &&
          confirm.date.difference(request.date).inMinutes.abs() < 15);

      if (!hasConfirmation) {
        cleanList.add(request);
      }
    }
    return cleanList;
  }

  void _sortLists() {
    _pendingTransactions.sort((a, b) => b.date.compareTo(a.date));
    _rejectedTransactions.sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> _persistIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('nbox_approved_ids', _approvedSmsIds.toList());
    await prefs.setStringList('nbox_rejected_ids', _rejectedSmsIds.toList());
  }

  Future<void> _loadProcessedIds() async {
    final prefs = await SharedPreferences.getInstance();
    _approvedSmsIds = (prefs.getStringList('nbox_approved_ids') ?? []).toSet();
    _rejectedSmsIds = (prefs.getStringList('nbox_rejected_ids') ?? []).toSet();
    await scanSmsInbox();
  }

  Future<bool> _checkSmsPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }
}
