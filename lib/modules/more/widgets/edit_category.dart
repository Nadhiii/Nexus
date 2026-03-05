import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/category_provider.dart';
import '../../../../core/models/category.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/top_snackbar.dart';

class EditCategoryModal extends StatefulWidget {
  final Category? categoryToEdit;

  const EditCategoryModal({super.key, this.categoryToEdit});

  @override
  State<EditCategoryModal> createState() => _EditCategoryModalState();
}

class _EditCategoryModalState extends State<EditCategoryModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emojiController = TextEditingController();
  Color _selectedColor = const Color(0xFF3B82F6); // Blue default
  bool _isLoading = false;

  final List<Color> _colorOptions = [
    const Color(0xFF3B82F6), // Blue
    const Color(0xFFEF4444), // Red
    const Color(0xFF22C55E), // Green
    const Color(0xFFEAB308), // Yellow
    const Color(0xFFEC4899), // Pink
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFFF97316), // Orange
  ];

  @override
  void initState() {
    super.initState();
    if (widget.categoryToEdit != null) {
      _nameController.text = widget.categoryToEdit!.name;
      _emojiController.text = widget.categoryToEdit!.emoji;
      _selectedColor = widget.categoryToEdit!.color;
    }

    // Add listeners to update the Token Preview instantly
    _nameController.addListener(() => setState(() {}));
    _emojiController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.categoryToEdit != null
        ? 'Edit Category'
        : 'Mint Category';

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
                    // 1. LIVE TOKEN PREVIEW (Unbreakable read-only visual)
                    _buildTokenPreview(),
                    const SizedBox(height: AppSpacing.xl2),

                    Text(
                      'Category Details',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // 2. ROCK SOLID INPUT FIELDS
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildStandardTextField(
                            controller: _emojiController,
                            hint: "🏷️",
                            icon: null,
                            maxLength: 2,
                            textAlign: TextAlign.center,
                            validator: (val) =>
                                (val == null || val.trim().isEmpty)
                                ? "Req"
                                : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          flex: 5,
                          child: _buildStandardTextField(
                            controller: _nameController,
                            hint: "Name (e.g. Subs)",
                            icon: Icons.label_outline,
                            validator: (val) =>
                                (val == null || val.trim().isEmpty)
                                ? "Required"
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl2),

                    Text(
                      'Theme Color',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // 3. COLOR GRID
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: AppColors.cardDarkElevated,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusXl,
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        alignment: WrapAlignment.center,
                        children: _colorOptions.map((color) {
                          final isSelected =
                              _selectedColor.toARGB32() == color.toARGB32();
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColor = color),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 3)
                                    : Border.all(color: Colors.transparent),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.6),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 20,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl2),

                    // 4. SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                          ),
                          elevation: 8,
                          shadowColor: _selectedColor.withValues(alpha: 0.5),
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
                                widget.categoryToEdit != null
                                    ? 'Save Changes'
                                    : 'Mint Category',
                                style: AppTypography.titleSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 80), // Padding for keyboard
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Builders ---

  Widget _buildTokenPreview() {
    final emoji = _emojiController.text.trim().isEmpty
        ? "🏷️"
        : _emojiController.text.trim();
    final name = _nameController.text.trim().isEmpty
        ? "New Category"
        : _nameController.text.trim();

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _selectedColor.withValues(alpha: 0.4),
              _selectedColor.withValues(alpha: 0.1),
              Colors.black.withValues(alpha: 0.8),
            ],
          ),
          border: Border.all(
            color: _selectedColor.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _selectedColor.withValues(alpha: 0.3),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                name.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardTextField({
    required TextEditingController controller,
    required String hint,
    required IconData? icon,
    int? maxLength,
    TextAlign textAlign = TextAlign.start,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      textAlign: textAlign,
      style: AppTypography.bodyLarge.copyWith(
        color: AppColors.textPrimary,
        fontSize: icon == null ? 24 : 16,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.textTertiary.withValues(alpha: 0.5),
        ),
        filled: true,
        fillColor: AppColors.cardDarkElevated,
        counterText: "",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        prefixIcon: icon != null
            ? Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.sm,
                ),
                child: Icon(icon, color: _selectedColor),
              )
            : null,
      ),
      validator: validator,
    );
  }

  // --- Logic ---

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final provider = context.read<CategoryProvider>();
        final category = Category(
          id:
              widget.categoryToEdit?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          emoji: _emojiController.text.trim().isEmpty
              ? '🏷️'
              : _emojiController.text.trim(),
          color: _selectedColor,
          isCustom: true,
        );

        if (widget.categoryToEdit != null) {
          await provider.updateCategory(category);
        } else {
          await provider.addCategory(category);
        }

        if (mounted) {
          Navigator.pop(context);
          showTopSnackBar(context, 'Category minted successfully');
        }
      } catch (e) {
        if (mounted) { showTopSnackBar(context, 'Error: $e', isError: true); }
      } finally {
        if (mounted) { setState(() => _isLoading = false); }
      }
    }
  }
}

void showEditCategoryModal(BuildContext context, {Category? category}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => EditCategoryModal(categoryToEdit: category),
    ),
  );
}
