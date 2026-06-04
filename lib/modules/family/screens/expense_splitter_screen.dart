import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/nexus_switch.dart';
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
  final List<String> _participants = ['Person 1', 'Person 2'];
  bool _includesTip = false;
  double _tipPercentage = 0;

  @override
  void dispose() {
    _amountController.dispose();
    _personNameController.dispose();
    super.dispose();
  }

  double get _totalAmount {
    final base = double.tryParse(_amountController.text) ?? 0;
    return base + (base * _tipPercentage / 100);
  }

  double get _perPersonAmount {
    if (_participants.isEmpty) {
      return 0;
    }
    return _totalAmount / _participants.length;
  }

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
              Text(
                '₹',
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
              Text(
                'Add Tip',
                style: const TextStyle(
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
                  }
                }),
              ),
            ],
          ),
          if (_includesTip) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [10, 15, 20, 25].map((percent) {
                final isSelected = _tipPercentage == percent;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _tipPercentage = percent.toDouble()),
                  child: Container(
                    width: 60,
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
              }).toList(),
            ),
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
            Row(
              children: [
                IconButton(
                  onPressed: _participants.length > 2
                      ? () => setState(() => _participants.removeLast())
                      : null,
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: _participants.length > 2
                        ? AppColors.error
                        : AppColors.textTertiary.withValues(alpha: 0.3),
                  ),
                ),
                Text(
                  '${_participants.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                IconButton(
                  onPressed: () => _addParticipantFromInput(),
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: AppColors.success,
                  ),
                ),
              ],
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_participants.length, (index) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primaryBlue.withValues(
                      alpha: 0.2,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _participants[index],
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildShareActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SEND SPLIT',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.group,
                label: 'Splitwise',
                color: AppColors.primaryBlue,
                onTap: _openSplitwise,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionButton(
                icon: Icons.account_balance_wallet,
                label: 'Google Pay',
                color: AppColors.success,
                onTap: _openGooglePay,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _shareSplit,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: Icon(Icons.share, color: AppColors.textSecondary),
            label: Text(
              'Share Message',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
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
      style: TextStyle(
        color: AppColors.textTertiary,
        fontSize: 12,
      ),
      textAlign: TextAlign.center,
    );
  }

  void _addParticipantFromInput() {
    final name = _personNameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _participants.add('Person ${_participants.length + 1}');
      });
      return;
    }

    final exists = _participants.any(
      (p) => p.toLowerCase() == name.toLowerCase(),
    );
    if (exists) {
      showTopSnackBar(context, '$name is already added', isError: true);
      return;
    }

    setState(() {
      _participants.add(name);
      _personNameController.clear();
    });
  }

  String _buildSplitMessage() {
    final participants = _participants
        .map((p) => '- $p: ₹${_perPersonAmount.toStringAsFixed(2)}')
        .join('\n');
    final baseAmount = double.tryParse(_amountController.text) ?? 0;

    return 'Split summary\n\n'
        'Bill: ₹${baseAmount.toStringAsFixed(2)}\n'
        'Tip: ${_tipPercentage.toStringAsFixed(0)}%\n'
        'Total: ₹${_totalAmount.toStringAsFixed(2)}\n'
        'Each person pays: ₹${_perPersonAmount.toStringAsFixed(2)}\n\n'
        '$participants';
  }

  Future<void> _openSplitwise() async {
    final message = _buildSplitMessage();
    await Clipboard.setData(ClipboardData(text: message));

    final appUri = Uri.parse('splitwise://');
    final webUri = Uri.parse('https://www.splitwise.com/');

    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }

    if (!mounted) { return; }
    showTopSnackBar(
      context,
      'Split copied. Paste in Splitwise.',
      isError: false,
    );
  }

  Future<void> _openGooglePay() async {
    final message = _buildSplitMessage();
    await Clipboard.setData(ClipboardData(text: message));

    final gpayUri = Uri.parse('tez://');
    final fallbackUri = Uri.parse('https://pay.google.com/');

    if (await canLaunchUrl(gpayUri)) {
      await launchUrl(gpayUri, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(fallbackUri)) {
      await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
    }

    if (!mounted) { return; }
    showTopSnackBar(
      context,
      'Split copied. Paste in Google Pay note.',
      isError: false,
    );
  }

  void _shareSplit() {
    Share.share(_buildSplitMessage(), subject: 'Quick Split');
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withValues(alpha: 0.3),
            AppColors.primaryBlue.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
      ),
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
            '₹${_perPersonAmount.toStringAsFixed(2)}',
            style: TextStyle(
              color: AppColors.primaryBlue,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_includesTip && _tipPercentage > 0) ...[
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
                    'Includes ${_tipPercentage.toInt()}% tip',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(₹${(double.tryParse(_amountController.text) ?? 0) * _tipPercentage / 100 / _participants.length})',
                    style: TextStyle(
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
                '₹${(double.tryParse(_amountController.text) ?? 0).toStringAsFixed(0)}',
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withValues(alpha: 0.1),
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              _buildSummaryItem(
                'Tip',
                '₹${((double.tryParse(_amountController.text) ?? 0) * _tipPercentage / 100).toStringAsFixed(0)}',
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withValues(alpha: 0.1),
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              _buildSummaryItem('Total', '₹${_totalAmount.toStringAsFixed(0)}'),
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
