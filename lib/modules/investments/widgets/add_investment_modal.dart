import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_animations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import '../../../core/models/investment.dart';
import '../../../core/providers/investment_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/top_snackbar.dart';

class AddInvestmentModal extends StatefulWidget {
  final Investment? investmentToEdit;

  const AddInvestmentModal({super.key, this.investmentToEdit});

  @override
  State<AddInvestmentModal> createState() => _AddInvestmentModalState();
}

class _AddInvestmentModalState extends State<AddInvestmentModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

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
    _controller = AnimationController(
      duration: AppAnimations.slow,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.fadeOutCurve),
    );
    _controller.forward();

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
    _controller.dispose();
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
    if (query.length < 3) { return; }
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Blur Backdrop
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withValues(alpha: 0.6)),
          ),
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(
                  maxWidth: 450,
                  maxHeight: 800,
                ),
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.backgroundBlack,
                  borderRadius: BorderRadius.circular(32),
                   border: Border.all(
                     color: AppColors.white12,
                   ),
                  // SHADOW REMOVED HERE
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.investmentToEdit != null
                              ? 'Edit Investment'
                              : 'Add Investment',
                          style: AppTypography.headlineMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: AppColors.white54),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Type Pills
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
                    const SizedBox(height: AppSpacing.xl),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // SEARCH (MF ONLY)
                              if (_selectedType == InvestmentType.mutualFund &&
                                  widget.investmentToEdit == null) ...[
                                _buildLabel('Search Fund'),
                                _buildGlassField(
                                  controller: _searchController,
                                  hint: "e.g. SBI Small Cap",
                                  icon: Icons.search,
                                  onChanged: _searchFunds,
                                ),
                                if (_isSearching)
                                  const LinearProgressIndicator(
                                    color: AppColors.investmentIndigo,
                                    backgroundColor: Colors.transparent,
                                  ),
                                if (_searchResults.isNotEmpty)
                                  Container(
                                    height: 150,
                                    margin: const EdgeInsets.only(top: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardSurface,
                                      borderRadius: BorderRadius.circular(12),
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
                                        subtitle: Text(
                                          _searchResults[i]['schemeCode']
                                              .toString(),
                                          style: TextStyle(
                                            color: AppColors.textTertiary,
                                            fontSize: 10,
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
                                const SizedBox(height: AppSpacing.xl),
                              ],

                              // FIELDS
                              _buildLabel('Details'),
                              _buildGlassField(
                                controller: _nameController,
                                hint: "Asset Name",
                                icon: Icons.description_outlined,
                              ),
                              const SizedBox(height: AppSpacing.xl2),
                              if (_selectedType != InvestmentType.mutualFund)
                                _buildGlassField(
                                  controller: _symbolController,
                                  hint: "Symbol (BTC, AAPL)",
                                  icon: Icons.short_text,
                                ),

                              const SizedBox(height: AppSpacing.xl2),
                              _buildGlassField(
                                controller: _quantityController,
                                hint: "Quantity",
                                icon: Icons.pie_chart_outline,
                                isNumber: true,
                              ),

                              const SizedBox(height: AppSpacing.xl),
                              _buildLabel('Valuation (₹)'),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildGlassField(
                                      controller: _investedController,
                                      hint: "Invested Amt",
                                      isNumber: true,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildGlassField(
                                      controller: _currentController,
                                      hint: "Current Value",
                                      isNumber: true,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: AppSpacing.xl2),

                              // ACTIONS
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _saveAsset,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusMd,
                                      ),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          'Save Investment',
                                          style: AppTypography.titleSmall
                                              .copyWith(
                                                color: AppColors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
        duration: AppAnimations.standard,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.investmentIndigo
              : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
             border: Border.all(
               color: isSelected
                   ? AppColors.investmentIndigo
                   : AppColors.white12,
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: AppTypography.titleSmall.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildGlassField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    bool isNumber = false,
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
        fillColor: AppColors.cardElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
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
      validator: (value) => (value == null || value.isEmpty) ? "Required" : null,
    );
  }

  Future<void> _saveAsset() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) { return; }

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
          quantity: double.parse(_quantityController.text),
          investedAmount: double.parse(_investedController.text),
          currentAmount: double.parse(_currentController.text),
          purchasePrice: double.tryParse(_navController.text) ?? 0.0,
          startDate: DateTime.now(),
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
        if (mounted) { showTopSnackBar(context, 'Error: $e', isError: true); }
      } finally {
        if (mounted) { setState(() => _isLoading = false); }
      }
    }
  }
}

// Global helper
Future<void> showAddInvestmentModal(
  BuildContext context, {
  Investment? investmentToEdit,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, __, ___) =>
          AddInvestmentModal(investmentToEdit: investmentToEdit),
    ),
  );
}
