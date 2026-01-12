import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/models/subscription.dart';
import '../../../core/widgets/top_snackbar.dart';

class AddSubscriptionModal extends StatefulWidget {
  final Subscription? subscriptionToEdit;

  const AddSubscriptionModal({super.key, this.subscriptionToEdit});

  @override
  State<AddSubscriptionModal> createState() => _AddSubscriptionModalState();
}

class _AddSubscriptionModalState extends State<AddSubscriptionModal>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  String _selectedFrequency = 'monthly';
  DateTime _nextDueDate = DateTime.now().add(const Duration(days: 30));
  Color _brandColor = AppColors.accentOrange; // Default color
  bool _isLoading = false;

  // Quick Add Data
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
    // Animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    // Edit Mode
    if (widget.subscriptionToEdit != null) {
      final s = widget.subscriptionToEdit!;
      _nameController.text = s.name;
      _amountController.text = s.amount.toStringAsFixed(0);
      _selectedFrequency = s.frequency;
      _nextDueDate = s.nextDueDate;
      try {
        _brandColor = Color(int.parse(s.color.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }

    // Live Preview Listeners
    _nameController.addListener(() => setState(() {}));
    _amountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _animationController.dispose();
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  constraints: const BoxConstraints(
                    maxWidth: 400,
                    maxHeight: 800,
                  ),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundBlack,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.subscriptionToEdit != null
                            ? "Edit Subscription"
                            : "New Subscription",
                        style: AppTypography.headlineSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Expanded(
                        child: SingleChildScrollView(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 1. LIVE PREVIEW
                                _buildLivePreview(),
                                const SizedBox(height: 32),

                                // 2. QUICK ADD (Always visible for faster entry)
                                ...[
                                  _buildLabel("QUICK ADD"),
                                  SizedBox(
                                    height: 50,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _popularServices.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 12),
                                      itemBuilder: (context, index) {
                                        final s = _popularServices[index];
                                        return GestureDetector(
                                          onTap: () => _onQuickAdd(s),
                                          child: Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: (s['color'] as Color)
                                                  .withOpacity(0.2),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: (s['color'] as Color)
                                                    .withOpacity(0.5),
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
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
                                  const SizedBox(height: 24),
                                ],

                                // 3. DETAILS
                                _buildLabel("SERVICE DETAILS"),
                                _buildGlassTextField(
                                  controller: _nameController,
                                  hint: "e.g. Netflix Premium",
                                  icon: Icons.subscriptions,
                                ),
                                const SizedBox(height: 16),
                                _buildGlassTextField(
                                  controller: _amountController,
                                  hint: "Amount (₹)",
                                  icon: Icons.currency_rupee,
                                  isNumber: true,
                                ),

                                const SizedBox(height: 24),
                                _buildLabel("BILLING CYCLE"),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardSurface,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.05),
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedFrequency,
                                      dropdownColor: AppColors.cardSurface,
                                      icon: const Icon(
                                        Icons.arrow_drop_down,
                                        color: AppColors.textSecondary,
                                      ),
                                      isExpanded: true,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
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
                                      onChanged: (v) => setState(
                                        () => _selectedFrequency = v!,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),
                                _buildLabel("NEXT DUE DATE"),
                                GestureDetector(
                                  onTap: _selectDate,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardSurface,
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.05),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          color: _brandColor,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          "Due On",
                                          style: TextStyle(
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          DateFormat(
                                            'dd MMM yyyy',
                                          ).format(_nextDueDate),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 40),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.cardSurface,
                                      foregroundColor: AppColors.accentOrange,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                        side: BorderSide(
                                          color: AppColors.accentOrange
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isLoading
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.accentOrange,
                                            ),
                                          )
                                        : const Text(
                                            "Save Subscription",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      "Cancel",
                                      style: TextStyle(
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _brandColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'S',
                style: TextStyle(
                  color: _brandColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textTertiary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  // FIXED: No labelText inside, preventing overlap
  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isNumber = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(30), // True Pill
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textTertiary.withOpacity(0.5)),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Icon(icon, color: AppColors.textSecondary),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        validator: (value) =>
            (value == null || value.isEmpty) ? "Required" : null,
      ),
    );
  }

  Future<void> _selectDate() async {
    // Ensure initialDate is within the allowed range to prevent crashes
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 10, now.month, now.day);
    final lastDate = DateTime(now.year + 10, now.month, now.day);

    DateTime initialDate = _nextDueDate;
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (date != null) setState(() => _nextDueDate = date);
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        // Convert Color to Hex
        String colorString =
            '#${_brandColor.value.toRadixString(16).substring(2)}';

        final sub = Subscription(
          id: widget.subscriptionToEdit?.id ?? '',
          userId: user.uid,
          name: _nameController.text.trim(),
          amount: double.parse(_amountController.text),
          frequency: _selectedFrequency,
          nextDueDate: _nextDueDate,
          categoryId: 'general',
          accountId: 'default',
          color: colorString, // Save brand color
          isActive: true,
          createdAt: DateTime.now(),
        );

        if (widget.subscriptionToEdit != null) {
          await Provider.of<SubscriptionProvider>(
            context,
            listen: false,
          ).updateSubscription(sub);
        } else {
          await Provider.of<SubscriptionProvider>(
            context,
            listen: false,
          ).addSubscription(sub);
        }

        if (mounted) {
          Navigator.pop(context);
          showTopSnackBar(context, 'Subscription saved');
        }
      } catch (e) {
        if (mounted) showTopSnackBar(context, 'Error: $e', isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}

Future<void> showAddSubscriptionModal(
  BuildContext context, {
  Subscription? subscriptionToEdit,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, __, ___) =>
          AddSubscriptionModal(subscriptionToEdit: subscriptionToEdit),
    ),
  );
}
