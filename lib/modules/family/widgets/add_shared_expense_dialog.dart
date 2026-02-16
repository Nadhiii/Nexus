import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/providers/shared_expense_provider.dart';
import '../../../core/models/shared_expense.dart';

class AddSharedExpenseDialog extends StatefulWidget {
  const AddSharedExpenseDialog({super.key});

  @override
  State<AddSharedExpenseDialog> createState() => _AddSharedExpenseDialogState();
}

class _AddSharedExpenseDialogState extends State<AddSharedExpenseDialog> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedPayer;
  String _selectedCategory = 'general';
  final Set<String> _selectedParticipants = {};
  bool _splitEqually = true;
  final Map<String, TextEditingController> _splitControllers = {};
  bool _isLoading = false;

  final _categories = [
    {'id': 'general', 'name': 'General', 'icon': Icons.receipt_long},
    {'id': 'food', 'name': 'Food & Dining', 'icon': Icons.restaurant},
    {'id': 'groceries', 'name': 'Groceries', 'icon': Icons.shopping_cart},
    {'id': 'transport', 'name': 'Transport', 'icon': Icons.directions_car},
    {'id': 'utilities', 'name': 'Utilities', 'icon': Icons.lightbulb},
    {'id': 'entertainment', 'name': 'Entertainment', 'icon': Icons.movie},
    {'id': 'shopping', 'name': 'Shopping', 'icon': Icons.shopping_bag},
    {'id': 'travel', 'name': 'Travel', 'icon': Icons.flight},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SharedExpenseProvider>();
      if (provider.familyMembers.isNotEmpty) {
        setState(() {
          _selectedPayer = provider.familyMembers.first.id;
          // Select all members by default
          for (var member in provider.familyMembers) {
            _selectedParticipants.add(member.id);
            _splitControllers[member.id] = TextEditingController();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    for (var controller in _splitControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.backgroundBlack,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildDescriptionField(),
                const SizedBox(height: 20),
                _buildAmountField(),
                const SizedBox(height: 20),
                _buildDateAndCategory(),
                const SizedBox(height: 24),
                _buildPayerSection(),
                const SizedBox(height: 24),
                _buildParticipantsSection(),
                const SizedBox(height: 24),
                _buildSplitSection(),
                const SizedBox(height: 20),
                _buildNotesField(),
                const SizedBox(height: 32),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.group_add,
            color: AppColors.primaryBlue,
            size: 22,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Shared Expense',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Split between family members',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('DESCRIPTION'),
        const SizedBox(height: 8),
        _buildGlassField(
          controller: _descriptionController,
          hint: 'What was this expense for?',
          icon: Icons.description_outlined,
        ),
      ],
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('TOTAL AMOUNT'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
          ),
          child: TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            onChanged: (_) => _updateSplits(),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(
                color: AppColors.textTertiary.withOpacity(0.5),
                fontSize: 20,
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  '₹',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 40),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateAndCategory() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('DATE'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectDate(),
                child: Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd/MM/yyyy').format(_selectedDate),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('CATEGORY'),
              const SizedBox(height: 8),
              Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    dropdownColor: AppColors.cardSurface,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textTertiary,
                    ),
                    items: _categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat['id'] as String,
                        child: Row(
                          children: [
                            Icon(
                              cat['icon'] as IconData,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              cat['name'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedCategory = val!),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPayerSection() {
    return Consumer<SharedExpenseProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('PAID BY'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: provider.familyMembers.map((member) {
                final isSelected = _selectedPayer == member.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPayer = member.id),
                  child: AnimatedContainer(
                    duration: AppAnimations.standard,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryBlue.withOpacity(0.2)
                          : AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryBlue
                            : Colors.white.withOpacity(0.05),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: isSelected
                              ? AppColors.primaryBlue
                              : AppColors.textTertiary.withOpacity(0.3),
                          child: Text(
                            member.name[0].toUpperCase(),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textTertiary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          member.name,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primaryBlue
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildParticipantsSection() {
    return Consumer<SharedExpenseProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLabel('SPLIT BETWEEN'),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedParticipants.length ==
                          provider.familyMembers.length) {
                        _selectedParticipants.clear();
                      } else {
                        _selectedParticipants.clear();
                        for (var m in provider.familyMembers) {
                          _selectedParticipants.add(m.id);
                        }
                      }
                      _updateSplits();
                    });
                  },
                  child: Text(
                    _selectedParticipants.length ==
                            provider.familyMembers.length
                        ? 'Clear All'
                        : 'Select All',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: provider.familyMembers.map((member) {
                final isSelected = _selectedParticipants.contains(member.id);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedParticipants.remove(member.id);
                      } else {
                        _selectedParticipants.add(member.id);
                      }
                      _updateSplits();
                    });
                  },
                  child: AnimatedContainer(
                    duration: AppAnimations.standard,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.success.withOpacity(0.2)
                          : AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.success
                            : Colors.white.withOpacity(0.05),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? AppColors.success
                              : AppColors.textTertiary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          member.name,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSplitSection() {
    final totalAmount = double.tryParse(_amountController.text) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel('SPLIT TYPE'),
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() {
                    _splitEqually = true;
                    _updateSplits();
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _splitEqually
                          ? AppColors.primaryBlue.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Equal',
                      style: TextStyle(
                        color: _splitEqually
                            ? AppColors.primaryBlue
                            : AppColors.textTertiary,
                        fontWeight: _splitEqually
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _splitEqually = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: !_splitEqually
                          ? AppColors.primaryBlue.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Custom',
                      style: TextStyle(
                        color: !_splitEqually
                            ? AppColors.primaryBlue
                            : AppColors.textTertiary,
                        fontWeight: !_splitEqually
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        if (_selectedParticipants.isNotEmpty && totalAmount > 0) ...[
          const SizedBox(height: 12),
          Consumer<SharedExpenseProvider>(
            builder: (context, provider, _) {
              final perPerson = _splitEqually
                  ? totalAmount / _selectedParticipants.length
                  : 0.0;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  children: _selectedParticipants.map((id) {
                    final member = provider.familyMembers.firstWhere(
                      (m) => m.id == id,
                      orElse: () => FamilyMember(id: id, name: 'Unknown'),
                    );

                    if (_splitEqually) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.primaryBlue
                                  .withOpacity(0.2),
                              child: Text(
                                member.name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                member.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            Text(
                              '₹${perPerson.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: id == _selectedPayer
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.primaryBlue
                                  .withOpacity(0.2),
                              child: Text(
                                member.name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                member.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: _splitControllers[id],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  prefixText: '₹',
                                  prefixStyle: TextStyle(
                                    color: AppColors.textTertiary,
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  border: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('NOTES (OPTIONAL)'),
        const SizedBox(height: 8),
        _buildGlassField(
          controller: _notesController,
          hint: 'Add any notes...',
          icon: Icons.note_outlined,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 56,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Add Expense',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.textTertiary,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildGlassField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textTertiary.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: AppColors.textTertiary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  void _updateSplits() {
    if (!_splitEqually) return;

    final totalAmount = double.tryParse(_amountController.text) ?? 0;
    if (totalAmount > 0 && _selectedParticipants.isNotEmpty) {
      final perPerson = totalAmount / _selectedParticipants.length;
      for (var id in _selectedParticipants) {
        _splitControllers[id]?.text = perPerson.toStringAsFixed(0);
      }
    }
    setState(() {});
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _save() async {
    // Validation
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return;
    }

    final totalAmount = double.tryParse(_amountController.text);
    if (totalAmount == null || totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (_selectedPayer == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select who paid')));
      return;
    }

    if (_selectedParticipants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one participant')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<SharedExpenseProvider>();
      final user = FirebaseAuth.instance.currentUser;

      // Build splits
      final List<ExpenseSplit> splits = [];
      final perPerson = _splitEqually
          ? totalAmount / _selectedParticipants.length
          : 0.0;

      for (var id in _selectedParticipants) {
        final member = provider.familyMembers.firstWhere(
          (m) => m.id == id,
          orElse: () => FamilyMember(id: id, name: 'Unknown'),
        );

        final amount = _splitEqually
            ? perPerson
            : double.tryParse(_splitControllers[id]?.text ?? '0') ?? 0;

        splits.add(
          ExpenseSplit(
            personId: id,
            personName: member.name,
            amount: amount,
            isSettled: id == _selectedPayer, // Payer's share is auto-settled
          ),
        );
      }

      final payerMember = provider.familyMembers.firstWhere(
        (m) => m.id == _selectedPayer,
        orElse: () => FamilyMember(id: _selectedPayer!, name: 'Unknown'),
      );

      final expense = SharedExpense(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user?.uid ?? '',
        description: description,
        totalAmount: totalAmount,
        date: _selectedDate,
        paidBy: _selectedPayer!,
        paidByName: payerMember.name,
        splits: splits,
        isSettled: false,
        category: _selectedCategory,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await provider.addSharedExpense(expense);

      if (mounted) {
        Navigator.pop(context);
        // Show option to notify participants
        _showNotifyOption(expense, splits, payerMember.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showNotifyOption(
    SharedExpense expense,
    List<ExpenseSplit> splits,
    String payerName,
  ) {
    // Get people who owe (exclude the payer)
    final owingSplits = splits
        .where((s) => s.personId != expense.paidBy)
        .toList();
    if (owingSplits.isEmpty) return; // No one to notify

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.backgroundBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Expense Added!',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Notify ${owingSplits.length} ${owingSplits.length == 1 ? 'person' : 'people'} about their share?',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              // Show split summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: owingSplits
                      .map(
                        (split) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.error.withOpacity(
                                  0.2,
                                ),
                                child: Text(
                                  split.personName[0].toUpperCase(),
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  split.personName,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              Text(
                                '₹${split.amount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          'Skip',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _shareExpense(expense, owingSplits, payerName);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        icon: const Icon(
                          Icons.share,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text(
                          'Share',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }

  void _shareExpense(
    SharedExpense expense,
    List<ExpenseSplit> owingSplits,
    String payerName,
  ) {
    final dateStr = DateFormat('dd MMM yyyy').format(expense.date);
    final splitDetails = owingSplits
        .map((s) => '• ${s.personName}: ₹${s.amount.toStringAsFixed(0)}')
        .join('\n');

    final message =
        '''💰 Expense Split Notification

$payerName paid ₹${expense.totalAmount.toStringAsFixed(0)} for "${expense.description}" on $dateStr.

Your share:
$splitDetails

Please settle up when you can! 🙏''';

    Share.share(message, subject: 'Expense Split: ${expense.description}');
  }
}
