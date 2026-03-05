import 'package:flutter/material.dart';
import '../../core/services/pdf_password_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';

class PDFPasswordManagerScreen extends StatefulWidget {
  const PDFPasswordManagerScreen({super.key});

  @override
  State<PDFPasswordManagerScreen> createState() =>
      _PDFPasswordManagerScreenState();
}

class _PDFPasswordManagerScreenState extends State<PDFPasswordManagerScreen> {
  late Future<List<String>> _passwordsFuture;

  @override
  void initState() {
    super.initState();
    _loadPasswords();
  }

  void _loadPasswords() {
    setState(() {
      _passwordsFuture = PDFPasswordManager.getSavedPasswords();
    });
  }

  void _showDeleteConfirmation(String password) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Password?'),
        content: const Text('This saved password will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await PDFPasswordManager.removePassword(password);
              _loadPasswords();
              if (!context.mounted) { return; }
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showClearAllConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Passwords?'),
        content: const Text(
          'All saved PDF passwords will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await PDFPasswordManager.clearAllPasswords();
              _loadPasswords();
              if (!context.mounted) { return; }
              Navigator.pop(context);
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        title: const Text('Saved PDF Passwords'),
        backgroundColor: AppColors.backgroundBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<String>>(
        future: _passwordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading passwords: ${snapshot.error}'),
            );
          }

          final passwords = snapshot.data ?? [];

          if (passwords.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_open,
                      size: 64,
                      color: AppColors.textTertiary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'No Saved Passwords',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'When you upload a password-protected PDF,\nthe password will be saved here for future use.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.info),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Passwords stored securely on your device',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  itemCount: passwords.length,
                  itemBuilder: (context, index) {
                    final password = passwords[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: ListTile(
                          leading: Icon(Icons.lock, color: AppColors.warning),
                          title: Text(
                            'Password ${index + 1}',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            password.length > 20
                                ? '${password.substring(0, 20)}...'
                                : password,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontFamily: 'monospace',
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.red,
                            onPressed: () => _showDeleteConfirmation(password),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showClearAllConfirmation,
                    icon: const Icon(Icons.delete_sweep),
                    label: const Text('Clear All Passwords'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
