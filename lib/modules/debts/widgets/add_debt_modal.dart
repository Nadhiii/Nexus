import 'package:flutter/material.dart';
import '../../../core/models/debt.dart';
import '../add_debt_screen.dart';

class AddDebtModal extends StatelessWidget {
  final Debt? debtToEdit;

  const AddDebtModal({Key? key, this.debtToEdit}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AddDebtScreen(debtToEdit: debtToEdit);
  }
}

// Helper function to show the add debt modal
Future<void> showAddDebtModal(BuildContext context, {Debt? debtToEdit}) {
  return Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AddDebtScreen(debtToEdit: debtToEdit),
      fullscreenDialog: true,
    ),
  );
}
