import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/models/goal.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/top_snackbar.dart';
import 'widgets/add_goal_modal.dart';

class ModernGoalsScreen extends StatefulWidget {
  const ModernGoalsScreen({super.key});

  @override
  State<ModernGoalsScreen> createState() => _ModernGoalsScreenState();
}

class _ModernGoalsScreenState extends State<ModernGoalsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  Stream<List<Goal>> _getGoalsStream() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('goals')
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Goal.fromMap({'id': doc.id, ...doc.data()}))
              .toList(),
        );
  }

  Future<void> _addGoal(Goal goal) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final goalData = goal.toMap();
        goalData['userId'] = user.uid;

        await FirebaseFirestore.instance.collection('goals').add(goalData);

        if (mounted) {
          showTopSnackBar(context, 'Goal added successfully');
        }
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(context, 'Error adding goal: $e', isError: true);
      }
    }
  }

  Future<void> _updateGoal(Goal goal) async {
    try {
      await FirebaseFirestore.instance
          .collection('goals')
          .doc(goal.id)
          .update(goal.toMap());

      if (mounted) {
        showTopSnackBar(context, 'Goal updated successfully');
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(context, 'Error updating goal: $e', isError: true);
      }
    }
  }

  Future<void> _deleteGoal(Goal goal) async {
    try {
      await FirebaseFirestore.instance
          .collection('goals')
          .doc(goal.id)
          .delete();

      if (mounted) {
        showTopSnackBar(context, 'Goal deleted successfully');
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(context, 'Error deleting goal: $e', isError: true);
      }
    }
  }

  void _showEditGoalModal(Goal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          AddGoalModal(onGoalAdded: _updateGoal, goalToEdit: goal),
    );
  }

  void _showDeleteConfirmation(Goal goal) async {
    final confirmed = await AppDialog.showDeleteConfirmation(
      context,
      itemName: goal.name,
    );
    if (confirmed == true) {
      _deleteGoal(goal);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: StreamBuilder<List<Goal>>(
        stream: _getGoalsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState(context, snapshot.error.toString());
          }

          final goals = snapshot.data ?? [];

          return CustomScrollView(
            slivers: [
              // 1. GOLDEN HEADER
              SliverAppBar(
                pinned: true,
                expandedHeight: 110,
                backgroundColor: AppColors.backgroundBlack,
                surfaceTintColor: AppColors.backgroundBlack,
                elevation: 0,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 24),
                  title: Text(
                    'Goals',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              // 2. HERO OVERVIEW (Total Savings Progress)
              if (goals.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: _buildOverviewCard(context, goals),
                  ),
                ),

              // 3. GOALS BENTO GRID
              if (goals.isEmpty)
                SliverFillRemaining(child: _buildEmptyState(context))
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    child: _buildBentoGoalsGrid(context, goals),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: FloatingActionButton.extended(
          onPressed: () => showAddGoalModal(context, _addGoal),
          backgroundColor: AppColors.cardSurface,
          icon: Icon(Icons.add, color: AppColors.accentPurple),
          label: Text(
            'New Goal',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.accentPurple,
            ),
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(color: AppColors.accentPurple.withOpacity(0.3)),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, List<Goal> goals) {
    final totalTarget = goals.fold<double>(
      0,
      (sum, goal) => sum + goal.targetAmount,
    );
    final totalSaved = goals.fold<double>(
      0,
      (sum, goal) => sum + goal.currentAmount,
    );
    final progress = totalTarget > 0 ? (totalSaved / totalTarget) : 0.0;
    final completedGoals = goals
        .where((g) => g.currentAmount >= g.targetAmount)
        .length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentTeal.withOpacity(0.25),
            AppColors.accentPurple.withOpacity(0.15),
            AppColors.cardSurface,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.accentTeal.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentTeal.withOpacity(0.15),
            blurRadius: 30,
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
              Text(
                'TOTAL SAVINGS',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentTeal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accentTeal.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flag_rounded,
                      color: AppColors.accentTeal,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$completedGoals/${goals.length} Done',
                      style: TextStyle(
                        color: AppColors.accentTeal,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${_formatAmount(totalSaved)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '/ ${_formatAmount(totalTarget)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Premium progress bar with glow
          Stack(
            children: [
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.accentPurple, AppColors.accentTeal],
                    ),
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentTeal.withOpacity(0.6),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Remaining: ₹${_formatAmount(totalTarget - totalSaved)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentTeal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(progress * 100).toStringAsFixed(0)}% Achieved',
                  style: TextStyle(
                    color: AppColors.accentTeal,
                    fontSize: 12,
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

  // ========== BENTO GRID LAYOUT ==========
  Widget _buildBentoGoalsGrid(BuildContext context, List<Goal> goals) {
    // Sort by target amount (highest first) for bento importance
    final sorted = List<Goal>.from(goals)
      ..sort((a, b) => b.targetAmount.compareTo(a.targetAmount));

    final List<Widget> rows = [];
    int index = 0;

    while (index < sorted.length) {
      final remaining = sorted.length - index;

      if (remaining == 1) {
        // Single item: wide tile
        rows.add(_buildBentoTile(context, sorted[index], isWide: true));
        index++;
      } else if (remaining == 2) {
        // Two items: two large squares OR wide + compact
        if (index == 0) {
          // First two: two large squares side by side
          rows.add(
            Row(
              children: [
                Expanded(
                  child: _buildBentoTile(context, sorted[index], isLarge: true),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBentoTile(
                    context,
                    sorted[index + 1],
                    isLarge: true,
                  ),
                ),
              ],
            ),
          );
        } else {
          // Later: row of 2 compact
          rows.add(
            Row(
              children: [
                Expanded(
                  child: _buildBentoTile(
                    context,
                    sorted[index],
                    isCompact: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBentoTile(
                    context,
                    sorted[index + 1],
                    isCompact: true,
                  ),
                ),
              ],
            ),
          );
        }
        index += 2;
      } else if (remaining >= 3 && index == 0) {
        // First row: 2 large squares
        rows.add(
          Row(
            children: [
              Expanded(
                child: _buildBentoTile(context, sorted[index], isLarge: true),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBentoTile(
                  context,
                  sorted[index + 1],
                  isLarge: true,
                ),
              ),
            ],
          ),
        );
        index += 2;
      } else if (remaining >= 3) {
        // Pattern: 1 wide + 2 stacked compact
        rows.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildBentoTile(context, sorted[index], isWide: true),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(
                        child: _buildBentoTile(
                          context,
                          sorted[index + 1],
                          isCompact: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _buildBentoTile(
                          context,
                          sorted[index + 2],
                          isCompact: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        index += 3;
      }

      rows.add(const SizedBox(height: 12));
    }

    return Column(children: rows);
  }

  Widget _buildBentoTile(
    BuildContext context,
    Goal goal, {
    bool isLarge = false,
    bool isWide = false,
    bool isCompact = false,
  }) {
    final progress = goal.targetAmount > 0
        ? (goal.currentAmount / goal.targetAmount)
        : 0.0;
    final percentage = (progress * 100).clamp(0, 100).round();
    final isCompleted = percentage >= 100;
    final goalColor = _getGoalColor(goal.name);

    if (isLarge) {
      // Large square tile
      return GestureDetector(
        onTap: () => _showEditGoalModal(goal),
        onLongPress: () => _showDeleteConfirmation(goal),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: isCompleted
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.success.withOpacity(0.2),
                        AppColors.cardSurface,
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        goalColor.withOpacity(0.2),
                        AppColors.cardSurface,
                      ],
                    ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: (isCompleted ? AppColors.success : goalColor)
                    .withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: (isCompleted ? AppColors.success : goalColor)
                      .withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isCompleted ? AppColors.success : goalColor)
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isCompleted ? Icons.check_circle : Icons.flag_rounded,
                        color: isCompleted ? AppColors.success : goalColor,
                        size: 22,
                      ),
                    ),
                    const Spacer(),
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'ACHIEVED',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: goalColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$percentage%',
                          style: TextStyle(
                            color: goalColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  goal.name,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${_formatAmount(goal.currentAmount)} / ${_formatAmount(goal.targetAmount)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                // Progress bar
                Stack(
                  children: [
                    Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isCompleted
                                ? [AppColors.success, AppColors.success]
                                : [goalColor, AppColors.accentTeal],
                          ),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isCompleted
                                          ? AppColors.success
                                          : AppColors.accentTeal)
                                      .withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isCompleted
                      ? 'Goal achieved! 🎉'
                      : '₹${_formatAmount(goal.targetAmount - goal.currentAmount)} to go',
                  style: TextStyle(
                    color: isCompleted
                        ? AppColors.success
                        : AppColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (isWide) {
      // Wide horizontal tile
      return GestureDetector(
        onTap: () => _showEditGoalModal(goal),
        onLongPress: () => _showDeleteConfirmation(goal),
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: isCompleted
                ? LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.success.withOpacity(0.15),
                      AppColors.cardSurface,
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      goalColor.withOpacity(0.15),
                      AppColors.cardSurface,
                    ],
                  ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: (isCompleted ? AppColors.success : goalColor).withOpacity(
                0.15,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (isCompleted ? AppColors.success : goalColor)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.flag_rounded,
                  color: isCompleted ? AppColors.success : goalColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      goal.name,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Progress bar
                    Stack(
                      children: [
                        Container(
                          height: 6,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isCompleted
                                    ? [AppColors.success, AppColors.success]
                                    : [goalColor, AppColors.accentTeal],
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${_formatAmount(goal.currentAmount)} of ₹${_formatAmount(goal.targetAmount)}',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'DONE',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: goalColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$percentage%',
                        style: TextStyle(
                          color: goalColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      // Compact tile
      return GestureDetector(
        onTap: () => _showEditGoalModal(goal),
        onLongPress: () => _showDeleteConfirmation(goal),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (isCompleted ? AppColors.success : goalColor).withOpacity(
                0.15,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle : Icons.flag_rounded,
                    color: isCompleted ? AppColors.success : goalColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      goal.name,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Progress bar
              Stack(
                children: [
                  Container(
                    height: 4,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: isCompleted ? AppColors.success : goalColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${_formatAmount(goal.targetAmount)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: (isCompleted ? AppColors.success : goalColor)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isCompleted ? '✓' : '$percentage%',
                      style: TextStyle(
                        color: isCompleted ? AppColors.success : goalColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
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

  Color _getGoalColor(String name) {
    // Generate a consistent color based on goal name
    final colors = [
      Colors.purple,
      Colors.blue,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated gradient container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.accentTeal.withOpacity(0.2),
                    AppColors.accentPurple.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: AppColors.accentTeal.withOpacity(0.2),
                ),
              ),
              child: Icon(
                Icons.flag_rounded,
                size: 56,
                color: AppColors.accentTeal.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "No Goals Yet",
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Set savings targets and track\nyour progress to financial freedom",
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            // Add Goal Button
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accentTeal, AppColors.accentPurple],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentTeal.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => showAddGoalModal(context, _addGoal),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_circle_outline,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Create Your First Goal',
                          style: AppTypography.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Quick suggestions
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('Emergency Fund', Icons.shield_outlined),
                _buildSuggestionChip('Vacation', Icons.flight_outlined),
                _buildSuggestionChip('New Car', Icons.directions_car_outlined),
                _buildSuggestionChip('Home', Icons.home_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String label, IconData icon) {
    return GestureDetector(
      onTap: () => showAddGoalModal(context, _addGoal),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.textTertiary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Error loading goals',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            Text(
              error,
              style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(amount % 100000 == 0 ? 0 : 1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }
}
