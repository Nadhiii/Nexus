import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/debt.dart';
import '../../core/providers/debt_provider.dart';
import '../../core/services/debt_service.dart';

class AddDebtScreen extends StatefulWidget {
  final Debt? debtToEdit;

  const AddDebtScreen({Key? key, this.debtToEdit}) : super(key: key);

  @override
  _AddDebtScreenState createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for all fields
  late TextEditingController _nameController;
  late TextEditingController _lenderNameController;
  late TextEditingController _originalAmountController;
  late TextEditingController _currentBalanceController;
  late TextEditingController _monthlyEMIController;
  late TextEditingController _interestRateController;
  late TextEditingController _totalTenureController;
  late TextEditingController _accountNumberController;
  late TextEditingController _notesController;

  // Selected values
  DebtType _selectedType = DebtType.other;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 365 * 5));
  late Color _selectedColor;
  late IconData _selectedIcon;

  bool get _isSimpleDebt =>
      _selectedType == DebtType.owedByMe || _selectedType == DebtType.owedToMe;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _selectedColor = DebtService.getDefaultColor(_selectedType);
    _selectedIcon = DebtService.getDefaultIcon(_selectedType);
    if (widget.debtToEdit != null) {
      _populateFieldsForEditing(widget.debtToEdit!);
    }
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _lenderNameController = TextEditingController();
    _originalAmountController = TextEditingController();
    _currentBalanceController = TextEditingController();
    _monthlyEMIController = TextEditingController();
    _interestRateController = TextEditingController();
    _totalTenureController = TextEditingController();
    _accountNumberController = TextEditingController();
    _notesController = TextEditingController();
  }

  void _populateFieldsForEditing(Debt debt) {
    _nameController.text = debt.name;
    _selectedType = debt.type;
    _originalAmountController.text = debt.originalAmount.toString();
    _currentBalanceController.text = debt.currentBalance.toString();
    _monthlyEMIController.text = debt.monthlyEMI?.toString() ?? '';
    _interestRateController.text = debt.interestRate?.toString() ?? '';
    _totalTenureController.text = debt.totalTenureMonths?.toString() ?? '';
    _lenderNameController.text = debt.lenderName ?? '';
    _accountNumberController.text = debt.accountNumber ?? '';
    _notesController.text = debt.notes ?? '';
    _startDate = debt.startDate ?? DateTime.now();
    _endDate =
        debt.endDate ?? DateTime.now().add(const Duration(days: 365 * 5));
    _selectedColor = DebtService.getDefaultColor(debt.type);
    _selectedIcon = DebtService.getDefaultIcon(debt.type);
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _nameController.dispose();
    _lenderNameController.dispose();
    _originalAmountController.dispose();
    _currentBalanceController.dispose();
    _monthlyEMIController.dispose();
    _interestRateController.dispose();
    _totalTenureController.dispose();
    _accountNumberController.dispose();
    _notesController.dispose();
  }

  void _onTypeChanged(DebtType? type) {
    if (type == null) return;
    setState(() {
      _selectedType = type;
      _selectedColor = DebtService.getDefaultColor(type);
      _selectedIcon = DebtService.getDefaultIcon(type);
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != (isStartDate ? _startDate : _endDate)) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _saveForm() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final debtProvider = Provider.of<DebtProvider>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final newDebt = Debt(
      id: widget.debtToEdit?.id ?? ' ', // Service will handle creation
      userId: user.uid,
      name: _nameController.text,
      type: _selectedType,
      originalAmount: double.tryParse(_originalAmountController.text) ?? 0.0,
      currentBalance: double.tryParse(_currentBalanceController.text) ?? 0.0,
      monthlyEMI: double.tryParse(_monthlyEMIController.text),
      interestRate: double.tryParse(_interestRateController.text),
      totalTenureMonths: int.tryParse(_totalTenureController.text),
      monthsPaid: 0, // Should be calculated or tracked separately
      lenderName: _lenderNameController.text,
      accountNumber: _accountNumberController.text,
      notes: _notesController.text,
      startDate: _startDate,
      endDate: _endDate,
      createdAt: widget.debtToEdit?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      color: _selectedColor,
      icon: _selectedIcon,
    );

    if (widget.debtToEdit != null) {
      debtProvider.updateDebt(newDebt);
    } else {
      debtProvider.addDebt(newDebt);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.debtToEdit == null ? 'Add Debt' : 'Edit Debt'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveForm),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, 'Debt Information'),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Debt Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              _buildDebtTypeDropdown(context),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lenderNameController,
                decoration: InputDecoration(
                  labelText: _isSimpleDebt ? 'Person\'s Name' : 'Lender Name',
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle(context, 'Amount & Terms'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _originalAmountController,
                      decoration: const InputDecoration(
                        labelText: 'Original Amount',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter an amount' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _currentBalanceController,
                      decoration: const InputDecoration(
                        labelText: 'Current Balance',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a balance' : null,
                    ),
                  ),
                ],
              ),
              if (!_isSimpleDebt) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _monthlyEMIController,
                        decoration: const InputDecoration(
                          labelText: 'Monthly EMI',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _interestRateController,
                        decoration: const InputDecoration(
                          labelText: 'Interest Rate (%)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _totalTenureController,
                  decoration: const InputDecoration(
                    labelText: 'Total Tenure (Months)',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
              const SizedBox(height: 16),
              _buildSectionTitle(context, 'Dates'),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                        ),
                        child: Text(
                          DateFormat.yMMMd().format(_startDate),
                          style: TextStyle(
                            color: _startDate == DateTime.now()
                                ? colorScheme.onSurface.withOpacity(0.6)
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                        ),
                        child: Text(
                          DateFormat.yMMMd().format(_endDate),
                          style: TextStyle(
                            color:
                                _endDate ==
                                    DateTime.now().add(
                                      const Duration(days: 365 * 5),
                                    )
                                ? colorScheme.onSurface.withOpacity(0.6)
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionTitle(context, 'Additional Details'),
              TextFormField(
                controller: _accountNumberController,
                decoration: const InputDecoration(labelText: 'Account Number'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _saveForm,
                  child: const Text('Save Debt'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDebtTypeDropdown(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DropdownButtonFormField<DebtType>(
      value: _selectedType,
      onChanged: _onTypeChanged,
      decoration: InputDecoration(
        labelText: 'Debt Type',
        filled: true,
        fillColor: colorScheme.surface,
      ),
      items: DebtType.values.map((DebtType type) {
        return DropdownMenuItem<DebtType>(
          value: type,
          child: Row(
            children: [
              Icon(
                DebtService.getDefaultIcon(type),
                color: DebtService.getDefaultColor(type),
              ),
              const SizedBox(width: 12),
              Text(DebtService.getDebtTypeDisplayName(type)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
