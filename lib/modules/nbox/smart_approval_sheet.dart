import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/models/detected_transaction.dart';
import '../../core/models/bike.dart';
import '../../core/models/debt.dart';
import '../../core/models/subscription.dart';
import '../../core/models/investment.dart';
import '../../core/providers/bike_provider.dart';
import '../../core/providers/debt_provider.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/providers/investment_provider.dart';
import '../../core/providers/account_provider.dart';
import '../../core/providers/transaction_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/nbox_provider.dart';
import '../../core/providers/knowledge_provider.dart';
import '../../core/providers/category_provider.dart';
import '../../core/models/knowledge_entry.dart';
import '../../core/models/transaction.dart' as transaction_models;
import '../../core/models/transaction_draft.dart';
import '../../core/services/transaction_intent_classifier.dart';
import '../../core/services/transaction_router.dart';
import '../../core/services/transaction_automation_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_animations.dart';
import '../../core/widgets/top_snackbar.dart';
import '../../core/utils/currency_formatter.dart';

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

Future<bool> showSmartApprovalSheet(
  BuildContext context,
  DetectedTransaction detected,
) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SmartApprovalSheet(detected: detected),
  );
  return result ?? false;
}

// ---------------------------------------------------------------------------
// Sheet
// ---------------------------------------------------------------------------

class SmartApprovalSheet extends StatefulWidget {
  final DetectedTransaction detected;
  const SmartApprovalSheet({super.key, required this.detected});

  @override
  State<SmartApprovalSheet> createState() => _SmartApprovalSheetState();
}

class _SmartApprovalSheetState extends State<SmartApprovalSheet>
    with SingleTickerProviderStateMixin {
  late TransactionIntent _classification;
  TransactionIntent? _overriddenIntent;
  bool _isSaving = false;
  bool _classified = false;

  // ── Fuel ──────────────────────────────────────────────────────────────────
  Bike? _selectedBike;
  final _odometerController = TextEditingController();
  final _fuelLitersController = TextEditingController();
  bool _isFullTank = true;

  // ── EMI ───────────────────────────────────────────────────────────────────
  Debt? _selectedDebt;

  // ── Subscription ──────────────────────────────────────────────────────────
  Subscription? _selectedSubscription;

  // ── Investment ────────────────────────────────────────────────────────────
  Investment? _selectedInvestment;

  // ── Account ───────────────────────────────────────────────────────────────
  String? _selectedAccountId;
  String? _selectedDestinationAccountId;
  String? _selectedCategoryId;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  TransactionIntent get _activeIntent => _overriddenIntent ?? _classification;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: AppAnimations.standard,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    _classification = TransactionIntent.general;

    WidgetsBinding.instance.addPostFrameCallback((_) => _classify());
  }

  @override
  void dispose() {
    _animController.dispose();
    _odometerController.dispose();
    _fuelLitersController.dispose();
    super.dispose();
  }

  void _classify() {
    final accountProvider = context.read<AccountProvider>();
    final knowledgeProvider = context.read<KnowledgeProvider>();
    final intelligence = TransactionAutomationService().analyze(
      detected: widget.detected,
      history: context.read<TransactionProvider>().transactions,
      knowledge: knowledgeProvider.entries,
      accounts: accountProvider,
    );
    final result = intelligence.intent;
    setState(() {
      _classified = true;
      _classification = result;

      // Pre-select matched entities

      // Auto-select bike if only one
      final bikes = context.read<BikeProvider>().bikes;
      if (bikes.length == 1) _selectedBike = bikes.first;

      // Default account: prefer the account matching the detected bank
      // (by name) over just picking the first one in the list.
      final accounts = context.read<AccountProvider>().accounts;
      if (accounts.isNotEmpty) {
        final detectedBank = widget.detected.bankName?.toLowerCase();
        final matched = detectedBank != null
            ? accounts
                  .where(
                    (a) =>
                        a.name.toLowerCase().contains(detectedBank) ||
                        detectedBank.contains(a.name.toLowerCase()),
                  )
                  .firstOrNull
            : null;
        _selectedAccountId =
            intelligence.accountId ?? (matched ?? accounts.first).id;
        _selectedCategoryId =
            intelligence.categoryId ?? widget.detected.detectedCategory;

        // Try to identify a transfer destination from the source message.
        if (result == TransactionIntent.transfer) {
          final source =
              accounts.where((a) => a.id == _selectedAccountId).firstOrNull ??
              matched ??
              accounts.first;
          final body = (widget.detected.body ?? '').toLowerCase();
          final destinationMatches = accounts.where((a) {
            if (!a.isActive || a.id == source.id) return false;
            final name = a.name.toLowerCase();
            final number = a.accountNumber?.replaceAll(RegExp(r'\D'), '');
            return body.contains(name) ||
                (number != null &&
                    number.length >= 4 &&
                    body.contains(number.substring(number.length - 4)));
          }).toList();
          if (destinationMatches.length == 1) {
            _selectedDestinationAccountId = destinationMatches.first.id;
          }
        }
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  String? _validate() {
    if (_selectedAccountId == null) return 'Please select an account';
    if (_activeIntent == TransactionIntent.transfer &&
        _selectedDestinationAccountId == null) {
      return 'Please select a destination account';
    }

    switch (_activeIntent) {
      case TransactionIntent.fuel:
        if (_selectedBike == null) return 'Please select a vehicle';
        if (_odometerController.text.trim().isEmpty) {
          return 'Please enter odometer reading';
        }
        final odo = double.tryParse(_odometerController.text);
        if (odo == null || odo <= 0) return 'Invalid odometer reading';
        if (odo < _selectedBike!.currentOdometer) {
          return 'Odometer must be ≥ current (${_selectedBike!.currentOdometer.toStringAsFixed(0)} km)';
        }
        if (_fuelLitersController.text.trim().isEmpty) {
          return 'Please enter fuel quantity';
        }
        final liters = double.tryParse(_fuelLitersController.text);
        if (liters == null || liters <= 0) return 'Invalid fuel quantity';
        break;
      case TransactionIntent.emiPayment:
        if (_selectedDebt == null) return 'Please select a loan / EMI';
        break;
      case TransactionIntent.subscriptionPayment:
        if (_selectedSubscription == null) {
          return 'Please select a subscription';
        }
        break;
      case TransactionIntent.investmentSip:
        if (_selectedInvestment == null) return 'Please select an investment';
        break;
      default:
        break;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Save — resolve the editable draft, then commit it through the shared path
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    final error = _validate();
    if (error != null) {
      showTopSnackBar(context, error, isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = context.read<UserProvider>().user!.uid;

      // Re-check against the live ledger immediately before writing. This
      // prevents a stale NBox analysis or a second approval from creating a
      // duplicate, while allowing a detection to become valid again after the
      // original transaction was actually deleted.
      final existingId = await _findExistingTransactionId();
      if (existingId != null) {
        await context.read<NewNboxProvider>().markAsApproved(
          widget.detected.id,
          widget.detected.source,
        );
        if (mounted) {
          showTopSnackBar(context, 'This transaction is already recorded.');
          Navigator.pop(context, false);
        }
        return;
      }

      // Validate the account again immediately before the commit.
      final account = context.read<AccountProvider>().getAccountById(
        _selectedAccountId!,
      );
      if (account == null) {
        showTopSnackBar(context, 'Account not found', isError: true);
        setState(() => _isSaving = false);
        return;
      }

      final router = TransactionRouter();
      ApprovedTransactionPlan plan;

      switch (_activeIntent) {
        // ── FUEL ──────────────────────────────────────────────────────────
        case TransactionIntent.fuel:
          final odo = double.parse(_odometerController.text);
          final liters = double.parse(_fuelLitersController.text);

          double? prevFullTankOdo;
          final entries = context.read<BikeProvider>().getEntriesForBike(
            _selectedBike!.id,
          );
          final prevFull = entries.where((e) => e.isFullTank).toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          if (prevFull.isNotEmpty) {
            prevFullTankOdo = prevFull.first.odometerReading;
          }

          plan = TransactionRouter.buildFuelPlan(
            detected: widget.detected,
            userId: userId,
            accountId: _selectedAccountId!,
            bike: _selectedBike!,
            odometerReading: odo,
            fuelLiters: liters,
            isFullTank: _isFullTank,
            previousFullTankOdometer: prevFullTankOdo,
          );
          break;

        // ── EMI ───────────────────────────────────────────────────────────
        case TransactionIntent.emiPayment:
          plan = TransactionRouter.buildEmiPlan(
            detected: widget.detected,
            userId: userId,
            accountId: _selectedAccountId!,
            debt: _selectedDebt!,
          );
          break;

        // ── SUBSCRIPTION ──────────────────────────────────────────────────
        case TransactionIntent.subscriptionPayment:
          plan = TransactionRouter.buildSubscriptionPlan(
            detected: widget.detected,
            userId: userId,
            accountId: _selectedAccountId!,
            subscription: _selectedSubscription!,
          );
          break;

        // ── SIP ───────────────────────────────────────────────────────────
        case TransactionIntent.investmentSip:
          plan = TransactionRouter.buildSipPlan(
            detected: widget.detected,
            userId: userId,
            accountId: _selectedAccountId!,
            investment: _selectedInvestment!,
          );
          break;

        case TransactionIntent.salary:
        case TransactionIntent.transfer:
        case TransactionIntent.food:
        case TransactionIntent.shopping:
        case TransactionIntent.entertainment:
        case TransactionIntent.medical:
        case TransactionIntent.general:
          final categoryId =
              _selectedCategoryId ??
              _categoryIdForIntent(_activeIntent) ??
              widget.detected.detectedCategory;
          final isIncome =
              _activeIntent == TransactionIntent.salary ||
              widget.detected.type.toLowerCase() == 'income';
          final isTransfer = _activeIntent == TransactionIntent.transfer;
          final draft = TransactionDraft(
            type: isTransfer
                ? transaction_models.TransactionType.transfer
                : isIncome
                ? transaction_models.TransactionType.income
                : transaction_models.TransactionType.expense,
            amount: widget.detected.amount,
            description: widget.detected.merchant,
            categoryId: isTransfer ? 'transfer' : categoryId,
            accountId: _selectedAccountId!,
            destinationAccountId:
                isTransfer ? _selectedDestinationAccountId : null,
            date: widget.detected.date,
            metadata: {
              'source': widget.detected.source,
              'sourceId': widget.detected.id,
              'sourceFingerprint': widget.detected.fingerprint,
              'intent': _activeIntent.name,
              'purpose': _activeIntent.name,
            },
          );

          plan = ApprovedTransactionPlan(
            source: widget.detected,
            intent: _activeIntent,
            draft: draft,
            sideEffects: const [],
          );
          break;
      }

      final transactionProvider = context.read<TransactionProvider>();
      await router.execute(
        plan: plan,
        userId: userId,
        transactionProvider: transactionProvider,
      );

      // General approvals are explicit user decisions, so offer to retain
      // the category as reusable Knowledge without forcing it.
      if (plan.intent != TransactionIntent.transfer &&
          plan.intent != TransactionIntent.fuel &&
          plan.intent != TransactionIntent.emiPayment &&
          plan.intent != TransactionIntent.subscriptionPayment &&
          plan.intent != TransactionIntent.investmentSip) {
        try {
          await _offerToRememberDecision(
            merchant: widget.detected.merchant,
            categoryId: plan.draft.categoryId ?? 'other',
            purpose: _activeIntent.name,
            role: plan.draft.type == transaction_models.TransactionType.income
                ? 'payer'
                : 'payee',
          );
        } catch (e) {
          debugPrint('Knowledge learning skipped after successful save: $e');
        }
      }

      // Only after the financial record succeeds may NBox mark the source
      // detection as processed.
      await context.read<NewNboxProvider>().markAsApproved(
        widget.detected.id,
        widget.detected.source,
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('SmartApprovalSheet._save error: $e');
      if (mounted) {
        showTopSnackBar(context, 'Failed to save: $e', isError: true);
        setState(() => _isSaving = false);
      }
    }
  }

  Future<String?> _findExistingTransactionId() async {
    final fingerprint = widget.detected.fingerprint.trim();
    if (fingerprint.isNotEmpty) {
      final existing = await context
          .read<TransactionProvider>()
          .findBySourceFingerprint(fingerprint);
      if (existing != null) return existing.id;
    }

    final history = context.read<TransactionProvider>().transactions;
    final normalizedMerchant = widget.detected.merchant.trim().toLowerCase();
    final same = history.where((tx) {
      final sameAmount = (tx.amount - widget.detected.amount).abs() < 0.01;
      final sameDirection = widget.detected.type.toLowerCase() == 'income'
          ? tx.type == transaction_models.TransactionType.income
          : tx.type == transaction_models.TransactionType.expense;
      final sameEntity =
          (tx.metadata?['entity']?.toString().toLowerCase() ==
              normalizedMerchant) ||
          (tx.description ?? '').trim().toLowerCase() == normalizedMerchant;
      final close =
          tx.date.difference(widget.detected.date).inMinutes.abs() <= 24 * 60;
      return sameAmount && sameDirection && sameEntity && close;
    });
    return same.isEmpty ? null : same.first.id;
  }

  Widget _buildCategorySelector() {
    final categories = context.watch<CategoryProvider>().categories;
    final validValue = categories.any((c) => c.id == _selectedCategoryId)
        ? _selectedCategoryId
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('CATEGORY'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: validValue,
          dropdownColor: AppColors.cardElevated,
          decoration: _inputDecoration('Select category'),
          items: categories
              .map(
                (c) => DropdownMenuItem<String>(
                  value: c.id,
                  child: Text('${c.emoji}  ${c.name}'),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedCategoryId = value),
        ),
      ],
    );
  }

  String? _categoryIdForIntent(TransactionIntent intent) {
    switch (intent) {
      case TransactionIntent.salary:
        return 'salary';
      case TransactionIntent.transfer:
        return 'transfer';
      case TransactionIntent.food:
        return 'food';
      case TransactionIntent.shopping:
        return 'shopping';
      case TransactionIntent.entertainment:
        return 'entertainment';
      case TransactionIntent.medical:
        return 'health';
      case TransactionIntent.general:
        return widget.detected.detectedCategory;
      default:
        return null;
    }
  }

  Future<void> _offerToRememberDecision({
    required String merchant,
    required String? categoryId,
    required String purpose,
    required String role,
  }) async {
    final knowledge = context.read<KnowledgeProvider>();
    final normalized = merchant.trim().toLowerCase();
    if (normalized.isEmpty || !mounted) return;

    final alreadyKnown = knowledge.entries.any(
      (entry) =>
          entry.active &&
          entry.subject == normalized &&
          (entry.predicate == 'category' || entry.predicate == 'purpose'),
    );
    if (alreadyKnown) return;

    final categories = context.read<CategoryProvider>().categories;
    final matches = categoryId == null
        ? const []
        : categories.where((c) => c.id == categoryId).toList();
    final categoryName = matches.isNotEmpty ? matches.first.name : null;
    final detail = categoryName == null
        ? 'Purpose: ${_titleCase(purpose)}'
        : '$merchant → $categoryName';

    final remember = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remember this?'),
        content: Text(
          '$detail\n\nUse this decision for similar transactions in the future?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remember'),
          ),
        ],
      ),
    );

    if (remember != true || !mounted) return;
    const evidence = ['User approved this transaction during NBox review.'];
    if (categoryId != null && categoryId.isNotEmpty) {
      await knowledge.learnCategory(
        subject: merchant,
        categoryId: categoryId,
        source: KnowledgeSource.explicit,
        evidence: evidence,
      );
    }
    await knowledge.learnPurpose(
      subject: merchant,
      purpose: purpose,
      source: KnowledgeSource.explicit,
      evidence: evidence,
    );
    await knowledge.learnCounterpartyRole(
      subject: merchant,
      role: role,
      source: KnowledgeSource.explicit,
      evidence: evidence,
    );
  }

  String _titleCase(String value) {
    return value
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: EdgeInsets.only(bottom: bottomInset),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    if (_classified) ...[
                      _buildIntentSelector(),
                      const SizedBox(height: 24),
                    ],
                    _buildAccountSelector(),
                    if (_activeIntent != TransactionIntent.transfer) ...[
                      const SizedBox(height: 16),
                      _buildCategorySelector(),
                    ],
                    if (_activeIntent == TransactionIntent.transfer) ...[
                      const SizedBox(height: 16),
                      _buildDestinationAccountSelector(),
                    ],
                    const SizedBox(height: 20),
                    if (_activeIntent.requiresExtraInput) ...[
                      _buildIntentForm(),
                      const SizedBox(height: 20),
                    ],
                    if (_activeIntent.hasSideEffects) ...[
                      _buildSideEffectPreview(),
                      const SizedBox(height: 24),
                    ],
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────────────

  Widget _buildHandle() => Center(
    child: Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  Widget _buildHeader() {
    final isIncome = widget.detected.type.toLowerCase() == 'income';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.detected.merchant,
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('dd MMM yyyy, hh:mm a').format(widget.detected.date),
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isIncome
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  size: 14,
                  color: isIncome ? AppColors.pastelGreen : AppColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  isIncome ? 'CREDITED' : 'DEBITED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: isIncome ? AppColors.pastelGreen : AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${isIncome ? '+' : '−'}₹${NumberFormat('#,##,###').format(widget.detected.amount)}',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: isIncome ? AppColors.pastelGreen : AppColors.textPrimary,
              ),
            ),
            if (widget.detected.balanceAfter != null) ...[
              const SizedBox(height: 2),
              Text(
                'Bal. ₹${NumberFormat('#,##,###.##').format(widget.detected.balanceAfter)}',
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDestinationAccountSelector() {
    final accounts = context
        .read<AccountProvider>()
        .accounts
        .where((a) => a.isActive && a.id != _selectedAccountId)
        .toList();
    if (_selectedDestinationAccountId != null &&
        !accounts.any((a) => a.id == _selectedDestinationAccountId)) {
      _selectedDestinationAccountId = null;
    }
    if (accounts.isEmpty) return const SizedBox.shrink();
    return DropdownButtonFormField<String>(
      initialValue: _selectedDestinationAccountId,
      decoration: const InputDecoration(
        labelText: 'Destination account',
        prefixIcon: Icon(Icons.call_made_rounded),
      ),
      items: accounts
          .map(
            (account) => DropdownMenuItem<String>(
              value: account.id,
              child: Text(account.name),
            ),
          )
          .toList(),
      onChanged: (value) =>
          setState(() => _selectedDestinationAccountId = value),
    );
  }

  Widget _buildIntentSelector() {
    const allIntents = TransactionIntent.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'WHAT IS THIS?',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 8),
            _buildConfidenceChip(),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allIntents.map((intent) {
            final isSelected = _activeIntent == intent;
            return GestureDetector(
              onTap: () => setState(() => _overriddenIntent = intent),
              child: AnimatedContainer(
                duration: AppAnimations.standard,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryBlue.withValues(alpha: 0.15)
                      : AppColors.backgroundBlack,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryBlue
                        : Colors.white.withValues(alpha: 0.08),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(intent.icon, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      intent.label,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primaryBlue
                            : AppColors.textSecondary,
                        fontSize: 12,
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
  }

  Widget _buildConfidenceChip() {
    Color color;
    String label;
    final confidenceLabel = widget.detected.isHighConfidence
        ? 'High'
        : widget.detected.isLowConfidence
        ? 'Low'
        : 'Medium';
    switch (confidenceLabel) {
      case 'High':
        color = AppColors.pastelGreen;
        label = '✓ High confidence';
        break;
      case 'Medium':
        color = AppColors.pastelOrange;
        label = '~ Medium confidence';
        break;
      default:
        color = AppColors.error;
        label = '⚠ Low confidence';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildAccountSelector() {
    final accounts = context.watch<AccountProvider>().accounts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('ACCOUNT'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedAccountId,
          dropdownColor: AppColors.cardElevated,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: _inputDecoration('Select account'),
          items: accounts
              .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
              .toList(),
          onChanged: (v) => setState(() => _selectedAccountId = v),
        ),
      ],
    );
  }

  Widget _buildIntentForm() {
    switch (_activeIntent) {
      case TransactionIntent.fuel:
        return _buildFuelForm();
      case TransactionIntent.emiPayment:
        return _buildEmiForm();
      case TransactionIntent.subscriptionPayment:
        return _buildSubscriptionForm();
      case TransactionIntent.investmentSip:
        return _buildSipForm();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFuelForm() {
    final bikes = context.watch<BikeProvider>().bikes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('VEHICLE'),
        const SizedBox(height: 8),
        if (bikes.length == 1)
          _buildBikeCard(bikes.first, selected: true, onTap: null)
        else
          ...bikes.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildBikeCard(
                b,
                selected: _selectedBike?.id == b.id,
                onTap: () => setState(() => _selectedBike = b),
              ),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('ODOMETER (km)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _odometerController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDecoration(
                      _selectedBike != null
                          ? 'Last: ${_selectedBike!.currentOdometer.toStringAsFixed(0)}'
                          : 'e.g. 47230',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('FUEL (liters)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _fuelLitersController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDecoration('e.g. 3.5'),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => setState(() => _isFullTank = !_isFullTank),
          child: Row(
            children: [
              AnimatedContainer(
                duration: AppAnimations.standard,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: _isFullTank
                      ? AppColors.primaryBlue
                      : AppColors.backgroundBlack,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _isFullTank
                        ? AppColors.primaryBlue
                        : Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: _isFullTank
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              Text(
                'Full tank fill-up',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(width: 6),
              Text(
                '(used for mileage calc)',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBikeCard(
    Bike bike, {
    required bool selected,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimations.standard,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryBlue.withValues(alpha: 0.1)
              : AppColors.backgroundBlack,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.primaryBlue
                : Colors.white.withValues(alpha: 0.08),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            const Text('🏍️', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bike.name,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${bike.make} ${bike.model} · ${bike.currentOdometer.toStringAsFixed(0)} km',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: AppColors.primaryBlue, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildEmiForm() {
    final debts = context
        .watch<DebtProvider>()
        .debts
        .where((d) => d.currentBalance > 0)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('SELECT LOAN / EMI'),
        const SizedBox(height: 8),
        DropdownButtonFormField<Debt>(
          initialValue: _selectedDebt,
          dropdownColor: AppColors.cardElevated,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: _inputDecoration('Select loan'),
          items: debts
              .map(
                (d) => DropdownMenuItem(
                  value: d,
                  child: Text(
                    '${d.type.icon} ${d.name} · ₹${(d.monthlyEMI ?? 0).toStringAsFixed(0)}/mo',
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selectedDebt = v),
        ),
      ],
    );
  }

  Widget _buildSubscriptionForm() {
    final subs = context
        .watch<SubscriptionProvider>()
        .subscriptions
        .where((s) => s.isActive)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('SELECT SUBSCRIPTION'),
        const SizedBox(height: 8),
        DropdownButtonFormField<Subscription>(
          initialValue: _selectedSubscription,
          dropdownColor: AppColors.cardElevated,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: _inputDecoration('Select subscription'),
          items: subs
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(
                    '${s.name} · ₹${s.amount.toStringAsFixed(0)}/${s.frequency}',
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selectedSubscription = v),
        ),
      ],
    );
  }

  Widget _buildSipForm() {
    final investments = context
        .watch<InvestmentProvider>()
        .investments
        .where((i) => i.isActive)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('SELECT INVESTMENT'),
        const SizedBox(height: 8),
        DropdownButtonFormField<Investment>(
          initialValue: _selectedInvestment,
          dropdownColor: AppColors.cardElevated,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: _inputDecoration('Select investment'),
          items: investments
              .map(
                (i) => DropdownMenuItem(
                  value: i,
                  child: Text(
                    '${i.name} · SIP ₹${i.sipAmount.toStringAsFixed(0)}',
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selectedInvestment = v),
        ),
      ],
    );
  }

  Widget _buildSideEffectPreview() {
    final previews = _buildPreviewItems();
    if (previews.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.primaryBlue, size: 14),
              const SizedBox(width: 6),
              Text(
                'WILL ALSO DO',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...previews.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppColors.pastelGreen,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _buildPreviewItems() {
    switch (_activeIntent) {
      case TransactionIntent.fuel:
        final bike = _selectedBike;
        if (bike == null) return ['Select a vehicle to see preview'];
        final odo = double.tryParse(_odometerController.text);
        final liters = double.tryParse(_fuelLitersController.text);
        final items = <String>[
          'Create fuel log for ${bike.name}',
          'Update odometer${odo != null ? ' → ${odo.toStringAsFixed(0)} km' : ''}',
        ];
        if (_isFullTank && odo != null && liters != null && liters > 0) {
          final prev = bike.currentOdometer;
          if (odo > prev) {
            final mileage = (odo - prev) / liters;
            items.add('Calculate mileage → ${mileage.toStringAsFixed(1)} km/L');
          }
        }
        return items;

      case TransactionIntent.emiPayment:
        final debt = _selectedDebt;
        if (debt == null) return ['Select a loan to see preview'];
        return [
          'Mark ${debt.name} EMI as paid',
          'Advance payment date by 1 month',
          'Update outstanding balance',
        ];

      case TransactionIntent.subscriptionPayment:
        final sub = _selectedSubscription;
        if (sub == null) return ['Select a subscription to see preview'];
        final next = sub.calculateNextDueDate();
        return [
          'Log payment for ${sub.name}',
          'Next due → ${DateFormat('dd MMM yyyy').format(next)}',
        ];

      case TransactionIntent.investmentSip:
        final inv = _selectedInvestment;
        if (inv == null) return ['Select an investment to see preview'];
        return [
          'Add ₹${AppCurrency.format(widget.detected.amount)} to ${inv.name}',
          'Update invested amount',
        ];

      default:
        return [];
    }
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: AppAnimations.standard,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: _isSaving
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
          color: _isSaving ? AppColors.cardElevated : null,
          boxShadow: _isSaving
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _activeIntent.hasSideEffects
                          ? 'Confirm & Save All'
                          : 'Save Transaction',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (_activeIntent.hasSideEffects) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.auto_awesome, size: 16),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(
    text,
    style: TextStyle(
      color: AppColors.textTertiary,
      fontSize: 10,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
    ),
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 13),
    filled: true,
    fillColor: AppColors.cardElevated,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.primaryBlue, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}
