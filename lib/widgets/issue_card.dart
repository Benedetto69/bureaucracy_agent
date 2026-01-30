import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/document_analyzer_models.dart';
import '../theme/app_theme.dart';

class IssueCard extends StatelessWidget {
  final AnalysisIssue issue;
  final VoidCallback? onGenerateDocument;

  const IssueCard({
    super.key,
    required this.issue,
    this.onGenerateDocument,
  });

  @override
  Widget build(BuildContext context) {
    final typeConfig = _getTypeConfig(issue.type);
    final confidencePercent = (issue.confidence * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          color: typeConfig.color.withAlpha(40),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with type badge and confidence
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: typeConfig.color.withAlpha(15),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Row(
              children: [
                _TypeBadge(
                  label: typeConfig.label,
                  icon: typeConfig.icon,
                  color: typeConfig.color,
                ),
                const Spacer(),
                _ConfidenceBadge(
                  percent: confidencePercent,
                  color: typeConfig.color,
                ),
              ],
            ),
          ),
          // Issue description
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(
              issue.issue,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
          // References
          if (issue.references.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bookmark_outline, size: 14, color: AppColors.textTertiary),
                      SizedBox(width: 6),
                      Text(
                        'Riferimenti normativi',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: issue.references.map((ref) {
                      return _ReferenceChip(reference: ref);
                    }).toList(),
                  ),
                ],
              ),
            ),
          // Actions section
          if (issue.actions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.checklist_outlined, size: 14, color: AppColors.textTertiary),
                      SizedBox(width: 6),
                      Text(
                        'Azioni consigliate',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...issue.actions.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.copy_outlined,
                    label: 'Copia',
                    onTap: () => _copyToClipboard(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _ActionButton(
                    icon: Icons.edit_document,
                    label: 'Genera bozza',
                    isPrimary: true,
                    onTap: onGenerateDocument ?? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Usa il bottone "Genera bozza PEC/Ricorso" sopra'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    final buffer = StringBuffer();
    buffer.writeln('PROBLEMA: ${issue.type.name.toUpperCase()}');
    buffer.writeln(issue.issue);
    buffer.writeln();
    buffer.writeln('AZIONI CONSIGLIATE:');
    for (var i = 0; i < issue.actions.length; i++) {
      buffer.writeln('${i + 1}. ${issue.actions[i]}');
    }
    if (issue.references.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('RIFERIMENTI:');
      for (final ref in issue.references) {
        buffer.writeln('- ${ref.citation} (${ref.source.name})');
      }
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.primary, size: 20),
            SizedBox(width: 12),
            Text('Copiato negli appunti'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  _IssueTypeConfig _getTypeConfig(IssueType type) {
    switch (type) {
      case IssueType.process:
        return const _IssueTypeConfig(
          label: 'Procedura',
          icon: Icons.timeline_outlined,
          color: AppColors.info,
        );
      case IssueType.formality:
        return const _IssueTypeConfig(
          label: 'Formalita',
          icon: Icons.description_outlined,
          color: AppColors.warning,
        );
      case IssueType.substance:
        return const _IssueTypeConfig(
          label: 'Sostanza',
          icon: Icons.gavel_outlined,
          color: AppColors.error,
        );
    }
  }
}

class _IssueTypeConfig {
  final String label;
  final IconData icon;
  final Color color;

  const _IssueTypeConfig({
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _TypeBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _TypeBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final int percent;
  final Color color;

  const _ConfidenceBadge({
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insights, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$percent%',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceChip extends StatelessWidget {
  final Reference reference;

  const _ReferenceChip({required this.reference});

  @override
  Widget build(BuildContext context) {
    final sourceConfig = _getSourceConfig(reference.source);

    return InkWell(
      onTap: () => _openUrl(reference.url),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: sourceConfig.color.withAlpha(15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: sourceConfig.color.withAlpha(40)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(sourceConfig.icon, size: 12, color: sourceConfig.color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                reference.citation,
                style: TextStyle(
                  color: sourceConfig.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.open_in_new, size: 10, color: sourceConfig.color.withAlpha(150)),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  _SourceConfig _getSourceConfig(ReferenceSource source) {
    switch (source) {
      case ReferenceSource.norma:
        return const _SourceConfig(
          icon: Icons.account_balance_outlined,
          color: AppColors.info,
        );
      case ReferenceSource.giurisprudenza:
        return const _SourceConfig(
          icon: Icons.gavel_outlined,
          color: AppColors.accent,
        );
      case ReferenceSource.policy:
        return const _SourceConfig(
          icon: Icons.policy_outlined,
          color: AppColors.warning,
        );
    }
  }
}

class _SourceConfig {
  final IconData icon;
  final Color color;

  const _SourceConfig({required this.icon, required this.color});
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: isPrimary ? null : Border.all(color: AppColors.surfaceElevated),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isPrimary ? Colors.black : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.black : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
