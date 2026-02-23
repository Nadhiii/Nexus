import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/Nex_assistant_provider.dart';

class NexSettingsScreen extends StatefulWidget {
  const NexSettingsScreen({super.key});

  @override
  State<NexSettingsScreen> createState() => _NexSettingsScreenState();
}

class _NexSettingsScreenState extends State<NexSettingsScreen> {
  bool _hasLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded && mounted) {
      _hasLoaded = true;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBlack,
        title: Text(
          'Nex Settings',
          style: AppTypography.headlineSmall.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AIAssistantProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'AI integrations have been removed from the UI.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Unified Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // No API keys to save; settings updated.
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Settings saved'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.info,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Save Settings',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // All Gemini/Claude UI helpers removed.
}
