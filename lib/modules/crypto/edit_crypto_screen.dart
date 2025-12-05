import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/models/crypto.dart';
import '../../core/providers/crypto_provider.dart';
import '../../core/widgets/top_snackbar.dart';

class EditCryptoScreen extends StatefulWidget {
  final Crypto crypto;

  const EditCryptoScreen({super.key, required this.crypto});

  @override
  State<EditCryptoScreen> createState() => _EditCryptoScreenState();
}

class _EditCryptoScreenState extends State<EditCryptoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _notesController;
  late DateTime _purchaseDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.crypto.name);
    _amountController = TextEditingController(
      text: widget.crypto.amount.toStringAsFixed(8),
    );
    _purchasePriceController = TextEditingController(
      text: widget.crypto.purchasePrice.toStringAsFixed(2),
    );
    _notesController = TextEditingController(text: widget.crypto.notes ?? '');
    _purchaseDate = widget.crypto.purchaseDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _purchasePriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateCrypto() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedCrypto = widget.crypto.copyWith(
        name: _nameController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        purchasePrice: double.parse(_purchasePriceController.text.trim()),
        purchaseDate: _purchaseDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await context.read<CryptoProvider>().updateCrypto(updatedCrypto);

      if (mounted) {
        showTopSnackBar(context, 'Crypto updated successfully!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(context, 'Error: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteCrypto() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text(
          'Delete Crypto',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this crypto holding?',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _isLoading = true;
      });

      try {
        await context.read<CryptoProvider>().deleteCrypto(widget.crypto.id);

        if (mounted) {
          showTopSnackBar(context, 'Crypto deleted successfully!');
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          showTopSnackBar(context, 'Error: $e', isError: true);
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.darkGradient.first,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.darkGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: colorScheme.onSurface,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Edit ${widget.crypto.symbol}',
                        style: AppTypography.headlineMedium.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: AppColors.error),
                      onPressed: _isLoading ? null : _deleteCrypto,
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Crypto Info Card
                        Container(
                          padding: AppSpacing.cardPaddingMd,
                          decoration: BoxDecoration(
                            color: AppColors.accentTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            border: Border.all(color: AppColors.accentTeal),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.accentTeal,
                                child: Text(
                                  widget.crypto.symbol[0],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.crypto.symbol,
                                      style: AppTypography.titleMedium.copyWith(
                                        color: colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'ID: ${widget.crypto.cryptoId}',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: colorScheme.onSurface
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Investment Name
                        Text(
                          'Investment Name',
                          style: AppTypography.titleSmall.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextFormField(
                          controller: _nameController,
                          style: TextStyle(color: colorScheme.onSurface),
                          decoration: InputDecoration(
                            hintText: 'e.g., My Bitcoin Investment',
                            hintStyle: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                            filled: true,
                            fillColor: AppColors.cardDarkElevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter an investment name';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Amount
                        Text(
                          'Amount',
                          style: AppTypography.titleSmall.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextFormField(
                          controller: _amountController,
                          style: TextStyle(color: colorScheme.onSurface),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,8}'),
                            ),
                          ],
                          decoration: InputDecoration(
                            hintText: 'e.g., 0.5',
                            hintStyle: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                            suffixText: widget.crypto.symbol,
                            suffixStyle: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                            filled: true,
                            fillColor: AppColors.cardDarkElevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter amount';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            if (double.parse(value) <= 0) {
                              return 'Amount must be greater than 0';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Purchase Price
                        Text(
                          'Average Purchase Price (₹ per unit)',
                          style: AppTypography.titleSmall.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextFormField(
                          controller: _purchasePriceController,
                          style: TextStyle(color: colorScheme.onSurface),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                          decoration: InputDecoration(
                            hintText: 'e.g., 3750000.00',
                            hintStyle: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                            prefixText: '₹ ',
                            prefixStyle: TextStyle(
                              color: colorScheme.onSurface,
                            ),
                            filled: true,
                            fillColor: AppColors.cardDarkElevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter purchase price';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            if (double.parse(value) <= 0) {
                              return 'Price must be greater than 0';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Purchase Date
                        Text(
                          'Purchase Date',
                          style: AppTypography.titleSmall.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _purchaseDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.dark().copyWith(
                                    colorScheme: ColorScheme.dark(
                                      primary: AppColors.primaryBlue,
                                      surface: AppColors.cardDark,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (date != null) {
                              setState(() {
                                _purchaseDate = date;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.cardDarkElevated,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Text(
                                  '${_purchaseDate.day}/${_purchaseDate.month}/${_purchaseDate.year}',
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Notes
                        Text(
                          'Notes',
                          style: AppTypography.titleSmall.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextFormField(
                          controller: _notesController,
                          style: TextStyle(color: colorScheme.onSurface),
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Add any notes about this investment...',
                            hintStyle: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                            filled: true,
                            fillColor: AppColors.cardDarkElevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl2),

                        // Update Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateCrypto,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentTeal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.lg,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Update Crypto',
                                    style: AppTypography.titleSmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
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
}
