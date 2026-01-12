import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/fuel_price_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
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
      if (!mounted) return;

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
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      print('Error saving API key: $e');
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
      backgroundColor: AppColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'RapidAPI Settings',
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
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
            TextField(
              controller: _apiKeyController,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                labelText: 'RapidAPI Key',
                labelStyle: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
                hintText: 'e.g., a1b2c3d4e5...',
                hintStyle: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary.withOpacity(0.5),
                ),
                filled: true,
                fillColor: AppColors.backgroundBlack,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.primaryBlue),
                ),
              ),
              maxLines: 3,
              minLines: 1,
            ),

            if (_message != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _message!.contains('Error')
                      ? AppColors.error.withOpacity(0.1)
                      : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                  color: AppColors.primaryBlue.withOpacity(0.3),
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Get your free API key from RapidAPI:\n1. Visit rapidapi.com\n2. Search "india fuel price"\n3. Subscribe to free plan\n4. Copy your API key',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primaryBlue,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveAPIKey,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Save & Test',
                          style: AppTypography.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
