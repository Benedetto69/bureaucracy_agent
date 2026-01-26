import 'package:flutter/material.dart';

import '../services/document_analyzer_models.dart';

class RiskStats extends StatelessWidget {
  final List<AnalysisIssue> issues;

  const RiskStats({super.key, required this.issues});

  @override
  Widget build(BuildContext context) {
    final stats = _calculateRiskStats();
    if (stats.isEmpty) {
      return const SizedBox();
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: stats
          .map(
            (stat) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF10131A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(stat.icon, color: stat.color, size: 20),
                  const SizedBox(height: 6),
                  Text(
                    stat.label,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stat.value.toString(),
                    style: TextStyle(
                      color: stat.color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  List<_RiskStat> _calculateRiskStats() {
    final counts = <IssueType, int>{};
    for (final issue in issues) {
      counts.update(issue.type, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts.entries
        .map((entry) => _RiskStat(
              label: entry.key.name.toUpperCase(),
              value: entry.value,
              color: _riskColor(_mapIssueTypeToRisk(entry.key)),
              icon: _mapIssueTypeToIcon(entry.key),
            ))
        .toList();
  }

  RiskLevel _mapIssueTypeToRisk(IssueType type) {
    switch (type) {
      case IssueType.substance:
        return RiskLevel.high;
      case IssueType.process:
        return RiskLevel.medium;
      case IssueType.formality:
        return RiskLevel.low;
    }
  }

  IconData _mapIssueTypeToIcon(IssueType type) {
    switch (type) {
      case IssueType.process:
        return Icons.calendar_month;
      case IssueType.formality:
        return Icons.document_scanner;
      case IssueType.substance:
        return Icons.gavel;
    }
  }

  Color _riskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.high:
        return Colors.redAccent;
      case RiskLevel.medium:
        return Colors.amberAccent;
      case RiskLevel.low:
        return Colors.greenAccent;
    }
  }
}

class _RiskStat {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  _RiskStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
}
