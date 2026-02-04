import 'package:ismart_shop/models/transaction.dart';

class NLPService {
  // Keywords for transaction type detection
  static const List<String> saleKeywords = [
    'sold', 'sale', 'selling', 'bought', 'customer', 'gave', 'received',
    'ekyangu', 'bintu', 'musaayi', 'kintu', 'nfunye', 'yakuba'
  ];
  
  static const List<String> expenseKeywords = [
    'spent', 'expense', 'bought for', 'paid', 'cost', 'transport',
    'kunsanze', 'kusaze', 'kulya', 'ebikole', 'ebiri kugula'
  ];
  
  static const List<String> purchaseKeywords = [
    'purchased', 'bought stock', 'restocked', 'supplier',
    'kugula', 'kugula stock', 'akawuki'
  ];

  static const List<String> amountKeywords = [
    'shillings', 'ugx', 'ugx', 'pounds', 'dollars',
    'shs', 's', 'maka', 'ffe'
  ];

  static TransactionIntent parseTransaction(String input) {
    String lowerInput = input.toLowerCase();
    
    TransactionType type = _detectType(lowerInput);
    double amount = _extractAmount(lowerInput);
    String itemName = _extractItem(lowerInput);
    String category = _detectCategory(lowerInput);

    return TransactionIntent(
      type: type,
      amount: amount,
      itemName: itemName,
      description: input,
      category: category,
    );
  }

  static TransactionType _detectType(String input) {
    for (String keyword in saleKeywords) {
      if (input.contains(keyword)) {
        return TransactionType.sale;
      }
    }
    
    for (String keyword in expenseKeywords) {
      if (input.contains(keyword)) {
        return TransactionType.expense;
      }
    }
    
    for (String keyword in purchaseKeywords) {
      if (input.contains(keyword)) {
        return TransactionType.purchase;
      }
    }
    
    return TransactionType.sale;
  }

  static double _extractAmount(String input) {
    // Pattern to find amounts (e.g., "5000", "5,000", "5000sh", "sh5000")
    RegExp amountPattern = RegExp(r'(\d{1,3}(?:,\d{3})*(?:\.\d+)?)');
    RegExp ugxPattern = RegExp(r'(?:ugx|ugx|shs|sh)\s*(\d{1,3}(?:,\d{3})*(?:\.\d+)?)', caseSensitive: false);
    
    Match? match = ugxPattern.firstMatch(input);
    if (match != null) {
      String amountStr = match.group(1)!.replaceAll(',', '');
      return double.tryParse(amountStr) ?? 0;
    }
    
    match = amountPattern.firstMatch(input);
    if (match != null) {
      String amountStr = match.group(0)!.replaceAll(',', '');
      return double.tryParse(amountStr) ?? 0;
    }
    
    return 0;
  }

  static String _extractItem(String input) {
    // Remove amount-related text
    String cleaned = input
        .replaceAll(RegExp(r'\d{1,3}(?:,\d{3})*(?:\.\d+)?'), '')
        .replaceAll(RegExp(r'(?:ugx|ugx|shs|sh)\s*\d+', caseSensitive: false), '')
        .replaceAll(RegExp(r'sold|sale|spent|expense|bought|purchased', caseSensitive: false), '')
        .trim();

    // Split by common delimiters and get significant words
    List<String> words = cleaned.split(RegExp(r'\s+'));
    
    // Filter out small words and get meaningful item name
    String itemName = words
        .where((word) => word.length > 2)
        .take(3)
        .join(' ')
        .trim();
    
    return itemName.isNotEmpty ? itemName : 'Item';
  }

  static String _detectCategory(String input) {
    List<String> lowerInput = input.toLowerCase().split(' ');
    
    // Food and beverages
    if (lowerInput.any((w) => ['bread', 'milk', 'soda', 'water', 'food', 'rice', 'meat', 'fish', 'egg', 'posho', 'matoke'].contains(w))) {
      return 'Food & Beverages';
    }
    
    // Household items
    if (lowerInput.any((w) => ['soap', 'toothpaste', 'brush', 'detergent', 'bucket', 'cup', 'plate'].contains(w))) {
      return 'Household';
    }
    
    // Transport
    if (lowerInput.any((w) => ['transport', 'fuel', 'taxi', 'boda', 'fare', 'petrol', 'diesel'].contains(w))) {
      return 'Transport';
    }
    
    // Phone credit
    if (lowerInput.any((w) => ['airtime', 'credit', 'mtn', 'airtel', 'vodafone'].contains(w))) {
      return 'Communication';
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
