import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/ai_settings.dart';
import '../providers/ai_assistant_provider.dart';

/// AI Settings Screen
/// Configure API keys and AI preferences
class AISettingsScreen extends StatefulWidget {
  const AISettingsScreen({super.key});

  @override
  State<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen> {
  final _geminiController = TextEditingController();
  final _claudeController = TextEditingController();
  bool _showGeminiKey = false;
  bool _showClaudeKey = false;
  bool _hasLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Load keys only once
    if (!_hasLoaded && mounted) {
      _hasLoaded = true;
      _loadKeys();
    }
  }

  void _loadKeys() {
    try {
      final provider = context.read<AIAssistantProvider>();
      
      // Load keys into controllers
      if (provider.settings.hasGeminiKey) {
        _geminiController.text = '••••••••••••••••••••';
      }
      if (provider.settings.hasClaudeKey) {
        _claudeController.text = '••••••••••••••••••••';
      }
    } catch (e) {
      debugPrint('Error loading keys in settings screen: $e');
    }
  }

  @override
  void dispose() {
    _geminiController.dispose();
    _claudeController.dispose();
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
          // Show loading while provider initializes
          if (!provider.isInitialized) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    'Loading settings...',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 32),

                // Free vs Paid Comparison
                _buildComparisonCard(),
                const SizedBox(height: 24),

                // Model Selection
                _buildModelSelection(provider),
                const SizedBox(height: 32),

                // Gemini API Key
                _buildApiKeySection(
                  title: 'Gemini API Key',
                  subtitle: 'FREE • 1.5M tokens/month • Fast responses',
                  controller: _geminiController,
                  isConfigured: provider.settings.hasGeminiKey,
                  showKey: _showGeminiKey,
                  onToggleVisibility: () =>
                      setState(() => _showGeminiKey = !_showGeminiKey),
                  onSave: (key) => _saveGeminiKey(provider, key),
                  onGetKey: () =>
                      _launchUrl('https://aistudio.google.com/app/apikey'),
                  color: Colors.blue,
                  icon: Icons.auto_awesome,
                  steps: [
                    'Go to Google AI Studio',
                    'Sign in with Google account',
                    'Click "Get API Key"',
                    'Copy and paste below',
                  ],
                ),
                const SizedBox(height: 24),

                // Claude API Key
                _buildApiKeySection(
                  title: 'Claude API Key',
                  subtitle: 'PAID • ~₹0.50-2 per chat • Smarter responses',
                  controller: _claudeController,
                  isConfigured: provider.settings.hasClaudeKey,
                  showKey: _showClaudeKey,
                  onToggleVisibility: () =>
                      setState(() => _showClaudeKey = !_showClaudeKey),
                  onSave: (key) => _saveClaudeKey(provider, key),
                  onGetKey: () =>
                      _launchUrl('https://console.anthropic.com/settings/keys'),
                  color: AppColors.premiumAmber,
                  icon: Icons.psychology,
                  steps: [
                    'Go to Anthropic Console',
                    'Create account & add credits',
                    'Go to Settings → API Keys',
                    'Create new key & paste below',
                  ],
                ),
                const SizedBox(height: 32),

                // Usage Stats (if configured)
                if (provider.settings.hasAnyKey) ...[
                  _buildUsageStats(provider),
                  const SizedBox(height: 24),
                ],

                // Info Card
                _buildInfoCard(),
                const SizedBox(height: 32),

                // Error Display
                if (provider.error != null) _buildErrorCard(provider.error!),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text(
                  'N',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Assistant',
                    style: AppTypography.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Configure your AI models',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComparisonCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.purple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.compare_arrows, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Gemini vs Claude',
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildComparisonColumn(
                  title: 'Gemini',
                  color: AppColors.info,
                  features: [
                    '• FREE to use',
                    '• Fast responses',
                    '• Good for daily use',
                    '• 1.5M tokens/month',
                  ],
                  recommended: true,
                ),
              ),
              Container(
                width: 1,
                height: 100,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: Colors.white.withOpacity(0.2),
              ),
              Expanded(
                child: _buildComparisonColumn(
                  title: 'Claude',
                  color: AppColors.premiumAmber,
                  features: [
                    '• Paid service',
                    '• Smarter analysis',
                    '• Better reasoning',
                    '• ~₹0.50-2 per chat',
                  ],
                  recommended: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonColumn({
    required String title,
    required Color color,
    required List<String> features,
    required bool recommended,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (recommended) ...[
              const SizedBox(width: 4),
              Icon(Icons.star, color: color, size: 14),
            ],
          ],
        ),
        const SizedBox(height: 12),
        ...features.map(
          (f) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              f,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModelSelection(AIAssistantProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Model',
            style: AppTypography.labelLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildModelButton(
                  title: 'Gemini',
                  subtitle: 'Free & Fast',
                  icon: Icons.auto_awesome,
                  color: Colors.blue,
                  isActive: provider.settings.activeModel == AIModel.gemini,
                  isAvailable: provider.settings.hasGeminiKey,
                  onTap: () => provider.switchModel(AIModel.gemini),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModelButton(
                  title: 'Claude',
                  subtitle: 'Smart & Paid',
                  icon: Icons.psychology,
                  color: AppColors.premiumAmber,
                  isActive: provider.settings.activeModel == AIModel.claude,
                  isAvailable: provider.settings.hasClaudeKey,
                  onTap: () => provider.switchModel(AIModel.claude),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModelButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isActive,
    required bool isAvailable,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isAvailable ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive
              ? color.withOpacity(0.2)
              : AppColors.backgroundBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : Colors.white.withOpacity(0.1),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isAvailable ? color : AppColors.textTertiary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isAvailable ? Colors.white : AppColors.textTertiary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 10,
              ),
            ),
            if (!isAvailable) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'No Key',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUsageStats(AIAssistantProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              Text(
                'Usage This Month',
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            provider.usageSummary,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (provider.settings.activeModel == AIModel.gemini) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: provider.estimatedFreeUsagePercent / 100,
              backgroundColor: AppColors.backgroundBlack,
              valueColor: AlwaysStoppedAnimation<Color>(
                provider.estimatedFreeUsagePercent > 80
                    ? AppColors.warning
                    : AppColors.info,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${provider.estimatedFreeUsagePercent.toStringAsFixed(1)}% of free tier used',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApiKeySection({
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required bool isConfigured,
    required bool showKey,
    required VoidCallback onToggleVisibility,
    required Function(String) onSave,
    required VoidCallback onGetKey,
    required Color color,
    required IconData icon,
    required List<String> steps,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (isConfigured)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 12,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Configured',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Setup Steps
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundBlack,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Setup Steps:',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...steps.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${entry.key + 1}',
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // API Key Input
          TextField(
            controller: controller,
            obscureText: !showKey,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              hintText: isConfigured
                  ? 'Enter new key to replace'
                  : 'Paste your API key here',
              hintStyle: TextStyle(color: AppColors.textTertiary),
              filled: true,
              fillColor: AppColors.backgroundBlack,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      showKey ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: onToggleVisibility,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.content_paste,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () async {
                      final data = await Clipboard.getData(
                        Clipboard.kTextPlain,
                      );
                      if (data?.text != null && mounted) {
                        controller.text = data!.text!;
                      }
                    },
                  ),
                ],
              ),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty && !value.contains('•')) {
                onSave(value);
              }
            },
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onGetKey,
                  icon: Icon(Icons.open_in_new, size: 16, color: color),
                  label: Text('Get API Key', style: TextStyle(color: color)),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    final key = controller.text;
                    if (key.isNotEmpty && !key.contains('•')) {
                      onSave(key);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save Key'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'About API Keys',
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Your keys are stored securely on your device only\n'
            '• Keys are never sent to our servers\n'
            '• Gemini offers a generous free tier\n'
            '• Claude costs ~₹0.50-2 per conversation\n'
            '• You can switch between models anytime',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: AppColors.error),
            onPressed: () => context.read<AIAssistantProvider>().clearError(),
          ),
        ],
      ),
    );
  }

  Future<void> _saveGeminiKey(AIAssistantProvider provider, String key) async {
    final success = await provider.setGeminiApiKey(key);
    if (success && mounted) {
      _geminiController.text = '••••••••••••••••••••';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gemini API key saved successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveClaudeKey(AIAssistantProvider provider, String key) async {
    final success = await provider.setClaudeApiKey(key);
    if (success && mounted) {
      _claudeController.text = '••••••••••••••••••••';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Claude API key saved successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Could not open $url')));
        }
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}