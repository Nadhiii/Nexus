import '../models/detected_transaction.dart';
import '../models/subscription.dart';
import '../models/debt.dart';
import '../models/investment.dart';

// ---------------------------------------------------------------------------
// Enums & Result Types
// ---------------------------------------------------------------------------

enum TransactionIntent {
  fuel,
  emiPayment,
  subscriptionPayment,
  investmentSip,
  salary,
  transfer,
  food,
  shopping,
  entertainment,
  medical,
  general,
}

extension TransactionIntentX on TransactionIntent {
  String get label {
    switch (this) {
      case TransactionIntent.fuel:
        return 'Fuel';
      case TransactionIntent.emiPayment:
        return 'EMI Payment';
      case TransactionIntent.subscriptionPayment:
        return 'Subscription';
      case TransactionIntent.investmentSip:
        return 'Investment / SIP';
      case TransactionIntent.salary:
        return 'Salary';
      case TransactionIntent.transfer:
        return 'Transfer';
      case TransactionIntent.food:
        return 'Food & Dining';
      case TransactionIntent.shopping:
        return 'Shopping';
      case TransactionIntent.entertainment:
        return 'Entertainment';
      case TransactionIntent.medical:
        return 'Medical';
      case TransactionIntent.general:
        return 'General Expense';
    }
  }

  String get icon {
    switch (this) {
      case TransactionIntent.fuel:
        return '⛽';
      case TransactionIntent.emiPayment:
        return '🏦';
      case TransactionIntent.subscriptionPayment:
        return '🔄';
      case TransactionIntent.investmentSip:
        return '📈';
      case TransactionIntent.salary:
        return '💰';
      case TransactionIntent.transfer:
        return '↔️';
      case TransactionIntent.food:
        return '🍽️';
      case TransactionIntent.shopping:
        return '🛍️';
      case TransactionIntent.entertainment:
        return '🎬';
      case TransactionIntent.medical:
        return '🏥';
      case TransactionIntent.general:
        return '💳';
    }
  }

  /// Whether this intent requires extra user input before saving
  bool get requiresExtraInput {
    switch (this) {
      case TransactionIntent.fuel:
      case TransactionIntent.emiPayment:
      case TransactionIntent.subscriptionPayment:
      case TransactionIntent.investmentSip:
        return true;
      default:
        return false;
    }
  }

  /// Whether this intent creates records in other modules
  bool get hasSideEffects {
    switch (this) {
      case TransactionIntent.fuel:
      case TransactionIntent.emiPayment:
      case TransactionIntent.subscriptionPayment:
      case TransactionIntent.investmentSip:
        return true;
      default:
        return false;
    }
  }
}

// ---------------------------------------------------------------------------

class ClassificationResult {
  final TransactionIntent intent;

  /// 0.0 – 1.0
  final double confidence;

  /// ID of the matched Subscription / Debt / Investment (if any)
  final String? matchedEntityId;
  final String? matchedEntityName;

  /// Suggested category string for the Finance transaction
  final String? suggestedCategory;

  const ClassificationResult({
    required this.intent,
    required this.confidence,
    this.matchedEntityId,
    this.matchedEntityName,
    this.suggestedCategory,
  });

  bool get isHighConfidence => confidence >= 0.80;
  bool get isMediumConfidence => confidence >= 0.55 && confidence < 0.80;
  bool get isLowConfidence => confidence < 0.55;

  String get confidenceLabel {
    if (isHighConfidence) return 'High';
    if (isMediumConfidence) return 'Medium';
    return 'Low';
  }

  ClassificationResult copyWith({
    TransactionIntent? intent,
    double? confidence,
    String? matchedEntityId,
    String? matchedEntityName,
    String? suggestedCategory,
  }) {
    return ClassificationResult(
      intent: intent ?? this.intent,
      confidence: confidence ?? this.confidence,
      matchedEntityId: matchedEntityId ?? this.matchedEntityId,
      matchedEntityName: matchedEntityName ?? this.matchedEntityName,
      suggestedCategory: suggestedCategory ?? this.suggestedCategory,
    );
  }
}

// ---------------------------------------------------------------------------
// Classifier
// ---------------------------------------------------------------------------

class TransactionIntentClassifier {
  // ── Fuel ──────────────────────────────────────────────────────────────────
  static const _fuelKeywords = [
    'petrol', 'diesel', 'fuel', 'hpcl', 'bpcl', 'iocl',
    'indian oil', 'hp petrol', 'hp pump', 'bharat petroleum',
    'shell', 'nayara', 'essar oil', 'pump', 'filling station',
    'fuel station', 'gas station', 'cng', 'lng',
  ];

  // ── EMI / Loan ─────────────────────────────────────────────────────────────
  static const _emiKeywords = [
    'emi', 'loan emi', 'loan payment', 'equated monthly',
    'emi debit', 'auto debit emi', 'nach debit', 'ecs debit',
  ];

  // ── Known subscription merchants ──────────────────────────────────────────
  static const _subscriptionMerchants = [
    'netflix', 'spotify', 'amazon prime', 'prime video',
    'hotstar', 'disney+', 'jiocinema', 'zee5', 'sonyliv',
    'youtube premium', 'youtube music', 'apple music',
    'apple tv', 'apple one', 'icloud', 'google one',
    'microsoft 365', 'office 365', 'adobe', 'canva',
    'notion', 'dropbox', 'nordvpn', 'expressvpn',
    'linkedin premium', 'swiggy one', 'zomato pro',
    'bigbasket', 'dunzo', 'blinkit', 'zepto',
  ];

  // ── Known SIP / investment merchants ──────────────────────────────────────
  static const _sipMerchants = [
    'zerodha', 'groww', 'kuvera', 'paytm money',
    'coin by zerodha', 'ppfas', 'axis mf', 'sbi mf',
    'hdfc mf', 'icici mf', 'nippon mf', 'mirae', 'motilal',
    'angel broking', 'upstox', 'smallcase', 'etmoney',
    'icicidirect', 'hdfcsec', 'kotak securities',
  ];
  static const _sipKeywords = [
    'sip', 'systematic investment', 'mutual fund', 'mf purchase',
    'nfo', 'nav', 'folio', 'units allotted', 'redemption',
  ];

  // ── Salary ─────────────────────────────────────────────────────────────────
  static const _salaryKeywords = [
    'salary', 'sal credit', 'payroll', 'stipend',
    'salary credited', 'salary credit', 'wages',
  ];

  // ── Transfer ───────────────────────────────────────────────────────────────
  static const _transferKeywords = [
    'neft', 'imps', 'rtgs', 'transfer to', 'self transfer',
    'own account', 'fund transfer', 'upi transfer',
  ];

  // ── Food ───────────────────────────────────────────────────────────────────
  static const _foodMerchants = [
    'zomato', 'swiggy', 'dominos', 'pizza hut', 'mcdonalds',
    'kfc', 'burger king', 'subway', 'starbucks', 'cafe coffee day',
    'dunkin', 'haldirams', 'barbeque nation', 'paradise',
  ];
  static const _foodKeywords = [
    'restaurant', 'hotel', 'cafe', 'canteen', 'food court',
    'dining', 'biryani', 'pizza', 'burger',
  ];

  // ── Shopping ───────────────────────────────────────────────────────────────
  static const _shoppingMerchants = [
    'amazon', 'flipkart', 'myntra', 'meesho', 'ajio',
    'nykaa', 'firstcry', 'tata cliq', 'snapdeal',
    'reliance digital', 'croma', 'vijay sales',
  ];

  // ── Entertainment ──────────────────────────────────────────────────────────
  static const _entertainmentKeywords = [
    'bookmyshow', 'pvr', 'inox', 'cinepolis', 'movie',
    'concert', 'event', 'ticket', 'gaming', 'steam',
  ];

  // ── Medical ────────────────────────────────────────────────────────────────
  static const _medicalKeywords = [
    'apollo', 'fortis', 'medplus', 'netmeds', 'pharmeasy',
    '1mg', 'clinic', 'hospital', 'pharmacy', 'medical',
    'doctor', 'diagnostic', 'lab', 'pathology',
  ];

  // ---------------------------------------------------------------------------

  /// Main entry point. Returns the best-guess [ClassificationResult].
  static ClassificationResult classify({
    required DetectedTransaction detected,
    required List<Subscription> subscriptions,
    required List<Debt> debts,
    required List<Investment> investments,
  }) {
    final merchant = detected.merchant.toLowerCase().trim();
    final category = (detected.detectedCategory ?? '').toLowerCase();
    final body = (detected.body ?? '').toLowerCase();
    final amount = detected.amount;
    final isExpense = detected.type.toLowerCase() == 'expense';
    final isIncome = detected.type.toLowerCase() == 'income';

    // Helper: combined text search space
    final searchText = '$merchant $category $body';

    // ── 1. SALARY (income override) ──────────────────────────────────────────
    if (isIncome && _containsAny(searchText, _salaryKeywords)) {
      return ClassificationResult(
        intent: TransactionIntent.salary,
        confidence: 0.90,
        suggestedCategory: 'Salary',
      );
    }

    // ── 2. TRANSFER ───────────────────────────────────────────────────────────
    if (_containsAny(searchText, _transferKeywords)) {
      return ClassificationResult(
        intent: TransactionIntent.transfer,
        confidence: 0.85,
        suggestedCategory: 'Transfer',
      );
    }

    // ── 3. FUEL ───────────────────────────────────────────────────────────────
    if (isExpense && _containsAny(searchText, _fuelKeywords)) {
      return ClassificationResult(
        intent: TransactionIntent.fuel,
        confidence: 0.88,
        suggestedCategory: 'Fuel',
      );
    }

    // ── 4. EMI — match against existing debts first ───────────────────────────
    if (isExpense) {
      final debtMatch = _matchDebt(merchant, amount, body, debts);
      if (debtMatch != null) return debtMatch;
    }

    // ── 5. SUBSCRIPTION — match existing, then known merchants ────────────────
    if (isExpense) {
      final subMatch = _matchSubscription(merchant, amount, subscriptions);
      if (subMatch != null) return subMatch;

      if (_containsAny(merchant, _subscriptionMerchants)) {
        return ClassificationResult(
          intent: TransactionIntent.subscriptionPayment,
          confidence: 0.78,
          suggestedCategory: 'Subscription',
        );
      }
    }

    // ── 6. INVESTMENT / SIP ───────────────────────────────────────────────────
    if (isExpense) {
      final sipMatch = _matchSip(merchant, amount, body, investments);
      if (sipMatch != null) return sipMatch;

      if (_containsAny(merchant, _sipMerchants) ||
          _containsAny(searchText, _sipKeywords)) {
        return ClassificationResult(
          intent: TransactionIntent.investmentSip,
          confidence: 0.75,
          suggestedCategory: 'Investment',
        );
      }
    }

    // ── 7. FOOD ───────────────────────────────────────────────────────────────
    if (_containsAny(merchant, _foodMerchants) ||
        _containsAny(searchText, _foodKeywords)) {
      return ClassificationResult(
        intent: TransactionIntent.food,
        confidence: 0.82,
        suggestedCategory: 'Food & Dining',
      );
    }

    // ── 8. SHOPPING ───────────────────────────────────────────────────────────
    if (_containsAny(merchant, _shoppingMerchants)) {
      return ClassificationResult(
        intent: TransactionIntent.shopping,
        confidence: 0.80,
        suggestedCategory: 'Shopping',
      );
    }

    // ── 9. ENTERTAINMENT ─────────────────────────────────────────────────────
    if (_containsAny(searchText, _entertainmentKeywords)) {
      return ClassificationResult(
        intent: TransactionIntent.entertainment,
        confidence: 0.78,
        suggestedCategory: 'Entertainment',
      );
    }

    // ── 10. MEDICAL ───────────────────────────────────────────────────────────
    if (_containsAny(searchText, _medicalKeywords)) {
      return ClassificationResult(
        intent: TransactionIntent.medical,
        confidence: 0.78,
        suggestedCategory: 'Medical',
      );
    }

    // ── Fallback ──────────────────────────────────────────────────────────────
    return ClassificationResult(
      intent: TransactionIntent.general,
      confidence: 0.40,
      suggestedCategory: detected.detectedCategory,
    );
  }

  // ---------------------------------------------------------------------------
  // Private matchers
  // ---------------------------------------------------------------------------

  static ClassificationResult? _matchDebt(
    String merchant,
    double amount,
    String body,
    List<Debt> debts,
  ) {
    // First pass: keyword match
    if (!_containsAny('$merchant $body', _emiKeywords)) return null;

    // Second pass: try to find a specific debt
    Debt? bestMatch;
    double bestScore = 0;

    for (final debt in debts.where((d) => d.currentBalance > 0)) {
      double score = 0;

      // Amount proximity (EMI match within 5%)
      if (debt.monthlyEMI != null && debt.monthlyEMI! > 0) {
        final diff = (amount - debt.monthlyEMI!).abs() / debt.monthlyEMI!;
        if (diff <= 0.05) {
          score += 0.5;
        } else if (diff <= 0.15) {
          score += 0.2;
        }
      }

      // Name match
      final debtName = debt.name.toLowerCase();
      final lender = (debt.lenderName ?? '').toLowerCase();
      if (merchant.contains(debtName) || debtName.contains(merchant)) {
        score += 0.35;
      } else if (merchant.contains(lender) || lender.contains(merchant)) {
        score += 0.25;
      }

      if (score > bestScore) {
        bestScore = score;
        bestMatch = debt;
      }
    }

    final baseConfidence = 0.65; // keyword already matched
    final entityConfidence = baseConfidence + (bestScore * 0.25);

    return ClassificationResult(
      intent: TransactionIntent.emiPayment,
      confidence: entityConfidence.clamp(0.0, 0.97),
      matchedEntityId: bestMatch?.id,
      matchedEntityName: bestMatch?.name,
      suggestedCategory: 'EMI / Loan',
    );
  }

  static ClassificationResult? _matchSubscription(
    String merchant,
    double amount,
    List<Subscription> subscriptions,
  ) {
    Subscription? bestMatch;
    double bestScore = 0;

    for (final sub in subscriptions.where((s) => s.isActive)) {
      double score = 0;
      final subName = sub.name.toLowerCase();

      // Amount match within 5%
      final diff = (amount - sub.amount).abs();
      final tolerance = sub.amount * 0.05;
      if (diff <= tolerance) {
        score += 0.45;
      } else if (diff <= sub.amount * 0.15) {
        score += 0.2;
      }

      // Name match
      if (merchant.contains(subName) || subName.contains(merchant)) {
        score += 0.45;
      } else {
        // Word-level match
        final words = subName.split(RegExp(r'\s+'));
        for (final w in words) {
          if (w.length > 2 && merchant.contains(w)) score += 0.15;
        }
      }

      if (score > bestScore) {
        bestScore = score;
        bestMatch = sub;
      }
    }

    if (bestScore >= 0.55) {
      return ClassificationResult(
        intent: TransactionIntent.subscriptionPayment,
        confidence: (0.55 + bestScore * 0.4).clamp(0.0, 0.97),
        matchedEntityId: bestMatch?.id,
        matchedEntityName: bestMatch?.name,
        suggestedCategory: 'Subscription',
      );
    }
    return null;
  }

  static ClassificationResult? _matchSip(
    String merchant,
    double amount,
    String body,
    List<Investment> investments,
  ) {
    if (!_containsAny('$merchant $body', _sipKeywords) &&
        !_containsAny(merchant, _sipMerchants)) {
      return null;
    }

    Investment? bestMatch;
    double bestScore = 0;

    for (final inv in investments.where((i) => i.isActive && i.sipAmount > 0)) {
      double score = 0;
      final invName = inv.name.toLowerCase();

      // SIP amount match
      final diff = (amount - inv.sipAmount).abs() / inv.sipAmount;
      if (diff <= 0.05) {
        score += 0.5;
      } else if (diff <= 0.15) {
        score += 0.2;
      }

      // Name match
      if (merchant.contains(invName) || invName.contains(merchant)) {
        score += 0.4;
      }

      if (score > bestScore) {
        bestScore = score;
        bestMatch = inv;
      }
    }

    return ClassificationResult(
      intent: TransactionIntent.investmentSip,
      confidence: (0.60 + bestScore * 0.35).clamp(0.0, 0.97),
      matchedEntityId: bestMatch?.id,
      matchedEntityName: bestMatch?.name,
      suggestedCategory: 'Investment',
    );
  }

  // ---------------------------------------------------------------------------
  // Utilities
  // ---------------------------------------------------------------------------

  static bool _containsAny(String text, List<String> keywords) {
    for (final kw in keywords) {
      if (text.contains(kw)) return true;
    }
    return false;
  }
}