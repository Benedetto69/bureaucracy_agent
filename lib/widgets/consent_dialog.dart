import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Dialog per ottenere il consenso informato prima dell'analisi
class ConsentDialog extends StatefulWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const ConsentDialog({
    super.key,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<ConsentDialog> createState() => _ConsentDialogState();
}

class _ConsentDialogState extends State<ConsentDialog> {
  bool _hasReadInfo = false;
  bool _acceptsDataProcessing = false;

  bool get _canProceed => _hasReadInfo && _acceptsDataProcessing;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.info.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.privacy_tip_outlined,
                      color: AppColors.info,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prima di analizzare',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Informativa sul trattamento dati',
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
              const SizedBox(height: 20),

              // Info box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.surfaceLight),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      icon: Icons.upload_outlined,
                      title: 'Cosa inviamo',
                      description:
                          'Il testo della multa e i metadati che hai inserito (importo, data, giurisdizione).',
                    ),
                    SizedBox(height: 14),
                    _InfoRow(
                      icon: Icons.timer_outlined,
                      title: 'Per quanto tempo',
                      description:
                          'I dati vengono elaborati e cancellati entro 24 ore dai nostri server.',
                    ),
                    SizedBox(height: 14),
                    _InfoRow(
                      icon: Icons.photo_outlined,
                      title: 'Le immagini',
                      description:
                          'Le foto restano sul tuo telefono. Non le carichiamo sui server.',
                    ),
                    SizedBox(height: 14),
                    _InfoRow(
                      icon: Icons.gavel_outlined,
                      title: 'Nota importante',
                      description:
                          'L\'analisi e\' indicativa e non costituisce consulenza legale.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Checkboxes
              _ConsentCheckbox(
                value: _hasReadInfo,
                onChanged: (v) => setState(() => _hasReadInfo = v ?? false),
                label: 'Ho letto e compreso le informazioni sopra',
              ),
              const SizedBox(height: 10),
              _ConsentCheckbox(
                value: _acceptsDataProcessing,
                onChanged: (v) =>
                    setState(() => _acceptsDataProcessing = v ?? false),
                label: 'Acconsento al trattamento dei dati per l\'analisi',
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onDecline,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.surfaceElevated),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Annulla'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _canProceed ? widget.onAccept : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _canProceed ? AppColors.primary : AppColors.surface,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: AppColors.surface,
                        disabledForegroundColor: AppColors.textDisabled,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _canProceed
                                ? Icons.check_circle_outline
                                : Icons.lock_outline,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text('Procedi con l\'analisi'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConsentCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;

  const _ConsentCheckbox({
    required this.value,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primary,
                checkColor: Colors.black,
                side: BorderSide(
                  color: value ? AppColors.primary : AppColors.textTertiary,
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: value ? AppColors.textPrimary : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: value ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
