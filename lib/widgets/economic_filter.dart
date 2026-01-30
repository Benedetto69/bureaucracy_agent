import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Economic analysis data for fine contestation
class EconomicAnalysis {
  final double fineAmount;
  final double? reducedAmount; // If paid within deadline
  final double estimatedLegalCosts;
  final double estimatedTimeCost; // In hours
  final double hourlyRate; // User's time value
  final int estimatedDays; // Time to resolution
  final double successProbability;

  const EconomicAnalysis({
    required this.fineAmount,
    this.reducedAmount,
    required this.estimatedLegalCosts,
    required this.estimatedTimeCost,
    this.hourlyRate = 20.0,
    required this.estimatedDays,
    required this.successProbability,
  });

  /// Calculate if contesting is economically worth it
  double get netBenefitIfWin {
    final totalCost = estimatedLegalCosts + (estimatedTimeCost * hourlyRate);
    return fineAmount - totalCost;
  }

  double get expectedValue {
    final potentialGain = fineAmount * successProbability;
    final totalCost = estimatedLegalCosts + (estimatedTimeCost * hourlyRate);
    return potentialGain - totalCost;
  }

  bool get isEconomicallyWorthIt => expectedValue > 0;
}

/// Economic filter widget showing cost-benefit analysis
class EconomicFilter extends StatelessWidget {
  final EconomicAnalysis analysis;
  final VoidCallback? onLearnMore;

  const EconomicFilter({
    super.key,
    required this.analysis,
    this.onLearnMore,
  });

  @override
  Widget build(BuildContext context) {
    final isWorthIt = analysis.isEconomicallyWorthIt;
    final verdictColor = isWorthIt ? AppColors.success : AppColors.warning;

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
          color: AppColors.surfaceElevated,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _buildHeader(verdictColor),

          // Main comparison
          _buildComparison(),

          // Expected value
          _buildExpectedValue(verdictColor),

          // Time investment
          _buildTimeInvestment(),

          // Bottom verdict
          _buildVerdict(isWorthIt, verdictColor),
        ],
      ),
    );
  }

  Widget _buildHeader(Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withAlpha(10),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.calculate_outlined,
              color: accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtro Economico',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Conviene contestare?',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparison() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          // Pay option
          Expanded(
            child: _buildOptionCard(
              title: 'Se paghi',
              icon: Icons.payment_outlined,
              color: AppColors.error,
              items: [
                _CostItem(
                  label: 'Multa',
                  value: analysis.fineAmount,
                  isNegative: true,
                ),
                if (analysis.reducedAmount != null)
                  _CostItem(
                    label: 'Ridotta (5gg)',
                    value: analysis.reducedAmount!,
                    isNegative: true,
                    isHighlighted: true,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Contest option
          Expanded(
            child: _buildOptionCard(
              title: 'Se contesti',
              icon: Icons.gavel_outlined,
              color: AppColors.success,
              items: [
                _CostItem(
                  label: 'Costi legali',
                  value: analysis.estimatedLegalCosts,
                  isNegative: true,
                ),
                _CostItem(
                  label: 'Tempo (${analysis.estimatedTimeCost.toInt()}h)',
                  value: analysis.estimatedTimeCost * analysis.hourlyRate,
                  isNegative: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<_CostItem> items,
  }) {
    final total = items.fold<double>(0, (sum, item) => sum + item.value);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(8),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    color: item.isHighlighted
                        ? AppColors.success
                        : AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  '${item.isNegative ? "-" : "+"}\u20AC${item.value.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: item.isHighlighted
                        ? AppColors.success
                        : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Totale',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '\u20AC${total.toStringAsFixed(0)}',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpectedValue(Color verdictColor) {
    final expectedValue = analysis.expectedValue;
    final isPositive = expectedValue > 0;
    final probabilityPercent = (analysis.successProbability * 100).toInt();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_outlined, size: 14, color: AppColors.info),
                const SizedBox(width: 8),
                const Text(
                  'Valore atteso del ricorso',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.info.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$probabilityPercent% prob.',
                    style: const TextStyle(
                      color: AppColors.info,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: isPositive ? AppColors.success : AppColors.error,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '${isPositive ? "+" : ""}\u20AC${expectedValue.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: isPositive ? AppColors.success : AppColors.error,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isPositive
                  ? 'In media, conviene contestare'
                  : 'In media, conviene pagare',
              style: TextStyle(
                color: isPositive ? AppColors.success : AppColors.warning,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInvestment() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          const Icon(Icons.schedule_outlined, size: 14, color: AppColors.textTertiary),
          const SizedBox(width: 8),
          Text(
            'Tempo stimato: ${analysis.estimatedDays} giorni per la risoluzione',
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerdict(bool isWorthIt, Color color) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(
        children: [
          Icon(
            isWorthIt ? Icons.thumb_up_outlined : Icons.thumb_down_outlined,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isWorthIt
                  ? 'Dal punto di vista economico, il ricorso potrebbe convenire.'
                  : 'Dal punto di vista puramente economico, potrebbe convenire pagare. Ma ci sono altri fattori da considerare.',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CostItem {
  final String label;
  final double value;
  final bool isNegative;
  final bool isHighlighted;

  const _CostItem({
    required this.label,
    required this.value,
    this.isNegative = false,
    this.isHighlighted = false,
  });
}
