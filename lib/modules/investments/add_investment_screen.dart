import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/models/investment.dart';
import '../../../core/providers/investment_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/top_snackbar.dart';

class ModernAddInvestmentScreen extends StatefulWidget {
  final Investment? investmentToEdit;

  const ModernAddInvestmentScreen({super.key, this.investmentToEdit});

  @override
  State<ModernAddInvestmentScreen> createState() =>
      _ModernAddInvestmentScreenState();
}

class _ModernAddInvestmentScreenState extends State<ModernAddInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _symbolController = TextEditingController();
  final _investedController = TextEditingController();
  final _currentController = TextEditingController();
  final _quantityController = TextEditingController();
  final _searchController = TextEditingController();
  final _navController = TextEditingController();

  // State
  InvestmentType _selectedType = InvestmentType.mutualFund;
  bool _isLoading = false;
  bool _isSearching = false;
  List<dynamic> _searchResults = [];
  String? _selectedSchemeCode;

  @override
  void initState() {
    super.initState();
    if (widget.investmentToEdit != null) {
      final i = widget.investmentToEdit!;
      _selectedType = i.type;
      _nameController.text = i.name;
      _symbolController.text = i.symbol ?? '';
      _investedController.text = i.investedAmount.toString();
      _currentController.text = i.currentAmount.toString();
      _quantityController.text = i.quantity.toString();
      _selectedSchemeCode = i.mutualFundSchemeCode;
      _navController.text = i.purchasePrice.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _symbolController.dispose();
    _investedController.dispose();
    _currentController.dispose();
    _quantityController.dispose();
    _searchController.dispose();
    _navController.dispose();
    super.dispose();
  }

  // --- MUTUAL FUND API ---
  Future<void> _searchFunds(String query) async {
    if (query.length < 3) return;
    setState(() => _isSearching = true);
    try {
      final response = await http.get(
        Uri.parse('https://api.mfapi.in/mf/search?q=$query'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _searchResults = json.decode(response.body) as List;
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _fetchNav(String code) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.mfapi.in/mf/$code'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final nav = data['data'][0]['nav'];
        setState(() {
          _navController.text = nav.toString();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.investmentToEdit != null ? "Edit Asset" : "Add Asset";

    return Scaffold(
      backgroundColor: AppColors.darkGradient.first,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120.0,
            backgroundColor: AppColors.darkGradient.first,
            foregroundColor: AppColors.white,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(title, style: AppTypography.headlineMedium),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PRIMARY AMOUNT
                    Text(
                      'Invested Amount',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _investedController,
                      autofocus: widget.investmentToEdit == null,
                      style: AppTypography.displayMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        prefixText: '₹ ',
                        prefixStyle: AppTypography.displayMedium.copyWith(
                          color: AppColors.investmentIndigo,
                          fontWeight: FontWeight.bold,
                        ),
                        hintStyle: TextStyle(color: AppColors.textTertiary),
                        filled: true,
                        fillColor: AppColors.cardDarkElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty)
                          return 'Invested amount is required';
                        if (double.tryParse(value.trim()) == null)
                          return 'Please enter a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl2),

                    // ASSET TYPE
                    Text(
                      'Asset Type',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildTypeChip(
                            "Mutual Fund",
                            InvestmentType.mutualFund,
                          ),
                          _buildTypeChip("Stock", InvestmentType.stock),
                          _buildTypeChip("Crypto", InvestmentType.crypto),
                          _buildTypeChip("Gold", InvestmentType.gold),
                          _buildTypeChip(
                            "Real Estate",
                            InvestmentType.realEstate,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl2),

                    // MF SEARCH (Conditional)
                    if (_selectedType == InvestmentType.mutualFund &&
                        widget.investmentToEdit == null) ...[
                      Text(
                        'Search Mutual Fund',
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildStandardField(
                        controller: _searchController,
                        hint: "e.g. SBI Small Cap",
                        icon: Icons.search,
                        onChanged: _searchFunds,
                      ),
                      if (_isSearching)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: LinearProgressIndicator(
                            color: AppColors.investmentIndigo,
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                      if (_searchResults.isNotEmpty)
                        Container(
                          height: 180,
                          margin: const EdgeInsets.only(top: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.cardDarkElevated,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                          child: ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (ctx, i) => ListTile(
                              title: Text(
                                _searchResults[i]['schemeName'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Text(
                                _searchResults[i]['schemeCode'].toString(),
                                style: TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 11,
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  _nameController.text =
                                      _searchResults[i]['schemeName'];
                                  _selectedSchemeCode =
                                      _searchResults[i]['schemeCode']
                                          .toString();
                                  _searchResults = [];
                                  _fetchNav(_selectedSchemeCode!);
                                });
                              },
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xl2),
                    ],

                    // ASSET DETAILS
                    Text(
                      'Asset Details',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildStandardField(
                      controller: _nameController,
                      hint: "Asset Name",
                      icon: Icons.description_outlined,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (_selectedType != InvestmentType.mutualFund) ...[
                      _buildStandardField(
                        controller: _symbolController,
                        hint: "Symbol (BTC, AAPL)",
                        icon: Icons.short_text,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    _buildStandardField(
                      controller: _quantityController,
                      hint: "Quantity",
                      icon: Icons.pie_chart_outline,
                      isNumber: true,
                    ),
                    const SizedBox(height: AppSpacing.xl2),

                    // CURRENT VALUATION
                    Text(
                      'Current Valuation (Optional)',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildStandardField(
                      controller: _currentController,
                      hint: "Current Value (₹)",
                      icon: Icons.trending_up,
                      isNumber: true,
                      isRequired: false,
                    ),
                    const SizedBox(height: AppSpacing.xl2),

                    // SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveAsset,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.investmentIndigo,
                          foregroundColor: AppColors.white,
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
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : Text(
                                widget.investmentToEdit != null
                                    ? "Save Changes"
                                    : "Save Asset",
                                style: AppTypography.titleSmall.copyWith(
                                  color: AppColors.white,
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
    );
  }

  Widget _buildTypeChip(String label, InvestmentType type) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.investmentIndigo
              : AppColors.cardDarkElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isSelected ? AppColors.investmentIndigo : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStandardField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    bool isNumber = false,
    bool isRequired = true,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      onChanged: onChanged,
      style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.cardDarkElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        prefixIcon: icon != null
            ? Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.sm,
                ),
                child: Icon(icon, color: AppColors.textSecondary, size: 20),
              )
            : null,
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) return "Required";
        return null;
      },
    );
  }

  Future<void> _saveAsset() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        final investment = Investment(
          id:
              widget.investmentToEdit?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          userId: user.uid,
          name: _nameController.text.trim(),
          type: _selectedType,
          symbol: _symbolController.text.trim().toUpperCase(),
          mutualFundSchemeCode: _selectedSchemeCode,
          mutualFundSchemeName: _selectedType == InvestmentType.mutualFund
              ? _nameController.text
              : null,
          quantity: double.tryParse(_quantityController.text) ?? 1.0,
          investedAmount: double.parse(_investedController.text),
          currentAmount:
              double.tryParse(_currentController.text) ??
              double.parse(_investedController.text),
          purchasePrice: double.tryParse(_navController.text) ?? 0.0,
          startDate: widget.investmentToEdit?.startDate ?? DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        final provider = Provider.of<InvestmentProvider>(
          context,
          listen: false,
        );
        if (widget.investmentToEdit != null) {
          await provider.updateInvestment(investment);
        } else {
          await provider.addInvestment(investment);
        }

        if (mounted) {
          Navigator.pop(context);
          showTopSnackBar(context, 'Asset Saved');
        }
      } catch (e) {
        if (mounted) showTopSnackBar(context, 'Error: $e', isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}

Future<void> navToAddInvestmentScreen(
  BuildContext context, {
  Investment? investmentToEdit,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          ModernAddInvestmentScreen(investmentToEdit: investmentToEdit),
    ),
  );
}
