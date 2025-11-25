import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/category_provider.dart';
import '../../../../core/models/category.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
// Assuming you have this

// Updated to push a full screen route instead of a modal bottom sheet
// This matches the 'Add Transaction' and 'Add Account' transition animations.
void showEditCategoryModal(BuildContext context, {Category? category}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => EditCategoryScreen(category: category),
    ),
  );
}

class EditCategoryScreen extends StatefulWidget {
  final Category? category;

  const EditCategoryScreen({super.key, this.category});

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emojiController;

  late Color _selectedColor;
  bool _isLoading = false;

  // Modern color palette matching other screens
  final List<Color> _colorOptions = [
    const Color(0xFFEF4444), // Red
    const Color(0xFFF97316), // Orange
    const Color(0xFFEAB308), // Yellow
    const Color(0xFF22C55E), // Green
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF8B5CF6), // Violet
    const Color(0xFFEC4899), // Pink
    const Color(0xFF64748B), // Slate
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _emojiController = TextEditingController(
      text: widget.category?.emoji ?? '',
    );
    _selectedColor = widget.category?.color ?? _colorOptions[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Gradient Background (Matching other Add screens)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppColors.darkGradient,
              ),
            ),
          ),

          // 2. Content
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(
                  context,
                  isEditing ? 'Edit Category' : 'New Category',
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('Basic Info'),
                          const SizedBox(height: AppSpacing.md),

                          // Name and Emoji Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Emoji Input
                              Container(
                                width: 80,
                                margin: const EdgeInsets.only(
                                  right: AppSpacing.md,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Icon',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    TextFormField(
                                      controller: _emojiController,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 24),
                                      maxLength: 1,
                                      decoration: InputDecoration(
                                        counterText: "",
                                        hintText: "😊",
                                        filled: true,
                                        fillColor: AppColors.cardDarkElevated,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppSpacing.radiusMd,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: AppSpacing.md,
                                            ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty)
                                          return 'Required';
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              // Name Input
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Category Name',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    TextFormField(
                                      controller: _nameController,
                                      style: AppTypography.bodyLarge.copyWith(
                                        color: Colors.white,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: "e.g. Groceries",
                                        hintStyle: TextStyle(
                                          color: Colors.white.withOpacity(0.3),
                                        ),
                                        filled: true,
                                        fillColor: AppColors.cardDarkElevated,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppSpacing.radiusMd,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.lg,
                                              vertical: AppSpacing.md,
                                            ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty)
                                          return 'Please enter a name';
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: AppSpacing.xl),
                          _buildSectionLabel('Appearance'),
                          const SizedBox(height: AppSpacing.md),

                          // Color Picker
                          Wrap(
                            spacing: AppSpacing.md,
                            runSpacing: AppSpacing.md,
                            children: _colorOptions.map((color) {
                              final isSelected =
                                  _selectedColor.value == color.value;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedColor = color),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? color
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: color.withOpacity(0.5),
                                                  blurRadius: 8,
                                                  spreadRadius: 1,
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
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: AppSpacing.xl2),

                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveCategory,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.lg,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd,
                                  ),
                                ),
                                elevation: 0,
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
                                      isEditing
                                          ? 'Save Changes'
                                          : 'Create Category',
                                      style: AppTypography.titleMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md, // Reduced bottom padding
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Text(
            title,
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: AppTypography.titleSmall.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<CategoryProvider>();

      final category = Category(
        id: widget.category?.id ?? DateTime.now().toString(),
        name: _nameController.text.trim(),
        emoji: _emojiController.text.trim(),
        color: _selectedColor,
        isCustom: true,
      );

      if (widget.category != null) {
        await provider.updateCategory(category);
        if (mounted) {
          // showTopSnackBar(context, 'Category updated successfully');
        }
      } else {
        await provider.addCategory(category);
        if (mounted) {
          // showTopSnackBar(context, 'Category created successfully');
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        // showTopSnackBar(context, 'Error: $e', isError: true);
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
