import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/providers/biometric_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_animations.dart';
import '../../core/widgets/nexus_button.dart';
import '../../core/widgets/nexus_switch.dart';
import '../../core/widgets/spring_tap.dart';
import '../../core/widgets/top_snackbar.dart';
import '../backup/backup_settings_screen.dart';
import '../notifications/notification_settings_screen.dart';
import '../gmail/nbox_sync_screen.dart';
import '../family/screens/family_dashboard_screen.dart';
import '../family/screens/expense_splitter_screen.dart';
import '../../core/services/ota_update_service.dart';
import 'reports_and_analytics_screen.dart';
import 'manage_categories_screen.dart';
import 'about_screen.dart';
import '../knowledge/knowledge_screen.dart';
import '../bike/ui/bike_screen.dart';

class ModernMoreScreen extends StatefulWidget {
  const ModernMoreScreen({super.key});

  @override
  State<ModernMoreScreen> createState() => _ModernMoreScreenState();
}

class _ModernMoreScreenState extends State<ModernMoreScreen> {
  final OTAUpdateService _otaService = OTAUpdateService();
  String? _updateStatus;
  double _downloadProgress = 0;
  bool _isDownloading = false;
  bool _isCancelled = false;
  StreamSubscription<int>? _otaProgressSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BiometricProvider>(context, listen: false).refresh();
    });
    _otaService.initNotifications();
  }

  Future<void> _checkForUpdates() async {
    await _otaProgressSubscription?.cancel();
    _otaProgressSubscription = null;
    setState(() {
      _updateStatus = 'Checking for updates...';
      _isDownloading = false;
      _downloadProgress = 0;
    });

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final update = await _otaService.checkForUpdate(currentVersion);

      if (update != null) {
        _isCancelled = false;
        setState(() {
          _updateStatus = 'Update available! Starting download...';
          _isDownloading = true;
        });

        _otaProgressSubscription = _otaService.progressStream.listen((
          progress,
        ) {
          if (mounted && !_isCancelled) {
            setState(() {
              if (progress < 0) {
                _isDownloading = false;
                _updateStatus = 'Update failed';
              } else if (progress >= 100) {
                _downloadProgress = 1.0;
                _isDownloading = false;
                _updateStatus = 'Install prompt opened';
              } else {
                _downloadProgress = progress / 100;
                _updateStatus = 'Downloading: $progress%';
              }
            });
          }
        });

        if (!mounted) {
          return;
        }
        await _otaService.startOTAUpdate(context, update['apk_url']);
      } else {
        setState(() => _updateStatus = 'Nexus is up to date ($currentVersion)');
      }
    } catch (e) {
      setState(() => _updateStatus = 'Update check failed');
    }
  }

  void _cancelUpdate() {
    _isCancelled = true;
    _otaService.cancelOTA();
    setState(() {
      _isDownloading = false;
      _downloadProgress = 0;
      _updateStatus = 'Download cancelled';
    });
  }

  @override
  void dispose() {
    _otaProgressSubscription?.cancel();
    _otaService.cancelOTA();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: AppColors.surfaceBackground,
            surfaceTintColor: AppColors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: AppSpacing.appBarTitlePadding,
              title: Text(
                'More',
                style: AppTypography.headlineMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: AppSpacing.screenHorizontalPadding,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppSpacing.sm),

                _buildSectionHeader("FINANCIAL TOOLS"),
                const SizedBox(height: AppSpacing.contentGap),
                _buildToolsGrid(),

                const SizedBox(height: AppSpacing.xl3),

                _buildSectionHeader("PREFERENCES"),
                const SizedBox(height: AppSpacing.contentGap),
                _buildSettingsSection(),

                const SizedBox(height: AppSpacing.xl3),

                _buildSectionHeader("SUPPORT"),
                const SizedBox(height: AppSpacing.contentGap),
                _buildSupportSection(),

                const SizedBox(height: AppSpacing.xl4),

                _buildExpressiveDownloadButton(),

                if (!_isDownloading && _updateStatus != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Center(
                    child: Text(
                      _updateStatus!,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.contentGap),

                _buildBottomActionButton(
                  label: "Sign Out",
                  onPressed: () => AuthService().signOut(),
                  isError: true,
                ),

                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpressiveDownloadButton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: _isDownloading ? null : _checkForUpdates,
          child: Container(
            height: AppSpacing.buttonHeightMd,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: AppSpacing.borderRadiusSm,
              color: AppColors.transparent,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                if (_isDownloading)
                  AnimatedContainer(
                    duration: AppAnimations.stateChangeDuration,
                    curve: AppAnimations.interactionCurve,
                    width: constraints.maxWidth * _downloadProgress,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.2),
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                  ),

                Padding(
                  padding: AppSpacing.cardPaddingMd,
                  child: Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            _isDownloading
                                ? "Downloading... ${(_downloadProgress * 100).toInt()}%"
                                : "Check for Updates",
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      if (_isDownloading)
                        AnimatedScale(
                          scale: (1.0 - _downloadProgress).clamp(0.0, 1.0),
                          duration: const Duration(milliseconds: 300),
                          child: AnimatedOpacity(
                            opacity: (1.0 - _downloadProgress).clamp(0.0, 1.0),
                            duration: const Duration(milliseconds: 300),
                            child: GestureDetector(
                              onTap: _cancelUpdate,
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  tooltip: 'Cancel update download',
                                  onPressed: _cancelUpdate,
                                  icon: const Icon(Icons.close_rounded),
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.textTertiary,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildBottomActionButton({
    required String label,
    required VoidCallback? onPressed,
    bool isError = false,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(
          color: isError
              ? AppColors.error.withValues(alpha: 0.2)
              : Theme.of(context).colorScheme.outline,
        ),
      ),
      child: NexusButton(
        label: label,
        onPressed: onPressed,
        variant: isError
            ? NexusButtonVariant.destructive
            : NexusButtonVariant.tertiary,
        width: double.infinity,
      ),
    );
  }

  Widget _buildToolsGrid() {
    const double gap = AppSpacing.sm; // Standard gap
    return Column(
      children: [
        // Top 3-Column Split (Fixed Height fixes the alignment issues)
        SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Tall Left
              Expanded(
                child: _TallToolCard(
                  icon: Icons.pie_chart_rounded,
                  color: AppColors.pastelPurple,
                  label: 'Analytics',
                  subtitle: 'Insights',
                  onTap: () => _navigate(const ReportsAndAnalyticsScreen()),
                ),
              ),
              const SizedBox(width: gap),

              // 2. Stacked Middle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _CompactToolCard(
                        icon: Icons.category_rounded,
                        color: AppColors.pastelOrange,
                        label: 'Categories',
                        onTap: () => _navigate(const ManageCategoriesScreen()),
                      ),
                    ),
                    const SizedBox(height: gap),
                    Expanded(
                      child: _CompactToolCard(
                        icon: Icons.call_split_rounded,
                        color: AppColors.success,
                        label: 'Quick Split',
                        onTap: () => _navigate(const ExpenseSplitterScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: gap),

              // 3. Tall Right
              Expanded(
                child: _TallToolCard(
                  icon: Icons.two_wheeler_rounded,
                  color: AppColors.accentTeal,
                  label: 'Garage',
                  subtitle: 'Vehicles',
                  onTap: () => _navigate(const ModernBikeScreen()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: gap),
        // Bottom Full-Width Banner
        _BannerToolCard(
          icon: Icons.family_restroom_rounded,
          color: AppColors.accentPink,
          label: 'Shared Expense',
          subtitle: 'Group bills, circles & quick transfers',
          onTap: () => _navigate(const FamilyDashboardScreen()),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      clipBehavior:
          Clip.antiAlias, // Keeps list ripples inside the rounded corners
      child: Column(
        children: [
          Consumer<BiometricProvider>(
            builder: (context, bio, _) => _buildTile(
              icon: Icons.fingerprint_rounded,
              color: AppColors.accentTeal,
              title: "Biometric Lock",
              trailing: NexusSwitch(
                value: bio.isBiometricEnabled,
                onChanged: bio.isBiometricAvailable
                    ? (v) => bio.setAllBiometricFeatures(v)
                    : null,
              ),
            ),
          ),
          _divider(),
          _buildTile(
            icon: Icons.cloud_upload_rounded,
            color: AppColors.accentTeal,
            title: "Cloud Backup",
            onTap: () => _navigate(const BackupSettingsScreen()),
          ),
          _divider(),
          _buildTile(
            icon: Icons.notifications_rounded,
            color: AppColors.accentOrange,
            title: "Notifications",
            onTap: () => _navigate(const NotificationSettingsScreen()),
          ),
          _divider(),
          _buildTile(
            icon: Icons.mark_email_unread_rounded,
            color: AppColors.error,
            title: "NBox Sync",
            onTap: () => _navigate(const NboxSyncScreen()),
          ),
          _divider(),
          _buildTile(
            icon: Icons.psychology_alt_rounded,
            color: AppColors.accentTeal,
            title: "Knowledge",
            subtitle: "What Nexus has learned",
            onTap: () => _navigate(const KnowledgeScreen()),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildTile(
            icon: Icons.help_outline_rounded,
            color: AppColors.info,
            title: "Help & Support",
            onTap: () => _launchEmail(),
          ),
          _divider(),
          _buildTile(
            icon: Icons.info_outline_rounded,
            color: AppColors.info,
            title: "About Nexus",
            onTap: () => _navigate(const AboutScreen()),
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppSpacing.borderRadiusXs,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: AppTypography.bodyLarge.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiary,
              ),
            )
          : null,
      trailing:
          trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
            size: 22,
          ),
    );
  }

  Widget _divider() => Divider(
    height: 1,
    color: AppColors.borderSubtle,
    indent: 70,
    endIndent: 20,
  );

  void _navigate(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'mahanadhip@gmail.com',
      query: 'subject=Nexus Support',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        Clipboard.setData(const ClipboardData(text: 'mahanadhip@gmail.com'));
        showTopSnackBar(context, "Email copied to clipboard");
      }
    }
  }
}

// ---------------------------------------------------------
// SUPPORTING BENTO GRID WIDGETS
// ---------------------------------------------------------

class _TallToolCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _TallToolCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SpringTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.labelMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactToolCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _CompactToolCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SpringTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: AppSpacing.xs),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.labelSmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerToolCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _BannerToolCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SpringTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.labelLarge.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
