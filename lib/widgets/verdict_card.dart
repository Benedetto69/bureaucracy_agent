import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Verdict recommendation type
enum VerdictType {
  pay,      // PAGA - Pay the fine
  evaluate, // VALUTA - Evaluate options
  contest,  // CONTESTA - Contest the fine
}

/// Risk item for the verdict
class VerdictRisk {
  final String title;
  final String description;
  final bool isPositive;

  const VerdictRisk({
    required this.title,
    required this.description,
    this.isPositive = false,
  });
}

/// Configuration for the verdict display
class VerdictConfig {
  final VerdictType type;
  final double successProbability; // 0.0 to 1.0
  final String reasoning;
  final List<VerdictRisk> risks;
  final List<VerdictRisk> benefits;

  const VerdictConfig({
    required this.type,
    required this.successProbability,
    required this.reasoning,
    this.risks = const [],
    this.benefits = const [],
  });
}

/// Final verdict card showing recommendation, probability, and risks
class VerdictCard extends StatelessWidget {
  final VerdictConfig config;
  final VoidCallback? onContestPressed;
  final VoidCallback? onPayPressed;

  const VerdictCard({
    super.key,
    required this.config,
    this.onContestPressed,
    this.onPayPressed,
  });

  @override
  Widget build(BuildContext context) {
    final verdictStyle = _getVerdictStyle(config.type);
    final probabilityPercent = (config.successProbability * 100).toInt();

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
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: verdictStyle.color.withAlpha(60),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: verdictStyle.color.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with verdict badge
          _buildHeader(verdictStyle),

          // Success probability meter
          _buildProbabilityMeter(probabilityPercent, verdictStyle),

          // Reasoning
          _buildReasoning(),

          // Risk/Benefit balance
          if (config.risks.isNotEmpty || config.benefits.isNotEmpty)
            _buildRiskBenefitSection(),

          // Disclaimer
          _buildDisclaimer(),

          // Action buttons
          _buildActions(verdictStyle),
        ],
      ),
    );
  }

  Widget _buildHeader(_VerdictStyle style) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: style.color.withAlpha(15),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(
                Icons.gavel_rounded,
                color: AppColors.textTertiary,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'VERDETTO FINALE',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: style.color.withAlpha(30),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: style.color.withAlpha(60)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(style.icon, color: style.color, size: 24),
                const SizedBox(width: 12),
                Text(
                  style.label,
                  style: TextStyle(
                    color: style.color,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProbabilityMeter(int percent, _VerdictStyle style) {
    final probabilityColor = _getProbabilityColor(percent);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.trending_up_rounded, size: 16, color: AppColors.textTertiary),
                  SizedBox(width: 8),
                  Text(
                    'Probabilita di successo stimata',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: probabilityColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$percent%',
                  style: TextStyle(
                    color: probabilityColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: config.successProbability,
              minHeight: 10,
              backgroundColor: AppColors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(probabilityColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bassa',
                style: TextStyle(
                  color: AppColors.textTertiary.withAlpha(150),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Alta',
                style: TextStyle(
                  color: AppColors.textTertiary.withAlpha(150),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReasoning() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 14, color: AppColors.warning),
                SizedBox(width: 8),
                Text(
                  'Motivazione',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              config.reasoning,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskBenefitSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.balance_outlined, size: 14, color: AppColors.textTertiary),
              SizedBox(width: 8),
              Text(
                'Bilancio rischi/benefici',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Benefits
          if (config.benefits.isNotEmpty) ...[
            ...config.benefits.map((benefit) => _buildRiskBenefitItem(benefit, true)),
          ],

          // Risks
          if (config.risks.isNotEmpty) ...[
            ...config.risks.map((risk) => _buildRiskBenefitItem(risk, false)),
          ],
        ],
      ),
    );
  }

  Widget _buildRiskBenefitItem(VerdictRisk item, bool isBenefit) {
    final color = isBenefit ? AppColors.success : AppColors.error;
    final icon = isBenefit ? Icons.add_circle_outline : Icons.remove_circle_outline;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.info.withAlpha(10),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.info.withAlpha(30)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 16, color: AppColors.info),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Questa analisi non costituisce parere legale. Per decisioni importanti, consulta un avvocato.',
                style: TextStyle(
                  color: AppColors.info,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(_VerdictStyle style) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (config.type != VerdictType.pay)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPayPressed,
                icon: const Icon(Icons.payment_outlined, size: 18),
                label: const Text('Paga multa'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.surfaceElevated),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          if (config.type != VerdictType.pay) const SizedBox(width: 12),
          Expanded(
            flex: config.type == VerdictType.pay ? 1 : 2,
            child: ElevatedButton.icon(
              onPressed: config.type == VerdictType.pay ? onPayPressed : onContestPressed,
              icon: Icon(
                config.type == VerdictType.pay
                    ? Icons.payment_outlined
                    : Icons.edit_document,
                size: 18,
              ),
              label: Text(
                config.type == VerdictType.pay
                    ? 'Paga la multa'
                    : 'Genera ricorso',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: style.color,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getProbabilityColor(int percent) {
    if (percent >= 70) return AppColors.success;
    if (percent >= 40) return AppColors.warning;
    return AppColors.error;
  }

  _VerdictStyle _getVerdictStyle(VerdictType type) {
    switch (type) {
      case VerdictType.pay:
        return const _VerdictStyle(
          label: 'PAGA',
          icon: Icons.payment_outlined,
          color: AppColors.error,
        );
      case VerdictType.evaluate:
        return const _VerdictStyle(
          label: 'VALUTA',
          icon: Icons.psychology_outlined,
          color: AppColors.warning,
        );
      case VerdictType.contest:
        return const _VerdictStyle(
          label: 'CONTESTA',
          icon: Icons.gavel_outlined,
          color: AppColors.success,
        );
    }
  }
}

class _VerdictStyle {
  final String label;
  final IconData icon;
  final Color color;

  const _VerdictStyle({
    required this.label,
    required this.icon,
    required this.color,
  });
}
