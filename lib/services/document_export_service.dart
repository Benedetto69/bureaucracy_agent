import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// Formato di esportazione supportati
enum ExportFormat {
  pdf('PDF', 'application/pdf', 'pdf'),
  txt('Testo', 'text/plain', 'txt'),
  clipboard('Appunti', '', '');

  final String label;
  final String mimeType;
  final String extension;

  const ExportFormat(this.label, this.mimeType, this.extension);
}

/// Risultato dell'esportazione
class ExportResult {
  final bool success;
  final String? filePath;
  final String? error;

  const ExportResult({
    required this.success,
    this.filePath,
    this.error,
  });

  factory ExportResult.success([String? filePath]) => ExportResult(
        success: true,
        filePath: filePath,
      );

  factory ExportResult.failure(String error) => ExportResult(
        success: false,
        error: error,
      );
}

/// Servizio per esportare documenti in vari formati
class DocumentExportService {
  /// Esporta un documento nel formato specificato
  static Future<ExportResult> export({
    required String title,
    required String body,
    required ExportFormat format,
    String? caseReference,
    String? jurisdiction,
    double? amount,
    DateTime? issueDate,
  }) async {
    try {
      switch (format) {
        case ExportFormat.pdf:
          return await _exportAsPdf(
            title: title,
            body: body,
            caseReference: caseReference,
            jurisdiction: jurisdiction,
            amount: amount,
            issueDate: issueDate,
          );
        case ExportFormat.txt:
          return await _exportAsTxt(
            title: title,
            body: body,
            caseReference: caseReference,
          );
        case ExportFormat.clipboard:
          return await _copyToClipboard(body);
      }
    } catch (e) {
      debugPrint('Errore esportazione: $e');
      return ExportResult.failure('Errore durante l\'esportazione: $e');
    }
  }

  /// Condividi documento
  static Future<ExportResult> share({
    required String title,
    required String body,
    required ExportFormat format,
    String? caseReference,
    String? jurisdiction,
    double? amount,
    DateTime? issueDate,
  }) async {
    try {
      final result = await export(
        title: title,
        body: body,
        format: format,
        caseReference: caseReference,
        jurisdiction: jurisdiction,
        amount: amount,
        issueDate: issueDate,
      );

      if (!result.success || result.filePath == null) {
        return result;
      }

      await Share.shareXFiles(
        [XFile(result.filePath!)],
        subject: title,
      );

      return ExportResult.success(result.filePath);
    } catch (e) {
      debugPrint('Errore condivisione: $e');
      return ExportResult.failure('Errore durante la condivisione: $e');
    }
  }

  /// Esporta come PDF
  static Future<ExportResult> _exportAsPdf({
    required String title,
    required String body,
    String? caseReference,
    String? jurisdiction,
    double? amount,
    DateTime? issueDate,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            if (caseReference != null || jurisdiction != null)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  if (caseReference != null)
                    pw.Text(
                      'Rif: $caseReference',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  if (jurisdiction != null)
                    pw.Text(
                      jurisdiction,
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                ],
              ),
            pw.Divider(),
            pw.SizedBox(height: 10),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generato con Bureaucracy Agent',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                ),
                pw.Text(
                  'Pagina ${context.pageNumber} di ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                ),
              ],
            ),
          ],
        ),
        build: (context) => [
          pw.Text(
            body,
            style: const pw.TextStyle(fontSize: 11, lineSpacing: 4),
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'ricorso_${caseReference ?? timestamp}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return ExportResult.success(file.path);
  }

  /// Esporta come file di testo
  static Future<ExportResult> _exportAsTxt({
    required String title,
    required String body,
    String? caseReference,
  }) async {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('=' * 60);
    buffer.writeln(title.toUpperCase());
    buffer.writeln('=' * 60);
    buffer.writeln();

    if (caseReference != null) {
      buffer.writeln('Riferimento: $caseReference');
      buffer.writeln('Data generazione: ${_formatDate(DateTime.now())}');
      buffer.writeln('-' * 60);
      buffer.writeln();
    }

    // Body
    buffer.writeln(body);

    buffer.writeln();
    buffer.writeln('-' * 60);
    buffer.writeln('Documento generato con Bureaucracy Agent');
    buffer.writeln('Questo documento e\' una bozza e richiede revisione');

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'ricorso_${caseReference ?? timestamp}.txt';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(buffer.toString());

    return ExportResult.success(file.path);
  }

  /// Copia negli appunti
  static Future<ExportResult> _copyToClipboard(String body) async {
    await Clipboard.setData(ClipboardData(text: body));
    return ExportResult.success();
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Widget per selezionare il formato di esportazione
class ExportFormatSelector extends StatelessWidget {
  final ExportFormat selectedFormat;
  final ValueChanged<ExportFormat> onFormatChanged;

  const ExportFormatSelector({
    super.key,
    required this.selectedFormat,
    required this.onFormatChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ExportFormat.values.map((format) {
        final isSelected = format == selectedFormat;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getIconForFormat(format),
                  size: 16,
                  color: isSelected ? Colors.black : Colors.white70,
                ),
                const SizedBox(width: 4),
                Text(format.label),
              ],
            ),
            selected: isSelected,
            onSelected: (_) => onFormatChanged(format),
            backgroundColor: const Color(0xFF1E2636),
            selectedColor: Colors.greenAccent,
            labelStyle: TextStyle(
              color: isSelected ? Colors.black : Colors.white70,
              fontSize: 12,
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getIconForFormat(ExportFormat format) {
    switch (format) {
      case ExportFormat.pdf:
        return Icons.picture_as_pdf;
      case ExportFormat.txt:
        return Icons.text_snippet;
      case ExportFormat.clipboard:
        return Icons.content_copy;
    }
  }
}
