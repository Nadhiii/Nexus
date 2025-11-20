import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/investment.dart';
import '../../core/providers/investment_provider.dart';
import '../../core/widgets/top_snackbar.dart';

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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New SIP'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Search for a Fund',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'E.g., TATA Digital India',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: _searchFunds,
              ),
              const SizedBox(height: 16),
              if (_isSearching)
                const Center(child: CircularProgressIndicator()),
              if (_searchResults.isNotEmpty)
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (ctx, i) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(_searchResults[i].schemeName),
                        subtitle: Text(_searchResults[i].schemeCode),
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
                ),
              if (_selectedFund != null)
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  child: ListTile(
                    leading: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    title: Text(
                      _selectedFund!.schemeName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Scheme Code: ${_selectedFund!.schemeCode}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() {
                        _selectedFund = null;
                        _searchController.clear();
                        _nameController.clear();
                      }),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                'Investment Details',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Investment Nickname',
                  hintText: 'e.g., My TATA Digital SIP',
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (val) => val!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Current Investment',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _investedAmountController,
                      decoration: const InputDecoration(
                        labelText: 'Total Amount Invested',
                        hintText: 'e.g., 1999',
                        prefixIcon: Icon(Icons.currency_rupee),
                        helperText: 'How much money have you already invested?',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => _calculateUnits(),
                      validator: (val) {
                        if (val == null || val.isEmpty)
                          return 'Enter invested amount';
                        if (double.tryParse(val) == null)
                          return 'Enter valid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _purchaseNavController,
                            decoration: const InputDecoration(
                              labelText: 'Purchase NAV',
                              hintText: 'e.g., 10.0772',
                              prefixIcon: Icon(Icons.show_chart),
                              helperText: 'NAV when you bought the units',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => _calculateUnits(),
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return 'Enter NAV';
                              if (double.tryParse(val) == null)
                                return 'Enter valid NAV';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
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
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_calculatedUnits != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You own ${_calculatedUnits!.toStringAsFixed(3)} units',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
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
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.repeat, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'Future SIP (Optional)',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'If you plan to invest monthly, enter the details below',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.orange[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _sipAmountController,
                            decoration: const InputDecoration(
                              labelText: 'Monthly SIP Amount',
                              hintText: 'e.g., 1000',
                              prefixIcon: Icon(Icons.currency_rupee),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _sipDayController,
                            decoration: const InputDecoration(
                              labelText: 'SIP Day',
                              hintText: 'e.g., 5',
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return null;
                              final day = int.tryParse(val);
                              if (day == null || day < 1 || day > 28)
                                return '1-28';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                title: const Text('Start Date'),
                subtitle: Text(
                  _selectedDate.toLocal().toString().split(' ')[0],
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null && pickedDate != _selectedDate) {
                    setState(() => _selectedDate = pickedDate);
                  }
                },
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Text(
                    'Save Investment',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
