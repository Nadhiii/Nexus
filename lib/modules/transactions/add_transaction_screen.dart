import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_animations.dart';
import '../../core/models/transaction.dart';
import '../../core/models/transaction_draft.dart';
import '../../core/providers/transaction_provider.dart';
import '../../core/providers/account_provider.dart';
import '../../core/providers/category_provider.dart';
import '../../core/models/detected_transaction.dart';
import '../../core/providers/nbox_provider.dart';
import '../../core/providers/knowledge_provider.dart';
import '../../core/models/knowledge_entry.dart';
import '../../core/widgets/top_snackbar.dart';
import '../../core/services/transaction_intelligence_service.dart';
import '../../core/utils/logo_utils.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/services/transaction_match_service.dart';
import '../payday/payday_checklist_helper.dart';

class ModernAddTransactionScreen extends StatefulWidget {
  final Transaction? transaction;
  final String? accountId;
  final String? categoryId;
  final TransactionType? initialType;
  final DetectedTransaction? detectedTransaction;

  const ModernAddTransactionScreen({
    super.key,
    this.transaction,
    this.accountId,
    this.categoryId,
    this.initialType,
    this.detectedTransaction,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    Transaction? transaction,
    String? accountId,
    String? categoryId,
    TransactionType? initialType,
    DetectedTransaction? detectedTransaction,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => ModernAddTransactionScreen(
        transaction: transaction,
        accountId: accountId,
        categoryId: categoryId,
        initialType: initialType,
        detectedTransaction: detectedTransaction,
      ),
    );
  }

  @override
  State<ModernAddTransactionScreen> createState() =>
      _ModernAddTransactionScreenState();
}

class _ModernAddTransactionScreenState
    extends State<ModernAddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  String? _selectedAccountId;
  String? _toAccountId;
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool get _isEditMode => widget.transaction != null;

  @override
  void initState() {
    super.initState();

    if (_isEditMode) {
      final transaction = widget.transaction!;
      _amountController.text = transaction.amount.toStringAsFixed(2);
      _descriptionController.text = transaction.description ?? '';
      _selectedType = transaction.type;
      _selectedAccountId = transaction.accountId;
      _toAccountId = transaction.toAccountId;
      _selectedCategory = transaction.categoryId;
      _selectedDate = transaction.date;
    } else {
      _selectedType = widget.initialType ?? TransactionType.expense;
      _selectedAccountId = widget.accountId;

      if (widget.detectedTransaction != null) {
        final detected = widget.detectedTransaction!;
        _amountController.text = detected.amount.toStringAsFixed(2);
        _descriptionController.text = detected.merchant;
        _selectedDate = detected.date;
        _selectedType = detected.type.toLowerCase() == 'income'
            ? TransactionType.income
            : TransactionType.expense;

        final understanding = const TransactionIntelligenceService().analyze(
          detected: detected,
          history: context.read<TransactionProvider>().transactions,
          knowledge: context.read<KnowledgeProvider>().entries,
        );
        _selectedCategory =
            widget.categoryId ??
            understanding.categoryId ??
            detected.detectedCategory ??
            'other';
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accounts = context.read<AccountProvider>().accounts;
      if (_selectedAccountId == null && accounts.isNotEmpty) {
        setState(() => _selectedAccountId = accounts.first.id);
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Color _getTypeColor() {
    switch (_selectedType) {
      case TransactionType.income:
        return AppColors.success;
      case TransactionType.transfer:
        return AppColors.primaryBlue;
      case TransactionType.adjustment:
        return AppColors.warning;
      case TransactionType.expense:
      default:
        return AppColors.error;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: _getTypeColor(),
              surface: AppColors.darkSurfaceElevated,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAccountId == null) {
      showTopSnackBar(context, 'Please select an account', isError: true);
      return;
    }

    if (_selectedType == TransactionType.transfer && _toAccountId == null) {
      showTopSnackBar(
        context,
        'Please select a destination account',
        isError: true,
      );
      return;
    }

    if (_selectedType == TransactionType.transfer &&
        _selectedAccountId == _toAccountId) {
      showTopSnackBar(
        context,
        'Source and destination accounts must be different',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text.trim());
      final now = DateTime.now();
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final transactionProvider = context.read<TransactionProvider>();
      final subscriptionProvider = context.read<SubscriptionProvider>();
      final nboxProvider = context.read<NewNboxProvider>();

      String? resolvedCategoryId = _selectedCategory;
      if (_selectedType != TransactionType.transfer) {
        final categories = context.read<CategoryProvider>().categories;
        final hasId = categories.any((c) => c.id == resolvedCategoryId);
        if (!hasId) {
          final byName = categories
              .where((c) => c.name == resolvedCategoryId)
              .toList();
          resolvedCategoryId = byName.isNotEmpty
              ? byName.first.id
              : resolvedCategoryId;
        }
        _selectedCategory = resolvedCategoryId;
      }

      if (!_isEditMode && widget.detectedTransaction != null) {
        final fingerprint = widget.detectedTransaction!.fingerprint;
        if (fingerprint.isNotEmpty) {
          final existing = await transactionProvider.findBySourceFingerprint(
            fingerprint,
          );
          if (existing != null) {
            if (!mounted) return;
            await nboxProvider.markAsApproved(
              widget.detectedTransaction!.id,
              widget.detectedTransaction!.source,
            );
            if (mounted) {
              showTopSnackBar(context, 'This transaction is already recorded.');
              Navigator.pop(context, false);
            }
            return;
          }
        }
      }

      final transaction = Transaction(
        id: _isEditMode ? widget.transaction!.id : '',
        userId: userId,
        type: _selectedType,
        amount: amount,
        description: _descriptionController.text.trim().isEmpty
            ? (_selectedType == TransactionType.transfer ? 'Transfer' : null)
            : _descriptionController.text.trim(),
        categoryId: _selectedType == TransactionType.transfer
            ? 'transfer'
            : resolvedCategoryId,
        accountId: _selectedAccountId!,
        toAccountId: _selectedType == TransactionType.transfer
            ? _toAccountId
            : null,
        date: _selectedDate,
        metadata: widget.detectedTransaction == null
            ? null
            : {
                'source': widget.detectedTransaction!.source,
                'sourceId': widget.detectedTransaction!.id,
                'sourceFingerprint': widget.detectedTransaction!.fingerprint,
                'entity': widget.detectedTransaction!.merchant,
              },
        createdAt: _isEditMode ? widget.transaction!.createdAt : now,
        updatedAt: now,
      );

      final success = _isEditMode
          ? await transactionProvider.updateTransaction(
              transaction,
              widget.transaction!,
            )
          : (await transactionProvider.commitDraft(
                  TransactionDraft.fromTransaction(transaction),
                )) !=
                null;

      if (success && mounted) {
        if (_selectedCategory == 'subscriptions') {
          final matchResult = TransactionMatchService.analyzeTransaction(
            transaction: transaction,
            subscriptions: subscriptionProvider.subscriptions,
            debts: [],
          );
          final matches = matchResult.matches.where(
            (m) => m.type.toString().contains('subscription'),
          );
          if (matches.isNotEmpty) {
            final subs = subscriptionProvider.subscriptions.where(
              (s) => s.id == matches.first.id,
            );
            if (subs.isNotEmpty) {
              await subscriptionProvider.markSubscriptionPaid(subs.first);
            }
          }
        }

        if (widget.detectedTransaction != null) {
          await nboxProvider.markAsApproved(
            widget.detectedTransaction!.id,
            widget.detectedTransaction!.source,
          );
          if (mounted) {
            if (!_isEditMode && transaction.type == TransactionType.income) {
              await PaydayChecklistHelper.checkAndShowChecklist(
                context,
                transaction: transaction,
              );
            }
            Navigator.of(context).pop(true);
            return;
          }
        }

        showTopSnackBar(
          context,
          _selectedType == TransactionType.transfer
              ? 'Transfer completed successfully!'
              : 'Transaction ${_isEditMode ? 'updated' : 'saved'} successfully!',
        );

        if (!_isEditMode && transaction.type == TransactionType.income) {
          Navigator.of(context).pop();
          await PaydayChecklistHelper.checkAndShowChecklist(
            context,
            transaction: transaction,
          );
        } else {
          Navigator.of(context).pop();
        }
      } else if (mounted) {
        showTopSnackBar(
          context,
          context.read<TransactionProvider>().error ??
              'Failed to save transaction',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) showTopSnackBar(context, 'Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final activeColor = _getTypeColor();

    return Material(
      color: AppColors.darkSurface,
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusLg),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xl + bottomInset,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderSubtleDark,
                      borderRadius: AppSpacing.borderRadiusFull,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditMode
                          ? 'Edit Transaction'
                          : (widget.detectedTransaction != null
                                ? 'Approve Transaction'
                                : 'New Transaction'),
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textSecondary,
                        size: AppSpacing.iconSm,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                _buildTypeToggle(),
                const SizedBox(height: AppSpacing.xl),

                _buildLabel('AMOUNT'),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: AppTypography.currencyMedium.copyWith(
                    color: activeColor,
                  ),
                  decoration: InputDecoration(
                    hintText: "0.00",
                    hintStyle: AppTypography.currencyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    prefixText: "₹ ",
                    prefixStyle: AppTypography.currencyMedium.copyWith(
                      color: activeColor,
                    ),
                    filled: true,
                    fillColor: AppColors.darkSurfaceElevated,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusSm,
                      borderSide: const BorderSide(
                        color: AppColors.borderSubtleDark,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusSm,
                      borderSide: const BorderSide(
                        color: AppColors.borderSubtleDark,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusSm,
                      borderSide: BorderSide(color: activeColor, width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty)
                      return "Amount is required";
                    if (double.tryParse(val.trim()) == null)
                      return "Enter a valid amount";
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                Consumer<AccountProvider>(
                  builder: (context, provider, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(
                          _selectedType == TransactionType.transfer
                              ? 'FROM ACCOUNT'
                              : 'ACCOUNT',
                        ),
                        _buildAccountDropdown(
                          accounts: provider.accounts,
                          selectedId: _selectedAccountId,
                          onChanged: (val) => setState(() {
                            _selectedAccountId = val;
                            if (_toAccountId == val) _toAccountId = null;
                          }),
                        ),
                        if (_selectedType == TransactionType.transfer) ...[
                          const SizedBox(height: AppSpacing.md),
                          _buildLabel('TO ACCOUNT'),
                          _buildAccountDropdown(
                            accounts: provider.accounts
                                .where((a) => a.id != _selectedAccountId)
                                .toList(),
                            selectedId: _toAccountId,
                            onChanged: (val) =>
                                setState(() => _toAccountId = val),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                if (_selectedType != TransactionType.transfer) ...[
                  _buildLabel('CATEGORY'),
                  Consumer<CategoryProvider>(
                    builder: (context, categoryProvider, _) {
                      final categories = categoryProvider.categories;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.darkSurfaceElevated,
                          borderRadius: AppSpacing.borderRadiusSm,
                          border: Border.all(color: AppColors.borderSubtleDark),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            isExpanded: true,
                            dropdownColor: AppColors.darkSurfaceElevated,
                            hint: Text(
                              'Select Category',
                              style: TextStyle(color: AppColors.textTertiary),
                            ),
                            items: categories.map((c) {
                              return DropdownMenuItem(
                                value: c.id,
                                child: Row(
                                  children: [
                                    Text(
                                      c.emoji,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      c.name,
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedCategory = val),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                _buildLabel('DESCRIPTION / NOTE (OPTIONAL)'),
                TextFormField(
                  controller: _descriptionController,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: "What was this for?",
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    filled: true,
                    fillColor: AppColors.darkSurfaceElevated,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(
                        left: AppSpacing.md,
                        right: AppSpacing.sm,
                      ),
                      child: Icon(
                        Icons.edit_note_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusSm,
                      borderSide: const BorderSide(
                        color: AppColors.borderSubtleDark,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusSm,
                      borderSide: const BorderSide(
                        color: AppColors.borderSubtleDark,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusSm,
                      borderSide: BorderSide(color: activeColor, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                _buildLabel('DATE'),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurfaceElevated,
                      borderRadius: AppSpacing.borderRadiusSm,
                      border: Border.all(color: AppColors.borderSubtleDark),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          DateFormat('dd MMM yyyy').format(_selectedDate),
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl2),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          backgroundColor: AppColors.darkSurfaceElevated,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppSpacing.borderRadiusSm,
                            side: const BorderSide(
                              color: AppColors.borderSubtleDark,
                            ),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveTransaction,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          backgroundColor: activeColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppSpacing.borderRadiusSm,
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isEditMode
                                    ? 'Save Changes'
                                    : 'Record Transaction',
                                style: AppTypography.labelLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceElevated,
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: AppColors.borderSubtleDark),
      ),
      child: Row(
        children: [
          _buildTypeOption('Expense', TransactionType.expense, AppColors.error),
          _buildTypeOption('Income', TransactionType.income, AppColors.success),
          _buildTypeOption(
            'Transfer',
            TransactionType.transfer,
            AppColors.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOption(String label, TransactionType type, Color color) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: AnimatedContainer(
          duration: AppAnimations.standard,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: AppSpacing.borderRadiusSm,
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountDropdown({
    required List<dynamic> accounts,
    required String? selectedId,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceElevated,
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: AppColors.borderSubtleDark),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: accounts.any((a) => a.id == selectedId) ? selectedId : null,
          isExpanded: true,
          dropdownColor: AppColors.darkSurfaceElevated,
          hint: Text(
            'Select Account',
            style: TextStyle(color: AppColors.textTertiary),
          ),
          items: accounts.map((a) {
            final logo = LogoUtils.bankLogoFor(a.bankName ?? a.name);
            return DropdownMenuItem<String>(
              value: a.id as String,
              child: Row(
                children: [
                  if (logo != null)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: LogoUtils.buildLogo(logo, size: 18),
                    )
                  else
                    Icon(
                      a.icon as IconData,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    a.name as String,
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

Future<T?> navToAddTransactionScreen<T>(
  BuildContext context, {
  Transaction? transaction,
  String? accountId,
  String? categoryId,
  TransactionType? initialType,
  DetectedTransaction? detectedTransaction,
}) {
  return ModernAddTransactionScreen.show<T>(
    context,
    transaction: transaction,
    accountId: accountId,
    categoryId: categoryId,
    initialType: initialType,
    detectedTransaction: detectedTransaction,
  );
}
