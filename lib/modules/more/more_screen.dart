import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/biometric_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/widgets/translucent_app_bar.dart';
import '../backup/backup_settings_screen.dart';
import 'about_screen.dart';
import 'widgets/edit_profile_modal.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
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
      extendBodyBehindAppBar: true,
      appBar: const TranslucentAppBar(title: Text('More')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.of(context).padding.top +
              kToolbarHeight +
              16, // Safe area + app bar + extra padding
          16,
          MediaQuery.of(context).padding.bottom +
              90 +
              16, // Safe area + nav bar (70) + margin (20) + extra padding
        ),
        children: [
          // Profile Section
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              final user = FirebaseAuth.instance.currentUser;
              final userProfile = userProvider.userProfile;
              
              if (userProvider.isLoading) {
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: CircularProgressIndicator()),
                    title: const Text('Loading...'),
                    subtitle: const Text('Getting user information'),
                    trailing: const Icon(Icons.edit),
                  ),
                );
              }
              
              // Fallback to Firebase Auth data if no profile
              final displayName = userProfile?.displayName ?? 
                                 user?.displayName ?? 
                                 (user?.isAnonymous == true ? 'Anonymous User' : 'User');
              final email = userProfile?.email ?? 
                           user?.email ?? 
                           (user?.isAnonymous == true ? 'Using without account' : 'No email');
              
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user?.photoURL != null 
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    child: user?.photoURL == null 
                        ? Icon(user?.isAnonymous == true ? Icons.person_off : Icons.person)
                        : null,
                  ),
                  title: Text(displayName),
                  subtitle: Text(email),
                  trailing: user?.isAnonymous == true 
                      ? const Icon(Icons.info_outline) 
                      : const Icon(Icons.edit),
                  onTap: () {
                    if (user?.isAnonymous == true) {
                      // Show info about anonymous account
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Anonymous Account'),
                          content: const Text(
                            'You are using the app without an account. To edit your profile, please sign in with Google or create an account.',
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
                      // Show edit profile modal
                      showEditProfileModal(context, userProfile);
                    }
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Settings Section
          const Text(
            'Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Dark Mode'),
                          subtitle: const Text(
                            'Switch between light and dark theme',
                          ),
                          value: themeProvider.isDarkMode,
                          onChanged: (value) {
                            themeProvider.toggleTheme();
                          },
                          secondary: const Icon(Icons.dark_mode),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Material You'),
                          subtitle: const Text(
                            'Dynamic colors from your wallpaper (Android 12+)',
                          ),
                          value: themeProvider.useMaterialYou,
                          onChanged: (value) {
                            themeProvider.toggleMaterialYou();
                          },
                          secondary: const Icon(Icons.color_lens),
                        ),
                      ],
                    );
                  },
                ),
                const Divider(height: 1),
                Consumer<BiometricProvider>(
                  builder: (context, biometricProvider, child) {
                    return SwitchListTile(
                      title: const Text('Biometric Security'),
                      subtitle: Text(
                        biometricProvider.isBiometricAvailable
                            ? 'Use fingerprint or face unlock'
                            : 'Not available on this device',
                      ),
                      value: biometricProvider.isBiometricEnabled,
                      onChanged: biometricProvider.isBiometricAvailable
                          ? (value) async {
                              await biometricProvider.setAllBiometricFeatures(
                                value,
                              );
                            }
                          : null,
                      secondary: const Icon(Icons.fingerprint),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notifications'),
                  subtitle: const Text('Manage notification preferences'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to notification settings
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('Backup & Sync'),
                  subtitle: const Text('Cloud backup settings'),
                  trailing: const Icon(Icons.chevron_right),
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
          ),

          const SizedBox(height: 16),

          // Tools Section
          const Text(
            'Tools',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.folder),
                  title: const Text('Document Vault'),
                  subtitle: const Text('Store bills and receipts'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to document vault
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.analytics),
                  title: const Text('Reports & Analytics'),
                  subtitle: const Text('Detailed spending insights'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to reports
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Support Section
          const Text(
            'Support',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('Help & Support'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to help
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('About'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AboutScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Sign Out Section
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                final authService = AuthService();
                try {
                  await authService.signOut();
                  // Navigation is handled by AuthGate's StreamBuilder
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sign out error: $e')),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
