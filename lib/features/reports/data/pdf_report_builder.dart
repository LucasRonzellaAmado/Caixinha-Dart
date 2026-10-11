import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../transactions/domain/finance_calculator.dart';
import '../../transactions/domain/transaction_enums.dart';
import '../domain/report_data.dart';

abstract final class PdfReportBuilder {
  static const _primary = PdfColors.teal700;

  static Future<Uint8List> build(ReportData data) {
    final document = pw.Document(
      title: 'Relatório financeiro',
      author: data.businessName,
      creator: 'Caixinha',
    );
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => _header(data),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Gerado pelo Caixinha em ${Dates.day(data.generatedAt)} - '
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ),
        build: (_) => [
          _sectionTitle('Resumo do negócio'),
          _summaryTable(data.businessSummary),
          pw.SizedBox(height: 16),
          _sectionTitle('Saídas do negócio por categoria'),
          _categoryTable(data, TransactionType.expense),
          pw.SizedBox(height: 16),
          _sectionTitle('Entradas do negócio por categoria'),
          _categoryTable(data, TransactionType.income),
          pw.SizedBox(height: 16),
          _sectionTitle('Movimentação pessoal'),
          _summaryTable(data.personalSummary, personal: true),
          pw.SizedBox(height: 16),
          _sectionTitle('Lançamentos'),
          _transactionsTable(data),
        ],
      ),
    );
    return document.save();
  }

  static String _money(int cents) => Money.format(cents);

  static pw.Widget _header(ReportData data) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 16),
        padding: const pw.EdgeInsets.only(bottom: 8),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _primary, width: 2)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  data.businessName.isEmpty ? 'Relatório financeiro' : data.businessName,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: _primary,
                  ),
                ),
                pw.Text('Relatório financeiro'),
              ],
            ),
            pw.Text('Período: ${periodLabel(data.period)}'),
          ],
        ),
      );

  static pw.Widget _sectionTitle(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
      );

  static pw.Widget _summaryTable(FinanceSummary summary, {bool personal = false}) =>
      pw.TableHelper.fromTextArray(
        headers: ['Item', 'Valor'],
        data: [
          ['Entradas', _money(summary.incomeCents)],
          ['Saídas', _money(summary.expenseCents)],
          if (!personal) ['Lucro (entradas - saídas)', _money(summary.profitCents)],
          if (!personal) ['Pró-labore (retiradas)', _money(summary.proLaboreCents)],
          [
            personal ? 'Saldo pessoal' : 'Sobra no caixa',
            _money(summary.balanceCents),
          ],
        ],
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
        headerDecoration: const pw.BoxDecoration(color: _primary),
        cellAlignments: {1: pw.Alignment.centerRight},
        columnWidths: {
          0: const pw.FlexColumnWidth(3),
          1: const pw.FlexColumnWidth(2),
        },
      );

  static pw.Widget _categoryTable(ReportData data, TransactionType type) {
    final totals = data.businessTotals(type);
    if (totals.isEmpty) return pw.Text('Nenhum lançamento.');
    return pw.TableHelper.fromTextArray(
      headers: ['Categoria', 'Total'],
      data: [
        for (final total in totals)
          [data.categoryName(total.categoryId), _money(total.totalCents)],
      ],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignments: {1: pw.Alignment.centerRight},
    );
  }

  static pw.Widget _transactionsTable(ReportData data) {
    final transactions = data.sortedTransactions;
    if (transactions.isEmpty) return pw.Text('Nenhum lançamento no período.');
    return pw.TableHelper.fromTextArray(
      headers: ['Data', 'Tipo', 'Escopo', 'Categoria', 'Descrição', 'Valor'],
      data: [
        for (final t in transactions)
          [
            Dates.day(t.date),
            t.type.label,
            t.scope.label,
            t.type == TransactionType.proLabore ? '-' : data.categoryName(t.categoryId),
            t.description,
            _money(t.signedAmountCents),
          ],
      ],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignments: {5: pw.Alignment.centerRight},
      columnWidths: {
        0: const pw.FixedColumnWidth(58),
        1: const pw.FixedColumnWidth(52),
        2: const pw.FixedColumnWidth(48),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(3),
        5: const pw.FixedColumnWidth(70),
      },
    );
  }
}
