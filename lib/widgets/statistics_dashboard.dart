import 'package:flutter/material.dart';

import '../services/usage_statistics_service.dart';

/// Dashboard per visualizzare le statistiche di utilizzo
class StatisticsDashboard extends StatefulWidget {
  const StatisticsDashboard({super.key});

  @override
  State<StatisticsDashboard> createState() => _StatisticsDashboardState();
}

class _StatisticsDashboardState extends State<StatisticsDashboard> {
  UsageStatistics _stats = const UsageStatistics();
  List<AnalysisRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final stats = await UsageStatisticsService.loadStatistics();
    final records = await UsageStatisticsService.loadRecords();
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _records = records;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF151C26), Color(0xFF0D1218)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildMainStats(),
          const SizedBox(height: 16),
          _buildSuccessIndicator(),
          const SizedBox(height: 16),
          _buildRiskDistribution(),
          if (_stats.topJurisdictions.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildTopJurisdictions(),
          ],
          if (_records.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildRecentActivity(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.analytics, color: Colors.blue, size: 22),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Le tue statistiche',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
              Text(
                'Riepilogo delle analisi effettuate',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh, color: Colors.white54, size: 20),
          tooltip: 'Aggiorna',
        ),
      ],
    );
  }

  Widget _buildMainStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.search,
            iconColor: Colors.blue,
            value: _stats.totalAnalyses.toString(),
            label: 'Analisi',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            icon: Icons.description,
            iconColor: Colors.green,
            value: _stats.documentsGenerated.toString(),
            label: 'Documenti',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            icon: Icons.share,
            iconColor: Colors.purple,
            value: _stats.documentsShared.toString(),
            label: 'Condivisi',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessIndicator() {
    final successRate = _stats.estimatedSuccessRate;
    final percentage = (successRate * 100).toInt();

    Color getColor() {
      if (successRate >= 0.6) return Colors.green;
      if (successRate >= 0.4) return Colors.amber;
      return Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: getColor().withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: getColor(), size: 18),
              const SizedBox(width: 8),
              const Text(
                'Tasso di successo stimato',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const Spacer(),
              Text(
                '$percentage%',
                style: TextStyle(
                  color: getColor(),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: successRate,
              backgroundColor: Colors.white.withAlpha(20),
              valueColor: AlwaysStoppedAnimation<Color>(getColor()),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getSuccessMessage(successRate),
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _getSuccessMessage(double rate) {
    if (rate >= 0.6) {
      return 'Ottimo! La maggior parte delle analisi indica buone possibilita di successo.';
    }
    if (rate >= 0.4) {
      return 'Risultati misti. Valuta attentamente ogni caso prima di procedere.';
    }
    if (rate > 0) {
      return 'Attenzione: molti casi presentano rischi elevati.';
    }
    return 'Nessun dato disponibile. Effettua delle analisi per vedere le statistiche.';
  }

  Widget _buildRiskDistribution() {
    final lowRisk = _stats.riskLevelCounts['low'] ?? 0;
    final mediumRisk = _stats.riskLevelCounts['medium'] ?? 0;
    final highRisk = _stats.riskLevelCounts['high'] ?? 0;
    final total = lowRisk + mediumRisk + highRisk;

    if (total == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribuzione rischio',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildRiskChip('Basso', lowRisk, Colors.green, total),
              const SizedBox(width: 8),
              _buildRiskChip('Medio', mediumRisk, Colors.amber, total),
              const SizedBox(width: 8),
              _buildRiskChip('Alto', highRisk, Colors.red, total),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskChip(String label, int count, Color color, int total) {
    final percentage = total > 0 ? (count / total * 100).toInt() : 0;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$label ($percentage%)',
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopJurisdictions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_city, color: Colors.white54, size: 16),
              SizedBox(width: 8),
              Text(
                'Giurisdizioni piu analizzate',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _stats.topJurisdictions.map((j) {
              return Chip(
                label: Text(j, style: const TextStyle(fontSize: 11)),
                backgroundColor: Colors.blue.withAlpha(20),
                labelStyle: const TextStyle(color: Colors.blue),
                side: BorderSide.none,
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final recentRecords = _records.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history, color: Colors.white54, size: 16),
              SizedBox(width: 8),
              Text(
                'Attivita recente',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recentRecords.map((record) => _buildActivityItem(record)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(AnalysisRecord record) {
    final riskColor = switch (record.riskLevel) {
      'low' => Colors.green,
      'medium' => Colors.amber,
      'high' => Colors.red,
      _ => Colors.grey,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: riskColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.jurisdiction.isNotEmpty ? record.jurisdiction : 'Analisi',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                Text(
                  '${_formatDate(record.timestamp)} - ${record.issuesCount} problemi',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
          Text(
            record.amount.toStringAsFixed(0),
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          if (record.documentGenerated)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.description, color: Colors.green, size: 14),
            ),
          if (record.documentShared)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.share, color: Colors.purple, size: 14),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Oggi ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) {
      return 'Ieri';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} giorni fa';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Widget compatto per mostrare statistiche nella home
class StatisticsMiniCard extends StatefulWidget {
  final VoidCallback? onTap;

  const StatisticsMiniCard({super.key, this.onTap});

  @override
  State<StatisticsMiniCard> createState() => _StatisticsMiniCardState();
}

class _StatisticsMiniCardState extends State<StatisticsMiniCard> {
  UsageStatistics _stats = const UsageStatistics();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await UsageStatisticsService.loadStatistics();
    if (mounted) {
      setState(() => _stats = stats);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_stats.totalAnalyses == 0) {
      return const SizedBox.shrink();
    }

    final successRate = (_stats.estimatedSuccessRate * 100).toInt();

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withAlpha(40)),
        ),
        child: Row(
          children: [
            const Icon(Icons.analytics, color: Colors.blue, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${_stats.totalAnalyses} analisi - $successRate% successo stimato',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
          ],
        ),
      ),
    );
  }
}
