import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../core/models/investment.dart';
import '../../core/providers/investment_provider.dart';
import '../../core/widgets/top_snackbar.dart';

class EditInvestmentScreen extends StatefulWidget {
  final Investment investment;

  const EditInvestmentScreen({super.key, required this.investment});

  @override
  _EditInvestmentScreenState createState() => _EditInvestmentScreenState();
}

class _EditInvestmentScreenState extends State<EditInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _investedAmountController;
  late TextEditingController _purchaseNavController;
  late TextEditingController _sipAmountController;
  late TextEditingController _sipDayController;

  bool _fetchingNav = false;
  double? _calculatedUnits;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.investment.name);
    _investedAmountController = TextEditingController(
      text:
          widget.investment.investedAmount?.toStringAsFixed(2) ??
          (widget.investment.units * widget.investment.purchaseNav)
              .toStringAsFixed(2),
    );
    _purchaseNavController = TextEditingController(
      text: widget.investment.purchaseNav.toStringAsFixed(4),
    );
    _sipAmountController = TextEditingController(
      text: widget.investment.sipAmount > 0
          ? widget.investment.sipAmount.toStringAsFixed(0)
          : '',
    );
    _sipDayController = TextEditingController(
      text: widget.investment.sipDay > 0
          ? widget.investment.sipDay.toString()
          : '',
    );
    _selectedDate = widget.investment.startDate;
    _calculateUnits();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _investedAmountController.dispose();
    _purchaseNavController.dispose();
    _sipAmountController.dispose();
    _sipDayController.dispose();
    super.dispose();
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
    setState(() => _fetchingNav = true);

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.mfapi.in/mf/${widget.investment.mutualFundSchemeCode}',
        ),
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
    if (_formKey.currentState!.validate()) {
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

        final updatedInvestment = widget.investment.copyWith(
          name: _nameController.text,
          sipAmount: sipAmount,
          sipDay: int.tryParse(_sipDayController.text) ?? 0,
          startDate: _selectedDate,
          purchaseNav: purchaseNav,
          units: units,
          updatedAt: DateTime.now(),
        );

        await Provider.of<InvestmentProvider>(
          context,
          listen: false,
        ).updateInvestment(updatedInvestment);

        if (mounted) {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
          showTopSnackBar(context, 'Investment updated successfully');
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
        title: const Text('Edit Investment'),
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
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.investment.mutualFundSchemeName,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Scheme Code: ${widget.investment.mutualFundSchemeCode}',
                        style: textTheme.bodySmall,
                      ),
                    ],
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
                          'Investment Amount',
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
                        helperText: 'Total money invested in this fund',
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
                              helperText: 'Average NAV at purchase',
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
                      'Monthly recurring investment details',
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
                              if (val == null || val.isEmpty) return null;
                              final day = int.tryParse(val);
                              if (day == null || day < 1 || day > 28)
                                return '1-28';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event, color: Colors.orange),
                      title: const Text('Start Date'),
                      subtitle: Text(
                        DateFormat('dd MMM yyyy').format(_selectedDate),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _selectedDate = date);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Update Investment',
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
