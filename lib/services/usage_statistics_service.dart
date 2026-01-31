import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Statistiche di utilizzo dell'app
class UsageStatistics {
  final int totalAnalyses;
  final int documentsGenerated;
  final int documentsShared;
  final Map<String, int> analysesByMonth;
  final Map<String, int> riskLevelCounts; // low, medium, high
  final double averageAmount;
  final List<String> topJurisdictions;
  final DateTime? firstAnalysisDate;
  final DateTime? lastAnalysisDate;

  const UsageStatistics({
    this.totalAnalyses = 0,
    this.documentsGenerated = 0,
    this.documentsShared = 0,
    this.analysesByMonth = const {},
    this.riskLevelCounts = const {},
    this.averageAmount = 0,
    this.topJurisdictions = const [],
    this.firstAnalysisDate,
    this.lastAnalysisDate,
  });

  UsageStatistics copyWith({
    int? totalAnalyses,
    int? documentsGenerated,
    int? documentsShared,
    Map<String, int>? analysesByMonth,
    Map<String, int>? riskLevelCounts,
    double? averageAmount,
    List<String>? topJurisdictions,
    DateTime? firstAnalysisDate,
    DateTime? lastAnalysisDate,
  }) {
    return UsageStatistics(
      totalAnalyses: totalAnalyses ?? this.totalAnalyses,
      documentsGenerated: documentsGenerated ?? this.documentsGenerated,
      documentsShared: documentsShared ?? this.documentsShared,
      analysesByMonth: analysesByMonth ?? this.analysesByMonth,
      riskLevelCounts: riskLevelCounts ?? this.riskLevelCounts,
      averageAmount: averageAmount ?? this.averageAmount,
      topJurisdictions: topJurisdictions ?? this.topJurisdictions,
      firstAnalysisDate: firstAnalysisDate ?? this.firstAnalysisDate,
      lastAnalysisDate: lastAnalysisDate ?? this.lastAnalysisDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalAnalyses': totalAnalyses,
        'documentsGenerated': documentsGenerated,
        'documentsShared': documentsShared,
        'analysesByMonth': analysesByMonth,
        'riskLevelCounts': riskLevelCounts,
        'averageAmount': averageAmount,
        'topJurisdictions': topJurisdictions,
        'firstAnalysisDate': firstAnalysisDate?.toIso8601String(),
        'lastAnalysisDate': lastAnalysisDate?.toIso8601String(),
      };

  factory UsageStatistics.fromJson(Map<String, dynamic> json) {
    return UsageStatistics(
      totalAnalyses: json['totalAnalyses'] as int? ?? 0,
      documentsGenerated: json['documentsGenerated'] as int? ?? 0,
      documentsShared: json['documentsShared'] as int? ?? 0,
      analysesByMonth: Map<String, int>.from(json['analysesByMonth'] ?? {}),
      riskLevelCounts: Map<String, int>.from(json['riskLevelCounts'] ?? {}),
      averageAmount: (json['averageAmount'] as num?)?.toDouble() ?? 0,
      topJurisdictions: List<String>.from(json['topJurisdictions'] ?? []),
      firstAnalysisDate: json['firstAnalysisDate'] != null
          ? DateTime.parse(json['firstAnalysisDate'] as String)
          : null,
      lastAnalysisDate: json['lastAnalysisDate'] != null
          ? DateTime.parse(json['lastAnalysisDate'] as String)
          : null,
    );
  }

  /// Calcola il tasso di successo stimato basato sui risk level
  double get estimatedSuccessRate {
    final total = riskLevelCounts.values.fold(0, (a, b) => a + b);
    if (total == 0) return 0;

    final lowRisk = riskLevelCounts['low'] ?? 0;
    final mediumRisk = riskLevelCounts['medium'] ?? 0;
    final highRisk = riskLevelCounts['high'] ?? 0;

    // Pesi stimati per successo
    final weightedSum = (lowRisk * 0.75) + (mediumRisk * 0.45) + (highRisk * 0.20);
    return weightedSum / total;
  }

  /// Risparmio potenziale stimato (30% sconto pagamento anticipato)
  double get potentialSavings => averageAmount * totalAnalyses * 0.30;
}

/// Record di una singola analisi per statistiche dettagliate
class AnalysisRecord {
  final String id;
  final DateTime timestamp;
  final String jurisdiction;
  final double amount;
  final String riskLevel;
  final int issuesCount;
  final bool documentGenerated;
  final bool documentShared;

  const AnalysisRecord({
    required this.id,
    required this.timestamp,
    required this.jurisdiction,
    required this.amount,
    required this.riskLevel,
    required this.issuesCount,
    this.documentGenerated = false,
    this.documentShared = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'jurisdiction': jurisdiction,
        'amount': amount,
        'riskLevel': riskLevel,
        'issuesCount': issuesCount,
        'documentGenerated': documentGenerated,
        'documentShared': documentShared,
      };

  factory AnalysisRecord.fromJson(Map<String, dynamic> json) {
    return AnalysisRecord(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      jurisdiction: json['jurisdiction'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      riskLevel: json['riskLevel'] as String? ?? 'medium',
      issuesCount: json['issuesCount'] as int? ?? 0,
      documentGenerated: json['documentGenerated'] as bool? ?? false,
      documentShared: json['documentShared'] as bool? ?? false,
    );
  }
}

/// Servizio per gestire le statistiche di utilizzo
class UsageStatisticsService {
  static const String _statsKey = 'usage_statistics';
  static const String _recordsKey = 'analysis_records';
  static const int _maxRecords = 100;

  /// Carica le statistiche
  static Future<UsageStatistics> loadStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_statsKey);
      if (jsonString == null || jsonString.isEmpty) {
        return const UsageStatistics();
      }
      return UsageStatistics.fromJson(jsonDecode(jsonString));
    } catch (e) {
      debugPrint('Errore caricamento statistiche: $e');
      return const UsageStatistics();
    }
  }

  /// Carica i record delle analisi
  static Future<List<AnalysisRecord>> loadRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_recordsKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => AnalysisRecord.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Errore caricamento record: $e');
      return [];
    }
  }

  /// Registra una nuova analisi
  static Future<void> recordAnalysis({
    required String id,
    required String jurisdiction,
    required double amount,
    required String riskLevel,
    required int issuesCount,
  }) async {
    try {
      final now = DateTime.now();
      final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      // Carica dati esistenti
      final stats = await loadStatistics();
      final records = await loadRecords();

      // Aggiorna record
      final newRecord = AnalysisRecord(
        id: id,
        timestamp: now,
        jurisdiction: jurisdiction,
        amount: amount,
        riskLevel: riskLevel,
        issuesCount: issuesCount,
      );
      records.insert(0, newRecord);
      if (records.length > _maxRecords) {
        records.removeRange(_maxRecords, records.length);
      }

      // Calcola nuove statistiche
      final newAnalysesByMonth = Map<String, int>.from(stats.analysesByMonth);
      newAnalysesByMonth[monthKey] = (newAnalysesByMonth[monthKey] ?? 0) + 1;

      final newRiskLevelCounts = Map<String, int>.from(stats.riskLevelCounts);
      newRiskLevelCounts[riskLevel] = (newRiskLevelCounts[riskLevel] ?? 0) + 1;

      // Calcola media importi
      final totalAmount = records.fold<double>(0, (sum, r) => sum + r.amount);
      final newAverageAmount = records.isNotEmpty ? totalAmount / records.length : 0.0;

      // Top jurisdictions
      final jurisdictionCounts = <String, int>{};
      for (final record in records) {
        if (record.jurisdiction.isNotEmpty) {
          jurisdictionCounts[record.jurisdiction] =
              (jurisdictionCounts[record.jurisdiction] ?? 0) + 1;
        }
      }
      final sortedJurisdictions = jurisdictionCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topJurisdictions = sortedJurisdictions
          .take(5)
          .map((e) => e.key)
          .toList();

      // Aggiorna statistiche
      final newStats = stats.copyWith(
        totalAnalyses: stats.totalAnalyses + 1,
        analysesByMonth: newAnalysesByMonth,
        riskLevelCounts: newRiskLevelCounts,
        averageAmount: newAverageAmount,
        topJurisdictions: topJurisdictions,
        firstAnalysisDate: stats.firstAnalysisDate ?? now,
        lastAnalysisDate: now,
      );

      await _persistStatistics(newStats);
      await _persistRecords(records);
    } catch (e) {
      debugPrint('Errore registrazione analisi: $e');
    }
  }

  /// Registra generazione documento
  static Future<void> recordDocumentGenerated(String analysisId) async {
    try {
      final stats = await loadStatistics();
      final records = await loadRecords();

      // Aggiorna record se esiste
      final index = records.indexWhere((r) => r.id == analysisId);
      if (index >= 0) {
        final record = records[index];
        records[index] = AnalysisRecord(
          id: record.id,
          timestamp: record.timestamp,
          jurisdiction: record.jurisdiction,
          amount: record.amount,
          riskLevel: record.riskLevel,
          issuesCount: record.issuesCount,
          documentGenerated: true,
          documentShared: record.documentShared,
        );
        await _persistRecords(records);
      }

      final newStats = stats.copyWith(
        documentsGenerated: stats.documentsGenerated + 1,
      );
      await _persistStatistics(newStats);
    } catch (e) {
      debugPrint('Errore registrazione documento: $e');
    }
  }

  /// Registra condivisione documento
  static Future<void> recordDocumentShared(String analysisId) async {
    try {
      final stats = await loadStatistics();
      final records = await loadRecords();

      // Aggiorna record se esiste
      final index = records.indexWhere((r) => r.id == analysisId);
      if (index >= 0) {
        final record = records[index];
        records[index] = AnalysisRecord(
          id: record.id,
          timestamp: record.timestamp,
          jurisdiction: record.jurisdiction,
          amount: record.amount,
          riskLevel: record.riskLevel,
          issuesCount: record.issuesCount,
          documentGenerated: record.documentGenerated,
          documentShared: true,
        );
        await _persistRecords(records);
      }

      final newStats = stats.copyWith(
        documentsShared: stats.documentsShared + 1,
      );
      await _persistStatistics(newStats);
    } catch (e) {
      debugPrint('Errore registrazione condivisione: $e');
    }
  }

  /// Pulisci tutte le statistiche
  static Future<void> clearStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_statsKey);
      await prefs.remove(_recordsKey);
    } catch (e) {
      debugPrint('Errore pulizia statistiche: $e');
    }
  }

  static Future<void> _persistStatistics(UsageStatistics stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statsKey, jsonEncode(stats.toJson()));
  }

  static Future<void> _persistRecords(List<AnalysisRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _recordsKey,
      jsonEncode(records.map((r) => r.toJson()).toList()),
    );
  }
}
