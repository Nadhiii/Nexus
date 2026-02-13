import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/biometric_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/top_snackbar.dart';
import '../backup/backup_settings_screen.dart';
import '../notifications/notification_settings_screen.dart';
import '../gmail/gmail_settings_screen.dart';
import '../family/screens/family_dashboard_screen.dart';
import '../family/screens/expense_splitter_screen.dart';
import '../ai_assistant/screens/ai_settings_screen.dart';
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
        slivers: [
          // 1. Profile Header
          SliverAppBar(
            pinned: true,
            expandedHeight: 110, // Standard
            backgroundColor: AppColors.backgroundBlack,
            surfaceTintColor: AppColors.backgroundBlack,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(
                left: 20,
                bottom: 24,
              ), // Standard
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
                const SizedBox(height: 20),

                // 2. Tools Grid (New Layout)
                Text("TOOLS", style: _headerStyle()),
                const SizedBox(height: 12),
                _buildToolsGrid(),
                const SizedBox(height: 32),

                // 3. Settings List
                Text("PREFERENCES", style: _headerStyle()),
                const SizedBox(height: 12),
                _buildSettingsSection(),

                const SizedBox(height: 32),
                Text("SUPPORT", style: _headerStyle()),
                const SizedBox(height: 12),
                _buildSupportSection(),

                const SizedBox(height: 40),
                _buildSignOutButton(),
                const SizedBox(height: 120), // Bottom padding
              ]),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle() {
    return AppTypography.labelSmall.copyWith(
      color: AppColors.textTertiary,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.2,
    );
  }

  Widget _buildToolsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ToolCard(
                icon: Icons.pie_chart_rounded,
                color: AppColors.primaryBlue,
                label: "Analytics",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReportsAndAnalyticsScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ToolCard(
                icon: Icons.category_rounded,
                color: AppColors.pastelOrange,
                label: "Categories",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManageCategoriesScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ToolCard(
                icon: Icons.cloud_upload_rounded,
                color: AppColors.accentTeal,
                label: "Backup",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BackupSettingsScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ToolCard(
                icon: Icons.family_restroom_rounded,
                color: AppColors.accentPink,
                label: "Family",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FamilyDashboardScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ToolCard(
                icon: Icons.call_split_rounded,
                color: AppColors.success,
                label: "Split Bill",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ExpenseSplitterScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Empty spacer to maintain grid alignment
            Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Consumer<BiometricProvider>(
            builder: (context, bio, _) => _buildTile(
              icon: Icons.fingerprint_rounded,
              color: AppColors.accentTeal,
              title: "Biometric Lock",
              trailing: Switch(
                value: bio.isBiometricEnabled,
                onChanged: bio.isBiometricAvailable
                    ? (v) => bio.setAllBiometricFeatures(v)
                    : null,
                activeThumbColor: AppColors.primaryBlue,
                activeTrackColor: AppColors.primaryBlue.withOpacity(0.4),
              ),
            ),
          ),
          _divider(),
          _buildTile(
            icon: Icons.notifications_rounded,
            color: AppColors.accentOrange,
            title: "Notifications",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationSettingsScreen(),
              ),
            ),
          ),
          _divider(),
          _buildTile(
            icon: Icons.mark_email_unread_rounded,
            color: AppColors.error,
            title: "Gmail Sync",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GmailSettingsScreen()),
            ),
          ),
          _divider(),
          _buildTile(
            icon: Icons.auto_awesome,
            color: const Color(0xFF6366F1),
            title: "Nex Settings",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AISettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _buildTile(
            icon: Icons.help_outline_rounded,
            color: AppColors.textSecondary,
            title: "Help & Support",
            onTap: () => showTopSnackBar(context, "Coming Soon!"),
          ),
          _divider(),
          _buildTile(
            icon: Icons.info_outline_rounded,
            color: AppColors.textSecondary,
            title: "About Nexus",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color color,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
      ),
      trailing:
          trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
            size: 20,
          ),
    );
  }

  Widget _divider() => Divider(
    height: 1,
    color: Colors.white.withOpacity(0.05),
    indent: 56,
    endIndent: 16,
  );

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () async {
          final auth = AuthService();
          await auth.signOut();
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: AppColors.error.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          "Sign Out",
          style: AppTypography.labelLarge.copyWith(color: AppColors.error),
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
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
