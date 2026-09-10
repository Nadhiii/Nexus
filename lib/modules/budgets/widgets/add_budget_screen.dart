import 'package:flutter/material.dart';
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

  @override
  State<ModernAddBudgetScreen> createState() => _ModernAddBudgetScreenState();
}

class _ModernAddBudgetScreenState extends State<ModernAddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _categoryNameController = TextEditingController();
  final _allocatedAmountController = TextEditingController();

  String _selectedCategoryId = 'miscellaneous';
  String _selectedPeriod = 'monthly';
  bool _isLoading = false;
  bool _showCommitments = false;
  
  bool get _isEditMode => widget.budget != null;

  // Financial commitments data
  double _totalEMIs = 0;
  double _totalSIPs = 0;
  double _totalSubscriptions = 0;
  double _recommendedGoalContribution = 0;
  int _activeDebts = 0;
  int _activeInvestments = 0;
  int _activeSubscriptions = 0;
  int _activeGoals = 0;

  final List<Map<String, dynamic>> _categories = [
    {'id': 'housing', 'name': 'Housing', 'icon': Icons.home, 'color': AppColors.info},
    {'id': 'food', 'name': 'Food', 'icon': Icons.restaurant, 'color': AppColors.green},
    {'id': 'transportation', 'name': 'Transport', 'icon': Icons.directions_car, 'color': AppColors.orange},
    {'id': 'shopping', 'name': 'Shopping', 'icon': Icons.shopping_bag, 'color': AppColors.red},
    {'id': 'entertainment', 'name': 'Fun', 'icon': Icons.movie, 'color': AppColors.accentPink},
    {'id': 'health', 'name': 'Health', 'icon': Icons.local_hospital, 'color': AppColors.accentTeal},
    {'id': 'savings', 'name': 'Savings', 'icon': Icons.savings, 'color': AppColors.accentPurple},
    {'id': 'miscellaneous', 'name': 'Misc', 'icon': Icons.more_horiz, 'color': AppColors.neutral500},
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final budget = widget.budget!;
      _selectedCategoryId = budget.categoryId;
      _categoryNameController.text = budget.categoryName;
      _allocatedAmountController.text = budget.allocatedAmount.toString();
      _selectedPeriod = budget.period;
    } else {
      _updateCategoryName();
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFinancialCommitments();
    });
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    _allocatedAmountController.dispose();
    super.dispose();
  }

  void _loadFinancialCommitments() {
    final debtProvider = context.read<DebtProvider>();
    final debts = debtProvider.debts
        .where((d) => d.currentBalance > 0 && d.monthlyEMI != null && d.monthlyEMI! > 0)
        .toList();
    _totalEMIs = debts.fold(0.0, (sum, d) => sum + (d.monthlyEMI ?? 0));
    _activeDebts = debts.length;

    final investmentProvider = context.read<InvestmentProvider>();
    final investments = investmentProvider.investments
        .where((i) => i.isActive && i.sipAmount > 0)
        .toList();
    _totalSIPs = investments.fold(0.0, (sum, i) => sum + i.sipAmount);
    _activeInvestments = investments.length;

    final subscriptionProvider = context.read<SubscriptionProvider>();
    final subscriptions = subscriptionProvider.subscriptions
        .where((s) => s.isActive)
        .toList();
    _totalSubscriptions = subscriptionProvider.totalMonthlyCost;
    _activeSubscriptions = subscriptions.length;

    final goalProvider = context.read<GoalProvider>();
    final goals = goalProvider.goals.where((g) => !g.isCompleted).toList();
    _activeGoals = goals.length;
    _recommendedGoalContribution = 0;
    
    for (final goal in goals) {
      final monthsRemaining = goal.targetDate.difference(DateTime.now()).inDays / 30;
      if (monthsRemaining > 0) {
        _recommendedGoalContribution += goal.remainingAmount / monthsRemaining;
      }
    }

    if (mounted) setState(() {});
  }

  void _updateCategoryName() {
    final cat = _categories.firstWhere(
      (c) => c['id'] == _selectedCategoryId,
      orElse: () => {'name': ''},
    );
    if (!_isEditMode) {
      _categoryNameController.text = cat['name'];
    }
  }

  bool _hasAnyCommitments() {
    return _totalEMIs > 0 || _totalSIPs > 0 || _totalSubscriptions > 0 || _recommendedGoalContribution > 0;
  }

  double get _totalCommitments => _totalEMIs + _totalSIPs + _totalSubscriptions + _recommendedGoalContribution;

  @override
  Widget build(BuildContext context) {
    final title = _isEditMode ? "Edit Budget" : "New Budget";
    
    // Retrieve the active color based on category to accent the header
    final activeCat = _categories.firstWhere((c) => c['id'] == _selectedCategoryId, orElse: () => _categories.last);
    final activeColor = activeCat['color'] as Color;

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
                    // PRIMARY AMOUNT
                    Text(
                      'Monthly Limit',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _allocatedAmountController,
                      autofocus: !_isEditMode,
                      style: AppTypography.displayMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        prefixText: '₹ ',
                        prefixStyle: AppTypography.displayMedium.copyWith(
                          color: activeColor,
                          fontWeight: FontWeight.bold,
                        ),
                        hintStyle: TextStyle(color: AppColors.textTertiary),
                        filled: true,
                        fillColor: AppColors.cardElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Limit is required';
                        if (double.tryParse(value.trim()) == null) return 'Enter a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl2),

                    // CATEGORY
                    Text(
                      'Category',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final isSelected = cat['id'] == _selectedCategoryId;
                          final catColor = cat['color'] as Color;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategoryId = cat['id'];
                                _updateCategoryName();
                              });
                            },
                            child: AnimatedContainer(
                              duration: AppAnimations.standard,
                              width: 72,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? catColor.withValues(alpha: 0.2)
                                    : AppColors.cardElevated,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                border: Border.all(
                                  color: isSelected ? catColor : Colors.transparent,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    cat['icon'],
                                    color: isSelected ? catColor : AppColors.textSecondary,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    cat['name'],
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : AppColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl2),

                    // DETAILS
                    Text(
                      'Details',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildStandardField(
                      controller: _categoryNameController,
                      hint: "Budget Name (e.g. Groceries)",
                      icon: Icons.label_outline,
                    ),

                    // COMMITMENTS CARD
                    if (!_isEditMode && _hasAnyCommitments()) ...[
                      const SizedBox(height: AppSpacing.xl2),
                      _buildFinancialCommitmentsCard(),
                    ],
                    
                    const SizedBox(height: AppSpacing.xl2),

                    // SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveBudget,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: activeColor,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                              )
                            : Text(
                                _isEditMode ? "Save Changes" : "Set Budget",
                                style: AppTypography.titleSmall.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    
                    if (_isEditMode) ...[
                      const SizedBox(height: AppSpacing.md),
                      Center(
                        child: TextButton.icon(
                          onPressed: _isLoading ? null : _deleteBudget,
                          icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                          label: const Text(
                            'Delete Budget',
                            style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                    
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

  Widget _buildStandardField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.cardElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.sm),
          child: Icon(icon, color: AppColors.textSecondary, size: 20),
        ),
      ),
      validator: (value) => (value == null || value.isEmpty) ? "Required" : null,
    );
  }

  Widget _buildFinancialCommitmentsCard() {
    return GestureDetector(
      onTap: () => setState(() => _showCommitments = !_showCommitments),
      child: AnimatedContainer(
        duration: AppAnimations.slow,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accentPurple.withValues(alpha: 0.15),
              AppColors.cardElevated,
            ],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.accentPurple.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.insights_rounded, color: AppColors.accentPurple, size: 18),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Monthly Commitments',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${_formatAmount(_totalCommitments)}/month already allocated',
                        style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _showCommitments ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
              ],
            ),
            if (_showCommitments) ...[
              const SizedBox(height: 16),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
              const SizedBox(height: 16),
              if (_totalEMIs > 0) _buildCommitmentRow(Icons.account_balance, 'EMIs & Loans', _activeDebts, _totalEMIs, Colors.orange),
              if (_totalSIPs > 0) _buildCommitmentRow(Icons.trending_up, 'SIP Investments', _activeInvestments, _totalSIPs, AppColors.success),
              if (_totalSubscriptions > 0) _buildCommitmentRow(Icons.subscriptions_rounded, 'Subscriptions', _activeSubscriptions, _totalSubscriptions, AppColors.accentPink),
              if (_recommendedGoalContribution > 0) _buildCommitmentRow(Icons.flag_rounded, 'Goals (suggested)', _activeGoals, _recommendedGoalContribution, AppColors.info),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: AppColors.warning, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Consider these commitments when setting your budget limit.',
                        style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCommitmentRow(IconData icon, String label, int count, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                Text('$count active', style: TextStyle(color: AppColors.textTertiary, fontSize: 10)),
              ],
            ),
          ),
          Text(
            '₹${_formatAmount(amount)}',
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) return '${(amount / 10000000).toStringAsFixed(1)}Cr';
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final end = DateTime(now.year, now.month + 1, 0);

      final budget = Budget(
        id: _isEditMode ? widget.budget!.id : '',
        categoryId: _selectedCategoryId,
        categoryName: _categoryNameController.text.trim(),
        allocatedAmount: double.parse(_allocatedAmountController.text),
        spentAmount: _isEditMode ? widget.budget!.spentAmount : 0.0,
        period: _selectedPeriod,
        startDate: now,
        endDate: end,
        accountId: 'default',
        isActive: true,
        createdAt: _isEditMode ? widget.budget!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final provider = Provider.of<BudgetProvider>(context, listen: false);
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

  Future<void> _deleteBudget() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<BudgetProvider>(context, listen: false).deleteBudget(widget.budget!.id);
      if (mounted) {
        Navigator.pop(context);
        showTopSnackBar(context, 'Budget deleted');
      }
    } catch (e) {
      if (mounted) showTopSnackBar(context, 'Error: $e', isError: true);
      setState(() => _isLoading = false);
    }
  }
}

// Global Nav Helpers
Future<void> navToAddBudgetScreen(BuildContext context, {Budget? budget}) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, _, _) => ModernAddBudgetScreen(budget: budget),
    ),
  );
}

// Keep this helper name to minimize changes in your files
Future<void> showAddBudgetModal(BuildContext context, {Budget? budget}) => navToAddBudgetScreen(context, budget: budget);


// --- Smart Quick Setup Modal (Kept as Dialog to maintain Wizard flow) ---

Future<void> showQuickSetupModal(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => const SmartQuickSetupModal(),
  );
}

class SmartQuickSetupModal extends StatefulWidget {
  const SmartQuickSetupModal({super.key});

  @override
  State<SmartQuickSetupModal> createState() => _SmartQuickSetupModalState();
}

class _SmartQuickSetupModalState extends State<SmartQuickSetupModal> {
  final _incomeController = TextEditingController();
  bool _isLoading = false;
  bool _showBreakdown = false;

  double _totalEMIs = 0;
  double _totalSIPs = 0;
  double _totalSubscriptions = 0;
  double _recommendedGoalContribution = 0;
  int _activeDebts = 0;
  int _activeInvestments = 0;
  int _activeSubscriptions = 0;
  int _activeGoals = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCommitments();
    });
  }

  void _loadCommitments() {
    final debtProvider = context.read<DebtProvider>();
    final debts = debtProvider.debts.where((d) => d.currentBalance > 0 && d.monthlyEMI != null && d.monthlyEMI! > 0).toList();
    _totalEMIs = debts.fold(0.0, (sum, d) => sum + (d.monthlyEMI ?? 0));
    _activeDebts = debts.length;

    final investmentProvider = context.read<InvestmentProvider>();
    final investments = investmentProvider.investments.where((i) => i.isActive && i.sipAmount > 0).toList();
    _totalSIPs = investments.fold(0.0, (sum, i) => sum + i.sipAmount);
    _activeInvestments = investments.length;

    final subscriptionProvider = context.read<SubscriptionProvider>();
    final subscriptions = subscriptionProvider.subscriptions.where((s) => s.isActive).toList();
    _totalSubscriptions = subscriptionProvider.totalMonthlyCost;
    _activeSubscriptions = subscriptions.length;

    final goalProvider = context.read<GoalProvider>();
    final goals = goalProvider.goals.where((g) => !g.isCompleted).toList();
    _activeGoals = goals.length;
    _recommendedGoalContribution = 0;
    for (final goal in goals) {
      final monthsRemaining = goal.targetDate.difference(DateTime.now()).inDays / 30;
      if (monthsRemaining > 0) {
        _recommendedGoalContribution += goal.remainingAmount / monthsRemaining;
      }
    }

    if (mounted) setState(() {});
  }

  double get _totalCommitments => _totalEMIs + _totalSIPs + _totalSubscriptions;
  bool get _hasCommitments => _totalCommitments > 0;

  String _formatAmount(double amount) {
    if (amount >= 10000000) return '${(amount / 10000000).toStringAsFixed(1)}Cr';
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.backgroundBlack,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.accentPurple, AppColors.accentPink]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quick Budget', style: AppTypography.headlineSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('Considers your existing commitments', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: AppColors.textTertiary, size: 20),
                  ),
                ],
              ),
              if (_hasCommitments) ...[
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => setState(() => _showBreakdown = !_showBreakdown),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.orange.withValues(alpha: 0.15), AppColors.cardSurface],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'You have ₹${_formatAmount(_totalCommitments)}/month in fixed commitments',
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                            Icon(_showBreakdown ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.textTertiary),
                          ],
                        ),
                        if (_showBreakdown) ...[
                          const SizedBox(height: 12),
                          Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
                          const SizedBox(height: 12),
                          if (_totalEMIs > 0) _buildSmallCommitmentRow(Icons.account_balance, 'EMIs', _activeDebts, _totalEMIs, Colors.orange),
                          if (_totalSIPs > 0) _buildSmallCommitmentRow(Icons.trending_up, 'SIPs', _activeInvestments, _totalSIPs, AppColors.success),
                          if (_totalSubscriptions > 0) _buildSmallCommitmentRow(Icons.subscriptions, 'Subscriptions', _activeSubscriptions, _totalSubscriptions, AppColors.accentPink),
                          if (_recommendedGoalContribution > 0) _buildSmallCommitmentRow(Icons.flag, 'Goals (suggested)', _activeGoals, _recommendedGoalContribution, AppColors.info),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: const Text('Monthly Income', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardElevated,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: TextField(
                  controller: _incomeController,
                  keyboardType: TextInputType.number,
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Enter amount',
                    hintStyle: TextStyle(color: AppColors.textTertiary),
                    filled: true,
                    fillColor: AppColors.cardElevated,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    prefixIcon: const Icon(Icons.currency_rupee, color: AppColors.accentPurple),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (_incomeController.text.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildBudgetPreview(),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _runSmartSetup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome, size: 18),
                            SizedBox(width: 8),
                            Text('Create Budgets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Will create ${_hasCommitments ? 'commitment-aware' : 'standard'} 50/30/20 budgets',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallCommitmentRow(IconData icon, String label, int count, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const Spacer(),
          Text('$count', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
          const SizedBox(width: 8),
          Text('₹${_formatAmount(amount)}', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildBudgetPreview() {
    final income = double.tryParse(_incomeController.text) ?? 0;
    if (income <= 0) return const SizedBox.shrink();

    final availableForBudgets = income - _totalCommitments;
    final isNegative = availableForBudgets <= 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isNegative ? AppColors.error.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (isNegative ? AppColors.error : AppColors.success).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isNegative ? Icons.warning : Icons.check_circle, color: isNegative ? AppColors.error : AppColors.success, size: 16),
              const SizedBox(width: 8),
              Text(
                isNegative ? 'Commitments exceed income!' : 'Available for budgets',
                style: TextStyle(color: isNegative ? AppColors.error : AppColors.success, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (!isNegative) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Needs (50%)', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                Text('₹${_formatAmount(availableForBudgets * 0.5)}', style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Wants (30%)', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                Text('₹${_formatAmount(availableForBudgets * 0.3)}', style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Savings (20%)', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                Text('₹${_formatAmount(availableForBudgets * 0.2)}', style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _runSmartSetup() async {
    final income = double.tryParse(_incomeController.text);
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
        Budget(id: '', categoryId: 'housing', categoryName: 'Housing & Rent', allocatedAmount: needsAmount * 0.30, period: 'monthly', startDate: now, endDate: endDate, accountId: '', isActive: true, createdAt: now, updatedAt: now),
        Budget(id: '', categoryId: 'food', categoryName: 'Food & Groceries', allocatedAmount: needsAmount * 0.40, period: 'monthly', startDate: now, endDate: endDate, accountId: '', isActive: true, createdAt: now, updatedAt: now),
        Budget(id: '', categoryId: 'transportation', categoryName: 'Transportation', allocatedAmount: needsAmount * 0.20, period: 'monthly', startDate: now, endDate: endDate, accountId: '', isActive: true, createdAt: now, updatedAt: now),
        Budget(id: '', categoryId: 'health', categoryName: 'Health & Utilities', allocatedAmount: needsAmount * 0.10, period: 'monthly', startDate: now, endDate: endDate, accountId: '', isActive: true, createdAt: now, updatedAt: now),
        Budget(id: '', categoryId: 'entertainment', categoryName: 'Entertainment', allocatedAmount: wantsAmount * 0.50, period: 'monthly', startDate: now, endDate: endDate, accountId: '', isActive: true, createdAt: now, updatedAt: now),
        Budget(id: '', categoryId: 'shopping', categoryName: 'Shopping & Personal', allocatedAmount: wantsAmount * 0.50, period: 'monthly', startDate: now, endDate: endDate, accountId: '', isActive: true, createdAt: now, updatedAt: now),
        if (_totalSIPs < savingsAmount * 0.5)
          Budget(id: '', categoryId: 'savings', categoryName: 'Savings & Emergency', allocatedAmount: savingsAmount - _totalSIPs.clamp(0, savingsAmount * 0.5), period: 'monthly', startDate: now, endDate: endDate, accountId: '', isActive: true, createdAt: now, updatedAt: now),
      ];

      for (final budget in budgets) {
        await budgetProvider.createBudget(budget);
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
}