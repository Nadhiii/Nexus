import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/bike.dart';
import '../../../core/providers/bike_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class DeletedBikesScreen extends StatelessWidget {
  const DeletedBikesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        title: const Text('Deleted Vehicles'),
        backgroundColor: AppColors.backgroundBlack,
        elevation: 0,
      ),
      body: Consumer<BikeProvider>(
        builder: (context, provider, _) {
          if (provider.deletedBikes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: 64,
                    color: AppColors.textTertiary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Deleted Vehicles',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Deleted vehicles will appear here',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: provider.deletedBikes.length,
            itemBuilder: (context, index) {
              final bike = provider.deletedBikes[index];
              return _buildDeletedBikeCard(context, bike, provider);
            },
          );
        },
      ),
    );
  }

  Widget _buildDeletedBikeCard(
    BuildContext context,
    Bike bike,
    BikeProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.two_wheeler,
                  color: AppColors.error,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bike.name,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${bike.make} ${bike.model} ${bike.year}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      bike.registrationNumber,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await provider.restoreBike(bike.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${bike.name} restored successfully'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: BorderSide(color: AppColors.success.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.restore, size: 20),
                  label: const Text('Restore'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showPermanentDeleteDialog(context, bike, provider);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.delete_forever, size: 20),
                  label: const Text('Delete Forever'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPermanentDeleteDialog(
    BuildContext context,
    Bike bike,
    BikeProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text(
          'Permanently Delete?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to permanently delete "${bike.name}"? This action cannot be undone and will delete all associated entries and trips.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Permanently delete the bike (hard delete)
              await provider.permanentlyDeleteBike(bike.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${bike.name} permanently deleted'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }
}
