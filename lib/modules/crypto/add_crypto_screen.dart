import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/models/crypto.dart';
import '../../core/providers/crypto_provider.dart';
import '../../core/services/crypto_price_service.dart';
import '../../core/widgets/top_snackbar.dart';

class AddCryptoScreen extends StatefulWidget {
  const AddCryptoScreen({super.key});

  @override
  State<AddCryptoScreen> createState() => _AddCryptoScreenState();
}

class _AddCryptoScreenState extends State<AddCryptoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _notesController = TextEditingController();
  final _cryptoService = CryptoPriceService();

  List<Map<String, String>> _searchResults = [];
  Map<String, String>? _selectedCrypto;
  DateTime _purchaseDate = DateTime.now();
  bool _isSearching = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _amountController.dispose();
    _purchasePriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _searchCrypto(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _cryptoService.searchCrypto(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      showTopSnackBar(context, 'Error searching crypto: $e', isError: true);
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _selectCrypto(Map<String, String> crypto) {
    setState(() {
      _selectedCrypto = crypto;
      _nameController.text = 'My ${crypto['name']}';
      _searchController.clear();
      _searchResults = [];
    });
  }

  Future<void> _saveCrypto() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCrypto == null) {
      showTopSnackBar(context, 'Please select a cryptocurrency', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        showTopSnackBar(context, 'User not logged in', isError: true);
        return;
      }

      final provider = context.read<CryptoProvider>();
      final newAmount = double.parse(_amountController.text.trim());
      final newPurchasePrice = double.parse(
        _purchasePriceController.text.trim(),
      );

      // Check if user already has this crypto
      final existingCrypto = provider.cryptos.firstWhere(
        (c) => c.cryptoId == _selectedCrypto!['id']! && c.isActive,
        orElse: () => Crypto(
          id: '',
          userId: user.uid,
          cryptoId: '',
          name: '',
          symbol: '',
          amount: 0,
          purchasePrice: 0,
          purchaseDate: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (existingCrypto.id.isNotEmpty) {
        // Accumulate: Calculate weighted average purchase price
        final totalOldValue =
            existingCrypto.amount * existingCrypto.purchasePrice;
        final totalNewValue = newAmount * newPurchasePrice;
        final totalAmount = existingCrypto.amount + newAmount;
        final avgPurchasePrice = (totalOldValue + totalNewValue) / totalAmount;

        final updatedCrypto = existingCrypto.copyWith(
          amount: totalAmount,
          purchasePrice: avgPurchasePrice,
          updatedAt: DateTime.now(),
          notes: _notesController.text.trim().isEmpty
              ? existingCrypto.notes
              : '${existingCrypto.notes ?? ''}\n${_notesController.text.trim()}'
                    .trim(),
        );

        await provider.updateCrypto(updatedCrypto);

        if (mounted) {
          showTopSnackBar(
            context,
            'Updated existing holdings! Total: ${totalAmount.toStringAsFixed(8)} ${_selectedCrypto!['symbol']}',
          );
          Navigator.of(context).pop();
        }
      } else {
        // Create new entry
        final crypto = Crypto(
          id: '',
          userId: user.uid,
          cryptoId: _selectedCrypto!['id']!,
          name: _nameController.text.trim(),
          symbol: _selectedCrypto!['symbol']!,
          amount: newAmount,
          purchasePrice: newPurchasePrice,
          purchaseDate: _purchaseDate,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await provider.addCrypto(crypto);

        if (mounted) {
          showTopSnackBar(context, 'Crypto added successfully!');
          Navigator.of(context).pop();
        }
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
                    Text(
                      'Add Crypto',
                      style: AppTypography.headlineMedium.copyWith(
                        color: colorScheme.onSurface,
                      ),
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
                        // Search Crypto
                        Text(
                          'Search Cryptocurrency',
                          style: AppTypography.titleSmall.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _searchController,
                          style: TextStyle(color: colorScheme.onSurface),
                          decoration: InputDecoration(
                            hintText: 'Search Bitcoin, Ethereum, etc.',
                            hintStyle: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                            prefixIcon: Icon(
                              Icons.search,
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
                          onChanged: (value) {
                            _searchCrypto(value);
                          },
                        ),

                        // Search Results
                        if (_isSearching)
                          const Padding(
                            padding: EdgeInsets.all(AppSpacing.md),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_searchResults.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.cardDarkElevated,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                            ),
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final crypto = _searchResults[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.accentTeal
                                        .withOpacity(0.2),
                                    child: Text(
                                      crypto['symbol']![0],
                                      style: TextStyle(
                                        color: AppColors.accentTeal,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    crypto['name']!,
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  subtitle: Text(
                                    crypto['symbol']!,
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withOpacity(
                                        0.6,
                                      ),
                                    ),
                                  ),
                                  onTap: () => _selectCrypto(crypto),
                                );
                              },
                            ),
                          ),

                        // Selected Crypto
                        if (_selectedCrypto != null) ...[
                          const SizedBox(height: AppSpacing.lg),
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
                                    _selectedCrypto!['symbol']![0],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedCrypto!['name']!,
                                        style: AppTypography.titleSmall
                                            .copyWith(
                                              color: colorScheme.onSurface,
                                            ),
                                      ),
                                      Text(
                                        _selectedCrypto!['symbol']!,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: colorScheme.onSurface
                                              .withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: AppColors.error,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _selectedCrypto = null;
                                      _nameController.clear();
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],

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
                            suffixText: _selectedCrypto?['symbol'] ?? '',
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
                          'Purchase Price (₹ per unit)',
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
                          'Notes (Optional)',
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

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveCrypto,
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
                                    'Add Crypto',
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
