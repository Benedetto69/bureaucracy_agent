import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'document_analyzer_models.dart';

class PdfService {
  static final _dateFormat = DateFormat('dd/MM/yyyy', 'it_IT');
  static final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'it_IT');

  static Future<Uint8List> generateContestationPdf({
    required DocumentResponse document,
    required String caseReference,
    required String jurisdiction,
    required double amount,
    required DateTime issueDate,
  }) async {
    final pdf = pw.Document(
      author: 'Bureaucracy Analyzer',
      creator: 'Bureaucracy Analyzer App',
      title: document.title,
      subject: 'Contestazione multa - $caseReference',
    );

    // Load fonts with fallback
    pw.ThemeData? theme;
    try {
      final baseFont = await PdfGoogleFonts.nunitoRegular();
      final boldFont = await PdfGoogleFonts.nunitoBold();
      final italicFont = await PdfGoogleFonts.nunitoItalic();
      theme = pw.ThemeData.withFont(
        base: baseFont,
        bold: boldFont,
        italic: italicFont,
      );
    } catch (_) {
      // Use default theme if font loading fails
      theme = null;
    }

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(context, document.title),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildMetadataSection(
            caseReference: caseReference,
            jurisdiction: jurisdiction,
            amount: amount,
            issueDate: issueDate,
          ),
          pw.SizedBox(height: 24),
          _buildBodySection(document.body),
          pw.SizedBox(height: 24),
          if (document.recommendations.isNotEmpty)
            _buildRecommendationsSection(document.recommendations),
          pw.SizedBox(height: 32),
          _buildSignatureSection(),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(pw.Context context, String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey400, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
          ),
          pw.Text(
            'Generato con Bureaucracy Analyzer',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey500,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Documento generato il ${_dateTimeFormat.format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
          pw.Text(
            'Pagina ${context.pageNumber} di ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMetadataSection({
    required String caseReference,
    required String jurisdiction,
    required double amount,
    required DateTime issueDate,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DATI DELLA PRATICA',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              _buildMetadataItem('Codice Pratica', caseReference),
              _buildMetadataItem('Giurisdizione', jurisdiction),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _buildMetadataItem(
                'Importo',
                NumberFormat.currency(locale: 'it_IT', symbol: '\u20AC')
                    .format(amount),
              ),
              _buildMetadataItem(
                'Data Notifica',
                _dateFormat.format(issueDate),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMetadataItem(String label, String value) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBodySection(String body) {
    final paragraphs = body.split('\n\n');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: paragraphs.map((paragraph) {
        if (paragraph.trim().isEmpty) return pw.SizedBox(height: 8);

        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Text(
            paragraph.trim(),
            style: const pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey800,
              lineSpacing: 4,
            ),
            textAlign: pw.TextAlign.justify,
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildRecommendationsSection(List<String> recommendations) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.amber200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 20,
                height: 20,
                decoration: const pw.BoxDecoration(
                  color: PdfColors.amber400,
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Center(
                  child: pw.Text(
                    '!',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'AZIONI RACCOMANDATE',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.amber900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          ...recommendations.asMap().entries.map((entry) {
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 18,
                    height: 18,
                    margin: const pw.EdgeInsets.only(right: 8, top: 1),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.amber600),
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(3)),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        '${entry.key + 1}',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.amber800,
                        ),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      entry.value,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static pw.Widget _buildSignatureSection() {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 24),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Data e luogo: _______________________',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Firma del ricorrente:',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            width: 200,
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey400, width: 1),
              ),
            ),
            child: pw.SizedBox(height: 40),
          ),
          pw.SizedBox(height: 32),
          _buildDisclaimerSection(),
        ],
      ),
    );
  }

  static pw.Widget _buildDisclaimerSection() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'AVVERTENZE IMPORTANTI',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Questo documento e\' stato generato automaticamente a scopo indicativo e richiede verifica e personalizzazione. '
            'Non costituisce consulenza legale professionale. '
            'Per importi elevati o casi complessi si consiglia la consulenza di un avvocato. '
            'Verificare i riferimenti normativi e la loro applicabilita\' al caso specifico. '
            'La decisione finale e la responsabilita\' rimangono dell\'utente.',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
              lineSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> sharePdf({
    required Uint8List pdfBytes,
    required String filename,
  }) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: filename);
  }

  static Future<void> previewPdf({
    required Uint8List pdfBytes,
    required String title,
  }) async {
    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: title,
    );
  }
}
