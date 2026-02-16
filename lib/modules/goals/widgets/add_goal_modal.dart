import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import '../../../core/models/goal.dart';
import '../../../core/widgets/top_snackbar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_animations.dart';

class AddGoalModal extends StatefulWidget {
  final Function(Goal) onGoalAdded;
  final Goal? goalToEdit;

  const AddGoalModal({super.key, required this.onGoalAdded, this.goalToEdit});

  @override
  State<AddGoalModal> createState() => _AddGoalModalState();
}

class _AddGoalModalState extends State<AddGoalModal>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

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
    const Color(0xFF00E676), // Neon Green
    const Color(0xFFFFEA00), // Neon Yellow
    const Color(0xFFFF3D00), // Neon Orange
    const Color(0xFFD500F9), // Neon Purple
    const Color(0xFFE91E63), // Pink
  ];

  @override
  void initState() {
    super.initState();

    // Initialize from existing goal if editing
    if (widget.goalToEdit != null) {
      _titleController.text = widget.goalToEdit!.name;
      _targetAmountController.text = widget.goalToEdit!.targetAmount.toString();
      _currentAmountController.text = widget.goalToEdit!.currentAmount
          .toString();
      _selectedCategory = widget.goalToEdit!.description ?? 'Savings';
      _selectedDeadline = widget.goalToEdit!.targetDate;
      _selectedColor = _parseColor(widget.goalToEdit!.color);
    }

    _animationController = AnimationController(
      duration: AppAnimations.slowest,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AppAnimations.standardCurve,
      ),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AppAnimations.staggeredCurve,
      ),
    );

    // Listen to changes for Live Preview
    _titleController.addListener(() => setState(() {}));
    _targetAmountController.addListener(() => setState(() {}));

    _animationController.forward();
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
    _animationController.dispose();
    _titleController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Blur Background
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
                  constraints: const BoxConstraints(
                    maxWidth: 400,
                    maxHeight: 750,
                  ),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundBlack, // Darker base
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Text(
                        widget.goalToEdit != null ? "Edit Goal" : "Create Goal",
                        style: AppTypography.headlineSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Scrollable Content
                      Expanded(
                        child: SingleChildScrollView(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 1. LIVE PREVIEW CARD
                                _buildLivePreview(),
                                const SizedBox(height: 32),

                                // 2. INPUT FIELDS
                                _buildLabel("GOAL DETAILS"),
                                _buildGlassTextField(
                                  controller: _titleController,
                                  label: "Goal Name",
                                  hint: "e.g. New Macbook",
                                  icon: Icons.flag,
                                ),
                                const SizedBox(height: 16),
                                _buildGlassTextField(
                                  controller: _targetAmountController,
                                  label: "Target Amount",
                                  hint: "0.00",
                                  icon: Icons.currency_rupee,
                                  isNumber: true,
                                ),
                                const SizedBox(height: 16),
                                _buildGlassTextField(
                                  controller: _currentAmountController,
                                  label: "Already Saved (Optional)",
                                  hint: "0.00",
                                  icon: Icons.savings,
                                  isNumber: true,
                                ),
                                const SizedBox(height: 16),

                                // Category Dropdown (Pill Style)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardSurface,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.05),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedCategory,
                                      dropdownColor: AppColors.cardSurface,
                                      icon: const Icon(
                                        Icons.arrow_drop_down,
                                        color: AppColors.textSecondary,
                                      ),
                                      isExpanded: true,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                      items: _categories
                                          .map(
                                            (c) => DropdownMenuItem(
                                              value: c,
                                              child: Text(c),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (v) => setState(
                                        () => _selectedCategory = v!,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 32),
                                _buildLabel("CUSTOMIZATION"),

                                // Color Picker
                                SizedBox(
                                  height: 50,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _colorOptions.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 12),
                                    itemBuilder: (context, index) {
                                      final color = _colorOptions[index];
                                      final isSelected =
                                          _selectedColor == color;
                                      return GestureDetector(
                                        onTap: () => setState(
                                          () => _selectedColor = color,
                                        ),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.transparent,
                                              width: 2,
                                            ),
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                      color: color.withOpacity(
                                                        0.6,
                                                      ),
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
                                const SizedBox(height: 20),

                                // Date Picker Pill
                                GestureDetector(
                                  onTap: () => _selectDate(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardSurface,
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.05),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          color: _selectedColor,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          "Target Date",
                                          style: TextStyle(
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          DateFormat(
                                            'dd MMM yyyy',
                                          ).format(_selectedDeadline),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(
                                          "Cancel",
                                          style: TextStyle(
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: SizedBox(
                                        height: 50,
                                        child: ElevatedButton(
                                          onPressed: _isLoading
                                              ? null
                                              : _createGoal,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppColors.cardSurface,
                                            foregroundColor: _selectedColor,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                              side: BorderSide(
                                                color: _selectedColor
                                                    .withOpacity(0.3),
                                              ),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: _isLoading
                                              ? SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: _selectedColor,
                                                      ),
                                                )
                                              : Text(
                                                  widget.goalToEdit != null
                                                      ? "Update Goal"
                                                      : "Create Goal",
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.white,
                                                  ),
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildLivePreview() {
    final title = _titleController.text.isEmpty
        ? "New Goal"
        : _titleController.text;
    final target = double.tryParse(_targetAmountController.text) ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _selectedColor.withOpacity(0.8),
            _selectedColor.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "PREVIEW",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Icon(Icons.flag, color: Colors.white.withOpacity(0.8), size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            "Target: ₹${target.toStringAsFixed(0)}",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.05, // Just a visual placeholder
              backgroundColor: Colors.black26,
              color: Colors.white,
              minHeight: 6,
            ),
          ),
        ],
      ),
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
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool isNumber = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(30), // TRUE PILL
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4), // Proper shadow on pill
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: AppColors.textTertiary),
          hintStyle: TextStyle(color: AppColors.textTertiary.withOpacity(0.5)),
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
        validator: (value) =>
            (value == null || value.isEmpty) && !label.contains("Optional")
            ? "Required"
            : null,
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
    if (picked != null) setState(() => _selectedDeadline = picked);
  }

  Future<void> _createGoal() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final target = double.parse(_targetAmountController.text);
        final current = double.tryParse(_currentAmountController.text) ?? 0.0;
        final user = FirebaseAuth.instance.currentUser;

        if (user == null) return;

        // Convert Color to Hex String for storage if your model expects String
        // Or adapt model to store int value. Assuming model stores String hex:
        String colorString =
            '#${_selectedColor.value.toRadixString(16).substring(2)}';

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

        await Future.delayed(AppAnimations.verySlow);
        widget.onGoalAdded(goal);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) showTopSnackBar(context, 'Error: $e', isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
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
      pageBuilder: (_, __, ___) => AddGoalModal(onGoalAdded: onGoalAdded),
    ),
  );
}
