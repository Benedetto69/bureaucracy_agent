import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Type of disclaimer for different contexts
enum DisclaimerType {
  info,      // General information
  warning,   // Warning/caution
  legal,     // Legal disclaimer
  ai,        // AI-generated content disclaimer
}

/// Reusable disclaimer banner widget
class DisclaimerBanner extends StatelessWidget {
  final String message;
  final DisclaimerType type;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final bool isDismissible;
  final bool isCompact;

  const DisclaimerBanner({
    super.key,
    required this.message,
    this.type = DisclaimerType.info,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    this.isDismissible = false,
    this.isCompact = false,
  });

  /// Legal disclaimer preset
  factory DisclaimerBanner.legal({
    Key? key,
    String? customMessage,
    VoidCallback? onLearnMore,
  }) {
    return DisclaimerBanner(
      key: key,
      message: customMessage ??
          'Questa analisi non costituisce parere legale. Le informazioni sono fornite a scopo informativo. Per decisioni importanti, consulta un avvocato.',
      type: DisclaimerType.legal,
      actionLabel: onLearnMore != null ? 'Scopri di piu' : null,
      onAction: onLearnMore,
    );
  }

  /// AI-generated content disclaimer preset
  factory DisclaimerBanner.aiGenerated({
    Key? key,
    String? customMessage,
  }) {
    return DisclaimerBanner(
      key: key,
      message: customMessage ??
          'Contenuto generato con l\'aiuto dell\'intelligenza artificiale. Verifica sempre le informazioni con fonti ufficiali.',
      type: DisclaimerType.ai,
    );
  }

  /// Warning disclaimer preset
  factory DisclaimerBanner.warning({
    Key? key,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    bool isDismissible = false,
  }) {
    return DisclaimerBanner(
      key: key,
      message: message,
      type: DisclaimerType.warning,
      actionLabel: actionLabel,
      onAction: onAction,
      isDismissible: isDismissible,
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = _getDisclaimerStyle(type);
    final padding = isCompact
        ? const EdgeInsets.all(10)
        : const EdgeInsets.all(14);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: style.color.withAlpha(12),
        borderRadius: BorderRadius.circular(isCompact ? AppRadius.sm : AppRadius.md),
        border: Border.all(
          color: style.color.withAlpha(35),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: EdgeInsets.all(isCompact ? 4 : 6),
                decoration: BoxDecoration(
                  color: style.color.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  style.icon,
                  color: style.color,
                  size: isCompact ? 14 : 16,
                ),
              ),
              SizedBox(width: isCompact ? 10 : 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isCompact) ...[
                      Text(
                        style.label,
                        style: TextStyle(
                          color: style.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      message,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: isCompact ? 11 : 12,
                        height: 1.4,
                      ),
                    ),
                    if (actionLabel != null && onAction != null) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: onAction,
                        child: Text(
                          actionLabel!,
                          style: TextStyle(
                            color: style.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: style.color.withAlpha(100),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Dismiss button
              if (isDismissible && onDismiss != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDismiss,
                  child: Icon(
                    Icons.close,
                    color: AppColors.textTertiary,
                    size: isCompact ? 16 : 18,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  _DisclaimerStyle _getDisclaimerStyle(DisclaimerType type) {
    switch (type) {
      case DisclaimerType.info:
        return const _DisclaimerStyle(
          label: 'INFORMAZIONE',
          icon: Icons.info_outline,
          color: AppColors.info,
        );
      case DisclaimerType.warning:
        return const _DisclaimerStyle(
          label: 'ATTENZIONE',
          icon: Icons.warning_amber_outlined,
          color: AppColors.warning,
        );
      case DisclaimerType.legal:
        return const _DisclaimerStyle(
          label: 'AVVISO LEGALE',
          icon: Icons.gavel_outlined,
          color: AppColors.accent,
        );
      case DisclaimerType.ai:
        return const _DisclaimerStyle(
          label: 'GENERATO CON AI',
          icon: Icons.auto_awesome_outlined,
          color: AppColors.info,
        );
    }
  }
}

class _DisclaimerStyle {
  final String label;
  final IconData icon;
  final Color color;

  const _DisclaimerStyle({
    required this.label,
    required this.icon,
    required this.color,
  });
}

/// Animated disclaimer that can expand/collapse
class ExpandableDisclaimer extends StatefulWidget {
  final String title;
  final String shortMessage;
  final String fullMessage;
  final DisclaimerType type;

  const ExpandableDisclaimer({
    super.key,
    required this.title,
    required this.shortMessage,
    required this.fullMessage,
    this.type = DisclaimerType.legal,
  });

  @override
  State<ExpandableDisclaimer> createState() => _ExpandableDisclaimerState();
}

class _ExpandableDisclaimerState extends State<ExpandableDisclaimer> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final style = _getDisclaimerStyle(widget.type);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: style.color.withAlpha(10),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: style.color.withAlpha(30),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      style.icon,
                      color: style.color,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          color: style.color,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: style.color,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AnimatedCrossFade(
                  firstChild: Text(
                    widget.shortMessage,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  secondChild: Text(
                    widget.fullMessage,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  crossFadeState: _isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _DisclaimerStyle _getDisclaimerStyle(DisclaimerType type) {
    switch (type) {
      case DisclaimerType.info:
        return const _DisclaimerStyle(
          label: 'INFORMAZIONE',
          icon: Icons.info_outline,
          color: AppColors.info,
        );
      case DisclaimerType.warning:
        return const _DisclaimerStyle(
          label: 'ATTENZIONE',
          icon: Icons.warning_amber_outlined,
          color: AppColors.warning,
        );
      case DisclaimerType.legal:
        return const _DisclaimerStyle(
          label: 'AVVISO LEGALE',
          icon: Icons.gavel_outlined,
          color: AppColors.accent,
        );
      case DisclaimerType.ai:
        return const _DisclaimerStyle(
          label: 'GENERATO CON AI',
          icon: Icons.auto_awesome_outlined,
          color: AppColors.info,
        );
    }
  }
}
