import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/category_provider.dart';
import '../../core/models/category.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/top_snackbar.dart'; // Assuming you have this from other screens
import 'widgets/edit_category_modal.dart';

class ManageCategoriesScreen extends StatelessWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Gradient Background
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
                _buildAppBar(context),
                Expanded(
                  child: Consumer<CategoryProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (provider.error != null) {
                        return Center(
                          child: Text(
                            provider.error!,
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.sm,
                            AppSpacing.lg,
                            100 // Space for FAB
                        ),
                        itemCount: provider.categories.length,
                        itemBuilder: (context, index) {
                          final category = provider.categories[index];

                          // Only custom categories can be deleted (Swiped)
                          if (category.isCustom) {
                            return Dismissible(
                              key: ValueKey(category.id),
                              direction: DismissDirection.endToStart,
                              background: _buildDeleteBackground(),
                              confirmDismiss: (direction) async {
                                return await _showDeleteConfirmation(context, category);
                              },
                              onDismissed: (direction) {
                                provider.deleteCategory(category.id);
                                // Optional: Show success snackbar if you have the utility
                                // showTopSnackBar(context, '${category.name} deleted');
                              },
                              child: _buildCategoryCard(context, category),
                            );
                          } else {
                            // Default categories cannot be swiped
                            return _buildCategoryCard(context, category);
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showEditCategoryModal(context),
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add),
        label: const Text('New Category'),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Text(
            'Manage Categories',
            style: AppTypography.headlineSmall.copyWith(
              color: Colors.white, // Fixed text color for dark background
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // The red background that appears when swiping
  Widget _buildDeleteBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.2), // Matches your theme's error container
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.error.withOpacity(0.5)),
      ),
      child: const Icon(Icons.delete_outline, color: AppColors.error),
    );
  }

  Widget _buildCategoryCard(BuildContext context, Category category) {
    return GestureDetector(
      // Tap to edit (if custom), or just view (if default)
      onTap: category.isCustom
          ? () => showEditCategoryModal(context, category: category)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.cardDarkElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: category.color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  category.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Name and Type
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: AppTypography.titleSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    category.isCustom ? 'Custom Category' : 'Default Category',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),

            // Visual cue for interaction
            if (category.isCustom)
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.3),
                size: 20,
              )
            else
              Icon(
                Icons.lock_outline,
                size: 16,
                color: Colors.white.withOpacity(0.3),
              ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context, Category category) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDarkElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: Text(
            'Delete Category',
            style: AppTypography.titleMedium.copyWith(color: Colors.white)
        ),
        content: Text(
          'Are you sure you want to delete "${category.name}"? This cannot be undone.',
          style: AppTypography.bodyMedium.copyWith(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.7))),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}