import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/providers/shared_expense_provider.dart';
import '../../../core/providers/family_debt_provider.dart';
import '../../../core/providers/account_provider.dart';
import '../../../core/providers/transaction_provider.dart';
import '../../../core/models/shared_expense.dart';
import '../../../core/models/family_debt.dart';
import '../../../core/models/account.dart';
import '../../../core/models/transaction.dart';
import '../../../core/models/transaction_draft.dart';
import '../../../core/widgets/nexus_card.dart';
import '../widgets/add_family_member.dart';
import '../widgets/add_shared_expense.dart';
import '../../../features/debts/widgets/add_family_debt_sheet.dart';

class FamilyDashboardScreen extends StatefulWidget {
  const FamilyDashboardScreen({super.key});

  @override
  State<FamilyDashboardScreen> createState() => _FamilyDashboardScreenState();
}

class _FamilyDashboardScreenState extends State<FamilyDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _expandedExpenseIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SharedExpenseProvider>().initialize();
      context.read<FamilyDebtProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openAddMember() async {
    final newMember = await ModernAddFamilyMemberScreen.show(context);
    if (newMember != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newMember.name} added!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
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
                  _buildFamilyDebtsTab(),
                  _buildMembersTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      // Standard FloatingActionButton replaces CollapsibleFab to prevent semantics assertion crashes
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddActionSheet(),
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
                'People & Balances',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Shared splits & personal IOUs',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberAvatarRow() {
    return Consumer2<SharedExpenseProvider, FamilyDebtProvider>(
      builder: (context, splitProvider, debtProvider, _) {
        final members = splitProvider.familyMembers;
        if (members.isEmpty) return const SizedBox.shrink();

        return Container(
          height: 96,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: members.length + 1,
            itemBuilder: (context, index) {
              if (index == members.length) {
                return _buildAddMemberAvatar();
              }
              final member = members[index];
              final splitOwed = splitProvider.getTotalOwedTo(member.id);
              final splitOwes = splitProvider.getTotalOwedBy(member.id);
              final splitNet = splitOwed - splitOwes;

              final debtSummary = debtProvider.summaryByPerson
                  .where((s) => s.personId == member.id)
                  .firstOrNull;
              final debtNet = debtSummary?.netBalance ?? 0;

              return _buildMemberAvatar(member, splitNet + debtNet);
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: () => _showContactDetailSheet(member),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cardSurface,
                border: Border.all(
                  color: balance != 0
                      ? balanceColor
                      : Colors.white.withValues(alpha: 0.1),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: balance != 0 ? balanceColor : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 60,
              child: Text(
                member.name.split(' ').first,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ),
            if (balance != 0)
              Text(
                '${isPositive ? '+' : ''}₹${AppCurrency.format(balance.abs())}',
                style: TextStyle(
                  color: balanceColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMemberAvatar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: _openAddMember,
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cardSurface,
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(
                Icons.add,
                color: AppColors.textTertiary,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
            ),
          ],
        ),
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
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Splits'),
          Tab(text: 'Direct IOUs'),
          Tab(text: 'People'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer2<SharedExpenseProvider, FamilyDebtProvider>(
      builder: (context, splitProvider, debtProvider, _) {
        final settlements = splitProvider.calculateSettlements();
        final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

        final splitOwe = splitProvider.getTotalOwedBy(currentUserId);
        final splitOwed = splitProvider.getTotalOwedTo(currentUserId);

        final totalOwe = splitOwe + debtProvider.totalIOweTo;
        final totalOwed = splitOwed + debtProvider.totalOwedToMe;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'You Owe (Total)',
                      '₹${AppCurrency.format(totalOwe)}',
                      AppColors.error,
                      Icons.arrow_upward,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'You\'re Owed',
                      '₹${AppCurrency.format(totalOwed)}',
                      AppColors.success,
                      Icons.arrow_downward,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionHeader(
                'Pending Group Settlements',
                Icons.swap_horiz,
              ),
              const SizedBox(height: 12),
              if (settlements.isEmpty)
                _buildEmptyState(
                  'No group settlements pending',
                  'Everyone is squared away on shared expenses.',
                  Icons.check_circle_outline,
                )
              else
                ...settlements.map((s) => _buildSettlementCard(s)),

              const SizedBox(height: 24),

              _buildSectionHeader(
                'Direct Balances By Person',
                Icons.people_outline,
              ),
              const SizedBox(height: 12),
              if (debtProvider.summaryByPerson.isEmpty)
                _buildEmptyState(
                  'No active 1-on-1 IOUs',
                  'Tap + to record personal borrowing or lending.',
                  Icons.handshake_outlined,
                )
              else
                ...debtProvider.summaryByPerson.map(
                  (s) => _buildPersonDebtSummaryCard(s),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpensesTab() {
    return Consumer<SharedExpenseProvider>(
      builder: (context, provider, _) {
        if (provider.expenses.isEmpty) {
          return Center(
            child: _buildEmptyState(
              'No shared splits',
              'Log group expenses like dining, travel, or rent.',
              Icons.receipt_long_outlined,
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: provider.expenses.length,
          itemBuilder: (context, index) =>
              _buildExpenseCard(provider.expenses[index]),
        );
      },
    );
  }

  Widget _buildFamilyDebtsTab() {
    return Consumer<FamilyDebtProvider>(
      builder: (context, provider, _) {
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        final debts = provider.debts.where((d) => !d.isSettled).toList();

        if (debts.isEmpty) {
          return Center(
            child: _buildEmptyState(
              'No direct IOUs',
              'Record money directly lent or borrowed between contacts.',
              Icons.handshake_outlined,
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: debts.length,
          itemBuilder: (context, index) {
            final debt = debts[index];
            final isLentByMe = debt.creditorId == currentUserId;
            final otherPartyName = isLentByMe
                ? debt.debtorName
                : debt.creditorName;
            final color = isLentByMe ? AppColors.success : AppColors.error;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(
                      isLentByMe ? Icons.arrow_outward : Icons.arrow_downward,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debt.description ??
                              (isLentByMe
                                  ? 'Lent to $otherPartyName'
                                  : 'Borrowed from $otherPartyName'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isLentByMe
                              ? '$otherPartyName owes you'
                              : 'You owe $otherPartyName',
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
                        '₹${AppCurrency.format(debt.currentAmount)}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ElevatedButton(
                        onPressed: () => _showDetailedSettleSheet(debt),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color.withValues(alpha: 0.15),
                          foregroundColor: color,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          minimumSize: const Size(64, 28),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: color.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                        child: const Text(
                          'Settle',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    color: AppColors.cardElevated,
                    onSelected: (val) {
                      if (val == 'edit') {
                        AddFamilyDebtModal.show(context, debtToEdit: debt);
                      } else if (val == 'delete') {
                        _confirmDeleteFamilyDebt(debt);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: Colors.white70,
                            ),
                            SizedBox(width: 8),
                            Text('Edit', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: AppColors.error,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
            GestureDetector(
              onTap: _openAddMember,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_add_outlined,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Add New Contact',
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
            ...provider.familyMembers.map((m) => _buildMemberCard(m, provider)),
          ],
        );
      },
    );
  }

  Widget _buildMemberCard(FamilyMember member, SharedExpenseProvider provider) {
    final owes = provider.getTotalOwedBy(member.id);
    final owed = provider.getTotalOwedTo(member.id);
    final net = owed - owes;

    return GestureDetector(
      onTap: () => _showContactDetailSheet(member),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
              child: Text(
                member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Tap to view shared breakdown',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              net >= 0
                  ? '+₹${AppCurrency.format(net)}'
                  : '-₹${AppCurrency.format(net.abs())}',
              style: TextStyle(
                color: net >= 0 ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: AppColors.textSecondary,
                size: 18,
              ),
              color: AppColors.cardElevated,
              onSelected: (action) {
                if (action == 'edit') {
                  _editMember(member);
                } else if (action == 'delete') {
                  _removeMember(member);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit', style: TextStyle(color: Colors.white)),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCard(SharedExpense expense) {
    final isExpanded = _expandedExpenseIds.contains(expense.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedExpenseIds.remove(expense.id);
                } else {
                  _expandedExpenseIds.add(expense.id);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
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
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Paid by ${expense.paidByName} • ${DateFormat('MMM d').format(expense.date)}',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${AppCurrency.format(expense.totalAmount)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppColors.textTertiary,
                        size: 18,
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    color: AppColors.cardElevated,
                    onSelected: (value) {
                      if (value == 'edit') {
                        ModernAddSharedExpenseScreen.show(
                          context,
                          expense: expense,
                        );
                      } else if (value == 'delete') {
                        _deleteExpense(expense);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: Colors.white70,
                            ),
                            SizedBox(width: 8),
                            Text('Edit', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: AppColors.error,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(color: Colors.white12, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PARTICIPANT BREAKDOWN',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...expense.splits.map(
                    (s) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            s.personName,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '₹${AppCurrency.format(s.amount)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showContactDetailSheet(FamilyMember member) {
    final splitProvider = context.read<SharedExpenseProvider>();
    final debtProvider = context.read<FamilyDebtProvider>();

    final memberSplits = splitProvider.expenses
        .where(
          (e) =>
              e.splits.any((s) => s.personId == member.id) ||
              e.paidBy == member.id,
        )
        .toList();

    final memberIOUs = debtProvider.getDebtsWithPerson(member.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              member.name,
              style: AppTypography.headlineMedium.copyWith(color: Colors.white),
            ),
            Text(
              'Full balance history and involved splits',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  if (memberIOUs.isNotEmpty) ...[
                    const Text(
                      'DIRECT IOUS',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...memberIOUs.map(
                      (d) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          d.description ?? 'Personal IOU',
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: Text(
                          '₹${AppCurrency.format(d.currentAmount)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    'SHARED SPLIT EXPENSES',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (memberSplits.isEmpty)
                    const Text(
                      'No shared splits with this person yet.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    )
                  else
                    ...memberSplits.map((e) {
                      final split = e.splits.firstWhere(
                        (s) => s.personId == member.id,
                        orElse: () => ExpenseSplit(
                          personId: '',
                          personName: '',
                          amount: 0,
                        ),
                      );
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          e.description,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          DateFormat('d MMM yyyy').format(e.date),
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                        trailing: Text(
                          '₹${AppCurrency.format(split.amount)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailedSettleSheet(FamilyDebt debt) {
    final amountController = TextEditingController(
      text: debt.currentAmount.toStringAsFixed(0),
    );
    Account? selectedAccount;
    bool recordInBank = false;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
          final isLentByMe =
              debt.creditorId == FirebaseAuth.instance.currentUser?.uid;
          final otherParty = isLentByMe ? debt.debtorName : debt.creditorName;

          return Material(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLg),
            ),
            child: Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.xl + bottomInset,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.borderSubtleDark,
                          borderRadius: AppSpacing.borderRadiusFull,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Settle Balance',
                      style: AppTypography.headlineMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      isLentByMe
                          ? 'Receiving payment from $otherParty'
                          : 'Making payment to $otherParty',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    Text(
                      'SETTLEMENT AMOUNT',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        prefixText: '₹ ',
                        prefixStyle: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 22,
                        ),
                        filled: true,
                        fillColor: AppColors.darkSurfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.borderSubtleDark,
                          ),
                        ),
                        suffixText:
                            'Max: ₹${AppCurrency.format(debt.currentAmount)}',
                        suffixStyle: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.darkSurfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSubtleDark),
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          'Record in Bank Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          isLentByMe
                              ? 'Deposits money into your account'
                              : 'Debits money from your account',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                        value: recordInBank,
                        activeThumbColor: AppColors.primaryBlue,
                        onChanged: (val) =>
                            setModalState(() => recordInBank = val),
                      ),
                    ),

                    if (recordInBank) ...[
                      const SizedBox(height: 16),
                      Text(
                        'PAY / DEPOSIT ACCOUNT',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Consumer<AccountProvider>(
                        builder: (context, accProvider, _) {
                          if (selectedAccount == null &&
                              accProvider.accounts.isNotEmpty) {
                            selectedAccount = accProvider.accounts.first;
                          }
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: AppColors.darkSurfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.borderSubtleDark,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<Account>(
                                value: selectedAccount,
                                isExpanded: true,
                                dropdownColor: AppColors.cardElevated,
                                items: accProvider.accounts.map((acc) {
                                  return DropdownMenuItem(
                                    value: acc,
                                    child: Row(
                                      children: [
                                        Text(
                                          acc.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '₹${acc.balance.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            color: AppColors.textTertiary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (acc) =>
                                    setModalState(() => selectedAccount = acc),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final amount = double.tryParse(
                                  amountController.text.trim(),
                                );
                                if (amount == null || amount <= 0) return;

                                setModalState(() => isSubmitting = true);

                                final user = FirebaseAuth.instance.currentUser;
                                if (recordInBank &&
                                    selectedAccount != null &&
                                    user != null) {
                                  final txn = Transaction(
                                    id: DateTime.now().millisecondsSinceEpoch
                                        .toString(),
                                    userId: user.uid,
                                    type: isLentByMe
                                        ? TransactionType.income
                                        : TransactionType.expense,
                                    amount: amount,
                                    description: isLentByMe
                                        ? 'Settlement received from ${debt.debtorName}'
                                        : 'Settlement paid to ${debt.creditorName}',
                                    categoryId: 'transfer',
                                    accountId: selectedAccount!.id,
                                    date: DateTime.now(),
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  );
                                  await context
                                      .read<TransactionProvider>()
                                      .commitDraft(
                                        TransactionDraft.fromTransaction(txn),
                                      );
                                }

                                final debtProvider = context
                                    .read<FamilyDebtProvider>();
                                if (amount >= debt.currentAmount) {
                                  await debtProvider.settleDebt(debt.id);
                                } else {
                                  await debtProvider.recordPayment(
                                    debt.id,
                                    amount,
                                    notes: 'Partial settlement',
                                  );
                                }

                                if (mounted) Navigator.pop(sheetContext);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Confirm Settlement',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPersonDebtSummaryCard(FamilyDebtSummary summary) {
    final isPositive = summary.netBalance > 0;
    final color = isPositive ? AppColors.success : AppColors.error;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            summary.personName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            summary.summary,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementCard(SettlementSummary settlement) {
    return NexusCard(
      color: AppColors.cardSurface,
      padding: AppSpacing.cardPaddingMd,
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.error.withValues(alpha: 0.2),
            child: Text(
              settlement.person2Name[0].toUpperCase(),
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${settlement.person2Name} owes ${settlement.person1Name}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '₹${AppCurrency.format(settlement.netAmount)}',
            style: const TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textTertiary, size: 16),
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

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryBlue, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.receipt_long,
                color: AppColors.primaryBlue,
              ),
              title: const Text(
                'Add Group Split Expense',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Split dinner, trips, groceries among members',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                ModernAddSharedExpenseScreen.show(context);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.handshake_outlined,
                color: AppColors.success,
              ),
              title: const Text(
                'Record 1-on-1 IOU / Personal Balance',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Money directly borrowed or lent to an individual',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                AddFamilyDebtModal.show(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _editMember(FamilyMember member) async {
    final controller = TextEditingController(text: member.name);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardElevated,
        title: const Text(
          'Edit member name',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.isNotEmpty && mounted) {
      await context.read<SharedExpenseProvider>().updateFamilyMember(
        FamilyMember(
          id: member.id,
          name: name,
          email: member.email,
          avatarUrl: member.avatarUrl,
          isActive: member.isActive,
        ),
      );
    }
  }

  Future<void> _removeMember(FamilyMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardElevated,
        title: const Text(
          'Remove Contact?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Remove ${member.name} from your contacts?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<SharedExpenseProvider>().removeFamilyMember(member.id);
    }
  }

  Future<void> _confirmDeleteFamilyDebt(FamilyDebt debt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardElevated,
        title: const Text('Delete IOU?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete this record with ${debt.debtorName}? This cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<FamilyDebtProvider>().deleteDebt(debt.id);
    }
  }

  Future<void> _deleteExpense(SharedExpense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardElevated,
        title: const Text(
          'Delete Expense?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Remove "${expense.description}" from your shared balances?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<SharedExpenseProvider>().deleteSharedExpense(
        expense.id,
      );
    }
  }
}
