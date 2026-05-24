// ignore_for_file: invalid_use_of_protected_member
import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nfc_manager/nfc_manager.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/account_provider.dart';
import '../../core/models/account.dart';
import '../../core/widgets/top_snackbar.dart';
import '../../core/services/secure_card_service.dart';
import '../../core/utils/logo_utils.dart';

class ModernAddAccountScreen extends StatefulWidget {
  final Account? accountToEdit;

  const ModernAddAccountScreen({super.key, this.accountToEdit});

  @override
  State<ModernAddAccountScreen> createState() => _ModernAddAccountScreenState();
}

class _ModernAddAccountScreenState extends State<ModernAddAccountScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late Animation<Offset> _logoSlideAnimation;
  String _previousBankName = '';

  // Stepper Controllers
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 3;

  // Form Keys for each step
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();

  // Basic Account Controllers
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscCodeController = TextEditingController();

  // Card Controllers & Focus
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _cardNumberFocus = FocusNode();

  bool _hasCardDetails = false;
  final SecureCardService _secureCardService = SecureCardService();

  AccountType _selectedType = AccountType.savings;
  Color _selectedColor = AppColors.primaryBlue;
  IconData _selectedIcon = Icons.account_balance;
  bool _isLoading = false;

  final List<Color> _colorPalette = [
    AppColors.primaryBlue,
    const Color(0xFF00E676),
    const Color(0xFFFFEA00),
    const Color(0xFFFF3D00),
    const Color(0xFFD500F9),
    const Color(0xFF2979FF),
    const Color(0xFF607D8B),
    const Color(0xFF37474F),
  ];

  final List<IconData> _iconPalette = [
    Icons.account_balance,
    Icons.savings,
    Icons.credit_card,
    Icons.wallet,
    Icons.pie_chart,
    Icons.attach_money,
    Icons.diamond,
    Icons.lock,
  ];

  @override
  void initState() {
    super.initState();

    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _logoSlideAnimation =
        Tween<Offset>(begin: const Offset(0.5, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _logoAnimationController,
            curve: Curves.easeOut,
          ),
        );

    if (widget.accountToEdit != null) {
      final account = widget.accountToEdit!;
      _nameController.text = account.name;
      _balanceController.text = account.balance.toString();
      _bankNameController.text = account.bankName ?? '';
      _accountNumberController.text = account.accountNumber ?? '';
      _ifscCodeController.text = account.ifscCode ?? '';
      _cardNumberController.text = account.cardNumber ?? '';
      _cardExpiryController.text = account.cardExpiry ?? '';
      _loadSecureCvv(account.id);
      _cardHolderController.text = account.cardHolderName ?? '';
      if (_cardNumberController.text.isNotEmpty) {
        _hasCardDetails = true;
      }

      _selectedType = account.type;
      _selectedColor = account.color;
      _selectedIcon = account.icon;
    }

    _nameController.addListener(() => setState(() {}));
    _balanceController.addListener(() => setState(() {}));
    _accountNumberController.addListener(() => setState(() {}));
    _cardNumberController.addListener(() => setState(() {}));
    _cardExpiryController.addListener(() => setState(() {}));

    _bankNameController.addListener(() {
      final currentBank = _bankNameController.text;
      if (currentBank != _previousBankName) {
        _previousBankName = currentBank;
        _logoAnimationController.forward(from: 0.0);
      }
      setState(() {});
    });
  }

  Future<void> _loadSecureCvv(String accountId) async {
    final cvv = await _secureCardService.getCvv(accountId);
    if (cvv != null && mounted) {
      setState(() => _cardCvvController.text = cvv);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _logoAnimationController.dispose();
    _nameController.dispose();
    _balanceController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _cardHolderController.dispose();
    _cardNumberFocus.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 0 && !_step1Key.currentState!.validate()) {
      return;
    }
    if (_currentPage == 1 && !_step2Key.currentState!.validate()) {
      return;
    }

    if (_currentPage < _totalPages - 1) {
      // Unfocus keyboard before sliding to next page to keep layout smooth
      FocusScope.of(context).unfocus();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _saveAccount();
    }
  }

  void _previousPage() {
    FocusScope.of(context).unfocus();
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _startNfcScan() async {
    if (!Platform.isAndroid) {
      return;
    }

    final availability = await NfcManager.instance.checkAvailability();
    if (availability != NfcAvailability.enabled) {
      if (mounted) {
        showTopSnackBar(context, "NFC is not available", isError: true);
      }
      return;
    }

    if (mounted) {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.cardElevated,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg),
          ),
        ),
        builder: (ctx) => Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          height: 300,
          child: Column(
            children: [
              const Icon(
                Icons.contactless,
                size: 64,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                "Hold Card to Back",
                style: AppTypography.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                "Searching for banking chip...",
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  NfcManager.instance.stopSession();
                  Navigator.pop(ctx);
                },
                child: const Text("Cancel"),
              ),
            ],
          ),
        ),
      ).whenComplete(() => NfcManager.instance.stopSession());
    }

    NfcManager.instance.startSession(
      pollingOptions: const {NfcPollingOption.iso14443},
      onDiscovered: (NfcTag tag) async {
        try {
          final tagUid = _extractTagUid(tag.data);
          if (tagUid != null && mounted) {
            setState(() {
              _cardNumberController.text = tagUid;
              _cardExpiryController.text = _cardExpiryController.text.isEmpty
                  ? "--/--"
                  : _cardExpiryController.text;
              _cardHolderController.text = _cardHolderController.text.isEmpty
                  ? "NFC Card"
                  : _cardHolderController.text;
              _hasCardDetails = true;
            });
          }
          if (mounted) {
            Navigator.pop(context);
            showTopSnackBar(
              context,
              tagUid != null
                  ? "Card detected! UID saved."
                  : "Card detected! (no UID found)",
            );
          }
          NfcManager.instance.stopSession();
        } catch (e) {
          NfcManager.instance.stopSession();
        }
      },
    );
  }

  String? _extractTagUid(dynamic data) {
    if (data is! Map) {
      return null;
    }
    final candidates = [
      data['id'],
      data['identifier'],
      (data['nfca'] is Map ? (data['nfca'] as Map)['identifier'] : null),
      (data['mifareclassic'] is Map
          ? (data['mifareclassic'] as Map)['identifier']
          : null),
      (data['mifareultralight'] is Map
          ? (data['mifareultralight'] as Map)['identifier']
          : null),
    ];
    for (final candidate in candidates) {
      final hex = _bytesToHex(candidate);
      if (hex != null && hex.isNotEmpty) {
        return hex;
      }
    }
    return null;
  }

  String? _bytesToHex(dynamic value) {
    if (value is List) {
      final bytes = value.whereType<int>().toList();
      if (bytes.isEmpty) {
        return null;
      }
      return bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join()
          .toUpperCase();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.accountToEdit != null ? 'Edit Account' : 'New Account';

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          title,
          style: AppTypography.headlineMedium.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: _previousPage,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Always show the Live Card. The SingleChildScrollView handles the keyboard now.
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.sm,
              ),
              child: _buildLiveCard(),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _totalPages,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentPage == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? _selectedColor
                          : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (int page) =>
                    setState(() => _currentPage = page),
                children: [
                  _buildStep1CoreInfo(),
                  _buildStep2BankDetails(),
                  _buildStep3Appearance(),
                ],
              ),
            ),

            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1CoreInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Form(
        key: _step1Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step 1: Core Info',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.textSecondary,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text(
              'Current Balance',
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _balanceController,
              // REMOVED autofocus completely to prevent immediate keyboard launch/crash
              style: AppTypography.displayMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: '₹ ',
                prefixStyle: AppTypography.displayMedium.copyWith(
                  color: _selectedColor,
                  fontWeight: FontWeight.bold,
                ),
                hintStyle: TextStyle(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.cardElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  borderSide: BorderSide.none,
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Balance is required';
                }
                if (double.tryParse(value.trim()) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xl2),

            Text(
              'Account Details',
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: AccountType.values.map((type) {
                  final isSelected = _selectedType == type;
                  final typeString = type.toString().split('.').last;
                  final typeName = typeString.isNotEmpty
                      ? '${typeString[0].toUpperCase()}${typeString.substring(1)}'
                      : '';

                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      label: Text(typeName),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedType = type);
                        }
                      },
                      selectedColor: _selectedColor.withValues(alpha: 0.2),
                      backgroundColor: AppColors.cardElevated,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? _selectedColor
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected ? _selectedColor : Colors.transparent,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            _buildStandardTextField(
              controller: _nameController,
              hint: "Account Name (e.g. Personal Savings)",
              icon: Icons.label_outline,
              validator: (val) =>
                  val == null || val.isEmpty ? "Required" : null,
            ),
            // Bottom padding to ensure scrollable area clears the keyboard comfortably
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2BankDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Form(
        key: _step2Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step 2: Bank Details',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.textSecondary,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            _buildStandardTextField(
              controller: _bankNameController,
              hint: "Bank Name",
              icon: Icons.account_balance,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildStandardTextField(
                    controller: _accountNumberController,
                    hint: "A/C Last 4",
                    icon: Icons.numbers,
                    isNumber: true,
                    maxLength: 4,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildStandardTextField(
                    controller: _ifscCodeController,
                    hint: "IFSC Code",
                    icon: Icons.code,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3Appearance() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Form(
        key: _step3Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step 3: Card & Look',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.textSecondary,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Link Physical/Virtual Card?',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: _hasCardDetails,
                  activeThumbColor: _selectedColor,
                  onChanged: (val) => setState(() => _hasCardDetails = val),
                ),
              ],
            ),
            if (_hasCardDetails) ...[
              const SizedBox(height: AppSpacing.md),
              if (Platform.isAndroid) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _startNfcScan,
                    icon: const Icon(Icons.nfc),
                    label: const Text("Scan Card via NFC"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              _buildStandardTextField(
                controller: _cardNumberController,
                focusNode: _cardNumberFocus,
                hint: "Card Number",
                icon: Icons.credit_card,
                maxLength: 19,
                isNumber: true,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _buildStandardTextField(
                      controller: _cardExpiryController,
                      hint: "Expiry (MM/YY)",
                      icon: Icons.calendar_today,
                      maxLength: 5,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildStandardTextField(
                      controller: _cardCvvController,
                      hint: "CVV",
                      icon: Icons.lock_outline,
                      maxLength: 4,
                      isNumber: true,
                      obscureText: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _buildStandardTextField(
                controller: _cardHolderController,
                hint: "Card Holder Name",
                icon: Icons.person_outline,
              ),
            ],
            const SizedBox(height: AppSpacing.xl2),

            Text(
              'Color Theme',
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
                itemCount: _colorPalette.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, index) {
                  final color = _colorPalette[index];
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.6),
                                  blurRadius: 12,
                                ),
                              ]
                            : [],
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Text(
              'Account Icon',
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
                itemCount: _iconPalette.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, index) {
                  final icon = _iconPalette[index];
                  final isSelected = _selectedIcon == icon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _selectedColor
                            : AppColors.cardElevated,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.transparent,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.backgroundBlack,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _previousPage,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
              child: Text(
                _currentPage == 0 ? "Cancel" : "Back",
                style: AppTypography.titleSmall,
              ),
            ),

            ElevatedButton(
              onPressed: _isLoading ? null : _nextPage,
              style: ElevatedButton.styleFrom(
                // THE FIX: Overriding the global double.infinity width from AppTheme
                minimumSize: const Size(140, AppSpacing.buttonHeightMd),
                backgroundColor: _selectedColor,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl2,
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
                      _currentPage == _totalPages - 1
                          ? (widget.accountToEdit != null ? 'Save' : 'Create')
                          : 'Next',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    FocusNode? focusNode,
    bool isNumber = false,
    int? maxLength,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLength: maxLength,
      obscureText: obscureText,
      style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.cardElevated,
        counterText: "",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.sm,
          ),
          child: Icon(icon, color: AppColors.textSecondary),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildLiveCard() {
    final hasCardData = _cardNumberController.text.isNotEmpty;
    String displayCardNum = "**** **** **** ****";
    if (hasCardData) {
      displayCardNum = _cardNumberController.text;
    } else if (_accountNumberController.text.isNotEmpty) {
      displayCardNum =
          "**** **** **** ${_accountNumberController.text.padRight(4, '*').substring(0, 4.clamp(0, 4))}";
    }

    final bankLogo = LogoUtils.bankLogoFor(_bankNameController.text);
    final logoScale = LogoUtils.bankLogoScale(_bankNameController.text);

    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF111111),
            Colors.black.withValues(alpha: 0.8),
            const Color(0xFF0A0A0A).withValues(alpha: 0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _selectedColor.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: _selectedColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          if (bankLogo != null)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Opacity(
                  opacity: 0.15,
                  child: Center(
                    child: LogoUtils.buildLogo(bankLogo, size: 200 * logoScale),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _nameController.text.isNotEmpty
                            ? _nameController.text.toUpperCase()
                            : (_bankNameController.text.isNotEmpty
                                  ? _bankNameController.text.toUpperCase()
                                  : "NEW ACCOUNT"),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SlideTransition(
                      position: _logoSlideAnimation,
                      child: bankLogo != null
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: LogoUtils.buildLogo(bankLogo, size: 24),
                            )
                          : Icon(
                              _selectedIcon,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 24,
                            ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.sim_card, color: Colors.amber, size: 28),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.wifi,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 20,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayCardNum,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: "Monospace",
                        fontSize: 16,
                        letterSpacing: 2,
                        shadows: [Shadow(blurRadius: 2, color: Colors.black45)],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "BALANCE",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 8,
                              ),
                            ),
                            Text(
                              "₹${_balanceController.text.isEmpty ? '0.00' : _balanceController.text}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "EXPIRY",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 8,
                              ),
                            ),
                            Text(
                              _cardExpiryController.text.isEmpty
                                  ? "MM/YY"
                                  : _cardExpiryController.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _saveAccount() async {
    if (!_step3Key.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final balance = double.tryParse(_balanceController.text.trim()) ?? 0.0;
      final now = DateTime.now();
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

      final account = Account(
        id: widget.accountToEdit?.id ?? '',
        userId: userId,
        name: _nameController.text.trim(),
        type: _selectedType,
        balance: balance,
        color: _selectedColor,
        iconCodePoint: _selectedIcon.codePoint,
        iconFontFamily: _selectedIcon.fontFamily ?? 'MaterialIcons',
        bankName: _bankNameController.text.trim().isEmpty
            ? null
            : _bankNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim().isEmpty
            ? null
            : _accountNumberController.text.trim(),
        ifscCode: _ifscCodeController.text.trim().isEmpty
            ? null
            : _ifscCodeController.text.trim(),
        cardNumber: _hasCardDetails && _cardNumberController.text.isNotEmpty
            ? _cardNumberController.text.trim()
            : null,
        cardExpiry: _hasCardDetails && _cardExpiryController.text.isNotEmpty
            ? _cardExpiryController.text.trim()
            : null,
        cardHolderName: _hasCardDetails && _cardHolderController.text.isNotEmpty
            ? _cardHolderController.text.trim()
            : null,
        createdAt: widget.accountToEdit?.createdAt ?? now,
        updatedAt: now,
      );

      final provider = context.read<AccountProvider>();

      String accountId;
      if (widget.accountToEdit != null) {
        await provider.updateAccount(account);
        accountId = account.id;
      } else {
        await provider.addAccount(account);
        accountId = provider.accounts
            .firstWhere(
              (a) => a.name == account.name && a.userId == account.userId,
              orElse: () => account,
            )
            .id;
      }

      if (_hasCardDetails && _cardCvvController.text.isNotEmpty) {
        await _secureCardService.storeCvv(
          accountId,
          _cardCvvController.text.trim(),
        );
      } else if (accountId.isNotEmpty) {
        await _secureCardService.deleteCvv(accountId);
      }

      if (mounted) {
        showTopSnackBar(
          context,
          widget.accountToEdit != null
              ? "Account Updated"
              : "Account Created Successfully",
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(context, "Error: $e", isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

Future<void> navToAddAccountScreen(
  BuildContext context, {
  Account? accountToEdit,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ModernAddAccountScreen(accountToEdit: accountToEdit),
    ),
  );
}
