import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/models/pdf_parsing_provider.dart';
import '../models/Nex_settings.dart';
import '../providers/Nex_assistant_provider.dart';

class NexSettingsScreen extends StatefulWidget {
  const NexSettingsScreen({super.key});

  @override
  State<NexSettingsScreen> createState() => _NexSettingsScreenState();
}

class _NexSettingsScreenState extends State<NexSettingsScreen> {
  final _geminiController = TextEditingController();
  final _claudeController = TextEditingController();
  bool _showGeminiKey = false;
  bool _showClaudeKey = false;
  bool _hasLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded && mounted) {
      _hasLoaded = true;
      final provider = context.read<AIAssistantProvider>();
      if (provider.settings.hasGeminiKey) {
        _geminiController.text = '••••••••••••••••••••';
      }
      if (provider.settings.claudeApiKey != null &&
          provider.settings.claudeApiKey!.isNotEmpty) {
        _claudeController.text = '••••••••••••••••••••';
      }
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
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Gemini API Key',
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _geminiController,
                obscureText: !_showGeminiKey,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Paste your API key here',
                  hintStyle: TextStyle(color: AppColors.textTertiary),
                  filled: true,
                  fillColor: AppColors.cardSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showGeminiKey ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _showGeminiKey = !_showGeminiKey),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Required for: PDF parsing, Chat',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Gemini Mode',
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildModeChip(provider, 'Auto', GeminiMode.auto),
                  _buildModeChip(provider, 'Fast', GeminiMode.fast),
                  _buildModeChip(provider, 'Thinking', GeminiMode.thinking),
                  _buildModeChip(provider, 'Pro', GeminiMode.pro),
                ],
              ),
              const SizedBox(height: 32),
              const Divider(color: AppColors.cardSurface),
              const SizedBox(height: 24),
              Text(
                'PDF Parsing Provider',
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose which AI service to use for PDF parsing:',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildProviderChip(
                    provider,
                    'Gemini',
                    PDFParsingProvider.gemini,
                  ),
                  _buildProviderChip(
                    provider,
                    'Claude',
                    PDFParsingProvider.claude,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Divider(color: AppColors.cardSurface),
              const SizedBox(height: 24),
              Text(
                'Claude API Key (Optional)',
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _claudeController,
                obscureText: !_showClaudeKey,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Paste your Claude API key here',
                  hintStyle: TextStyle(color: AppColors.textTertiary),
                  filled: true,
                  fillColor: AppColors.cardSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showClaudeKey ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _showClaudeKey = !_showClaudeKey),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Optional - For chat only (PDF parsing uses Gemini)',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 32),
              // Unified Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final geminiKey = _geminiController.text;
                    final claudeKey = _claudeController.text;
                    bool anySuccess = false;
                    String message = '';

                    // Save Gemini key
                    if (geminiKey.isNotEmpty && !geminiKey.contains('•')) {
                      try {
                        await provider.setGeminiApiKey(geminiKey);
                        anySuccess = true;
                        message += 'Gemini key saved! ';
                      } catch (e) {
                        message += 'Gemini key failed. ';
                      }
                    }

                    // Save Claude key
                    if (claudeKey.isNotEmpty && !claudeKey.contains('•')) {
                      try {
                        await provider.setClaudeApiKey(claudeKey);
                        anySuccess = true;
                        message += 'Claude key saved! ';
                      } catch (e) {
                        message += 'Claude key failed. ';
                      }
                    }

                    if (mounted && message.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message.trim()),
                          backgroundColor: anySuccess
                              ? AppColors.success
                              : AppColors.error,
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
                    'Save All API Keys',
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

  Widget _buildModeChip(
    AIAssistantProvider provider,
    String label,
    GeminiMode mode,
  ) {
    final isSelected = provider.settings.geminiMode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => provider.setGeminiMode(mode),
      selectedColor: AppColors.info.withOpacity(0.3),
      backgroundColor: AppColors.backgroundBlack,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textTertiary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
      shape: StadiumBorder(
        side: BorderSide(
          color: isSelected ? AppColors.info : Colors.white.withOpacity(0.1),
        ),
      ),
    );
  }

  Widget _buildProviderChip(
    AIAssistantProvider provider,
    String label,
    PDFParsingProvider pdfProvider,
  ) {
    final isSelected = provider.settings.pdfParsingProvider == pdfProvider;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => provider.setPDFParsingProvider(pdfProvider),
      selectedColor: AppColors.success.withOpacity(0.3),
      backgroundColor: AppColors.backgroundBlack,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textTertiary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
      shape: StadiumBorder(
        side: BorderSide(
          color: isSelected ? AppColors.success : Colors.white.withOpacity(0.1),
        ),
      ),
    );
  }
}
