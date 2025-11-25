import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/mutualfunds.dart';
import '../../core/providers/investment_provider.dart';
import '../../core/widgets/top_snackbar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';

class AddInvestmentScreen extends StatefulWidget {
  static const routeName = '/add-investment';

  const AddInvestmentScreen({super.key});

  @override
  _AddInvestmentScreenState createState() => _AddInvestmentScreenState();
}

class _AddInvestmentScreenState extends State<AddInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _investedAmountController = TextEditingController();
  final _purchaseNavController = TextEditingController();
  final _sipAmountController = TextEditingController();
  final _sipDayController = TextEditingController();

  MutualFund? _selectedFund;
  List<MutualFund> _searchResults = [];
  bool _isSearching = false;
  bool _fetchingNav = false;
  DateTime _selectedDate = DateTime.now();
  double? _calculatedUnits;

  Future<void> _searchFunds(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final response = await http.get(
        Uri.parse('https://api.mfapi.in/mf/search?q=$query'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          _searchResults = data
              .map((fund) => MutualFund.fromJson(fund))
              .toList();
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _calculateUnits() {
    final invested = double.tryParse(_investedAmountController.text) ?? 0;
    final nav = double.tryParse(_purchaseNavController.text) ?? 0;

    if (invested > 0 && nav > 0) {
      setState(() {
        _calculatedUnits = invested / nav;
      });
    } else {
      setState(() {
        _calculatedUnits = null;
      });
    }
  }

  Future<void> _fetchCurrentNav() async {
    if (_selectedFund == null) return;

    setState(() => _fetchingNav = true);

    try {
      final response = await http.get(
        Uri.parse('https://api.mfapi.in/mf/${_selectedFund!.schemeCode}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final navData = data['data'] as List?;
        if (navData != null && navData.isNotEmpty) {
          final currentNav = double.parse(navData[0]['nav'].toString());
          setState(() {
            _purchaseNavController.text = currentNav.toStringAsFixed(4);
            _fetchingNav = false;
          });
          _calculateUnits();
        }
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(context, 'Error fetching NAV: $e', isError: true);
      }
    } finally {
      setState(() => _fetchingNav = false);
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate() && _selectedFund != null) {
      _formKey.currentState!.save();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final investedAmount = double.parse(_investedAmountController.text);
        final purchaseNav = double.parse(_purchaseNavController.text);
        final units = _calculatedUnits ?? (investedAmount / purchaseNav);
        final sipAmount = double.tryParse(_sipAmountController.text) ?? 0.0;

        final newInvestment = Investment(
          id: ' ',
          userId: user.uid,
          name: _nameController.text,
          mutualFundSchemeCode: _selectedFund!.schemeCode,
          mutualFundSchemeName: _selectedFund!.schemeName,
          sipAmount: sipAmount,
          sipDay: int.tryParse(_sipDayController.text) ?? 1,
          startDate: _selectedDate,
          purchaseNav: purchaseNav,
          units: units,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await Provider.of<InvestmentProvider>(
          context,
          listen: false,
        ).addInvestment(newInvestment);

        if (mounted) {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
          showTopSnackBar(context, 'Investment added successfully');
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop();
          showTopSnackBar(context, 'Error: $e', isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkGradient.first,
      appBar: AppBar(
        title: Text(
          'Add New SIP',
          style: AppTypography.headlineSmall.copyWith(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.darkGradient,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search for a Fund',
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _searchController,
                  style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'E.g., TATA Digital India',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _searchFunds,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_isSearching)
                  const Center(child: CircularProgressIndicator()),
                if (_searchResults.isNotEmpty)
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (ctx, i) => ListTile(
                        title: Text(
                          _searchResults[i].schemeName,
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          _searchResults[i].schemeCode,
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedFund = _searchResults[i];
                            _searchController.text =
                                _searchResults[i].schemeName;
                            _nameController.text = _searchResults[i].schemeName;
                            _searchResults = [];
                          });
                        },
                      ),
                    ),
                  ),
                if (_selectedFund != null)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: AppColors.primaryBlue.withOpacity(0.3),
                      ),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                      ),
                      title: Text(
                        _selectedFund!.schemeName,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        'Scheme Code: ${_selectedFund!.schemeCode}',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white),
                        onPressed: () => setState(() {
                          _selectedFund = null;
                          _searchController.clear();
                          _nameController.clear();
                        }),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Investment Details',
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _nameController,
                  style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Investment Nickname',
                    labelStyle: TextStyle(color: Colors.white70),
                    hintText: 'e.g., My TATA Digital SIP',
                    hintStyle: TextStyle(color: Colors.white30),
                    prefixIcon: const Icon(Icons.label, color: Colors.white70),
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (val) =>
                      val!.isEmpty ? 'Please enter a name' : null,
                ),
                const SizedBox(height: AppSpacing.xl),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(
                      color: AppColors.primaryBlue.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet,
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            'Current Investment',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        controller: _investedAmountController,
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Total Amount Invested',
                          labelStyle: TextStyle(color: Colors.white70),
                          hintText: 'e.g., 1999',
                          hintStyle: TextStyle(color: Colors.white30),
                          prefixIcon: const Icon(
                            Icons.currency_rupee,
                            color: Colors.white70,
                          ),
                          helperText:
                              'How much money have you already invested?',
                          helperStyle: TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: AppColors.cardDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => _calculateUnits(),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Enter invested amount';
                          }
                          if (double.tryParse(val) == null) {
                            return 'Enter valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _purchaseNavController,
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.white,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Purchase NAV',
                                labelStyle: TextStyle(color: Colors.white70),
                                hintText: 'e.g., 10.0772',
                                hintStyle: TextStyle(color: Colors.white30),
                                prefixIcon: const Icon(
                                  Icons.show_chart,
                                  color: Colors.white70,
                                ),
                                helperText: 'NAV when you bought the units',
                                helperStyle: TextStyle(color: Colors.white54),
                                filled: true,
                                fillColor: AppColors.cardDark,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd,
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (_) => _calculateUnits(),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Enter NAV';
                                }
                                if (double.tryParse(val) == null) {
                                  return 'Enter valid NAV';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: _fetchCurrentNav,
                              icon: _fetchingNav
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.refresh, size: 18),
                              label: const Text('Get Current'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_calculatedUnits != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            border: Border.all(
                              color: AppColors.success.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.success,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  'You own ${_calculatedUnits!.toStringAsFixed(3)} units',
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.accentOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(
                      color: AppColors.accentOrange.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.repeat,
                            color: AppColors.accentOrange,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            'Future SIP (Optional)',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentOrange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'If you plan to invest monthly, enter the details below',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.accentOrange.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _sipAmountController,
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.white,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Monthly SIP Amount',
                                labelStyle: TextStyle(color: Colors.white70),
                                hintText: 'e.g., 1000',
                                hintStyle: TextStyle(color: Colors.white30),
                                prefixIcon: const Icon(
                                  Icons.currency_rupee,
                                  color: Colors.white70,
                                ),
                                filled: true,
                                fillColor: AppColors.cardDark,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd,
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: TextFormField(
                              controller: _sipDayController,
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.white,
                              ),
                              decoration: InputDecoration(
                                labelText: 'SIP Day',
                                labelStyle: TextStyle(color: Colors.white70),
                                hintText: 'e.g., 5',
                                hintStyle: TextStyle(color: Colors.white30),
                                prefixIcon: const Icon(
                                  Icons.calendar_today,
                                  color: Colors.white70,
                                ),
                                filled: true,
                                fillColor: AppColors.cardDark,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd,
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (val) {
                                if (val == null || val.isEmpty) return null;
                                final day = int.tryParse(val);
                                if (day == null || day < 1 || day > 28) {
                                  return '1-28';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: ListTile(
                    title: Text(
                      'Start Date',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      _selectedDate.toLocal().toString().split(' ')[0],
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                    ),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppColors.primaryBlue,
                                onPrimary: Colors.white,
                                surface: AppColors.cardDark,
                                onSurface: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (pickedDate != null && pickedDate != _selectedDate) {
                        setState(() => _selectedDate = pickedDate);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                      ),
                    ),
                    child: Text(
                      'Save Investment',
                      style: AppTypography.labelLarge.copyWith(
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
      ),
    );
  }
}
