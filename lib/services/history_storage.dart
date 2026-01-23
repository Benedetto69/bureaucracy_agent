import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/document_history.dart';

class DocumentHistoryStorage {
  static const _historyKey = 'document_history';

  final SharedPreferences _prefs;

  DocumentHistoryStorage._(this._prefs);

  static Future<DocumentHistoryStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return DocumentHistoryStorage._(prefs);
  }

  Future<List<DocumentHistoryEntry>> loadHistory() async {
    final raw = _prefs.getStringList(_historyKey) ?? [];
    return raw
        .map((entry) => DocumentHistoryEntry.fromJson(
            jsonDecode(entry) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveHistory(List<DocumentHistoryEntry> entries) async {
    final encoded = entries.map((entry) => entry.encode()).toList();
    await _prefs.setStringList(_historyKey, encoded);
  }
}
