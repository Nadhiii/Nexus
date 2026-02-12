import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nfc_manager/nfc_manager.dart';
// Note: Do not import platform_tags.dart manually
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/account_provider.dart';
import '../../core/models/account.dart';
import '../../core/widgets/top_snackbar.dart';
import '../../core/services/secure_card_service.dart';

/// Backward compatibility alias
typedef ModernAddAccountScreen = AddAccountModal;

class AddAccountModal extends StatefulWidget {
  final Account? accountToEdit;

  const AddAccountModal({super.key, this.accountToEdit});

  @override
  State<AddAccountModal> createState() => _AddAccountModalState();
}

class _AddAccountModalState extends State<AddAccountModal>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  final _formKey = GlobalKey<FormState>();

  // Basic Account Controllers
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();

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
    const Color(0xFF00E676), // Neon Green
    const Color(0xFFFFEA00), // Neon Yellow
    const Color(0xFFFF3D00), // Neon Orange
    const Color(0xFFD500F9), // Neon Purple
    const Color(0xFF2979FF), // Bright Blue
    const Color(0xFF607D8B), // Blue Grey
    const Color(0xFF37474F), // Dark Slate
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

    // Animation setup
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

    // Edit mode initialization
    if (widget.accountToEdit != null) {
      final account = widget.accountToEdit!;
      _nameController.text = account.name;
      _balanceController.text = account.balance.toString();
      _bankNameController.text = account.bankName ?? '';
      _accountNumberController.text = account.accountNumber ?? '';

      _cardNumberController.text = account.cardNumber ?? '';
      _cardExpiryController.text = account.cardExpiry ?? '';
      // CVV is loaded from secure storage, not from account model
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
  }

  Future<void> _loadSecureCvv(String accountId) async {
    final cvv = await _secureCardService.getCvv(accountId);
    if (cvv != null && mounted) {
      setState(() {
        _cardCvvController.text = cvv;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _balanceController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _cardHolderController.dispose();
    _cardNumberFocus.dispose();
    super.dispose();
  }

  // --- NFC LOGIC START ---

  Future<void> _startNfcScan() async {
    if (!Platform.isAndroid) return;

    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      if (mounted) {
        showTopSnackBar(context, "NFC is not available", isError: true);
      }
      return;
    }

    if (mounted) {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.cardSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => Container(
          padding: const EdgeInsets.all(24),
          height: 300,
          child: Column(
            children: [
              const Icon(Icons.contactless, size: 64, color: Colors.blue),
              const SizedBox(height: 16),
              const Text(
                "Hold Card to Back",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
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
      ).whenComplete(() {
        NfcManager.instance.stopSession();
      });
    }

    NfcManager.instance.startSession(
      pollingOptions: const {NfcPollingOption.iso14443},
      onDiscovered: (NfcTag tag) async {
        try {
          // Extract tag UID - simple, no complex EMV parsing needed
          // ignore: invalid_use_of_protected_member
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
    if (data is! Map) return null;
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
      if (hex != null && hex.isNotEmpty) return hex;
    }
    return null;
  }

  String? _bytesToHex(dynamic value) {
    if (value is List) {
      final bytes = value.whereType<int>().toList();
      if (bytes.isEmpty) return null;
      return bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join()
          .toUpperCase();
    }
    return null;
  }

  // --- NFC LOGIC END ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Backdrop blur
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
          // Centered modal container
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
                      // Title
                      Text(
                        widget.accountToEdit != null
                            ? "Edit Account"
                            : "New Account",
                        style: AppTypography.headlineSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Scrollable content
                      Expanded(
                        child: SingleChildScrollView(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 1. LIVE PREVIEW CARD
                                _buildLiveCard(),
                                const SizedBox(height: 32),

                                // 2. DETAILS
                                _buildLabel("ACCOUNT DETAILS"),
                                _buildGlassTextField(
                                  controller: _nameController,
                                  hint: "Account Name (e.g. HDFC Salary)",
                                  icon: Icons.label_outline,
                                ),
                                const SizedBox(height: 16),
                                _buildGlassTextField(
                                  controller: _balanceController,
                                  hint: "Current Balance (₹)",
                                  icon: Icons.currency_rupee,
                                  isNumber: true,
                                ),

                                const SizedBox(height: 24),

                                // 3. CARD DETAILS (OPTIONAL)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildLabel("CARD DETAILS (OPTIONAL)"),
                                    Switch(
                                      value: _hasCardDetails,
                                      activeColor: _selectedColor,
                                      onChanged: (val) {
                                        setState(() => _hasCardDetails = val);
                                      },
                                    ),
                                  ],
                                ),

                                if (_hasCardDetails) ...[
                                  const SizedBox(height: 8),

                                  // NFC Scan button (Android only)
                                  if (Platform.isAndroid) ...[
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: _startNfcScan,
                                        icon: const Icon(Icons.nfc),
                                        label: const Text(
                                          "Scan Card (Experimental)",
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          side: BorderSide(
                                            color: Colors.white.withOpacity(
                                              0.3,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  _buildGlassTextField(
                                    controller: _cardNumberController,
                                    focusNode: _cardNumberFocus,
                                    hint: "Card Number",
                                    icon: Icons.credit_card,
                                    maxLength: 19,
                                    isNumber: true,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildGlassTextField(
                                          controller: _cardExpiryController,
                                          hint: "Expiry (MM/YY)",
                                          icon: Icons.calendar_today,
                                          maxLength: 5,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildGlassTextField(
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
                                  const SizedBox(height: 16),
                                  _buildGlassTextField(
                                    controller: _cardHolderController,
                                    hint: "Card Holder Name",
                                    icon: Icons.person_outline,
                                  ),
                                ],

                                const SizedBox(height: 24),

                                // 4. APPEARANCE
                                _buildLabel("APPEARANCE"),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 50,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _colorPalette.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 12),
                                    itemBuilder: (context, index) {
                                      final color = _colorPalette[index];
                                      final isSelected =
                                          _selectedColor == color;
                                      return GestureDetector(
                                        onTap: () => setState(
                                          () => _selectedColor = color,
                                        ),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.transparent,
                                              width: 3,
                                            ),
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                      color: color.withOpacity(
                                                        0.6,
                                                      ),
                                                      blurRadius: 12,
                                                    ),
                                                  ]
                                                : [],
                                          ),
                                          child: isSelected
                                              ? const Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                )
                                              : null,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 50,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _iconPalette.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 12),
                                    itemBuilder: (context, index) {
                                      final icon = _iconPalette[index];
                                      final isSelected = _selectedIcon == icon;
                                      return GestureDetector(
                                        onTap: () => setState(
                                          () => _selectedIcon = icon,
                                        ),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? _selectedColor
                                                : AppColors.cardSurface,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? Colors.white.withOpacity(
                                                      0.5,
                                                    )
                                                  : Colors.white.withOpacity(
                                                      0.1,
                                                    ),
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

                                const SizedBox(height: 24),

                                // 5. BANK INFO
                                _buildLabel("BANK INFO"),
                                _buildGlassTextField(
                                  controller: _bankNameController,
                                  hint: "Bank Name",
                                  icon: Icons.account_balance,
                                ),
                                const SizedBox(height: 16),
                                _buildGlassTextField(
                                  controller: _accountNumberController,
                                  hint: "Account Number (Last 4)",
                                  icon: Icons.numbers,
                                  maxLength: 4,
                                  isNumber: true,
                                ),

                                const SizedBox(height: 40),

                                // 6. SAVE BUTTON (border style)
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _saveAccount,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.cardSurface,
                                      foregroundColor: _selectedColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                        side: BorderSide(
                                          color: _selectedColor.withOpacity(
                                            0.3,
                                          ),
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
                                              color: _selectedColor,
                                            ),
                                          )
                                        : const Text(
                                            "Save Account",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // 7. CANCEL BUTTON
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

  // --- WIDGETS ---

  Widget _buildLiveCard() {
    final hasCardData = _cardNumberController.text.isNotEmpty;
    String displayCardNum = "**** **** **** ****";
    if (hasCardData) {
      displayCardNum = _cardNumberController.text;
    } else if (_accountNumberController.text.isNotEmpty) {
      displayCardNum =
          "**** **** **** ${_accountNumberController.text.padRight(4, '*').substring(0, 4.clamp(0, 4))}";
    }

    return Container(
      height: 180,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _selectedColor,
            _selectedColor.withOpacity(0.6),
            Colors.black.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _selectedColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _bankNameController.text.isEmpty
                      ? (_nameController.text.isEmpty
                            ? "New Account"
                            : _nameController.text)
                      : _bankNameController.text.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                _selectedIcon,
                color: Colors.white.withOpacity(0.8),
                size: 24,
              ),
            ],
          ),

          Row(
            children: [
              const Icon(Icons.sim_card, color: Colors.amber, size: 28),
              const SizedBox(width: 8),
              Icon(Icons.wifi, color: Colors.white.withOpacity(0.5), size: 20),
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
                          color: Colors.white.withOpacity(0.6),
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
                          color: Colors.white.withOpacity(0.6),
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

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    FocusNode? focusNode,
    bool isNumber = false,
    int? maxLength,
    bool obscureText = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(30), // Pill shape
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLength: maxLength,
        obscureText: obscureText,
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
          counterText: "",
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            if (hint.contains("Account Name") || hint.contains("Balance")) {
              return "Required";
            }
          }
          return null;
        },
      ),
    );
  }

  void _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

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

        cardNumber: _hasCardDetails && _cardNumberController.text.isNotEmpty
            ? _cardNumberController.text.trim()
            : null,
        cardExpiry: _hasCardDetails && _cardExpiryController.text.isNotEmpty
            ? _cardExpiryController.text.trim()
            : null,
        // CVV is stored securely, not in Firestore
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
        // Get the newly created account's ID
        accountId = provider.accounts
            .firstWhere(
              (a) => a.name == account.name && a.userId == account.userId,
              orElse: () => account,
            )
            .id;
      }

      // Store CVV securely (locally only, never in cloud)
      if (_hasCardDetails && _cardCvvController.text.isNotEmpty) {
        await _secureCardService.storeCvv(
          accountId,
          _cardCvvController.text.trim(),
        );
      } else if (accountId.isNotEmpty) {
        // If CVV was cleared, remove from secure storage
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
      if (mounted) showTopSnackBar(context, "Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

/// Shows the Add Account Modal with floating design
Future<void> showAddAccountModal(
  BuildContext context, {
  Account? accountToEdit,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, __, ___) =>
          AddAccountModal(accountToEdit: accountToEdit),
    ),
  );
}
