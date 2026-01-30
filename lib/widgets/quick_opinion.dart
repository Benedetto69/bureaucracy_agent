import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Quick opinion sentiment type
enum OpinionSentiment {
  positive,  // Green - good chances
  neutral,   // Yellow - uncertain
  negative,  // Red - low chances
}

/// Quick opinion data model
class QuickOpinionData {
  final String opinion; // 3-5 sentences max
  final OpinionSentiment sentiment;
  final String bottomLine; // Single sentence takeaway
  final double confidence; // 0.0 to 1.0

  const QuickOpinionData({
    required this.opinion,
    required this.sentiment,
    required this.bottomLine,
    required this.confidence,
  });
}

/// Quick opinion widget - concise 3-5 sentence summary
class QuickOpinion extends StatelessWidget {
  final QuickOpinionData data;
  final VoidCallback? onExpandDetails;
  final VoidCallback? onCopy;
  final bool showExpandButton;

  const QuickOpinion({
    super.key,
    required this.data,
    this.onExpandDetails,
    this.onCopy,
    this.showExpandButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final sentimentStyle = _getSentimentStyle(data.sentiment);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceLight,
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: sentimentStyle.color.withAlpha(50),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: sentimentStyle.color.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with sentiment indicator
          _buildHeader(sentimentStyle),

          // Opinion content
          _buildOpinionContent(),

          // Bottom line
          _buildBottomLine(sentimentStyle),

          // Actions
          if (showExpandButton || onCopy != null)
            _buildActions(context, sentimentStyle),
        ],
      ),
    );
  }

  Widget _buildHeader(_SentimentStyle style) {
    final confidencePercent = (data.confidence * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: style.color.withAlpha(10),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      child: Row(
        children: [
          // Sentiment icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: style.color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              style.icon,
              color: style.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Parere Rapido',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: style.color.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        style.label,
                        style: TextStyle(
                          color: style.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Affidabilita: $confidencePercent%',
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpinionContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Text(
        data.opinion,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildBottomLine(_SentimentStyle style) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: style.color.withAlpha(12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: style.color.withAlpha(35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.format_quote_rounded,
            color: style.color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              data.bottomLine,
              style: TextStyle(
                color: style.color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, _SentimentStyle style) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (onCopy != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _copyToClipboard(context);
                  onCopy?.call();
                },
                icon: const Icon(Icons.copy_outlined, size: 16),
                label: const Text('Copia'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.surfaceElevated),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          if (onCopy != null && showExpandButton) const SizedBox(width: 10),
          if (showExpandButton)
            Expanded(
              flex: onCopy != null ? 2 : 1,
              child: ElevatedButton.icon(
                onPressed: onExpandDetails,
                icon: const Icon(Icons.expand_more, size: 18),
                label: const Text('Vedi analisi completa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: style.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    final buffer = StringBuffer();
    buffer.writeln('PARERE RAPIDO');
    buffer.writeln();
    buffer.writeln(data.opinion);
    buffer.writeln();
    buffer.writeln('IN SINTESI: ${data.bottomLine}');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 20),
            SizedBox(width: 12),
            Text('Parere copiato negli appunti'),
          ],
        ),
        backgroundColor: AppColors.surfaceElevated,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  _SentimentStyle _getSentimentStyle(OpinionSentiment sentiment) {
    switch (sentiment) {
      case OpinionSentiment.positive:
        return const _SentimentStyle(
          label: 'BUONE POSSIBILITA',
          icon: Icons.thumb_up_outlined,
          color: AppColors.success,
        );
      case OpinionSentiment.neutral:
        return const _SentimentStyle(
          label: 'DA VALUTARE',
          icon: Icons.psychology_outlined,
          color: AppColors.warning,
        );
      case OpinionSentiment.negative:
        return const _SentimentStyle(
          label: 'DIFFICILE',
          icon: Icons.thumb_down_outlined,
          color: AppColors.error,
        );
    }
  }
}

class _SentimentStyle {
  final String label;
  final IconData icon;
  final Color color;

  const _SentimentStyle({
    required this.label,
    required this.icon,
    required this.color,
  });
}
