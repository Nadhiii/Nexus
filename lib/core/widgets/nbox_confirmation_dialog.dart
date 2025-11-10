import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart' as app_models;
import '../../models/detected_transaction.dart';
import '../services/firestore_service.dart';

class NBoxConfirmationDialog extends StatefulWidget {
  final DetectedTransaction detectedTransaction;

  const NBoxConfirmationDialog({super.key, required this.detectedTransaction});

  @override
  State<NBoxConfirmationDialog> createState() => _NBoxConfirmationDialogState();
}

class _NBoxConfirmationDialogState extends State<NBoxConfirmationDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  String? _selectedAccountId;
  String? _selectedCategory;
  String _transactionType = 'expense';
  bool _isLoading = false;
  List<dynamic> _accounts = [];

  final List<String> _categories = [
    'Food & Dining',
    'Transportation',
    'Shopping',
    'Bills & Utilities',
    'Entertainment',
    'Healthcare',
    'Cash Withdrawal',
    'Salary',
    'Other Income',
    'Other Expense',
  ];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.detectedTransaction.amount.toStringAsFixed(2),
    );
    _descriptionController = TextEditingController(
      text: widget.detectedTransaction.subtitle,
    );
    _selectedDate = widget.detectedTransaction.date;
    _selectedCategory = widget.detectedTransaction.category;

    // Determine transaction type from title
    if (widget.detectedTransaction.title.toLowerCase().contains('received') ||
        widget.detectedTransaction.title.toLowerCase().contains('credit')) {
      _transactionType = 'income';
    }

    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final accounts = await FirestoreService.getAccounts();
    setState(() {
      _accounts = accounts;
      if (_accounts.isNotEmpty && _selectedAccountId == null) {
        _selectedAccountId = _accounts.first.id;
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an account')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final amount = double.parse(_amountController.text);

      final now = DateTime.now();
      final transaction = app_models.Transaction(
        id: '', // Firestore will generate
        userId: userId,
        accountId: _selectedAccountId!,
        amount: amount,
        type: _transactionType == 'income'
            ? app_models.TransactionType.income
            : app_models.TransactionType.expense,
        categoryId: _selectedCategory,
        description: _descriptionController.text,
        date: _selectedDate,
        createdAt: now,
        updatedAt: now,
        metadata: {
          'source': 'nbox',
          'smsBody': widget.detectedTransaction.smsBody,
        },
      );

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('transactions')
          .add(transaction.toMap());

      // Update account balance
      final accountDoc = await FirebaseFirestore.instance
          .collection('accounts')
          .doc(_selectedAccountId)
          .get();

      if (accountDoc.exists) {
        final currentBalance = (accountDoc.data()?['balance'] ?? 0.0)
            .toDouble();
        final newBalance = _transactionType == 'income'
            ? currentBalance + amount
            : currentBalance - amount;

        await FirebaseFirestore.instance
            .collection('accounts')
            .doc(_selectedAccountId)
            .update({'balance': newBalance});
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating transaction: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      _transactionType == 'income'
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      color: _transactionType == 'income'
                          ? Colors.green
                          : Colors.red,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Confirm Transaction',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            widget.detectedTransaction.title,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // SMS Body (expandable)
                ExpansionTile(
                  title: const Text('View Full SMS'),
                  tilePadding: EdgeInsets.zero,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.detectedTransaction.smsBody,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Transaction Type
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'expense',
                      label: Text('Expense'),
                      icon: Icon(Icons.arrow_upward),
                    ),
                    ButtonSegment(
                      value: 'income',
                      label: Text('Income'),
                      icon: Icon(Icons.arrow_downward),
                    ),
                  ],
                  selected: {_transactionType},
                  onSelectionChanged: (Set<String> selection) {
                    setState(() => _transactionType = selection.first);
                  },
                ),
                const SizedBox(height: 16),

                // Amount
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '₹',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Account Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedAccountId,
                  decoration: const InputDecoration(
                    labelText: 'Account',
                    border: OutlineInputBorder(),
                  ),
                  items: _accounts.map<DropdownMenuItem<String>>((account) {
                    return DropdownMenuItem<String>(
                      value: account.id,
                      child: Text(account.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedAccountId = value);
                  },
                  validator: (value) {
                    if (value == null) return 'Please select account';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value);
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date Picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Date'),
                  subtitle: Text(
                    DateFormat('MMM dd, yyyy').format(_selectedDate),
                  ),
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      setState(() => _selectedDate = pickedDate);
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _saveTransaction,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        _isLoading ? 'Saving...' : 'Create Transaction',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
