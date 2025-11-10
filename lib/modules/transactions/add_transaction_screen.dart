import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/translucent_app_bar.dart';
import '../../core/providers/transaction_provider.dart';
import '../../core/models/transaction.dart';

class AddTransactionScreen extends StatefulWidget {
  final String? selectedAccountId;

  const AddTransactionScreen({super.key, this.selectedAccountId});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  // Type-specific controllers
  final _interestRateController = TextEditingController(); // For Debt
  final _lenderController = TextEditingController(); // For Debt
  final _dueDateController = TextEditingController(); // For Debt
  final _sourceDueDateController =
      TextEditingController(); // For Income (salary date, etc.)
  final _providerController = TextEditingController(); // For Subscription
  final _nextBillingController = TextEditingController(); // For Subscription
  final _fromAccountController = TextEditingController(); // For Transfer
  final _toAccountController = TextEditingController(); // For Transfer
  final _portfolioController = TextEditingController(); // For Investment
  final _unitsController = TextEditingController(); // For Investment

  String _selectedType = 'Expense';
  String _selectedCategory = 'Food & Dining';
  String _selectedAccount = 'Cash';
  String _customCategory = '';
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;
  String _recurringFrequency = 'Monthly';

  final List<String> _transactionTypes = [
    'Expense',
    'Income',
    'Debt',
    'Subscription',
    'Investment',
    'Transfer',
  ];

  final Map<String, List<String>> _categoriesByType = {
    'Expense': [
      'Food & Dining',
      'Transportation',
      'Shopping',
      'Entertainment',
      'Bills & Utilities',
      'Healthcare',
      'Education',
      'Personal Care',
      'Travel',
      'Gifts & Donations',
      'Other Expenses',
      'Custom Category...',
    ],
    'Income': [
      'Salary',
      'Freelance',
      'Business',
      'Investment Returns',
      'Rental Income',
      'Side Hustle',
      'Gifts Received',
      'Other Income',
      'Custom Category...',
    ],
    'Debt': [
      'Credit Card',
      'Personal Loan',
      'Home Loan',
      'Car Loan',
      'Education Loan',
      'Business Loan',
      'Other Debt',
      'Custom Category...',
    ],
    'Subscription': [
      'Streaming Services',
      'Software & Apps',
      'Gym & Fitness',
      'News & Magazines',
      'Cloud Storage',
      'Music & Audio',
      'Gaming',
      'Other Subscriptions',
      'Custom Category...',
    ],
    'Investment': [
      'Mutual Funds',
      'Stocks',
      'Fixed Deposits',
      'Gold',
      'Real Estate',
      'Crypto',
      'Other Investments',
      'Custom Category...',
    ],
    'Transfer': [
      'Between Accounts',
      'To Family',
      'To Friends',
      'Other Transfers',
      'Custom Category...',
    ],
  };

  final List<String> _accounts = [
    'Cash',
    'Savings Account',
    'Checking Account',
    'Credit Card',
    'Digital Wallet',
    'Custom Account',
  ];

  final List<String> _frequencies = [
    'Daily',
    'Weekly',
    'Monthly',
    'Quarterly',
    'Yearly',
  ];

  @override
  void initState() {
    super.initState();
    _updateCategoriesForType();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _interestRateController.dispose();
    _lenderController.dispose();
    _dueDateController.dispose();
    _sourceDueDateController.dispose();
    _providerController.dispose();
    _nextBillingController.dispose();
    _fromAccountController.dispose();
    _toAccountController.dispose();
    _portfolioController.dispose();
    _unitsController.dispose();
    super.dispose();
  }

  void _updateCategoriesForType() {
    final categories = _categoriesByType[_selectedType] ?? [];
    if (categories.isNotEmpty && !categories.contains(_selectedCategory)) {
      _selectedCategory = categories.first;
    }
  }

  Color _getTypeColor() {
    switch (_selectedType) {
      case 'Income':
        return Colors.green;
      case 'Expense':
        return Colors.red;
      case 'Debt':
        return Colors.orange;
      case 'Subscription':
        return Colors.purple;
      case 'Investment':
        return Colors.blue;
      case 'Transfer':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon() {
    switch (_selectedType) {
      case 'Income':
        return Icons.trending_up;
      case 'Expense':
        return Icons.trending_down;
      case 'Debt':
        return Icons.credit_card;
      case 'Subscription':
        return Icons.subscriptions;
      case 'Investment':
        return Icons.account_balance;
      case 'Transfer':
        return Icons.swap_horiz;
      default:
        return Icons.attach_money;
    }
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Handle custom category
        String finalCategory = _selectedCategory;
        if (_selectedCategory == 'Custom Category...' &&
            _customCategory.isNotEmpty) {
          finalCategory = _customCategory;
        }

        // Create the transaction object
        TransactionType transactionType;
        switch (_selectedType) {
          case 'Income':
            transactionType = TransactionType.income;
            break;
          case 'Transfer':
            transactionType = TransactionType.transfer;
            break;
          default: // 'Expense', 'Debt', 'Subscription', 'Investment'
            transactionType = TransactionType.expense;
            break;
        }

        final transaction = Transaction(
          id: '', // Will be set by Firestore
          type: transactionType,
          amount: double.parse(_amountController.text),
          description: _titleController.text,
          categoryId: finalCategory,
          accountId: widget.selectedAccountId ?? '', // Use the selected account
          toAccountId: _selectedType == 'Transfer'
              ? _toAccountController.text
              : null,
          date: _selectedDate,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Save the transaction using the provider
        await context.read<TransactionProvider>().addTransaction(transaction);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(); // Go back to previous screen
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving transaction: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Get type-specific data for saving
  Future<void> _showCustomCategoryDialog() async {
    final customCategory = await showDialog<String>(
      context: context,
      builder: (context) {
        String tempCategory = '';
        return AlertDialog(
          title: const Text('Custom Category'),
          content: TextField(
            decoration: const InputDecoration(
              labelText: 'Category Name',
              hintText: 'Enter custom category name',
            ),
            onChanged: (value) {
              tempCategory = value;
            },
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(tempCategory),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (customCategory != null && customCategory.isNotEmpty) {
      setState(() {
        _customCategory = customCategory;
        _selectedCategory = 'Custom Category...';
      });
    }
  }

  // Build type-specific form fields
  List<Widget> _buildTypeSpecificFields() {
    switch (_selectedType) {
      case 'Debt':
        return _buildDebtFields();
      case 'Income':
        return _buildIncomeFields();
      case 'Subscription':
        return _buildSubscriptionFields();
      case 'Investment':
        return _buildInvestmentFields();
      case 'Transfer':
        return _buildTransferFields();
      default:
        return []; // Expense doesn't need additional fields
    }
  }

  // Debt-specific fields
  List<Widget> _buildDebtFields() {
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance, color: _getTypeColor()),
                  const SizedBox(width: 8),
                  Text(
                    'Debt Details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Lender/Bank Name
              TextFormField(
                controller: _lenderController,
                decoration: const InputDecoration(
                  labelText: 'Lender/Bank Name',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., HDFC Bank, Credit Card Company',
                ),
              ),
              const SizedBox(height: 16),

              // Interest Rate
              TextFormField(
                controller: _interestRateController,
                decoration: const InputDecoration(
                  labelText: 'Interest Rate (%)',
                  border: OutlineInputBorder(),
                  suffixText: '% per annum',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Due Date
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null) {
                    _dueDateController.text =
                        '${date.day}/${date.month}/${date.year}';
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Due Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _dueDateController.text.isEmpty
                        ? 'Select due date'
                        : _dueDateController.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  // Income-specific fields
  List<Widget> _buildIncomeFields() {
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up, color: _getTypeColor()),
                  const SizedBox(width: 8),
                  Text(
                    'Income Details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Source Date (for salary, next expected date)
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    _sourceDueDateController.text =
                        '${date.day}/${date.month}/${date.year}';
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Next Expected Date (Optional)',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                    helperText: 'For recurring income like salary',
                  ),
                  child: Text(
                    _sourceDueDateController.text.isEmpty
                        ? 'Select date'
                        : _sourceDueDateController.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  // Subscription-specific fields
  List<Widget> _buildSubscriptionFields() {
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.subscriptions, color: _getTypeColor()),
                  const SizedBox(width: 8),
                  Text(
                    'Subscription Details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Service Provider
              TextFormField(
                controller: _providerController,
                decoration: const InputDecoration(
                  labelText: 'Service Provider',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Netflix, Spotify, Adobe',
                ),
              ),
              const SizedBox(height: 16),

              // Next Billing Date
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    _nextBillingController.text =
                        '${date.day}/${date.month}/${date.year}';
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Next Billing Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _nextBillingController.text.isEmpty
                        ? 'Select billing date'
                        : _nextBillingController.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  // Investment-specific fields
  List<Widget> _buildInvestmentFields() {
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up, color: _getTypeColor()),
                  const SizedBox(width: 8),
                  Text(
                    'Investment Details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Portfolio/Fund Name
              TextFormField(
                controller: _portfolioController,
                decoration: const InputDecoration(
                  labelText: 'Fund/Stock/Portfolio Name',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., HDFC Equity Fund, Reliance Industries',
                ),
              ),
              const SizedBox(height: 16),

              // Units/Quantity
              TextFormField(
                controller: _unitsController,
                decoration: const InputDecoration(
                  labelText: 'Units/Quantity (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Number of units purchased',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
    ];
  }

  // Transfer-specific fields
  List<Widget> _buildTransferFields() {
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.swap_horiz, color: _getTypeColor()),
                  const SizedBox(width: 8),
                  Text(
                    'Transfer Details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // From Account
              DropdownButtonFormField<String>(
                initialValue: _selectedAccount, // Use as from account
                decoration: const InputDecoration(
                  labelText: 'From Account',
                  border: OutlineInputBorder(),
                ),
                items: _accounts.map((account) {
                  return DropdownMenuItem(value: account, child: Text(account));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAccount = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // To Account/Person
              TextFormField(
                controller: _toAccountController,
                decoration: const InputDecoration(
                  labelText: 'To Account/Person',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., My Savings Account, John Doe',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please specify the destination';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: TranslucentAppBar(
        title: const Text('Add Transaction'),
        actions: [
          TextButton(
            onPressed: _saveTransaction,
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + kToolbarHeight + 16,
            16,
            MediaQuery.of(context).padding.bottom + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount Input (Primary)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(_getTypeIcon(), size: 40, color: _getTypeColor()),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          prefixText: '₹ ',
                          border: const OutlineInputBorder(),
                          labelStyle: TextStyle(color: _getTypeColor()),
                        ),
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _getTypeColor(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Transaction Type Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transaction Type',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _transactionTypes.map((type) {
                          return ChoiceChip(
                            label: Text(type),
                            selected: _selectedType == type,
                            onSelected: (selected) {
                              setState(() {
                                _selectedType = type;
                                _updateCategoriesForType();
                              });
                            },
                            selectedColor: _getTypeColor().withOpacity(0.2),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Transaction Details
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transaction Details',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),

                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title/Description',
                          border: OutlineInputBorder(),
                          hintText: 'Enter transaction description',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Category
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: const OutlineInputBorder(),
                          suffixText:
                              _selectedCategory == 'Custom Category...' &&
                                  _customCategory.isNotEmpty
                              ? _customCategory
                              : null,
                        ),
                        items: (_categoriesByType[_selectedType] ?? []).map((
                          category,
                        ) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) async {
                          if (value == 'Custom Category...') {
                            await _showCustomCategoryDialog();
                          } else {
                            setState(() {
                              _selectedCategory = value!;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Account
                      DropdownButtonFormField<String>(
                        initialValue: _selectedAccount,
                        decoration: const InputDecoration(
                          labelText: 'Account',
                          border: OutlineInputBorder(),
                        ),
                        items: _accounts.map((account) {
                          return DropdownMenuItem(
                            value: account,
                            child: Text(account),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedAccount = value!;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // Date Selection
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            setState(() {
                              _selectedDate = date;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Notes
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                          border: OutlineInputBorder(),
                          hintText: 'Add any additional notes',
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Type-specific form sections
              ..._buildTypeSpecificFields(),

              const SizedBox(height: 16),

              // Recurring Options (for Subscriptions/Bills)
              if (_selectedType == 'Subscription' || _selectedType == 'Debt')
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.repeat, color: _getTypeColor()),
                            const SizedBox(width: 8),
                            Text(
                              'Recurring Transaction',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          title: const Text('Make this recurring'),
                          subtitle: Text(
                            _selectedType == 'Subscription'
                                ? 'Automatically track subscription renewals'
                                : 'Set up recurring debt payments',
                          ),
                          value: _isRecurring,
                          onChanged: (value) {
                            setState(() {
                              _isRecurring = value;
                            });
                          },
                        ),
                        if (_isRecurring) ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _recurringFrequency,
                            decoration: const InputDecoration(
                              labelText: 'Frequency',
                              border: OutlineInputBorder(),
                            ),
                            items: _frequencies.map((frequency) {
                              return DropdownMenuItem(
                                value: frequency,
                                child: Text(frequency),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _recurringFrequency = value!;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getTypeColor(),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Add $_selectedType',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
