import 'package:flutter_test/flutter_test.dart';
import 'package:ismart_shop/models/transaction.dart';
import 'package:ismart_shop/models/transaction_item.dart';
import 'package:ismart_shop/services/nlp_service.dart';

void main() {
  group('NLP Service Tests', () {
    test('Parse sale transaction', () {
      const input = 'Sold bread for 5000 shillings';
      final result = NLPService.parseTransaction(input);

      expect(result.type, TransactionType.sale);
      expect(result.amount, 5000);
      expect(result.itemName.isNotEmpty, true);
    });

    test('Parse expense transaction', () {
      const input = 'Spent 20000 on transport';
      final result = NLPService.parseTransaction(input);

      expect(result.type, TransactionType.expense);
      expect(result.amount, 20000);
    });

    test('Parse purchase transaction', () {
      const input = 'Bought stock for 500000';
      final result = NLPService.parseTransaction(input);

      expect(result.type, TransactionType.purchase);
      expect(result.amount, 500000);
    });

    test('Extract amount with currency symbol', () {
      const input = 'Sold milk for ugx 3000';
      final result = NLPService.parseTransaction(input);

      expect(result.amount, 3000);
    });

    test('Default to sale if no keywords found', () {
      const input = 'Some random text without keywords';
      final result = NLPService.parseTransaction(input);

      expect(result.type, TransactionType.sale);
    });
  });

  group('Transaction Model Tests', () {
    test('Create transaction with all fields', () {
      // Create a sample item
      final item = TransactionItem(
        id: 'item-1',
        itemName: 'Bread',
        quantity: 1,
        unit: QuantityUnit.pcs,
        pricePerUnit: 5000,
        amount: 5000,
      );

      final transaction = Transaction(
        id: 'test-id',
        type: TransactionType.sale,
        items: [item],
        totalAmount: 5000,
        description: 'Sold bread for 5000',
        createdAt: DateTime.now(),
        userId: 'user-id',
        category: 'Food',
      );

      expect(transaction.id, 'test-id');
      expect(transaction.type, TransactionType.sale);
      expect(transaction.primaryItemName, 'Bread');
      expect(transaction.totalAmount, 5000);
      expect(transaction.category, 'Food');
      expect(transaction.itemCount, 1);
    });

    test('Copy transaction with modified fields', () {
      final item = TransactionItem(
        id: 'item-1',
        itemName: 'Bread',
        quantity: 1,
        unit: QuantityUnit.pcs,
        pricePerUnit: 5000,
        amount: 5000,
      );

      final original = Transaction(
        id: 'test-id',
        type: TransactionType.sale,
        items: [item],
        totalAmount: 5000,
        description: 'Sold bread',
        createdAt: DateTime.now(),
        userId: 'user-id',
      );

      final modifiedItem = TransactionItem(
        id: 'item-1',
        itemName: 'Milk',
        quantity: 1,
        unit: QuantityUnit.pcs,
        pricePerUnit: 6000,
        amount: 6000,
      );

      final modified = original.copyWith(
        items: [modifiedItem],
        totalAmount: 6000,
      );

      expect(modified.totalAmount, 6000);
      expect(modified.primaryItemName, 'Milk');
      expect(modified.id, original.id);
    });

    test('Legacy getters work for backward compatibility', () {
      final item = TransactionItem(
        id: 'item-1',
        itemName: 'Bread',
        quantity: 1,
        unit: QuantityUnit.pcs,
        pricePerUnit: 5000,
        amount: 5000,
      );

      final transaction = Transaction(
        id: 'test-id',
        type: TransactionType.sale,
        items: [item],
        totalAmount: 5000,
        description: 'Sold bread',
        createdAt: DateTime.now(),
        userId: 'user-id',
      );

      // Legacy getters should still work
      expect(transaction.itemName, 'Bread');
      expect(transaction.amount, 5000);
    });
  });

  group('TransactionItem Tests', () {
    test('Create item with auto-calculated amount', () {
      final item = TransactionItem.create(
        itemName: 'Sugar',
        quantity: 2,
        unit: QuantityUnit.kgs,
        pricePerUnit: 5000,
      );

      expect(item.itemName, 'Sugar');
      expect(item.quantity, 2);
      expect(item.unit, QuantityUnit.kgs);
      expect(item.pricePerUnit, 5000);
      expect(item.amount, 10000); // Auto-calculated: 2 * 5000
    });

    test('Get unit display string', () {
      expect(
          TransactionItem(
                  id: '1',
                  itemName: 'Test',
                  quantity: 1,
                  unit: QuantityUnit.pcs,
                  pricePerUnit: 100,
                  amount: 100)
              .unitDisplay,
          'pcs');
      expect(
          TransactionItem(
                  id: '1',
                  itemName: 'Test',
                  quantity: 1,
                  unit: QuantityUnit.kgs,
                  pricePerUnit: 100,
                  amount: 100)
              .unitDisplay,
          'kgs');
      expect(
          TransactionItem(
                  id: '1',
                  itemName: 'Test',
                  quantity: 1,
                  unit: QuantityUnit.grams,
                  pricePerUnit: 100,
                  amount: 100)
              .unitDisplay,
          'grams');
    });

    test('Get quantity display string', () {
      expect(
          TransactionItem(
                  id: '1',
                  itemName: 'Test',
                  quantity: 2.5,
                  unit: QuantityUnit.kgs,
                  pricePerUnit: 100,
                  amount: 250)
              .quantityDisplay,
          '2.50 kgs');
    });
  });
}
