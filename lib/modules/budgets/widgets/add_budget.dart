import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_animations.dart';
import 'dart:ui';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/budget_provider.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/providers/investment_provider.dart';
import '../../../core/providers/debt_provider.dart';
import '../../../core/providers/goal_provider.dart';
import '../../../core/models/budget.dart';
export '../../../core/models/budget.dart';
import '../../../core/widgets/top_snackbar.dart';

class AddBudgetModal extends StatefulWidget {
  final Budget? budget;

  const AddBudgetModal({super.key, this.budget});

  @override
  State<AddBudgetModal> createState() => _AddBudgetModalState();
}

class _AddBudgetModalState extends State<AddBudgetModal>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppAnimations.slow,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AppAnimations.fadeOutCurve,
      ),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AppAnimations.fadeInCurve,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundBlack,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: AddBudgetForm(
                      onDismiss: () => Navigator.pop(context),
                      budget: widget.budget,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddBudgetForm extends StatefulWidget {
  final VoidCallback onDismiss;
  final Budget? budget;

  const AddBudgetForm({super.key, required this.onDismiss, this.budget});

  @override
  State<AddBudgetForm> createState() => _AddBudgetFormState();
}

class _AddBudgetFormState extends State<AddBudgetForm> {
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
    {
      'id': 'housing',
      'name': 'Housing',
      'icon': Icons.home,
      'color': AppColors.info,
    },
    {
      'id': 'food',
      'name': 'Food',
      'icon': Icons.restaurant,
      'color': AppColors.green,
    },
    {
      'id': 'transportation',
      'name': 'Transport',
      'icon': Icons.directions_car,
      'color': AppColors.orange,
    },
    {
      'id': 'shopping',
      'name': 'Shopping',
      'icon': Icons.shopping_bag,
      'color': AppColors.red,
    },
    {
      'id': 'entertainment',
      'name': 'Fun',
      'icon': Icons.movie,
      'color': AppColors.accentPink,
    },
    {
      'id': 'health',
      'name': 'Health',
      'icon': Icons.local_hospital,
      'color': AppColors.accentTeal,
    },
    {
      'id': 'savings',
      'name': 'Savings',
      'icon': Icons.savings,
      'color': AppColors.accentPurple,
    },
    {
      'id': 'miscellaneous',
      'name': 'Misc',
      'icon': Icons.more_horiz,
      'color': AppColors.neutral500,
    },
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
    // Load financial commitments after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFinancialCommitments();
    });
  }

  void _loadFinancialCommitments() {
    // Get debts (EMIs)
    final debtProvider = context.read<DebtProvider>();
    final debts = debtProvider.debts
        .where(
          (d) =>
              d.currentBalance > 0 && d.monthlyEMI != null && d.monthlyEMI! > 0,
        )
        .toList();
    _totalEMIs = debts.fold(0.0, (sum, d) => sum + (d.monthlyEMI ?? 0));
    _activeDebts = debts.length;

    // Get investments (SIPs)
    final investmentProvider = context.read<InvestmentProvider>();
    final investments = investmentProvider.investments
        .where((i) => i.isActive && i.sipAmount > 0)
        .toList();
    _totalSIPs = investments.fold(0.0, (sum, i) => sum + i.sipAmount);
    _activeInvestments = investments.length;

    // Get subscriptions
    final subscriptionProvider = context.read<SubscriptionProvider>();
    final subscriptions = subscriptionProvider.subscriptions
        .where((s) => s.isActive)
        .toList();
    _totalSubscriptions = subscriptionProvider.totalMonthlyCost;
    _activeSubscriptions = subscriptions.length;

    // Get goals (calculate recommended monthly contribution)
    final goalProvider = context.read<GoalProvider>();
    final goals = goalProvider.goals.where((g) => !g.isCompleted).toList();
    _activeGoals = goals.length;
    _recommendedGoalContribution = 0;
    for (final goal in goals) {
      final monthsRemaining =
          goal.targetDate.difference(DateTime.now()).inDays / 30;
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isEditMode ? 'Edit Budget' : 'Create Budget',
                style: AppTypography.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: widget.onDismiss,
                icon: const Icon(Icons.close, color: Colors.white54),
              ),
            ],
          ),
        ),

        // Body
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('CATEGORY'),
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = cat['id'] == _selectedCategoryId;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategoryId = cat['id'];
                              _updateCategoryName();
                            });
                          },
                          child: AnimatedContainer(
                            duration: AppAnimations.standard,
                            width: 64,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (cat['color'] as Color).withOpacity(0.2)
                                  : AppColors.cardSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? (cat['color'] as Color)
                                    : Colors.white.withOpacity(0.05),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  cat['icon'],
                                  color: isSelected
                                      ? (cat['color'] as Color)
                                      : Colors.white54,
                                  size: 24,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  cat['name'],
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white54,
                                    fontSize: 10,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
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

                  const SizedBox(height: 24),
                  _buildLabel('DETAILS'),
                  _buildGlassTextField(
                    label: 'Budget Name',
                    controller: _categoryNameController,
                    icon: Icons.label_outline,
                  ),

                  const SizedBox(height: 16),
                  _buildGlassTextField(
                    label: 'Limit Amount (₹)',
                    controller: _allocatedAmountController,
                    icon: Icons.currency_rupee,
                    isNumber: true,
                  ),

                  // Financial Commitments Section
                  if (!_isEditMode && _hasAnyCommitments()) ...[
                    const SizedBox(height: 24),
                    _buildFinancialCommitmentsCard(),
                  ],

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveBudget,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cardSurface,
                        foregroundColor: AppColors.accentPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: BorderSide(
                            color: AppColors.accentPurple.withOpacity(0.3),
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accentPurple,
                              ),
                            )
                          : Text(
                              _isEditMode ? 'Update' : 'Set Budget',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  if (_isEditMode) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: _deleteBudget,
                        child: const Text(
                          'Delete Budget',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textTertiary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isNumber = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(30), // Pill Shape
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.textTertiary),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Icon(icon, color: AppColors.textSecondary),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        validator: (value) => value!.isEmpty ? 'Required' : null,
      ),
    );
  }

  bool _hasAnyCommitments() {
    return _totalEMIs > 0 ||
        _totalSIPs > 0 ||
        _totalSubscriptions > 0 ||
        _recommendedGoalContribution > 0;
  }

  double get _totalCommitments =>
      _totalEMIs +
      _totalSIPs +
      _totalSubscriptions +
      _recommendedGoalContribution;

  Widget _buildFinancialCommitmentsCard() {
    return GestureDetector(
      onTap: () => setState(() => _showCommitments = !_showCommitments),
      child: AnimatedContainer(
        duration: AppAnimations.slow,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accentPurple.withOpacity(0.15),
              AppColors.cardSurface,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accentPurple.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.insights_rounded,
                    color: AppColors.accentPurple,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Monthly Commitments',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${_formatAmount(_totalCommitments)}/month already allocated',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _showCommitments
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
              ],
            ),
            if (_showCommitments) ...[
              const SizedBox(height: 16),
              Container(height: 1, color: Colors.white.withOpacity(0.05)),
              const SizedBox(height: 16),
              // EMIs
              if (_totalEMIs > 0)
                _buildCommitmentRow(
                  icon: Icons.account_balance,
                  label: 'EMIs & Loans',
                  count: _activeDebts,
                  amount: _totalEMIs,
                  color: Colors.orange,
                ),
              // SIPs
              if (_totalSIPs > 0)
                _buildCommitmentRow(
                  icon: Icons.trending_up,
                  label: 'SIP Investments',
                  count: _activeInvestments,
                  amount: _totalSIPs,
                  color: AppColors.success,
                ),
              // Subscriptions
              if (_totalSubscriptions > 0)
                _buildCommitmentRow(
                  icon: Icons.subscriptions_rounded,
                  label: 'Subscriptions',
                  count: _activeSubscriptions,
                  amount: _totalSubscriptions,
                  color: AppColors.accentPink,
                ),
              // Goals
              if (_recommendedGoalContribution > 0)
                _buildCommitmentRow(
                  icon: Icons.flag_rounded,
                  label: 'Goals (suggested)',
                  count: _activeGoals,
                  amount: _recommendedGoalContribution,
                  color: AppColors.info,
                ),
              const SizedBox(height: 12),
              // Suggestion
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.warning,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Consider these commitments when setting your budget limit.',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
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

  Widget _buildCommitmentRow({
    required IconData icon,
    required String label,
    required int count,
    required double amount,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$count active',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 10),
                ),
              ],
            ),
          ),
          Text(
            '₹${_formatAmount(amount)}',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // Basic Budget Logic ...
      // In a real app, calculate dates based on 'period'
      final now = DateTime.now();
      final end = DateTime(now.year, now.month + 1, 0);

      final budget = Budget(
        id: _isEditMode ? widget.budget!.id : '',
        categoryId: _selectedCategoryId,
        categoryName: _categoryNameController.text.trim(),
        allocatedAmount: double.parse(_allocatedAmountController.text),
        spentAmount: _isEditMode ? widget.budget!.spentAmount : 0.0,
        period: _selectedPeriod,
        startDate: now, // Simplified
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
        widget.onDismiss();
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
      await Provider.of<BudgetProvider>(
        context,
        listen: false,
      ).deleteBudget(widget.budget!.id);
      if (mounted) {
        widget.onDismiss();
        showTopSnackBar(context, 'Budget deleted');
      }
    } catch (e) {
      if (mounted) showTopSnackBar(context, 'Error: $e', isError: true);
      setState(() => _isLoading = false);
    }
  }
}

// --- Smart Quick Setup Modal ---
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

  // Financial commitments
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
    // Get debts (EMIs)
    final debtProvider = context.read<DebtProvider>();
    final debts = debtProvider.debts
        .where(
          (d) =>
              d.currentBalance > 0 && d.monthlyEMI != null && d.monthlyEMI! > 0,
        )
        .toList();
    _totalEMIs = debts.fold(0.0, (sum, d) => sum + (d.monthlyEMI ?? 0));
    _activeDebts = debts.length;

    // Get investments (SIPs)
    final investmentProvider = context.read<InvestmentProvider>();
    final investments = investmentProvider.investments
        .where((i) => i.isActive && i.sipAmount > 0)
        .toList();
    _totalSIPs = investments.fold(0.0, (sum, i) => sum + i.sipAmount);
    _activeInvestments = investments.length;

    // Get subscriptions
    final subscriptionProvider = context.read<SubscriptionProvider>();
    final subscriptions = subscriptionProvider.subscriptions
        .where((s) => s.isActive)
        .toList();
    _totalSubscriptions = subscriptionProvider.totalMonthlyCost;
    _activeSubscriptions = subscriptions.length;

    // Get goals
    final goalProvider = context.read<GoalProvider>();
    final goals = goalProvider.goals.where((g) => !g.isCompleted).toList();
    _activeGoals = goals.length;
    _recommendedGoalContribution = 0;
    for (final goal in goals) {
      final monthsRemaining =
          goal.targetDate.difference(DateTime.now()).inDays / 30;
      if (monthsRemaining > 0) {
        _recommendedGoalContribution += goal.remainingAmount / monthsRemaining;
      }
    }

    if (mounted) setState(() {});
  }

  double get _totalCommitments => _totalEMIs + _totalSIPs + _totalSubscriptions;
  bool get _hasCommitments => _totalCommitments > 0;

  String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(1)}Cr';
    }
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
                      gradient: LinearGradient(
                        colors: [AppColors.accentPurple, AppColors.accentPink],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Smart Budget',
                          style: AppTypography.headlineSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Considers your existing commitments',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                  ),
                ],
              ),

              // Existing Commitments Card
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
                        colors: [
                          Colors.orange.withOpacity(0.15),
                          AppColors.cardSurface,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'You have ₹${_formatAmount(_totalCommitments)}/month in fixed commitments',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Icon(
                              _showBreakdown
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: AppColors.textTertiary,
                            ),
                          ],
                        ),
                        if (_showBreakdown) ...[
                          const SizedBox(height: 12),
                          Container(
                            height: 1,
                            color: Colors.white.withOpacity(0.05),
                          ),
                          const SizedBox(height: 12),
                          if (_totalEMIs > 0)
                            _buildSmallCommitmentRow(
                              Icons.account_balance,
                              'EMIs',
                              _activeDebts,
                              _totalEMIs,
                              Colors.orange,
                            ),
                          if (_totalSIPs > 0)
                            _buildSmallCommitmentRow(
                              Icons.trending_up,
                              'SIPs',
                              _activeInvestments,
                              _totalSIPs,
                              AppColors.success,
                            ),
                          if (_totalSubscriptions > 0)
                            _buildSmallCommitmentRow(
                              Icons.subscriptions,
                              'Subscriptions',
                              _activeSubscriptions,
                              _totalSubscriptions,
                              AppColors.accentPink,
                            ),
                          if (_recommendedGoalContribution > 0)
                            _buildSmallCommitmentRow(
                              Icons.flag,
                              'Goals (suggested)',
                              _activeGoals,
                              _recommendedGoalContribution,
                              AppColors.info,
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4),
                child: Text(
                  'MONTHLY INCOME',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppColors.accentPurple.withOpacity(0.3),
                  ),
                ),
                child: TextField(
                  controller: _incomeController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Enter amount',
                    hintStyle: TextStyle(
                      color: AppColors.textTertiary.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    prefixIcon: Icon(
                      Icons.currency_rupee,
                      color: AppColors.accentPurple,
                    ),
                  ),
                ),
              ),

              // Budget Preview
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.auto_awesome, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'Create Smart Budgets',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
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

  Widget _buildSmallCommitmentRow(
    IconData icon,
    String label,
    int count,
    double amount,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
          const Spacer(),
          Text(
            '$count',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
          ),
          const SizedBox(width: 8),
          Text(
            '₹${_formatAmount(amount)}',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
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
        color: isNegative
            ? AppColors.error.withOpacity(0.1)
            : AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isNegative ? AppColors.error : AppColors.success).withOpacity(
            0.2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isNegative ? Icons.warning : Icons.check_circle,
                color: isNegative ? AppColors.error : AppColors.success,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                isNegative
                    ? 'Commitments exceed income!'
                    : 'Available for budgets',
                style: TextStyle(
                  color: isNegative ? AppColors.error : AppColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (!isNegative) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Needs (50%)',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
                ),
                Text(
                  '₹${_formatAmount(availableForBudgets * 0.5)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Wants (30%)',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
                ),
                Text(
                  '₹${_formatAmount(availableForBudgets * 0.3)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Savings (20%)',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
                ),
                Text(
                  '₹${_formatAmount(availableForBudgets * 0.2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid income')),
      );
      return;
    }

    // Check if commitments exceed income
    final availableForBudgets = income - _totalCommitments;
    if (availableForBudgets <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Your commitments (₹${_formatAmount(_totalCommitments)}) exceed your income!',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final budgetProvider = context.read<BudgetProvider>();
      final now = DateTime.now();
      final endDate = DateTime(now.year, now.month + 1, 0);

      // Smart 50/30/20 rule on AVAILABLE income (after commitments)
      final needsAmount = availableForBudgets * 0.50;
      final wantsAmount = availableForBudgets * 0.30;
      final savingsAmount = availableForBudgets * 0.20;

      final budgets = [
        // NEEDS (50% of available)
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
        // WANTS (30% of available)
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
        // SAVINGS (20% of available - only if not already covered by SIPs)
        if (_totalSIPs < savingsAmount * 0.5)
          Budget(
            id: '',
            categoryId: 'savings',
            categoryName: 'Savings & Emergency',
            allocatedAmount:
                savingsAmount - _totalSIPs.clamp(0, savingsAmount * 0.5),
            period: 'monthly',
            startDate: now,
            endDate: endDate,
            accountId: '',
            isActive: true,
            createdAt: now,
            updatedAt: now,
          ),
      ];

      for (final budget in budgets) {
        await budgetProvider.createBudget(budget);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _hasCommitments
                        ? 'Smart budgets created! (Excluded ₹${_formatAmount(_totalCommitments)} in commitments)'
                        : 'Budgets created using 50/30/20 rule!',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

Future<void> showAddBudgetModal(BuildContext context, {Budget? budget}) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, __, ___) => AddBudgetModal(budget: budget),
    ),
  );
}
