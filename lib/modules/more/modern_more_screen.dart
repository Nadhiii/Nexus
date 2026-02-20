import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/biometric_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/top_snackbar.dart';
import '../backup/backup_settings_screen.dart';
import '../notifications/notification_settings_screen.dart';
import '../gmail/gmail_settings_enhanced_screen.dart';
import '../family/screens/family_dashboard_screen.dart';
import '../family/screens/expense_splitter_screen.dart';
import 'package:nexus/modules/Nex/screens/Nex_settings_screen.dart';
import 'package:nexus/modules/Nex/screens/Nex_chat_screen.dart';
import 'about_screen.dart';
import 'reports_and_analytics_screen.dart';
import 'manage_categories_screen.dart';

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

                // 1. STABLE FINANCIAL TOOLS
                _buildSectionHeader("FINANCIAL TOOLS"),
                const SizedBox(height: 12),
                _buildToolsGrid(),

                const SizedBox(height: 32),

                // 2. PREFERENCES (FIXED BIOMETRIC TOGGLE)
                _buildSectionHeader("PREFERENCES"),
                const SizedBox(height: 12),
                _buildSettingsSection(),

                const SizedBox(height: 32),

                // 3. LABS (WIP SECTION)
                _buildSectionHeader("LABS"),
                const SizedBox(height: 12),
                _buildLabsSection(),

                const SizedBox(height: 32),

                // 4. SUPPORT
                _buildSectionHeader("SUPPORT"),
                const SizedBox(height: 12),
                _buildSupportSection(),

                const SizedBox(height: 40),
                _buildSignOutButton(),
                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
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
              "Family",
              () => _navigate(const FamilyDashboardScreen()),
            ),
            const SizedBox(width: 12),
            _expandedTool(
              Icons.call_split_rounded,
              AppColors.success,
              "Split Bill",
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

  Widget _buildLabsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _buildTile(
            icon: Icons.auto_awesome_rounded,
            color: AppColors.primaryBlue,
            title: "Nex AI Chat",
            subtitle: "Intelligent financial assistant",
            onTap: () => _navigate(const AIChatScreen()),
          ),
          _divider(),
          _buildTile(
            icon: Icons.file_present_rounded,
            color: AppColors.accentTeal,
            title: "PDF Import",
            subtitle: "Extract data from bank statements",
            onTap: () =>
                showTopSnackBar(context, "PDF extraction is in development"),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          // BIOMETRIC TOGGLE: Fixed to show even when disabled
          Consumer<BiometricProvider>(
            builder: (context, bio, _) => _buildTile(
              icon: Icons.fingerprint_rounded,
              color: AppColors.accentTeal,
              title: "Biometric Lock",
              trailing: Switch(
                value: bio.isBiometricEnabled,
                // If it's available on device, allow toggling regardless of current state
                onChanged: bio.isBiometricAvailable
                    ? (v) => bio.setAllBiometricFeatures(v)
                    : null,
                activeThumbColor: AppColors.primaryBlue,
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
            onTap: () => _navigate(const GmailSettingsEnhancedScreen()),
          ),
          _divider(),
          _buildTile(
            icon: Icons.settings_suggest_rounded,
            color: const Color(0xFF6366F1),
            title: "Nex Settings",
            onTap: () => _navigate(const NexSettingsScreen()),
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
        border: Border.all(color: Colors.white.withOpacity(0.05)),
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
          color: color.withOpacity(0.1),
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
    color: Colors.white.withOpacity(0.05),
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

  Widget _buildSignOutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: TextButton(
        onPressed: () => AuthService().signOut(),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        child: Text(
          "Sign Out",
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
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
