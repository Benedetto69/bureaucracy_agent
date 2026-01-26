/// Payload JSON standard che il backend FastAPI si aspetta per l’analisi.
class AnalyzePayload {
  final String documentId;
  final SourceType source;
  final Metadata metadata;
  final String text;
  final List<Attachment> attachments;

  const AnalyzePayload({
    required this.documentId,
    required this.source,
    required this.metadata,
    required this.text,
    this.attachments = const [],
  });

  Map<String, dynamic> toJson() => {
        'document_id': documentId,
        'source': source.value,
        'metadata': metadata.toJson(),
        'text': text,
        if (attachments.isNotEmpty)
          'attachments':
              attachments.map((attachment) => attachment.toJson()).toList(),
      };
}

class Metadata {
  final String userId;
  final DateTime issueDate;
  final double amount;
  final String jurisdiction;

  const Metadata({
    required this.userId,
    required this.issueDate,
    required this.amount,
    required this.jurisdiction,
  });

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'issue_date': issueDate.toIso8601String().split('T').first,
        'amount': amount.toStringAsFixed(2),
        'jurisdiction': jurisdiction.trim(),
      };
}

class Attachment {
  final String filename;
  final String mimeType;
  final String hash;

  const Attachment({
    required this.filename,
    required this.mimeType,
    required this.hash,
  });

  Map<String, dynamic> toJson() => {
        'filename': filename,
        'mime_type': mimeType,
        'hash': hash,
      };
}

enum SourceType {
  ocr('ocr'),
  upload('upload'),
  manual('manual');

  const SourceType(this.value);
  final String value;
}

class AnalyzeResponse {
  final String documentId;
  final List<AnalysisIssue> results;
  final Summary summary;
  final DateTime serverTime;

  AnalyzeResponse({
    required this.documentId,
    required this.results,
    required this.summary,
    required this.serverTime,
  });

  factory AnalyzeResponse.fromJson(Map<String, dynamic> json) {
    final serverTimeString = json['server_time'] as String;
    return AnalyzeResponse(
      documentId: json['document_id'] as String,
      results: (json['results'] as List<dynamic>)
          .map((entry) => AnalysisIssue.fromJson(entry as Map<String, dynamic>))
          .toList(),
      summary: Summary.fromJson(json['summary'] as Map<String, dynamic>),
      serverTime: DateTime.parse(serverTimeString),
    );
  }
}

class AnalysisIssue {
  final IssueType type;
  final String issue;
  final double confidence;
  final List<Reference> references;
  final List<String> actions;

  AnalysisIssue({
    required this.type,
    required this.issue,
    required this.confidence,
    required this.references,
    required this.actions,
  });

  factory AnalysisIssue.fromJson(Map<String, dynamic> json) => AnalysisIssue(
        type: IssueTypeX.fromValue(json['type'] as String),
        issue: json['issue'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        references: (json['references'] as List<dynamic>)
            .map((entry) => Reference.fromJson(entry as Map<String, dynamic>))
            .toList(),
        actions: (json['actions'] as List<dynamic>).cast<String>(),
      );
}

class Reference {
  final ReferenceSource source;
  final String citation;
  final Uri url;

  Reference({
    required this.source,
    required this.citation,
    required this.url,
  });

  factory Reference.fromJson(Map<String, dynamic> json) => Reference(
        source: ReferenceSourceX.fromValue(json['source'] as String),
        citation: json['citation'] as String,
        url: Uri.parse(json['url'] as String),
      );
}

class Summary {
  final RiskLevel riskLevel;
  final String nextStep;

  Summary({
    required this.riskLevel,
    required this.nextStep,
  });

  factory Summary.fromJson(Map<String, dynamic> json) => Summary(
        riskLevel: RiskLevelX.fromValue(json['risk_level'] as String),
        nextStep: json['next_step'] as String,
      );
}

enum IssueType { process, formality, substance }

extension IssueTypeX on IssueType {
  static IssueType fromValue(String value) {
    switch (value) {
      case 'process':
        return IssueType.process;
      case 'formality':
        return IssueType.formality;
      case 'substance':
        return IssueType.substance;
      default:
        throw ArgumentError.value(
            value, 'type', 'Tipo di issue non riconosciuto');
    }
  }
}

enum ReferenceSource { norma, giurisprudenza, policy }

extension ReferenceSourceX on ReferenceSource {
  static ReferenceSource fromValue(String value) {
    switch (value) {
      case 'norma':
        return ReferenceSource.norma;
      case 'giurisprudenza':
        return ReferenceSource.giurisprudenza;
      case 'policy':
        return ReferenceSource.policy;
      default:
        throw ArgumentError.value(value, 'source', 'Source non valida');
    }
  }
}

enum RiskLevel { low, medium, high }

extension RiskLevelX on RiskLevel {
  static RiskLevel fromValue(String value) {
    switch (value) {
      case 'low':
        return RiskLevel.low;
      case 'medium':
        return RiskLevel.medium;
      case 'high':
        return RiskLevel.high;
      default:
        throw ArgumentError.value(value, 'risk_level', 'Risk level non valido');
    }
  }
}

class DocumentRequest {
  final String documentId;
  final String userId;
  final IssueType issueType;
  final List<String> actions;
  final List<Reference> references;
  final String summaryNextStep;

  DocumentRequest({
    required this.documentId,
    required this.userId,
    required this.issueType,
    required this.actions,
    required this.references,
    required this.summaryNextStep,
  });

  Map<String, dynamic> toJson() => {
        'document_id': documentId,
        'user_id': userId,
        'issue_type': issueType.name,
        'actions': actions,
        'references': references
            .map((ref) => {
                  'source': ref.source.name,
                  'citation': ref.citation,
                  'url': ref.url.toString(),
                })
            .toList(),
        'summary_next_step': summaryNextStep,
      };
}

class DocumentResponse {
  final String documentId;
  final String title;
  final String body;
  final List<String> recommendations;

  DocumentResponse({
    required this.documentId,
    required this.title,
    required this.body,
    required this.recommendations,
  });

  factory DocumentResponse.fromJson(Map<String, dynamic> json) =>
      DocumentResponse(
        documentId: json['document_id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        recommendations:
            (json['recommendations'] as List<dynamic>).cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        'document_id': documentId,
        'title': title,
        'body': body,
        'recommendations': recommendations,
      };
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;

  ApiException({required this.message, this.statusCode, this.body});

  @override
  String toString() =>
      'ApiException($statusCode): $message${body == null ? '' : ' | $body'}';
}
