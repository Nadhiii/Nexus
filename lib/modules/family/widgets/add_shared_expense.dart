import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/providers/shared_expense_provider.dart';
import '../../../core/models/shared_expense.dart';
import '../../../core/widgets/top_snackbar.dart';
import '../../../core/utils/currency_formatter.dart';

class ModernAddSharedExpenseScreen extends StatefulWidget {
  final SharedExpense? expense;

  const ModernAddSharedExpenseScreen({super.key, this.expense});

  @override
  State<ModernAddSharedExpenseScreen> createState() =>
      _ModernAddSharedExpenseScreenState();
}

class _ModernAddSharedExpenseScreenState
    extends State<ModernAddSharedExpenseScreen> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _quickPersonController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedPayer;
  String _selectedCategory = 'general';
  final Set<String> _selectedParticipants = {};
  bool _splitEqually = true;
  final Map<String, TextEditingController> _splitControllers = {};
  bool _isLoading = false;
  bool _isAddingQuickPerson = false;

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
      final existing = widget.expense;
      if (existing != null) {
        _descriptionController.text = existing.description;
        _amountController.text = existing.totalAmount.toStringAsFixed(2);
        _notesController.text = existing.notes ?? '';
        _selectedDate = existing.date;
        _selectedPayer = existing.paidBy;
        _selectedCategory = existing.category ?? 'general';
        _splitEqually = false;
        for (final split in existing.splits) {
          _selectedParticipants.add(split.personId);
          _splitControllers[split.personId] = TextEditingController(
            text: split.amount.toStringAsFixed(2),
          );
        }
        setState(() {});
      } else if (provider.familyMembers.isNotEmpty) {
        setState(() {
          _selectedPayer = provider.familyMembers.first.id;
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
    _quickPersonController.dispose();
    for (var controller in _splitControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkGradient.first,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120.0,
            backgroundColor: AppColors.darkGradient.first,
            foregroundColor: AppColors.white,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                widget.expense == null ? 'Shared Expense' : 'Edit Expense',
                style: AppTypography.headlineMedium,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TOTAL AMOUNT (Massive)
                  Text(
                    'Total Amount',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _amountController,
                    autofocus: true,
                    style: AppTypography.displayMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    onChanged: (_) => _updateSplits(),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      prefixText: '₹ ',
                      prefixStyle: AppTypography.displayMedium.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                      hintStyle: TextStyle(color: AppColors.textTertiary),
                      filled: true,
                      fillColor: AppColors.cardElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildEachPersonSummaryCard(),
                  const SizedBox(height: AppSpacing.xl2),

                  // DESCRIPTION
                  Text(
                    'Description',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildGlassField(
                    controller: _descriptionController,
                    hint: 'e.g. Dinner at Absolute Barbecue',
                    icon: Icons.description_outlined,
                  ),
                  const SizedBox(height: AppSpacing.xl2),

                  // DATE & CATEGORY
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date',
                              style: AppTypography.titleSmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            GestureDetector(
                              onTap: _selectDate,
                              child: Container(
                                height: 56,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.cardElevated,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 20,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      DateFormat(
                                        'dd MMM yyyy',
                                      ).format(_selectedDate),
                                      style: AppTypography.bodyLarge.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Category',
                              style: AppTypography.titleSmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Container(
                              height: 56,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cardElevated,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedCategory,
                                  isExpanded: true,
                                  dropdownColor: AppColors.cardElevated,
                                  icon: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: AppColors.textSecondary,
                                  ),
                                  items: _categories.map((cat) {
                                    return DropdownMenuItem<String>(
                                      value: cat['id'] as String,
                                      child: Row(
                                        children: [
                                          Icon(
                                            cat['icon'] as IconData,
                                            size: 20,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          Text(
                                            cat['name'] as String,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
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
                  ),
                  const SizedBox(height: AppSpacing.xl2),

                  // PAYER
                  _buildPayerSection(),
                  const SizedBox(height: AppSpacing.xl2),

                  // PARTICIPANTS & SPLITS
                  _buildParticipantsSection(),
                  const SizedBox(height: AppSpacing.xl2),
                  _buildSplitSection(),
                  const SizedBox(height: AppSpacing.xl2),

                  // NOTES
                  Text(
                    'Notes (Optional)',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildGlassField(
                    controller: _notesController,
                    hint: 'Add any extra details...',
                    icon: Icons.note_outlined,
                  ),
                  const SizedBox(height: AppSpacing.xl2),

                  // SUBMIT
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.lg,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : Text(
                              'Save Expense',
                              style: AppTypography.titleSmall.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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
        prefixIcon: Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.sm,
          ),
          child: Icon(icon, color: AppColors.textSecondary, size: 20),
        ),
      ),
    );
  }

  Widget _buildPayerSection() {
    return Consumer<SharedExpenseProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paid By',
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: provider.familyMembers.map((member) {
                final isSelected = _selectedPayer == member.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPayer = member.id),
                  child: AnimatedContainer(
                    duration: AppAnimations.standard,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryBlue.withValues(alpha: 0.2)
                          : AppColors.cardElevated,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryBlue
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: isSelected
                              ? AppColors.primaryBlue
                              : AppColors.textTertiary.withValues(alpha: 0.3),
                          child: Text(
                            member.name.isNotEmpty
                                ? member.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textTertiary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
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
                Text(
                  'Split Between',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                    style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quickPersonController,
                    textCapitalization: TextCapitalization.words,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add person manually (e.g. Arun)',
                      hintStyle: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      filled: true,
                      fillColor: AppColors.cardElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide: BorderSide.none,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _isAddingQuickPerson
                        ? null
                        : () => _addQuickParticipant(provider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    ),
                    icon: _isAddingQuickPerson
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(Icons.person_add_alt_1, size: 16),
                    label: Text(
                      _isAddingQuickPerson ? 'Adding' : 'Add',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: provider.familyMembers.map((member) {
                final isSelected = _selectedParticipants.contains(member.id);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      isSelected
                          ? _selectedParticipants.remove(member.id)
                          : _selectedParticipants.add(member.id);
                      _updateSplits();
                    });
                  },
                  child: AnimatedContainer(
                    duration: AppAnimations.standard,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.success.withValues(alpha: 0.2)
                          : AppColors.cardElevated,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.success
                            : Colors.transparent,
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
                        const SizedBox(width: AppSpacing.sm),
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

  Widget _buildEachPersonSummaryCard() {
    final totalAmount = double.tryParse(_amountController.text) ?? 0;
    final participantCount = _selectedParticipants.length;
    final each =
        participantCount > 0 ? totalAmount / participantCount : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Each person',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            participantCount == 0
                ? 'Select participants to calculate split'
                : '₹${AppCurrency.format(each)}',
            style: AppTypography.headlineMedium.copyWith(
              color: participantCount == 0
                  ? AppColors.textTertiary
                  : AppColors.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            participantCount == 0
                ? 'Choose members below'
                : '$participantCount ${participantCount == 1 ? 'person' : 'people'} selected',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addQuickParticipant(SharedExpenseProvider provider) async {
    final name = _quickPersonController.text.trim();
    if (name.isEmpty) {
      showTopSnackBar(context, 'Enter a name to add', isError: true);
      return;
    }

    final existing = provider.familyMembers
        .where((m) => m.name.toLowerCase() == name.toLowerCase())
        .firstOrNull;
    if (existing != null) {
      setState(() {
        _selectedParticipants.add(existing.id);
        _selectedPayer ??= existing.id;
        _splitControllers.putIfAbsent(existing.id, () => TextEditingController());
        _quickPersonController.clear();
      });
      _updateSplits();
      return;
    }

    setState(() => _isAddingQuickPerson = true);
    try {
      final member = FamilyMember(
        id: 'manual_${DateTime.now().microsecondsSinceEpoch}',
        name: name,
      );
      await provider.addFamilyMember(member);
      if (!mounted) return;
      setState(() {
        _selectedParticipants.add(member.id);
        _selectedPayer ??= member.id;
        _splitControllers[member.id] = TextEditingController();
        _quickPersonController.clear();
      });
      _updateSplits();
      showTopSnackBar(context, '$name added', isError: false);
    } catch (e) {
      if (!mounted) return;
      showTopSnackBar(context, 'Failed to add person: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isAddingQuickPerson = false);
      }
    }
  }

  Widget _buildSplitSection() {
    final totalAmount = double.tryParse(_amountController.text) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Split Type',
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardElevated,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() {
                      _splitEqually = true;
                      _updateSplits();
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: _splitEqually
                            ? AppColors.primaryBlue.withValues(alpha: 0.3)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
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
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _splitEqually = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: !_splitEqually
                            ? AppColors.primaryBlue.withValues(alpha: 0.3)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
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
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_selectedParticipants.isNotEmpty && totalAmount > 0) ...[
          const SizedBox(height: AppSpacing.md),
          Consumer<SharedExpenseProvider>(
            builder: (context, provider, _) {
              final perPerson = _splitEqually
                  ? totalAmount / _selectedParticipants.length
                  : 0.0;

              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.cardElevated,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Column(
                  children: _selectedParticipants.map((id) {
                    final member = provider.familyMembers.firstWhere(
                      (m) => m.id == id,
                      orElse: () => FamilyMember(id: id, name: 'Unknown'),
                    );

                    if (_splitEqually) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.primaryBlue.withValues(
                                alpha: 0.2,
                              ),
                              child: Text(
                                member.name.isNotEmpty
                                    ? member.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                member.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            Text(
                              '₹${AppCurrency.format(perPerson)}',
                              style: TextStyle(
                                color: id == _selectedPayer
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.primaryBlue.withValues(
                                alpha: 0.2,
                              ),
                              child: Text(
                                member.name.isNotEmpty
                                    ? member.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                member.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller: _splitControllers[id],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  prefixText: '₹ ',
                                  prefixStyle: TextStyle(
                                    color: AppColors.textTertiary,
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 8,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.cardElevated,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
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

  void _updateSplits() {
    if (!_splitEqually) {
      return;
    }
    final totalAmount = double.tryParse(_amountController.text) ?? 0;
    if (totalAmount > 0 && _selectedParticipants.isNotEmpty) {
      final perPerson = totalAmount / _selectedParticipants.length;
      for (var id in _selectedParticipants) {
        _splitControllers[id]?.text = perPerson.toStringAsFixed(2);
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
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      showTopSnackBar(context, 'Please enter a description', isError: true);
      return;
    }

    final totalAmount = double.tryParse(_amountController.text);
    if (totalAmount == null || totalAmount <= 0) {
      showTopSnackBar(context, 'Please enter a valid amount', isError: true);
      return;
    }

    if (_selectedPayer == null) {
      showTopSnackBar(context, 'Please select who paid', isError: true);
      return;
    }
    if (_selectedParticipants.isEmpty) {
      showTopSnackBar(
        context,
        'Please select at least one participant',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<SharedExpenseProvider>();
      final user = FirebaseAuth.instance.currentUser;

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
            isSettled: id == _selectedPayer,
          ),
        );
      }

      final payerMember = provider.familyMembers.firstWhere(
        (m) => m.id == _selectedPayer,
        orElse: () => FamilyMember(id: _selectedPayer!, name: 'Unknown'),
      );

      final expense = SharedExpense(
        id: widget.expense?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
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
        createdAt: widget.expense?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final enteredTotal = splits.fold<double>(0, (sum, split) => sum + split.amount);
      if ((enteredTotal - totalAmount).abs() > 0.01) {
        throw StateError('Split amounts must add up to the total');
      }
      if (widget.expense == null) {
        await provider.addSharedExpense(expense);
      } else {
        await provider.updateSharedExpense(expense);
      }

      if (mounted) {
        Navigator.pop(context);
        if (widget.expense == null) {
          _showNotifyOption(expense, splits, payerMember.name);
        }
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(context, 'Error: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showNotifyOption(
    SharedExpense expense,
    List<ExpenseSplit> splits,
    String payerName,
  ) {
    final owingSplits = splits
        .where((s) => s.personId != expense.paidBy)
        .toList();
    if (owingSplits.isEmpty) {
      return;
    }

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
                  color: AppColors.success.withValues(alpha: 0.2),
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
                                backgroundColor: AppColors.error.withValues(
                                  alpha: 0.2,
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
                                '₹${AppCurrency.format(split.amount)}',
                                style: const TextStyle(
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
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openSplitwise(expense, owingSplits, payerName);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppColors.primaryBlue.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        icon: Icon(
                          Icons.group,
                          color: AppColors.primaryBlue,
                          size: 16,
                        ),
                        label: Text(
                          'Splitwise',
                          style: TextStyle(color: AppColors.primaryBlue),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openGooglePay(expense, owingSplits, payerName);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppColors.success.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        icon: Icon(
                          Icons.account_balance_wallet,
                          color: AppColors.success,
                          size: 16,
                        ),
                        label: Text(
                          'Google Pay',
                          style: TextStyle(color: AppColors.success),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
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
    final message = _buildSplitMessage(expense, owingSplits, payerName);
    Share.share(message, subject: 'Expense Split: ${expense.description}');
  }

  String _buildSplitMessage(
    SharedExpense expense,
    List<ExpenseSplit> owingSplits,
    String payerName,
  ) {
    final dateStr = DateFormat('dd MMM yyyy').format(expense.date);
    final splitDetails = owingSplits
        .map((s) => '• ${s.personName}: ₹${AppCurrency.format(s.amount)}')
        .join('\n');
    return '''💰 Expense Split Notification\n\n$payerName paid ₹${AppCurrency.format(expense.totalAmount)} for "${expense.description}" on $dateStr.\n\nYour share:\n$splitDetails\n\nPlease settle up when you can! 🙏''';
  }

  Future<void> _openSplitwise(
    SharedExpense expense,
    List<ExpenseSplit> owingSplits,
    String payerName,
  ) async {
    final message = _buildSplitMessage(expense, owingSplits, payerName);
    await Clipboard.setData(ClipboardData(text: message));

    final appUri = Uri.parse('splitwise://');
    final webUri = Uri.parse('https://www.splitwise.com/');

    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }

    if (mounted) {
      showTopSnackBar(
        context,
        'Split details copied. Paste in Splitwise.',
        isError: false,
      );
    }
  }

  Future<void> _openGooglePay(
    SharedExpense expense,
    List<ExpenseSplit> owingSplits,
    String payerName,
  ) async {
    final message = _buildSplitMessage(expense, owingSplits, payerName);
    await Clipboard.setData(ClipboardData(text: message));

    final gpayUri = Uri.parse('tez://');
    final fallbackUri = Uri.parse('https://pay.google.com/');

    if (await canLaunchUrl(gpayUri)) {
      await launchUrl(gpayUri, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(fallbackUri)) {
      await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
    }

    if (mounted) {
      showTopSnackBar(
        context,
        'Split details copied. Paste in Google Pay note.',
        isError: false,
      );
    }
  }
}

Future<void> navToAddSharedExpenseScreen(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const ModernAddSharedExpenseScreen()),
  );
}
