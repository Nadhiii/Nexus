import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/providers/shared_expense_provider.dart';
import '../../../core/models/shared_expense.dart';
import '../../../core/widgets/top_snackbar.dart';
import 'add_family_member.dart';

class ModernAddSharedExpenseScreen extends StatefulWidget {
  final SharedExpense? expense;

  const ModernAddSharedExpenseScreen({super.key, this.expense});

  static Future<void> show(BuildContext context, {SharedExpense? expense}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => ModernAddSharedExpenseScreen(expense: expense),
    );
  }

  @override
  State<ModernAddSharedExpenseScreen> createState() =>
      _ModernAddSharedExpenseScreenState();
}

class _ModernAddSharedExpenseScreenState
    extends State<ModernAddSharedExpenseScreen> {
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SharedExpenseProvider>();
      final existing = widget.expense;
      if (existing != null) {
        _descriptionController.text = existing.description;
        _amountController.text = existing.totalAmount.toStringAsFixed(0);
        _notesController.text = existing.notes ?? '';
        _selectedDate = existing.date;
        _selectedPayer = existing.paidBy;
        _selectedCategory = existing.category ?? 'general';
        _splitEqually = false;
        for (final split in existing.splits) {
          _selectedParticipants.add(split.personId);
          _splitControllers[split.personId] = TextEditingController(
            text: split.amount.toStringAsFixed(0),
          );
        }
      } else if (provider.familyMembers.isNotEmpty) {
        _selectedPayer = provider.familyMembers.first.id;
        for (var member in provider.familyMembers) {
          _selectedParticipants.add(member.id);
          _splitControllers[member.id] = TextEditingController();
        }
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    for (var c in _splitControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _updateSplits() {
    if (!_splitEqually) return;
    final total = double.tryParse(_amountController.text.trim()) ?? 0;
    if (total > 0 && _selectedParticipants.isNotEmpty) {
      final perPerson = total / _selectedParticipants.length;
      for (var id in _selectedParticipants) {
        _splitControllers.putIfAbsent(id, () => TextEditingController());
        _splitControllers[id]?.text = perPerson.toStringAsFixed(0);
      }
    }
    setState(() {});
  }

  Future<void> _openAddNewMember() async {
    final newMember = await ModernAddFamilyMemberScreen.show(context);
    if (newMember != null && mounted) {
      setState(() {
        _selectedParticipants.add(newMember.id);
        _splitControllers[newMember.id] = TextEditingController();
        _selectedPayer ??= newMember.id;
        _updateSplits();
      });
    }
  }

  void _save() async {
    final desc = _descriptionController.text.trim();
    if (desc.isEmpty) {
      showTopSnackBar(context, 'Please enter a description', isError: true);
      return;
    }

    final total = double.tryParse(_amountController.text.trim());
    if (total == null || total <= 0) {
      showTopSnackBar(context, 'Please enter a valid amount', isError: true);
      return;
    }

    if (_selectedPayer == null || _selectedParticipants.isEmpty) {
      showTopSnackBar(
        context,
        'Select who paid and who participates',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<SharedExpenseProvider>();
      final user = FirebaseAuth.instance.currentUser;
      final perPerson = total / _selectedParticipants.length;

      final List<ExpenseSplit> splits = [];
      for (var id in _selectedParticipants) {
        final member = provider.familyMembers.firstWhere(
          (m) => m.id == id,
          orElse: () => FamilyMember(id: id, name: 'Unknown'),
        );
        final amt = _splitEqually
            ? perPerson
            : double.tryParse(_splitControllers[id]?.text ?? '0') ?? 0;
        splits.add(
          ExpenseSplit(
            personId: id,
            personName: member.name,
            amount: amt,
            isSettled: id == _selectedPayer,
          ),
        );
      }

      final payerMember = provider.familyMembers.firstWhere(
        (m) => m.id == _selectedPayer,
        orElse: () => FamilyMember(id: _selectedPayer!, name: 'Unknown'),
      );

      final expense = SharedExpense(
        id:
            widget.expense?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user?.uid ?? '',
        description: desc,
        totalAmount: total,
        date: _selectedDate,
        paidBy: _selectedPayer!,
        paidByName: payerMember.name,
        splits: splits,
        isSettled: false,
        category: _selectedCategory,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        createdAt: widget.expense?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.expense == null) {
        await provider.addSharedExpense(expense);
      } else {
        await provider.updateSharedExpense(expense);
      }

      if (mounted) {
        Navigator.pop(context);
        showTopSnackBar(context, 'Shared expense saved!');
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
    final isEditing = widget.expense != null;

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
                    isEditing ? 'Edit Shared Expense' : 'New Shared Expense',
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

              _buildLabel('TOTAL AMOUNT'),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => _updateSplits(),
                style: AppTypography.currencyMedium.copyWith(
                  color: AppColors.primaryBlue,
                ),
                decoration: InputDecoration(
                  hintText: "0.00",
                  hintStyle: AppTypography.currencyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  prefixText: "₹ ",
                  prefixStyle: AppTypography.currencyMedium.copyWith(
                    color: AppColors.primaryBlue,
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
                      color: AppColors.primaryBlue,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              _buildLabel('DESCRIPTION'),
              TextFormField(
                controller: _descriptionController,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: "e.g. Dinner, Rent, Groceries",
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  filled: true,
                  fillColor: AppColors.darkSurfaceElevated,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(
                      left: AppSpacing.md,
                      right: AppSpacing.sm,
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
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
                      color: AppColors.primaryBlue,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Payer & Participant Selection
              Consumer<SharedExpenseProvider>(
                builder: (context, provider, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildLabel('PAID BY'),
                          TextButton.icon(
                            onPressed: _openAddNewMember,
                            icon: const Icon(Icons.person_add_alt_1, size: 16),
                            label: const Text(
                              'Add Member',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryBlue,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: 4,
                        children: [
                          ...provider.familyMembers.map((m) {
                            final isSelected = _selectedPayer == m.id;
                            return ChoiceChip(
                              label: Text(m.name),
                              selected: isSelected,
                              onSelected: (_) =>
                                  setState(() => _selectedPayer = m.id),
                              selectedColor: AppColors.primaryBlue.withValues(
                                alpha: 0.2,
                              ),
                              backgroundColor: AppColors.darkSurfaceElevated,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : AppColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : AppColors.borderSubtleDark,
                              ),
                            );
                          }),
                          ActionChip(
                            avatar: const Icon(
                              Icons.add,
                              size: 16,
                              color: AppColors.primaryBlue,
                            ),
                            label: const Text(
                              'New',
                              style: TextStyle(color: AppColors.primaryBlue),
                            ),
                            backgroundColor: AppColors.darkSurfaceElevated,
                            side: const BorderSide(
                              color: AppColors.primaryBlue,
                              style: BorderStyle.solid,
                            ),
                            onPressed: _openAddNewMember,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      _buildLabel('PARTICIPANTS'),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: 4,
                        children: [
                          ...provider.familyMembers.map((m) {
                            final isSelected = _selectedParticipants.contains(
                              m.id,
                            );
                            return FilterChip(
                              label: Text(m.name),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedParticipants.add(m.id);
                                  } else {
                                    _selectedParticipants.remove(m.id);
                                  }
                                  _updateSplits();
                                });
                              },
                              selectedColor: AppColors.success.withValues(
                                alpha: 0.2,
                              ),
                              backgroundColor: AppColors.darkSurfaceElevated,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.success
                                    : AppColors.borderSubtleDark,
                              ),
                            );
                          }),
                          ActionChip(
                            avatar: const Icon(
                              Icons.add,
                              size: 16,
                              color: AppColors.success,
                            ),
                            label: const Text(
                              'New',
                              style: TextStyle(color: AppColors.success),
                            ),
                            backgroundColor: AppColors.darkSurfaceElevated,
                            side: const BorderSide(
                              color: AppColors.success,
                              style: BorderStyle.solid,
                            ),
                            onPressed: _openAddNewMember,
                          ),
                        ],
                      ),
                    ],
                  );
                },
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
                      onPressed: _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.lg,
                        ),
                        backgroundColor: AppColors.primaryBlue,
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
                              'Save Expense',
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
}

Future<void> navToAddSharedExpenseScreen(BuildContext context) {
  return ModernAddSharedExpenseScreen.show(context);
}
