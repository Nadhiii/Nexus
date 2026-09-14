import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/providers/shared_expense_provider.dart';
import '../../../core/models/shared_expense.dart';
import '../../../core/services/firestore_service.dart';

class ModernAddFamilyMemberScreen extends StatefulWidget {
  const ModernAddFamilyMemberScreen({super.key});

  /// Opens as a native fullscreen dialog route — eliminates all bottom sheet
  /// layout and semantics parentDataDirty collisions completely.
  static Future<FamilyMember?> show(BuildContext context) {
    return Navigator.of(context).push<FamilyMember>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const ModernAddFamilyMemberScreen(),
      ),
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickDeviceContact() async {
    try {
      final permission = await FlutterContacts.requestPermission(
        readonly: true,
      );
      if (!permission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contact permission was denied'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final contact = await FlutterContacts.openExternalPick();
      if (contact != null) {
        final fullContact = await FlutterContacts.getContact(contact.id);
        setState(() {
          _nameController.text =
              (fullContact?.displayName ?? contact.displayName).trim();
          if (fullContact?.phones.isNotEmpty == true) {
            _emailController.text = fullContact!.phones.first.number;
          } else if (fullContact?.emails.isNotEmpty == true) {
            _emailController.text = fullContact!.emails.first.address;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open contacts: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
      final userName = (userData['displayName'] ?? userData['name'])
          ?.toString()
          .trim();
      final userEmail = userData['email']?.toString().trim();

      final member = FamilyMember(
        id: (userId != null && userId.isNotEmpty)
            ? userId
            : 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: (userName != null && userName.isNotEmpty)
            ? userName
            : 'Nexus User',
        email: (userEmail != null && userEmail.isNotEmpty) ? userEmail : null,
      );

      await provider.addFamilyMember(member);

      if (mounted) {
        Navigator.of(context).pop(member);
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

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textTertiary),
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
      filled: true,
      fillColor: AppColors.darkSurfaceElevated,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        borderSide: const BorderSide(color: AppColors.borderSubtleDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        borderSide: const BorderSide(color: AppColors.borderSubtleDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Add Member',
          style: AppTypography.headlineSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Add a contact manually or import from your phonebook.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 20),

            // Device Contact Picker
            OutlinedButton.icon(
              onPressed: _pickDeviceContact,
              icon: const Icon(
                Icons.contacts_outlined,
                size: 18,
                color: AppColors.primaryBlue,
              ),
              label: const Text(
                'Choose from Phone Contacts',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size(double.infinity, 46),
              ),
            ),
            const SizedBox(height: 16),

            // Manual Input: Name
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
              decoration: _fieldDecoration(
                hint: 'Full Name (e.g. Alex, Tarun)',
                icon: Icons.person_outline,
              ),
            ),
            const SizedBox(height: 12),

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
                    decoration: _fieldDecoration(
                      hint: 'Phone or Email (optional)',
                      icon: Icons.mail_outline,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSavingManual ? null : _addManualMember,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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
                      : const Text(
                          'Add',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Section Divider
            Row(
              children: [
                const Expanded(
                  child: Divider(color: AppColors.borderSubtleDark),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
            const SizedBox(height: 16),

            // Stream of Nexus Users
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreService.getRegisteredUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  );
                }

                final users = snapshot.data ?? const <Map<String, dynamic>>[];
                if (users.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'No registered Nexus users found.\nType any name above to add them.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: users.map((user) {
                    final rawName = user['name']?.toString().trim();
                    final name = (rawName != null && rawName.isNotEmpty)
                        ? rawName
                        : 'Nexus User';
                    final email = user['email']?.toString().trim() ?? '';
                    final initial = name.isNotEmpty
                        ? name[0].toUpperCase()
                        : '?';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderSubtleDark),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primaryBlue.withValues(
                              alpha: 0.2,
                            ),
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: AppTypography.bodyMedium.copyWith(
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
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Select'),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<FamilyMember?> navToAddFamilyMemberScreen(BuildContext context) {
  return ModernAddFamilyMemberScreen.show(context);
}
