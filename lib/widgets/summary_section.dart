import 'package:flutter/material.dart';

import '../services/document_analyzer_models.dart';

class SummarySection extends StatelessWidget {
  final Summary? summary;
  final String defaultMessage;
  final String? serverTime;
  final String userId;
  final String jurisdiction;
  final String formattedAmount;
  final String formattedDate;

  const SummarySection({
    super.key,
    required this.summary,
    required this.defaultMessage,
    this.serverTime,
    required this.userId,
    required this.jurisdiction,
    required this.formattedAmount,
    required this.formattedDate,
  });

  @override
  Widget build(BuildContext context) {
    final riskLevel = summary?.riskLevel;
    final riskLabel = riskLevel?.name.toUpperCase() ?? 'STRATEGIA IN ATTESA';
    final nextStep = summary?.nextStep ?? defaultMessage;
    final serverTimeLabel =
        serverTime != null ? 'Aggiornato $serverTime' : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF141B2A),
            Color(0xFF0E121A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 14,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildRiskBadge(riskLevel),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rischio stimato: $riskLabel',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (serverTimeLabel != null)
                      Text(
                        serverTimeLabel,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            nextStep,
            style: const TextStyle(fontSize: 16, color: Colors.greenAccent),
          ),
          const SizedBox(height: 16),
          _buildMetadataChips(),
        ],
      ),
    );
  }

  Widget _buildRiskBadge(RiskLevel? level) {
    final color = _riskColor(level);
    final label = level?.name.toUpperCase() ?? 'ATTESA';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha((0.25 * 255).round()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataChips() {
    final chips = <Widget>[
      _metadataChip('Cliente', userId),
      _metadataChip('Giurisdizione', jurisdiction),
      _metadataChip('Importo', formattedAmount),
      _metadataChip('Notifica', formattedDate),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: chips,
    );
  }

  Widget _metadataChip(String label, String value) {
    return Chip(
      label: Text(
        '$label: $value',
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
      backgroundColor: Colors.blueGrey.shade900,
      side: const BorderSide(color: Colors.blueGrey),
    );
  }

  Color _riskColor(RiskLevel? level) {
    switch (level) {
      case RiskLevel.high:
        return Colors.redAccent;
      case RiskLevel.medium:
        return Colors.amberAccent;
      case RiskLevel.low:
        return Colors.greenAccent;
      default:
        return Colors.blueGrey;
    }
  }
}
