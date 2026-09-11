import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/providers/budget_provider.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/providers/investment_provider.dart';
import '../../../core/providers/debt_provider.dart';
import '../../../core/providers/goal_provider.dart';
import '../../../core/models/budget.dart';
import '../../../core/widgets/top_snackbar.dart';

export '../../../core/models/budget.dart';

class ModernAddBudgetScreen extends StatefulWidget {
  final Budget? budget;

  const ModernAddBudgetScreen({super.key, this.budget});

  static Future<void> show(BuildContext context, {Budget? budget}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => ModernAddBudgetScreen(budget: budget),
    );
  }

  @override
  State<ModernAddBudgetScreen> createState() => _ModernAddBudgetScreenState();
}

class _ModernAddBudgetScreenState extends State<ModernAddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _categoryNameController = TextEditingController();
  final _allocatedAmountController = TextEditingController();

  String _selectedCategoryId = 'housing';
  final String _selectedPeriod = 'monthly';
  bool _isLoading = false;
  bool _showCommitments = false;

  bool get _isEditMode => widget.budget != null;

  double _totalEMIs = 0;
  double _totalSIPs = 0;
  double _totalSubscriptions = 0;
  double _recommendedGoalContribution = 0;

  final List<Map<String, dynamic>> _categories = [
    {'id': 'housing', 'name': 'Housing', 'icon': Icons.home_outlined, 'color': AppColors.info},
    {'id': 'food', 'name': 'Food', 'icon': Icons.restaurant_outlined, 'color': AppColors.success},
    {'id': 'transportation', 'name': 'Transport', 'icon': Icons.directions_car_outlined, 'color': AppColors.warning},
    {'id': 'shopping', 'name': 'Shopping', 'icon': Icons.shopping_bag_outlined, 'color': AppColors.error},
    {'id': 'entertainment', 'name': 'Entertainment', 'icon': Icons.movie_outlined, 'color': AppColors.accentPink},
    {'id': 'health', 'name': 'Health', 'icon': Icons.local_hospital_outlined, 'color': AppColors.accentTeal},
    {'id': 'savings', 'name': 'Savings', 'icon': Icons.savings_outlined, 'color': AppColors.accentPurple},
    {'id': 'miscellaneous', 'name': 'Misc', 'icon': Icons.more_horiz_outlined, 'color': AppColors.textSecondary},
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final b = widget.budget!;
      _selectedCategoryId = b.categoryId;
      _categoryNameController.text = b.categoryName;
      _allocatedAmountController.text = b.allocatedAmount.toStringAsFixed(0);
    } else {
      _updateCategoryName();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCommitments());
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    _allocatedAmountController.dispose();
    super.dispose();
  }

  void _loadCommitments() {
    final debtProvider = context.read<DebtProvider>();
    final debts = debtProvider.debts
        .where((d) => d.currentBalance > 0 && d.monthlyEMI != null && d.monthlyEMI! > 0)
        .toList();
    _totalEMIs = debts.fold(0.0, (sum, d) => sum + (d.monthlyEMI ?? 0));

    final invProvider = context.read<InvestmentProvider>();
    final invs = invProvider.investments.where((i) => i.isActive && i.sipAmount > 0).toList();
    _totalSIPs = invs.fold(0.0, (sum, i) => sum + i.sipAmount);

    final subProvider = context.read<SubscriptionProvider>();
    _totalSubscriptions = subProvider.totalMonthlyCost;

    final goalProvider = context.read<GoalProvider>();
    final goals = goalProvider.goals.where((g) => !g.isCompleted).toList();
    _recommendedGoalContribution = 0;
    for (final g in goals) {
      final months = g.targetDate.difference(DateTime.now()).inDays / 30;
      if (months > 0) _recommendedGoalContribution += g.remainingAmount / months;
    }
    if (mounted) setState(() {});
  }

  void _updateCategoryName() {
    final cat = _categories.firstWhere(
      (c) => c['id'] == _selectedCategoryId,
      orElse: () => _categories.first,
    );
    if (!_isEditMode) {
      _categoryNameController.text = cat['name'];
    }
  }

  double get _totalCommitments =>
      _totalEMIs + _totalSIPs + _totalSubscriptions + _recommendedGoalContribution;

  void _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final end = DateTime(now.year, now.month + 1, 0);

      final budget = Budget(
        id: _isEditMode ? widget.budget!.id : '',
        categoryId: _selectedCategoryId,
        categoryName: _categoryNameController.text.trim(),
        allocatedAmount: double.parse(_allocatedAmountController.text.trim()),
        spentAmount: _isEditMode ? widget.budget!.spentAmount : 0.0,
        period: _selectedPeriod,
        startDate: now,
        endDate: end,
        accountId: 'default',
        isActive: true,
        createdAt: _isEditMode ? widget.budget!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final provider = context.read<BudgetProvider>();
      if (_isEditMode) {
        await provider.updateBudget(budget);
      } else {
        await provider.createBudget(budget);
      }

      if (mounted) {
        Navigator.pop(context);
        showTopSnackBar(context, 'Budget saved successfully');
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
    final activeCat = _categories.firstWhere(
      (c) => c['id'] == _selectedCategoryId,
      orElse: () => _categories.first,
    );
    final activeColor = activeCat['color'] as Color;

    return Material(
      color: AppColors.darkSurface,
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
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
                      _isEditMode ? "Edit Budget" : "New Budget",
                      style: AppTypography.headlineMedium.copyWith(color: AppColors.textPrimary),
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
                const SizedBox(height: AppSpacing.xl),

                _buildLabel('MONTHLY SPENDING LIMIT'),
                TextFormField(
                  controller: _allocatedAmountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: AppTypography.currencyMedium.copyWith(color: activeColor),
                  decoration: InputDecoration(
                    hintText: "0.00",
                    hintStyle: AppTypography.currencyMedium.copyWith(color: AppColors.textTertiary),
                    prefixText: "₹ ",
                    prefixStyle: AppTypography.currencyMedium.copyWith(color: activeColor),
                    filled: true,
                    fillColor: AppColors.darkSurfaceElevated,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusSm,
                      borderSide: const BorderSide(color: AppColors.borderSubtleDark),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusSm,
                      borderSide: const BorderSide(color: AppColors.borderSubtleDark),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusSm,
                      borderSide: BorderSide(color: activeColor, width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return "Limit is required";
                    if (double.tryParse(val.trim()) == null) return "Enter a valid amount";
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                _buildLabel('CATEGORY'),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = cat['id'] == _selectedCategoryId;
                    final color = cat['color'] as Color;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedCategoryId = cat['id'];
                          _updateCategoryName();
                        });
                      },
                      child: AnimatedContainer(
                        duration: AppAnimations.standard,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.15)
                              : AppColors.darkSurfaceElevated,
                          borderRadius: AppSpacing.borderRadiusSm,
                          border: Border.all(
                            color: isSelected ? color : AppColors.borderSubtleDark,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              cat['icon'],
                              color: isSelected ? color : AppColors.textSecondary,
                              size: 22,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cat['name'],
                              style: AppTypography.labelSmall.copyWith(
                                color: isSelected ? color : AppColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                _buildLabel('BUDGET NAME'),
                TextFormField(
                  controller: _categoryNameController,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: "e.g. Groceries, Dine Out",
                    hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                    filled: true,
                    fillColor: AppColors.darkSurfaceElevated,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.sm),
                      child: Icon(Icons.label_outline, color: AppColors.textSecondary, size: 20),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusSm,
                      borderSide: const BorderSide(color: AppColors.borderSubtleDark),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusSm,
                      borderSide: const BorderSide(color: AppColors.borderSubtleDark),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusSm,
                      borderSide: BorderSide(color: activeColor, width: 1.5),
                    ),
                  ),
                  validator: (val) =>
                      (val == null || val.trim().isEmpty) ? "Name is required" : null,
                ),

                if (!_isEditMode && _totalCommitments > 0) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _buildCommitmentsWidget(),
                ],

                const SizedBox(height: AppSpacing.xl2),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          backgroundColor: AppColors.darkSurfaceElevated,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppSpacing.borderRadiusSm,
                            side: const BorderSide(color: AppColors.borderSubtleDark),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveBudget,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
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
                                _isEditMode ? 'Save Changes' : 'Set Budget',
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

  Widget _buildCommitmentsWidget() {
    return GestureDetector(
      onTap: () => setState(() => _showCommitments = !_showCommitments),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.darkSurfaceElevated,
          borderRadius: AppSpacing.borderRadiusSm,
          border: Border.all(color: AppColors.borderSubtleDark),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    "₹${_totalCommitments.toStringAsFixed(0)} allocated in commitments",
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  _showCommitments ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
            if (_showCommitments) ...[
              const SizedBox(height: AppSpacing.sm),
              if (_totalEMIs > 0) _buildCommitmentDetail("EMIs", _totalEMIs),
              if (_totalSIPs > 0) _buildCommitmentDetail("SIP Investments", _totalSIPs),
              if (_totalSubscriptions > 0) _buildCommitmentDetail("Subscriptions", _totalSubscriptions),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCommitmentDetail(String title, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTypography.caption),
          Text(
            "₹${amount.toStringAsFixed(0)}",
            style: AppTypography.caption.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SMART QUICK SETUP BOTTOM SHEET (Replaces the old popup dialog)
// ═══════════════════════════════════════════════════════════════════════════

class SmartQuickSetupSheet extends StatefulWidget {
  const SmartQuickSetupSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => const SmartQuickSetupSheet(),
    );
  }

  @override
  State<SmartQuickSetupSheet> createState() => _SmartQuickSetupSheetState();
}

class _SmartQuickSetupSheetState extends State<SmartQuickSetupSheet> {
  final _incomeController = TextEditingController();
  bool _isLoading = false;
  bool _showBreakdown = false;

  double _totalEMIs = 0;
  double _totalSIPs = 0;
  double _totalSubscriptions = 0;
  double _recommendedGoalContribution = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCommitments());
  }

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  void _loadCommitments() {
    final debtProvider = context.read<DebtProvider>();
    final debts = debtProvider.debts
        .where((d) => d.currentBalance > 0 && d.monthlyEMI != null && d.monthlyEMI! > 0)
        .toList();
    _totalEMIs = debts.fold(0.0, (sum, d) => sum + (d.monthlyEMI ?? 0));

    final invProvider = context.read<InvestmentProvider>();
    final invs = invProvider.investments.where((i) => i.isActive && i.sipAmount > 0).toList();
    _totalSIPs = invs.fold(0.0, (sum, i) => sum + i.sipAmount);

    final subProvider = context.read<SubscriptionProvider>();
    _totalSubscriptions = subProvider.totalMonthlyCost;

    final goalProvider = context.read<GoalProvider>();
    final goals = goalProvider.goals.where((g) => !g.isCompleted).toList();
    _recommendedGoalContribution = 0;
    for (final g in goals) {
      final months = g.targetDate.difference(DateTime.now()).inDays / 30;
      if (months > 0) _recommendedGoalContribution += g.remainingAmount / months;
    }
    if (mounted) setState(() {});
  }

  double get _totalCommitments =>
      _totalEMIs + _totalSIPs + _totalSubscriptions + _recommendedGoalContribution;

  void _runSmartSetup() async {
    final income = double.tryParse(_incomeController.text.trim());
    if (income == null || income <= 0) {
      showTopSnackBar(context, 'Please enter a valid income', isError: true);
      return;
    }

    final availableForBudgets = income - _totalCommitments;
    if (availableForBudgets <= 0) {
      showTopSnackBar(context, 'Your commitments exceed your income!', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final budgetProvider = context.read<BudgetProvider>();
      final now = DateTime.now();
      final endDate = DateTime(now.year, now.month + 1, 0);

      final needsAmount = availableForBudgets * 0.50;
      final wantsAmount = availableForBudgets * 0.30;
      final savingsAmount = availableForBudgets * 0.20;

      final budgets = [
        Budget(
          id: '',
          categoryId: 'housing',
          categoryName: 'Housing & Rent',
          allocatedAmount: needsAmount * 0.30,
          period: 'monthly',
          startDate: now,
          endDate: endDate,
          accountId: '',
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
        Budget(
          id: '',
          categoryId: 'food',
          categoryName: 'Food & Groceries',
          allocatedAmount: needsAmount * 0.40,
          period: 'monthly',
          startDate: now,
          endDate: endDate,
          accountId: '',
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
        Budget(
          id: '',
          categoryId: 'transportation',
          categoryName: 'Transportation',
          allocatedAmount: needsAmount * 0.20,
          period: 'monthly',
          startDate: now,
          endDate: endDate,
          accountId: '',
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
        Budget(
          id: '',
          categoryId: 'health',
          categoryName: 'Health & Utilities',
          allocatedAmount: needsAmount * 0.10,
          period: 'monthly',
          startDate: now,
          endDate: endDate,
          accountId: '',
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
        Budget(
          id: '',
          categoryId: 'entertainment',
          categoryName: 'Entertainment',
          allocatedAmount: wantsAmount * 0.50,
          period: 'monthly',
          startDate: now,
          endDate: endDate,
          accountId: '',
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
        Budget(
          id: '',
          categoryId: 'shopping',
          categoryName: 'Shopping & Personal',
          allocatedAmount: wantsAmount * 0.50,
          period: 'monthly',
          startDate: now,
          endDate: endDate,
          accountId: '',
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
        if (_totalSIPs < savingsAmount * 0.5)
          Budget(
            id: '',
            categoryId: 'savings',
            categoryName: 'Savings & Emergency',
            allocatedAmount: savingsAmount - _totalSIPs.clamp(0, savingsAmount * 0.5),
            period: 'monthly',
            startDate: now,
            endDate: endDate,
            accountId: '',
            isActive: true,
            createdAt: now,
            updatedAt: now,
          ),
      ];

      for (final b in budgets) {
        await budgetProvider.createBudget(b);
      }

      if (mounted) {
        Navigator.pop(context);
        showTopSnackBar(context, 'Budgets created successfully!');
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

    return Material(
      color: AppColors.darkSurface,
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xl + bottomInset,
        ),
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
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.accentPurple, size: 22),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Quick Budget Setup',
                        style: AppTypography.headlineMedium.copyWith(color: AppColors.textPrimary),
                      ),
                    ],
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
              const SizedBox(height: 4),
              Text(
                'Calculates standard 50/30/20 budgets after your commitments',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
              ),
              const SizedBox(height: AppSpacing.xl),

              if (_totalCommitments > 0) ...[
                GestureDetector(
                  onTap: () => setState(() => _showBreakdown = !_showBreakdown),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: AppSpacing.borderRadiusSm,
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            "₹${_totalCommitments.toStringAsFixed(0)}/mo in fixed commitments",
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          _showBreakdown ? Icons.expand_less : Icons.expand_more,
                          color: AppColors.warning,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              Text(
                'MONTHLY TAKE-HOME INCOME',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _incomeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTypography.currencyMedium.copyWith(color: AppColors.accentPurple),
                decoration: InputDecoration(
                  hintText: "0.00",
                  hintStyle: AppTypography.currencyMedium.copyWith(color: AppColors.textTertiary),
                  prefixText: "₹ ",
                  prefixStyle: AppTypography.currencyMedium.copyWith(color: AppColors.accentPurple),
                  filled: true,
                  fillColor: AppColors.darkSurfaceElevated,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppSpacing.borderRadiusSm,
                    borderSide: const BorderSide(color: AppColors.borderSubtleDark),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppSpacing.borderRadiusSm,
                    borderSide: const BorderSide(color: AppColors.borderSubtleDark),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusSm)),
                    borderSide: BorderSide(color: AppColors.accentPurple, width: 1.5),
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
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        backgroundColor: AppColors.darkSurfaceElevated,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSpacing.borderRadiusSm,
                          side: const BorderSide(color: AppColors.borderSubtleDark),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _runSmartSetup,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        backgroundColor: AppColors.accentPurple,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSpacing.borderRadiusSm,
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Generate Budgets',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GLOBAL HELPERS & BACKWARD COMPATIBILITY
// ═══════════════════════════════════════════════════════════════════════════

Future<void> navToAddBudgetScreen(BuildContext context, {Budget? budget}) {
  return ModernAddBudgetScreen.show(context, budget: budget);
}

Future<void> showAddBudgetModal(BuildContext context, {Budget? budget}) =>
    navToAddBudgetScreen(context, budget: budget);

Future<void> showQuickSetupModal(BuildContext context) {
  return SmartQuickSetupSheet.show(context);
}

typedef SmartQuickSetupModal = SmartQuickSetupSheet;