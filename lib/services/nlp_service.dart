import 'package:flutter/foundation.dart';
import 'package:ismart_shop/models/transaction.dart';

class NLPService {
  // Keywords for transaction type detection - ordered by priority
  static const List<String> saleKeywords = [
    // English
    'sold', 'sale', 'selling', 'gave', 'received', 'got paid', 'earned',
    'customer paid', 'paid me', 'money received', 'made sale', 'to customer',
    // Luganda
    'ekyangu', 'bintu', 'musaayi', 'kintu', 'nfunye', 'yakuba',
    'yankuba', 'yasamba', 'nakuwadde', 'nakuwadha', 'mu kigwo'
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

  // Cash Receipt keywords - for detecting money received from customers
  static const List<String> cashReceiptKeywords = [
    // English
    'received from', 'got from', 'paid by', 'payment from', 'money from',
    'customer paid', 'paid me', 'money received', 'received payment',
    'collection', 'collected', 'balance paid', 'settled',
    // Luganda
    'yakuba', 'yankuba', 'nakuwadde', 'nakuwadha', 'awadde', 'mwaka',
    'ekigwo', 'olusolo', 'ekikapu'
  ];

  // Unit patterns - comprehensive list
  static const List<String> unitPatterns = [
    // Weight units
    'kilograms', 'kilogram', 'kgs', 'kg', 'kilo', 'kilos',
    'grams', 'gram', 'g', 'gr',
    'milligrams', 'milligram', 'mg',
    'pounds', 'pound', 'lbs', 'lb',
    'ounces', 'ounce', 'oz',

    // Volume units
    'liters', 'liter', 'litres', 'litre', 'l',
    'milliliters', 'milliliter', 'ml',
    'gallons', 'gallon', 'gal',
    'cups', 'cup',
    'tablespoons', 'tablespoon', 'tbsp',
    'teaspoons', 'teaspoon', 'tsp',

    // Count units
    'pieces', 'piece', 'pcs', 'pc',
    'items', 'item', 'units', 'unit',
    'pairs', 'pair', 'pr',
    'dozens', 'dozen', 'dz',
    'scores', 'score',
    'sets', 'set',
    'bunches', 'bunch',
    'heads', 'head',

    // Packaging units
    'packets', 'packet', 'packs', 'pack',
    'boxes', 'box',
    'bags', 'bag',
    'bundles', 'bundle',
    'bottles', 'bottle',
    'cans', 'can',
    'jars', 'jar',
    'cartons', 'carton',
    'crates', 'crate',
    'sacks', 'sack',
    'rolls', 'roll',
    'sheets', 'sheet',
    'reams', 'ream',
    'strips', 'strip',
    'tabs', 'tab',

    // Length units
    'meters', 'meter', 'm',
    'centimeters', 'centimeter', 'cm',
    'millimeters', 'millimeter', 'mm',
    'feet', 'foot', 'ft',
    'inches', 'inch', 'in',

    // Other
    'servings', 'serving',
    'portions', 'portion',
    'plates', 'plate',
    'dishes', 'dish',
    'bowls', 'bowl',
    'glasses', 'glass',
  ];

  // Common item categories with items
  static final Map<String, List<String>> categoryItems = {
    'Food & Beverages': [
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
      'potato',
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
      'tomatoes',
      'tomato',
      'carrot',
      'lettuce',
      'cucumber',
      'fruits',
      'apple',
      'mango',
      'orange',
      'pineapple',
      'avocado',
      'sugar',
      'salt',
      'cooking oil',
      'oil',
      'flour',
      'powder',
      'spice',
      'seasoning',
      'butter',
      'margarine',
      'cheese',
      'yogurt',
      'ugali',
      'groundnuts',
      'peanuts'
    ],
    'Household': [
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
      'mosquito net',
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
      'polythene',
      'garbage bag',
      'mop',
      'broom',
      'brush',
      'cloth',
      'sponge',
      'aluminum foil',
      'plastic bag',
      'envelope',
      'notebook',
      'pen'
    ],
    'Transport': [
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
      'toll',
      'fare',
      'trip',
      'journey'
    ],
    'Communication': [
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
      'minutes',
      'voice',
      'mb',
      'gb'
    ],
    'Utilities': [
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
      'charge',
      'token',
      'prepaid'
    ],
    'Medical': [
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
      'antiseptic',
      'drug',
      'vitamins',
      'syrup',
      'tablet',
      'capsule',
      'injection'
    ],
    'Clothing': [
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
      'skirt',
      'blouse',
      'shorts',
      'vest',
      'jersey',
      'shoe'
    ],
    'Personal Care': [
      'perfume',
      'deodorant',
      'cream',
      'lotion',
      'shampoo',
      'conditioner',
      'body oil',
      'Vaseline',
      'petroleum jelly',
      'razor',
      'shaving cream'
    ]
  };

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

    // Extract all the details
    ParsedTransactionDetails details = _parseAllDetails(lowerInput);

    // Calculate total amount
    double totalAmount = _calculateTotalAmount(
        details.unitPrice, details.quantity, details.totalPrice);

    return TransactionIntent(
      type: type,
      amount: totalAmount,
      itemName: details.itemName,
      description: input,
      category: details.category,
      quantity: details.quantity,
      unit: details.unit,
      unitPrice: details.unitPrice,
      customerName: details.customerName,
      notes: details.notes,
      transactionDate: details.date,
    );
  }

  static TransactionType _detectType(String input) {
    // Check in order: cash receipts > purchases > expenses > sales (most specific first)

    // Check for cash receipts first (e.g., "Received 20,000 from John")
    for (String keyword in cashReceiptKeywords) {
      if (input.contains(keyword)) {
        return TransactionType.cashReceipt;
      }
    }

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

  static ParsedTransactionDetails _parseAllDetails(String input) {
    ParsedTransactionDetails details = ParsedTransactionDetails();

    // Extract quantity and unit
    details.quantity = _extractQuantity(input);
    details.unit = _extractUnit(input);

    // Extract prices
    details.unitPrice = _extractUnitPrice(input);
    details.totalPrice = _extractTotalPrice(input);

    // Extract item name
    details.itemName = _extractItemName(input);

    // Detect category
    details.category = _detectCategory(input, details.itemName);

    // Extract customer name
    details.customerName = _extractCustomerName(input);

    // Extract notes
    details.notes = _extractNotes(input);

    // Extract date
    details.date = _extractDate(input);

    return details;
  }

  static int _extractQuantity(String input) {
    // Handle Luganda number words
    String normalized = input.toLowerCase();

    // First, remove common filler words that might interfere with detection
    normalized = normalized.replaceAll('each', '');
    normalized = normalized.replaceAll('per', '');
    normalized = normalized.replaceAll('only', '');

    // Common Luganda/vernacular numbers
    final lugandaNumbers = {
      'emu': 1,
      'emuu': 1,
      'emuun': 1,
      'ebiri': 2,
      'ebiriiro': 2,
      'esatu': 3,
      'esatut': 3,
      'esoba': 4,
      'esobat': 4,
      'etaano': 5,
      'etaanot': 5,
      'mukaaga': 6,
      'mukaagat': 6,
      'musanvu': 7,
      'musanvut': 7,
      'munaana': 8,
      'munaanat': 8,
      'mwenda': 9,
      'mwendat': 9,
      'ekumi': 10,
    };

    for (var entry in lugandaNumbers.entries) {
      if (normalized.contains(entry.key)) {
        return entry.value;
      }
    }

    // English word numbers - comprehensive list including variations
    final wordNumbers = {
      'one': 1,
      'once': 1,
      'two': 2,
      'twice': 2,
      'three': 3,
      'thrice': 3,
      'four': 4,
      'five': 5,
      'six': 6,
      'seven': 7,
      'eight': 8,
      'nine': 9,
      'ten': 10,
      'eleven': 11,
      'twelve': 12,
      'thirteen': 13,
      'fourteen': 14,
      'fifteen': 15,
      'sixteen': 16,
      'seventeen': 17,
      'eighteen': 18,
      'nineteen': 19,
      'twenty': 20,
      'thirty': 30,
      'forty': 40,
      'fifty': 50,
      'sixty': 60,
      'seventy': 70,
      'eighty': 80,
      'ninety': 90,
      'hundred': 100,
      // Common numeric word variations
      'a': 1,
      'an': 1,
      'pair': 2,
      'dozen': 12,
      'couple': 2,
      ' couple ': 2,
      'few': 3,
      'several': 5,
      'bunch': 5,
      'some': 3,
      'lot': 10,
      'lots': 10,
    };

    // Extract word number from the beginning of the input (after transaction verb)
    // This handles patterns like "sold three bread at 2000" or "sold three breads each at 2000"
    RegExp wordNumPattern = RegExp(
        r'(?:sold|bought|spent|paid|buy|sell|purchase)\s+(one|two|three|four|five|six|seven|eight|nine|ten|a|an)\s+\w+',
        caseSensitive: false);
    var wordMatch = wordNumPattern.firstMatch(normalized);
    if (wordMatch != null) {
      String wordNum = wordMatch.group(1)!.toLowerCase();
      if (wordNumbers.containsKey(wordNum)) {
        debugPrint(
            'NLP: Found word number "$wordNum" = ${wordNumbers[wordNum]}');
        return wordNumbers[wordNum]!;
      }
    }

    // Also check for patterns with "each" or "at" after the item
    RegExp wordNumEachPattern = RegExp(
        r'(?:sold|bought|spent|paid)\s+(one|two|three|four|five|six|seven|eight|nine|ten|a|an)\s+\w+\s+(?:each\s+)?(?:at|for)\s+\d+',
        caseSensitive: false);
    wordMatch = wordNumEachPattern.firstMatch(normalized);
    if (wordMatch != null) {
      String wordNum = wordMatch.group(1)!.toLowerCase();
      if (wordNumbers.containsKey(wordNum)) {
        debugPrint(
            'NLP: Found word number (each pattern) "$wordNum" = ${wordNumbers[wordNum]}');
        return wordNumbers[wordNum]!;
      }
    }

    for (var entry in wordNumbers.entries) {
      if (normalized.contains(entry.key)) {
        return entry.value;
      }
    }

    // Pattern: "3 pieces", "5 kgs", "10 pcs", "2 dozen", "3 bundles", etc.
    RegExp qtyPattern = RegExp(
        r'(\d+(?:\.\d+)?)\s*(?:pieces?|pcs?|pc|piece|items?|units?|kgs?|kg|kilograms?|grams?|g|gr|liters?|l|ml|packets?|packs?|boxes?|bags?|bundles?|dozen|dz|score|pairs?|bottles?|cans?|cups?|plates?|rolls?|sheets?|reams?|pairs?|jars?|cartons?|crates?|sacks?|heads?|bunches?|sets?|meters?|cm|mm|feet|ft|inches?|in)',
        caseSensitive: false);
    var match = qtyPattern.firstMatch(input);
    if (match != null) {
      double qty = double.tryParse(match.group(1)!) ?? 1;
      if (qty > 0 && qty <= 1000) return qty.round();
    }

    // Pattern: "3 at 5000" - quantity before price (e.g., "sold three bread at 2000")
    RegExp qtyAtPricePattern =
        RegExp(r'(\d+)\s+at\s+\d+', caseSensitive: false);
    match = qtyAtPricePattern.firstMatch(input);
    if (match != null) {
      double qty = double.tryParse(match.group(1)!) ?? 1;
      if (qty > 0 && qty <= 100) return qty.round();
    }

    // Pattern: "sold 3 bread" - action verb followed by quantity item
    RegExp soldQtyPattern = RegExp(
        r'(?:sold|bought|spent|paid|buy|sell|purchase)\s+(\d+)\s+\w+',
        caseSensitive: false);
    match = soldQtyPattern.firstMatch(input);
    if (match != null) {
      double qty = double.tryParse(match.group(1)!) ?? 1;
      if (qty > 0 && qty <= 100) return qty.round();
    }

    // Pattern: "3" at the beginning before item (if small number)
    RegExp startPattern = RegExp(r'^(\d+)\s+([a-z]+)', caseSensitive: false);
    match = startPattern.firstMatch(input);
    if (match != null) {
      double qty = double.tryParse(match.group(1)!) ?? 1;
      if (qty > 0 && qty <= 100) return qty.round();
    }

    // Handle informal: "3 bread" (without unit) - common pattern
    RegExp informalPattern =
        RegExp(r'(\d+)\s+([a-z]{2,})', caseSensitive: false);
    match = informalPattern.firstMatch(input);
    if (match != null) {
      double qty = double.tryParse(match.group(1)!) ?? 1;
      if (qty > 0 && qty <= 100) return qty.round();
    }

    return 1;
  }

  static String _extractUnit(String input) {
    // Find unit in the input - comprehensive pattern
    RegExp unitPattern = RegExp(
        r'(\d+(?:\.\d+)?)\s*(pieces?|pcs?|pc|piece|items?|units?|kgs?|kg|kilograms?|grams?|g|gr|liters?|l|ml|packets?|packs?|boxes?|bags?|bundles?|dozen|dz|score|pairs?|bottles?|cans?|cups?|plates?|rolls?|sheets?|reams?|pairs?|jars?|cartons?|crates?|sacks?|heads?|bunches?|sets?|meters?|cm|mm|feet|ft|inches?|in)',
        caseSensitive: false);
    var match = unitPattern.firstMatch(input);
    if (match != null) {
      String unit = match.group(2)!.toLowerCase();
      // Normalize common units
      if (unit.startsWith('pc')) return 'pcs';
      if (unit.startsWith('kg') || unit == 'kilo') return 'kgs';
      if (unit.startsWith('gram') || unit == 'g' || unit == 'gr') return 'g';
      if (unit.startsWith('liter') || unit == 'l') return 'L';
      if (unit.startsWith('milliliter') || unit == 'ml') return 'ml';
      if (unit.startsWith('packet')) return 'packets';
      if (unit.startsWith('dozen')) return 'dozen';
      if (unit.startsWith('box')) return 'boxes';
      if (unit.startsWith('bag')) return 'bags';
      if (unit.startsWith('bundle')) return 'bundles';
      if (unit.startsWith('bottle')) return 'bottles';
      if (unit.startsWith('can')) return 'cans';
      if (unit.startsWith('cup')) return 'cups';
      if (unit.startsWith('plate')) return 'plates';
      if (unit.startsWith('roll')) return 'rolls';
      if (unit.startsWith('sheet')) return 'sheets';
      if (unit.startsWith('ream')) return 'reams';
      if (unit.startsWith('pair') || unit == 'pr') return 'pairs';
      if (unit.startsWith('jar')) return 'jars';
      if (unit.startsWith('carton')) return 'cartons';
      if (unit.startsWith('crate')) return 'crates';
      if (unit.startsWith('sack')) return 'sacks';
      if (unit.startsWith('head')) return 'heads';
      if (unit.startsWith('bunch')) return 'bunches';
      if (unit.startsWith('set')) return 'sets';
      if (unit.startsWith('meter') || unit == 'm') return 'meters';
      if (unit.startsWith('centimeter') || unit == 'cm') return 'cm';
      if (unit.startsWith('millimeter') || unit == 'mm') return 'mm';
      if (unit.startsWith('foot') || unit == 'ft' || unit == 'feet') {
        return 'feet';
      }
      if (unit.startsWith('inch') || unit == 'in') return 'inches';
      return unit;
    }
    return 'pcs'; // default
  }

  static double _extractUnitPrice(String input) {
    // Pattern: "each at 5000" or "at 5000 each"
    RegExp eachPattern = RegExp(
        r'(?:each|per|@\s*)?\s*(?:at|from)\s+(\d+(?:,\d+)?)\s*(?:each|per)?',
        caseSensitive: false);
    var match = eachPattern.firstMatch(input);
    if (match != null) {
      double price = _parseNumber(match.group(1)!);
      if (price > 0) return price;
    }

    // Pattern: "5000 each" or "5000 per"
    RegExp priceEachPattern =
        RegExp(r'(\d+)\s*(?:each|per|ugx|shs|shillings)', caseSensitive: false);
    match = priceEachPattern.firstMatch(input);
    if (match != null) {
      double price = _parseNumber(match.group(1)!);
      if (price > 0) return price;
    }

    // Pattern: "sold 3 bread at 5000" - transaction verb followed by quantity item at price
    RegExp soldAtPattern = RegExp(
        r'(?:sold|bought|spent|paid)\s+\d+\s+\w+\s+(?:at|for)\s+(\d+)',
        caseSensitive: false);
    match = soldAtPattern.firstMatch(input);
    if (match != null) {
      double price = _parseNumber(match.group(1)!);
      if (price > 0) return price;
    }

    // Pattern: "3 bread 5000 each" - quantity item price each
    RegExp qtyItemPricePattern =
        RegExp(r'\d+\s+\w+\s+(\d+)\s*(?:each|per)?', caseSensitive: false);
    match = qtyItemPricePattern.firstMatch(input);
    if (match != null) {
      double price = _parseNumber(match.group(1)!);
      if (price > 0) return price;
    }

    // NEW: Pattern for "sold 3 breads each at 5000" - supports plural items and "each" keyword
    RegExp soldEachAtPattern = RegExp(
        r'(?:sold|bought|paid)\s+\d+\s+\w+\s+(?:each)?\s+(?:at|for)\s+(\d+)',
        caseSensitive: false);
    match = soldEachAtPattern.firstMatch(input);
    if (match != null) {
      double price = _parseNumber(match.group(1)!);
      if (price > 0) return price;
    }

    // NEW: Simple pattern for "3 at 5000" after item name
    RegExp atPricePattern = RegExp(r'\d+\s+at\s+(\d+)', caseSensitive: false);
    match = atPricePattern.firstMatch(input);
    if (match != null) {
      double price = _parseNumber(match.group(1)!);
      if (price > 0) return price;
    }

    return 0;
  }

  static double _extractTotalPrice(String input) {
    // Pattern: "for 5000" or "total 5000" or "spent 5000"
    RegExp totalPattern = RegExp(
        r'(?:for|total|spent|worth|amount)\s+(?:of\s+)?(\d+(?:,\d+)?)',
        caseSensitive: false);
    var match = totalPattern.firstMatch(input);
    if (match != null) {
      double price = _parseNumber(match.group(1)!);
      if (price > 0) return price;
    }

    // Pattern: "5000 shillings" or "5000 ugx"
    RegExp pricePattern =
        RegExp(r'(\d+)\s*(?:ugx|shs|sh|shillings)', caseSensitive: false);
    var match2 = pricePattern.firstMatch(input);
    if (match2 != null) {
      double price = _parseNumber(match2.group(1)!);
      if (price > 0) return price;
    }

    // Find largest number (likely total)
    RegExp numberPattern = RegExp(r'\b(\d+)\b');
    List<Match> matches = numberPattern.allMatches(input).toList();
    double maxNum = 0;
    for (var m in matches) {
      double num = _parseNumber(m.group(1)!);
      if (num > maxNum && num >= 100) {
        maxNum = num;
      }
    }
    return maxNum;
  }

  static double _calculateTotalAmount(
      double unitPrice, int quantity, double totalPrice) {
    // If we have both unit price and quantity, calculate total
    if (unitPrice > 0 && quantity > 1) {
      return unitPrice * quantity;
    }

    // If we have total price, use it
    if (totalPrice > 0) {
      return totalPrice;
    }

    // If we only have unit price (quantity = 1), use it
    if (unitPrice > 0) {
      return unitPrice;
    }

    return 0;
  }

  static String _extractItemName(String input) {
    // Remove all numbers, prices, and common words
    String cleaned = input;

    // Handle common typos and informal language - normalize first
    // Common informal/variant patterns
    cleaned = cleaned.replaceAll(RegExp(r'\bi\s+'), 'I '); // lowercase i to I
    // Handle different forms: dnt, dont, don't, don.t
    cleaned =
        cleaned.replaceAll(RegExp(r'\bdnt\b', caseSensitive: false), 'do not');
    cleaned =
        cleaned.replaceAll(RegExp(r'\bdont\b', caseSensitive: false), 'do not');
    cleaned = cleaned.replaceAll(
        RegExp(r"don[.,']?t\b", caseSensitive: false), 'do not');
    cleaned =
        cleaned.replaceAll(RegExp(r"\bcant\b", caseSensitive: false), 'cannot');
    cleaned = cleaned.replaceAll(
        RegExp(r'\bwont\b', caseSensitive: false), 'will not');
    cleaned =
        cleaned.replaceAll(RegExp(r'\bitm\b', caseSensitive: false), 'item');
    cleaned = cleaned.replaceAll(
        RegExp(r'\bqty\b', caseSensitive: false), 'quantity');
    cleaned =
        cleaned.replaceAll(RegExp(r'\bpcs\b', caseSensitive: false), 'pieces');
    cleaned = cleaned.replaceAll(RegExp(r'\bu\s+'), 'you '); // u to you
    cleaned = cleaned.replaceAll(RegExp(r'\br\b', caseSensitive: false), 'are');
    cleaned =
        cleaned.replaceAll(RegExp(r'\bur\b', caseSensitive: false), 'your');

    // Handle informal number words (common misspellings in Ugandan context)
    cleaned = cleaned.replaceAll(RegExp(r'\bn\b', caseSensitive: false), 'and');
    cleaned =
        cleaned.replaceAll(RegExp(r'\bw\b', caseSensitive: false), 'with');
    cleaned = cleaned.replaceAll(RegExp(r'\bb\b', caseSensitive: false), 'be');
    cleaned = cleaned.replaceAll(RegExp(r'\bc\b', caseSensitive: false), 'see');

    // Common typos in popular items
    cleaned =
        cleaned.replaceAll(RegExp(r'\bbread\b', caseSensitive: false), 'bread');
    cleaned =
        cleaned.replaceAll(RegExp(r'\bmillk\b', caseSensitive: false), 'milk');
    cleaned =
        cleaned.replaceAll(RegExp(r'\bsuger\b', caseSensitive: false), 'sugar');
    cleaned = cleaned.replaceAll(
        RegExp(r'\bwaater\b', caseSensitive: false), 'water');
    cleaned =
        cleaned.replaceAll(RegExp(r'\bsooda\b', caseSensitive: false), 'soda');
    cleaned =
        cleaned.replaceAll(RegExp(r'\bbrad\b', caseSensitive: false), 'bread');
    cleaned = cleaned.replaceAll(
        RegExp(r'\bbreaad\b', caseSensitive: false), 'bread');

    // Remove numbers (both digits and word numbers)
    cleaned = cleaned.replaceAll(RegExp(r'\d+'), '');

    // Also remove word numbers - these should not be in item name
    final wordNumbersToRemove = [
      'one',
      'two',
      'three',
      'four',
      'five',
      'six',
      'seven',
      'eight',
      'nine',
      'ten',
      'eleven',
      'twelve',
      'thirteen',
      'fourteen',
      'fifteen',
      'sixteen',
      'seventeen',
      'eighteen',
      'nineteen',
      'twenty',
      'thirty',
      'forty',
      'fifty',
      'sixty',
      'seventy',
      'eighty',
      'ninety',
      'hundred',
      'first',
      'second',
      'third',
      'fourth',
      'fifth',
      'sixth',
      'seventh',
      'eighth',
      'ninth',
      'tenth',
      'once',
      'twice',
      'thrice',
      'pair',
      'dozen',
      'couple',
      'few',
      'several',
      'bunch',
      'some'
    ];
    for (String num in wordNumbersToRemove) {
      cleaned =
          cleaned.replaceAll(RegExp('\\b$num\\b', caseSensitive: false), '');
    }

    // Remove price patterns
    cleaned = cleaned.replaceAll(
        RegExp(r'(?:ugx|shs|sh|shillings)\s*\d+', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(
        RegExp(r'\d+\s*(?:ugx|shs|sh|shillings|each|per)',
            caseSensitive: false),
        '');

    // Remove transaction type keywords (including Luganda variants)
    for (String keyword in [
      ...saleKeywords,
      ...expenseKeywords,
      ...purchaseKeywords,
      ...cashReceiptKeywords
    ]) {
      cleaned = cleaned.replaceAll(
          RegExp('\\b$keyword\\b', caseSensitive: false), '');
    }

    // Remove units
    for (String unit in unitPatterns) {
      cleaned =
          cleaned.replaceAll(RegExp('\\b$unit\\b', caseSensitive: false), '');
    }

    // Remove common words (expanded list)
    List<String> commonWords = [
      'the',
      'a',
      'an',
      'to',
      'from',
      'by',
      'with',
      'in',
      'on',
      'at',
      'of',
      'i',
      'me',
      'my',
      'we',
      'our',
      'us',
      'for',
      'and',
      'or',
      'but',
      'yesterday',
      'today',
      'tomorrow',
      'morning',
      'afternoon',
      'evening',
      'just',
      'only',
      'exactly',
      'total',
      'sum',
      'worth',
      'amount',
      'customer',
      'name',
      'called',
      'mr',
      'mrs',
      'miss',
      'sir',
      'then',
      'than',
      'that',
      'this',
      'these',
      'those',
      'have',
      'has',
      'had',
      'doing',
      'did',
      'done',
      'was',
      'were',
      'been',
      'being',
      'got',
      'getting',
      'give',
      'gave',
      'given',
      'take',
      'took',
      'taken',
      'come',
      'came',
      'coming',
      'go',
      'went',
      'going',
      'say',
      'said',
      'saying',
      'tell',
      'told',
      'know',
      'knew',
      'known',
      'think',
      'thought',
      'want',
      'wanted',
      'need',
      'needed',
      'like',
      'liked',
      'use',
      'used',
      'find',
      'found',
      'put',
      'putting',
      'keep',
      'kept',
      'let',
      'begin',
      'seem',
      'help',
      'show',
      'hear',
      'play',
      'run',
      'move',
      'live',
      'believe',
      'bring',
      'happen',
      'write',
      'provide',
      'sit',
      'stand',
      'lose',
      'pay',
      'meet',
      'include',
      'continue',
      'set',
      'learn',
      'change',
      'lead',
      'understand',
      'watch',
      'follow',
      'stop',
      'create',
      'speak',
      'read',
      'allow',
      'add',
      'spend',
      'grow',
      'open',
      'walk',
      'win',
      'offer',
      'remember',
      'love',
      'consider',
      'appear',
      'buy',
      'wait',
      'serve',
      'die',
      'send',
      'expect',
      'build',
      'stay',
      'fall',
      'cut',
      'reach',
      'kill',
      'remain',
      'please',
      'thank',
      'please',
      'sorry',
      'ok',
      'okay',
      'yes',
      'no',
      'yeah',
      'yep',
      'nope',
      'now',
      'here',
      'there',
      'all',
      'some',
      'any',
      'many',
      'much',
      'most',
      'other',
      'such',
      'own',
      'same',
      'too',
      'very',
      'just',
      'still',
      'even',
      'also',
      'already',
      'yet',
      'ever',
      'never',
      'again',
      'away',
      'around',
      'about',
      'back',
      'down',
      'up',
      'out',
      'off',
      'over',
      'under',
      'after',
      'before',
      'between',
      'during',
      'through',
      'above',
      'below'
    ];

    for (String word in commonWords) {
      cleaned =
          cleaned.replaceAll(RegExp('\\b$word\\b', caseSensitive: false), '');
    }

    // Clean up - remove extra spaces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (cleaned.isEmpty) return 'Unknown';

    // Capitalize properly
    cleaned = cleaned.split(' ').where((w) => w.isNotEmpty).map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');

    // Handle combined items (e.g., "bread and milk") - try to separate
    if (cleaned.contains(' & ') || cleaned.contains(' and ')) {
      // Keep as combined for now, will be parsed as multiple items
      return cleaned;
    }

    return cleaned.isNotEmpty ? cleaned : 'Unknown';
  }

  static String _detectCategory(String input, String itemName) {
    String searchText = '$input $itemName'.toLowerCase();
    List<String> words = searchText.split(RegExp(r'[\s,\-\.]+'));

    for (var entry in categoryItems.entries) {
      for (String item in entry.value) {
        if (words.contains(item)) {
          return entry.key;
        }
      }
    }

    return 'Other';
  }

  static String _extractCustomerName(String input) {
    // Pattern: "to John" or "from John" or "customer John" or "John paid"
    RegExp toPattern = RegExp(
        r'(?:to|from|customer|client|buyer)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)',
        caseSensitive: false);
    var match = toPattern.firstMatch(input);
    if (match != null) {
      return match.group(1)!;
    }

    // Pattern: "John paid" at the start
    RegExp paidPattern = RegExp(
        r'^([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)\s+(?:paid| bought| purchased)',
        caseSensitive: false);
    match = paidPattern.firstMatch(input);
    if (match != null) {
      return match.group(1)!;
    }

    return '';
  }

  static String _extractNotes(String input) {
    // Remove the main transaction parts to get notes
    String notes = input;

    // Remove price information
    notes = notes.replaceAll(
        RegExp(r'\d+\s*(?:ugx|shs|sh|shillings|each|per)?',
            caseSensitive: false),
        '');

    // Remove quantity
    notes = notes.replaceAll(
        RegExp(
            r'\d+\s*(?:pieces?|pcs?|pc|kgs?|kg|grams?|g|liters?|l|ml|packets?|packs?)?',
            caseSensitive: false),
        '');

    // Remove transaction types
    for (String keyword in [
      ...saleKeywords,
      ...expenseKeywords,
      ...purchaseKeywords
    ]) {
      notes =
          notes.replaceAll(RegExp('\\b$keyword\\b', caseSensitive: false), '');
    }

    // Clean up
    notes = notes.replaceAll(RegExp(r'\s+'), ' ').trim();

    // If notes is too long or equals item name, return empty
    if (notes.length > 100 || notes.toLowerCase() == input.toLowerCase()) {
      return '';
    }

    return notes;
  }

  static DateTime? _extractDate(String input) {
    String lower = input.toLowerCase();
    DateTime now = DateTime.now();

    if (lower.contains('yesterday')) {
      return DateTime(now.year, now.month, now.day - 1);
    }

    if (lower.contains('today')) {
      return DateTime(now.year, now.month, now.day);
    }

    if (lower.contains('tomorrow')) {
      return DateTime(now.year, now.month, now.day + 1);
    }

    // Try to find explicit date
    RegExp datePattern = RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{2,4})');
    var match = datePattern.firstMatch(input);
    if (match != null) {
      try {
        int day = int.parse(match.group(1)!);
        int month = int.parse(match.group(2)!);
        int year = int.parse(match.group(3)!);
        if (year < 100) year += 2000;
        return DateTime(year, month, day);
      } catch (e) {
        // Ignore parsing errors
      }
    }

    return null; // Default to current date
  }

  static double _parseNumber(String numStr) {
    String cleaned = numStr.replaceAll(',', '').replaceAll(' ', '');
    return double.tryParse(cleaned) ?? 0;
  }
}

class ParsedTransactionDetails {
  int quantity = 1;
  String unit = 'pcs';
  double unitPrice = 0;
  double totalPrice = 0;
  String itemName = 'Unknown';
  String category = 'Other';
  String customerName = '';
  String notes = '';
  DateTime? date;
}

class TransactionIntent {
  final TransactionType type;
  final double amount;
  final String itemName;
  final String description;
  final String category;
  final int quantity;
  final String unit;
  final double unitPrice;
  final String customerName;
  final String notes;
  final DateTime? transactionDate;

  // Support for multiple items
  final List<Map<String, dynamic>>? additionalItems;

  TransactionIntent({
    required this.type,
    required this.amount,
    required this.itemName,
    required this.description,
    required this.category,
    this.quantity = 1,
    this.unit = 'pcs',
    this.unitPrice = 0,
    this.customerName = '',
    this.notes = '',
    this.transactionDate,
    this.additionalItems,
  });

  bool get hasMultipleItems =>
      (additionalItems != null && additionalItems!.isNotEmpty) ||
      itemName.contains(',') ||
      itemName.contains(' and ');

  int get totalItemsCount {
    if (additionalItems != null && additionalItems!.isNotEmpty) {
      return 1 + additionalItems!.length;
    }
    if (itemName.contains(',') || itemName.contains(' and ')) {
      final items = itemName
          .split(RegExp(r'[, ]+and[, ]+|,'))
          .where((s) => s.trim().isNotEmpty)
          .toList();
      return items.length;
    }
    return 1;
  }
}
