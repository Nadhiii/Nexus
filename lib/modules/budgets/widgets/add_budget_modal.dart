import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/budget_provider.dart';
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
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
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
  bool get _isEditMode => widget.budget != null;

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
                            duration: const Duration(milliseconds: 200),
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

// --- Quick Setup Modal ---
Future<void> showQuickSetupModal(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => const QuickSetupModal(),
  );
}

class QuickSetupModal extends StatefulWidget {
  const QuickSetupModal({super.key});

  @override
  State<QuickSetupModal> createState() => _QuickSetupModalState();
}

class _QuickSetupModalState extends State<QuickSetupModal> {
  final _incomeController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Auto Budget', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'We will create a 50/30/20 plan for you based on your income.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundBlack,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _incomeController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Monthly Income',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                prefixIcon: Icon(
                  Icons.currency_rupee,
                  color: AppColors.accentPurple,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _runAutoSetup,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.cardSurface,
            foregroundColor: AppColors.accentPurple,
            side: BorderSide(color: AppColors.accentPurple.withOpacity(0.3)),
          ),
          child: const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _runAutoSetup() async {
    final income = double.tryParse(_incomeController.text);
    if (income == null || income <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid income')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final budgetProvider = context.read<BudgetProvider>();

      // 50/30/20 rule:
      // 50% - Needs (Housing, Food, Transportation, Health)
      // 30% - Wants (Entertainment, Shopping, Personal)
      // 20% - Savings (Savings, Investments)

      final now = DateTime.now();
      final endDate = DateTime(now.year, now.month + 1, 0); // End of next month

      // Calculate allocations
      final needsAmount = income * 0.50;
      final wantsAmount = income * 0.30;
      final savingsAmount = income * 0.20;

      // Create budgets
      final budgets = [
        Budget(
          id: '',
          categoryId: 'housing',
          categoryName: 'Housing',
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
          allocatedAmount: needsAmount * 0.35,
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
          categoryName: 'Health & Medical',
          allocatedAmount: needsAmount * 0.15,
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
        Budget(
          id: '',
          categoryId: 'savings',
          categoryName: 'Savings',
          allocatedAmount: savingsAmount * 0.70,
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
          categoryId: 'investments',
          categoryName: 'Investments',
          allocatedAmount: savingsAmount * 0.30,
          period: 'monthly',
          startDate: now,
          endDate: endDate,
          accountId: '',
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      // Add all budgets
      for (final budget in budgets) {
        await budgetProvider.createBudget(budget);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Auto budgets created successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
