import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a single "you owe this person X" entry, used for
/// generating payment suggestions.
class DebtEntry {
  final String personId;
  final String personName;
  final double amount;

  DebtEntry({required this.personId, required this.personName, required this.amount});
}

/// A suggested payment to make towards clearing a debt.
class PaymentSuggestion {
  final String personId;
  final String personName;
  final double suggestedAmount;
  final double remainingDebtAfter;
  final bool clearsDebt;

  PaymentSuggestion({
    required this.personId,
    required this.personName,
    required this.suggestedAmount,
    required this.remainingDebtAfter,
    required this.clearsDebt,
  });
}

/// Handles local notifications and "how should I use my available cash
/// to pay back what I owe" suggestions.
class DebtReminderService {
  DebtReminderService._();
  static final DebtReminderService instance = DebtReminderService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _prefsKeyPrefix = 'debt_reminder_last_notified_';
  static const String _prefsThresholdKey = 'debt_reminder_threshold';
  static const double _defaultThreshold = 500.0;

  bool _initialized = false;

  /// Call once at app startup (e.g. in main.dart) before using notifications.
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings: settings);
    _initialized = true;
  }

  /// Get the user-configured threshold (default Γé╣500). A reminder for a
  /// given person only fires once their owed amount crosses this value
  /// AND has increased since the last time we notified about them.
  Future<double> getThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_prefsThresholdKey) ?? _defaultThreshold;
  }

  Future<void> setThreshold(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefsThresholdKey, value);
  }

  Future<double> _getLastNotified(String personId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('$_prefsKeyPrefix$personId') ?? 0.0;
  }

  Future<void> _setLastNotified(String personId, double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('$_prefsKeyPrefix$personId', amount);
  }

  /// Clear the stored "last notified" amount for a person, e.g. once a
  /// debt is fully settled, so the next time they owe money it notifies
  /// fresh from zero.
  Future<void> clearLastNotified(String personId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefsKeyPrefix$personId');
  }

  /// Greedily allocate [availableBalance] across [debts] (largest debts
  /// first) and return suggestions for how much to pay each person.
  ///
  /// Example: balance = 3000, debts = [Varun: 1000, Tarun: 500]
  /// -> Varun gets 1000 (clears), Tarun gets 500 (clears), 1500 left over.
  ///
  /// Example: balance = 3000, debts = [Varun: 3000]
  /// -> Varun gets 3000 (clears).
  List<PaymentSuggestion> suggestPayments(
    double availableBalance,
    List<DebtEntry> debts,
  ) {
    if (availableBalance <= 0 || debts.isEmpty) return [];

    final sorted = [...debts]..sort((a, b) => b.amount.compareTo(a.amount));

    double remaining = availableBalance;
    final suggestions = <PaymentSuggestion>[];

    for (final debt in sorted) {
      if (remaining <= 0) break;
      if (debt.amount <= 0) continue;

      final payment = debt.amount <= remaining ? debt.amount : remaining;
      remaining -= payment;

      suggestions.add(
        PaymentSuggestion(
          personId: debt.personId,
          personName: debt.personName,
          suggestedAmount: payment,
          remainingDebtAfter: debt.amount - payment,
          clearsDebt: payment >= debt.amount,
        ),
      );
    }

    return suggestions;
  }

  /// Build a friendly notification body from payment suggestions.
  ///
  /// e.g. "Hey, I see you have Γé╣3,000. Consider paying Varun Γé╣1,000 and
  /// Tarun Γé╣500 to catch up on what you owe them."
  ///
  /// e.g. "Hey, I see you have Γé╣3,000. Consider paying Varun Γé╣3,000 ΓÇö that
  /// clears what you owe him."
  String buildSuggestionMessage(
    double availableBalance,
    List<PaymentSuggestion> suggestions,
  ) {
    if (suggestions.isEmpty) return '';

    final balanceStr = 'Γé╣${availableBalance.toStringAsFixed(0)}';

    if (suggestions.length == 1) {
      final s = suggestions.first;
      final amountStr = 'Γé╣${s.suggestedAmount.toStringAsFixed(0)}';
      if (s.clearsDebt) {
        return 'Hey, I see you have $balanceStr. Consider paying '
            '${s.personName} $amountStr ΓÇö that clears what you owe them!';
      } else {
        return 'Hey, I see you have $balanceStr. Consider paying '
            '${s.personName} $amountStr to chip away at what you owe them.';
      }
    }

    // Multiple people
    final parts = <String>[];
    for (final s in suggestions) {
      final amountStr = 'Γé╣${s.suggestedAmount.toStringAsFixed(0)}';
      parts.add('${s.personName} $amountStr');
    }

    final allClear = suggestions.every((s) => s.clearsDebt);
    final joined = _joinWithAnd(parts);

    if (allClear) {
      return 'Hey, I see you have $balanceStr. Consider paying $joined to '
          'clear what you owe them!';
    }
    return 'Hey, I see you have $balanceStr. Consider paying $joined to '
        'catch up on what you owe them.';
  }

  String _joinWithAnd(List<String> parts) {
    if (parts.length == 1) return parts.first;
    if (parts.length == 2) return '${parts[0]} and ${parts[1]}';
    return '${parts.sublist(0, parts.length - 1).join(', ')}, '
        'and ${parts.last}';
  }

  /// Checks each debt against the stored "last notified" amount and the
  /// threshold. Returns the list of debts that should trigger a reminder
  /// (i.e. crossed the threshold and increased since last notification),
  /// and updates the stored "last notified" amounts for those debts.
  Future<List<DebtEntry>> getDebtsToRemind(List<DebtEntry> currentDebts) async {
    final threshold = await getThreshold();
    final toRemind = <DebtEntry>[];

    for (final debt in currentDebts) {
      if (debt.amount <= 0) {
        // Debt cleared - reset tracking so future debts notify fresh.
        await clearLastNotified(debt.personId);
        continue;
      }

      final lastNotified = await _getLastNotified(debt.personId);

      if (debt.amount >= threshold && debt.amount > lastNotified) {
        toRemind.add(debt);
        await _setLastNotified(debt.personId, debt.amount);
      }
    }

    return toRemind;
  }

  /// Show a simple "you owe X" reminder notification (no balance context).
  Future<void> showDebtReminder(List<DebtEntry> debts) async {
    if (debts.isEmpty) return;
    await initialize();

    String body;
    if (debts.length == 1) {
      final d = debts.first;
      body = 'You owe ${d.personName} Γé╣${d.amount.toStringAsFixed(0)}. '
          'Consider settling up soon.';
    } else {
      final parts = debts
          .map((d) => '${d.personName} Γé╣${d.amount.toStringAsFixed(0)}')
          .toList();
      body = 'You owe ${_joinWithAnd(parts)}. Consider settling up soon.';
    }

    await _notifications.show(
      id: 1001,
      title: 'Outstanding balances',
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'debt_reminders',
          'Debt Reminders',
          channelDescription: 'Reminders about money you owe to others',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Show a "you have Γé╣X, consider paying..." notification with concrete
  /// payment suggestions based on available balance.
  Future<void> showPaymentSuggestion(
    double availableBalance,
    List<PaymentSuggestion> suggestions,
  ) async {
    if (suggestions.isEmpty) return;
    await initialize();

    final body = buildSuggestionMessage(availableBalance, suggestions);
    if (body.isEmpty) return;

    await _notifications.show(
      id: 1002,
      title: 'You can settle up',
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'debt_payment_suggestions',
          'Payment Suggestions',
          channelDescription:
              'Suggestions for paying back people based on your balance',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
