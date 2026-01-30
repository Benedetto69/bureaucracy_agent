import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/document_history.dart';

/// Secure storage for document history with encryption and retention policy
class SecureDocumentHistoryStorage {
  static const _historyKey = 'secure_document_history';
  static const _maxEntries = 50;
  static const _retentionDays = 90;

  final FlutterSecureStorage _secureStorage;

  SecureDocumentHistoryStorage._()
      : _secureStorage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        );

  static SecureDocumentHistoryStorage? _instance;

  /// Get singleton instance
  static SecureDocumentHistoryStorage get instance {
    _instance ??= SecureDocumentHistoryStorage._();
    return _instance!;
  }

  /// Load history with automatic retention cleanup
  Future<List<DocumentHistoryEntry>> loadHistory() async {
    try {
      final raw = await _secureStorage.read(key: _historyKey);
      if (raw == null || raw.isEmpty) return [];

      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      final entries = decoded
          .map((entry) =>
              DocumentHistoryEntry.fromJson(entry as Map<String, dynamic>))
          .toList();

      // Apply retention policy - remove entries older than 90 days
      final now = DateTime.now();
      final filteredEntries = entries.where((entry) {
        final age = now.difference(entry.timestamp).inDays;
        return age <= _retentionDays;
      }).toList();

      // If we removed entries, save the cleaned list
      if (filteredEntries.length != entries.length) {
        await _saveEntriesInternal(filteredEntries);
        debugPrint(
            'Retention policy: removed ${entries.length - filteredEntries.length} old entries');
      }

      return filteredEntries;
    } catch (error) {
      debugPrint('Error loading secure history: $error');
      return [];
    }
  }

  /// Save history with max entries limit
  Future<void> saveHistory(List<DocumentHistoryEntry> entries) async {
    // Enforce max entries limit
    final limitedEntries = entries.length > _maxEntries
        ? entries.sublist(0, _maxEntries)
        : entries;

    await _saveEntriesInternal(limitedEntries);
  }

  Future<void> _saveEntriesInternal(List<DocumentHistoryEntry> entries) async {
    try {
      final encoded = entries.map((entry) => entry.toJson()).toList();
      await _secureStorage.write(
        key: _historyKey,
        value: jsonEncode(encoded),
      );
    } catch (error) {
      debugPrint('Error saving secure history: $error');
      rethrow;
    }
  }

  /// Add a single entry to history
  Future<void> addEntry(DocumentHistoryEntry entry) async {
    final entries = await loadHistory();
    entries.insert(0, entry); // Add to beginning (most recent first)
    await saveHistory(entries);
  }

  /// Remove a single entry by document ID
  Future<void> removeEntry(String documentId) async {
    final entries = await loadHistory();
    entries.removeWhere((e) => e.document.documentId == documentId);
    await saveHistory(entries);
  }

  /// Clear all history
  Future<void> clearHistory() async {
    try {
      await _secureStorage.delete(key: _historyKey);
    } catch (error) {
      debugPrint('Error clearing secure history: $error');
      rethrow;
    }
  }

  /// Export history as JSON string (for GDPR data portability)
  Future<String> exportHistory() async {
    final entries = await loadHistory();
    final exported = {
      'exported_at': DateTime.now().toIso8601String(),
      'entries': entries.map((e) => e.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(exported);
  }

  /// Get history statistics
  Future<Map<String, dynamic>> getStats() async {
    final entries = await loadHistory();
    if (entries.isEmpty) {
      return {
        'total_entries': 0,
        'oldest_entry': null,
        'newest_entry': null,
      };
    }

    final sorted = List<DocumentHistoryEntry>.from(entries)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return {
      'total_entries': entries.length,
      'oldest_entry': sorted.last.timestamp.toIso8601String(),
      'newest_entry': sorted.first.timestamp.toIso8601String(),
    };
  }
}
