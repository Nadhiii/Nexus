import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/nexus_switch.dart';
import '../../../core/widgets/nexus_card.dart';
import '../../../core/widgets/top_snackbar.dart';

/// Expense Splitter Screen - For quick expense splitting calculations
/// This screen allows users to quickly split expenses without saving them
class ExpenseSplitterScreen extends StatefulWidget {
  const ExpenseSplitterScreen({super.key});

  @override
  State<ExpenseSplitterScreen> createState() => _ExpenseSplitterScreenState();
}

class _ExpenseSplitterScreenState extends State<ExpenseSplitterScreen> {
  final _amountController = TextEditingController();
  final _personNameController = TextEditingController();
  final _customTipController = TextEditingController();
  final List<TextEditingController> _participantControllers = [
    TextEditingController(text: 'Person 1'),
    TextEditingController(text: 'Person 2'),
  ];
  bool _includesTip = false;
  double _tipPercentage = 0;
  bool _isCustomTip = false;
  bool _customTipIsAmount = false;

  @override
  void dispose() {
    _amountController.dispose();
    _personNameController.dispose();
    _customTipController.dispose();
    for (final c in _participantControllers) {
      c.dispose();
    }
    super.dispose();
  }

  double get _totalAmount {
    final base = double.tryParse(_amountController.text) ?? 0;
    if (!_includesTip) return base;
    if (_isCustomTip && _customTipIsAmount) {
      return base + (double.tryParse(_customTipController.text) ?? 0);
    }
    return base + (base * _effectiveTip / 100);
  }

  double get _perPersonAmount {
    if (_participantControllers.isEmpty) return 0;
    return _totalAmount / _participantControllers.length;
  }

  double get _effectiveTip {
    if (!_isCustomTip) return _tipPercentage;
    final val = double.tryParse(_customTipController.text) ?? 0;
    if (_customTipIsAmount) {
      final base = double.tryParse(_amountController.text) ?? 0;
      return base == 0 ? 0 : (val / base) * 100;
    }
    return val;
  }

  List<String> get _participants =>
      _participantControllers.map((c) => c.text.trim()).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAmountInput(),
                    const SizedBox(height: 24),
                    _buildResultCard(),
                    const SizedBox(height: 24),
                    _buildTipSection(),
                    const SizedBox(height: 24),
                    _buildParticipantsSection(),
                    const SizedBox(height: 24),
                    _buildShareActions(),
                    const SizedBox(height: 24),
                    _buildHelperText(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Split',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Split bills instantly',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Text(
            'TOTAL BILL',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Γé╣',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: IntrinsicWidth(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(color: Colors.white24, fontSize: 48),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Add Tip',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              NexusSwitch(
                value: _includesTip,
                activeThumbColor: AppColors.primaryBlue,
                onChanged: (val) => setState(() {
                  _includesTip = val;
                  if (!val) {
                    _tipPercentage = 0;
                    _isCustomTip = false;
                    _customTipController.clear();
                  }
                }),
              ),
            ],
          ),
          if (_includesTip) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ...[5, 10, 15, 20].map((percent) {
                  final isSelected = !_isCustomTip && _tipPercentage == percent;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _tipPercentage = percent.toDouble();
                      _isCustomTip = false;
                      _customTipController.clear();
                    }),
                    child: Container(
                      width: 56,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryBlue.withValues(alpha: 0.2)
                            : AppColors.backgroundBlack,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryBlue
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(
                        '$percent%',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.primaryBlue
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
                GestureDetector(
                  onTap: () => setState(() {
                    _isCustomTip = true;
                    _tipPercentage = 0;
                  }),
                  child: Container(
                    width: 56,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _isCustomTip
                          ? AppColors.primaryBlue.withValues(alpha: 0.2)
                          : AppColors.backgroundBlack,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isCustomTip
                            ? AppColors.primaryBlue
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      'Custom',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _isCustomTip
                            ? AppColors.primaryBlue
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_isCustomTip) ...[
              const SizedBox(height: 12),
              // Mode toggle: % vs Γé╣
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _customTipIsAmount = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: !_customTipIsAmount
                              ? AppColors.primaryBlue.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: !_customTipIsAmount
                                ? AppColors.primaryBlue
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          '% Percentage',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !_customTipIsAmount
                                ? AppColors.primaryBlue
                                : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _customTipIsAmount = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _customTipIsAmount
                              ? AppColors.primaryBlue.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _customTipIsAmount
                                ? AppColors.primaryBlue
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          'Γé╣ Amount',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _customTipIsAmount
                                ? AppColors.primaryBlue
                                : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _customTipController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: _customTipIsAmount
                      ? 'Enter tip amount'
                      : 'Enter percentage',
                  hintStyle: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 13,
                  ),
                  suffixText: _customTipIsAmount ? 'Γé╣' : '%',
                  suffixStyle: const TextStyle(color: AppColors.primaryBlue),
                  filled: true,
                  fillColor: AppColors.backgroundBlack,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primaryBlue),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildParticipantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SPLIT BETWEEN',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            Text(
              '${_participantControllers.length} people',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _personNameController,
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => _addParticipantFromInput(),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Add person name',
                  hintStyle: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: AppColors.cardElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.primaryBlue.withValues(alpha: 0.5),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _addParticipantFromInput,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(80, 44),
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.person_add_alt_1, size: 16),
                label: const Text(
                  'Add',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _participantControllers.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primaryBlue.withValues(
                      alpha: 0.2,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _participantControllers[index],
                      style: const TextStyle(color: Colors.white),
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Person ${index + 1}',
                        hintStyle: TextStyle(color: AppColors.textTertiary),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        filled: false,
                      ),
                    ),
                  ),
                  if (_participantControllers.length > 2)
                    GestureDetector(
                      onTap: () => setState(() {
                        _participantControllers[index].dispose();
                        _participantControllers.removeAt(index);
                      }),
                      child: const Icon(
                        Icons.remove_circle_outline,
                        color: AppColors.error,
                        size: 20,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildShareActions() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _shareSplitMessage,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cardElevated,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
        ),
        icon: const Icon(Icons.share, size: 18),
        label: const Text(
          'Share via WhatsApp / Message',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.35)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: Icon(icon, color: color, size: 18),
      label: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildHelperText() {
    return Text(
      'Quick Split is calculation-only and does not save to your accounts.',
      style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
      textAlign: TextAlign.center,
    );
  }

  void _addParticipantFromInput() {
    final name = _personNameController.text.trim();
    final newName = name.isEmpty
        ? 'Person ${_participantControllers.length + 1}'
        : name;

    final exists = _participantControllers.any(
      (c) => c.text.trim().toLowerCase() == newName.toLowerCase(),
    );
    if (exists) {
      showTopSnackBar(context, '$newName is already added', isError: true);
      return;
    }

    setState(() {
      _participantControllers.add(TextEditingController(text: newName));
      _personNameController.clear();
    });
  }

  String _buildSplitMessage() {
    final participants = _participants
        .map((p) => '- $p: Γé╣${_perPersonAmount.toStringAsFixed(2)}')
        .join('\n');
    final baseAmount = double.tryParse(_amountController.text) ?? 0;

    return 'Split summary\n\n'
        'Bill: Γé╣${baseAmount.toStringAsFixed(2)}\n'
        'Tip: ${_effectiveTip.toStringAsFixed(_effectiveTip % 1 == 0 ? 0 : 1)}%\n'
        'Total: Γé╣${_totalAmount.toStringAsFixed(2)}\n'
        'Each person pays: Γé╣${_perPersonAmount.toStringAsFixed(2)}\n\n'
        '$participants';
  }

  void _shareSplitMessage() {
    if (_amountController.text.isEmpty || _participants.isEmpty) return;

    final StringBuffer buffer = StringBuffer();
    buffer.writeln("=== ≡ƒº╛ Quick Split Bill Breakdown ===");
    buffer.writeln("Total Bill: Γé╣${_totalAmount.toStringAsFixed(2)}");
    buffer.writeln(
      "Per Person Share: Γé╣${_perPersonAmount.toStringAsFixed(2)}\n",
    );
    buffer.writeln("≡ƒæñ Split Details:");

    for (var participant in _participants) {
      buffer.writeln(
        "ΓÇó $participant owes: Γé╣${_perPersonAmount.toStringAsFixed(2)}",
      );
    }

    buffer.writeln("\nSent via Nexus Quick Split");
    Share.share(buffer.toString());
  }

  Widget _buildResultCard() {
    return NexusCard(
      variant: NexusCardVariant.accent,
      padding: AppSpacing.cardPaddingLg,
      child: Column(
        children: [
          Text(
            'EACH PERSON PAYS',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Γé╣${_perPersonAmount.toStringAsFixed(2)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primaryBlue,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_includesTip && _effectiveTip > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.backgroundBlack.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Includes ${_effectiveTip.toStringAsFixed(_effectiveTip % 1 == 0 ? 0 : 1)}% tip',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(Γé╣${((double.tryParse(_amountController.text) ?? 0) * _effectiveTip / 100 / _participantControllers.length).toStringAsFixed(2)})',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSummaryItem(
                'Bill',
                'Γé╣${(double.tryParse(_amountController.text) ?? 0).toStringAsFixed(0)}',
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withValues(alpha: 0.1),
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              _buildSummaryItem(
                'Tip',
                'Γé╣${((double.tryParse(_amountController.text) ?? 0) * _effectiveTip / 100).toStringAsFixed(0)}',
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withValues(alpha: 0.1),
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              _buildSummaryItem('Total', 'Γé╣${_totalAmount.toStringAsFixed(0)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
        ),
      ],
    );
  }
}
