import 'dart:developer';
import 'package:flutter/material.dart';

/// Service for handling debt payment notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Check for upcoming EMI payments and show notifications
  Future<void> checkUpcomingPayments(List<dynamic> debts) async {
    final now = DateTime.now();
    final upcoming = <Map<String, dynamic>>[];

    for (final debt in debts) {
      if (debt.nextDueDate != null) {
        final daysUntilDue = debt.nextDueDate!.difference(now).inDays;

        // Notify for payments due in the next 3 days
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
      // In a real app, you would use a proper notification plugin like:
      // - flutter_local_notifications
      // - firebase_messaging
      // For now, we'll just log it
    }
  }

  /// Show in-app notification for due payments
  static void showInAppNotification(
    BuildContext context,
    String title,
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(message),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Get upcoming payments for display in widgets
  List<Map<String, dynamic>> getUpcomingPayments(List<dynamic> debts) {
    final now = DateTime.now();
    final upcoming = <Map<String, dynamic>>[];

    for (final debt in debts) {
      if (debt.nextDueDate != null) {
        final daysUntilDue = debt.nextDueDate!.difference(now).inDays;

        // Include payments due in the next 7 days
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

    // Sort by due date (closest first)
    upcoming.sort((a, b) => a['daysUntilDue'].compareTo(b['daysUntilDue']));

    return upcoming;
  }

  /// Format due date message for display
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
