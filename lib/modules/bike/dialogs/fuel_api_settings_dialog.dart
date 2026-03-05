import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/providers/fuel_price_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class FuelAPISettingsDialog extends StatefulWidget {
  const FuelAPISettingsDialog({super.key});

  @override
  State<FuelAPISettingsDialog> createState() => _FuelAPISettingsDialogState();
}

class _FuelAPISettingsDialogState extends State<FuelAPISettingsDialog> {
  final _apiKeyController = TextEditingController();
  bool _isLoading = false;
  String? _message;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveAPIKey() async {
    if (_apiKeyController.text.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _message = 'Please enter an API key';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _message = null;
      });
    }

    try {
      if (!mounted) {
        return;
      }

      final priceProvider = Provider.of<FuelPriceProvider>(
        context,
        listen: false,
      );
      await priceProvider.setAPIKey(_apiKeyController.text.trim());

      // Test the API by refreshing
      await priceProvider.refresh();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _message = 'API key saved! Prices updated.';
        });

        // Close dialog after 1.5 seconds
        await Future.delayed(AppAnimations.veryLong);
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      debugPrint('Error saving API key: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _message = 'Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.backgroundBlack,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RapidAPI Settings',
                    style: AppTypography.headlineSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Add your RapidAPI key to get live fuel prices',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // API Key Input
              _buildLabel('API KEY'),
              _buildGlassField(
                controller: _apiKeyController,
                hint: 'e.g., a1b2c3d4e5...',
                maxLines: 2,
              ),

              if (_message != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _message!.contains('Error')
                        ? AppColors.error.withValues(alpha: 0.1)
                        : AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _message!.contains('Error')
                          ? AppColors.error.withValues(alpha: 0.3)
                          : AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _message!.contains('Error')
                            ? Icons.error_outline
                            : Icons.check_circle_outline,
                        color: _message!.contains('Error')
                            ? AppColors.error
                            : AppColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _message!,
                          style: AppTypography.bodySmall.copyWith(
                            color: _message!.contains('Error')
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Get your free API key from RapidAPI:\n1. Visit rapidapi.com\n2. Search "india fuel price"\n3. Subscribe to free plan\n4. Copy your API key',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primaryBlue,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAPIKey,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save & Test',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(
      text,
      style: TextStyle(
        color: AppColors.textTertiary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _buildGlassField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
