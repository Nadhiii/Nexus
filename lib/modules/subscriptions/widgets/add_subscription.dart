import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/models/subscription.dart';
import '../../../core/widgets/top_snackbar.dart';
import '../../../core/utils/logo_utils.dart';

class ModernAddSubscriptionScreen extends StatefulWidget {
  final Subscription? subscriptionToEdit;

  const ModernAddSubscriptionScreen({super.key, this.subscriptionToEdit});

  @override
  State<ModernAddSubscriptionScreen> createState() =>
      _ModernAddSubscriptionScreenState();
}

class _ModernAddSubscriptionScreenState
    extends State<ModernAddSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  String _selectedFrequency = 'monthly';
  DateTime _nextDueDate = DateTime.now().add(const Duration(days: 30));
  Color _brandColor = AppColors.accentOrange;
  bool _isLoading = false;

  bool get _isEditMode => widget.subscriptionToEdit != null;

  final List<Map<String, dynamic>> _popularServices = [
    {'name': 'Netflix', 'color': const Color(0xFFE50914), 'icon': 'N'},
    {'name': 'Spotify', 'color': const Color(0xFF1DB954), 'icon': 'S'},
    {'name': 'YouTube', 'color': const Color(0xFFFF0000), 'icon': 'Y'},
    {'name': 'Prime', 'color': const Color(0xFF00A8E1), 'icon': 'P'},
    {'name': 'Apple', 'color': const Color(0xFFFFFFFF), 'icon': 'A'},
    {'name': 'Disney+', 'color': const Color(0xFF113CCF), 'icon': 'D'},
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final s = widget.subscriptionToEdit!;
      _nameController.text = s.name;
      _amountController.text = s.amount.toStringAsFixed(0);
      _selectedFrequency = s.frequency;
      _nextDueDate = s.nextDueDate;
      try {
        _brandColor = Color(int.parse(s.color.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }

    _nameController.addListener(() => setState(() {}));
    _amountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onQuickAdd(Map<String, dynamic> service) {
    setState(() {
      _nameController.text = service['name'];
      _brandColor = service['color'];
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditMode ? 'Edit Subscription' : 'New Subscription';

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
              title: Text(title, style: AppTypography.headlineMedium),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLivePreview(),
                    const SizedBox(height: AppSpacing.xl2),

                    Text(
                      'Amount',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _amountController,
                      autofocus: !_isEditMode,
                      style: AppTypography.displayMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        prefixText: '₹ ',
                        prefixStyle: AppTypography.displayMedium.copyWith(
                          color: _brandColor,
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
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Amount is required';
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl2),

                    if (!_isEditMode) ...[
                      Text(
                        'Quick Add',
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        height: 50,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _popularServices.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final s = _popularServices[index];
                            final logoPath = LogoUtils.subscriptionLogoFor(
                              s['name'] as String,
                            );
                            return GestureDetector(
                              onTap: () => _onQuickAdd(s),
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: (s['color'] as Color).withValues(
                                    alpha: 0.2,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: (s['color'] as Color).withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                                child: Center(
                                  child: logoPath != null
                                      ? LogoUtils.buildLogo(logoPath, size: 22)
                                      : Text(
                                          s['icon'],
                                          style: TextStyle(
                                            color: s['color'],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl2),
                    ],

                    Text(
                      'Service Name',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _nameController,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. Netflix Premium',
                        hintStyle: TextStyle(color: AppColors.textTertiary),
                        filled: true,
                        fillColor: AppColors.cardElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) => value!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: AppSpacing.xl2),

                    Text(
                      'Billing Cycle',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardElevated,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedFrequency,
                        dropdownColor: AppColors.cardElevated,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'monthly',
                            child: Text('Monthly'),
                          ),
                          DropdownMenuItem(
                            value: 'yearly',
                            child: Text('Yearly'),
                          ),
                          DropdownMenuItem(
                            value: 'weekly',
                            child: Text('Weekly'),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _selectedFrequency = v!),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl2),

                    Text(
                      'Next Due Date',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    GestureDetector(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
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
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              DateFormat('MMM dd, yyyy').format(_nextDueDate),
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.chevron_right,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl2),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
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
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : Text(
                                _isEditMode
                                    ? 'Save Changes'
                                    : 'Save Subscription',
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
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreview() {
    final name = _nameController.text.isEmpty
        ? "Service Name"
        : _nameController.text;
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final logoPath = LogoUtils.subscriptionLogoFor(name);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: _brandColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _brandColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Center(
              child: logoPath != null
                  ? LogoUtils.buildLogo(logoPath, size: 26)
                  : Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'S',
                      style: TextStyle(
                        color: _brandColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _selectedFrequency.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 10, now.month, now.day);
    final lastDate = DateTime(now.year + 10, now.month, now.day);

    DateTime initialDate = _nextDueDate;
    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    }
    if (initialDate.isAfter(lastDate)) {
      initialDate = lastDate;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (date != null) {
      setState(() => _nextDueDate = date);
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          return;
        }

        String colorString =
            '#${_brandColor.toARGB32().toRadixString(16).substring(2)}';

        final sub = Subscription(
          id: widget.subscriptionToEdit?.id ?? '',
          userId: user.uid,
          name: _nameController.text.trim(),
          amount: double.parse(_amountController.text),
          frequency: _selectedFrequency,
          nextDueDate: _nextDueDate,
          categoryId: 'general',
          accountId: 'default',
          color: colorString,
          isActive: true,
          createdAt: DateTime.now(),
        );

        if (widget.subscriptionToEdit != null) {
          await context.read<SubscriptionProvider>().updateSubscription(sub);
        } else {
          await context.read<SubscriptionProvider>().addSubscription(sub);
        }

        if (mounted) {
          Navigator.pop(context);
          showTopSnackBar(context, 'Subscription saved');
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
  }
}

Future<void> showAddSubscription(
  BuildContext context, {
  Subscription? subscriptionToEdit,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, _, _) =>
          ModernAddSubscriptionScreen(subscriptionToEdit: subscriptionToEdit),
    ),
  );
}

// Alias for backwards compatibility
Future<void> showAddSubscriptionModal(
  BuildContext context, {
  Subscription? subscriptionToEdit,
}) => showAddSubscription(context, subscriptionToEdit: subscriptionToEdit);
