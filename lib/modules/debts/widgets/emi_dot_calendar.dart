import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

/// EMI Dot Calendar
/// Shows one dot per EMI month. Paid = filled. Current = pulsing outlined.
/// Tapping the current unpaid month dot triggers onMarkPaid.
class EmiDotCalendar extends StatefulWidget {
  final int totalMonths;
  final int paidMonths;
  final DateTime? startDate;
  final Color typeColor;
  final VoidCallback? onMarkPaid;

  const EmiDotCalendar({
    super.key,
    required this.totalMonths,
    required this.paidMonths,
    required this.typeColor,
    this.startDate,
    this.onMarkPaid,
  });

  @override
  State<EmiDotCalendar> createState() => _EmiDotCalendarState();
}

class _EmiDotCalendarState extends State<EmiDotCalendar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _monthLabel(int index) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    if (widget.startDate != null) {
      final month = (widget.startDate!.month - 1 + index) % 12;
      return months[month];
    }
    return months[index % 12];
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.totalMonths.clamp(1, 60);
    final paid = widget.paidMonths.clamp(0, total);
    final now = DateTime.now();

    // Which index is the current month?
    int? currentMonthIndex;
    if (widget.startDate != null) {
      final monthsElapsed =
          (now.year - widget.startDate!.year) * 12 +
          (now.month - widget.startDate!.month);
      if (monthsElapsed >= 0 && monthsElapsed < total) {
        currentMonthIndex = monthsElapsed;
      }
    } else {
      currentMonthIndex = paid; // best guess
    }

    // For long tenures show a window: last 3 paid + next 6 unpaid, max 9 dots
    List<int> indices;
    if (total <= 12) {
      indices = List.generate(total, (i) => i);
    } else {
      final start = (paid - 3).clamp(0, total - 1);
      final end = (start + 9).clamp(0, total);
      indices = List.generate(end - start, (i) => start + i);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress fraction text
        Row(
          children: [
            Text(
              '$paid/$total EMIs',
              style: TextStyle(
                color: widget.typeColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (total > 12)
              Text(
                'showing ${indices.first + 1}–${indices.last + 1}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 9,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Dot row
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: indices.map((i) {
            final isPaid = i < paid;
            final isCurrent = i == currentMonthIndex && !isPaid;
            final isMissed = i < (currentMonthIndex ?? paid) && !isPaid;

            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _buildDot(
                index: i,
                isPaid: isPaid,
                isCurrent: isCurrent,
                isMissed: isMissed,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDot({
    required int index,
    required bool isPaid,
    required bool isCurrent,
    required bool isMissed,
  }) {
    final color = isPaid
        ? widget.typeColor
        : isMissed
        ? AppColors.error
        : isCurrent
        ? widget.typeColor
        : Colors.white.withValues(alpha: 0.15);

    Widget dot = Column(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isPaid ? color : Colors.transparent,
            border: Border.all(
              color: isPaid
                  ? color
                  : isMissed
                  ? AppColors.error
                  : isCurrent
                  ? widget.typeColor
                  : Colors.white.withValues(alpha: 0.2),
              width: isPaid ? 0 : 1.5,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          _monthLabel(index),
          style: TextStyle(
            color: isPaid
                ? widget.typeColor.withValues(alpha: 0.8)
                : isCurrent
                ? widget.typeColor
                : Colors.white.withValues(alpha: 0.25),
            fontSize: 7,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );

    // Pulse animation on current month dot
    if (isCurrent) {
      dot = AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) => Opacity(
          opacity: _pulseAnimation.value,
          child: child,
        ),
        child: dot,
      );

      // Make it tappable
      if (widget.onMarkPaid != null) {
        dot = GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            widget.onMarkPaid!();
          },
          child: dot,
        );
      }
    }

    return dot;
  }
}
