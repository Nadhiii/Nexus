import 'package:flutter_test/flutter_test.dart';
import 'package:nexus/modules/debts/debts_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:nexus/core/providers/debt_provider.dart';
import 'package:nexus/core/models/debt.dart';

class MockDebtProvider extends ChangeNotifier implements DebtProvider {
  @override
  List<Debt> get debts => [
    Debt(
      id: "1",
      userId: "u1",
      name: "Test Debt",
      type: DebtType.personalLoan,
      originalAmount: 10000,
      currentBalance: 5000,
      monthlyEMI: 1000,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Debt(
      id: "2",
      userId: "u1",
      name: "Paid Debt",
      type: DebtType.creditCard,
      originalAmount: 5000,
      currentBalance: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];
  @override
  bool get isLoading => false;
  @override
  String? get error => null;
  @override
  double get totalDebt => 5000;
  
  // ignore: annotate_overrides
  Future<void> addDebt(Debt debt) async {}
  // ignore: annotate_overrides
  Future<void> updateDebt(Debt debt) async {}
  // ignore: annotate_overrides
  Future<void> deleteDebt(String debtId) async {}
  // ignore: annotate_overrides
  Future<void> clearAllData() async {}
  @override
  void clear() {}
  // ignore: annotate_overrides
  Future<void> restoreFromBackup(List<dynamic> data) async {}
  // ignore: annotate_overrides
  Future<void> payDebt(String debtId, double amount) async {}
}

void main() {
  testWidgets('Debts crash test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DebtProvider>(create: (_) => MockDebtProvider()),
        ],
        child: const MaterialApp(home: ModernDebtsScreen()),
      ),
    );
     await tester.pumpAndSettle();
  });
}
