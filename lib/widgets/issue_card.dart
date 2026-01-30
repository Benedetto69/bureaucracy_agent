import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/document_analyzer_models.dart';

class IssueCard extends StatelessWidget {
  final AnalysisIssue issue;

  const IssueCard({super.key, required this.issue});

  @override
  Widget build(BuildContext context) {
    final typeLabel = issue.type.name.toUpperCase();
    final quickSummary =
        'Issue: $typeLabel\n${issue.issue}\nAzioni: ${issue.actions.join('; ')}';
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: const Color(0xFF1C1C1C),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _buildTypeBadge(typeLabel),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    issue.issue,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: issue.references.map((ref) {
                return Tooltip(
                  message: ref.url.toString(),
                  child: Chip(
                    label: Text(
                      '${ref.citation} (${ref.source.name.toUpperCase()})',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.blueGrey.shade800,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            const Text(
              'Azioni consigliate',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            ...issue.actions.map((action) => Row(
                  children: [
                    const Icon(Icons.arrow_right, size: 20, color: Colors.greenAccent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(action, style: const TextStyle(color: Colors.white70)),
                    ),
                  ],
                )),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: quickSummary));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Testo copiato negli appunti'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copia istruzioni'),
                ),
                const SizedBox(width: 6),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blueAccent,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    // Could trigger share or open help screen in future.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Preparazione documento in arrivo'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.document_scanner, size: 16),
                  label: const Text('Prepara bozza'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white10,
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
