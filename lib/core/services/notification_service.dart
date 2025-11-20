import 'dart:developer';
import 'package:flutter/material.dart';
import '../widgets/top_snackbar.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> checkUpcomingPayments(List<dynamic> debts) async {
    final now = DateTime.now();
    final upcoming = <Map<String, dynamic>>[];

    for (final debt in debts) {
      if (debt.nextDueDate != null) {
        final daysUntilDue = debt.nextDueDate!.difference(now).inDays;

        if (daysUntilDue >= 0 && daysUntilDue <= 3) {
          upcoming.add({'debt': debt, 'daysUntilDue': daysUntilDue});
        }
      }
    }

    if (upcoming.isNotEmpty) {
      _showUpcomingPaymentNotifications(upcoming);
    }
  }

  void _showUpcomingPaymentNotifications(List<Map<String, dynamic>> upcoming) {
    for (final item in upcoming) {
      final debt = item['debt'];
      final days = item['daysUntilDue'] as int;

      String message;
      if (days == 0) {
        message =
            'EMI payment for ${debt.name} is due today! Amount: ₹${debt.monthlyEMI.toStringAsFixed(0)}';
      } else if (days == 1) {
        message =
            'EMI payment for ${debt.name} is due tomorrow! Amount: ₹${debt.monthlyEMI.toStringAsFixed(0)}';
      } else {
        message =
            'EMI payment for ${debt.name} is due in $days days! Amount: ₹${debt.monthlyEMI.toStringAsFixed(0)}';
      }

      log('Notification: $message');
    }
  }

  static void showInAppNotification(
    BuildContext context,
    String title,
    String message,
  ) {
    showTopSnackBar(context, '$title: $message', isError: true);
  }

  List<Map<String, dynamic>> getUpcomingPayments(List<dynamic> debts) {
    final now = DateTime.now();
    final upcoming = <Map<String, dynamic>>[];

    for (final debt in debts) {
      if (debt.nextDueDate != null) {
        final daysUntilDue = debt.nextDueDate!.difference(now).inDays;

        if (daysUntilDue >= 0 && daysUntilDue <= 7) {
          upcoming.add({
            'debt': debt,
            'daysUntilDue': daysUntilDue,
            'amount': debt.monthlyEMI,
            'dueDate': debt.nextDueDate,
          });
        }
      }
    }

    upcoming.sort((a, b) => a['daysUntilDue'].compareTo(b['daysUntilDue']));

    return upcoming;
  }

  static String formatDueDateMessage(int daysUntilDue) {
    if (daysUntilDue == 0) {
      return 'Due Today';
    } else if (daysUntilDue == 1) {
      return 'Due Tomorrow';
    } else {
      return 'Due in $daysUntilDue days';
    }
  }
}
