import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_animations.dart';
import '../../core/models/transaction.dart';
import '../../core/providers/transaction_provider.dart';
import '../../core/providers/account_provider.dart';
import '../../core/providers/category_provider.dart';
import '../../core/models/detected_transaction.dart';
import '../../core/providers/nbox_provider.dart';
import '../../core/widgets/top_snackbar.dart';
import '../../core/services/smart_category_resolver.dart';
import '../../core/utils/logo_utils.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/services/transaction_match_service.dart';
import '../payday/payday_checklist_helper.dart';

class ModernAddTransactionScreen extends StatefulWidget {
  final Transaction? transaction;
  final String? accountId;
  final TransactionType? initialType;
  final DetectedTransaction? detectedTransaction;

  const ModernAddTransactionScreen({
    super.key,
    this.transaction,
    this.accountId,
    this.initialType,
    this.detectedTransaction,
  });

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
  String? _toAccountId; // For transfers
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool get _isEditMode => widget.transaction != null;

  final FocusNode _categoryFocus = FocusNode();
  bool _categoryHasFocus = false;

  // Categories now sourced from CategoryProvider

  @override
  void initState() {
    super.initState();

    _categoryFocus.addListener(() {
      if (mounted) {
        setState(() {
          _categoryHasFocus = _categoryFocus.hasFocus;
        });
      }
    });

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

      if (widget.detectedTransaction != null) {
        final detected = widget.detectedTransaction!;
        _amountController.text = detected.amount.toStringAsFixed(2);
        _descriptionController.text = detected.merchant;
        _selectedDate = detected.date;
        _selectedType = detected.type.toLowerCase() == 'income'
            ? TransactionType.income
            : TransactionType.expense;
        // Prefer detectedCategory if present, else fallback to merchant-based suggestion
        _selectedCategory =
            detected.detectedCategory ??
            SmartCategoryResolver.resolve(
              merchant: detected.merchant,
              body: detected.body,
              amount: detected.amount,
              transactionType: detected.type,
            );
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _categoryFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditMode
        ? 'Edit Transaction'
        : (widget.detectedTransaction != null
              ? 'Approve Transaction'
              : 'New Transaction');

    return Scaffold(
      backgroundColor: AppColors.darkGradient.first,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120.0,
            backgroundColor: AppColors.darkGradient.first,
            foregroundColor: AppColors.white,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(title, style: AppTypography.headlineMedium),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      autofocus:
                          !_isEditMode && widget.detectedTransaction == null,
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
                        hintStyle: TextStyle(color: AppColors.textTertiary),
                        filled: true,
                        fillColor: AppColors.cardElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
                                color: AppColors.cardElevated,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusLg,
                                ),
                              ),
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedAccountId,
                                dropdownColor: AppColors.cardElevated,
                                style: AppTypography.bodyLarge.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusLg,
                                    ),
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
                                  final bankLogo = LogoUtils.bankLogoFor(
                                    account.bankName ?? account.name,
                                  );
                                  return DropdownMenuItem<String>(
                                    value: account.id,
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(
                                            AppSpacing.xs,
                                          ),
                                          decoration: BoxDecoration(
                                            color: account.color.withValues(
                                              alpha: 0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              AppSpacing.radiusSm,
                                            ),
                                          ),
                                          child: bankLogo != null
                                              ? LogoUtils.buildLogo(
                                                  bankLogo,
                                                  size: 16,
                                                )
                                              : Icon(
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
                            // Show "To Account" dropdown for transfers
                            if (_selectedType == TransactionType.transfer) ...[
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                'To Account',
                                style: AppTypography.titleSmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.cardElevated,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusLg,
                                  ),
                                ),
                                child: DropdownButtonFormField<String>(
                                  initialValue: _toAccountId,
                                  dropdownColor: AppColors.cardElevated,
                                  style: AppTypography.bodyLarge.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusLg,
                                      ),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.lg,
                                      vertical: AppSpacing.md,
                                    ),
                                  ),
                                  hint: Text(
                                    'Select destination account',
                                    style: AppTypography.bodyLarge.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                  items: provider.accounts
                                      .where((a) => a.id != _selectedAccountId)
                                      .map((account) {
                                        final bankLogo = LogoUtils.bankLogoFor(
                                          account.bankName ?? account.name,
                                        );
                                        return DropdownMenuItem<String>(
                                          value: account.id,
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  AppSpacing.xs,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: account.color
                                                      .withValues(alpha: 0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        AppSpacing.radiusSm,
                                                      ),
                                                ),
                                                child: bankLogo != null
                                                    ? LogoUtils.buildLogo(
                                                        bankLogo,
                                                        size: 16,
                                                      )
                                                    : Icon(
                                                        account.icon,
                                                        color: account.color,
                                                        size: 16,
                                                      ),
                                              ),
                                              const SizedBox(
                                                width: AppSpacing.sm,
                                              ),
                                              Text(account.name),
                                            ],
                                          ),
                                        );
                                      })
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _toAccountId = value;
                                    });
                                  },
                                  validator: (value) {
                                    if (_selectedType ==
                                            TransactionType.transfer &&
                                        value == null) {
                                      return 'Please select a destination account';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl2),
                    // Hide category for transfers
                    if (_selectedType != TransactionType.transfer) ...[
                      Text(
                        'Category',
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Consumer<CategoryProvider>(
                        builder: (context, categoryProvider, _) {
                          if (categoryProvider.isLoading) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(AppSpacing.md),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          final categories = categoryProvider.categories;
                          if (categories.isEmpty) {
                            return Text(
                              'No categories found',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            );
                          }
                          String? resolvedCategoryId = _selectedCategory;
                          final hasId = categories.any(
                            (c) => c.id == resolvedCategoryId,
                          );
                          if (!hasId) {
                            final byName = categories
                                .where((c) => c.name == resolvedCategoryId)
                                .toList();
                            resolvedCategoryId = byName.isNotEmpty
                                ? byName.first.id
                                : null;
                          }

                          final selectedColor = categories
                              .firstWhere(
                                (c) => c.id == resolvedCategoryId,
                                orElse: () => categories.first,
                              )
                              .color;
                          return AnimatedScale(
                            duration: AppAnimations.fast,
                            curve: AppAnimations.fadeOutCurve,
                            scale: _categoryHasFocus ? 1.02 : 1.0,
                            child: AnimatedOpacity(
                              duration: AppAnimations.fast,
                              curve: AppAnimations.fadeOutCurve,
                              opacity: _categoryHasFocus ? 1.0 : 0.95,
                              child: AnimatedContainer(
                                duration: AppAnimations.standard,
                                curve: AppAnimations.fadeOutCurve,
                                decoration: BoxDecoration(
                                  color: AppColors.cardElevated,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusLg,
                                  ),
                                  border: Border.all(
                                    color: _selectedCategory == null
                                        ? AppColors.cardElevated
                                        : selectedColor,
                                    width: 1.5,
                                  ),
                                  boxShadow: _selectedCategory == null
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: selectedColor.withValues(
                                              alpha: 0.2,
                                            ),
                                            blurRadius: 8,
                                          ),
                                        ],
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.xs,
                                ),
                                child: Builder(
                                  builder: (context) {
                                    // Build a custom dropdown with overlay for full control
                                    final selectedCat = (categories.isNotEmpty)
                                        ? categories.firstWhere(
                                            (c) => c.id == _selectedCategory,
                                            orElse: () => categories.first,
                                          )
                                        : null;
                                    return GestureDetector(
                                      onTap: () async {
                                        final RenderBox box =
                                            context.findRenderObject()
                                                as RenderBox;
                                        final Offset position = box
                                            .localToGlobal(Offset.zero);
                                        final selected = await showMenu<String>(
                                          context: context,
                                          position: RelativeRect.fromLTRB(
                                            position.dx,
                                            position.dy + box.size.height,
                                            position.dx + box.size.width,
                                            position.dy,
                                          ),
                                          color: AppColors.cardElevated,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppSpacing.radiusLg,
                                            ),
                                          ),
                                          items: categories.map((c) {
                                            return PopupMenuItem<String>(
                                              value: c.id,
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal:
                                                              AppSpacing.sm,
                                                          vertical:
                                                              AppSpacing.xs,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: c.color.withValues(
                                                        alpha: 0.2,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            AppSpacing.radiusSm,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      c.emoji,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: AppSpacing.sm,
                                                  ),
                                                  Text(
                                                    c.name,
                                                    style: AppTypography
                                                        .bodyLarge
                                                        .copyWith(
                                                          color: AppColors
                                                              .textPrimary,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        );
                                        if (selected != null) {
                                          setState(() {
                                            _selectedCategory = selected;
                                          });
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.lg,
                                          vertical: AppSpacing.md,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.cardElevated,
                                          borderRadius: BorderRadius.circular(
                                            AppSpacing.radiusLg,
                                          ),
                                          border: Border.all(
                                            color: _selectedCategory == null
                                                ? AppColors.textTertiary
                                                      .withValues(alpha: 0.2)
                                                : AppColors.primaryBlue
                                                      .withValues(alpha: 0.4),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.08,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            if (selectedCat != null &&
                                                _selectedCategory != null) ...[
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: AppSpacing.sm,
                                                      vertical: AppSpacing.xs,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: selectedCat.color
                                                      .withValues(alpha: 0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        AppSpacing.radiusSm,
                                                      ),
                                                ),
                                                child: Text(
                                                  selectedCat.emoji,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(
                                                width: AppSpacing.sm,
                                              ),
                                              Text(
                                                selectedCat.name,
                                                style: AppTypography.bodyLarge
                                                    .copyWith(
                                                      color:
                                                          AppColors.textPrimary,
                                                    ),
                                              ),
                                            ] else ...[
                                              Text(
                                                'Select category',
                                                style: AppTypography.bodyLarge
                                                    .copyWith(
                                                      color: AppColors
                                                          .textTertiary,
                                                    ),
                                              ),
                                            ],
                                            const Spacer(),
                                            Icon(
                                              Icons.keyboard_arrow_down,
                                              color: AppColors.textTertiary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl2),
                    ],
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
                        hintStyle: TextStyle(color: AppColors.textTertiary),
                        filled: true,
                        fillColor: AppColors.cardElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
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
                          color: AppColors.cardElevated,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
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
                          backgroundColor:
                              _selectedType == TransactionType.income
                              ? AppColors.success
                              : AppColors.primaryBlue,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : Text(
                                _isEditMode
                                    ? 'Save Changes'
                                    : 'Save Transaction',
                                style: AppTypography.titleSmall.copyWith(
                                  color: AppColors.white,
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
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  setState(() => _selectedType = TransactionType.expense),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: _selectedType == TransactionType.expense
                      ? AppColors.error
                      : AppColors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_upward,
                      color: _selectedType == TransactionType.expense
                          ? AppColors.white
                          : AppColors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Expense',
                      style: AppTypography.titleSmall.copyWith(
                        color: _selectedType == TransactionType.expense
                            ? AppColors.white
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
              onTap: () =>
                  setState(() => _selectedType = TransactionType.income),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: _selectedType == TransactionType.income
                      ? AppColors.success
                      : AppColors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_downward,
                      color: _selectedType == TransactionType.income
                          ? AppColors.white
                          : AppColors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Income',
                      style: AppTypography.titleSmall.copyWith(
                        color: _selectedType == TransactionType.income
                            ? AppColors.white
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
              onTap: () =>
                  setState(() => _selectedType = TransactionType.transfer),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: _selectedType == TransactionType.transfer
                      ? AppColors.primaryBlue
                      : AppColors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.swap_horiz,
                      color: _selectedType == TransactionType.transfer
                          ? AppColors.white
                          : AppColors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Transfer',
                      style: AppTypography.titleSmall.copyWith(
                        color: _selectedType == TransactionType.transfer
                            ? AppColors.white
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
      showTopSnackBar(context, 'Please select an account', isError: true);
      return;
    }

    // Validate destination account for transfers
    if (_selectedType == TransactionType.transfer && _toAccountId == null) {
      showTopSnackBar(
        context,
        'Please select a destination account',
        isError: true,
      );
      return;
    }

    // Validate same account for transfers
    if (_selectedType == TransactionType.transfer &&
        _selectedAccountId == _toAccountId) {
      showTopSnackBar(
        context,
        'Source and destination accounts must be different',
        isError: true,
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

      debugPrint('🔄 Creating transfer transaction:');
      debugPrint('   Type: $_selectedType');
      debugPrint('   From Account ID: $_selectedAccountId');
      debugPrint('   To Account ID: $_toAccountId');
      debugPrint('   Amount: $amount');

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
        createdAt: _isEditMode ? widget.transaction!.createdAt : now,
        updatedAt: now,
      );

      debugPrint('📝 Transaction object created:');
      debugPrint('   accountId: ${transaction.accountId}');
      debugPrint('   toAccountId: ${transaction.toAccountId}');

      final provider = context.read<TransactionProvider>();
      final success = _isEditMode
          ? await provider.updateTransaction(transaction, widget.transaction!)
          : await provider.addTransaction(transaction);

      // --- SUBSCRIPTION MATCHING AND PAYMENT ---
      if (success && mounted) {
        // If this is a subscription expense, try to match and mark as paid
        final categoryLower = _selectedCategory?.toLowerCase();
        // --- SUBSCRIPTION ---
        if (categoryLower == 'subscriptions' ||
            _selectedCategory == 'subscriptions') {
          final subscriptionProvider = context.read<SubscriptionProvider>();
          final matchResult = TransactionMatchService.analyzeTransaction(
            transaction: transaction,
            subscriptions: subscriptionProvider.subscriptions,
            debts: [],
          );
          final matches = matchResult.matches.where(
            (m) => m.type.toString().contains('subscription'),
          );
          if (matches.isNotEmpty) {
            final match = matches.first;
            final subs = subscriptionProvider.subscriptions.where(
              (s) => s.id == match.id,
            );
            if (subs.isNotEmpty) {
              final sub = subs.first;
              await subscriptionProvider.markSubscriptionPaid(sub);
              if (!mounted) {
                return;
              }
            }
          }
        }

        // --- INVESTMENT ---
        if (categoryLower == 'investment' ||
            _selectedCategory == 'investment') {
          // TODO: Implement InvestmentProvider logic
          // Example:
          // final investmentProvider = context.read<InvestmentProvider>();
          // final matchResult = TransactionMatchService.analyzeTransaction(
          //   transaction: transaction,
          //   investments: investmentProvider.investments,
          //   debts: [],
          // );
          // final matches = matchResult.matches.where((m) => m.type.toString().contains('investment'));
          // if (matches.isNotEmpty) {
          //   final match = matches.first;
          //   final invs = investmentProvider.investments.where((i) => i.id == match.id);
          //   if (invs.isNotEmpty) {
          //     final inv = invs.first;
          //     await investmentProvider.markInvestmentPaid(inv);
          //   }
          // }
        }

        // --- DEBTS ---
        if (categoryLower == 'debts' || _selectedCategory == 'debts') {
          // TODO: Implement DebtProvider logic
          // Example:
          // final debtProvider = context.read<DebtProvider>();
          // final matchResult = TransactionMatchService.analyzeTransaction(
          //   transaction: transaction,
          //   subscriptions: [],
          //   debts: debtProvider.debts,
          // );
          // final matches = matchResult.matches.where((m) => m.type.toString().contains('emi'));
          // if (matches.isNotEmpty) {
          //   final match = matches.first;
          //   final debts = debtProvider.debts.where((d) => d.id == match.id);
          //   if (debts.isNotEmpty) {
          //     final debt = debts.first;
          //     await debtProvider.markDebtPaid(debt);
          //   }
          // }
        }

        if (!mounted) {
          return;
        }
        if (widget.detectedTransaction != null) {
          context.read<NewNboxProvider>().markAsApproved(
            widget.detectedTransaction!.id,
            widget.detectedTransaction!.source,
          );
          // Check for payday checklist before popping
          if (!_isEditMode && transaction.type == TransactionType.income) {
            await PaydayChecklistHelper.checkAndShowChecklist(
              context,
              transaction: transaction,
            );
            if (!mounted) {
              return;
            }
          }
          if (!mounted) {
            return;
          }
          Navigator.of(context).pop(true);
          return;
        }

        if (!mounted) {
          return;
        }

        showTopSnackBar(
          context,
          _selectedType == TransactionType.transfer
              ? 'Transfer completed successfully!'
              : 'Transaction ${_isEditMode ? 'updated' : 'saved'} successfully!',
        );

        // Check for payday checklist for new income transactions
        if (!_isEditMode && transaction.type == TransactionType.income) {
          Navigator.of(context).pop();
          await PaydayChecklistHelper.checkAndShowChecklist(
            context,
            transaction: transaction,
          );
          if (!mounted) {
            return;
          }
        } else {
          Navigator.of(context).pop();
        }
      } else if (mounted) {
        final error = context.read<TransactionProvider>().error;
        showTopSnackBar(
          context,
          error ?? 'Failed to save transaction',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(context, 'Error: $e', isError: true);
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
