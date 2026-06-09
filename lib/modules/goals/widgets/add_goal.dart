import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../core/models/goal.dart';
import '../../../core/widgets/top_snackbar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';

class ModernAddGoalScreen extends StatefulWidget {
  final Function(Goal) onGoalAdded;
  final Goal? goalToEdit;

  const ModernAddGoalScreen({
    super.key,
    required this.onGoalAdded,
    this.goalToEdit,
  });

  @override
  State<ModernAddGoalScreen> createState() => _ModernAddGoalScreenState();
}

class _ModernAddGoalScreenState extends State<ModernAddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _currentAmountController = TextEditingController();

  String _selectedCategory = 'Savings';
  DateTime _selectedDeadline = DateTime.now().add(const Duration(days: 90));
  Color _selectedColor = AppColors.primaryBlue;
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

  final List<Color> _colorOptions = [
    AppColors.primaryBlue,
    const Color(0xFF00E676),
    const Color(0xFFFFEA00),
    const Color(0xFFFF3D00),
    const Color(0xFFD500F9),
    const Color(0xFFE91E63),
  ];

  @override
  void initState() {
    super.initState();

    if (widget.goalToEdit != null) {
      _titleController.text = widget.goalToEdit!.name;
      _targetAmountController.text = widget.goalToEdit!.targetAmount.toString();
      _currentAmountController.text = widget.goalToEdit!.currentAmount
          .toString();
      _selectedCategory = widget.goalToEdit!.description ?? 'Savings';
      _selectedDeadline = widget.goalToEdit!.targetDate;
      _selectedColor = _parseColor(widget.goalToEdit!.color);
    }

    _titleController.addListener(() => setState(() {}));
    _targetAmountController.addListener(() => setState(() {}));
    _currentAmountController.addListener(() => setState(() {}));
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppColors.primaryBlue;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.goalToEdit != null ? "Edit Goal" : "Create Goal";
    final goalId = widget.goalToEdit?.id ?? '';

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
                    _buildLivePreview(),
                    const SizedBox(height: AppSpacing.xl2),

                    Text(
                      'Target Amount',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _targetAmountController,
                      autofocus: widget.goalToEdit == null,
                      style: AppTypography.displayMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        prefixText: '₹ ',
                        prefixStyle: AppTypography.displayMedium.copyWith(
                          color: _selectedColor,
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

                    Text(
                      'Goal Name',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildStandardTextField(
                      controller: _titleController,
                      hint: "e.g. New Macbook",
                      icon: Icons.flag_outlined,
                      validator: (val) =>
                          val == null || val.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: AppSpacing.xl2),

                    Text(
                      'Already Saved (Optional)',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildStandardTextField(
                      controller: _currentAmountController,
                      hint: "0.00",
                      icon: Icons.savings_outlined,
                      isNumber: true,
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
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardElevated,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        dropdownColor: AppColors.cardElevated,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                        ),
                        items: _categories
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedCategory = v!),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl2),

                    Text(
                      'Target Date',
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
                              DateFormat(
                                'MMM dd, yyyy',
                              ).format(_selectedDeadline),
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

                    Text(
                      'Appearance',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 50,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _colorOptions.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final color = _colorOptions[index];
                          final isSelected = _selectedColor == color;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColor = color),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.6),
                                          blurRadius: 10,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 20,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl2),

                    if (goalId.isNotEmpty)
                      Center(child: _buildOpenInTasksButton(context, goalId)),

                    if (goalId.isNotEmpty)
                      const SizedBox(height: AppSpacing.sm),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createGoal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
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
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : Text(
                                widget.goalToEdit != null
                                    ? 'Save Changes'
                                    : 'Save Goal',
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

  Widget _buildStandardTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isNumber = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.sm,
          ),
          child: Icon(icon, color: AppColors.textSecondary),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildLivePreview() {
    final title = _titleController.text.isEmpty
        ? "New Goal"
        : _titleController.text;
    final target = double.tryParse(_targetAmountController.text) ?? 0;
    final current = double.tryParse(_currentAmountController.text) ?? 0;
    double progress = target > 0 ? (current / target) : 0.05;
    if (progress > 1.0) {
      progress = 1.0;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: _selectedColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _selectedColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: _selectedColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.flag, color: _selectedColor, size: 20),
              ),
              Text(
                "${(progress * 100).toStringAsFixed(0)}%",
                style: AppTypography.titleMedium.copyWith(
                  color: _selectedColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: AppTypography.headlineSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            "Target: ₹${target.toStringAsFixed(0)}",
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              color: _selectedColor,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() => _selectedDeadline = picked);
    }
  }

  Future<void> _createGoal() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final target = double.parse(_targetAmountController.text);
        final current = double.tryParse(_currentAmountController.text) ?? 0.0;
        final user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          return;
        }

        String colorString =
            '#${_selectedColor.toARGB32().toRadixString(16).substring(2)}';

        final goal = Goal(
          id:
              widget.goalToEdit?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          userId: user.uid,
          name: _titleController.text.trim(),
          description: _selectedCategory,
          targetAmount: target,
          currentAmount: current,
          targetDate: _selectedDeadline,
          color: colorString,
          isCompleted: widget.goalToEdit?.isCompleted ?? false,
          createdAt: widget.goalToEdit?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        widget.onGoalAdded(goal);
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          showTopSnackBar(context, 'Error: $e', isError: true);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _launchTasksForItem(String itemId) async {
    try {
      final uri = Uri.parse('nexustasks://open/tasks/$itemId');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
      // If Tasks not installed: silently do nothing
    } catch (_) {
      // Swallow all errors silently
    }
  }

  Widget _buildOpenInTasksButton(BuildContext context, String itemId) {
    return TextButton.icon(
      onPressed: () => _launchTasksForItem(itemId),
      icon: Icon(Icons.checklist_rounded, size: 14, color: Colors.white38),
      label: Text(
        'Open in Tasks →',
        style: TextStyle(color: Colors.white38, fontSize: 12),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

Future<void> navToAddGoalScreen(
  BuildContext context,
  Function(Goal) onGoalAdded, {
  Goal? goalToEdit,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          ModernAddGoalScreen(onGoalAdded: onGoalAdded, goalToEdit: goalToEdit),
    ),
  );
}
