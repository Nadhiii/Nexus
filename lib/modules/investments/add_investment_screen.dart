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
import '../../../core/theme/app_animations.dart';
import '../../../core/widgets/top_snackbar.dart';

class ModernAddInvestmentScreen extends StatefulWidget {
  final Investment? investmentToEdit;

  const ModernAddInvestmentScreen({super.key, this.investmentToEdit});

  static Future<void> show(
    BuildContext context, {
    Investment? investmentToEdit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) =>
          ModernAddInvestmentScreen(investmentToEdit: investmentToEdit),
    );
  }

  @override
  State<ModernAddInvestmentScreen> createState() =>
      _ModernAddInvestmentScreenState();
}

class _ModernAddInvestmentScreenState extends State<ModernAddInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _symbolController = TextEditingController();
  final _investedController = TextEditingController();
  final _currentController = TextEditingController();
  final _quantityController = TextEditingController();
  final _searchController = TextEditingController();
  final _navController = TextEditingController();

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
      _investedController.text = i.investedAmount.toStringAsFixed(0);
      _currentController.text = i.currentAmount.toStringAsFixed(0);
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
    } catch (_) {
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
        setState(() => _navController.text = nav.toString());
      }
    } catch (_) {}
  }

  Future<void> _saveAsset() async {
    if (!_formKey.currentState!.validate()) return;
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
        quantity: double.tryParse(_quantityController.text.trim()) ?? 1.0,
        investedAmount: double.parse(_investedController.text.trim()),
        currentAmount:
            double.tryParse(_currentController.text.trim()) ??
            double.parse(_investedController.text.trim()),
        purchasePrice: double.tryParse(_navController.text.trim()) ?? 0.0,
        startDate: widget.investmentToEdit?.startDate ?? DateTime.now(),
        lastUpdated: DateTime.now(),
      );

      final provider = context.read<InvestmentProvider>();
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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.investmentToEdit != null;

    return Material(
      color: AppColors.darkSurface,
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusLg),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xl + bottomInset,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderSubtleDark,
                      borderRadius: AppSpacing.borderRadiusFull,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? "Edit Asset" : "Add Asset",
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textSecondary,
                        size: AppSpacing.iconSm,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                _buildLabel('INVESTED AMOUNT'),
                TextFormField(
                  controller: _investedController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: AppTypography.currencyMedium.copyWith(
                    color: AppColors.investmentIndigo,
                  ),
                  decoration: InputDecoration(
                    hintText: "0.00",
                    hintStyle: AppTypography.currencyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    prefixText: "₹ ",
                    prefixStyle: AppTypography.currencyMedium.copyWith(
                      color: AppColors.investmentIndigo,
                    ),
                    filled: true,
                    fillColor: AppColors.darkSurfaceElevated,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusSm,
                      borderSide: const BorderSide(
                        color: AppColors.borderSubtleDark,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusSm,
                      borderSide: const BorderSide(
                        color: AppColors.borderSubtleDark,
                      ),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(AppSpacing.radiusSm),
                      ),
                      borderSide: BorderSide(
                        color: AppColors.investmentIndigo,
                        width: 1.5,
                      ),
                    ),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? "Invested amount is required"
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),

                _buildLabel('ASSET TYPE'),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildTypeChip("Mutual Fund", InvestmentType.mutualFund),
                      _buildTypeChip("Stock", InvestmentType.stock),
                      _buildTypeChip("Crypto", InvestmentType.crypto),
                      _buildTypeChip("Gold", InvestmentType.gold),
                      _buildTypeChip("Real Estate", InvestmentType.realEstate),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                if (_selectedType == InvestmentType.mutualFund &&
                    !isEditing) ...[
                  _buildLabel('SEARCH MUTUAL FUND'),
                  _buildField(
                    controller: _searchController,
                    hint: "e.g. SBI Small Cap, Parag Parikh",
                    icon: Icons.search,
                    onChanged: _searchFunds,
                  ),
                  if (_isSearching)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(
                        color: AppColors.investmentIndigo,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  if (_searchResults.isNotEmpty)
                    Container(
                      height: 140,
                      margin: const EdgeInsets.only(top: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurfaceElevated,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                        border: Border.all(color: AppColors.borderSubtleDark),
                      ),
                      child: ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (ctx, i) => ListTile(
                          title: Text(
                            _searchResults[i]['schemeName'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _nameController.text =
                                  _searchResults[i]['schemeName'];
                              _selectedSchemeCode =
                                  _searchResults[i]['schemeCode'].toString();
                              _searchResults = [];
                              _fetchNav(_selectedSchemeCode!);
                            });
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                _buildLabel('ASSET NAME'),
                _buildField(
                  controller: _nameController,
                  hint: "e.g. Nifty 50 Index Fund",
                  icon: Icons.description_outlined,
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? "Asset name is required"
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),

                Row(
                  children: [
                    if (_selectedType != InvestmentType.mutualFund) ...[
                      Expanded(
                        child: _buildField(
                          controller: _symbolController,
                          hint: "Symbol (BTC, RELIANCE)",
                          icon: Icons.short_text,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                    ],
                    Expanded(
                      child: _buildField(
                        controller: _quantityController,
                        hint: "Quantity (Units)",
                        icon: Icons.pie_chart_outline,
                        isNumber: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                _buildLabel('CURRENT VALUATION (OPTIONAL)'),
                _buildField(
                  controller: _currentController,
                  hint: "Current Total Value (₹)",
                  icon: Icons.trending_up,
                  isNumber: true,
                ),
                const SizedBox(height: AppSpacing.xl2),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          backgroundColor: AppColors.darkSurfaceElevated,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppSpacing.borderRadiusSm,
                            side: const BorderSide(
                              color: AppColors.borderSubtleDark,
                            ),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveAsset,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          backgroundColor: AppColors.investmentIndigo,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppSpacing.borderRadiusSm,
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isEditing ? 'Save Changes' : 'Save Asset',
                                style: AppTypography.labelLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, InvestmentType type) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: AppAnimations.standard,
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.investmentIndigo.withValues(alpha: 0.15)
              : AppColors.darkSurfaceElevated,
          borderRadius: AppSpacing.borderRadiusSm,
          border: Border.all(
            color: isSelected
                ? AppColors.investmentIndigo
                : AppColors.borderSubtleDark,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isSelected
                  ? AppColors.investmentIndigo
                  : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isNumber = false,
    Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      onChanged: onChanged,
      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textTertiary,
        ),
        filled: true,
        fillColor: AppColors.darkSurfaceElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.sm,
          ),
          child: Icon(icon, color: AppColors.textSecondary, size: 20),
        ),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: const BorderSide(color: AppColors.borderSubtleDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusSm,
          borderSide: const BorderSide(color: AppColors.borderSubtleDark),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusSm)),
          borderSide: BorderSide(color: AppColors.investmentIndigo, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}

Future<void> navToAddInvestmentScreen(
  BuildContext context, {
  Investment? investmentToEdit,
}) {
  return ModernAddInvestmentScreen.show(
    context,
    investmentToEdit: investmentToEdit,
  );
}

Future<void> showAddInvestmentModal(
  BuildContext context, {
  Investment? investmentToEdit,
}) => navToAddInvestmentScreen(context, investmentToEdit: investmentToEdit);
