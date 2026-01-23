import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import 'document_analyzer_models.dart';

export 'document_analyzer_models.dart';

/// Client che consuma `/analyze` e `/generate-document` restituendo modelli tipati.
class DocumentAnalyzerApi {
  final http.Client _httpClient;
  final String _baseUrl;
  final String _token;
  final Uuid _uuid;

  DocumentAnalyzerApi({
    http.Client? httpClient,
    String? baseUrl,
    String? token,
  })  : _httpClient = httpClient ?? http.Client(),
        _baseUrl =
            baseUrl ?? dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8000',
        _token = token ?? dotenv.env['BACKEND_API_TOKEN'] ?? 'changeme',
        _uuid = const Uuid();

  Future<AnalyzeResponse> analyzeDocument(
    AnalyzePayload payload, {
    String? requestId,
  }) async {
    final id = requestId ?? _uuid.v4();
    final uri = Uri.parse('$_baseUrl/analyze');
    final response = await _httpClient.post(
      uri,
      headers: _defaultJsonHeaders(id),
      body: jsonEncode(payload.toJson()),
    );

    if (response.statusCode != 200) {
      throw ApiException(
        message: 'La brain response ha restituito ${response.statusCode}',
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return AnalyzeResponse.fromJson(decoded);
  }

  Future<DocumentResponse> generateDocument(DocumentRequest request,
      {String? requestId}) async {
    final id = requestId ?? _uuid.v4();
    final uri = Uri.parse('$_baseUrl/generate-document');
    final response = await _httpClient.post(
      uri,
      headers: _defaultJsonHeaders(id),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200) {
      throw ApiException(
        message: 'Document generation failed ${response.statusCode}',
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return DocumentResponse.fromJson(decoded);
  }

  Map<String, String> _defaultJsonHeaders(String requestId) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
        'Request-Id': requestId,
      };
}
