import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/detected_transaction.dart';
import '../models/transaction.dart' as app_models;
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import '../theme/app_spacing.dart';

class NBoxConfirmationDialog extends StatefulWidget {
  final DetectedTransaction detectedTransaction;

  const NBoxConfirmationDialog({super.key, required this.detectedTransaction});

  @override
  State<NBoxConfirmationDialog> createState() => _NBoxConfirmationDialogState();
}

class _NBoxConfirmationDialogState extends State<NBoxConfirmationDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late app_models.TransactionType _transactionType;
  String? _selectedAccountId;
  String? _selectedCategory;

  final List<String> _categories = [
    'Food & Dining', 'Transportation', 'Shopping', 'Bills & Utilities', 'Entertainment',
    'Healthcare', 'Cash Withdrawal', 'Salary', 'Other Income', 'Other Expense',
  ];

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.detectedTransaction.title);
    _transactionType = widget.detectedTransaction.type == 'income' ? app_models.TransactionType.income : app_models.TransactionType.expense;
    _selectedCategory = widget.detectedTransaction.category;
    final accountProvider = context.read<AccountProvider>();
    if (accountProvider.accounts.isNotEmpty) {
      _selectedAccountId = accountProvider.accounts.first.id;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _approve() async {
    if (!_formKey.currentState!.validate()) return;

    final transactionProvider = context.read<TransactionProvider>();
    final success = await transactionProvider.addTransactionFromDetected(
      widget.detectedTransaction,
      accountId: _selectedAccountId!,
      category: _selectedCategory!,
      type: _transactionType,
    );

    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Review Transaction'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Amount: ₹${widget.detectedTransaction.amount.toStringAsFixed(2)}'),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) => value!.isEmpty ? 'Cannot be empty' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<app_models.TransactionType>(
                value: _transactionType,
                items: app_models.TransactionType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.name))).toList(),
                onChanged: (value) => setState(() => _transactionType = value!),
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: AppSpacing.lg),
              Consumer<AccountProvider>(
                builder: (context, provider, _) => DropdownButtonFormField<String>(
                  value: _selectedAccountId,
                  items: provider.accounts.map((acc) => DropdownMenuItem(value: acc.id, child: Text(acc.name))).toList(),
                  onChanged: (value) => setState(() => _selectedAccountId = value!),
                  decoration: const InputDecoration(labelText: 'Account'),
                  validator: (value) => value == null ? 'Please select an account' : null,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value!),
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (value) => value == null ? 'Please select a category' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        ElevatedButton(onPressed: _approve, child: const Text('Approve')),
      ],
    );
  }
}
