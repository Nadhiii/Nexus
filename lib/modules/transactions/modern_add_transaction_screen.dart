import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/models/transaction.dart';
import '../../core/providers/transaction_provider.dart';
import '../../core/providers/account_provider.dart';
import '../../models/detected_sms_transaction.dart';
import '../../core/providers/new_nbox_provider.dart';

class ModernAddTransactionScreen extends StatefulWidget {
  final Transaction? transaction;
  final String? accountId;
  final TransactionType? initialType;
  final DetectedSmsTransaction? detectedSmsTransaction;

  const ModernAddTransactionScreen({
    super.key,
    this.transaction,
    this.accountId,
    this.initialType,
    this.detectedSmsTransaction,
  });

  @override
  State<ModernAddTransactionScreen> createState() => _ModernAddTransactionScreenState();
}

class _ModernAddTransactionScreenState extends State<ModernAddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  String? _selectedAccountId;
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool get _isEditMode => widget.transaction != null;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Food & Dining', 'icon': Icons.restaurant, 'color': AppColors.error},
    {'name': 'Shopping', 'icon': Icons.shopping_bag, 'color': AppColors.accentPurple},
    {'name': 'Transportation', 'icon': Icons.directions_car, 'color': AppColors.primaryBlue},
    {'name': 'Entertainment', 'icon': Icons.movie, 'color': AppColors.accentTeal},
    {'name': 'Bills', 'icon': Icons.receipt_long, 'color': AppColors.warning},
    {'name': 'Healthcare', 'icon': Icons.local_hospital, 'color': AppColors.error},
    {'name': 'Salary', 'icon': Icons.account_balance_wallet, 'color': AppColors.success},
    {'name': 'Investment', 'icon': Icons.trending_up, 'color': AppColors.accentTeal},
    {'name': 'Other', 'icon': Icons.more_horiz, 'color': AppColors.neutral500},
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final transaction = widget.transaction!;
      _amountController.text = transaction.amount.toStringAsFixed(2);
      _descriptionController.text = transaction.description ?? '';
      _selectedType = transaction.type;
      _selectedAccountId = transaction.accountId;
      _selectedCategory = transaction.categoryId;
      _selectedDate = transaction.date;
    } else {
      _selectedType = widget.initialType ?? TransactionType.expense;
      _selectedAccountId = widget.accountId;

      if (widget.detectedSmsTransaction != null) {
        final detected = widget.detectedSmsTransaction!;
        _amountController.text = detected.amount.toStringAsFixed(2);
        _descriptionController.text = detected.merchant;
        _selectedDate = detected.date;
        _selectedType = detected.type == 'income' ? TransactionType.income : TransactionType.expense;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditMode ? 'Edit Transaction' : (widget.detectedSmsTransaction != null ? 'Approve Transaction' : 'New Transaction');

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppColors.darkGradient,
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTypography.displaySmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl2),
                          
                          _buildTypeToggle(),
                          const SizedBox(height: AppSpacing.xl2),
                          
                          Text(
                            'Amount',
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _amountController,
                            autofocus: !_isEditMode && widget.detectedSmsTransaction == null,
                            style: AppTypography.displayMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              prefixText: '₹ ',
                              prefixStyle: AppTypography.displayMedium.copyWith(
                                color: _selectedType == TransactionType.income 
                                    ? AppColors.success 
                                    : AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                              hintStyle: TextStyle(
                                color: AppColors.textTertiary,
                              ),
                              filled: true,
                              fillColor: AppColors.cardDarkElevated,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Amount is required';
                              }
                              if (double.tryParse(value.trim()) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl2),
                          
                          Consumer<AccountProvider>(
                            builder: (context, provider, child) {
                              if (provider.accounts.isEmpty) {
                                return Container(
                                  padding: AppSpacing.cardPaddingMd,
                                  decoration: BoxDecoration(
                                    color: AppColors.cardDarkElevated,
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'No accounts available',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Account',
                                    style: AppTypography.titleSmall.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.cardDarkElevated,
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                    ),
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedAccountId,
                                      dropdownColor: AppColors.cardDarkElevated,
                                      style: AppTypography.bodyLarge.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.lg,
                                          vertical: AppSpacing.md,
                                        ),
                                      ),
                                      hint: Text(
                                        'Select account',
                                        style: AppTypography.bodyLarge.copyWith(
                                          color: AppColors.textTertiary,
                                        ),
                                      ),
                                      items: provider.accounts.map((account) {
                                        return DropdownMenuItem<String>(
                                          value: account.id,
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(AppSpacing.xs),
                                                decoration: BoxDecoration(
                                                  color: account.color.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                                ),
                                                child: Icon(
                                                  account.icon,
                                                  color: account.color,
                                                  size: 16,
                                                ),
                                              ),
                                              const SizedBox(width: AppSpacing.sm),
                                              Text(account.name),
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
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl2),
                          
                          Text(
                            'Category',
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: _categories.map((category) {
                              final isSelected = _selectedCategory == category['name'];
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = category['name'];
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? (category['color'] as Color).withOpacity(0.2)
                                        : AppColors.cardDarkElevated,
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                    border: Border.all(
                                      color: isSelected 
                                          ? (category['color'] as Color)
                                          : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        category['icon'] as IconData,
                                        size: 18,
                                        color: isSelected 
                                            ? (category['color'] as Color)
                                            : AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Text(
                                        category['name'] as String,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: isSelected 
                                              ? AppColors.textPrimary
                                              : AppColors.textSecondary,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: AppSpacing.xl2),
                          
                          Text(
                            'Description (Optional)',
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _descriptionController,
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Add a note...',
                              hintStyle: TextStyle(
                                color: AppColors.textTertiary,
                              ),
                              filled: true,
                              fillColor: AppColors.cardDarkElevated,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: AppSpacing.xl2),
                          
                          Text(
                            'Date',
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          GestureDetector(
                            onTap: () => _selectDate(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cardDarkElevated,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(_selectedDate),
                                    style: AppTypography.bodyLarge.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.chevron_right,
                                    color: AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl2),
                          
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveTransaction,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedType == TransactionType.income
                                    ? AppColors.success
                                    : AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _isEditMode ? 'Save Changes' : 'Save Transaction',
                                      style: AppTypography.titleSmall.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDarkElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedType = TransactionType.expense),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: _selectedType == TransactionType.expense
                      ? AppColors.error
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_upward,
                      color: _selectedType == TransactionType.expense
                          ? Colors.white
                          : AppColors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Expense',
                      style: AppTypography.titleSmall.copyWith(
                        color: _selectedType == TransactionType.expense
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedType = TransactionType.income),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: _selectedType == TransactionType.income
                      ? AppColors.success
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_downward,
                      color: _selectedType == TransactionType.income
                          ? Colors.white
                          : AppColors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Income',
                      style: AppTypography.titleSmall.copyWith(
                        color: _selectedType == TransactionType.income
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select an account'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text.trim());
      final now = DateTime.now();
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

      final transaction = Transaction(
        id: _isEditMode ? widget.transaction!.id : '',
        userId: userId,
        type: _selectedType,
        amount: amount,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        categoryId: _selectedCategory,
        accountId: _selectedAccountId!,
        date: _selectedDate,
        createdAt: _isEditMode ? widget.transaction!.createdAt : now,
        updatedAt: now,
      );

      final provider = context.read<TransactionProvider>();
      final success = _isEditMode
          ? await provider.updateTransaction(transaction, widget.transaction!)
          : await provider.addTransaction(transaction);

      if (success && mounted) {
        // If this was an NBox transaction, mark it as approved
        if (widget.detectedSmsTransaction != null && mounted) {
          context.read<NewNboxProvider>().markAsApproved(widget.detectedSmsTransaction!.smsId);
          Navigator.of(context).pop(true); // Pop with success for NBox
          return; // Prevent double pop
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction ${_isEditMode ? 'updated' : 'saved'} successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        final error = context.read<TransactionProvider>().error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to save transaction'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
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
