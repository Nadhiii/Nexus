import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/biometric_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../backup/backup_settings_screen.dart';
import 'about_screen.dart';
import 'widgets/edit_profile_modal.dart';

class ModernMoreScreen extends StatefulWidget {
  const ModernMoreScreen({super.key});

  @override
  State<ModernMoreScreen> createState() => _ModernMoreScreenState();
}

class _ModernMoreScreenState extends State<ModernMoreScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BiometricProvider>(context, listen: false).refresh();
      Provider.of<UserProvider>(context, listen: false).loadUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.background,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Settings',
                style: AppTypography.headlineLarge.copyWith(
                  color: Theme.of(context).colorScheme.onBackground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              100, // Bottom padding for nav bar
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Profile Card
                _buildProfileCard(),
                const SizedBox(height: AppSpacing.xl),

                // Settings Section
                _buildSectionHeader('Preferences'),
                const SizedBox(height: AppSpacing.md),
                _buildSettingsCard(),
                const SizedBox(height: AppSpacing.xl),

                // Tools Section
                _buildSectionHeader('Tools'),
                const SizedBox(height: AppSpacing.md),
                _buildToolsCard(),
                const SizedBox(height: AppSpacing.xl),

                // Support Section
                _buildSectionHeader('Support'),
                const SizedBox(height: AppSpacing.md),
                _buildSupportCard(),
                const SizedBox(height: AppSpacing.xl),

                // Sign Out Button
                _buildSignOutButton(),
                const SizedBox(height: AppSpacing.lg),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Text(
        title,
        style: AppTypography.bodyLarge.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = FirebaseAuth.instance.currentUser;
        final userProfile = userProvider.userProfile;

        if (userProvider.isLoading) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.blueGradient,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Loading...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Getting user information',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Fallback to Firebase Auth data if no profile
        final displayName =
            userProfile?.displayName ??
            user?.displayName ??
            (user?.isAnonymous == true ? 'Anonymous User' : 'User');
        final email =
            userProfile?.email ??
            user?.email ??
            (user?.isAnonymous == true ? 'Using without account' : 'No email');

        return Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.blueGradient,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              if (user?.isAnonymous == true) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    title: Text(
                      'Anonymous Account',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ),
                    content: Text(
                      'You are using the app without an account. To edit your profile, please sign in with Google or create an account.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              } else if (userProfile != null) {
                showEditProfileModal(context, userProfile);
              }
            },
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Row(
              children: [
                // Profile Picture
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    image: user?.photoURL != null
                        ? DecorationImage(
                            image: NetworkImage(user!.photoURL!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: user?.photoURL == null
                      ? Icon(
                          user?.isAnonymous == true
                              ? Icons.person_off_rounded
                              : Icons.person_rounded,
                          color: Colors.white,
                          size: 32,
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.lg),
                // Profile Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Edit Icon
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    user?.isAnonymous == true
                        ? Icons.info_outline_rounded
                        : Icons.edit_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          // Theme Toggle
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return _buildSettingTile(
                icon: Icons.color_lens_rounded,
                iconColor: AppColors.accentPurple,
                title: 'Material You Theme',
                subtitle: 'Use wallpaper colors in the app',
                trailing: Switch(
                  value: themeProvider.useMaterialYou,
                  onChanged: (value) {
                    themeProvider.toggleTheme(value);
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              );
            },
          ),
          _buildDivider(),

          // Biometric Security
          Consumer<BiometricProvider>(
            builder: (context, biometricProvider, child) {
              return _buildSettingTile(
                icon: Icons.fingerprint_rounded,
                iconColor: AppColors.accentTeal,
                title: 'Biometric Security',
                subtitle: biometricProvider.isBiometricAvailable
                    ? 'Use fingerprint or face unlock'
                    : 'Not available on this device',
                trailing: Switch(
                  value: biometricProvider.isBiometricEnabled,
                  onChanged: biometricProvider.isBiometricAvailable
                      ? (value) async {
                          await biometricProvider.setAllBiometricFeatures(
                            value,
                          );
                        }
                      : null,
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              );
            },
          ),
          _buildDivider(),

          // Notifications
          _buildSettingTile(
            icon: Icons.notifications_rounded,
            iconColor: AppColors.accentOrange,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            onTap: () {
              // TODO: Navigate to notification settings
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Coming soon!')));
            },
          ),
          _buildDivider(),

          // Backup & Sync
          _buildSettingTile(
            icon: Icons.backup_rounded,
            iconColor: AppColors.accentPurple,
            title: 'Backup & Sync',
            subtitle: 'Cloud backup settings',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const BackupSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          _buildSettingTile(
            icon: Icons.folder_rounded,
            iconColor: AppColors.accentTeal,
            title: 'Document Vault',
            subtitle: 'Store bills and receipts',
            onTap: () {
              // TODO: Navigate to document vault
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Coming soon!')));
            },
          ),
          _buildDivider(),
          _buildSettingTile(
            icon: Icons.analytics_rounded,
            iconColor: AppColors.primaryBlue,
            title: 'Reports & Analytics',
            subtitle: 'Detailed spending insights',
            onTap: () {
              // TODO: Navigate to reports
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Coming soon!')));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          _buildSettingTile(
            icon: Icons.help_rounded,
            iconColor: AppColors.accentOrange,
            title: 'Help & Support',
            subtitle: 'Get help with the app',
            onTap: () {
              // TODO: Navigate to help
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Coming soon!')));
            },
          ),
          _buildDivider(),
          _buildSettingTile(
            icon: Icons.info_rounded,
            iconColor: AppColors.primaryBlue,
            title: 'About',
            subtitle: 'App version and information',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyLarge.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Trailing
            if (trailing != null)
              trailing
            else if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: Theme.of(context).colorScheme.error.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        onTap: () async {
          // Show confirmation dialog
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text(
                'Sign Out',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              content: Text(
                'Are you sure you want to sign out?',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            final authService = AuthService();
            try {
              await authService.signOut();
              // Navigation is handled by AuthGate's StreamBuilder
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Sign out error: $e'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            }
          }
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: Theme.of(context).colorScheme.error,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Sign Out',
                style: AppTypography.bodyLarge.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
