import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/detected_transaction.dart';
import '../services/smart_category_resolver.dart';

// ---------------------------------------------------------------------------
// Internal parse result ΓÇö built before constructing DetectedTransaction
// ---------------------------------------------------------------------------
class _ParseResult {
  final double amount;
  final String type; // 'expense' | 'income'
  final String merchant;
  final String? bankName; // e.g. "HDFC Bank" - identified source bank
  final String? accountNumber; // last-4 digits if present
  final double? balance; // available/closing balance if present
  final double confidence;
  final List<String> warnings;

  const _ParseResult({
    required this.amount,
    required this.type,
    required this.merchant,
    this.bankName,
    this.accountNumber,
    this.balance,
    this.confidence = 0.8,
    this.warnings = const [],
  });
}

// ---------------------------------------------------------------------------
// Ignorable-rule helpers
// ---------------------------------------------------------------------------
typedef _Predicate = bool Function(String lower);

/// A named ignore rule ΓÇö the name lets you log *which* rule dropped a message.
class _IgnoreRule {
  final String name;
  final _Predicate matches;
  const _IgnoreRule(this.name, this.matches);
}

// ---------------------------------------------------------------------------
// Bank / fintech template
// ---------------------------------------------------------------------------

/// Sender-specific parsing overrides.  Only [senderPrefixes] is mandatory;
/// the rest fall back to the shared generic logic in [NewSmsParser].
class _BankTemplate {
  /// TRAI sender codes (without the 2-letter circle prefix).
  /// e.g. "HDFCBK" matches both "AD-HDFCBK" and "VM-HDFCBK".
  final List<String> senderPrefixes;

  /// Human-readable bank name shown on the review card, e.g. "HDFC Bank".
  final String displayName;

  /// Amount regex override. Group 1 must be the raw numeric string.
  final RegExp? amountPattern;

  /// Merchant extractor override. Return null to fall through to generic logic.
  final String? Function(String body)? extractMerchant;

  const _BankTemplate({
    required this.senderPrefixes,
    required this.displayName,
    this.amountPattern,
    this.extractMerchant,
  });
}

// ---------------------------------------------------------------------------
// Main parser
// ---------------------------------------------------------------------------
class NewSmsParser {
  // ΓöÇΓöÇ Public API ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

  /// Synchronous ΓÇö safe inside a [compute()] isolate.
  static DetectedTransaction? parseSync(
    String id,
    String body,
    String sender,
    DateTime date,
  ) {
    final cleanBody = body.replaceAll(RegExp(r'[\n\r]+'), ' ').trim();
    final lower = cleanBody.toLowerCase();

    // Gate 1: is this an ignorable non-transaction message?
    final ignoreReason = _ignoreReason(lower);
    if (ignoreReason != null) return null;

    // Gate 2: does this look like a confirmed money movement?
    if (!_isConfirmedTransaction(lower)) return null;

    final result = _extractFields(cleanBody, lower, sender);
    if (result == null) return null;

    final detectedCategory = SmartCategoryResolver.resolve(
      merchant: result.merchant,
      body: body,
      amount: result.amount,
      transactionType: result.type,
    );

    return DetectedTransaction(
      id: id,
      fingerprint: _fingerprint(sender, date, body),
      amount: result.amount,
      merchant: result.merchant,
      date: date,
      type: result.type,
      source: 'sms',
      body: body,
      confidence: result.confidence,
      warnings: result.warnings,
      detectedCategory: detectedCategory,
      bankName: result.bankName,
      balanceAfter: result.balance,
      accountNumber: result.accountNumber,
    );
  }

  /// Async wrapper for call-sites that need [Future] semantics.
  static Future<DetectedTransaction?> parse(
    String id,
    String body,
    String sender,
    DateTime date,
  ) async =>
      parseSync(id, body, sender, date);

  // ΓöÇΓöÇ Gate 2: confirmed-transaction allowlist ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  //
  // We flip the logic: instead of trying to blocklist every possible
  // non-transaction, we require at least ONE confirmed-movement keyword.
  // "Payment is successful at merchant" does NOT contain any of these ΓåÆ
  // it gets dropped even though it has an amount.

  static final RegExp _confirmedMovementPattern = RegExp(
    r'\b('
    r'sent|received|debited|credited|'
    r'transferred|withdrawn|deposited|'
    r'purchase(?:d)?|spent|'
    r'refund(?:ed)?|cashback credited'
    r')\b',
    caseSensitive: false,
  );

  static bool _isConfirmedTransaction(String lower) =>
      _confirmedMovementPattern.hasMatch(lower);

  // ΓöÇΓöÇ Ignore rules ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  //
  // These run BEFORE the confirmed-movement check so truly ignorable messages
  // (e.g. OTPs that happen to contain "sent") are dropped first.

  static final List<_IgnoreRule> _ignoreRules = [
    // Security / auth
    // IMPORTANT: this rule runs BEFORE the confirmed-movement check
    // (see class comment), specifically so genuine OTP-delivery SMS
    // get dropped even if they happen to contain a movement word like
    // "sent" (e.g. "OTP sent for your login"). But most real bank
    // transaction SMS *also* carry a disclaimer like "Do not share
    // OTP/PIN with anyone" ΓÇö a bare `contains('otp')` would wrongly
    // drop those too. So: always drop messages that actually deliver
    // an OTP (code adjacent to the word), but for a bare mention of
    // OTP/PIN/verification-code with no code attached, only drop it
    // if there's no confirmed movement keyword elsewhere in the body.
    _IgnoreRule(
      'otp',
      (s) {
        final deliversOtp = RegExp(
              r'\d{4,8}\s+is\s+(?:your\s+)?(?:otp|one[\s-]?time\s+password|verification\s+code)',
            ).hasMatch(s) ||
            RegExp(
              r'\b(?:otp|one[\s-]?time\s+password|verification\s+code)\b\s*(?:is|:)?\s*\d{4,8}\b',
            ).hasMatch(s) ||
            RegExp(r'\buse\s+otp\s*\d{4,8}\b').hasMatch(s);
        if (deliversOtp) return true;

        final mentionsOtp = s.contains('otp') ||
            s.contains('one time password') ||
            s.contains('is your code') ||
            s.contains('verification code');
        if (!mentionsOtp) return false;

        // Bare disclaimer mention ΓÇö only ignorable if nothing here
        // actually looks like a completed transaction.
        return !_confirmedMovementPattern.hasMatch(s);
      },
    ),

    // Failed / declined / reversed ΓÇö no money moved
    _IgnoreRule(
      'failed_or_reversed',
      (s) =>
          s.contains('failed') ||
          s.contains('declined') ||
          s.contains('could not process') ||
          s.contains('reversed') ||
          s.contains('reversal'),
    ),

    // Mandate / AutoPay setup ΓÇö no money moved yet
    // Covers: "mandate created", "autopay created/registered/set up",
    //         "nach registered", "e-mandate", "aspresented frequency" etc.
    _IgnoreRule(
      'mandate_setup',
      (s) =>
          s.contains('e-mandate') ||
          s.contains('upi-mandate') ||
          s.contains('created a mandate') ||
          s.contains('frequency') || // autopay schedule SMS always has this
          (s.contains('mandate') &&
              (s.contains('success') ||
                  s.contains('registered') ||
                  s.contains('activated') ||
                  s.contains('created'))) ||
          (s.contains('autopay') &&
              (s.contains('created') ||
                  s.contains('registered') ||
                  s.contains('set up') ||
                  s.contains('setup'))) ||
          (s.contains('nach') &&
              (s.contains('registered') || s.contains('set') || s.contains('created'))),
    ),

    // Future / pending ΓÇö no money has moved yet
    _IgnoreRule(
      'future_debit',
      (s) =>
          s.contains('will be debited') ||
          s.contains('scheduled for') ||
          s.contains('request received') ||
          s.contains('trying to collect') ||
          s.contains('requested for') ||
          s.contains('payment initiated'),
    ),

    // Limit / threshold changes
    _IgnoreRule(
      'limit_change',
      (s) =>
          (s.contains('credit limit') &&
              (s.contains('set') || s.contains('updated') || s.contains('enhanced'))) ||
          s.contains('spending limit'),
    ),

    // Marketing
    _IgnoreRule(
      'marketing',
      (s) =>
          s.contains('apply now') ||
          s.contains('pre-approved') ||
          s.contains('exclusive offer') ||
          // generic "offer" only if cashback/reward aren't also present
          (s.contains('offer') &&
              !s.contains('cashback credited') &&
              !s.contains('reward')),
    ),

    // Balance-only enquiry (no transaction keyword)
    _IgnoreRule(
      'balance_only',
      (s) =>
          (s.contains('available balance') || s.contains('avl bal')) &&
          !_confirmedMovementPattern.hasMatch(s),
    ),
  ];

  /// Returns the rule name that matched, or null if the message is NOT ignorable.
  static String? _ignoreReason(String lower) {
    for (final rule in _ignoreRules) {
      if (rule.matches(lower)) return rule.name;
    }
    return null;
  }

  // ΓöÇΓöÇ Bank / fintech templates ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

  static final List<_BankTemplate> _bankTemplates = [
    // ΓöÇΓöÇ HDFC Bank ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
    // "Rs.500.00 debited from a/c **1234 on 12-Jun-25 to VPA merchant@upi"
    _BankTemplate(
      senderPrefixes: ['HDFCBK', 'HDFCBA', 'HDFCBN', 'HDFCCC', 'HDFCDC', 'HDFCHI', 'PAYZAP'],
      displayName: 'HDFC Bank',
      amountPattern: RegExp(r'Rs\.?\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false),
      extractMerchant: (body) {
        // Prefer explicit "to VPA xyz@bank"
        final vpa = RegExp(
          r'\bto\s+VPA\s+([a-zA-Z0-9.\-_]+@[a-zA-Z]{2,})',
          caseSensitive: false,
        ).firstMatch(body);
        if (vpa != null) return vpa.group(1)!.toLowerCase();

        // "to <name>. Ref" or "to <name> Ref"
        final to = RegExp(
          r'\bto\s+([A-Za-z0-9 &.\-]{2,40}?)(?:\.\s*Ref|\bRef\b|\.?\s*$)',
          caseSensitive: false,
        ).firstMatch(body);
        return to?.group(1)?.trim();
      },
    ),

    // ΓöÇΓöÇ ICICI Bank ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
    // "ICICI Bank Acct XX1234 debited for Rs 500.00 on 12-Jun-25; info: Swiggy"
    _BankTemplate(
      senderPrefixes: ['ICICIB', 'ICICIH', 'ICICIBNK', 'ISRVCE'],
      displayName: 'ICICI Bank',
      amountPattern: RegExp(r'(?:Rs\.?|INR)\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false),
      extractMerchant: (body) {
        final info = RegExp(
          r'(?:info[:\s]+|merchant[:\s]+)([A-Za-z0-9 &.\-]{2,40})',
          caseSensitive: false,
        ).firstMatch(body);
        if (info != null) return info.group(1)!.trim();

        final at = RegExp(
          r'\bat\s+([A-Za-z0-9 &.\-]{2,40}?)(?:\s+on\b|\s+Ref|\.|$)',
          caseSensitive: false,
        ).firstMatch(body);
        return at?.group(1)?.trim();
      },
    ),

    // ΓöÇΓöÇ SBI ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
    // "Your A/c X1234 is debited with INR 500.00 on 12Jun25..."
    _BankTemplate(
      senderPrefixes: ['SBIINB', 'SBIPAY', 'SBIATM', 'SBIUPI', 'SBIBNK', 'SBISMS', 'ATMSBI'],
      displayName: 'SBI',
      amountPattern: RegExp(r'(?:INR|Rs\.?|Γé╣)\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false),
      extractMerchant: (body) {
        final to = RegExp(
          r'(?:transferred to|paid to|transfer to|to)\s+([A-Za-z0-9 &.\-]{2,40}?)(?:\s+Ref|\s+UPI|\.|$)',
          caseSensitive: false,
        ).firstMatch(body);
        return to?.group(1)?.trim();
      },
    ),

    // ΓöÇΓöÇ Axis Bank ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
    _BankTemplate(
      senderPrefixes: ['AXISBK', 'AXISIN', 'AXISB', 'AXISHR', 'AXISMR'],
      displayName: 'Axis Bank',
      extractMerchant: (body) {
        final at = RegExp(
          r'(?:at|to)\s+([A-Za-z0-9 &.\-]{2,40}?)(?:\s+on\b|\s+Ref|\s+UPI|\.|$)',
          caseSensitive: false,
        ).firstMatch(body);
        return at?.group(1)?.trim();
      },
    ),

    // ΓöÇΓöÇ Kotak Mahindra ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
    _BankTemplate(
      senderPrefixes: ['KOTAKB', 'KOTAKP', 'KTKBNK', 'KTKREM'],
      displayName: 'Kotak Mahindra Bank',
      extractMerchant: (body) {
        final at = RegExp(
          r'(?:at|to)\s+([A-Za-z0-9 &.\-]{2,40}?)(?:\s+on\b|\s+Ref|\.|$)',
          caseSensitive: false,
        ).firstMatch(body);
        return at?.group(1)?.trim();
      },
    ),

    // ΓöÇΓöÇ Federal Bank ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
    // "INR 500.00 sent from your Federal Bank A/C to <merchant>.Ref..."
    _BankTemplate(
      senderPrefixes: ['FEDBNK', 'FEDADV'],
      displayName: 'Federal Bank',
      extractMerchant: (body) {
        final to = RegExp(
          r'\b(?:sent|paid|debited|transferred)\b.{0,30}?\bto\s+([A-Za-z0-9 &.\-]{2,50}?)(?:\.Ref|\s+Ref|\.?\s+on\b|\.|$)',
          caseSensitive: false,
        ).firstMatch(body);
        return to?.group(1)?.trim();
      },
    ),

    // ΓöÇΓöÇ IDFC First ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
    _BankTemplate(
      senderPrefixes: ['IDFCBK', 'IDFCFB', 'IDFCIT'],
      displayName: 'IDFC FIRST Bank',
      extractMerchant: (body) {
        final at = RegExp(
          r'\bat\s+([A-Za-z0-9 &.\-]{2,40}?)(?:\s+on\b|\s+Ref|\.|$)',
          caseSensitive: false,
        ).firstMatch(body);
        return at?.group(1)?.trim();
      },
    ),

    // ΓöÇΓöÇ IndusInd ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
    _BankTemplate(
      senderPrefixes: ['INDUSB', 'INDUSA', 'INDUSO'],
      displayName: 'IndusInd Bank',
      extractMerchant: (body) {
        final at = RegExp(
          r'(?:at|to)\s+([A-Za-z0-9 &.\-]{2,40}?)(?:\s+on\b|\s+Ref|\.|$)',
          caseSensitive: false,
        ).firstMatch(body);
        return at?.group(1)?.trim();
      },
    ),

    // ΓöÇΓöÇ slice (neobank) ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
    // Expense: "Rs. 403.98 sent from a/c xx8047 on 10-Jun-26 to ZOMATO (UPI Ref: ΓÇª)"
    // Income:  "Rs. 1,000 received in slice A/c xx8047 on ΓÇª from Mahanadi P J via UPI"
    _BankTemplate(
      senderPrefixes: ['SLICEP', 'SLICEB', 'SLCPAY'],
      displayName: 'Slice',
      amountPattern: RegExp(r'Rs\.?\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false),
      extractMerchant: (body) {
        // Expense: "to <NAME> (UPI Ref" or "to <NAME> via UPI"
        final to = RegExp(
          r'\bto\s+([A-Za-z0-9 &.\-]{2,50}?)\s*(?:\(UPI|\bvia\b|\bRef\b|\bUPI\b)',
          caseSensitive: false,
        ).firstMatch(body);
        if (to != null) return to.group(1)!.trim();

        // Income: "from <NAME> via UPI"
        final from = RegExp(
          r'\bfrom\s+([A-Za-z0-9 &.\-]{2,50}?)\s+(?:via\b|through\b|using\b)',
          caseSensitive: false,
        ).firstMatch(body);
        return from?.group(1)?.trim();
      },
    ),
  ];

  static _BankTemplate? _templateFor(String sender) {
    // Senders arrive as "AD-HDFCBK", "slice", "VM-AXISBK", etc.
    final upper = sender.toUpperCase().replaceFirst(RegExp(r'^[A-Z]{2}-'), '');
    for (final tpl in _bankTemplates) {
      for (final prefix in tpl.senderPrefixes) {
        if (upper.startsWith(prefix.toUpperCase())) return tpl;
      }
    }
    return null;
  }

  // ΓöÇΓöÇ Field extraction ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

  static final RegExp _genericAmountPattern = RegExp(
    r'(?:Rs\.?|INR|Γé╣)\s*\.?\s*([0-9,]+(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );

  // Words that confirm money came IN
  static final RegExp _incomePattern = RegExp(
    r'\b(credited|received|deposited|added to|refunded|cashback credited)\b',
    caseSensitive: false,
  );

  // Words that confirm money went OUT
  static final RegExp _expensePattern = RegExp(
    r'\b(debited|sent|paid|spent|withdrawn|purchased|transferred from)\b',
    caseSensitive: false,
  );

  // Last-4 digits of account or card
  static final RegExp _accountPattern = RegExp(
    r'(?:a/?c|acct|account|card)\s*(?:no\.?|#|xx+)?\.?\s*[xX*]{0,4}(\d{4})\b',
    caseSensitive: false,
  );

  // Available / closing balance
  static final RegExp _balancePattern = RegExp(
    r'(?:avl\.?\s*bal(?:ance)?|available\s+bal(?:ance)?|closing\s+bal(?:ance)?)'
    r'\s*(?:is|:|-|ΓÇô)?\s*(?:Rs\.?|INR|Γé╣)?\s*([0-9,]+(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );

  static _ParseResult? _extractFields(String body, String lower, String sender) {
    final template = _templateFor(sender);

    // ΓöÇΓöÇ Amount ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
    final amountRx = template?.amountPattern ?? _genericAmountPattern;
    final amountMatch = amountRx.firstMatch(body);
    if (amountMatch == null) return null;

    final amount = double.tryParse(amountMatch.group(1)!.replaceAll(',', ''));
    if (amount == null || amount <= 0) return null;

    // ΓöÇΓöÇ Transaction type ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
    // At this point _isConfirmedTransaction already passed, so one of these
    // keywords is guaranteed to be present.
    final hasIncome = _incomePattern.hasMatch(lower);
    final hasExpense = _expensePattern.hasMatch(lower);

    final String type;
    if (hasIncome && !hasExpense) {
      type = 'income';
    } else {
      // hasExpense alone, or both (debit wins to be safe)
      type = 'expense';
    }

    // ΓöÇΓöÇ Merchant ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
    // Priority: bank-specific ΓåÆ UPI VPA ΓåÆ income "from" ΓåÆ expense "to/at" ΓåÆ sender
    String? merchant;

    merchant = template?.extractMerchant?.call(body);
    merchant ??= _extractUpiVpa(body);

    if (merchant == null) {
      if (type == 'income') {
        merchant = _extractFromSender(body); // "received from <name> via"
      }
      merchant ??= _extractToAt(body); // "sent/paid to <name>"
    }

    // Track this separately from the final fallback below ΓÇö a merchant
    // that came from the raw sender code isn't a real counterparty and
    // should be flagged for review rather than presented as certain.
    final merchantWasExtracted = merchant != null;
    merchant ??= _cleanSender(sender);

    // Confidence: a recognized bank template plus a genuinely extracted
    // merchant is as reliable as this parser gets. Either piece missing
    // drops confidence and adds a specific, actionable warning rather
    // than silently defaulting to "pretty sure."
    double confidence = template != null ? 0.9 : 0.65;
    final warnings = <String>[];
    if (!merchantWasExtracted) {
      confidence -= 0.15;
      warnings.add('Merchant unclear - using sender ID');
    }
    if (template == null) {
      warnings.add('Bank not recognized - generic parsing used');
    }

    return _ParseResult(
      amount: amount,
      type: type,
      merchant: _normaliseMerchant(merchant),
      // Fall back to the cleaned sender code (e.g. "PAYTMB") when no
      // dedicated template exists ΓÇö still better than nothing on the
      // review card, and consistent with how merchant already falls
      // back to the sender elsewhere in this function.
      bankName: template?.displayName ?? _cleanSender(sender),
      accountNumber: _accountPattern.firstMatch(body)?.group(1),
      balance: _balancePattern.firstMatch(body).let(
        (m) => double.tryParse(m.group(1)!.replaceAll(',', '')),
      ),
      confidence: confidence.clamp(0.0, 1.0),
      warnings: warnings,
    );
  }

  // ΓöÇΓöÇ Merchant sub-extractors ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

  static final RegExp _upiVpaPattern = RegExp(
    r'(?:^|\s)([a-zA-Z0-9.\-_]{2,}@[a-zA-Z]{2,})(?:\s|\.|$)',
    caseSensitive: false,
  );

  /// Pulls a UPI VPA like "swiggy@icici" from anywhere in the body.
  static String? _extractUpiVpa(String body) =>
      _upiVpaPattern.firstMatch(body)?.group(1)?.toLowerCase();

  static final RegExp _fromPattern = RegExp(
    r'\bfrom\s+([A-Za-z0-9 &.\-]{2,50}?)\s+(?:via\b|through\b|using\b)',
    caseSensitive: false,
  );

  /// For income SMS: "received from <name> via UPI"
  static String? _extractFromSender(String body) =>
      _fromPattern.firstMatch(body)?.group(1)?.trim();

  static final RegExp _toAtPattern = RegExp(
    r'(?:\bto\b|\bat\b)\s+([A-Za-z0-9 &.\-]{2,40})',
    caseSensitive: false,
  );

  static final RegExp _metaNoise = RegExp(
    r'\b(upi|ref|txn|mandate|neft|imps|rtgs|transfer|bank|a\/c|acct|account)\b',
    caseSensitive: false,
  );

  /// Generic "to/at <name>" fallback; rejects metadata tokens.
  static String? _extractToAt(String body) {
    final m = _toAtPattern.firstMatch(body);
    if (m == null) return null;

    String candidate = m.group(1)!
        .trim()
        .replaceAll(RegExp(r'\s*\.?\s*(?:Ref|UPI).*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+on\s+\d.*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\(.*$'), '') // strip "(UPI Ref: ΓÇª"
        .trim();

    if (candidate.isEmpty || _metaNoise.hasMatch(candidate.toLowerCase())) {
      return null;
    }
    return candidate;
  }

  static String _cleanSender(String sender) => sender
      .replaceAll(RegExp(r'^[A-Z]{2}-'), '')
      .replaceAll(RegExp(r'[0-9]'), '')
      .toUpperCase();

  static String _normaliseMerchant(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'UNKNOWN';
    return raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[.,;:]+$'), '')
        .trim()
        .toUpperCase();
  }

  // ΓöÇΓöÇ Fingerprint ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

  static String _fingerprint(String sender, DateTime date, String body) {
  final snippet = body.length > 40 ? body.substring(0, 40) : body;
  return md5.convert(utf8.encode('$sender|$snippet')).toString();
  }
}

// ---------------------------------------------------------------------------
// Tiny extension to avoid nullable indirection boilerplate
// ---------------------------------------------------------------------------
extension _Let<T> on T? {
  R? let<R>(R? Function(T) f) {
    final v = this;
    return v == null ? null : f(v);
  }
}
