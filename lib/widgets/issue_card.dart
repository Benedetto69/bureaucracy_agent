import 'package:flutter/material.dart';

import '../services/document_analyzer_models.dart';

class IssueCard extends StatelessWidget {
  final AnalysisIssue issue;

  const IssueCard({super.key, required this.issue});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '[${issue.type.name.toUpperCase()}] ${issue.issue}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: issue.references.map((ref) {
                return Tooltip(
                  message: ref.url.toString(),
                  child: Chip(
                    label: Text(
                      '${ref.citation} (${ref.source.name.toUpperCase()})',
                      overflow: TextOverflow.ellipsis,
                    ),
                    backgroundColor: Colors.blueGrey.shade800,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text('Azioni consigliate:',
                style: TextStyle(color: Colors.grey[300])),
            ...issue.actions.map((action) => Row(
                  children: [
                    const Icon(Icons.chevron_right,
                        size: 20, color: Colors.greenAccent),
                    Expanded(
                      child: Text(
                        action,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                )),
          ],
        ),
      ),
    );
  }
}
