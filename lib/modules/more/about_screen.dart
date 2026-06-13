import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/top_snackbar.dart';
// import '../../core/services/ota_update_service.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  // Removed OTA update logic and button; now in More screen.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: CustomScrollView(
        slivers: [
          // 1. IMMERSIVE HEADER (With Back Button)
          SliverAppBar(
            pinned: true,
            expandedHeight: 110,
            backgroundColor: AppColors.backgroundBlack,
            surfaceTintColor: AppColors.backgroundBlack,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(
                left: 60,
                bottom: 24,
              ), // Offset for back button
              title: Text(
                'About',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          // 2. APP HERO CARD
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/icons/icon.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Nexus",
                    style: AppTypography.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Update button moved to More screen
                ],
              ),
            ),
          ),

          // 3. INFO TILES
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader("MISSION"),
                _buildGlassCard(
                  context,
                  child: Text(
                    "Nexus is built on the belief that you know your money best. No black-box algorithms or AI guesswork, just powerful, precision tools wrapped in a stunning, distraction-free interface. Take absolute control of your financial destiny with clarity and confidence.",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                _buildSectionHeader("DEVELOPER"),
                _buildGlassCard(
                  context,
                  child: Column(
                    children: [
                      _buildDevRow(
                        Icons.person,
                        "Mahanadhi Parisara",
                        "Developer",
                      ),
                      const Divider(color: Colors.white10, height: 24),
                      _buildActionRow(
                        context,
                        icon: Icons.language,
                        label: "Website",
                        onTap: () =>
                            _launchURL(context, 'https://mahanadhi.space'),
                      ),
                      const SizedBox(height: 12),
                      _buildActionRow(
                        context,
                        icon: Icons.email_outlined,
                        label: "Contact Support",
                        onTap: () => _launchEmail(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                _buildSectionHeader("TECH STACK"),
                _buildGlassCard(
                  context,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTechChip("Flutter"),
                      _buildTechChip("Firebase"),
                      _buildTechChip("Provider"),
                      _buildTechChip("Material 3"),
                    ],
                  ),
                ),

                const SizedBox(height: 100), // Bottom padding
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: child,
    );
  }

  Widget _buildDevRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.open_in_new,
            color: AppColors.primaryBlue.withValues(alpha: 0.5),
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildTechChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        label,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    );
  }

  Future<void> _launchURL(BuildContext context, String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        showTopSnackBar(context, "Could not open link", isError: true);
      }
    }
  }

  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'mahanadhip@gmail.com',
      query: 'subject=Nexus Support',
    );
    try {
      await launchUrl(emailLaunchUri);
    } catch (e) {
      if (context.mounted) {
        Clipboard.setData(const ClipboardData(text: 'mahanadhip@gmail.com'));
        showTopSnackBar(context, "Email copied to clipboard");
      }
    }
  }
}
