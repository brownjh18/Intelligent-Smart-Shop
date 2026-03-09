import 'package:ismart_shop/models/transaction.dart';

class NLPService {
  // Keywords for transaction type detection - ordered by priority
  static const List<String> saleKeywords = [
    // English
    'sold', 'sale', 'selling', 'gave', 'received', 'got paid', 'earned',
    'customer paid', 'paid me', 'money received', 'made sale',
    // Luganda
    'ekyangu', 'bintu', 'musaayi', 'kintu', 'nfunye', 'yakuba',
    'yankuba', 'yasamba', 'nakuwadde', 'nakuwadha'
  ];

  static const List<String> expenseKeywords = [
    // English
    'spent', 'expense', 'paid for', 'cost', 'bought for', 'paid out',
    'gave out', 'money out', 'used for', 'bought', 'purchased',
    // Luganda
    'kunsanze', 'kusaze', 'kulya', 'ebikole', 'ebiri kugula',
    'nakusaze', 'nakusanzie', 'nakugule', 'nakugulie'
  ];

  static const List<String> purchaseKeywords = [
    // English
    'purchased stock', 'bought stock', 'restocked', 'supplier', 'stock in',
    'ordered', 'got stock', 'received stock', 'imported',
    // Luganda
    'kugula', 'kugula stock', 'akawuki', 'nakugula', 'nakugula stock'
  ];

  // Amount patterns - various formats
  static const List<String> amountKeywords = [
    'shillings',
    'ugx',
    'ugx',
    'shs',
    'sh',
    's',
    'maka',
    'ffe',
    'pounds',
    'dollars'
  ];

  // Quantity patterns
  static const List<String> quantityKeywords = [
    'pieces',
    'pcs',
    'pc',
    'items',
    'units',
    'kgs',
    'kg',
    'grams',
    'g',
    'liters',
    'l',
    'ml',
    'packets',
    'packs',
    'boxes',
    'bags',
    'bundles',
    'dozen',
    'score',
    'pairs',
    'pairs'
  ];

  static TransactionIntent parseTransaction(String input) {
    if (input.isEmpty) {
      return TransactionIntent(
        type: TransactionType.sale,
        amount: 0,
        itemName: 'Unknown',
        description: input,
        category: 'Other',
      );
    }

    String lowerInput = input.toLowerCase();

    TransactionType type = _detectType(lowerInput);
    double amount = _extractAmount(lowerInput);
    int quantity = _extractQuantity(lowerInput);
    String itemName = _extractItem(lowerInput, quantity > 1);
    String category = _detectCategory(lowerInput);

    // If quantity was found, update item name to include quantity
    if (quantity > 1 && itemName != 'Unknown') {
      itemName = '$quantity $itemName';
    }

    return TransactionIntent(
      type: type,
      amount: amount,
      itemName: itemName,
      description: input,
      category: category,
    );
  }

  static TransactionType _detectType(String input) {
    // Check in order: purchases > expenses > sales (most specific first)

    // Check for purchases first (most specific)
    for (String keyword in purchaseKeywords) {
      if (input.contains(keyword)) {
        return TransactionType.purchase;
      }
    }

    // Check for expenses
    for (String keyword in expenseKeywords) {
      if (input.contains(keyword)) {
        return TransactionType.expense;
      }
    }

    // Check for sales
    for (String keyword in saleKeywords) {
      if (input.contains(keyword)) {
        return TransactionType.sale;
      }
    }

    // Default to sale if no keywords found
    return TransactionType.sale;
  }

  static double _extractAmount(String input) {
    // Most reliable patterns first

    // Pattern 1: Look for 'at X' or 'for X' - most common in speech
    RegExp atForPattern =
        RegExp(r'\b(?:at|for)\s+(\d+)\b', caseSensitive: false);
    var match = atForPattern.firstMatch(input);
    if (match != null) {
      double amount = double.tryParse(match.group(1)!) ?? 0;
      if (amount > 0) return amount;
    }

    // Pattern 2: Look for currency symbol followed by number
    RegExp currencyPattern =
        RegExp(r'\b(?:ugx|shs|sh)\s*(\d+)\b', caseSensitive: false);
    match = currencyPattern.firstMatch(input);
    if (match != null) {
      double amount = double.tryParse(match.group(1)!) ?? 0;
      if (amount > 0) return amount;
    }

    // Pattern 3: Look for number followed by currency
    RegExp numberCurrencyPattern =
        RegExp(r'\b(\d+)\s*(?:ugx|shs|sh|shillings)\b', caseSensitive: false);
    match = numberCurrencyPattern.firstMatch(input);
    if (match != null) {
      double amount = double.tryParse(match.group(1)!) ?? 0;
      if (amount > 0) return amount;
    }

    // Pattern 4: Find all standalone numbers with 3+ digits and pick the largest (likely price)
    RegExp numberPattern = RegExp(r'\b(\d{3,})\b');
    List<Match> allMatches = numberPattern.allMatches(input).toList();
    if (allMatches.isNotEmpty) {
      double maxAmount = 0;
      for (var m in allMatches) {
        double amount = double.tryParse(m.group(1)!) ?? 0;
        if (amount > maxAmount) {
          maxAmount = amount;
        }
      }
      if (maxAmount > 0) return maxAmount;
    }

    // Pattern 5: Any number >= 100
    RegExp anyNumberPattern = RegExp(r'\b(\d+)\b');
    match = anyNumberPattern.firstMatch(input);
    if (match != null) {
      double amount = double.tryParse(match.group(1)!) ?? 0;
      if (amount >= 100) return amount;
    }

    return 0;
  }

  static int _extractQuantity(String input) {
    // Pattern 1: "3 sugar" or "3 pieces of sugar" or "3pcs sugar"
    RegExp qtyPattern = RegExp(
        r'(\d+)\s*(?:pieces?|pcs?|pc|items?|units?|kgs?|kg|grams?|g|liters?|l|ml|packets?|packs?|boxes?|bags?|bundles?|dozen|score|pairs?)',
        caseSensitive: false);
    var match = qtyPattern.firstMatch(input);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 1;
    }

    // Pattern 2: "sugar 3" (item followed by number at end)
    RegExp reversePattern = RegExp(r'[a-z]+\s+(\d+)\s*$', caseSensitive: false);
    match = reversePattern.firstMatch(input);
    if (match != null) {
      int qty = int.tryParse(match.group(1)!) ?? 1;
      // Only use if it's a small number (likely quantity, not price)
      if (qty <= 100) return qty;
    }

    return 1;
  }

  static double _parseNumber(String numStr) {
    String cleaned = numStr.replaceAll(',', '').replaceAll(' ', '');
    return double.tryParse(cleaned) ?? 0;
  }

  static String _extractItem(String input, bool hasQuantity) {
    // List of words to remove
    List<String> wordsToRemove = [
      // Transaction type words
      ...saleKeywords,
      ...expenseKeywords,
      ...purchaseKeywords,
      // Amount-related words
      'shillings', 'ugx', 'ugx', 'shs', 'sh', 's', 'maka', 'ffe',
      'at', 'for', 'price', 'only', 'equals',
      // Quantity words
      'pieces', 'pcs', 'pc', 'items', 'units', 'kgs', 'kg', 'grams', 'g',
      'liters', 'l', 'ml', 'packets', 'packs', 'boxes', 'bags', 'bundles',
      'dozen', 'score', 'pairs',
      // Common filler words
      'the', 'a', 'an', 'to', 'from', 'by', 'with', 'in', 'on', 'of',
      'i', 'me', 'my', 'we', 'our', 'us',
      'yesterday', 'today', 'tomorrow', 'morning', 'afternoon', 'evening',
      'just', 'only', 'exactly', 'total', 'sum'
    ];

    // Remove numbers and amount-related patterns
    String cleaned = input
        .replaceAll(RegExp(r'\d{1,3}(?:,\d{3})*(?:\.\d+)?'), '')
        .replaceAll(
            RegExp(r'(?:ugx|ugx|shs|sh)\s*\d+', caseSensitive: false), '')
        .replaceAll(
            RegExp(r'\d+\s*(?:ugx|ugx|shs|sh|shillings|pieces?|pcs?)',
                caseSensitive: false),
            '')
        .toLowerCase();

    // Remove words from the list
    for (String word in wordsToRemove) {
      cleaned =
          cleaned.replaceAll(RegExp('\\b$word\\b', caseSensitive: false), ' ');
    }

    // Split by common delimiters
    List<String> words = cleaned.split(RegExp(r'[\s,\-\.]+'));

    // Filter and get meaningful words
    String itemName = words
        .where((word) => word.length > 2) // At least 3 characters
        .where((word) => !wordsToRemove.contains(word)) // Not a removed word
        .take(5) // Max 5 words
        .join(' ')
        .trim();

    // Capitalize first letter of each word
    if (itemName.isNotEmpty) {
      itemName = itemName.split(' ').map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1);
      }).join(' ');
    }

    return itemName.isNotEmpty ? itemName : 'Unknown';
  }

  static String _detectCategory(String input) {
    List<String> words = input.toLowerCase().split(RegExp(r'[\s,\-\.]+'));

    // Food and beverages
    List<String> foodWords = [
      'bread',
      'milk',
      'soda',
      'water',
      'food',
      'rice',
      'meat',
      'fish',
      'egg',
      'eggs',
      'posho',
      'matoke',
      'banana',
      'cassava',
      'sweet potato',
      'chicken',
      'beef',
      'pork',
      'tea',
      'coffee',
      'juice',
      'beer',
      'wine',
      'biscuits',
      'cakes',
      'cookies',
      'chips',
      'rolex',
      'chapati',
      'pizza',
      'hamburger',
      'sandwich',
      'spaghetti',
      'pasta',
      'beans',
      'peas',
      'cabbage',
      'onion',
      'tomato',
      'carrot',
      'lettuce',
      'cucumber',
      'fruits',
      'apple',
      'mango',
      'orange',
      'pineapple',
      'avocado'
    ];

    // Household items
    List<String> householdWords = [
      'soap',
      'toothpaste',
      'toothbrush',
      'detergent',
      'bucket',
      'cup',
      'plate',
      'bowl',
      'spoon',
      'fork',
      'knife',
      'pan',
      'pot',
      'kettle',
      'blanket',
      'pillow',
      'sheet',
      'mattress',
      'mosquito',
      'net',
      'candle',
      'torch',
      'battery',
      'bulb',
      'tube',
      'paint',
      'cement',
      'bricks',
      'timber',
      'iron',
      'sheet',
      'polythene',
      'garbage',
      'bag'
    ];

    // Transport
    List<String> transportWords = [
      'transport',
      'fuel',
      'petrol',
      'diesel',
      'taxi',
      'boda',
      'boda-boda',
      'fare',
      'bus',
      'minibus',
      'coach',
      'car',
      'vehicle',
      'maintenance',
      'repair',
      'tire',
      'tyres',
      'oil',
      'engine',
      'parking',
      'toll'
    ];

    // Communication
    List<String> communicationWords = [
      'airtime',
      'credit',
      'mtn',
      'airtel',
      'vodafone',
      'sms',
      'data',
      'internet',
      'wifi',
      'bundle',
      'top-up',
      'recharge',
      'sim',
      'phone',
      'mobile',
      'call',
      'minutes'
    ];

    // Utilities
    List<String> utilityWords = [
      'electricity',
      'power',
      'bill',
      'water bill',
      'rent',
      'internet',
      'wifi',
      'subscription',
      'membership',
      'fee',
      'charge'
    ];

    // Medical
    List<String> medicalWords = [
      'medicine',
      'drugs',
      'pharmacy',
      'hospital',
      'clinic',
      'doctor',
      'nurse',
      'treatment',
      'injection',
      'vaccine',
      'panadol',
      'aspirin',
      'first aid',
      'bandage',
      'plaster',
      'cotton',
      'antiseptic'
    ];

    // Clothing
    List<String> clothingWords = [
      'clothes',
      'shirt',
      'trousers',
      'dress',
      'shoes',
      'sandals',
      'socks',
      'underwear',
      'jacket',
      'sweater',
      'hat',
      'cap',
      'belt',
      'tie',
      'uniform',
      'school',
      'uniform'
    ];

    // Check each category
    for (String word in words) {
      if (foodWords.contains(word)) return 'Food & Beverages';
      if (householdWords.contains(word)) return 'Household';
      if (transportWords.contains(word)) return 'Transport';
      if (communicationWords.contains(word)) return 'Communication';
      if (utilityWords.contains(word)) return 'Utilities';
      if (medicalWords.contains(word)) return 'Medical';
      if (clothingWords.contains(word)) return 'Clothing';
    }

    return 'Other';
  }
}

class TransactionIntent {
  final TransactionType type;
  final double amount;
  final String itemName;
  final String description;
  final String category;

  TransactionIntent({
    required this.type,
    required this.amount,
    required this.itemName,
    required this.description,
    required this.category,
  });
}
