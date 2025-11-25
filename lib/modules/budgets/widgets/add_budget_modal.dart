import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/budget_provider.dart';
import '../../../core/models/budget.dart';
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
      backgroundColor: Colors.black.withOpacity(0.5),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardDarkElevated, // Dark background
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: AddBudgetForm(
                      onDismiss: () => Navigator.pop(context),
                      budget: widget.budget,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
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
  final _notesController = TextEditingController();

  String _selectedCategoryId = 'miscellaneous';
  String _selectedPeriod = 'monthly';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime(
    DateTime.now().year,
    DateTime.now().month + 1,
    0,
  );
  bool _isLoading = false;
  bool get _isEditMode => widget.budget != null;

  // Use predefined categories from your logic, but we will style them locally
  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'housing',
      'name': 'Housing',
      'icon': Icons.home,
      'color': Colors.blue,
    },
    {
      'id': 'food',
      'name': 'Food',
      'icon': Icons.restaurant,
      'color': Colors.green,
    },
    {
      'id': 'transportation',
      'name': 'Transport',
      'icon': Icons.directions_car,
      'color': Colors.orange,
    },
    {
      'id': 'shopping',
      'name': 'Shopping',
      'icon': Icons.shopping_bag,
      'color': Colors.red,
    },
    {
      'id': 'entertainment',
      'name': 'Fun',
      'icon': Icons.movie,
      'color': Colors.pink,
    },
    {
      'id': 'health',
      'name': 'Health',
      'icon': Icons.local_hospital,
      'color': Colors.cyan,
    },
    {
      'id': 'personal',
      'name': 'Personal',
      'icon': Icons.face,
      'color': Colors.amber,
    },
    {
      'id': 'education',
      'name': 'Education',
      'icon': Icons.school,
      'color': Colors.indigo,
    },
    {
      'id': 'savings',
      'name': 'Savings',
      'icon': Icons.savings,
      'color': Colors.purple,
    },
    {
      'id': 'miscellaneous',
      'name': 'Misc',
      'icon': Icons.more_horiz,
      'color': Colors.grey,
    },
    {
      'id': 'custom',
      'name': 'Custom',
      'icon': Icons.edit,
      'color': Colors.teal,
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
      _startDate = budget.startDate;
      _endDate = budget.endDate;
      _notesController.text = budget.metadata?['notes'] ?? '';
    } else {
      _updateCategoryName();
    }
  }

  void _updateCategoryName() {
    final cat = _categories.firstWhere(
      (c) => c['id'] == _selectedCategoryId,
      orElse: () => {'name': ''},
    );
    if (_selectedCategoryId != 'custom') {
      _categoryNameController.text = cat['name'];
    } else if (!_isEditMode) {
      _categoryNameController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Modal Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isEditMode ? 'Edit Budget' : 'New Budget',
                style: AppTypography.titleMedium.copyWith(color: Colors.white),
              ),
              IconButton(
                onPressed: widget.onDismiss,
                icon: const Icon(Icons.close, color: Colors.white70),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),

        // Form Body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Category',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 100,
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
                          child: Container(
                            width: 70,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accentPurple
                                  : AppColors.cardDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accentPurple
                                    : Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  cat['icon'],
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  cat['name'],
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'Budget Name',
                    controller: _categoryNameController,
                    icon: Icons.label_outline,
                  ),

                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Amount Limit',
                    controller: _allocatedAmountController,
                    icon: Icons.currency_rupee,
                    isNumber: true,
                  ),

                  const SizedBox(height: 16),
                  Row(children: [Expanded(child: _buildDropdown())]),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveBudget,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentPurple,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
                              _isEditMode ? 'Update Budget' : 'Create Budget',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  if (_isEditMode) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.accentPurple),
            filled: true,
            fillColor: AppColors.cardDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          validator: (value) => value!.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Period',
          style: AppTypography.bodySmall.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPeriod,
              dropdownColor: AppColors.cardDarkElevated,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.accentPurple,
              ),
              items: ['monthly', 'weekly', 'yearly'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value[0].toUpperCase() + value.substring(1),
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedPeriod = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final budget = Budget(
        id: _isEditMode ? widget.budget!.id : '',
        categoryId: _selectedCategoryId,
        categoryName: _categoryNameController.text.trim(),
        allocatedAmount: double.parse(_allocatedAmountController.text),
        spentAmount: _isEditMode ? widget.budget!.spentAmount : 0.0,
        period: _selectedPeriod,
        startDate: _startDate,
        endDate: _endDate,
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
    if (!_isEditMode) return;
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
      backgroundColor: AppColors.cardDarkElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        'Auto Budget Setup',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Enter your monthly income. We will create a 50/30/20 split for you (Needs, Wants, Savings).',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _incomeController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Monthly Income',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              filled: true,
              fillColor: AppColors.cardDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(
                Icons.currency_rupee,
                color: AppColors.accentPurple,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createAutoBudgets,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentPurple,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createAutoBudgets() async {
    final income = double.tryParse(_incomeController.text);
    if (income == null || income <= 0) return;

    setState(() => _isLoading = true);
    final provider = Provider.of<BudgetProvider>(context, listen: false);

    // 50% Needs, 30% Wants, 20% Savings
    try {
      final now = DateTime.now();
      final end = DateTime(now.year, now.month + 1, 0);

      final plans = [
        {'cat': 'housing', 'name': 'Housing & Bills', 'pct': 0.30},
        {'cat': 'food', 'name': 'Groceries', 'pct': 0.20},
        {'cat': 'transportation', 'name': 'Transport', 'pct': 0.10},
        {'cat': 'shopping', 'name': 'Shopping & Fun', 'pct': 0.20},
        {'cat': 'savings', 'name': 'Savings', 'pct': 0.20},
      ];

      for (var plan in plans) {
        final amount = income * (plan['pct'] as double);
        await provider.createBudget(
          Budget(
            id: '',
            categoryId: plan['cat'] as String,
            categoryName: plan['name'] as String,
            allocatedAmount: amount,
            spentAmount: 0,
            period: 'monthly',
            startDate: now,
            endDate: end,
            accountId: 'default',
            isActive: true,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      if (mounted) {
        Navigator.pop(context);
        showTopSnackBar(context, 'Auto budgets created successfully!');
      }
    } catch (e) {
      if (mounted) showTopSnackBar(context, 'Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

Future<void> showAddBudgetModal(BuildContext context, {Budget? budget}) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      pageBuilder: (context, _, __) => AddBudgetModal(budget: budget),
      transitionsBuilder: (context, animation, _, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}
