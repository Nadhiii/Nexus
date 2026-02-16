import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/shared_expense_provider.dart';
import '../../../core/models/shared_expense.dart';
import '../../../core/widgets/collapsible_fab.dart';
import '../widgets/add_family_member_dialog.dart';
import '../widgets/add_shared_expense_dialog.dart';

class FamilyDashboardScreen extends StatefulWidget {
  const FamilyDashboardScreen({super.key});

  @override
  State<FamilyDashboardScreen> createState() => _FamilyDashboardScreenState();
}

class _FamilyDashboardScreenState extends State<FamilyDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SharedExpenseProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildMemberAvatarRow(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildExpensesTab(),
                  _buildMembersTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: CollapsibleFab(
        onPressed: () => _showAddExpenseDialog(),
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: 'Add Expense',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// Stories-style horizontal avatar row for family members
  Widget _buildMemberAvatarRow() {
    return Consumer<SharedExpenseProvider>(
      builder: (context, provider, _) {
        final members = provider.familyMembers;
        if (members.isEmpty) return const SizedBox.shrink();

        return Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: members.length + 1, // +1 for "Add" button
            itemBuilder: (context, index) {
              if (index == members.length) {
                // Add member button
                return _buildAddMemberAvatar();
              }
              final member = members[index];
              // Net balance = what they're owed - what they owe
              final owed = provider.getTotalOwedTo(member.id);
              final owes = provider.getTotalOwedBy(member.id);
              final balance = owed - owes;
              return _buildMemberAvatar(member, balance);
            },
          ),
        );
      },
    );
  }

  Widget _buildMemberAvatar(FamilyMember member, double balance) {
    final isPositive = balance >= 0;
    final balanceColor = balance == 0
        ? AppColors.textTertiary
        : (isPositive ? AppColors.success : AppColors.error);

    // Generate color from name for avatar background
    final colors = [
      AppColors.primaryBlue,
      AppColors.accentPink,
      AppColors.accentTeal,
      AppColors.pastelOrange,
      AppColors.pastelPurple,
      AppColors.success,
    ];
    final avatarColor = colors[member.name.hashCode % colors.length];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar with ring indicator
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: balance != 0
                    ? [balanceColor, balanceColor.withOpacity(0.5)]
                    : [Colors.grey.shade700, Colors.grey.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: avatarColor.withOpacity(0.2),
                border: Border.all(color: AppColors.backgroundBlack, width: 2),
              ),
              child: Center(
                child: Text(
                  member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: avatarColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Name
          SizedBox(
            width: 64,
            child: Text(
              member.name.split(' ').first,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Balance indicator
          if (balance != 0)
            Text(
              '${isPositive ? '+' : ''}₹${balance.abs().toStringAsFixed(0)}',
              style: TextStyle(
                color: balanceColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddMemberAvatar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: () => _showAddMemberDialog(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cardSurface,
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              ),
              child: Icon(
                Icons.add_rounded,
                color: AppColors.textTertiary,
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Family',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Split expenses & track balances',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(30),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primaryBlue,
          borderRadius: BorderRadius.circular(30),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textTertiary,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Expenses'),
          Tab(text: 'Members'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer<SharedExpenseProvider>(
      builder: (context, provider, _) {
        final settlements = provider.calculateSettlements();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Stats
              _buildQuickStats(provider),
              const SizedBox(height: 24),

              // Settlements Section
              _buildSectionHeader('Settlements', Icons.swap_horiz),
              const SizedBox(height: 12),
              if (settlements.isEmpty)
                _buildEmptyState(
                  'All settled up!',
                  'No pending payments between family members.',
                  Icons.check_circle_outline,
                )
              else
                ...settlements.map((s) => _buildSettlementCard(s)),

              const SizedBox(height: 24),

              // Recent Activity
              _buildSectionHeader('Recent Activity', Icons.history),
              const SizedBox(height: 12),
              if (provider.expenses.isEmpty)
                _buildEmptyState(
                  'No expenses yet',
                  'Tap + to add your first shared expense.',
                  Icons.receipt_long_outlined,
                )
              else
                ...provider.expenses.take(5).map((e) => _buildExpenseCard(e)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickStats(SharedExpenseProvider provider) {
    final currentUserId = provider.familyMembers.isNotEmpty
        ? provider.familyMembers.first.id
        : '';
    final youOwe = provider.getTotalOwedBy(currentUserId);
    final youAreOwed = provider.getTotalOwedTo(currentUserId);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'You Owe',
            '₹${youOwe.toStringAsFixed(0)}',
            AppColors.error,
            Icons.arrow_upward,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'You\'re Owed',
            '₹${youAreOwed.toStringAsFixed(0)}',
            AppColors.success,
            Icons.arrow_downward,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textTertiary, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSettlementCard(SettlementSummary settlement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // Person who owes
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.error.withOpacity(0.2),
            child: Text(
              settlement.person2Name[0].toUpperCase(),
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settlement.person2Name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'owes ',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      settlement.person1Name,
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '₹${settlement.netAmount.toStringAsFixed(0)}',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(SharedExpense expense) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _getCategoryIcon(expense.category),
              color: AppColors.primaryBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Paid by ${expense.paidByName} • ${DateFormat('MMM d').format(expense.date)}',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${expense.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (expense.isSettled)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Settled',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesTab() {
    return Consumer<SharedExpenseProvider>(
      builder: (context, provider, _) {
        if (provider.expenses.isEmpty) {
          return Center(
            child: _buildEmptyState(
              'No shared expenses',
              'Start by adding an expense you want to split.',
              Icons.receipt_long_outlined,
            ),
          );
        }

        // Group by month
        final groupedExpenses = <String, List<SharedExpense>>{};
        for (var expense in provider.expenses) {
          final key = DateFormat('MMMM yyyy').format(expense.date);
          groupedExpenses.putIfAbsent(key, () => []).add(expense);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: groupedExpenses.length,
          itemBuilder: (context, index) {
            final month = groupedExpenses.keys.elementAt(index);
            final expenses = groupedExpenses[month]!;
            final total = expenses.fold(0.0, (sum, e) => sum + e.totalAmount);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        month,
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      Text(
                        '₹${total.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                ...expenses.map((e) => _buildExpenseCard(e)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMembersTab() {
    return Consumer<SharedExpenseProvider>(
      builder: (context, provider, _) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Add Member Button
            GestureDetector(
              onTap: () => _showAddMemberDialog(),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_add_outlined,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add Family Member',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Member List
            ...provider.familyMembers.map(
              (member) => _buildMemberCard(member, provider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMemberCard(FamilyMember member, SharedExpenseProvider provider) {
    final owes = provider.getTotalOwedBy(member.id);
    final owed = provider.getTotalOwedTo(member.id);
    final net = owed - owes;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryBlue.withOpacity(0.2),
            backgroundImage: member.avatarUrl != null
                ? NetworkImage(member.avatarUrl!)
                : null,
            child: member.avatarUrl == null
                ? Text(
                    member.name[0].toUpperCase(),
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                if (member.email != null)
                  Text(
                    member.email!,
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                net >= 0
                    ? '+₹${net.toStringAsFixed(0)}'
                    : '-₹${net.abs().toStringAsFixed(0)}',
                style: TextStyle(
                  color: net >= 0 ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                net >= 0 ? 'is owed' : 'owes',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'food':
      case 'dining':
        return Icons.restaurant;
      case 'groceries':
        return Icons.shopping_cart;
      case 'transport':
      case 'transportation':
        return Icons.directions_car;
      case 'utilities':
        return Icons.lightbulb;
      case 'entertainment':
        return Icons.movie;
      case 'shopping':
        return Icons.shopping_bag;
      case 'travel':
        return Icons.flight;
      default:
        return Icons.receipt_long;
    }
  }

  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddSharedExpenseDialog(),
    );
  }

  void _showAddMemberDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddFamilyMemberDialog(),
    );
  }
}
