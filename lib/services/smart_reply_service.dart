import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Smart Reply Service - Provides intelligent automated responses
/// based on speech input patterns and business context
class SmartReplyService {
  /// Analyze the transcribed text and return an appropriate response
  static String generateSmartReply(
      String input, Map<String, dynamic> businessData) {
    final lowerInput = input.toLowerCase().trim();

    // Extract key business metrics
    final todaySales = _extractDouble(businessData, "Today's Sales") ?? 0;
    final todayExpenses = _extractDouble(businessData, "Today's Expenses") ?? 0;
    final todayProfit = _extractDouble(businessData, "Today's Profit") ?? 0;
    final weekSales = _extractDouble(businessData, "This Week's Sales") ?? 0;
    final monthSales = _extractDouble(businessData, "This Month's Sales") ?? 0;
    final totalTransactions =
        _extractDouble(businessData, "Total Transactions") ?? 0;

    // Greeting patterns
    if (_matchesPattern(lowerInput, [
      'hello',
      'hi',
      'hey',
      'good morning',
      'good afternoon',
      'good evening'
    ])) {
      return _generateGreeting(todaySales, totalTransactions);
    }

    // Thank you patterns
    if (_matchesPattern(lowerInput, ['thank', 'thanks', 'thank you'])) {
      return _generateThankYouResponse();
    }

    // Sales queries
    if (_matchesPattern(lowerInput,
        ['how much', 'sales', 'sold', 'revenue', 'income', 'earnings'])) {
      return _generateSalesResponse(todaySales, weekSales, monthSales);
    }

    // Profit queries
    if (_matchesPattern(
        lowerInput, ['profit', 'earnings', 'margin', 'how much did i make'])) {
      return _generateProfitResponse(todayProfit, todaySales, todayExpenses);
    }

    // Expense queries
    if (_matchesPattern(
        lowerInput, ['expense', 'spent', 'cost', 'money out'])) {
      return _generateExpenseResponse(todayExpenses);
    }

    // Inventory queries
    if (_matchesPattern(
        lowerInput, ['inventory', 'stock', 'products', 'items'])) {
      return _generateInventoryResponse(totalTransactions);
    }

    // Transaction recording patterns
    if (_isTransactionIntent(lowerInput)) {
      return _generateTransactionGuidance(lowerInput);
    }

    // Help requests
    if (_matchesPattern(
        lowerInput, ['help', 'what can you do', 'how to', 'how do i'])) {
      return _generateHelpResponse();
    }

    // Default response
    return _generateDefaultResponse(
        todaySales, todayExpenses, totalTransactions);
  }

  static bool _matchesPattern(String input, List<String> patterns) {
    return patterns.any((pattern) => input.contains(pattern));
  }

  static double? _extractDouble(Map<String, dynamic> data, String key) {
    try {
      final value = data[key];
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
        return double.tryParse(cleaned);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  static String _generateGreeting(double todaySales, double totalTransactions) {
    final hour = DateTime.now().hour;
    String timeGreeting;

    if (hour < 12) {
      timeGreeting = 'Good morning';
    } else if (hour < 17) {
      timeGreeting = 'Good afternoon';
    } else {
      timeGreeting = 'Good evening';
    }

    String salesComment = '';
    if (todaySales > 0) {
      salesComment =
          '\n\n📈 Great to see you\'re tracking your business! Today\'s sales: UGX ${_formatNumber(todaySales)}';
    } else if (totalTransactions > 0) {
      salesComment =
          '\n\n📊 You have ${totalTransactions.toInt()} transactions recorded. Ready to add more?';
    }

    return '$timeGreeting! 👋 I\'m your iSmart AI assistant, here to help you manage your shop.$salesComment\n\n💡 Try saying:\n• "Sold 5 bread at 2000"\n• "How much did I sell today?"\n• "What\'s my profit?"';
  }

  static String _generateThankYouResponse() {
    return 'You\'re very welcome! 😊\n\nI\'m here to help you grow your business. Feel free to ask me anything about your sales, expenses, or inventory. 📈\n\nWhat would you like to do next?';
  }

  static String _generateSalesResponse(
      double todaySales, double weekSales, double monthSales) {
    if (todaySales == 0 && weekSales == 0 && monthSales == 0) {
      return '📊 Sales Summary\n\n'
          'Today: UGX 0\n'
          'This Week: UGX 0\n'
          'This Month: UGX 0\n\n'
          '💡 You haven\'t recorded any sales yet. Start by saying:\n'
          '"Sold 5 bread at 2000"\n'
          '"Sold 2 milk at 1500 each"\n\n'
          'Every big business starts with the first sale! 🚀';
    }

    String response = '📊 Your Sales Summary\n\n';
    if (todaySales > 0) {
      response += '📅 Today: UGX ${_formatNumber(todaySales)}\n';
    } else {
      response += '📅 Today: UGX 0\n';
    }

    if (weekSales > 0) {
      response += '📆 This Week: UGX ${_formatNumber(weekSales)}\n';
    }

    if (monthSales > 0) {
      response += '📆 This Month: UGX ${_formatNumber(monthSales)}\n';
    }

    // Add insights
    if (todaySales > 0 && weekSales > 0) {
      final dailyAverage = weekSales / 7;
      if (todaySales >= dailyAverage) {
        response +=
            '\n🌟 Great job! You\'re above your daily average of UGX ${_formatNumber(dailyAverage)}';
      } else {
        response +=
            '\n💪 Keep pushing! Your daily average is UGX ${_formatNumber(dailyAverage)}';
      }
    }

    return response;
  }

  static String _generateProfitResponse(
      double profit, double sales, double expenses) {
    if (profit == 0 && sales == 0) {
      return '💰 Profit Analysis\n\n'
          'No profit data available yet.\n\n'
          '💡 To track profit:\n'
          '1. Record your sales: "Sold 5 bread at 2000"\n'
          '2. Record your expenses: "Spent 10000 on transport"\n'
          '3. I\'ll calculate your profit automatically!\n\n'
          'Profit = Sales - Expenses 📈';
    }

    String response = '💰 Profit Analysis\n\n';
    response += 'Today\'s Profit: UGX ${_formatNumber(profit)}\n';

    if (sales > 0) {
      final margin = (profit / sales * 100);
      response += 'Profit Margin: ${margin.toStringAsFixed(1)}%\n';

      if (margin > 30) {
        response += '🌟 Excellent margin! You\'re doing great!';
      } else if (margin > 15) {
        response += '💪 Good margin. Keep it up!';
      } else {
        response += '💡 Tip: Focus on higher-margin items to increase profit.';
      }
    }

    return response;
  }

  static String _generateExpenseResponse(double expenses) {
    if (expenses == 0) {
      return '💸 Expense Tracker\n\n'
          'No expenses recorded today! 🎉\n\n'
          '💡 Record expenses by saying:\n'
          '"Spent 5000 on transport"\n'
          '"Paid 10000 for rent"\n'
          '"Bought packaging materials 3000"';
    }

    return '💸 Today\'s Expenses: UGX ${_formatNumber(expenses)}\n\n'
        '💡 Tip: Keep tracking expenses to maximize your profit!\n\n'
        'Remember: Profit = Sales - Expenses';
  }

  static String _generateInventoryResponse(double totalTransactions) {
    return '📦 Inventory & Products\n\n'
        '${totalTransactions > 0 ? "You have ${totalTransactions.toInt()} transactions recorded." : "No transactions yet."}\n\n'
        '💡 To add products:\n'
        '• Say: "Add product Bread, price 5000, quantity 100"\n'
        '• Or go to Inventory screen and tap "Add Product"\n\n'
        '📊 Tip: Keep your inventory updated to avoid stockouts!';
  }

  static bool _isTransactionIntent(String input) {
    final patterns = [
      r'\bsold\b',
      r'\bsell\b',
      r'\bsale\b',
      r'\bspent\b',
      r'\bexpense\b',
      r'\bpaid\b',
      r'\bbought\b',
      r'\bpurchase\b',
      r'\bstock\b',
      r'\bi\s+(sold|bought|spent|paid)\b',
      r'\b(sold|bought|spent)\s+\d+',
      r'\bat\s+\d+',
      r'\bfor\s+\d+',
    ];

    return patterns.any((pattern) => RegExp(pattern).hasMatch(input));
  }

  static String _generateTransactionGuidance(String input) {
    // Check if it's a sale
    if (input.contains('sold') || input.contains('sell')) {
      return '📝 I understand you want to record a SALE.\n\n'
          '💡 To help me understand better, please include:\n'
          '• Item name (what did you sell?)\n'
          '• Quantity (how many?)\n'
          '• Price (at what price?)\n\n'
          'Example: "Sold 5 bread at 2000"\n'
          'Example: "Sold 2 milk and 3 bread at 1500 each"\n\n'
          'Try again with more details! 🎯';
    }

    // Check if it's an expense
    if (input.contains('spent') ||
        input.contains('expense') ||
        input.contains('paid')) {
      return '💸 I understand you want to record an EXPENSE.\n\n'
          '💡 Please include:\n'
          '• What you spent on\n'
          '• Amount\n\n'
          'Example: "Spent 10000 on transport"\n'
          'Example: "Paid 5000 for electricity"\n\n'
          'Try again with more details! 🎯';
    }

    // Check if it's a purchase
    if (input.contains('bought') ||
        input.contains('purchase') ||
        input.contains('stock')) {
      return '📦 I understand you want to record a PURCHASE/RESTOCK.\n\n'
          '💡 Please include:\n'
          '• Item name\n'
          '• Quantity\n'
          '• Price per unit\n\n'
          'Example: "Bought 10 packets sugar at 3000"\n'
          'Example: "Purchased 5 bags rice at 25000"\n\n'
          'Try again with more details! 🎯';
    }

    return '📝 I can help you record transactions!\n\n'
        '💡 Please be specific:\n'
        '• "Sold 5 bread at 2000"\n'
        '• "Spent 10000 on transport"\n'
        '• "Bought 10 sugar at 3000"\n\n'
        'What would you like to record? 🎯';
  }

  static String _generateHelpResponse() {
    return '🤖 I\'m your iSmart AI assistant! Here\'s what I can do:\n\n'
        '📝 **Record Transactions:**\n'
        '• "Sold 5 bread at 2000"\n'
        '• "Spent 10000 on transport"\n'
        '• "Bought 10 sugar at 3000"\n\n'
        '💰 **Business Queries:**\n'
        '• "How much did I sell today?"\n'
        '• "What\'s my profit?"\n'
        '• "Show my expenses"\n\n'
        '📦 **Inventory Management:**\n'
        '• "Add product Bread, price 5000"\n\n'
        '🖨️ **Printing:**\n'
        '• "Print my last receipt"\n'
        '• "Print daily report"\n\n'
        'Just speak or type your request! 🎯';
  }

  static String _generateDefaultResponse(
      double todaySales, double expenses, double totalTransactions) {
    if (todaySales > 0 || expenses > 0) {
      return '📊 Quick Overview:\n\n'
          'Today\'s Sales: UGX ${_formatNumber(todaySales)}\n'
          'Today\'s Expenses: UGX ${_formatNumber(expenses)}\n'
          'Total Transactions: ${totalTransactions.toInt()}\n\n'
          '💡 Ask me:\n'
          '• "How much did I sell?"\n'
          '• "What\'s my profit?"\n'
          '• "Show my expenses"\n\n'
          'Or record a new transaction! 🎯';
    }

    return '👋 Hello! I\'m your iSmart AI assistant! 🚀\n\n'
        'I can help you:\n\n'
        '📝 Record transactions:\n'
        '• "Sold 5 bread at 2000"\n'
        '• "Spent 10000 on transport"\n\n'
        '💰 Answer questions:\n'
        '• "How much did I sell today?"\n'
        '• "What\'s my profit?"\n\n'
        '📦 Manage inventory:\n'
        '• "Add product Sugar, price 5000"\n\n'
        'Start recording your first transaction! 📈';
  }

  static String _formatNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return NumberFormat('#,###').format(value);
    }
    return value.toStringAsFixed(0);
  }

  /// Extract structured data from transaction text
  static Map<String, dynamic>? extractTransactionData(String text) {
    final lowerText = text.toLowerCase();

    // Determine transaction type
    String type = 'sale';
    if (lowerText.contains('spent') ||
        lowerText.contains('expense') ||
        lowerText.contains('paid') ||
        lowerText.contains('cost')) {
      type = 'expense';
    } else if (lowerText.contains('bought') ||
        lowerText.contains('purchase') ||
        lowerText.contains('stock') ||
        lowerText.contains('restock')) {
      type = 'purchase';
    }

    // Extract item name
    String? item;
    final itemPatterns = [
      RegExp(
          r'(?:sold|bought|purchase|spent|paid)\s+(\d+)\s+([\w\s]+?)\s+(?:at|for|each|@)'),
      RegExp(
          r'(?:sold|bought|purchase)\s+([\w\s]+?)\s+(\d+)\s+(?:at|for|each|@)'),
      RegExp(r'(?:sold|bought|purchase)\s+([\w\s]+?)\s+(?:at|for|@)\s+(\d+)'),
      RegExp(r'spent\s+(\d+)\s+on\s+([\w\s]+)'),
      RegExp(r'paid\s+(\d+)\s+for\s+([\w\s]+)'),
    ];

    for (final pattern in itemPatterns) {
      final match = pattern.firstMatch(lowerText);
      if (match != null) {
        if (pattern.toString().contains(r'(\d+)\s+([\w\s]+)')) {
          item = match.group(2)?.trim();
        } else {
          item = match.group(1)?.trim();
        }
        break;
      }
    }

    // Extract quantity
    int quantity = 1;
    final qtyPatterns = [
      RegExp(r'(?:sold|bought|purchase)\s+(\d+)\s+'),
      RegExp(r'spent\s+(\d+)\s+'),
      RegExp(r'paid\s+(\d+)\s+'),
    ];

    for (final pattern in qtyPatterns) {
      final match = pattern.firstMatch(lowerText);
      if (match != null) {
        quantity = int.tryParse(match.group(1) ?? '1') ?? 1;
        break;
      }
    }

    // Extract price
    double price = 0;
    final pricePatterns = [
      RegExp(r'(?:at|for|@)\s+(\d+)'),
      RegExp(r'(\d+)\s+(?:shillings|ugx|ugandan)'),
    ];

    for (final pattern in pricePatterns) {
      final match = pattern.firstMatch(lowerText);
      if (match != null) {
        price = double.tryParse(match.group(1) ?? '0') ?? 0;
        break;
      }
    }

    if (item == null || item.isEmpty) return null;

    return {
      'type': type,
      'item': item,
      'quantity': quantity,
      'unitPrice': price,
      'total': price * quantity,
    };
  }
}
