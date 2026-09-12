import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/providers/shared_expense_provider.dart';
import '../../../core/models/shared_expense.dart';
import '../../../core/services/firestore_service.dart';

class ModernAddFamilyMemberScreen extends StatefulWidget {
  const ModernAddFamilyMemberScreen({super.key});

  /// Presents the sheet as a standard modal bottom sheet (same pattern as
  /// ModernAddSharedExpenseScreen), which handles the slide transition and
  /// barrier itself.
  static Future<FamilyMember?> show(BuildContext context) {
    return showModalBottomSheet<FamilyMember>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => const ModernAddFamilyMemberScreen(),
    );
  }

  @override
  State<ModernAddFamilyMemberScreen> createState() =>
      _ModernAddFamilyMemberScreenState();
}

class _ModernAddFamilyMemberScreenState
    extends State<ModernAddFamilyMemberScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isSavingManual = false;

  // Don't attach the live Firestore-backed user list until the sheet's
  // entrance transition has settled. Rebuilding a StreamBuilder mid-animation
  // is what was triggering the '!semantics.parentDataDirty' assertion crash.
  bool _showNexusUsersList = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = ModalRoute.of(context);
      if (route?.animation != null) {
        void onStatus(AnimationStatus status) {
          if (status == AnimationStatus.completed) {
            route!.animation!.removeStatusListener(onStatus);
            if (mounted) setState(() => _showNexusUsersList = true);
          }
        }

        route!.animation!.addStatusListener(onStatus);
        if (route.animation!.isCompleted) {
          onStatus(AnimationStatus.completed);
        }
      } else {
        setState(() => _showNexusUsersList = true);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _addManualMember() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a name'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSavingManual = true);

    try {
      final provider = context.read<SharedExpenseProvider>();
      final newMember = FamilyMember(
        id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
      );

      await provider.addFamilyMember(newMember);

      if (mounted) {
        Navigator.of(context).pop(newMember);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newMember.name} added!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingManual = false);
    }
  }

  Future<void> _addRegisteredUser(Map<String, dynamic> userData) async {
    try {
      final provider = context.read<SharedExpenseProvider>();
      final userId = userData['uid']?.toString();
      final userName = (userData['displayName'] ?? userData['name'])?.toString().trim();
      final userEmail = userData['email']?.toString().trim();
      final member = FamilyMember(
        id: (userId != null && userId.isNotEmpty)
            ? userId
            : 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: (userName != null && userName.isNotEmpty) ? userName : 'Unknown',
        email: (userEmail != null && userEmail.isNotEmpty) ? userEmail : null,
      );

      await provider.addFamilyMember(member);
      if (mounted) {
        Navigator.of(context).pop(member);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.name} added!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final totalHeight = mediaQuery.size.height * 0.85;

    return Container(
      height: totalHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.lg + bottomInset,
      ),
      child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
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

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add Member',
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textSecondary,
                        size: AppSpacing.iconSm,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Add a contact manually or pick a registered Nexus user.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Manual Input: Name
                TextField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Full Name (e.g. Alex)',
                    hintStyle: TextStyle(color: AppColors.textTertiary),
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: AppColors.darkSurfaceElevated,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      borderSide: const BorderSide(
                        color: AppColors.borderSubtleDark,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      borderSide: const BorderSide(
                        color: AppColors.borderSubtleDark,
                      ),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(AppSpacing.radiusSm),
                      ),
                      borderSide: BorderSide(
                        color: AppColors.primaryBlue,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Manual Input: Email / Phone + Add Button
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addManualMember(),
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Email or phone (optional)',
                          hintStyle: TextStyle(color: AppColors.textTertiary),
                          prefixIcon: const Icon(
                            Icons.mail_outline,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: AppColors.darkSurfaceElevated,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                            borderSide: const BorderSide(
                              color: AppColors.borderSubtleDark,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                            borderSide: const BorderSide(
                              color: AppColors.borderSubtleDark,
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(AppSpacing.radiusSm),
                            ),
                            borderSide: BorderSide(
                              color: AppColors.primaryBlue,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ElevatedButton(
                      onPressed: _isSavingManual ? null : _addManualMember,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                        ),
                      ),
                      child: _isSavingManual
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Section Divider
                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: AppColors.borderSubtleDark),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Text(
                        'OR CHOOSE FROM NEXUS',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(color: AppColors.borderSubtleDark),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Stream list of registered Nexus users
                Expanded(
                  child: !_showNexusUsersList
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryBlue,
                          ),
                        )
                      : StreamBuilder<List<Map<String, dynamic>>>(
                    stream: FirestoreService.getRegisteredUsersStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryBlue,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Could not load Nexus users. Use the form above to add members.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }

                      final users =
                          snapshot.data ?? const <Map<String, dynamic>>[];
                      if (users.isEmpty) {
                        return Center(
                          child: Text(
                            'No other Nexus users found.\nAdd anyone manually using the fields above.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 13,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: users.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final rawName = user['name']?.toString().trim();
                          final name = (rawName != null && rawName.isNotEmpty)
                              ? rawName
                              : 'Unknown User';
                          final rawEmail = user['email']?.toString().trim();
                          final email =
                              (rawEmail != null && rawEmail.isNotEmpty)
                              ? rawEmail
                              : '';
                          final initial = name.isNotEmpty
                              ? name[0].toUpperCase()
                              : '?';

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.darkSurfaceElevated,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm,
                              ),
                              border: Border.all(
                                color: AppColors.borderSubtleDark,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.primaryBlue
                                      .withValues(alpha: 0.2),
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: AppTypography.bodyMedium
                                            .copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      if (email.isNotEmpty)
                                        Text(
                                          email,
                                          style: TextStyle(
                                            color: AppColors.textTertiary,
                                            fontSize: 11,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: () => _addRegisteredUser(user),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primaryBlue,
                                    side: const BorderSide(
                                      color: AppColors.primaryBlue,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusSm,
                                      ),
                                    ),
                                  ),
                                  child: const Text('Add'),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

Future<FamilyMember?> navToAddFamilyMemberScreen(BuildContext context) {
  return ModernAddFamilyMemberScreen.show(context);
}