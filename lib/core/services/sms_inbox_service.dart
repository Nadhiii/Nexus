import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import '../../utils/sms_parser.dart';
import '../../models/detected_transaction.dart';

class SmsInboxService {
  final SmsQuery _query = SmsQuery();

  Future<List<SmsMessage>> getRecentMessages({int days = 7}) async {
    final now = DateTime.now();
    final since = now.subtract(Duration(days: days));
    final messages = await _query.querySms(
      kinds: [SmsQueryKind.inbox],
      count: 200, // Look at a larger batch of recent messages
    );
    return messages.where((m) => m.date != null && m.date!.isAfter(since)).toList();
  }

  Future<List<DetectedTransaction>> detectTransactions({int days = 14}) async {
    final messages = await getRecentMessages(days: days);
    final detectedTransactions = <DetectedTransaction>[];

    for (final message in messages) {
      if (message.body == null) continue;

      final transaction = SmsParser.parse(message.body!, message.address, message.date ?? DateTime.now());

      if (transaction != null) {
        detectedTransactions.add(transaction);
      }
    }

    return detectedTransactions;
  }
}
