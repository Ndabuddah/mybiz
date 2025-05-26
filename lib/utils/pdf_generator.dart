import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/business.dart';

class PdfGenerator {
  // Generate a business plan PDF
  static Future<File> generateBusinessPlan({required Business business, required String planContent}) async {
    final pdf = pw.Document();

    // Load font
    final fontData = await rootBundle.load('assets/fonts/inter/Inter-Regular.ttf');
    final fontBoldData = await rootBundle.load('assets/fonts/inter/Inter-Bold.ttf');
    final ttf = pw.Font.ttf(fontData);
    final ttfBold = pw.Font.ttf(fontBoldData);

    // Add pages to the PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(business.name, style: pw.TextStyle(font: ttfBold, fontSize: 24, color: PdfColors.indigo700)), pw.Text('Business Plan', style: pw.TextStyle(font: ttf, fontSize: 16, color: PdfColors.grey700))]),
              pw.Divider(color: PdfColors.grey400),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [pw.Text('Generated with MyBiz', style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.grey600)), pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.grey600))],
          );
        },
        build: (pw.Context context) {
          return [
            // Title section
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('BUSINESS PLAN', style: pw.TextStyle(font: ttfBold, fontSize: 28, color: PdfColors.indigo900)),
                  pw.SizedBox(height: 10),
                  pw.Text(business.name, style: pw.TextStyle(font: ttfBold, fontSize: 24, color: PdfColors.indigo700)),
                  pw.SizedBox(height: 5),
                  pw.Text(business.industry, style: pw.TextStyle(font: ttf, fontSize: 16, color: PdfColors.grey700)),
                  pw.SizedBox(height: 10),
                  pw.Text('Generated on: ${DateFormat('MMMM d, yyyy').format(DateTime.now())}', style: pw.TextStyle(font: ttf, fontSize: 12, color: PdfColors.grey600)),
                ],
              ),
            ),

            // Business overview
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [pw.Text('BUSINESS OVERVIEW', style: pw.TextStyle(font: ttfBold, fontSize: 16, color: PdfColors.indigo700)), pw.SizedBox(height: 10), pw.Text(business.description, style: pw.TextStyle(font: ttf, fontSize: 12))],
              ),
            ),

            // Main content
            pw.Container(margin: const pw.EdgeInsets.only(top: 20), child: pw.Text(planContent, style: pw.TextStyle(font: ttf, fontSize: 12))),
          ];
        },
      ),
    );

    // Save the PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/${business.name.replaceAll(' ', '_')}_Business_Plan.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  // Generate an invoice PDF
  static Future<File> generateInvoice({
    required Business business,
    required String invoiceNumber,
    required DateTime invoiceDate,
    required DateTime dueDate,
    required String clientName,
    required String clientEmail,
    required String clientAddress,
    required List<Map<String, dynamic>> items,
    required double taxRate,
    String? notes,
  }) async {
    final pdf = pw.Document();

    // Load font
    final fontData = await rootBundle.load('assets/fonts/inter/Inter-Regular.ttf');
    final fontBoldData = await rootBundle.load('assets/fonts/inter/Inter-Bold.ttf');
    final ttf = pw.Font.ttf(fontData);
    final ttfBold = pw.Font.ttf(fontBoldData);

    // Calculate totals
    double subtotal = 0;
    for (var item in items) {
      subtotal += (item['quantity'] as num) * (item['price'] as num);
    }

    final taxAmount = subtotal * (taxRate / 100);
    final total = subtotal + taxAmount;

    // Add pages to the PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [pw.Text(business.name, style: pw.TextStyle(font: ttfBold, fontSize: 24, color: PdfColors.indigo700)), pw.SizedBox(height: 5), pw.Text(business.industry, style: pw.TextStyle(font: ttf, fontSize: 12, color: PdfColors.grey700))],
                ),
                pw.Container(padding: const pw.EdgeInsets.all(10), decoration: pw.BoxDecoration(color: PdfColors.indigo700, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))), child: pw.Text('INVOICE', style: pw.TextStyle(font: ttfBold, fontSize: 20, color: PdfColors.white))),
              ],
            ),

            pw.SizedBox(height: 20),

            // Invoice info and client info
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Invoice details
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Invoice Details', style: pw.TextStyle(font: ttfBold, fontSize: 14, color: PdfColors.indigo700)),
                      pw.SizedBox(height: 5),
                      pw.Row(children: [pw.Text('Invoice Number:', style: pw.TextStyle(font: ttfBold, fontSize: 10)), pw.SizedBox(width: 5), pw.Text(invoiceNumber, style: pw.TextStyle(font: ttf, fontSize: 10))]),
                      pw.SizedBox(height: 2),
                      pw.Row(children: [pw.Text('Date:', style: pw.TextStyle(font: ttfBold, fontSize: 10)), pw.SizedBox(width: 5), pw.Text(DateFormat('MMMM d, yyyy').format(invoiceDate), style: pw.TextStyle(font: ttf, fontSize: 10))]),
                      pw.SizedBox(height: 2),
                      pw.Row(children: [pw.Text('Due Date:', style: pw.TextStyle(font: ttfBold, fontSize: 10)), pw.SizedBox(width: 5), pw.Text(DateFormat('MMMM d, yyyy').format(dueDate), style: pw.TextStyle(font: ttf, fontSize: 10))]),
                    ],
                  ),
                ),

                // Client details
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Bill To', style: pw.TextStyle(font: ttfBold, fontSize: 14, color: PdfColors.indigo700)),
                      pw.SizedBox(height: 5),
                      pw.Text(clientName, style: pw.TextStyle(font: ttfBold, fontSize: 10)),
                      pw.SizedBox(height: 2),
                      pw.Text(clientEmail, style: pw.TextStyle(font: ttf, fontSize: 10)),
                      pw.SizedBox(height: 2),
                      pw.Text(clientAddress, style: pw.TextStyle(font: ttf, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 30),

            // Items table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {0: const pw.FlexColumnWidth(1), 1: const pw.FlexColumnWidth(4), 2: const pw.FlexColumnWidth(1), 3: const pw.FlexColumnWidth(2), 4: const pw.FlexColumnWidth(2)},
              children: [
                // Table header
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.indigo50),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('#', style: pw.TextStyle(font: ttfBold, fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Item Description', style: pw.TextStyle(font: ttfBold, fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Qty', style: pw.TextStyle(font: ttfBold, fontSize: 10), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Unit Price', style: pw.TextStyle(font: ttfBold, fontSize: 10), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Amount', style: pw.TextStyle(font: ttfBold, fontSize: 10), textAlign: pw.TextAlign.right)),
                  ],
                ),

                // Table items
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final amount = (item['quantity'] as num) * (item['price'] as num);

                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${index + 1}', style: pw.TextStyle(font: ttf, fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(item['description'] as String, style: pw.TextStyle(font: ttf, fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${item['quantity']}', style: pw.TextStyle(font: ttf, fontSize: 10), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('R${(item['price'] as num).toStringAsFixed(2)}', style: pw.TextStyle(font: ttf, fontSize: 10), textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('R${amount.toStringAsFixed(2)}', style: pw.TextStyle(font: ttf, fontSize: 10), textAlign: pw.TextAlign.right)),
                    ],
                  );
                }).toList(),
              ],
            ),

            pw.SizedBox(height: 10),

            // Totals
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [pw.Container(width: 100, child: pw.Text('Subtotal:', style: pw.TextStyle(font: ttf, fontSize: 10))), pw.Container(width: 100, child: pw.Text('R${subtotal.toStringAsFixed(2)}', style: pw.TextStyle(font: ttf, fontSize: 10), textAlign: pw.TextAlign.right))],
                  ),
                  pw.SizedBox(height: 2),
                  pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Container(width: 100, child: pw.Text('Tax (${taxRate.toStringAsFixed(1)}%):', style: pw.TextStyle(font: ttf, fontSize: 10))),
                      pw.Container(width: 100, child: pw.Text('R${taxAmount.toStringAsFixed(2)}', style: pw.TextStyle(font: ttf, fontSize: 10), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: pw.BoxDecoration(color: PdfColors.indigo700, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
                    child: pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Container(width: 100, child: pw.Text('Total:', style: pw.TextStyle(font: ttfBold, fontSize: 12, color: PdfColors.white))),
                        pw.Container(width: 100, child: pw.Text('R${total.toStringAsFixed(2)}', style: pw.TextStyle(font: ttfBold, fontSize: 12, color: PdfColors.white), textAlign: pw.TextAlign.right)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 30),

            // Notes
            if (notes != null && notes.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text('Notes', style: pw.TextStyle(font: ttfBold, fontSize: 12)), pw.SizedBox(height: 5), pw.Text(notes, style: pw.TextStyle(font: ttf, fontSize: 10))]),
              ),
              pw.SizedBox(height: 20),
            ],

            // Footer
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 10),
            pw.Text('Thank you for your business!', style: pw.TextStyle(font: ttfBold, fontSize: 12, color: PdfColors.indigo700), textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 5),
            pw.Text('Generated with MyBiz - Your Business Companion', style: pw.TextStyle(font: ttf, fontSize: 8, color: PdfColors.grey600), textAlign: pw.TextAlign.center),
          ];
        },
      ),
    );

    // Save the PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/Invoice_${invoiceNumber.replaceAll(' ', '_')}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }
}
