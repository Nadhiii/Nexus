import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/providers/debt_provider.dart';
import '../../core/models/debt.dart';

class AddDebtScreen extends StatefulWidget {
  final Debt? debtToEdit;
  final bool isModal;
  final VoidCallback? onDismiss;

  const AddDebtScreen({
    super.key,
    this.debtToEdit,
    this.isModal = false,
    this.onDismiss,
  });

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lenderController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _monthlyEMIController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _totalTenureController = TextEditingController();
  final _monthsPaidController = TextEditingController();
  final _notesController = TextEditingController();

  DebtType _selectedType = DebtType.personalLoan;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _nextDueDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _lenderController.dispose();
    _totalAmountController.dispose();
    _monthlyEMIController.dispose();
    _interestRateController.dispose();
    _totalTenureController.dispose();
    _monthsPaidController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.debtToEdit == null ? 'Add Debt' : 'Edit Debt',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
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
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveDebt,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            _buildBasicInfoSection(),
            const SizedBox(height: 28),
            _buildAmountSection(),
            const SizedBox(height: 28),
            _buildPaymentSection(),
            const SizedBox(height: 28),
            _buildNotesSection(),
            const SizedBox(height: 28),
            _buildHelpSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Basic Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Debt Name',
                hintText: 'e.g., Home Loan, Car Loan, Personal Loan',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a debt name';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lenderController,
              decoration: const InputDecoration(
                labelText: 'Lender Name',
                hintText: 'e.g., SBI, HDFC Bank, ICICI Bank',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the lender name';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<DebtType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Debt Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: DebtType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(_getDebtTypeIcon(type), size: 20),
                      const SizedBox(width: 8),
                      Text(_getDebtTypeDisplayName(type)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Amount Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _totalAmountController,
              decoration: const InputDecoration(
                labelText: 'Total Loan Amount',
                hintText: '₹ 0',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the total loan amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _monthlyEMIController,
              decoration: const InputDecoration(
                labelText: 'Monthly EMI',
                hintText: '₹ 0',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payment),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the monthly EMI amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid EMI amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _interestRateController,
              decoration: const InputDecoration(
                labelText: 'Interest Rate (% per year)',
                hintText: 'e.g., 8.5',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.percent),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the interest rate';
                }
                final rate = double.tryParse(value);
                if (rate == null || rate < 0 || rate > 50) {
                  return 'Please enter a valid interest rate (0-50)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _totalTenureController,
                    decoration: const InputDecoration(
                      labelText: 'Total Tenure (Months)',
                      hintText: 'e.g., 240',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_month),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter tenure';
                      }
                      final months = int.tryParse(value);
                      if (months == null || months <= 0 || months > 600) {
                        return 'Please enter valid tenure (1-600 months)';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _monthsPaidController,
                    decoration: const InputDecoration(
                      labelText: 'Months Paid',
                      hintText: 'e.g., 24',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.check_circle_outline),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter months paid';
                      }
                      final months = int.tryParse(value);
                      if (months == null || months < 0) {
                        return 'Please enter valid months';
                      }
                      final totalTenure = int.tryParse(
                        _totalTenureController.text,
                      );
                      if (totalTenure != null && months > totalTenure) {
                        return 'Cannot exceed total tenure';
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
    );
  }

  Widget _buildPaymentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.date_range_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Loan Dates',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectStartDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Loan Start Date *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _startDate == null
                            ? 'Select date'
                            : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                        style: _startDate == null
                            ? TextStyle(color: Colors.grey.shade600)
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _selectEndDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Loan End Date *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.event),
                      ),
                      child: Text(
                        _endDate == null
                            ? 'Select date'
                            : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                        style: _endDate == null
                            ? TextStyle(color: Colors.grey.shade600)
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectNextDueDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Next EMI Due Date (Optional)',
                  helperText: 'Set this to receive payment reminders',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notification_important),
                ),
                child: Text(
                  _nextDueDate == null
                      ? 'Select date for notifications'
                      : '${_nextDueDate!.day}/${_nextDueDate!.month}/${_nextDueDate!.year}',
                  style: _nextDueDate == null
                      ? TextStyle(color: Colors.grey.shade600)
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.note_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Additional Notes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Any additional information about this loan...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit_note),
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSection() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Tips',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '• Enter the original total loan amount you borrowed\n'
              '• Monthly EMI is the fixed amount you pay every month\n'
              '• Interest rate should be the annual rate from your loan agreement\n'
              '• Tenure is the total number of months for loan repayment\n'
              '• Months paid helps track your current progress\n'
              '• Accurate dates help with payment scheduling and tracking\n'
              '• Set next due date to receive payment reminder notifications',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDebtTypeIcon(DebtType type) {
    switch (type) {
      case DebtType.creditCard:
        return Icons.credit_card;
      case DebtType.personalLoan:
        return Icons.person;
      case DebtType.homeLoan:
        return Icons.home;
      case DebtType.carLoan:
        return Icons.directions_car;
      case DebtType.educationLoan:
        return Icons.school;
      case DebtType.businessLoan:
        return Icons.business;
      case DebtType.goldLoan:
        return Icons.star;
      case DebtType.other:
        return Icons.account_balance;
    }
  }

  String _getDebtTypeDisplayName(DebtType type) {
    switch (type) {
      case DebtType.creditCard:
        return 'Credit Card';
      case DebtType.personalLoan:
        return 'Personal Loan';
      case DebtType.homeLoan:
        return 'Home Loan';
      case DebtType.carLoan:
        return 'Car Loan';
      case DebtType.educationLoan:
        return 'Education Loan';
      case DebtType.businessLoan:
        return 'Business Loan';
      case DebtType.goldLoan:
        return 'Gold Loan';
      case DebtType.other:
        return 'Other Debt';
    }
  }

  Color _getDebtTypeColor(DebtType type) {
    switch (type) {
      case DebtType.creditCard:
        return Colors.red;
      case DebtType.personalLoan:
        return Colors.blue;
      case DebtType.homeLoan:
        return Colors.green;
      case DebtType.carLoan:
        return Colors.purple;
      case DebtType.educationLoan:
        return Colors.orange;
      case DebtType.businessLoan:
        return Colors.teal;
      case DebtType.goldLoan:
        return Colors.amber;
      case DebtType.other:
        return Colors.grey;
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Auto-calculate end date based on tenure if both values are available
        if (_totalTenureController.text.isNotEmpty) {
          final tenure = int.tryParse(_totalTenureController.text);
          if (tenure != null) {
            _endDate = DateTime(picked.year, picked.month + tenure, picked.day);
          }
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _endDate ??
          (_startDate?.add(const Duration(days: 365)) ??
              DateTime.now().add(const Duration(days: 365))),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 30)),
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _selectNextDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _nextDueDate = picked;
      });
    }
  }

  Future<void> _saveDebt() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate required dates
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select loan start date')),
      );
      return;
    }

    if (_endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select loan end date')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final debt = Debt(
        id: '', // Will be set by Firestore
        name: _nameController.text.trim(),
        type: _selectedType,
        originalAmount: double.parse(_totalAmountController.text),
        currentBalance:
            double.parse(_totalAmountController.text) -
            (double.parse(_monthlyEMIController.text) *
                int.parse(_monthsPaidController.text)),
        interestRate: double.parse(_interestRateController.text),
        monthlyEMI: double.parse(_monthlyEMIController.text),
        totalTenureMonths: int.parse(_totalTenureController.text),
        monthsPaid: int.parse(_monthsPaidController.text),
        startDate: _startDate!,
        endDate: _endDate!,
        nextDueDate: _nextDueDate,
        color: _getDebtTypeColor(_selectedType),
        icon: _getDebtTypeIcon(_selectedType),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lenderName: _lenderController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      await context.read<DebtProvider>().createDebt(debt);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${debt.name} added successfully'),
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
            content: Text('Error adding debt: $e'),
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
