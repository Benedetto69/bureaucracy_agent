import 'dart:convert';

import 'package:bureaucracy_agent/services/document_analyzer_models.dart';

class DocumentHistoryEntry {
  final DocumentResponse document;
  final DateTime timestamp;

  DocumentHistoryEntry(this.document, this.timestamp);

  Map<String, dynamic> toJson() => {
        'document': document.toJson(),
        'timestamp': timestamp.toIso8601String(),
      };

  factory DocumentHistoryEntry.fromJson(Map<String, dynamic> json) =>
      DocumentHistoryEntry(
        DocumentResponse.fromJson(json['document'] as Map<String, dynamic>),
        DateTime.parse(json['timestamp'] as String),
      );

  static DocumentHistoryEntry fromEncoded(String encoded) =>
      DocumentHistoryEntry.fromJson(jsonDecode(encoded) as Map<String, dynamic>);

  String encode() => jsonEncode(toJson());
}
