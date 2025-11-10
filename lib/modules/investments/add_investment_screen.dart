import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/investment_provider.dart';
import '../../core/models/investment.dart';

class AddInvestmentScreen extends StatefulWidget {
  final Investment? investmentToEdit;
  final bool isModal;
  final VoidCallback? onDismiss;

  const AddInvestmentScreen({
    super.key,
    this.investmentToEdit,
    this.isModal = false,
    this.onDismiss,
  });

  @override
  State<AddInvestmentScreen> createState() => _AddInvestmentScreenState();
}

class _AddInvestmentScreenState extends State<AddInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _symbolController = TextEditingController();
  final _unitsController = TextEditingController();
  final _priceController = TextEditingController();
  final _platformController = TextEditingController();

  InvestmentType _selectedType = InvestmentType.stock;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _symbolController.dispose();
    _unitsController.dispose();
    _priceController.dispose();
    _platformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.isModal) {
      // Modal version without Scaffold
      return Material(
        color: Colors.transparent,
        child: Column(
          children: [
            // Fixed header for modal
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  // Custom close button
                  Material(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(22),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () {
                        if (widget.onDismiss != null) {
                          widget.onDismiss!();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: const Icon(
                          Icons.close,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title
                  Expanded(
                    child: Text(
                      widget.investmentToEdit == null ? 'Add Investment' : 'Edit Investment',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Scrollable content
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    children: _buildFormContent(theme),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Full screen version with Scaffold
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.investmentToEdit == null ? 'Add Investment' : 'Edit Investment',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        leading: Container(
          margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: Material(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                if (widget.isModal && widget.onDismiss != null) {
                  widget.onDismiss!();
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                child: const Icon(
                  Icons.close,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: _buildFormContent(theme),
        ),
      ),
    );
  }

  List<Widget> _buildFormContent(ThemeData theme) {
    return [
            // Investment Type Selection
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Investment Type',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: InvestmentType.values.map((type) {
                        final isSelected = _selectedType == type;
                        return FilterChip(
                          label: Text(_getInvestmentTypeLabel(type)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedType = type;
                            });
                          },
                          backgroundColor: theme.colorScheme.surface,
                          selectedColor: theme.colorScheme.primaryContainer,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Investment Details Form
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Investment Details',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Investment Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Investment Name',
                        hintText: _getNameHint(_selectedType),
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(_getInvestmentTypeIcon(_selectedType)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter investment name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Symbol/Code
                    TextFormField(
                      controller: _symbolController,
                      decoration: InputDecoration(
                        labelText: _getSymbolLabel(_selectedType),
                        hintText: _getSymbolHint(_selectedType),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.tag),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter ${_getSymbolLabel(_selectedType).toLowerCase()}';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        // Units/Shares
                        Expanded(
                          child: TextFormField(
                            controller: _unitsController,
                            decoration: InputDecoration(
                              labelText: _getUnitsLabel(_selectedType),
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.numbers),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              final number = double.tryParse(value);
                              if (number == null || number <= 0) {
                                return 'Invalid amount';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Price per unit
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(
                              labelText: 'Price per Unit (₹)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.currency_rupee),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              final number = double.tryParse(value);
                              if (number == null || number <= 0) {
                                return 'Invalid price';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Total Investment Display
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(
                          0.3,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Investment:',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _calculateTotalInvestment(),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Investment Platform/Broker
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Where is it invested?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _platformController,
                      decoration: InputDecoration(
                        labelText: 'Platform/Broker',
                        hintText: 'e.g., Zerodha, Groww, Upstox, HDFC Securities',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.business),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the platform/broker name';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Add Investment Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _addInvestment,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add Investment'),
              ),
            ),
        ];
      }

  String _calculateTotalInvestment() {
    final units = double.tryParse(_unitsController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    final total = units * price;
    return '₹${total.toStringAsFixed(2)}';
  }

  String _getInvestmentTypeLabel(InvestmentType type) {
    switch (type) {
      case InvestmentType.stock:
        return 'Stock';
      case InvestmentType.mutualFund:
        return 'Mutual Fund';
      case InvestmentType.etf:
        return 'ETF';
      case InvestmentType.bond:
        return 'Bond';
      case InvestmentType.crypto:
        return 'Crypto';
      case InvestmentType.commodity:
        return 'Commodity';
      case InvestmentType.reit:
        return 'REIT';
      case InvestmentType.other:
        return 'Other';
    }
  }

  IconData _getInvestmentTypeIcon(InvestmentType type) {
    switch (type) {
      case InvestmentType.stock:
        return Icons.trending_up;
      case InvestmentType.mutualFund:
        return Icons.account_balance;
      case InvestmentType.etf:
        return Icons.pie_chart;
      case InvestmentType.bond:
        return Icons.receipt_long;
      case InvestmentType.crypto:
        return Icons.currency_bitcoin;
      case InvestmentType.commodity:
        return Icons.agriculture;
      case InvestmentType.reit:
        return Icons.apartment;
      case InvestmentType.other:
        return Icons.category;
    }
  }

  String _getNameHint(InvestmentType type) {
    switch (type) {
      case InvestmentType.stock:
        return 'e.g., Apple Inc., HDFC Bank';
      case InvestmentType.mutualFund:
        return 'e.g., HDFC Equity Fund';
      case InvestmentType.etf:
        return 'e.g., Nifty 50 ETF';
      case InvestmentType.bond:
        return 'e.g., Government Bond';
      case InvestmentType.crypto:
        return 'e.g., Bitcoin, Ethereum';
      case InvestmentType.commodity:
        return 'e.g., Gold, Silver';
      case InvestmentType.reit:
        return 'e.g., Embassy REIT';
      case InvestmentType.other:
        return 'Enter investment name';
    }
  }

  String _getSymbolLabel(InvestmentType type) {
    switch (type) {
      case InvestmentType.stock:
        return 'Stock Symbol';
      case InvestmentType.mutualFund:
        return 'Fund Code';
      case InvestmentType.etf:
        return 'ETF Symbol';
      case InvestmentType.bond:
        return 'Bond Code';
      case InvestmentType.crypto:
        return 'Crypto Symbol';
      case InvestmentType.commodity:
        return 'Commodity Code';
      case InvestmentType.reit:
        return 'REIT Symbol';
      case InvestmentType.other:
        return 'Symbol/Code';
    }
  }

  String _getSymbolHint(InvestmentType type) {
    switch (type) {
      case InvestmentType.stock:
        return 'e.g., AAPL, HDFCBANK';
      case InvestmentType.mutualFund:
        return 'e.g., 120716';
      case InvestmentType.etf:
        return 'e.g., NIFTYBEES';
      case InvestmentType.bond:
        return 'e.g., GOI2030';
      case InvestmentType.crypto:
        return 'e.g., BTC, ETH';
      case InvestmentType.commodity:
        return 'e.g., GOLD, SILVER';
      case InvestmentType.reit:
        return 'e.g., EMBASSYOFC';
      case InvestmentType.other:
        return 'Enter symbol';
    }
  }

  String _getUnitsLabel(InvestmentType type) {
    switch (type) {
      case InvestmentType.stock:
        return 'Shares';
      case InvestmentType.mutualFund:
        return 'Units';
      case InvestmentType.etf:
        return 'Units';
      case InvestmentType.bond:
        return 'Units';
      case InvestmentType.crypto:
        return 'Coins';
      case InvestmentType.commodity:
        return 'Quantity';
      case InvestmentType.reit:
        return 'Units';
      case InvestmentType.other:
        return 'Units';
    }
  }

  Future<void> _addInvestment() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final units = double.parse(_unitsController.text);
      final price = double.parse(_priceController.text);
      final totalInvested = units * price;
      final now = DateTime.now();

      final investment = Investment(
        id: '', // Will be set by Firestore
        name: _nameController.text.trim(),
        symbol: _symbolController.text.trim().toUpperCase(),
        type: _selectedType,
        accountId: 'investment_portfolio', // Dummy account ID for investments
        units: units,
        averagePrice: price,
        currentPrice: price, // Initially same as purchase price
        totalInvested: totalInvested,
        currentValue: totalInvested, // Initially same as invested
        currency: '₹',
        lastUpdated: now,
        createdAt: now,
        updatedAt: now,
        metadata: {
          'platform': _platformController.text.trim(),
        },
      );

      final investmentProvider = Provider.of<InvestmentProvider>(
        context,
        listen: false,
      );
      await investmentProvider.addInvestment(investment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Investment added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        if (widget.isModal && widget.onDismiss != null) {
          widget.onDismiss!();
        } else {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add investment: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
