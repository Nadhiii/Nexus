import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/category_provider.dart';
import '../../core/models/category.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/swipe_to_delete.dart';
import '../../core/widgets/collapsible_fab.dart';
import 'widgets/edit_category_modal.dart';

class ManageCategoriesScreen extends StatelessWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: Consumer<CategoryProvider>(
        builder: (context, provider, child) {
          final systemCategories = provider.categories
              .where((c) => !c.isCustom)
              .toList();
          final customCategories = provider.categories
              .where((c) => c.isCustom)
              .toList();

          return CustomScrollView(
            slivers: [
              // 1. IMMERSIVE HEADER
              SliverAppBar(
                pinned: true,
                expandedHeight: 110,
                backgroundColor: AppColors.backgroundBlack,
                surfaceTintColor: AppColors.backgroundBlack,
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 60, bottom: 24),
                  title: Text(
                    'Category Vault',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              // 2. SYSTEM CATEGORIES (Locked)
              if (systemCategories.isNotEmpty) ...[
                SliverToBoxAdapter(child: _buildSectionHeader("SYSTEM CORE")),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildCategoryTile(
                          context,
                          systemCategories[index],
                        ),
                      ),
                      childCount: systemCategories.length,
                    ),
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // 3. USER CATEGORIES (Unlocked)
              if (customCategories.isNotEmpty) ...[
                SliverToBoxAdapter(child: _buildSectionHeader("USER DEFINED")),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final category = customCategories[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SwipeToDelete(
                          itemKey: ValueKey(category.id),
                          itemId: category.id,
                          itemName: category.name,
                          onDelete: () => provider.deleteCategory(category.id),
                          child: _buildCategoryTile(context, category),
                        ),
                      );
                    }, childCount: customCategories.length),
                  ),
                ),
              ],
            ],
          );
        },
      ),
      floatingActionButton: CollapsibleFab(
        onPressed: () => showEditCategoryModal(context),
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: 'Mint Category',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.textTertiary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildCategoryTile(BuildContext context, Category category) {
    final isLocked = !category.isCustom;

    return GestureDetector(
      onTap: isLocked
          ? null
          : () => showEditCategoryModal(context, category: category),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardSurface.withOpacity(0.6), // Glass effect
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: category.isCustom
                ? category.color.withOpacity(0.3)
                : Colors.white.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            // Glowing Icon Container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: category.color.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: category.color.withOpacity(0.1),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  category.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isLocked)
                    Text(
                      "System Protected",
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),

            // Status Icon
            Icon(
              isLocked ? Icons.lock_outline : Icons.edit_outlined,
              size: 18,
              color: isLocked ? AppColors.textTertiary : Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
