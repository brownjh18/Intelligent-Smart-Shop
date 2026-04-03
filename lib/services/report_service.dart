import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:ismart_shop/models/transaction.dart';
import 'package:flutter/foundation.dart';

class ReportService {
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy HH:mm');
  static final NumberFormat _currencyFormat = NumberFormat('#,###');

  /// Get the downloads directory based on platform
  static Future<Directory> _getDownloadsDirectory() async {
    if (kIsWeb) {
      // Web doesn't have access to filesystem, use documents directory
      return await getApplicationDocumentsDirectory();
    }

    if (Platform.isAndroid) {
      // On Android, try to get external storage (Downloads folder)
      // For Android 10+ (API 29+), we use app-specific external storage
      // which is accessible in the Downloads folder via Files app
      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          // Navigate to Downloads folder
          final downloadsPath = externalDir.path.replaceFirst(
            RegExp(r'/Android/data/[^/]+/files'),
            '/Download',
          );
          final downloadsDir = Directory(downloadsPath);
          if (await downloadsDir.exists()) {
            return downloadsDir;
          }
        }
      } catch (e) {
        // Fall back to app documents directory
      }

      // Fallback to app's documents directory
      return await getApplicationDocumentsDirectory();
    }

    if (Platform.isIOS) {
      // On iOS, save to app's Documents folder which is accessible via Files app
      return await getApplicationDocumentsDirectory();
    }

    // Default fallback
    return await getApplicationDocumentsDirectory();
  }

  /// Generate a receipt PDF
  static Future<String> generateReceipt(Transaction transaction) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Text(
                  'iSMART SHOP',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.Text(
                  'Receipt',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Receipt number and date
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                      'Receipt #: ${transaction.id.substring(0, 8).toUpperCase()}'),
                  pw.Text(_dateTimeFormat.format(transaction.createdAt)),
                ],
              ),
              pw.SizedBox(height: 15),

              // Transaction type
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: _getTypeColor(transaction.type),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  transaction.type.name.toUpperCase(),
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 15),

              // Items table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  // Header row
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Item',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Qty',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Price',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Total',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right),
                      ),
                    ],
                  ),
                  // Item rows
                  ...transaction.items.map((item) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(item.itemName),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                                '${item.quantity.toStringAsFixed(0)} ${item.unitDisplay}',
                                textAlign: pw.TextAlign.center),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                                _currencyFormat.format(item.pricePerUnit),
                                textAlign: pw.TextAlign.right),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(_currencyFormat.format(item.amount),
                                textAlign: pw.TextAlign.right),
                          ),
                        ],
                      )),
                ],
              ),
              pw.SizedBox(height: 15),

              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('TOTAL: ',
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                      'UGX ${_currencyFormat.format(transaction.totalAmount)}',
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ],
              ),

              // Category and customer
              if (transaction.category != null ||
                  transaction.customerName != null) ...[
                pw.SizedBox(height: 15),
                pw.Divider(),
                if (transaction.category != null)
                  pw.Text('Category: ${transaction.category}'),
                if (transaction.customerName != null)
                  pw.Text('Customer: ${transaction.customerName}'),
              ],

              // Notes
              if (transaction.notes != null &&
                  transaction.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 10),
                pw.Text('Notes: ${transaction.notes}'),
              ],

              // Footer
              pw.Spacer(),
              pw.Divider(),
              pw.Center(
                child: pw.Text(
                  'Thank you for your business!',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Save the PDF
    final output = await _getDownloadsDirectory();
    final fileName =
        'receipt_${transaction.id.substring(0, 8)}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  /// Print receipt directly using the printing package
  /// Parameters:
  /// - transaction: The transaction to print
  /// - receiptNumber: Optional receipt number to display (defaults to transaction id)
  static Future<void> printReceipt(Transaction transaction,
      {String? receiptNumber}) async {
    final pdf = pw.Document();

    // Use receipt number or generate from transaction ID
    final displayReceiptNumber = receiptNumber ??
        (transaction.id.isNotEmpty
            ? transaction.id.substring(0, 8).toUpperCase()
            : 'N/A');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Text(
                  'iSMART SHOP',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.Text(
                  'Receipt',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Receipt number and date
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Receipt #: $displayReceiptNumber'),
                  pw.Text(_dateTimeFormat.format(transaction.createdAt)),
                ],
              ),
              pw.SizedBox(height: 15),

              // Transaction type
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: _getTypeColor(transaction.type),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  transaction.type.name.toUpperCase(),
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 15),

              // Items table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  // Header row
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Item',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Qty',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Price',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Total',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right),
                      ),
                    ],
                  ),
                  // Item rows
                  ...transaction.items.map((item) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(item.itemName),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                                '${item.quantity.toStringAsFixed(0)} ${item.unitDisplay}',
                                textAlign: pw.TextAlign.center),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                                _currencyFormat.format(item.pricePerUnit),
                                textAlign: pw.TextAlign.right),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(_currencyFormat.format(item.amount),
                                textAlign: pw.TextAlign.right),
                          ),
                        ],
                      )),
                ],
              ),
              pw.SizedBox(height: 15),

              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('TOTAL: ',
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                      'UGX ${_currencyFormat.format(transaction.totalAmount)}',
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ],
              ),

              // Category and customer
              if (transaction.category != null ||
                  transaction.customerName != null) ...[
                pw.SizedBox(height: 15),
                pw.Divider(),
                if (transaction.category != null)
                  pw.Text('Category: ${transaction.category}'),
                if (transaction.customerName != null)
                  pw.Text('Customer: ${transaction.customerName}'),
              ],

              // Notes
              if (transaction.notes != null &&
                  transaction.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 10),
                pw.Text('Notes: ${transaction.notes}'),
              ],

              // Footer
              pw.Spacer(),
              pw.Divider(),
              pw.Center(
                child: pw.Text(
                  'Thank you for your business!',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Print the PDF directly using the printing package
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Receipt_$displayReceiptNumber',
    );
  }

  /// Generate sales records Excel file
  static Future<String> generateSalesExcel(List<Transaction> transactions,
      {DateTime? startDate, DateTime? endDate}) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sales Records'];

    // Title
    sheet.appendRow([TextCellValue('iSMART SHOP - Sales Records')]);
    if (startDate != null && endDate != null) {
      sheet.appendRow([
        TextCellValue(
            'Period: ${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}')
      ]);
    }
    sheet.appendRow([]);

    // Headers
    final headers = [
      'Date',
      'Item',
      'Quantity',
      'Unit',
      'Unit Price',
      'Total',
      'Category',
      'Customer',
      'Notes'
    ];
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    // Data
    double totalSales = 0;
    for (var transaction
        in transactions.where((t) => t.type == TransactionType.sale)) {
      for (var item in transaction.items) {
        sheet.appendRow([
          TextCellValue(_dateTimeFormat.format(transaction.createdAt)),
          TextCellValue(item.itemName),
          TextCellValue(item.quantity.toStringAsFixed(0)),
          TextCellValue(item.unitDisplay),
          TextCellValue(_currencyFormat.format(item.pricePerUnit)),
          TextCellValue(_currencyFormat.format(item.amount)),
          TextCellValue(transaction.category ?? ''),
          TextCellValue(transaction.customerName ?? ''),
          TextCellValue(transaction.notes ?? ''),
        ]);
        totalSales += item.amount;
      }
    }

    // Total row
    sheet.appendRow([]);
    sheet.appendRow([
      TextCellValue('TOTAL'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(_currencyFormat.format(totalSales)),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
    ]);

    // Save file
    final output = await _getDownloadsDirectory();
    final fileName = 'sales_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File('${output.path}/$fileName');
    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }

    return file.path;
  }

  /// Generate expense records Excel file
  static Future<String> generateExpenseExcel(List<Transaction> transactions,
      {DateTime? startDate, DateTime? endDate}) async {
    final excel = Excel.createExcel();
    final sheet = excel['Expense Records'];

    // Title
    sheet.appendRow([TextCellValue('iSMART SHOP - Expense Records')]);
    if (startDate != null && endDate != null) {
      sheet.appendRow([
        TextCellValue(
            'Period: ${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}')
      ]);
    }
    sheet.appendRow([]);

    // Headers
    final headers = ['Date', 'Item/Description', 'Amount', 'Category', 'Notes'];
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    // Data
    double totalExpenses = 0;
    for (var transaction
        in transactions.where((t) => t.type == TransactionType.expense)) {
      for (var item in transaction.items) {
        sheet.appendRow([
          TextCellValue(_dateTimeFormat.format(transaction.createdAt)),
          TextCellValue(item.itemName),
          TextCellValue(_currencyFormat.format(item.amount)),
          TextCellValue(transaction.category ?? 'Other'),
          TextCellValue(transaction.notes ?? ''),
        ]);
        totalExpenses += item.amount;
      }
    }

    // Total row
    sheet.appendRow([]);
    sheet.appendRow([
      TextCellValue('TOTAL'),
      TextCellValue(''),
      TextCellValue(_currencyFormat.format(totalExpenses)),
      TextCellValue(''),
      TextCellValue(''),
    ]);

    // Save file
    final output = await _getDownloadsDirectory();
    final fileName = 'expenses_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File('${output.path}/$fileName');
    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }

    return file.path;
  }

  /// Generate daily sales report
  static Future<String> generateDailyReport(
      List<Transaction> transactions, DateTime date) async {
    final pdf = pw.Document();

    // Filter transactions for the day
    final dayTransactions = transactions
        .where((t) =>
            t.createdAt.year == date.year &&
            t.createdAt.month == date.month &&
            t.createdAt.day == date.day)
        .toList();

    // Calculate totals
    double totalSales = 0;
    double totalExpenses = 0;
    double totalPurchases = 0;
    Map<String, double> salesByCategory = {};
    Map<String, int> itemsSoldCount = {};

    for (var t in dayTransactions) {
      switch (t.type) {
        case TransactionType.sale:
          totalSales += t.totalAmount;
          for (var item in t.items) {
            salesByCategory[t.category ?? 'Other'] =
                (salesByCategory[t.category ?? 'Other'] ?? 0) + item.amount;
            itemsSoldCount[item.itemName] =
                (itemsSoldCount[item.itemName] ?? 0) + item.quantity.toInt();
          }
          break;
        case TransactionType.expense:
          totalExpenses += t.totalAmount;
          break;
        case TransactionType.purchase:
          totalPurchases += t.totalAmount;
          break;
        case TransactionType.cashReceipt:
          // Cash receipts don't affect daily totals
          break;
      }
    }

    final profit = totalSales - totalExpenses;

    // Find top item
    String topItem = 'N/A';
    int maxSold = 0;
    itemsSoldCount.forEach((item, count) {
      if (count > maxSold) {
        maxSold = count;
        topItem = item;
      }
    });

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Text(
                  'iSMART SHOP',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.Text(
                  'Daily Sales Report',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Center(
                child: pw.Text(_dateFormat.format(date)),
              ),
              pw.Divider(),
              pw.SizedBox(height: 15),

              // Summary section
              pw.Text('SUMMARY',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: 10),

              pw.Row(
                children: [
                  pw.Expanded(
                    child: _buildSummaryBox(
                        'Total Sales', totalSales, PdfColors.green),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: _buildSummaryBox(
                        'Total Expenses', totalExpenses, PdfColors.red),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: _buildSummaryBox('Net Profit', profit,
                        profit >= 0 ? PdfColors.blue : PdfColors.orange),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Sales by category
              pw.Text('SALES BY CATEGORY',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: 10),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Category',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Amount',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Percentage',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right),
                      ),
                    ],
                  ),
                  ...salesByCategory.entries.map((e) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(e.key),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(_currencyFormat.format(e.value),
                                textAlign: pw.TextAlign.right),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                                '${(e.value / totalSales * 100).toStringAsFixed(1)}%',
                                textAlign: pw.TextAlign.right),
                          ),
                        ],
                      )),
                ],
              ),
              pw.SizedBox(height: 20),

              // Top selling items
              pw.Text('TOP SELLING ITEMS',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: 10),

              pw.Text('Most Sold: $topItem ($maxSold items)'),
              pw.SizedBox(height: 20),

              // Transaction details
              pw.Text('TRANSACTION DETAILS',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: 10),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Time',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Type',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Item',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Amount',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right),
                      ),
                    ],
                  ),
                  ...dayTransactions.map((t) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(_timeFormat.format(t.createdAt)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(t.type.name.toUpperCase()),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(t.itemNames),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                                _currencyFormat.format(t.totalAmount),
                                textAlign: pw.TextAlign.right),
                          ),
                        ],
                      )),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Center(
                child: pw.Text(
                    'Generated on ${_dateTimeFormat.format(DateTime.now())}'),
              ),
            ],
          );
        },
      ),
    );

    // Save the PDF
    final output = await _getDownloadsDirectory();
    final fileName =
        'daily_report_${DateFormat('yyyyMMdd').format(date)}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  /// Generate profit summary report
  static Future<String> generateProfitSummary(List<Transaction> transactions,
      {DateTime? startDate, DateTime? endDate}) async {
    final pdf = pw.Document();

    // Filter transactions by date range if provided
    var filteredTransactions = transactions;
    if (startDate != null && endDate != null) {
      filteredTransactions = transactions
          .where((t) =>
              t.createdAt
                  .isAfter(startDate.subtract(const Duration(days: 1))) &&
              t.createdAt.isBefore(endDate.add(const Duration(days: 1))))
          .toList();
    }

    // Calculate totals
    double totalSales = 0;
    double totalExpenses = 0;
    double totalPurchases = 0;
    int totalTransactions = filteredTransactions.length;
    Map<String, double> salesByCategory = {};
    Map<String, double> expensesByCategory = {};

    for (var t in filteredTransactions) {
      switch (t.type) {
        case TransactionType.sale:
          totalSales += t.totalAmount;
          for (var item in t.items) {
            salesByCategory[t.category ?? 'Other'] =
                (salesByCategory[t.category ?? 'Other'] ?? 0) + item.amount;
          }
          break;
        case TransactionType.expense:
          totalExpenses += t.totalAmount;
          expensesByCategory[t.category ?? 'Other'] =
              (expensesByCategory[t.category ?? 'Other'] ?? 0) + t.totalAmount;
          break;
        case TransactionType.purchase:
          totalPurchases += t.totalAmount;
          break;
        case TransactionType.cashReceipt:
          // Cash receipts don't affect sales/expenses
          break;
      }
    }

    final profit = totalSales - totalExpenses;
    final double profitMargin =
        totalSales > 0 ? (profit / totalSales * 100) : 0;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Text(
                  'iSMART SHOP',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.Text(
                  'Profit & Loss Summary',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
              ),
              if (startDate != null && endDate != null)
                pw.Center(
                  child: pw.Text(
                      '${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}'),
                ),
              pw.Divider(),
              pw.SizedBox(height: 15),

              // Summary boxes
              pw.Text('FINANCIAL OVERVIEW',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: 10),

              pw.Row(
                children: [
                  pw.Expanded(
                      child: _buildSummaryBox(
                          'Total Sales', totalSales, PdfColors.green)),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                      child: _buildSummaryBox(
                          'Total Expenses', totalExpenses, PdfColors.red)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                children: [
                  pw.Expanded(
                      child: _buildSummaryBox('Net Profit', profit,
                          profit >= 0 ? PdfColors.blue : PdfColors.orange)),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                      child: _buildSummaryBox(
                          'Profit Margin', profitMargin, PdfColors.purple,
                          suffix: '%')),
                ],
              ),
              pw.SizedBox(height: 20),

              // Sales breakdown
              pw.Text('SALES BREAKDOWN',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: 10),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Category',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Amount',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('% of Sales',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right),
                      ),
                    ],
                  ),
                  ...salesByCategory.entries.map((e) => pw.TableRow(
                        children: [
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(e.key)),
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(_currencyFormat.format(e.value),
                                  textAlign: pw.TextAlign.right)),
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(
                                  '${(e.value / totalSales * 100).toStringAsFixed(1)}%',
                                  textAlign: pw.TextAlign.right)),
                        ],
                      )),
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('TOTAL',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(_currencyFormat.format(totalSales),
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child:
                              pw.Text('100%', textAlign: pw.TextAlign.right)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Expenses breakdown
              if (expensesByCategory.isNotEmpty) ...[
                pw.Text('EXPENSES BREAKDOWN',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 14)),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('Category',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('Amount',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold),
                                textAlign: pw.TextAlign.right)),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('% of Expenses',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold),
                                textAlign: pw.TextAlign.right)),
                      ],
                    ),
                    ...expensesByCategory.entries.map((e) => pw.TableRow(
                          children: [
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text(e.key)),
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text(_currencyFormat.format(e.value),
                                    textAlign: pw.TextAlign.right)),
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text(
                                    '${(e.value / totalExpenses * 100).toStringAsFixed(1)}%',
                                    textAlign: pw.TextAlign.right)),
                          ],
                        )),
                    pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('TOTAL',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                                _currencyFormat.format(totalExpenses),
                                textAlign: pw.TextAlign.right,
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child:
                                pw.Text('100%', textAlign: pw.TextAlign.right)),
                      ],
                    ),
                  ],
                ),
              ],

              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Center(
                child: pw.Text(
                    'Generated on ${_dateTimeFormat.format(DateTime.now())} | Total Transactions: $totalTransactions'),
              ),
            ],
          );
        },
      ),
    );

    // Save the PDF
    final output = await _getDownloadsDirectory();
    final fileName =
        'profit_summary_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  static PdfColor _getTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.sale:
        return PdfColors.green;
      case TransactionType.expense:
        return PdfColors.red;
      case TransactionType.purchase:
        return PdfColors.blue;
      case TransactionType.cashReceipt:
        return PdfColors.purple;
    }
  }

  static pw.Widget _buildSummaryBox(String label, double value, PdfColor color,
      {String suffix = ''}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style:
                  const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 5),
          pw.Text('UGX ${_currencyFormat.format(value)}$suffix',
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
