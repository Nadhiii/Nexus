import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/providers/biometric_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BiometricProvider>(context, listen: false).refresh();
    });
    _otaService.initNotifications();
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _updateStatus = 'Checking for updates...';
      _isDownloading = false;
      _downloadProgress = 0;
    });

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      debugPrint("DEBUG: Local App Version is: '$currentVersion'");

      final update = await _otaService.checkForUpdate(currentVersion);

      if (update != null) {
        setState(() {
          _updateStatus = 'Update available! Starting download...';
          _isDownloading = true;
        });

        _otaService.progressStream.listen((progress) {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: AppColors.backgroundBlack,
            surfaceTintColor: AppColors.backgroundBlack,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
              title: Text(
                'More',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 10),

                _buildSectionHeader("FINANCIAL TOOLS"),
                const SizedBox(height: 12),
                _buildToolsGrid(),

                const SizedBox(height: 32),

                _buildSectionHeader("PREFERENCES"),
                const SizedBox(height: 12),
                _buildSettingsSection(),
                
                const SizedBox(height: 32),

                _buildSectionHeader("SUPPORT"),
                const SizedBox(height: 12),
                _buildSupportSection(),

                const SizedBox(height: 40),

                _buildExpressiveDownloadButton(),

                if (!_isDownloading && _updateStatus != null) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _updateStatus!,
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),

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
            height: 56,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.transparent,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                if (_isDownloading)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    width: constraints.maxWidth * _downloadProgress,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: AppColors.error,
                                  size: 18,
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isError
              ? AppColors.error.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.labelLarge.copyWith(
              color: isError ? AppColors.error : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolsGrid() {
    return Column(
      children: [
        Row(
          children: [
            _expandedTool(
              Icons.pie_chart_rounded,
              AppColors.pastelPurple,
              "Analytics",
              () => _navigate(const ReportsAndAnalyticsScreen()),
            ),
            const SizedBox(width: 12),
            _expandedTool(
              Icons.category_rounded,
              AppColors.pastelOrange,
              "Categories",
              () => _navigate(const ManageCategoriesScreen()),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _expandedTool(
              Icons.family_restroom_rounded,
              AppColors.accentPink,
              "Family & Friends",
              () => _navigate(const FamilyDashboardScreen()),
            ),
            const SizedBox(width: 12),
            _expandedTool(
              Icons.call_split_rounded,
              AppColors.success,
              "Quick Split",
              () => _navigate(const ExpenseSplitterScreen()),
            ),
          ],
        ),
      ],
    );
  }

  Widget _expandedTool(
    IconData icon,
    Color color,
    String label,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: _ToolCard(icon: icon, color: color, label: label, onTap: onTap),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
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
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          _buildTile(
            icon: Icons.help_outline_rounded,
            color: Colors.blueGrey,
            title: "Help & Support",
            onTap: () => _launchEmail(),
          ),
          _divider(),
          _buildTile(
            icon: Icons.info_outline_rounded,
            color: Colors.blueGrey,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: AppTypography.bodyLarge.copyWith(
          color: AppColors.textPrimary,
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
    color: Colors.white.withValues(alpha: 0.05),
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

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ToolCard({
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
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 10),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}