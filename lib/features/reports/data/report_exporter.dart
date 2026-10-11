import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/result/result.dart';
import '../domain/csv_report_builder.dart';
import '../domain/report_data.dart';
import 'pdf_report_builder.dart';

class ReportExporter {
  const ReportExporter();

  Future<Result<void>> sharePdf(ReportData data) => _guard(() async {
        final bytes = await PdfReportBuilder.build(data);
        final file = await _write('${_fileName(data)}.pdf', bytes);
        await _share(file, 'application/pdf', data);
      });

  Future<Result<void>> shareCsv(ReportData data) => _guard(() async {
        final content = '﻿${CsvReportBuilder.build(data)}';
        final file = await _write(
          '${_fileName(data)}.csv',
          Uint8List.fromList(utf8.encode(content)),
        );
        await _share(file, 'text/csv', data);
      });

  Future<Result<void>> shareText(String fileName, String content) =>
      _guard(() async {
        final file = await _write(
          fileName,
          Uint8List.fromList(utf8.encode(content)),
        );
        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path, mimeType: 'application/json')]),
        );
      });

  String _fileName(ReportData data) {
    String stamp(DateTime d) =>
        '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
    final last = data.period.end.subtract(const Duration(days: 1));
    return 'caixinha-${stamp(data.period.start)}-${stamp(last)}';
  }

  Future<File> _write(String name, Uint8List bytes) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$name');
    return file.writeAsBytes(bytes, flush: true);
  }

  Future<void> _share(File file, String mimeType, ReportData data) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mimeType)],
        subject: 'Relatório ${data.businessName} (${periodLabel(data.period)})',
        text: 'Relatório financeiro de ${periodLabel(data.period)}.',
      ),
    );
  }

  Future<Result<void>> _guard(Future<void> Function() body) async {
    try {
      await body();
      return const Ok(null);
    } on Object catch (error, stackTrace) {
      return Err(
        UnexpectedFailure(
          'Não foi possível gerar o arquivo.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
