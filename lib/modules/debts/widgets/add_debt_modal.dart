import 'package:flutter/material.dart';
import '../../../core/models/debt.dart';
import '../modern_add_debt_screen.dart';

class AddDebtModal extends StatelessWidget {
  final Debt? debtToEdit;

  const AddDebtModal({super.key, this.debtToEdit});

  @override
  Widget build(BuildContext context) {
    return ModernAddDebtScreen(debtToEdit: debtToEdit);
  }
}

// Helper function to show the add debt modal
Future<void> showAddDebtModal(BuildContext context, {Debt? debtToEdit}) {
  return Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ModernAddDebtScreen(debtToEdit: debtToEdit),
      fullscreenDialog: true,
    ),
  );
}
