/// SmartCategoryResolver
///
/// Single source of truth for transaction categorization.
/// Always returns a valid Category.id from default category set.
class SmartCategoryResolver {
  SmartCategoryResolver._();

  static const Map<String, String> _merchantMap = {
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

    'reliance digital': 'tech',
    'croma': 'tech',
    'vijay sales': 'tech',
    'apple store': 'tech',
    'apple.com': 'tech',
    'samsung': 'tech',
    'oneplus': 'tech',

    'uber': 'transport',
    'ola': 'transport',
    'rapido': 'transport',
    'meru': 'transport',
    'blu smart': 'transport',
    'bluesmart': 'transport',
    'irctc': 'transport',
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

    'google one': 'tech',
    'icloud': 'tech',
    'microsoft': 'tech',
    'office 365': 'tech',
    'adobe': 'tech',
    'canva': 'tech',
    'notion': 'tech',
    'dropbox': 'tech',
    'nordvpn': 'tech',

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
  };

  static const List<MapEntry<String, String>> _keywordList = [
    MapEntry('neft', 'transfer'),
    MapEntry('imps', 'transfer'),
    MapEntry('rtgs', 'transfer'),
    MapEntry('upi transfer', 'transfer'),
    MapEntry('self transfer', 'transfer'),
    MapEntry('fund transfer', 'transfer'),
    MapEntry('transfer to', 'transfer'),
    MapEntry('transfer from', 'transfer'),

    MapEntry('salary credited', 'salary'),
    MapEntry('salary credit', 'salary'),
    MapEntry('sal credit', 'salary'),
    MapEntry('salary', 'salary'),
    MapEntry('payroll', 'salary'),
    MapEntry('stipend', 'salary'),
    MapEntry('wages', 'salary'),

    MapEntry('emi debit', 'bills'),
    MapEntry('nach debit', 'bills'),
    MapEntry('ecs debit', 'bills'),
    MapEntry('loan emi', 'bills'),
    MapEntry(' emi ', 'bills'),

    MapEntry('sip', 'investment'),
    MapEntry('systematic investment', 'investment'),
    MapEntry('mutual fund', 'investment'),
    MapEntry('mf purchase', 'investment'),
    MapEntry('units allotted', 'investment'),
    MapEntry('folio', 'investment'),

    MapEntry('petrol', 'garage'),
    MapEntry('diesel', 'garage'),
    MapEntry('fuel', 'garage'),
    MapEntry('cng', 'garage'),
    MapEntry('filling station', 'garage'),
    MapEntry('pump', 'garage'),

    MapEntry('restaurant', 'food'),
    MapEntry('dining', 'food'),
    MapEntry('cafe', 'food'),
    MapEntry('food court', 'food'),
    MapEntry('canteen', 'food'),
    MapEntry('hotel', 'food'),

    MapEntry('grocery', 'groceries'),
    MapEntry('supermarket', 'groceries'),
    MapEntry('hypermarket', 'groceries'),
    MapEntry('mart', 'groceries'),

    MapEntry('cab', 'transport'),
    MapEntry('taxi', 'transport'),
    MapEntry('auto ride', 'transport'),
    MapEntry('metro', 'transport'),
    MapEntry('bus ticket', 'transport'),
    MapEntry('train ticket', 'transport'),

    MapEntry('flight', 'travel'),
    MapEntry('hotel booking', 'travel'),
    MapEntry('resort', 'travel'),
    MapEntry('hostel', 'travel'),
    MapEntry('airbnb', 'travel'),

    MapEntry('movie', 'entertainment'),
    MapEntry('ticket', 'entertainment'),
    MapEntry('concert', 'entertainment'),
    MapEntry('gaming', 'entertainment'),
    MapEntry('subscription', 'entertainment'),

    MapEntry('pharmacy', 'health'),
    MapEntry('hospital', 'health'),
    MapEntry('clinic', 'health'),
    MapEntry('doctor', 'health'),
    MapEntry('medical', 'health'),
    MapEntry('diagnostic', 'health'),
    MapEntry('lab test', 'health'),
    MapEntry('insurance', 'health'),
    MapEntry('gym', 'health'),
    MapEntry('fitness', 'health'),

    MapEntry('tuition', 'education'),
    MapEntry('school fee', 'education'),
    MapEntry('college fee', 'education'),
    MapEntry('course', 'education'),
    MapEntry('exam fee', 'education'),

    MapEntry('e-com', 'shopping'),
    MapEntry('marketplace', 'shopping'),
    MapEntry('online order', 'shopping'),
    MapEntry('shopping', 'shopping'),

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

    MapEntry('split', 'shared'),
    MapEntry('splitwise', 'shared'),
    MapEntry('share expense', 'shared'),
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
      return 'salary';
    }

    final exactHit = _merchantMapHit(lMerchant);
    if (exactHit != null) {
      return exactHit;
    }

    final bodyHit = _keywordListHit('$lMerchant $lBody');
    if (bodyHit != null) {
      return bodyHit;
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
