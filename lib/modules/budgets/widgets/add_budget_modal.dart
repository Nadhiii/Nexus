import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/budget_provider.dart';
import '../../../core/models/budget.dart';

class AddBudgetModal extends StatefulWidget {
  final Budget? budget; // Make budget optional for create/edit

  const AddBudgetModal({super.key, this.budget});

  @override
  State<AddBudgetModal> createState() => _AddBudgetModalState();
}

class _AddBudgetModalState extends State<AddBudgetModal>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _blurAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _blurAnimation = Tween<double>(begin: 0.0, end: 15.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    HapticFeedback.lightImpact();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _dismissModal() async {
    HapticFeedback.lightImpact();
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _dismissModal();
        }
      },
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Stack(
              children: [
                BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: _blurAnimation.value,
                    sigmaY: _blurAnimation.value,
                  ),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black.withOpacity(
                      0.3 * _opacityAnimation.value,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _dismissModal,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.transparent,
                  ),
                ),
                Center(
                  child: GestureDetector(
                    onTap: () {},
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Opacity(
                        opacity: _opacityAnimation.value,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing20,
                            vertical: AppTheme.spacing32,
                          ),
                          constraints: BoxConstraints(
                            maxHeight:
                                MediaQuery.of(context).size.height * 0.85,
                            maxWidth: 500,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 40,
                                spreadRadius: 0,
                                offset: const Offset(0, 20),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 0,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: AddBudgetForm(
                              onDismiss: _dismissModal,
                              budget: widget.budget, // Pass budget to form
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
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

  final List<Map<String, dynamic>> _predefinedCategories = [
    {
      'id': 'housing',
      'name': 'Housing & Utilities',
      'icon': Icons.home,
      'color': Colors.blue,
    },
    {
      'id': 'food',
      'name': 'Food & Groceries',
      'icon': Icons.restaurant,
      'color': Colors.green,
    },
    {
      'id': 'transportation',
      'name': 'Transportation',
      'icon': Icons.directions_car,
      'color': Colors.orange,
    },
    {
      'id': 'savings',
      'name': 'Savings',
      'icon': Icons.savings,
      'color': Colors.purple,
    },
    {
      'id': 'investments',
      'name': 'Investments',
      'icon': Icons.trending_up,
      'color': Colors.teal,
    },
    {
      'id': 'entertainment',
      'name': 'Entertainment',
      'icon': Icons.movie,
      'color': Colors.pink,
    },
    {
      'id': 'shopping',
      'name': 'Shopping',
      'icon': Icons.shopping_bag,
      'color': Colors.red,
    },
    {
      'id': 'health',
      'name': 'Health & Insurance',
      'icon': Icons.local_hospital,
      'color': Colors.cyan,
    },
    {
      'id': 'personal',
      'name': 'Personal Care',
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
      'id': 'miscellaneous',
      'name': 'Miscellaneous',
      'icon': Icons.more_horiz,
      'color': Colors.grey,
    },
    {
      'id': 'custom',
      'name': 'Custom',
      'icon': Icons.edit,
      'color': Colors.deepOrange,
    },
  ];

  final List<Map<String, String>> _periodOptions = [
    {'value': 'weekly', 'label': 'Weekly'},
    {'value': 'monthly', 'label': 'Monthly'},
    {'value': 'yearly', 'label': 'Yearly'},
    {'value': 'custom', 'label': 'Custom Period'},
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      // Pre-fill form for editing
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

  @override
  void dispose() {
    _categoryNameController.dispose();
    _allocatedAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateCategoryName() {
    final selectedCategory = _predefinedCategories.firstWhere(
      (cat) => cat['id'] == _selectedCategoryId,
      orElse: () => {'name': 'Custom Category'},
    );

    if (_selectedCategoryId == 'custom') {
      if (_categoryNameController.text == 'Custom') {
        _categoryNameController.clear();
      }
    } else {
      _categoryNameController.text = selectedCategory['name'];
    }
  }

  void _updatePeriodDates() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'weekly':
        _startDate = now;
        _endDate = now.add(const Duration(days: 7));
        break;
      case 'monthly':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case 'yearly':
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year + 1, 1, 0);
        break;
      case 'custom':
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          _isEditMode ? 'Edit Budget' : 'Add Budget',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: widget.onDismiss,
          icon: const Icon(Icons.close, color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: math.max(
                MediaQuery.of(context).viewInsets.bottom + 16,
                16,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Budget Category',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.5),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 140,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                childAspectRatio: 1,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: _predefinedCategories.length,
                          itemBuilder: (context, index) {
                            final category = _predefinedCategories[index];
                            final isSelected =
                                category['id'] == _selectedCategoryId;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCategoryId = category['id'];
                                  _updateCategoryName();
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (category['color'] as Color)
                                            .withOpacity(0.2)
                                      : Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                  border: isSelected
                                      ? Border.all(
                                          color: category['color'] as Color,
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      category['icon'] as IconData,
                                      color: isSelected
                                          ? category['color'] as Color
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      (category['name'] as String)
                                          .split(' ')
                                          .first,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontSize: 10,
                                            color: isSelected
                                                ? category['color'] as Color
                                                : Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
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
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Category Name',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _categoryNameController,
                  enabled:
                      _selectedCategoryId ==
                      'custom',
                  decoration: InputDecoration(
                    hintText: _selectedCategoryId == 'custom'
                        ? 'Enter custom category name'
                        : 'Category name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: _selectedCategoryId == 'custom'
                        ? Theme.of(context).colorScheme.surfaceContainerHighest
                        : Theme.of(context).colorScheme.surfaceContainerHighest
                              .withOpacity(0.5),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a category name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                Text(
                  'Budget Amount',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _allocatedAmountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter budget amount',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter budget amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                Text(
                  'Budget Period',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedPeriod,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                  items: _periodOptions.map((option) {
                    return DropdownMenuItem(
                      value: option['value'],
                      child: Text(option['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPeriod = value!;
                      _updatePeriodDates();
                    });
                  },
                ),
                const SizedBox(height: 24),

                if (_selectedPeriod == 'custom') ...[
                  Text(
                    'Custom Period',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectStartDate(context),
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            'Start: ${_startDate.day}/${_startDate.month}/${_startDate.year}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectEndDate(context),
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            'End: ${_endDate.day}/${_endDate.month}/${_endDate.year}',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                Text(
                  'Notes (Optional)',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add notes about this budget...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 32),

                FilledButton(
                  onPressed: _isLoading ? null : _saveBudget,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEditMode ? 'Save Changes' : 'Create Budget'),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 30));
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be after start date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

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
        accountId: _isEditMode ? widget.budget!.accountId : 'default',
        isActive: true,
        metadata: _notesController.text.trim().isNotEmpty
            ? {'notes': _notesController.text.trim()}
            : null,
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
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Budget ${_isEditMode ? 'updated' : 'created'} successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving budget: $e'),
            backgroundColor: Colors.red,
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

class QuickSetupModal extends StatefulWidget {
  const QuickSetupModal({super.key});

  @override
  State<QuickSetupModal> createState() => _QuickSetupModalState();
}

class _QuickSetupModalState extends State<QuickSetupModal>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _blurAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _blurAnimation = Tween<double>(begin: 0.0, end: 15.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    HapticFeedback.lightImpact();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _dismissModal() async {
    HapticFeedback.lightImpact();
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _dismissModal();
        }
      },
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Stack(
              children: [
                BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: _blurAnimation.value,
                    sigmaY: _blurAnimation.value,
                  ),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black.withOpacity(
                      0.3 * _opacityAnimation.value,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _dismissModal,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.transparent,
                  ),
                ),
                Center(
                  child: GestureDetector(
                    onTap: () {},
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Opacity(
                        opacity: _opacityAnimation.value,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing20,
                            vertical: AppTheme.spacing32,
                          ),
                          constraints: BoxConstraints(
                            maxHeight:
                                MediaQuery.of(context).size.height * 0.85,
                            maxWidth: 500,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 40,
                                spreadRadius: 0,
                                offset: const Offset(0, 20),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 0,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: QuickSetupForm(
                              onDismiss: _dismissModal,
                              provider: Provider.of<BudgetProvider>(
                                context,
                                listen: false,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class QuickSetupForm extends StatefulWidget {
  final VoidCallback onDismiss;
  final BudgetProvider provider;

  const QuickSetupForm({
    super.key,
    required this.onDismiss,
    required this.provider,
  });

  @override
  State<QuickSetupForm> createState() => _QuickSetupFormState();
}

class _QuickSetupFormState extends State<QuickSetupForm> {
  final _formKey = GlobalKey<FormState>();
  final _monthlyIncomeController = TextEditingController();

  String _selectedBudgetRule = '50-30-20';
  bool _isLoading = false;

  final Map<String, Map<String, dynamic>> _budgetRules = {
    '50-30-20': {
      'name': '50/30/20 Rule',
      'description': 'Popular budgeting method',
      'categories': {
        'housing': {'percentage': 30, 'name': 'Housing & Utilities'},
        'food': {'percentage': 15, 'name': 'Food & Groceries'},
        'transportation': {'percentage': 5, 'name': 'Transportation'},
        'savings': {'percentage': 20, 'name': 'Savings'},
        'entertainment': {'percentage': 15, 'name': 'Entertainment'},
        'personal': {'percentage': 10, 'name': 'Personal Care'},
        'miscellaneous': {'percentage': 5, 'name': 'Miscellaneous'},
      },
    },
    'zero-based': {
      'name': 'Zero-Based Budget',
      'description': 'Every rupee has a purpose',
      'categories': {
        'housing': {'percentage': 25, 'name': 'Housing & Utilities'},
        'food': {'percentage': 15, 'name': 'Food & Groceries'},
        'transportation': {'percentage': 15, 'name': 'Transportation'},
        'savings': {'percentage': 20, 'name': 'Savings'},
        'investments': {'percentage': 10, 'name': 'Investments'},
        'entertainment': {'percentage': 10, 'name': 'Entertainment'},
        'miscellaneous': {'percentage': 5, 'name': 'Miscellaneous'},
      },
    },
    'essentials-first': {
      'name': 'Essentials First',
      'description': 'Priority on needs over wants',
      'categories': {
        'housing': {'percentage': 35, 'name': 'Housing & Utilities'},
        'food': {'percentage': 20, 'name': 'Food & Groceries'},
        'transportation': {'percentage': 15, 'name': 'Transportation'},
        'savings': {'percentage': 15, 'name': 'Savings'},
        'health': {'percentage': 10, 'name': 'Health & Insurance'},
        'miscellaneous': {'percentage': 5, 'name': 'Miscellaneous'},
      },
    },
  };

  @override
  void dispose() {
    _monthlyIncomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'Quick Budget Setup',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: widget.onDismiss,
          icon: const Icon(Icons.close, color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: math.max(
                MediaQuery.of(context).viewInsets.bottom + 16,
                16,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Quick Budget Setup',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create multiple budgets based on proven methods',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Monthly Income',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _monthlyIncomeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter your monthly income',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your monthly income';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                Text(
                  'Choose Budget Method',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),

                ..._budgetRules.entries.map((entry) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: RadioListTile<String>(
                      value: entry.key,
                      groupValue: _selectedBudgetRule,
                      onChanged: (value) {
                        setState(() {
                          _selectedBudgetRule = value!;
                        });
                      },
                      title: Text(
                        entry.value['name'],
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        entry.value['description'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      tileColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 32),

                FilledButton(
                  onPressed: _isLoading ? null : _createBudgets,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Budgets'),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createBudgets() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final monthlyIncome = double.parse(_monthlyIncomeController.text);
      final selectedRule = _budgetRules[_selectedBudgetRule]!;
      final categories = selectedRule['categories'] as Map<String, dynamic>;

      for (final entry in categories.entries) {
        final categoryId = entry.key;
        final categoryData = entry.value as Map<String, dynamic>;
        final percentage = categoryData['percentage'] as int;
        final categoryName = categoryData['name'] as String;

        final allocatedAmount = (monthlyIncome * percentage) / 100;

        final budget = Budget(
          id: '',
          categoryId: categoryId,
          categoryName: categoryName,
          allocatedAmount: allocatedAmount,
          spentAmount: 0.0,
          period: 'monthly',
          startDate: DateTime.now(),
          endDate: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
          accountId: 'default',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await widget.provider.createBudget(budget);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${categories.length} budgets created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating budgets: $e'),
            backgroundColor: Colors.red,
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

Future<void> showAddBudgetModal(BuildContext context, {Budget? budget}) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: false,
      pageBuilder: (context, animation, _) {
        return AddBudgetModal(budget: budget);
      },
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
    ),
  );
}

Future<void> showQuickSetupModal(BuildContext context) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: false,
      pageBuilder: (context, animation, _) {
        return const QuickSetupModal();
      },
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
    ),
  );
}
