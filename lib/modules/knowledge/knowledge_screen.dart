import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/knowledge/merchant_knowledge.dart';
import '../../../core/providers/knowledge_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'all'; // 'all', 'active', 'disabled'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.read<KnowledgeProvider>();

    final scaffoldBg = isDark
        ? AppColors.backgroundBlack
        : AppColors.kuveraBgLight; //[cite: 10, 12]
    final textColor = isDark
        ? AppColors.textPrimary
        : AppColors.kuveraTextPrimaryLight; //[cite: 10, 12]
    final subtextColor = isDark
        ? AppColors.textTertiary
        : AppColors.kuveraTextSecondaryLight; //[cite: 10, 12]

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Memory & Rules',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            Text(
              'Automations learned by Nexus',
              style: AppTypography.bodySmall.copyWith(color: subtextColor),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.help_outline_rounded,
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.kuveraTextSecondaryLight, //[cite: 10]
            ),
            onPressed: () => _showInfoBottomSheet(context, isDark),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.lg,
              ), //[cite: 11]
              child: Column(
                children: [
                  // 1. Sleek Hero Stats Banner
                  _buildHeroMetricsCard(provider, isDark),
                  const SizedBox(height: AppSpacing.lg), //[cite: 11]
                  // 2. Integrated Search Bar
                  _buildSearchField(isDark),
                  const SizedBox(height: AppSpacing.md), //[cite: 11]
                  // 3. Segmented Filter Tabs
                  _buildFilterSegments(isDark),
                ],
              ),
            ),
          ),

          // 4. Merchant Cards List
          _buildMerchantList(provider, isDark),

          const SliverToBoxAdapter(
            child: SizedBox(height: 100), // clearance for FAB
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, provider, isDark),
        backgroundColor: AppColors.primaryBlue, //[cite: 10]
        foregroundColor: AppColors.white, //[cite: 10]
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          'Teach Merchant',
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.white,
          ), //[cite: 10, 13]
        ),
      ),
    );
  }

  // --- HERO STATS BANNER ---
  Widget _buildHeroMetricsCard(KnowledgeProvider provider, bool isDark) {
    return FutureBuilder<KnowledgeStats>(
      future: provider.getStats(), //[cite: 2, 5]
      builder: (context, snapshot) {
        final count = snapshot.data?.merchantCount ?? 0;
        final approvalRate = snapshot.data?.autoApprovalEligible ?? 0;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg), //[cite: 11]
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.cardSurface
                : AppColors.kuveraCardLight, //[cite: 10, 12]
            borderRadius: AppSpacing.borderRadiusMd, //[cite: 11]
            border: Border.all(
              color: isDark
                  ? AppColors.borderSubtle
                  : AppColors.kuveraBorderLight, //[cite: 10, 12]
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(
                  alpha: isDark ? 0.35 : 0.05,
                ), //[cite: 10]
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(
                          alpha: 0.15,
                        ), //[cite: 10]
                        borderRadius: AppSpacing.borderRadiusSm, //[cite: 11]
                      ),
                      child: const Icon(
                        Icons.store_rounded,
                        color: AppColors.primaryBlue, //[cite: 10]
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md), //[cite: 11]
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$count',
                          style: AppTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textPrimary
                                : AppColors
                                      .kuveraTextPrimaryLight, //[cite: 10, 13]
                          ),
                        ),
                        Text(
                          'Learned Patterns',
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? AppColors.textTertiary
                                : AppColors
                                      .kuveraTextSecondaryLight, //[cite: 10, 13]
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                height: 36,
                width: 1,
                color: isDark
                    ? AppColors.white12
                    : AppColors.kuveraBorderLight, //[cite: 10, 12]
              ),
              const SizedBox(width: AppSpacing.md), //[cite: 11]
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.pastelGreen.withValues(
                          alpha: 0.15,
                        ), //[cite: 10]
                        borderRadius: AppSpacing.borderRadiusSm, //[cite: 11]
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.pastelGreen, //[cite: 10]
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md), //[cite: 11]
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$approvalRate%',
                          style: AppTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textPrimary
                                : AppColors
                                      .kuveraTextPrimaryLight, //[cite: 10, 13]
                          ),
                        ),
                        Text(
                          'Auto-Categorized',
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? AppColors.textTertiary
                                : AppColors
                                      .kuveraTextSecondaryLight, //[cite: 10, 13]
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- SEARCH FIELD ---
  Widget _buildSearchField(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardElevated
            : AppColors.kuveraArcBgLight, //[cite: 10]
        borderRadius: AppSpacing.borderRadiusLg, //[cite: 11]
        border: Border.all(
          color: isDark
              ? AppColors.borderSubtle
              : AppColors.kuveraBorderLight, //[cite: 10, 12]
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val.trim()),
        style: AppTypography.bodyMedium.copyWith(
          color: isDark
              ? AppColors.textPrimary
              : AppColors.kuveraTextPrimaryLight, //[cite: 10, 13]
        ),
        decoration: InputDecoration(
          hintText: 'Search merchant or pattern...',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: isDark
                ? AppColors.textTertiary
                : AppColors.kuveraTextSecondaryLight, //[cite: 10, 13]
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: isDark
                ? AppColors.textSecondary
                : AppColors.kuveraTextSecondaryLight, //[cite: 10]
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ), //[cite: 11]
        ),
      ),
    );
  }

  // --- FILTER SEGMENT PILLS ---
  Widget _buildFilterSegments(bool isDark) {
    final filters = [
      {'key': 'all', 'label': 'All Rules'},
      {'key': 'active', 'label': 'Active'},
      {'key': 'disabled', 'label': 'Paused'},
    ];

    return Row(
      children: filters.map((f) {
        final isSelected = _filterType == f['key'];
        final bg = isSelected
            ? AppColors
                  .primaryBlue //[cite: 10]
            : (isDark
                  ? AppColors.cardElevated.withValues(alpha: 0.6)
                  : AppColors.kuveraCardLight); //[cite: 10, 12]
        final border = isSelected
            ? AppColors
                  .primaryBlue //[cite: 10]
            : (isDark
                  ? AppColors.borderSubtle
                  : AppColors.kuveraBorderLight); //[cite: 10, 12]
        final textCol = isSelected
            ? AppColors
                  .white //[cite: 10]
            : (isDark
                  ? AppColors.textSecondary
                  : AppColors.kuveraTextSecondaryLight); //[cite: 10]

        return Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm), //[cite: 11]
          child: InkWell(
            onTap: () => setState(() => _filterType = f['key']!),
            borderRadius: AppSpacing.borderRadiusFull, //[cite: 11]
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 7,
              ), //[cite: 11]
              decoration: BoxDecoration(
                color: bg,
                borderRadius: AppSpacing.borderRadiusFull, //[cite: 11]
                border: Border.all(color: border),
              ),
              child: Text(
                f['label']!,
                style: AppTypography.labelSmall.copyWith(
                  color: textCol,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- MERCHANT SLIVER LIST ---
  Widget _buildMerchantList(KnowledgeProvider provider, bool isDark) {
    return StreamBuilder<List<MerchantKnowledge>>(
      stream: provider.watchAllMerchants(), //[cite: 2, 5]
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryBlue,
              ), //[cite: 10]
            ),
          );
        }

        var merchants = snapshot.data ?? []; //[cite: 2]

        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          merchants = merchants.where((m) {
            return m.name.toLowerCase().contains(query) ||
                m.normalizedName.contains(query);
          }).toList(); //[cite: 2]
        }

        if (_filterType == 'active') {
          merchants = merchants
              .where((m) => !m.isDisabled)
              .toList(); //[cite: 2]
        } else if (_filterType == 'disabled') {
          merchants = merchants.where((m) => m.isDisabled).toList(); //[cite: 2]
        }

        if (merchants.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl2), //[cite: 11]
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_fix_high_rounded,
                      size: 48,
                      color: isDark
                          ? AppColors.textTertiary
                          : AppColors.kuveraTextSecondaryLight, //[cite: 10]
                    ),
                    const SizedBox(height: AppSpacing.md), //[cite: 11]
                    Text(
                      _searchQuery.isEmpty
                          ? 'No merchant rules configured'
                          : 'No merchants match "$_searchQuery"', //[cite: 2]
                      style: AppTypography.titleMedium.copyWith(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.kuveraTextPrimaryLight, //[cite: 10, 13]
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs), //[cite: 11]
                    Text(
                      'Approve transactions to train Nexus or tap + below.',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textTertiary
                            : AppColors
                                  .kuveraTextSecondaryLight, //[cite: 10, 13]
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
          ), //[cite: 11]
          sliver: SliverList.separated(
            itemCount: merchants.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.md), //[cite: 11]
            itemBuilder: (context, index) {
              final merchant = merchants[index];
              return _MerchantCard(
                merchant: merchant,
                isDark: isDark,
                onToggle: () => provider.toggleMerchantKnowledge(
                  merchant.id,
                  !merchant.isDisabled,
                ), //[cite: 2]
                onDelete: () =>
                    _confirmDelete(context, provider, merchant, isDark),
                onEdit: () => _showEditDialog(context, merchant, isDark),
              );
            },
          ),
        );
      },
    );
  }

  // --- DIALOGS & ACTIONS ---
  void _showInfoBottomSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark
          ? AppColors.cardElevated
          : AppColors.kuveraCardLight, //[cite: 10, 12]
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ), //[cite: 11, 12]
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl), //[cite: 11]
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How Nexus Learns',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimary
                    : AppColors.kuveraTextPrimaryLight, //[cite: 10, 13]
              ),
            ),
            const SizedBox(height: AppSpacing.lg), //[cite: 11]
            _InfoRow(
              icon: Icons.auto_awesome_rounded,
              title: 'Automatic Recognition',
              body:
                  'Nexus infers recurring spending patterns each time you confirm a transaction category.', //[cite: 2]
              isDark: isDark,
            ),
            const SizedBox(height: AppSpacing.md), //[cite: 11]
            _InfoRow(
              icon: Icons.tune_rounded,
              title: 'Manual Overrides',
              body:
                  'Explicit rules created here take strict priority over automatic guesses.',
              isDark: isDark,
            ),
            const SizedBox(height: AppSpacing.md), //[cite: 11]
            _InfoRow(
              icon: Icons.pause_circle_outline_rounded,
              title: 'Paused Memory',
              body:
                  'Toggle a rule off to prevent automatic categorizations without erasing transaction logs.',
              isDark: isDark,
            ),
            const SizedBox(height: AppSpacing.xl), //[cite: 11]
          ],
        ),
      ),
    );
  }

  void _showAddDialog(
    BuildContext context,
    KnowledgeProvider provider,
    bool isDark,
  ) {
    final nameCtrl = TextEditingController();
    bool isRecurring = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: isDark
              ? AppColors.cardSurface
              : AppColors.kuveraCardLight, //[cite: 10, 12]
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ), //[cite: 11, 12]
          title: Text(
            'New Merchant Rule',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimary
                  : AppColors.kuveraTextPrimaryLight, //[cite: 10, 13]
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColors.kuveraTextPrimaryLight, //[cite: 10, 13]
                ),
                decoration: InputDecoration(
                  labelText: 'Merchant Name',
                  hintText: 'e.g. Swiggy, Uber, Netflix',
                  filled: true,
                  fillColor: isDark
                      ? AppColors.cardElevated
                      : AppColors.kuveraArcBgLight, //[cite: 10]
                  border: OutlineInputBorder(
                    borderRadius: AppSpacing.borderRadiusSm, //[cite: 11]
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md), //[cite: 11]
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primaryBlue, //[cite: 10, 12]
                title: Text(
                  'Regular / Recurring Subscription',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.kuveraTextPrimaryLight, //[cite: 10, 13]
                  ),
                ),
                value: isRecurring,
                onChanged: (v) => setDlgState(() => isRecurring = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColors.kuveraTextSecondaryLight, //[cite: 10]
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue, //[cite: 10, 12]
                foregroundColor: AppColors.white, //[cite: 10, 12]
                shape: const StadiumBorder(), //[cite: 12]
              ),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;

                final knowledge = MerchantKnowledge(
                  id: DateTime.now().millisecondsSinceEpoch
                      .toString(), //[cite: 2]
                  name: name,
                  normalizedName: name.toLowerCase(), //[cite: 2]
                  isRecurring: isRecurring,
                  transactionCount: 1, //[cite: 2]
                );

                await provider.saveMerchantKnowledge(knowledge); //[cite: 2]
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save Rule'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    MerchantKnowledge merchant,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? AppColors.cardSurface
            : AppColors.kuveraCardLight, //[cite: 10, 12]
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ), //[cite: 11, 12]
        title: Text(
          merchant.name, //[cite: 2]
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.textPrimary
                : AppColors.kuveraTextPrimaryLight, //[cite: 10, 13]
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _KeyValueRow(
              label: 'Assigned Category',
              val: merchant.category ?? 'Uncategorized', //[cite: 2]
              isDark: isDark,
            ),
            const SizedBox(height: AppSpacing.sm), //[cite: 11]
            _KeyValueRow(
              label: 'Payment Type',
              val: merchant.isRecurring ? 'Recurring' : 'One-off', //[cite: 2]
              isDark: isDark,
            ),
            const SizedBox(height: AppSpacing.sm), //[cite: 11]
            _KeyValueRow(
              label: 'Logged Transactions',
              val: '${merchant.occurrenceCount}', //[cite: 2]
              isDark: isDark,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    KnowledgeProvider provider,
    MerchantKnowledge merchant,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? AppColors.cardSurface
            : AppColors.kuveraCardLight, //[cite: 10, 12]
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ), //[cite: 11, 12]
        title: const Text('Delete Rule?'),
        content: Text(
          'Nexus will forget categorization rules for "${merchant.name}". Previous transactions are preserved.', //[cite: 2]
          style: AppTypography.bodySmall.copyWith(
            color: isDark
                ? AppColors.textSecondary
                : AppColors.kuveraTextSecondaryLight, //[cite: 10, 13]
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error, //[cite: 10]
              foregroundColor: AppColors.white, //[cite: 10]
              shape: const StadiumBorder(), //[cite: 12]
            ),
            onPressed: () async {
              await provider.deleteMerchantKnowledge(merchant.id); //[cite: 2]
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// --- REDESIGNED MERCHANT CARD ---
class _MerchantCard extends StatelessWidget {
  final MerchantKnowledge merchant;
  final bool isDark;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _MerchantCard({
    required this.merchant,
    required this.isDark,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = merchant.isDisabled; //[cite: 2]

    final cardBg = isDark
        ? (isDisabled
              ? AppColors.cardSurface.withValues(alpha: 0.35)
              : AppColors.cardSurface) //[cite: 10]
        : (isDisabled
              ? AppColors.kuveraCardLight.withValues(alpha: 0.5)
              : AppColors.kuveraCardLight); //[cite: 10]

    final borderColor = isDark
        ? (isDisabled
              ? AppColors.borderSubtle.withValues(alpha: 0.2)
              : AppColors.borderSubtle) //[cite: 10]
        : AppColors.kuveraBorderLight; //[cite: 10, 12]

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isDisabled ? 0.6 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: AppSpacing.borderRadiusMd, //[cite: 11]
          border: Border.all(color: borderColor, width: 1),
          boxShadow: isDisabled
              ? []
              : [
                  BoxShadow(
                    color: AppColors.black.withValues(
                      alpha: isDark ? 0.3 : 0.04,
                    ), //[cite: 10]
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ), //[cite: 11]
        child: Row(
          children: [
            // Leading Icon Badge
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDisabled
                    ? (isDark
                          ? AppColors.cardElevated
                          : AppColors.kuveraArcBgLight) //[cite: 10]
                    : AppColors.primaryBlue.withValues(
                        alpha: 0.12,
                      ), //[cite: 10]
                borderRadius: AppSpacing.borderRadiusSm, //[cite: 11]
              ),
              child: Icon(
                merchant.isRecurring
                    ? Icons.repeat_rounded
                    : Icons.store_rounded, //[cite: 2]
                size: 20,
                color: isDisabled
                    ? (isDark
                          ? AppColors.textTertiary
                          : AppColors.kuveraTextSecondaryLight) //[cite: 10]
                    : AppColors.primaryBlue, //[cite: 10]
              ),
            ),
            const SizedBox(width: AppSpacing.md), //[cite: 11]
            // Title & Inline Tags
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    merchant.name, //[cite: 2]
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColors.kuveraTextPrimaryLight, //[cite: 10, 13]
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(
                            alpha: 0.12,
                          ), //[cite: 10]
                          borderRadius: AppSpacing.borderRadiusXs, //[cite: 11]
                        ),
                        child: Text(
                          merchant.category ?? 'Uncategorized', //[cite: 2]
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primaryBlue, //[cite: 10]
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (merchant.isRecurring) //[cite: 2]
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.pastelTeal.withValues(
                              alpha: 0.12,
                            ), //[cite: 10]
                            borderRadius:
                                AppSpacing.borderRadiusXs, //[cite: 11]
                          ),
                          child: Text(
                            'Recurring',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.pastelTeal, //[cite: 10]
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      Text(
                        '· ${merchant.occurrenceCount}x', //[cite: 2]
                        style: AppTypography.caption.copyWith(
                          color: isDark
                              ? AppColors.textTertiary
                              : AppColors
                                    .kuveraTextSecondaryLight, //[cite: 10, 13]
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Toggle Switch
            Transform.scale(
              scale: 0.82,
              child: Switch.adaptive(
                value: !merchant.isDisabled, //[cite: 2]
                activeColor: AppColors.pastelGreen, //[cite: 10]
                onChanged: (_) => onToggle(), //[cite: 2]
              ),
            ),

            // 3-Dot Overflow Menu (Removes the clunky bottom row)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                size: 20,
                color: isDark
                    ? AppColors.textTertiary
                    : AppColors.kuveraTextSecondaryLight, //[cite: 10]
              ),
              color: isDark
                  ? AppColors.cardElevated
                  : AppColors.kuveraCardLight, //[cite: 10, 12]
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.borderRadiusSm,
              ), //[cite: 11]
              onSelected: (val) {
                if (val == 'edit') onEdit();
                if (val == 'delete') onDelete();
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Edit Rule'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: AppColors.error,
                      ), //[cite: 10]
                      const SizedBox(width: 8),
                      Text(
                        'Forget',
                        style: TextStyle(color: AppColors.error),
                      ), //[cite: 10]
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool isDark;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primaryBlue, size: 22), //[cite: 10]
        const SizedBox(width: AppSpacing.md), //[cite: 11]
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.labelLarge.copyWith(
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColors.kuveraTextPrimaryLight, //[cite: 10, 13]
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.textTertiary
                      : AppColors.kuveraTextSecondaryLight, //[cite: 10, 13]
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  final String label;
  final String val;
  final bool isDark;

  const _KeyValueRow({
    required this.label,
    required this.val,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isDark
                ? AppColors.textTertiary
                : AppColors.kuveraTextSecondaryLight, //[cite: 10, 13]
          ),
        ),
        Text(
          val,
          style: AppTypography.labelMedium.copyWith(
            color: isDark
                ? AppColors.textPrimary
                : AppColors.kuveraTextPrimaryLight, //[cite: 10, 13]
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
