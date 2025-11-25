import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import '../../../core/models/goal.dart';
import '../../../core/widgets/top_snackbar.dart';
import '../../../core/theme/app_colors.dart';

class AddGoalModal extends StatefulWidget {
  final Function(Goal) onGoalAdded;

  const AddGoalModal({super.key, required this.onGoalAdded});

  @override
  State<AddGoalModal> createState() => _AddGoalModalState();
}

class _AddGoalModalState extends State<AddGoalModal>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _blurAnimation;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _currentAmountController = TextEditingController();

  String _selectedCategory = 'Savings';
  DateTime _selectedDeadline = DateTime.now().add(const Duration(days: 90));
  bool _isLoading = false;

  final List<String> _categories = [
    'Savings',
    'Emergency',
    'Travel',
    'Technology',
    'Education',
    'Investment',
    'Home',
    'Health',
    'Other',
  ];

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
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
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
                  color: Colors.black.withOpacity(
                    0.3 * _opacityAnimation.value,
                  ),
                ),
              ),
              Center(
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      constraints: const BoxConstraints(maxWidth: 500),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildHeader(theme),
                            Flexible(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: _buildForm(theme),
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.flag, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create New Goal',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Set a savings target and track your progress',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _closeModal,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _titleController,
            label: 'Goal Title',
            hint: 'e.g., Emergency Fund',
            icon: Icons.title,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a goal title';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildDropdownField(theme),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _targetAmountController,
            label: 'Target Amount',
            hint: 'Enter amount',
            icon: Icons.currency_rupee,
            keyboardType: TextInputType.number,
            prefixText: '₹ ',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter target amount';
              }
              final amount = double.tryParse(value);
              if (amount == null || amount <= 0) {
                return 'Please enter a valid amount';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _currentAmountController,
            label: 'Current Amount (Optional)',
            hint: 'Enter current savings',
            icon: Icons.savings,
            keyboardType: TextInputType.number,
            prefixText: '₹ ',
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                final amount = double.tryParse(value);
                if (amount == null || amount < 0) {
                  return 'Please enter a valid amount';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildDateField(theme),
          const SizedBox(height: 32),
          _buildButtons(theme),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? prefixText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
    );
  }

  Widget _buildDropdownField(ThemeData theme) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: const Icon(Icons.category),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
      items: _categories.map((category) {
        return DropdownMenuItem(value: category, child: Text(category));
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value!;
        });
      },
    );
  }

  Widget _buildDateField(ThemeData theme) {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Target Date',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_selectedDeadline.day}/${_selectedDeadline.month}/${_selectedDeadline.year}',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : _closeModal,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FilledButton(
            onPressed: _isLoading ? null : _createGoal,
            style: FilledButton.styleFrom(
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
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Create Goal'),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  Future<void> _createGoal() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final targetAmount = double.parse(_targetAmountController.text);
        final currentAmount = _currentAmountController.text.trim().isEmpty
            ? 0.0
            : double.parse(_currentAmountController.text);

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('User not logged in');
        }

        final newGoal = Goal(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: user.uid,
          name: _titleController.text.trim(),
          description: _selectedCategory,
          targetAmount: targetAmount,
          currentAmount: currentAmount,
          targetDate: _selectedDeadline,
          color: '#4CAF50',
          isCompleted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await Future.delayed(const Duration(milliseconds: 500));

        widget.onGoalAdded(newGoal);

        if (mounted) {
          await _closeModal();

          showTopSnackBar(
            context,
            'Goal "${newGoal.name}" created successfully!',
          );
        }
      } catch (e) {
        if (mounted) {
          showTopSnackBar(context, 'Error creating goal: $e', isError: true);
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

  Future<void> _closeModal() async {
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

Future<void> showAddGoalModal(
  BuildContext context,
  Function(Goal) onGoalAdded,
) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: false,
      pageBuilder: (context, animation, _) {
        return AddGoalModal(onGoalAdded: onGoalAdded);
      },
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
    ),
  );
}
