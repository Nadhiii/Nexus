import '../../../core/models/debt.dart';
import '../../../core/utils/logo_utils.dart';

class DebtLogoUtils {
  static String bankIdentityFromParts({
    String? lenderName,
    String? name,
    String? customTypeName,
    String? notes,
  }) {
    final tokens = <String?>[
      lenderName,
      name,
      customTypeName,
      notes,
    ].whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty);

    return tokens.join(' ');
  }

  static String bankIdentityForDebt(Debt debt) {
    return bankIdentityFromParts(
      lenderName: debt.lenderName,
      name: debt.name,
      customTypeName: debt.customTypeName,
      notes: debt.notes,
    );
  }

  static String? bankLogoForDebt(Debt debt) {
    return LogoUtils.bankLogoFor(bankIdentityForDebt(debt));
  }

  static double bankLogoScaleForDebt(Debt debt) {
    return LogoUtils.bankLogoScale(bankIdentityForDebt(debt));
  }

  static String? bankLogoForParts({
    String? lenderName,
    String? name,
    String? customTypeName,
    String? notes,
  }) {
    return LogoUtils.bankLogoFor(
      bankIdentityFromParts(
        lenderName: lenderName,
        name: name,
        customTypeName: customTypeName,
        notes: notes,
      ),
    );
  }

  static double bankLogoScaleForParts({
    String? lenderName,
    String? name,
    String? customTypeName,
    String? notes,
  }) {
    return LogoUtils.bankLogoScale(
      bankIdentityFromParts(
        lenderName: lenderName,
        name: name,
        customTypeName: customTypeName,
        notes: notes,
      ),
    );
  }
}
