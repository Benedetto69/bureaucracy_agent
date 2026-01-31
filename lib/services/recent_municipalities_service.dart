import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'municipalities_database.dart';

/// Entry per un comune recente
class RecentMunicipalityEntry {
  final String municipalityName;
  final DateTime lastUsed;
  final int useCount;

  const RecentMunicipalityEntry({
    required this.municipalityName,
    required this.lastUsed,
    this.useCount = 1,
  });

  RecentMunicipalityEntry copyWith({
    String? municipalityName,
    DateTime? lastUsed,
    int? useCount,
  }) {
    return RecentMunicipalityEntry(
      municipalityName: municipalityName ?? this.municipalityName,
      lastUsed: lastUsed ?? this.lastUsed,
      useCount: useCount ?? this.useCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': municipalityName,
        'lastUsed': lastUsed.toIso8601String(),
        'useCount': useCount,
      };

  factory RecentMunicipalityEntry.fromJson(Map<String, dynamic> json) {
    return RecentMunicipalityEntry(
      municipalityName: json['name'] as String,
      lastUsed: DateTime.parse(json['lastUsed'] as String),
      useCount: json['useCount'] as int? ?? 1,
    );
  }
}

/// Servizio per gestire i comuni usati di recente
class RecentMunicipalitiesService {
  static const String _storageKey = 'recent_municipalities';
  static const int _maxRecentItems = 10;

  /// Carica i comuni recenti
  static Future<List<RecentMunicipalityEntry>> loadRecent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final entries = jsonList
          .map((json) => RecentMunicipalityEntry.fromJson(json as Map<String, dynamic>))
          .toList();
      // Ordina per uso recente
      entries.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
      return entries;
    } catch (e) {
      debugPrint('Errore caricamento comuni recenti: $e');
      return [];
    }
  }

  /// Ottieni i comuni recenti come Municipality objects
  static Future<List<Municipality>> getRecentMunicipalities() async {
    final entries = await loadRecent();
    final municipalities = <Municipality>[];
    for (final entry in entries) {
      final results = MunicipalitiesDatabase.search(entry.municipalityName);
      if (results.isNotEmpty) {
        // Trova match esatto
        final exactMatch = results.where((m) =>
          m.name.toLowerCase() == entry.municipalityName.toLowerCase()
        ).firstOrNull;
        if (exactMatch != null) {
          municipalities.add(exactMatch);
        } else {
          municipalities.add(results.first);
        }
      }
    }
    return municipalities;
  }

  /// Ottieni i comuni piu usati (ordinati per frequenza)
  static Future<List<Municipality>> getMostUsedMunicipalities({int limit = 5}) async {
    final entries = await loadRecent();
    // Ordina per conteggio utilizzo
    entries.sort((a, b) => b.useCount.compareTo(a.useCount));

    final municipalities = <Municipality>[];
    for (final entry in entries.take(limit)) {
      final results = MunicipalitiesDatabase.search(entry.municipalityName);
      if (results.isNotEmpty) {
        final exactMatch = results.where((m) =>
          m.name.toLowerCase() == entry.municipalityName.toLowerCase()
        ).firstOrNull;
        if (exactMatch != null) {
          municipalities.add(exactMatch);
        } else {
          municipalities.add(results.first);
        }
      }
    }
    return municipalities;
  }

  /// Registra l'uso di un comune
  static Future<void> recordUsage(String municipalityName) async {
    try {
      final entries = await loadRecent();
      final now = DateTime.now();

      // Cerca se esiste gia
      final existingIndex = entries.indexWhere(
        (e) => e.municipalityName.toLowerCase() == municipalityName.toLowerCase(),
      );

      if (existingIndex >= 0) {
        // Aggiorna entry esistente
        final existing = entries[existingIndex];
        entries[existingIndex] = existing.copyWith(
          lastUsed: now,
          useCount: existing.useCount + 1,
        );
      } else {
        // Aggiungi nuovo
        entries.add(RecentMunicipalityEntry(
          municipalityName: municipalityName,
          lastUsed: now,
          useCount: 1,
        ));
      }

      // Ordina per uso recente e limita
      entries.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
      final toSave = entries.take(_maxRecentItems).toList();

      await _persist(toSave);
    } catch (e) {
      debugPrint('Errore salvataggio comune recente: $e');
    }
  }

  /// Rimuovi un comune dalla lista recenti
  static Future<void> removeRecent(String municipalityName) async {
    try {
      final entries = await loadRecent();
      entries.removeWhere(
        (e) => e.municipalityName.toLowerCase() == municipalityName.toLowerCase(),
      );
      await _persist(entries);
    } catch (e) {
      debugPrint('Errore rimozione comune recente: $e');
    }
  }

  /// Pulisci tutta la cronologia
  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('Errore pulizia cronologia comuni: $e');
    }
  }

  static Future<void> _persist(List<RecentMunicipalityEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }
}
