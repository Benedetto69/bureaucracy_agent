import 'package:flutter/material.dart';
import '../utils/deadline_calculator.dart';

/// Banner che mostra lo stato delle scadenze per il ricorso
class DeadlineBanner extends StatelessWidget {
  final DateTime notificationDate;
  final VoidCallback? onTap;

  const DeadlineBanner({
    required this.notificationDate,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final info = DeadlineCalculator.getDeadlineInfo(notificationDate);

    return GestureDetector(
      onTap: onTap ?? () => _showDeadlineDetails(context, info),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getGradientColors(info.status),
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getBorderColor(info.status),
            width: info.isUrgent ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _getShadowColor(info.status),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusIcon(info.status),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.title,
                        style: TextStyle(
                          color: _getTitleColor(info.status),
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        info.message,
                        style: TextStyle(
                          color: _getTextColor(info.status),
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!info.isExpired) _buildCountdown(info),
              ],
            ),
            if (info.actions.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: info.actions.map(_buildActionChip).toList(),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.touch_app,
                  size: 14,
                  color: _getTextColor(info.status).withAlpha(150),
                ),
                const SizedBox(width: 4),
                Text(
                  'Tocca per dettagli',
                  style: TextStyle(
                    color: _getTextColor(info.status).withAlpha(150),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(DeadlineStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case DeadlineStatus.expired:
        icon = Icons.error;
        color = Colors.red;
        break;
      case DeadlineStatus.urgent:
        icon = Icons.warning_amber_rounded;
        color = Colors.orange;
        break;
      case DeadlineStatus.warning:
        icon = Icons.schedule;
        color = Colors.amber;
        break;
      case DeadlineStatus.ok:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildCountdown(DeadlineInfo info) {
    final days = info.daysRemainingPrefetto;
    final color = _getCountdownColor(info.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        children: [
          Text(
            days.toString(),
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'giorni',
            style: TextStyle(
              color: color.withAlpha(200),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(DeadlineAction action) {
    final color = _getActionColor(action.type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getActionIcon(action.type),
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                action.label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                action.description,
                style: TextStyle(
                  color: color.withAlpha(180),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Color> _getGradientColors(DeadlineStatus status) {
    switch (status) {
      case DeadlineStatus.expired:
        return [const Color(0xFF2D1515), const Color(0xFF1A0F0F)];
      case DeadlineStatus.urgent:
        return [const Color(0xFF2D2015), const Color(0xFF1A140F)];
      case DeadlineStatus.warning:
        return [const Color(0xFF2D2A15), const Color(0xFF1A180F)];
      case DeadlineStatus.ok:
        return [const Color(0xFF152D1D), const Color(0xFF0F1A14)];
    }
  }

  Color _getBorderColor(DeadlineStatus status) {
    switch (status) {
      case DeadlineStatus.expired:
        return Colors.red.withAlpha(80);
      case DeadlineStatus.urgent:
        return Colors.orange.withAlpha(80);
      case DeadlineStatus.warning:
        return Colors.amber.withAlpha(80);
      case DeadlineStatus.ok:
        return Colors.green.withAlpha(80);
    }
  }

  Color _getShadowColor(DeadlineStatus status) {
    switch (status) {
      case DeadlineStatus.expired:
        return Colors.red.withAlpha(20);
      case DeadlineStatus.urgent:
        return Colors.orange.withAlpha(20);
      case DeadlineStatus.warning:
        return Colors.amber.withAlpha(20);
      case DeadlineStatus.ok:
        return Colors.green.withAlpha(20);
    }
  }

  Color _getTitleColor(DeadlineStatus status) {
    switch (status) {
      case DeadlineStatus.expired:
        return Colors.red.shade300;
      case DeadlineStatus.urgent:
        return Colors.orange.shade300;
      case DeadlineStatus.warning:
        return Colors.amber.shade300;
      case DeadlineStatus.ok:
        return Colors.green.shade300;
    }
  }

  Color _getTextColor(DeadlineStatus status) {
    switch (status) {
      case DeadlineStatus.expired:
        return Colors.red.shade100;
      case DeadlineStatus.urgent:
        return Colors.orange.shade100;
      case DeadlineStatus.warning:
        return Colors.amber.shade100;
      case DeadlineStatus.ok:
        return Colors.green.shade100;
    }
  }

  Color _getCountdownColor(DeadlineStatus status) {
    switch (status) {
      case DeadlineStatus.expired:
        return Colors.red;
      case DeadlineStatus.urgent:
        return Colors.orange;
      case DeadlineStatus.warning:
        return Colors.amber;
      case DeadlineStatus.ok:
        return Colors.green;
    }
  }

  Color _getActionColor(DeadlineActionType type) {
    switch (type) {
      case DeadlineActionType.ok:
        return Colors.green;
      case DeadlineActionType.warning:
        return Colors.amber;
      case DeadlineActionType.urgent:
        return Colors.orange;
      case DeadlineActionType.expired:
        return Colors.red;
      case DeadlineActionType.info:
        return Colors.blue;
    }
  }

  IconData _getActionIcon(DeadlineActionType type) {
    switch (type) {
      case DeadlineActionType.ok:
        return Icons.check_circle_outline;
      case DeadlineActionType.warning:
        return Icons.schedule;
      case DeadlineActionType.urgent:
        return Icons.priority_high;
      case DeadlineActionType.expired:
        return Icons.cancel_outlined;
      case DeadlineActionType.info:
        return Icons.info_outline;
    }
  }

  void _showDeadlineDetails(BuildContext context, DeadlineInfo info) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1117),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _DeadlineDetailsSheet(
        notificationDate: notificationDate,
        info: info,
      ),
    );
  }
}

class _DeadlineDetailsSheet extends StatelessWidget {
  final DateTime notificationDate;
  final DeadlineInfo info;

  const _DeadlineDetailsSheet({
    required this.notificationDate,
    required this.info,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.white70),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Dettaglio Scadenze',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
              'Data notifica',
              _formatDate(notificationDate),
              Icons.mail_outline,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Giorni trascorsi',
              '${info.daysSinceNotification} giorni',
              Icons.history,
            ),
            const Divider(color: Colors.white24, height: 32),
            const Text(
              'Scadenze disponibili',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            _buildDeadlineRow(
              'Ricorso al Prefetto',
              info.prefettoDeadline,
              info.daysRemainingPrefetto,
              'Gratuito, decide entro 180 giorni',
            ),
            const SizedBox(height: 10),
            _buildDeadlineRow(
              'Ricorso al Giudice di Pace',
              info.giudicePaceDeadline,
              info.daysRemainingGiudicePace,
              'Contributo unificato €43',
            ),
            if (info.daysRemainingEarlyPayment > 0) ...[
              const SizedBox(height: 10),
              _buildDeadlineRow(
                'Pagamento ridotto (-30%)',
                notificationDate.add(const Duration(days: 5)),
                info.daysRemainingEarlyPayment,
                'Sconto se paghi entro 5 giorni',
                highlight: true,
              ),
            ],
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withAlpha(40)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'I termini decorrono dal giorno successivo alla notifica. '
                      'Festivi inclusi nel conteggio.',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDeadlineRow(
    String label,
    DateTime deadline,
    int daysRemaining,
    String subtitle, {
    bool highlight = false,
  }) {
    final isExpired = daysRemaining < 0;
    final isUrgent = daysRemaining >= 0 && daysRemaining <= 5;
    final color = isExpired
        ? Colors.red
        : isUrgent
            ? Colors.orange
            : highlight
                ? Colors.green
                : Colors.white70;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: color.withAlpha(150),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatDate(deadline),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              Text(
                isExpired
                    ? 'Scaduto'
                    : daysRemaining == 0
                        ? 'Oggi!'
                        : '$daysRemaining giorni',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
