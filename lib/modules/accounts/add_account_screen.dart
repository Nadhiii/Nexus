import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/widgets/translucent_app_bar.dart';
import '../../core/providers/account_provider.dart';
import '../../core/models/account.dart';
import '../../core/services/account_service.dart';

class AddAccountScreen extends StatefulWidget {
  final Account? account; // Optional account for editing

  const AddAccountScreen({super.key, this.account});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _notesController = TextEditingController();

  AccountType _selectedType = AccountType.savings;
  Color _selectedColor = Colors.blue;
  IconData _selectedIcon = Icons.account_balance;
  bool _isLoading = false;

  final List<Color> _availableColors = [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
    Colors.amber,
    Colors.deepOrange,
    Colors.cyan,
    Colors.lime,
  ];

  @override
  void initState() {
    super.initState();
    print('AddAccountScreen: initState called');

    if (widget.account != null) {
      print('AddAccountScreen: editing existing account');
      // Populate fields for editing
      _nameController.text = widget.account!.name;
      _bankNameController.text = widget.account!.bankName ?? '';
      _balanceController.text = widget.account!.balance.toString();
      _accountNumberController.text = widget.account!.accountNumber ?? '';
      _notesController.text = widget.account!.notes ?? '';
      _selectedType = widget.account!.type;
      _selectedColor = widget.account!.color;
      _selectedIcon = widget.account!.icon;
    } else {
      print('AddAccountScreen: creating new account');
      _updateDefaultColorAndIcon();
    }
    print('AddAccountScreen: initState completed');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bankNameController.dispose();
    _balanceController.dispose();
    _accountNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateDefaultColorAndIcon() {
    try {
      print(
        'AddAccountScreen: _updateDefaultColorAndIcon called for type: $_selectedType',
      );
      _selectedColor = AccountService.getDefaultColor(_selectedType);
      _selectedIcon = AccountService.getDefaultIcon(_selectedType);
      print('AddAccountScreen: _updateDefaultColorAndIcon completed');
    } catch (e) {
      print('AddAccountScreen: Error in _updateDefaultColorAndIcon - $e');
      // Fallback to safe defaults
      _selectedColor = Colors.blue;
      _selectedIcon = Icons.account_balance;
    }
  }

  @override
  Widget build(BuildContext context) {
    print('AddAccountScreen: build called');
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: TranslucentAppBar(
        title: Text(widget.account != null ? 'Edit Account' : 'Add Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(onPressed: _saveAccount, child: const Text('Save')),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.of(context).padding.top + kToolbarHeight + 16,
          16,
          MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Type Selection
              _buildSectionHeader('Account Type'),
              const SizedBox(height: 8),
              _buildAccountTypeSelector(),
              const SizedBox(height: 24),

              // Basic Information
              _buildSectionHeader('Basic Information'),
              const SizedBox(height: 16),
              _buildAccountNameField(),
              const SizedBox(height: 16),
              _buildBankNameField(),
              const SizedBox(height: 16),
              _buildBalanceField(),
              const SizedBox(height: 24),

              // Appearance
              _buildSectionHeader('Appearance'),
              const SizedBox(height: 16),
              _buildColorSelector(),
              const SizedBox(height: 16),
              _buildIconSelector(),
              const SizedBox(height: 24),

              // Optional Information
              _buildSectionHeader('Optional Information'),
              const SizedBox(height: 16),
              _buildAccountNumberField(),
              const SizedBox(height: 16),
              _buildNotesField(),
              const SizedBox(height: 32),

              // Preview
              _buildSectionHeader('Preview'),
              const SizedBox(height: 8),
              _buildAccountPreview(),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _saveAccount,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildAccountTypeSelector() {
    return DropdownButtonFormField<AccountType>(
      initialValue: _selectedType,
      decoration: const InputDecoration(
        labelText: 'Account Type *',
        border: OutlineInputBorder(),
      ),
      items: AccountType.values.map((type) {
        return DropdownMenuItem<AccountType>(
          value: type,
          child: Row(
            children: [
              Icon(
                AccountService.getDefaultIcon(type),
                color: AccountService.getDefaultColor(type),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getTypeDisplayName(type),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      _getTypeDescription(type),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (AccountType? value) {
        if (value != null) {
          setState(() {
            _selectedType = value;
            _updateDefaultColorAndIcon();
          });
        }
      },
      validator: (value) {
        if (value == null) {
          return 'Please select an account type';
        }
        return null;
      },
    );
  }

  String _getTypeDescription(AccountType type) {
    switch (type) {
      case AccountType.savings:
        return 'Money saved for future use and emergencies';
      case AccountType.salary:
        return 'Account where salary is credited monthly';
      case AccountType.checking:
        return 'Current account for daily transactions';
      case AccountType.investment:
        return 'Stocks, bonds, mutual funds';
      case AccountType.cash:
        return 'Physical cash on hand';
      case AccountType.other:
        return 'Custom types - you can name it anything';
    }
  }

  String _getTypeDisplayName(AccountType type) {
    switch (type) {
      case AccountType.savings:
        return 'Savings Account';
      case AccountType.salary:
        return 'Salary Account';
      case AccountType.checking:
        return 'Checking Account';
      case AccountType.investment:
        return 'Investment Account';
      case AccountType.cash:
        return 'Cash';
      case AccountType.other:
        return 'Custom Account';
    }
  }

  Widget _buildAccountNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Account Name *',
        hintText: 'e.g., Main Checking, Emergency Fund',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Account name is required';
        }
        return null;
      },
    );
  }

  Widget _buildBankNameField() {
    return TextFormField(
      controller: _bankNameController,
      decoration: const InputDecoration(
        labelText: 'Bank/Institution Name',
        hintText: 'e.g., State Bank, HDFC Bank',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildBalanceField() {
    return TextFormField(
      controller: _balanceController,
      decoration: const InputDecoration(
        labelText: 'Current Balance *',
        hintText: '0.00',
        border: OutlineInputBorder(),
        prefixText: '₹ ',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Balance is required';
        }
        final balance = double.tryParse(value.trim());
        if (balance == null) {
          return 'Please enter a valid number';
        }
        return null;
      },
    );
  }

  Widget _buildColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Color', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableColors.map((color) {
            final isSelected = _selectedColor == color;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = color;
                });
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildIconSelector() {
    final icons = [
      Icons.account_balance,
      Icons.savings,
      Icons.credit_card,
      Icons.trending_up,
      Icons.payments,
      Icons.money_off,
      Icons.account_balance_wallet,
      Icons.account_box,
      Icons.business,
      Icons.home,
      Icons.work,
      Icons.school,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Icon', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: icons.map((icon) {
            final isSelected = _selectedIcon == icon;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIcon = icon;
                });
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? _selectedColor.withOpacity(0.1)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? _selectedColor
                        : Theme.of(context).colorScheme.outline,
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? _selectedColor
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAccountNumberField() {
    return TextFormField(
      controller: _accountNumberController,
      decoration: const InputDecoration(
        labelText: 'Account Number (Last 4 digits)',
        hintText: 'e.g., 1234',
        border: OutlineInputBorder(),
      ),
      maxLength: 4,
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Notes',
        hintText: 'Any additional information about this account',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
    );
  }

  Widget _buildAccountPreview() {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _selectedColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_selectedIcon, color: _selectedColor, size: 24),
        ),
        title: Text(
          _nameController.text.isEmpty ? 'Account Name' : _nameController.text,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Account(
                id: '',
                userId: '',
                name: '',
                type: _selectedType,
                balance: 0,
                color: Colors.blue,
                icon: Icons.account_balance,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ).typeDisplayName,
            ),
            if (_bankNameController.text.isNotEmpty)
              Text(_bankNameController.text),
          ],
        ),
        trailing: Text(
          '₹${_balanceController.text.isEmpty ? '0.00' : _balanceController.text}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.green, // All account types are assets now
          ),
        ),
      ),
    );
  }

  void _saveAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final balance = double.parse(_balanceController.text.trim());
      final now = DateTime.now();
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

      final account = Account(
        id:
            widget.account?.id ??
            '', // Use existing ID for editing, empty for new
        userId: widget.account?.userId ?? userId,
        name: _nameController.text.trim(),
        type: _selectedType,
        bankName: _bankNameController.text.trim().isEmpty
            ? null
            : _bankNameController.text.trim(),
        balance: balance,
        color: _selectedColor,
        icon: _selectedIcon,
        createdAt:
            widget.account?.createdAt ??
            now, // Keep original created date for editing
        updatedAt: now,
        accountNumber: _accountNumberController.text.trim().isEmpty
            ? null
            : _accountNumberController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      final success = widget.account != null
          ? await context.read<AccountProvider>().updateAccount(account)
          : await context.read<AccountProvider>().createAccount(account);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.account != null
                  ? 'Account updated successfully!'
                  : 'Account created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        final error = context.read<AccountProvider>().error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error ??
                  (widget.account != null
                      ? 'Failed to update account'
                      : 'Failed to create account'),
            ),
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
