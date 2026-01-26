import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/document_history.dart';

class DocumentHistoryList extends StatelessWidget {
  final List<DocumentHistoryEntry> history;

  const DocumentHistoryList({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: history.map((entry) {
        return Card(
          color: const Color(0xFF1D1E24),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.document.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                Text(
                  entry.document.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.timestamp.toIso8601String().split('T').first,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.greenAccent),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: entry.document.body));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Testo copiato negli appunti')),
                        );
                      },
                    )
                  ],
                )
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
