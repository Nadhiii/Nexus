import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/category_provider.dart';
import '../../core/models/category.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/swipe_to_delete.dart';
import '../../core/widgets/collapsible_fab.dart';
import '../../core/widgets/nexus_card.dart';
import 'widgets/edit_category.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  String _activeFilter = 'All'; // 'All', 'System', 'Custom', 'Hidden'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkGradient.first,
      body: Consumer<CategoryProvider>(
        builder: (context, provider, child) {
          final allCategories = provider.categories;
          final hiddenCategories = provider.hiddenCategories;
          final systemCategories = allCategories
              .where((c) => !c.isCustom)
              .toList();
          final customCategories = allCategories
              .where((c) => c.isCustom)
              .toList();

          final isHiddenView = _activeFilter == 'Hidden';

          // Apply Filter
          List<Category> displayedCategories = allCategories;
          if (_activeFilter == 'System') { displayedCategories = systemCategories; }
          if (_activeFilter == 'Custom') { displayedCategories = customCategories; }
          if (isHiddenView) { displayedCategories = hiddenCategories; }

          return CustomScrollView(
            slivers: [
              // 1. HEADER
              SliverAppBar(
                pinned: true,
                expandedHeight: 120.0,
                backgroundColor: AppColors.darkGradient.first,
                foregroundColor: AppColors.white,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    'Category Vault',
                    style: AppTypography.headlineMedium,
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),

              // 2. VAULT SUMMARY CARD & FILTERS
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCard(
                        total: allCategories.length,
                        system: systemCategories.length,
                        custom: customCategories.length,
                      ),
                      const SizedBox(height: AppSpacing.xl2),

                      // Filter Chips
                      Row(
                        children: [
                          _buildFilterChip('All'),
                          const SizedBox(width: AppSpacing.sm),
                          _buildFilterChip('System'),
                          const SizedBox(width: AppSpacing.sm),
                          _buildFilterChip('Custom'),
                          if (hiddenCategories.isNotEmpty) ...[
                            const SizedBox(width: AppSpacing.sm),
                            _buildFilterChip(
                              'Hidden',
                              badgeCount: hiddenCategories.length,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),

              // 3. CATEGORY LIST
              if (displayedCategories.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      isHiddenView
                          ? "Nothing hidden ΓÇö deleted defaults show up here"
                          : "No categories found",
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    0,
                    AppSpacing.xl,
                    100,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final category = displayedCategories[index];

                      if (isHiddenView) {
                        // Hidden defaults aren't swipeable/editable here ΓÇö
                        // just show them with an explicit restore action.
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _buildHiddenCategoryTile(
                            context,
                            category,
                            onRestore: () => provider.unhideCategory(category.id),
                          ),
                        );
                      }

                      final tile = Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _buildCategoryTile(context, category),
                      );

                      // Allow swipe-to-delete for BOTH custom and default
                      // categories. For defaults, deleteCategory() marks
                      // them 'hidden' instead of truly deleting the
                      // (non-existent) Firestore doc.
                      return SwipeToDelete(
                        itemKey: ValueKey(category.id),
                        itemId: category.id,
                        itemName: category.name,
                        onDelete: () => provider.deleteCategory(
                          category.id,
                          isDefault: !category.isCustom,
                        ),
                        child: tile,
                      );
                    }, childCount: displayedCategories.length),
                  ),
                ),
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

  // --- UI COMPONENTS ---

  Widget _buildSummaryCard({
    required int total,
    required int system,
    required int custom,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBlue.withValues(alpha: 0.15),
            AppColors.backgroundBlack,
          ],
        ),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "VAULT STATUS",
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const Icon(
                Icons.pie_chart_outline,
                color: AppColors.primaryBlue,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    total.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "TOTAL ACTIVE",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildStatPill("$system System", Colors.white24),
                  const SizedBox(width: 8),
                  _buildStatPill(
                    "$custom Custom",
                    AppColors.primaryBlue.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, {int? badgeCount}) {
    final isActive = _activeFilter == label;
    return FilterChip(
      label: Text(badgeCount != null && badgeCount > 0 ? '$label  $badgeCount' : label),
      selected: isActive,
      showCheckmark: false,
      onSelected: (_) => setState(() => _activeFilter = label),
    );
  }

 Widget _buildCategoryTile(BuildContext context, Category category) {
    return GestureDetector(
      onTap: () => showEditCategoryModal(context, category: category),
      child: NexusCard(
        color: AppColors.cardElevated,
        border: Border.all(color: category.isCustom ? category.color.withValues(alpha: 0.3) : AppColors.borderSubtle),
        padding: AppSpacing.cardPaddingMd,
        child: Row(
          children: [
            // Glowing Icon Container
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: category.color.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: category.color.withValues(alpha: 0.1),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  category.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        category.isCustom ? "User Minted" : "Editable Default",
                        style: TextStyle(
                          color: category.color.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (category.isModified) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "Modified",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Status Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.edit_outlined,
                size: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHiddenCategoryTile(
    BuildContext context,
    Category category, {
    required VoidCallback onRestore,
  }) {
    return Opacity(
      opacity: 0.6,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: category.color.withValues(alpha: 0.2)),
              ),
              child: Center(
                child: Text(
                  category.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Hidden",
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onRestore,
              icon: const Icon(Icons.restore, size: 16, color: AppColors.primaryBlue),
              label: const Text(
                "Restore",
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
