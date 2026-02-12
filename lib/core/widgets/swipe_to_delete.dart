import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import 'top_snackbar.dart';

// Global set to track recently restored item IDs for animation
final Set<String> _recentlyRestoredItems = {};

// Global map to store undo callbacks by item ID to prevent stale closure issues
final Map<String, VoidCallback> _undoCallbacks = {};

/// A reusable swipe-to-delete widget with consistent behavior across the app.
///
/// Features:
/// - Consistent right-to-left swipe direction
/// - Optional confirmation dialog before delete
/// - Undo functionality via SnackBar
/// - Smooth restore animation when undo is pressed
/// - Customizable delete action
class SwipeToDelete<T> extends StatefulWidget {
  /// Unique key for the item
  final Key itemKey;

  /// The child widget to wrap
  final Widget child;

  /// Called when the item should be deleted
  final VoidCallback onDelete;

  /// Called when user taps undo - should restore the item
  /// If null, undo won't be available
  final VoidCallback? onUndoDelete;

  /// The name/description of the item being deleted (for snackbar message)
  final String itemName;

  /// Unique ID for tracking restore animations
  final String itemId;

  /// Whether to show a confirmation dialog before delete
  final bool showConfirmation;

  /// Custom confirmation title
  final String? confirmTitle;

  /// Custom confirmation message
  final String? confirmMessage;

  /// Whether swipe is enabled
  final bool enabled;

  /// Duration for undo snackbar (default 5 seconds)
  final Duration undoDuration;

  const SwipeToDelete({
    super.key,
    required this.itemKey,
    required this.child,
    required this.onDelete,
    required this.itemId,
    this.onUndoDelete,
    this.itemName = 'Item',
    this.showConfirmation = false,
    this.confirmTitle,
    this.confirmMessage,
    this.enabled = true,
    this.undoDuration = const Duration(seconds: 5),
  });

  @override
  State<SwipeToDelete<T>> createState() => _SwipeToDeleteState<T>();
}

class _SwipeToDeleteState<T> extends State<SwipeToDelete<T>>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _shouldAnimate = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(-0.3, 0.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Check if this item was recently restored
    if (_recentlyRestoredItems.contains(widget.itemId)) {
      _shouldAnimate = true;
      _recentlyRestoredItems.remove(widget.itemId);
      // Start animation after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _animationController.forward();
        }
      });
    } else {
      // No animation needed, set to completed state
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Dismissible(
      key: widget.itemKey,
      direction: widget.enabled
          ? DismissDirection.endToStart
          : DismissDirection.none,
      confirmDismiss: widget.showConfirmation
          ? (_) => _showConfirmDialog(context)
          : null,
      onDismissed: (_) => _handleDismiss(context),
      background: _buildBackground(),
      child: widget.child,
    );

    // Wrap with animation if this item was restored
    if (_shouldAnimate) {
      content = FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(position: _slideAnimation, child: content),
      );
    }

    return content;
  }

  Widget _buildBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.error.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Delete',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 24),
        ],
      ),
    );
  }

  Future<bool> _showConfirmDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              backgroundColor: AppColors.cardDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              title: Text(
                widget.confirmTitle ?? 'Delete ${widget.itemName}',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              content: Text(
                widget.confirmMessage ??
                    'Are you sure you want to delete this ${widget.itemName}?',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.error.withOpacity(0.1),
                  ),
                  child: Text(
                    'Delete',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _handleDismiss(BuildContext context) {
    // Capture the itemId and callback in local variables before any async operations
    final itemId = widget.itemId;
    final undoCallback = widget.onUndoDelete;
    final itemName = widget.itemName;
    final deleteCallback = widget.onDelete;
    final undoDuration = widget.undoDuration;

    // Store the undo callback BEFORE deletion to capture current state
    if (undoCallback != null) {
      _undoCallbacks[itemId] = undoCallback;
      print('💾 SwipeToDelete: Stored undo callback for item $itemId');
      print('📋 Current stored callbacks: ${_undoCallbacks.keys.toList()}');
    }

    // Delete the item with a small delay to allow animation to complete
    print('🗑️ SwipeToDelete: Scheduling deletion for item $itemId');

    // Schedule deletion after current frame to avoid conflicts with dismiss animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🗑️ SwipeToDelete: Executing deletion for item $itemId');
      deleteCallback();
    });

    // Safety check before showing snackbar
    if (!context.mounted) {
      print('⚠️ SwipeToDelete: Context not mounted, skipping snackbar');
      return;
    }

    // Show snackbar with or without undo using top snackbar (doesn't block navbar)
    try {
      showTopSnackBar(
        context,
        '$itemName deleted',
        icon: Icons.delete_outline_rounded,
        backgroundColor: AppColors.cardDarkElevated,
        duration: undoDuration,
        action: undoCallback != null
            ? TopSnackBarAction(
                label: 'UNDO',
                onPressed: () {
                  print('↩️ SwipeToDelete: UNDO pressed for item $itemId');
                  print(
                    '📋 Available callbacks: ${_undoCallbacks.keys.toList()}',
                  );

                  // Retrieve the stored callback
                  final storedCallback = _undoCallbacks[itemId];
                  if (storedCallback == null) {
                    print(
                      '❌ SwipeToDelete: No undo callback found for $itemId',
                    );
                    return;
                  }

                  // Mark this item for animation when it reappears
                  _recentlyRestoredItems.add(itemId);

                  // Restore the item using the stored callback
                  print(
                    '📞 SwipeToDelete: Calling stored onUndoDelete callback',
                  );
                  storedCallback();
                  print('✅ SwipeToDelete: onUndoDelete callback completed');

                  // Clean up the stored callback
                  _undoCallbacks.remove(itemId);

                  // Note: Skip showing restored snackbar - context may be invalid
                },
              )
            : null,
      );
    } catch (e) {
      print('⚠️ SwipeToDelete: Error showing snackbar: $e');
    }
  }
}
