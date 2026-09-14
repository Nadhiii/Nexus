import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/providers/family_debt_provider.dart';
import '../../../core/models/family_debt.dart';
import '../../../core/models/shared_expense.dart';
import '../../../core/widgets/top_snackbar.dart';
import '../widgets/add_family_debt_sheet.dart';

class AddFamilyDebtModal extends StatefulWidget {
  final FamilyDebt? debtToEdit;

  const AddFamilyDebtModal({super.key, this.debtToEdit});

  static Future<void> show(BuildContext context, {FamilyDebt? debtToEdit}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => AddFamilyDebtModal(debtToEdit: debtToEdit),
    );
  }

  @override
  State<AddFamilyDebtModal> createState() => _AddFamilyDebtModalState();
}

class _AddFamilyDebtModalState extends State<AddFamilyDebtModal> {
  final _formKey = GlobalKey<FormState>();
  final _personNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLent = true; // true = I gave money (They owe me); false = I borrowed
  String? _selectedPersonId;
  DateTime? _dueDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final d = widget.debtToEdit;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (d != null) {
      _amountController.text = d.originalAmount.toStringAsFixed(0);
      _descriptionController.text = d.description ?? '';
      _notesController.text = d.notes ?? '';
      _dueDate = d.dueDate;
      _isLent = (d.creditorId == currentUserId);
      _selectedPersonId = _isLent ? d.debtorId : d.creditorId;
      _personNameController.text = _isLent ? d.debtorName : d.creditorName;
    }
  }

  @override
  void dispose() {
    _personNameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showTopSnackBar(context, 'Please sign in first', isError: true);
      return;
    }

    final personName = _personNameController.text.trim();
    if (personName.isEmpty) {
      showTopSnackBar(context, 'Please enter a person name', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<FamilyDebtProvider>();
      final amount = double.parse(_amountController.text.trim());
      final currentUserId = user.uid;
      final currentUserName = user.displayName?.trim().isNotEmpty == true
          ? user.displayName!
          : 'You';

      // Use the selected ID if tapped, or generate a manual unique id
      final otherPersonId =
          _selectedPersonId ??
          'manual_${personName.toLowerCase().replaceAll(' ', '_')}';

      final debt = FamilyDebt(
        id:
            widget.debtToEdit?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        creatorId: currentUserId,
        creditorId: _isLent ? currentUserId : otherPersonId,
        creditorName: _isLent ? currentUserName : personName,
        debtorId: _isLent ? otherPersonId : currentUserId,
        debtorName: _isLent ? personName : currentUserName,
        originalAmount: amount,
        currentAmount: widget.debtToEdit?.currentAmount ?? amount,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : (_isLent ? 'Lent to $personName' : 'Borrowed from $personName'),
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        createdAt: widget.debtToEdit?.createdAt ?? DateTime.now(),
        dueDate: _dueDate,
        payments: widget.debtToEdit?.payments ?? [],
        isSettled: widget.debtToEdit?.isSettled ?? false,
      );

      await provider.addDebt(debt);

      if (mounted) {
        Navigator.pop(context);
        showTopSnackBar(context, 'Personal balance recorded!');
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
    final color = _isLent ? AppColors.success : AppColors.error;

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
                      'Record Peer Balance / IOU',
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
                const SizedBox(height: AppSpacing.lg),

                // Lent vs Borrowed Direction
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.darkSurfaceElevated,
                    borderRadius: AppSpacing.borderRadiusSm,
                    border: Border.all(color: AppColors.borderSubtleDark),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildDirectionTab('I Lent Money', true)),
                      Expanded(
                        child: _buildDirectionTab('I Borrowed Money', false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                _buildLabel('AMOUNT'),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: AppTypography.currencyMedium.copyWith(color: color),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: AppTypography.currencyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    prefixText: '₹ ',
                    prefixStyle: AppTypography.currencyMedium.copyWith(
                      color: color,
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
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusSm,
                      borderSide: BorderSide(color: color, width: 1.5),
                    ),
                  ),
                  validator: (val) =>
                      (val == null || val.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.lg),

                _buildLabel(
                  _isLent
                      ? 'WHO OWES YOU? (NAME)'
                      : 'WHO DID YOU BORROW FROM? (NAME)',
                ),
                TextFormField(
                  controller: _personNameController,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: _inputDecoration(
                    'Type any name (e.g. Rahul, Sneha)',
                    Icons.person_outline,
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? 'Enter a name'
                      : null,
                  onChanged: (val) {
                    if (_selectedPersonId != null) {
                      setState(() => _selectedPersonId = null);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),

                // Quick Contact Chips (Optional selection)
                Consumer<FamilyDebtProvider>(
                  builder: (context, provider, _) {
                    if (provider.familyMembers.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Or pick a saved contact:',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: provider.familyMembers.map((m) {
                            final isSelected =
                                _personNameController.text.trim() == m.name;
                            return ChoiceChip(
                              label: Text(m.name),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  _personNameController.text = m.name;
                                  _selectedPersonId = m.id;
                                });
                              },
                              selectedColor: color.withValues(alpha: 0.2),
                              backgroundColor: AppColors.darkSurfaceElevated,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? color
                                    : AppColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 11,
                              ),
                              side: BorderSide(
                                color: isSelected
                                    ? color
                                    : AppColors.borderSubtleDark,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                _buildLabel('REASON / DESCRIPTION (OPTIONAL)'),
                TextFormField(
                  controller: _descriptionController,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: _inputDecoration(
                    'e.g. Flight tickets, cash loan',
                    Icons.description_outlined,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                _buildLabel('EXPECTED SETTLEMENT DATE (OPTIONAL)'),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate:
                          _dueDate ??
                          DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(
                        const Duration(days: 365 * 3),
                      ),
                    );
                    if (picked != null) setState(() => _dueDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurfaceElevated,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(color: AppColors.borderSubtleDark),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.event,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _dueDate != null
                              ? DateFormat('d MMM yyyy').format(_dueDate!)
                              : 'Select due date',
                          style: TextStyle(
                            color: _dueDate != null
                                ? Colors.white
                                : AppColors.textTertiary,
                          ),
                        ),
                        const Spacer(),
                        if (_dueDate != null)
                          GestureDetector(
                            onTap: () => setState(() => _dueDate = null),
                            child: const Icon(
                              Icons.clear,
                              size: 16,
                              color: AppColors.textTertiary,
                            ),
                          ),
                      ],
                    ),
                  ),
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
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          backgroundColor: color,
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
                                'Record Balance',
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

  Widget _buildDirectionTab(String label, bool isLent) {
    final isSelected = _isLent == isLent;
    final color = isLent ? AppColors.success : AppColors.error;
    return GestureDetector(
      onTap: () => setState(() => _isLent = isLent),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: AppSpacing.borderRadiusSm,
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isSelected ? color : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
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
        borderSide: BorderSide(color: AppColors.primaryBlue, width: 1.5),
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
