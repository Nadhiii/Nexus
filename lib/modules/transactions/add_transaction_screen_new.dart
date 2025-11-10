import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/models/transaction.dart';
import '../../core/models/account.dart';
import '../../core/providers/transaction_provider.dart';
import '../../core/providers/account_provider.dart';
import '../../core/theme/app_theme.dart';

class AddTransactionScreenNew extends StatefulWidget {
  final String? accountId;
  final TransactionType? initialType;
  final Transaction? transactionToEdit;
  final bool isModal;
  final VoidCallback? onDismiss;

  const AddTransactionScreenNew({
    super.key,
    this.accountId,
    this.initialType,
    this.transactionToEdit,
    this.isModal = false,
    this.onDismiss,
  });

  @override
  State<AddTransactionScreenNew> createState() =>
      _AddTransactionScreenNewState();
}

class _AddTransactionScreenNewState extends State<AddTransactionScreenNew> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  String? _selectedAccountId;
  String? _selectedToAccountId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final List<String> _commonCategories = [
    'Food & Dining',
    'Shopping',
    'Transportation',
    'Entertainment',
    'Bills & Utilities',
    'Healthcare',
    'Education',
    'Travel',
    'Investment',
    'Salary',
    'Bonus',
    'Gift',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? TransactionType.expense;
    _selectedAccountId = widget.accountId;

    if (widget.transactionToEdit != null) {
      _initializeForEditing();
    }
  }

  void _initializeForEditing() {
    final transaction = widget.transactionToEdit!;
    _amountController.text = transaction.amount.toString();
    _descriptionController.text = transaction.description ?? '';
    _categoryController.text = transaction.categoryId ?? '';
    _selectedType = transaction.type;
    _selectedAccountId = transaction.accountId;
    _selectedToAccountId = transaction.toAccountId;
    _selectedDate = transaction.date;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.transactionToEdit == null
              ? 'Add Transaction'
              : 'Edit Transaction',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        leading: Container(
          margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: Material(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                if (widget.isModal && widget.onDismiss != null) {
                  widget.onDismiss!();
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                child: const Icon(
                  Icons.close,
                  color: AppTheme.iosBluePrimary,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Consumer2<AccountProvider, TransactionProvider>(
        builder: (context, accountProvider, transactionProvider, child) {
          if (accountProvider.accounts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 64),
                  SizedBox(height: 16),
                  Text('No accounts available'),
                  Text('Please create an account first'),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transaction Type Selector
                  _buildTransactionTypeSelector(),
                  const SizedBox(height: 32),

                  // Amount Input
                  _buildAmountInput(),
                  const SizedBox(height: 20),

                  // Description Input
                  _buildDescriptionInput(),
                  const SizedBox(height: 20),

                  // Category Input
                  _buildCategoryInput(),
                  const SizedBox(height: 20),

                  // Account Selection
                  _buildAccountSelection(accountProvider.accounts),
                  const SizedBox(height: 20),

                  // To Account Selection (for transfers)
                  if (_selectedType == TransactionType.transfer) ...[
                    _buildToAccountSelection(accountProvider.accounts),
                    const SizedBox(height: 20),
                  ],

                  // Date Selection
                  _buildDateSelection(),
                  const SizedBox(height: 40),

                  // Save Button
                  _buildSaveButton(transactionProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transaction Type',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTypeButton(
                'Income',
                Icons.trending_up,
                Colors.green,
                TransactionType.income,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeButton(
                'Expense',
                Icons.trending_down,
                Colors.red,
                TransactionType.expense,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeButton(
                'Transfer',
                Icons.swap_horiz,
                Colors.blue,
                TransactionType.transfer,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeButton(
    String label,
    IconData icon,
    Color color,
    TransactionType type,
  ) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          if (type != TransactionType.transfer) {
            _selectedToAccountId = null;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: isSelected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    final color = _selectedType == TransactionType.income
        ? Colors.green
        : _selectedType == TransactionType.expense
        ? Colors.red
        : Colors.blue;

    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
      decoration: InputDecoration(
        labelText: 'Amount',
        prefixIcon: Icon(Icons.currency_rupee, color: color),
        prefixText: '₹ ',
        prefixStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: color,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter an amount';
        }
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return 'Please enter a valid amount';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionInput() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Description',
        hintText: 'What was this transaction for?',
        prefixIcon: const Icon(Icons.description),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a description';
        }
        return null;
      },
    );
  }

  Widget _buildCategoryInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _categoryController,
          decoration: InputDecoration(
            labelText: 'Category',
            hintText: 'Select or enter a category',
            prefixIcon: const Icon(Icons.category),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _commonCategories.map((category) {
            return FilterChip(
              label: Text(category),
              selected: _categoryController.text == category,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _categoryController.text = category;
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAccountSelection(List<Account> accounts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'From Account',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedAccountId,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.account_balance_wallet),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: accounts.map((account) {
            return DropdownMenuItem(
              value: account.id,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: account.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      '${account.name} (₹${account.balance.toStringAsFixed(2)})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        height: 1.0,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedAccountId = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Please select an account';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildToAccountSelection(List<Account> accounts) {
    final availableAccounts = accounts
        .where((a) => a.id != _selectedAccountId)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'To Account',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedToAccountId,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.account_balance),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: availableAccounts.map((account) {
            return DropdownMenuItem(
              value: account.id,
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: account.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          account.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '₹${account.balance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedToAccountId = value;
            });
          },
          validator: (value) {
            if (_selectedType == TransactionType.transfer && value == null) {
              return 'Please select a destination account';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 12),
                Text(
                  DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate),
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(TransactionProvider transactionProvider) {
    final color = _selectedType == TransactionType.income
        ? Colors.green
        : _selectedType == TransactionType.expense
        ? Colors.red
        : Colors.blue;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : () => _saveTransaction(transactionProvider),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                widget.transactionToEdit == null
                    ? 'Add Transaction'
                    : 'Update Transaction',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _saveTransaction(TransactionProvider transactionProvider) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final transaction = Transaction(
        id: widget.transactionToEdit?.id ?? '',
        type: _selectedType,
        amount: double.parse(_amountController.text),
        description: _descriptionController.text.trim(),
        categoryId: _categoryController.text.trim().isNotEmpty
            ? _categoryController.text.trim()
            : null,
        accountId: _selectedAccountId!,
        toAccountId: _selectedToAccountId,
        date: _selectedDate,
        createdAt: widget.transactionToEdit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool success;
      if (widget.transactionToEdit == null) {
        success = await transactionProvider.addTransaction(transaction);
      } else {
        success = await transactionProvider.updateTransaction(
          widget.transactionToEdit!,
          transaction,
        );
      }

      if (success && mounted) {
        if (widget.isModal && widget.onDismiss != null) {
          widget.onDismiss!();
        } else {
          Navigator.of(context).pop();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.transactionToEdit == null
                  ? 'Transaction added successfully!'
                  : 'Transaction updated successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(transactionProvider.error ?? 'An error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
