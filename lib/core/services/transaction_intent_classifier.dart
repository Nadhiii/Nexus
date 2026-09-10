enum TransactionIntent {
  fuel, emiPayment, subscriptionPayment, investmentSip, salary, transfer,
  food, shopping, entertainment, medical, general,
}

extension TransactionIntentX on TransactionIntent {
  String get icon => switch (this) {
        TransactionIntent.fuel => '⛽',
        TransactionIntent.emiPayment => '🏦',
        TransactionIntent.subscriptionPayment => '🔁',
        TransactionIntent.investmentSip => '📈',
        TransactionIntent.salary => '💰',
        TransactionIntent.transfer => '↔️',
        TransactionIntent.food => '🍽️',
        TransactionIntent.shopping => '🛍️',
        TransactionIntent.entertainment => '🎬',
        TransactionIntent.medical => '⚕️',
        TransactionIntent.general => '🧾',
      };

  String get label => switch (this) {
        TransactionIntent.fuel => 'Fuel',
        TransactionIntent.emiPayment => 'EMI Payment',
        TransactionIntent.subscriptionPayment => 'Subscription',
        TransactionIntent.investmentSip => 'Investment / SIP',
        TransactionIntent.salary => 'Salary',
        TransactionIntent.transfer => 'Transfer',
        TransactionIntent.food => 'Food & Dining',
        TransactionIntent.shopping => 'Shopping',
        TransactionIntent.entertainment => 'Entertainment',
        TransactionIntent.medical => 'Medical',
        TransactionIntent.general => 'General Expense',
      };

    bool get requiresExtraInput =>
      this == TransactionIntent.fuel ||
      this == TransactionIntent.emiPayment ||
      this == TransactionIntent.subscriptionPayment ||
      this == TransactionIntent.investmentSip;

  bool get hasSideEffects => requiresExtraInput;
}
