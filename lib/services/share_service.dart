import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'document_analyzer_models.dart';

class ShareService {
  static Future<void> shareText({
    required String text,
    required String subject,
  }) async {
    await Share.share(text, subject: subject);
  }

  static Future<void> shareDocument(DocumentResponse document) async {
    final text = _formatDocumentAsText(document);
    await Share.share(
      text,
      subject: document.title,
    );
  }

  static Future<void> sharePdfFile({
    required Uint8List pdfBytes,
    required String filename,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');
    await file.writeAsBytes(pdfBytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: filename.replaceAll('.pdf', ''),
    );
  }

  static String _formatDocumentAsText(DocumentResponse document) {
    final buffer = StringBuffer();

    buffer.writeln('=' * 50);
    buffer.writeln(document.title.toUpperCase());
    buffer.writeln('=' * 50);
    buffer.writeln();
    buffer.writeln(document.body);
    buffer.writeln();

    if (document.recommendations.isNotEmpty) {
      buffer.writeln('-' * 30);
      buffer.writeln('AZIONI RACCOMANDATE:');
      buffer.writeln('-' * 30);
      for (var i = 0; i < document.recommendations.length; i++) {
        buffer.writeln('${i + 1}. ${document.recommendations[i]}');
      }
      buffer.writeln();
    }

    buffer.writeln('---');
    buffer.writeln('Generato con Bureaucracy Analyzer');

    return buffer.toString();
  }

  static String formatDocumentForEmail(DocumentResponse document) {
    return _formatDocumentAsText(document);
  }
}
