/// SmartCategoryResolver
///
/// Single source of truth for transaction categorization.
/// Always returns a valid Category.id from default category set.
///
/// Upgraded with expanded India-specific coverage: UPI apps, more
/// regional/national merchants, RTO/FASTag, insurance/PF, rent,
/// donations, and person-to-person UPI transfers. All original
/// entries and behavior are preserved.
class SmartCategoryResolver {
  SmartCategoryResolver._();

  static const Map<String, String> _merchantMap = {
    // --- FOOD DELIVERY / DINING ---
    'zomato': 'food',
    'swiggy': 'food',
    'ubereats': 'food',
    'foodpanda': 'food',
    'dominos': 'food',
    'domino': 'food',
    'pizza hut': 'food',
    'mcdonalds': 'food',
    'mcdonald': 'food',
    'kfc': 'food',
    'burger king': 'food',
    'subway': 'food',
    'starbucks': 'food',
    'cafe coffee day': 'food',
    'ccd': 'food',
    'dunkin': 'food',
    'haldirams': 'food',
    'barbeque nation': 'food',
    'paradise': 'food',
    'fasoos': 'food',
    'box8': 'food',
    'freshmenu': 'food',
    'rebel foods': 'food',
    'behrouz': 'food',
    'faasos': 'food',
    'chaayos': 'food',
    'third wave coffee': 'food',
    'blue tokai': 'food',
    'wow momo': 'food',
    'wowmomo': 'food',
    'lassi': 'food',
    'sagar ratna': 'food',
    'saravana bhavan': 'food',
    'mtr': 'food',
    'anand sweets': 'food',
    'bikanervala': 'food',
    'naturals ice cream': 'food',
    'baskin robbins': 'food',
    'kwality walls': 'food',

    // --- GROCERIES / QUICK COMMERCE ---
    'bigbasket': 'groceries',
    'blinkit': 'groceries',
    'zepto': 'groceries',
    'dunzo': 'groceries',
    'grofers': 'groceries',
    'jiomart': 'groceries',
    'dmart': 'groceries',
    'reliance fresh': 'groceries',
    'more supermarket': 'groceries',
    'nature basket': 'groceries',
    'lulu hypermarket': 'groceries',
    'spencer': 'groceries',
    'swiggy instamart': 'groceries',
    'instamart': 'groceries',
    'flipkart minutes': 'groceries',
    'star bazaar': 'groceries',
    'vishal mega mart': 'groceries',
    "nature's basket": 'groceries',

    // --- SHOPPING / E-COMMERCE ---
    'amazon': 'shopping',
    'flipkart': 'shopping',
    'myntra': 'shopping',
    'meesho': 'shopping',
    'ajio': 'shopping',
    'nykaa': 'shopping',
    'firstcry': 'shopping',
    'tata cliq': 'shopping',
    'snapdeal': 'shopping',
    'shopsy': 'shopping',
    'limeroad': 'shopping',
    'purplle': 'shopping',
    'mamaearth': 'shopping',
    'boat': 'shopping',
    'noise': 'shopping',
    'westside': 'shopping',
    'zara': 'shopping',
    'h&m': 'shopping',
    'marks and spencer': 'shopping',
    'lifestyle': 'shopping',
    'max fashion': 'shopping',
    'pantaloons': 'shopping',
    'reliance trends': 'shopping',
    'shoppers stop': 'shopping',
    'central mall': 'shopping',
    'brand factory': 'shopping',
    'decathlon': 'shopping',
    'ikea': 'shopping',
    'urban ladder': 'shopping',
    'pepperfry': 'shopping',
    'fabindia': 'shopping',
    'bata': 'shopping',
    'metro shoes': 'shopping',
    'titan': 'shopping',
    'tanishq': 'shopping',
    'caratlane': 'shopping',
    'kalyan jewellers': 'shopping',
    'malabar gold': 'shopping',

    // --- ELECTRONICS / TECH ---
    'reliance digital': 'tech',
    'croma': 'tech',
    'vijay sales': 'tech',
    'apple store': 'tech',
    'apple.com': 'tech',
    'samsung': 'tech',
    'oneplus': 'tech',
    'mi store': 'tech',
    'xiaomi': 'tech',

    // --- TRANSPORT / CABS / RTO ---
    'uber': 'transport',
    'ola': 'transport',
    'rapido': 'transport',
    'meru': 'transport',
    'blu smart': 'transport',
    'bluesmart': 'transport',
    'irctc': 'transport',
    'namma yatri': 'transport',
    'redbus': 'transport',
    'ksrtc': 'transport',
    'msrtc': 'transport',
    'delhi metro': 'transport',
    'dmrc': 'transport',
    'bmrcl': 'transport',
    'bengaluru metro': 'transport',
    'ncmc': 'transport',
    'fastag': 'transport',
    'paytm fastag': 'transport',
    'ihmcl': 'transport',
    'rto': 'transport',
    'parivahan': 'transport',
    'parking': 'transport',

    // --- TRAVEL ---
    'makemytrip': 'travel',
    'goibibo': 'travel',
    'cleartrip': 'travel',
    'ixigo': 'travel',
    'yatra': 'travel',
    'airasia': 'travel',
    'indigo': 'travel',
    'air india': 'travel',
    'spicejet': 'travel',
    'vistara': 'travel',
    'akasa': 'travel',
    'oyo': 'travel',
    'treebo': 'travel',
    'fabhotels': 'travel',
    'booking.com': 'travel',
    'agoda': 'travel',
    'trivago': 'travel',
    'thomas cook': 'travel',
    'veena world': 'travel',

    // --- ENTERTAINMENT / OTT ---
    'bookmyshow': 'entertainment',
    'pvr': 'entertainment',
    'inox': 'entertainment',
    'cinepolis': 'entertainment',
    'netflix': 'entertainment',
    'spotify': 'entertainment',
    'prime video': 'entertainment',
    'amazon prime': 'entertainment',
    'hotstar': 'entertainment',
    'disney': 'entertainment',
    'jiocinema': 'entertainment',
    'zee5': 'entertainment',
    'sonyliv': 'entertainment',
    'youtube premium': 'entertainment',
    'apple tv': 'entertainment',
    'apple music': 'entertainment',
    'gaana': 'entertainment',
    'jiosaavn': 'entertainment',
    'wynk': 'entertainment',
    'sunnxt': 'entertainment',
    'aha video': 'entertainment',

    // --- HEALTH ---
    'apollo': 'health',
    'medplus': 'health',
    'netmeds': 'health',
    'pharmeasy': 'health',
    '1mg': 'health',
    'practo': 'health',
    'tata 1mg': 'health',
    'cult.fit': 'health',
    'cult fit': 'health',
    'curefit': 'health',
    'healthians': 'health',
    'thyrocare': 'health',
    'fortis': 'health',
    'max healthcare': 'health',
    'manipal hospital': 'health',
    'narayana health': 'health',
    'aiims': 'health',
    'dr lal pathlabs': 'health',
    'lal pathlabs': 'health',
    'metropolis': 'health',
    'wellness forever': 'health',

    // --- FUEL / GARAGE ---
    'hpcl': 'garage',
    'bpcl': 'garage',
    'iocl': 'garage',
    'indian oil': 'garage',
    'bharat petroleum': 'garage',
    'hindustan petroleum': 'garage',
    'shell': 'garage',
    'nayara': 'garage',
    'essar oil': 'garage',
    'reliance bp': 'garage',

    // --- INVESTMENT / BROKING ---
    'groww': 'investment',
    'zerodha': 'investment',
    'upstox': 'investment',
    'kuvera': 'investment',
    'paytm money': 'investment',
    'etmoney': 'investment',
    'coin': 'investment',
    'icicidirect': 'investment',
    'hdfcsec': 'investment',
    'kotak securities': 'investment',
    'angel broking': 'investment',
    'angel one': 'investment',
    'smallcase': 'investment',
    'motilaloswal': 'investment',
    'motilal oswal': 'investment',
    '5paisa': 'investment',
    'indmoney': 'investment',

    // --- TECH SUBSCRIPTIONS ---
    'google one': 'tech',
    'icloud': 'tech',
    'microsoft': 'tech',
    'office 365': 'tech',
    'adobe': 'tech',
    'canva': 'tech',
    'notion': 'tech',
    'dropbox': 'tech',
    'nordvpn': 'tech',
    'chatgpt': 'tech',
    'openai': 'tech',
    'claude.ai': 'tech',
    'anthropic': 'tech',

    // --- EDUCATION ---
    'udemy': 'education',
    'coursera': 'education',
    'unacademy': 'education',
    'byju': 'education',
    'vedantu': 'education',
    'toppr': 'education',
    'leetcode': 'education',
    'pluralsight': 'education',
    'skillshare': 'education',
    'linkedin learning': 'education',
    'physics wallah': 'education',
    'pw': 'education',
    'allen career institute': 'education',
    'aakash institute': 'education',
    'fiitjee': 'education',
    'whitehat jr': 'education',
    'cuemath': 'education',

    // --- INSURANCE ---
    'lic': 'insurance',
    'lic of india': 'insurance',
    'hdfc life': 'insurance',
    'icici prudential': 'insurance',
    'sbi life': 'insurance',
    'max life': 'insurance',
    'bajaj allianz': 'insurance',
    'star health': 'insurance',
    'niva bupa': 'insurance',
    'care health': 'insurance',
    'acko': 'insurance',
    'digit insurance': 'insurance',
    'policybazaar': 'insurance',
    'epfo': 'insurance',
    'nps': 'insurance',

    // --- UPI APPS (as merchant/app name themselves — usually further
    // resolved by body text via the keyword list, but mapped here as a
    // safe default so a bare "PhonePe" merchant name doesn't fall to
    // 'other') ---
    'phonepe': 'upi_p2p',
    'google pay': 'upi_p2p',
    'gpay': 'upi_p2p',
    'paytm': 'upi_p2p',
    'amazon pay': 'upi_p2p',
    'bhim': 'upi_p2p',
    'cred': 'bills',
  };

  static const List<MapEntry<String, String>> _keywordList = [
    // --- BANK TRANSFERS ---
    MapEntry('neft', 'transfer'),
    MapEntry('imps', 'transfer'),
    MapEntry('rtgs', 'transfer'),
    MapEntry('upi transfer', 'transfer'),
    MapEntry('self transfer', 'transfer'),
    MapEntry('fund transfer', 'transfer'),
    MapEntry('transfer to', 'transfer'),
    MapEntry('transfer from', 'transfer'),

    // --- UPI PERSON-TO-PERSON (checked before generic merchant keywords
    // so "paid to <name>" style SMS/notifications land correctly) ---
    MapEntry('paid to', 'upi_p2p'),
    MapEntry('sent to', 'upi_p2p'),
    MapEntry('received from', 'upi_p2p'),
    MapEntry('upi/p2p', 'upi_p2p'),
    MapEntry('p2p transfer', 'upi_p2p'),
    MapEntry('to vpa', 'upi_p2p'),
    MapEntry('@okaxis', 'upi_p2p'),
    MapEntry('@oksbi', 'upi_p2p'),
    MapEntry('@okhdfcbank', 'upi_p2p'),
    MapEntry('@okicici', 'upi_p2p'),
    MapEntry('@ybl', 'upi_p2p'),
    MapEntry('@apl', 'upi_p2p'),
    MapEntry('@ibl', 'upi_p2p'),

    // --- SALARY / INCOME ---
    MapEntry('salary credited', 'salary'),
    MapEntry('salary credit', 'salary'),
    MapEntry('sal credit', 'salary'),
    MapEntry('salary', 'salary'),
    MapEntry('payroll', 'salary'),
    MapEntry('stipend', 'salary'),
    MapEntry('wages', 'salary'),

    // --- RENT ---
    MapEntry('rent payment', 'rent'),
    MapEntry('house rent', 'rent'),
    MapEntry('rent paid', 'rent'),
    MapEntry('landlord', 'rent'),
    MapEntry('nobroker', 'rent'),
    MapEntry('rentpay', 'rent'),
    MapEntry('rent via credit card', 'rent'),

    // --- BILLS / EMI ---
    MapEntry('emi debit', 'bills'),
    MapEntry('nach debit', 'bills'),
    MapEntry('ecs debit', 'bills'),
    MapEntry('loan emi', 'bills'),
    MapEntry(' emi ', 'bills'),
    MapEntry('credit card bill', 'bills'),
    MapEntry('cc bill payment', 'bills'),

    // --- INVESTMENT ---
    MapEntry('sip', 'investment'),
    MapEntry('systematic investment', 'investment'),
    MapEntry('mutual fund', 'investment'),
    MapEntry('mf purchase', 'investment'),
    MapEntry('units allotted', 'investment'),
    MapEntry('folio', 'investment'),
    MapEntry('ppf', 'investment'),
    MapEntry('nps contribution', 'investment'),
    MapEntry('rd installment', 'investment'),
    MapEntry('fd booked', 'investment'),
    MapEntry('recurring deposit', 'investment'),

    // --- INSURANCE / PF ---
    MapEntry('premium paid', 'insurance'),
    MapEntry('policy premium', 'insurance'),
    MapEntry('insurance premium', 'insurance'),
    MapEntry('pf contribution', 'insurance'),
    MapEntry('provident fund', 'insurance'),
    MapEntry('epf contribution', 'insurance'),

    // --- DONATIONS / RELIGIOUS ---
    MapEntry('donation', 'donation'),
    MapEntry('temple', 'donation'),
    MapEntry('mandir', 'donation'),
    MapEntry('gurudwara', 'donation'),
    MapEntry('church offering', 'donation'),
    MapEntry('masjid', 'donation'),
    MapEntry('charity', 'donation'),
    MapEntry('ngo', 'donation'),
    MapEntry('tirupati', 'donation'),
    MapEntry('temple trust', 'donation'),

    // --- FUEL ---
    MapEntry('petrol', 'garage'),
    MapEntry('diesel', 'garage'),
    MapEntry('fuel', 'garage'),
    MapEntry('cng', 'garage'),
    MapEntry('filling station', 'garage'),
    MapEntry('pump', 'garage'),
    MapEntry('ev charging', 'garage'),
    MapEntry('service center', 'garage'),
    MapEntry('car service', 'garage'),
    MapEntry('bike service', 'garage'),

    // --- FOOD ---
    MapEntry('restaurant', 'food'),
    MapEntry('dining', 'food'),
    MapEntry('cafe', 'food'),
    MapEntry('food court', 'food'),
    MapEntry('canteen', 'food'),
    MapEntry('hotel', 'food'),
    MapEntry('dhaba', 'food'),
    MapEntry('tiffin', 'food'),
    MapEntry('mess bill', 'food'),

    // --- GROCERIES ---
    MapEntry('grocery', 'groceries'),
    MapEntry('supermarket', 'groceries'),
    MapEntry('hypermarket', 'groceries'),
    MapEntry('mart', 'groceries'),
    MapEntry('kirana', 'groceries'),
    MapEntry('provision store', 'groceries'),

    // --- TRANSPORT ---
    MapEntry('cab', 'transport'),
    MapEntry('taxi', 'transport'),
    MapEntry('auto ride', 'transport'),
    MapEntry('metro', 'transport'),
    MapEntry('bus ticket', 'transport'),
    MapEntry('train ticket', 'transport'),
    MapEntry('toll', 'transport'),
    MapEntry('fastag recharge', 'transport'),
    MapEntry('auto rickshaw', 'transport'),
    MapEntry('local train', 'transport'),

    // --- TRAVEL ---
    MapEntry('flight', 'travel'),
    MapEntry('hotel booking', 'travel'),
    MapEntry('resort', 'travel'),
    MapEntry('hostel', 'travel'),
    MapEntry('airbnb', 'travel'),
    MapEntry('houseboat', 'travel'),
    MapEntry('tour package', 'travel'),
    MapEntry('holiday package', 'travel'),

    // --- ENTERTAINMENT ---
    MapEntry('movie', 'entertainment'),
    MapEntry('ticket', 'entertainment'),
    MapEntry('concert', 'entertainment'),
    MapEntry('gaming', 'entertainment'),
    MapEntry('subscription', 'entertainment'),
    MapEntry('event booking', 'entertainment'),
    MapEntry('amusement park', 'entertainment'),
    MapEntry('water park', 'entertainment'),

    // --- HEALTH ---
    MapEntry('pharmacy', 'health'),
    MapEntry('hospital', 'health'),
    MapEntry('clinic', 'health'),
    MapEntry('doctor', 'health'),
    MapEntry('medical', 'health'),
    MapEntry('diagnostic', 'health'),
    MapEntry('lab test', 'health'),
    MapEntry('gym', 'health'),
    MapEntry('fitness', 'health'),
    MapEntry('chemist', 'health'),
    MapEntry('dental', 'health'),
    MapEntry('ayurveda', 'health'),
    MapEntry('yoga class', 'health'),

    // --- EDUCATION ---
    MapEntry('tuition', 'education'),
    MapEntry('school fee', 'education'),
    MapEntry('college fee', 'education'),
    MapEntry('course', 'education'),
    MapEntry('exam fee', 'education'),
    MapEntry('coaching class', 'education'),
    MapEntry('entrance exam', 'education'),
    MapEntry('semester fee', 'education'),

    // --- SHOPPING ---
    MapEntry('e-com', 'shopping'),
    MapEntry('marketplace', 'shopping'),
    MapEntry('online order', 'shopping'),
    MapEntry('shopping', 'shopping'),

    // --- BILLS / UTILITIES ---
    MapEntry('electricity', 'bills'),
    MapEntry('water bill', 'bills'),
    MapEntry('gas bill', 'bills'),
    MapEntry('broadband', 'bills'),
    MapEntry('wifi', 'bills'),
    MapEntry('internet', 'bills'),
    MapEntry('mobile recharge', 'bills'),
    MapEntry('recharge', 'bills'),
    MapEntry('dth', 'bills'),
    MapEntry('utility', 'bills'),
    MapEntry('lpg cylinder', 'bills'),
    MapEntry('gas cylinder', 'bills'),
    MapEntry('society maintenance', 'bills'),
    MapEntry('maintenance charges', 'bills'),
    MapEntry('property tax', 'bills'),
    MapEntry('municipal tax', 'bills'),

    // --- SHARED / SPLIT ---
    MapEntry('split', 'shared'),
    MapEntry('splitwise', 'shared'),
    MapEntry('share expense', 'shared'),

    // --- FAMILY SUPPORT ---
    MapEntry('sent to mother', 'family'),
    MapEntry('sent to father', 'family'),
    MapEntry('family support', 'family'),
    MapEntry('home expenses', 'family'),
    MapEntry('parents support', 'family'),
  ];

  static String resolve({
    required String merchant,
    String? body,
    double? amount,
    String? transactionType,
  }) {
    final lMerchant = merchant.toLowerCase().trim();
    final lBody = (body ?? '').toLowerCase();
    final isIncome = transactionType?.toLowerCase() == 'income';

    if (isIncome) {
      if (_containsAny(lMerchant, ['salary', 'payroll', 'stipend']) ||
          _containsAny(lBody, [
            'salary credited',
            'salary credit',
            'sal credit',
            'payroll',
          ])) {
        return 'salary';
      }
      if (_merchantMapHit(lMerchant) == 'investment') {
        return 'investment';
      }
      if (_containsAny(lBody, ['received from', 'sent to you']) ||
          _containsAny(lMerchant, ['phonepe', 'google pay', 'gpay', 'paytm', 'bhim'])) {
        return 'upi_p2p';
      }
      // No salary keyword and no investment-merchant match — do NOT assume
      // salary. Unrecognized income (refunds, loan repayment confirmations
      // mistyped upstream, interest credits, reimbursements, etc.) should
      // land in 'other' for manual review, not be silently labeled salary.
      return 'other';
    }

    // Keyword list is checked before the merchant map for a few
    // high-specificity phrases (e.g. "paid to", "@okaxis") so a P2P UPI
    // payment through an app like PhonePe/GPay doesn't get bucketed
    // into a generic app-level default before the more specific intent
    // (person-to-person) is recognized.
    final earlyBodyHit = _keywordListHit('$lMerchant $lBody');

    final exactHit = _merchantMapHit(lMerchant);
    if (exactHit != null && earlyBodyHit == null) {
      return exactHit;
    }

    if (earlyBodyHit != null) {
      return earlyBodyHit;
    }

    if (exactHit != null) {
      return exactHit;
    }

    if (amount != null) {
      if (amount <= 50) {
        return 'food';
      }
      if (_isTypicalRechargeAmount(amount)) {
        return 'bills';
      }
    }

    return 'other';
  }

  static String? _merchantMapHit(String lMerchant) {
    if (_merchantMap.containsKey(lMerchant)) {
      return _merchantMap[lMerchant];
    }

    for (final entry in _merchantMap.entries) {
      if (lMerchant.contains(entry.key) || entry.key.contains(lMerchant)) {
        if (entry.key.length >= 3 && _isWordMatch(lMerchant, entry.key)) {
          return entry.value;
        }
      }
    }
    return null;
  }

  static String? _keywordListHit(String text) {
    for (final entry in _keywordList) {
      if (text.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  static bool _containsAny(String text, List<String> keywords) {
    for (final kw in keywords) {
      if (text.contains(kw)) {
        return true;
      }
    }
    return false;
  }

  static bool _isWordMatch(String text, String keyword) {
    if (keyword.length >= 5) {
      return text.contains(keyword);
    }

    final idx = text.indexOf(keyword);
    if (idx == -1) {
      return false;
    }

    final before = idx == 0 ? ' ' : text[idx - 1];
    final after =
        (idx + keyword.length >= text.length) ? ' ' : text[idx + keyword.length];
    const boundaryChars = ' .,/-_()[]|:;!?';
    return boundaryChars.contains(before) || boundaryChars.contains(after);
  }

  static const Set<int> _rechargeAmounts = {
    149,
    179,
    199,
    219,
    249,
    299,
    349,
    399,
    449,
    499,
    599,
    699,
  };

  static bool _isTypicalRechargeAmount(double amount) {
    return _rechargeAmounts.contains(amount.round());
  }
}