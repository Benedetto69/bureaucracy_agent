import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import 'package:bureaucracy_agent/services/document_analyzer_models.dart';

const String _envApiBaseUrl = String.fromEnvironment('API_BASE_URL');
const String _envBackendToken = String.fromEnvironment('BACKEND_API_TOKEN');

/// Client che consuma `/analyze` e `/generate-document` restituendo modelli tipati.
class DocumentAnalyzerApi {
  final http.Client _httpClient;
  final String _baseUrl;
  final String _token;
  final Uuid _uuid;
  static const _defaultBaseUrl = 'http://127.0.0.1:8000';
  static const _defaultToken = 'changeme';

  DocumentAnalyzerApi({
    http.Client? httpClient,
    String? baseUrl,
    String? token,
  })  : _httpClient = httpClient ?? http.Client(),
        _baseUrl = _resolveBaseUrl(baseUrl),
        _token = _resolveToken(token),
        _uuid = const Uuid();

  static String _resolveBaseUrl(String? override) {
    final resolved = override ??
        (_envApiBaseUrl.isNotEmpty ? _envApiBaseUrl : null) ??
        _defaultBaseUrl;
    if (kReleaseMode && resolved == _defaultBaseUrl) {
      throw StateError('API_BASE_URL non configurato: imposta un endpoint '
          'HTTPS reale in fase di build (dart-define API_BASE_URL).');
    }
    if (kReleaseMode) {
      final uri = Uri.tryParse(resolved);
      if (uri == null || uri.scheme != 'https') {
        throw StateError(
            'API_BASE_URL non valido: in release e\' richiesto un endpoint HTTPS.');
      }
    }
    return resolved;
  }

  static String _resolveToken(String? override) {
    final resolved = override ??
        (_envBackendToken.isNotEmpty ? _envBackendToken : null) ??
        _defaultToken;
    if (kReleaseMode && (resolved.isEmpty || resolved == _defaultToken)) {
      throw StateError('BACKEND_API_TOKEN non configurato: sostituisci '
          'il placeholder in fase di build (dart-define BACKEND_API_TOKEN).');
    }
    return resolved;
  }

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
