import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../lib/services/api_service.dart';
import '../lib/services/document_analyzer_models.dart';

void main() {
  group('DocumentAnalyzerApi', () {
    final requestPayload = AnalyzePayload(
      documentId: 'doc-123',
      source: SourceType.ocr,
      metadata: Metadata(
        userId: 'user-1',
        issueDate: DateTime(2026, 1, 15),
        amount: 520,
        jurisdiction: 'Roma',
      ),
      text: 'Notifica di sanzione con importo e termini.',
    );

    final mockResponse = {
      'document_id': 'doc-123',
      'results': [
        {
          'type': 'process',
          'issue': 'Notifica fuori termine',
          'confidence': 0.92,
          'references': [
            {
              'source': 'norma',
              'citation': 'art. 3',
              'url': 'https://norma.example/art3'
            }
          ],
          'actions': ['Invia pec']
        }
      ],
      'summary': {
        'risk_level': 'high',
        'next_step': 'Invia prima pec'
      },
      'server_time': '2026-01-22T10:00:00Z',
    };

    test('parses response correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), 'https://api.test/analyze');
        expect(request.headers['Authorization'], 'Bearer token-xyz');
        final requestBody = jsonDecode(request.body) as Map<String, dynamic>;
        expect(requestBody['document_id'], requestPayload.documentId);
        return http.Response(jsonEncode(mockResponse), 200);
      });

      final api = DocumentAnalyzerApi(
        httpClient: mockClient,
        baseUrl: 'https://api.test',
        token: 'token-xyz',
      );

      final result = await api.analyzeDocument(requestPayload);
      expect(result.documentId, requestPayload.documentId);
      expect(result.results, isNotEmpty);
      expect(result.summary.nextStep, 'Invia prima pec');
      expect(result.summary.riskLevel, RiskLevel.high);
    });

    test('throws ApiException on error response', () async {
      final mockClient = MockClient((request) async {
        return http.Response('error', 500);
      });

      final api = DocumentAnalyzerApi(
        httpClient: mockClient,
        baseUrl: 'https://api.test',
        token: 'token-xyz',
      );

      expect(
        () => api.analyzeDocument(requestPayload),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
