import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/account_provider.dart';
import '../../core/models/account.dart';
import '../../core/widgets/top_snackbar.dart';

class ModernAddAccountScreen extends StatefulWidget {
  final Account? accountToEdit;

  const ModernAddAccountScreen({super.key, this.accountToEdit});

  @override
  State<ModernAddAccountScreen> createState() => _ModernAddAccountScreenState();
}

class _ModernAddAccountScreenState extends State<ModernAddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();

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
    if (widget.accountToEdit != null) {
      final account = widget.accountToEdit!;
      _nameController.text = account.name;
      _balanceController.text = account.balance.toString();
      _bankNameController.text = account.bankName ?? '';
      _accountNumberController.text = account.accountNumber ?? '';
      _selectedType = account.type;
      _selectedColor = account.color;
      _selectedIcon = account.icon;
    }

    _nameController.addListener(() => setState(() {}));
    _balanceController.addListener(() => setState(() {}));
    _accountNumberController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBlack,
        elevation: 0,
        centerTitle: true,
        // FIXED TITLE HERE
        title: Text(
          widget.accountToEdit != null ? 'Edit Account' : 'Add Account',
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _buildLiveCard()),
              const SizedBox(height: 32),

              Text("DETAILS", style: _headerStyle()),
              const SizedBox(height: 16),

              _buildGlassTextField(
                controller: _nameController,
                label: "Account Name",
                icon: Icons.label_outline,
                hint: "e.g. HDFC Salary",
              ),
              const SizedBox(height: 16),
              _buildGlassTextField(
                controller: _balanceController,
                label: "Current Balance",
                icon: Icons.currency_rupee,
                hint: "0.00",
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),

              const SizedBox(height: 32),
              Text("APPEARANCE", style: _headerStyle()),
              const SizedBox(height: 16),

              // Color Picker
              SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _colorPalette.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
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
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.6),
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

              const SizedBox(height: 16),

              // Icon Picker
              SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _iconPalette.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
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
                              : AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Colors.white.withOpacity(0.5)
                                : Colors.white.withOpacity(0.1),
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

              const SizedBox(height: 32),
              Text("BANK INFO (OPTIONAL)", style: _headerStyle()),
              const SizedBox(height: 16),
              _buildGlassTextField(
                controller: _bankNameController,
                label: "Bank Name",
                icon: Icons.account_balance,
              ),
              const SizedBox(height: 16),
              _buildGlassTextField(
                controller: _accountNumberController,
                label: "Last 4 Digits",
                icon: Icons.numbers,
                maxLength: 4,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedColor,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: _selectedColor.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Save Account",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildLiveCard() {
    final displayNum = _accountNumberController.text
        .padRight(4, '*')
        .substring(0, 4.clamp(0, 4));

    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
              Text(
                _nameController.text.isEmpty
                    ? "New Account"
                    : _nameController.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                _selectedIcon,
                color: Colors.white.withOpacity(0.8),
                size: 28,
              ),
            ],
          ),

          Row(
            children: [
              const Icon(Icons.sim_card, color: Colors.amber, size: 32),
              const SizedBox(width: 8),
              Icon(Icons.wifi, color: Colors.white.withOpacity(0.5), size: 24),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "BALANCE",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    "₹${_balanceController.text.isEmpty ? '0.00' : _balanceController.text}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                "**** $displayNum",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontFamily: "Monospace",
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle() {
    return AppTypography.labelSmall.copyWith(
      color: AppColors.textTertiary,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.2,
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.textSecondary),
          labelStyle: TextStyle(color: AppColors.textTertiary),
          hintStyle: TextStyle(color: AppColors.textTertiary.withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          counterText: "",
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            if (label == "Account Name" || label == "Current Balance") {
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
        createdAt: widget.accountToEdit?.createdAt ?? now,
        updatedAt: now,
      );

      final provider = context.read<AccountProvider>();

      if (widget.accountToEdit != null) {
        await provider.updateAccount(account);
      } else {
        await provider.addAccount(account);
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
