import 'package:flutter/material.dart';

const _entryFeatures = [
  'Analisi guidata su testo e metadati (OCR on-device su iOS).',
  'Summary con rischio stimato e prossimo step operativo.',
  'Bozza di risposta pronta da copiare e rifinire.',
  'Storico locale delle analisi per riuso rapido.',
];

const _trustHighlights = [
  'I dati vengono inviati al server solo per l’analisi richiesta.',
  'La cronologia resta salvata localmente sul dispositivo.',
  'Nessun account obbligatorio per usare l’app.',
];

const _riskStatuses = [
  _StatusData(
    label: 'Attesa',
    status: 'Strategia in attesa',
    description:
        'La macchina valuta il rischio e prepara il prossimo step operativo.',
    accent: Color(0xFF6EC79C),
  ),
  _StatusData(
    label: 'Analisi',
    status: 'Testo + metadati',
    description:
        'Testo e parametri vengono incrociati con regole di analisi.',
    accent: Color(0xFFE2C965),
  ),
  _StatusData(
    label: 'Action',
    status: 'Bozza pronta',
    description: 'PEC o ricorso da inviare con poche modifiche manuali.',
    accent: Color(0xFF33A2FF),
  ),
];

const _pricingCopy =
    'Piano gratuito con limite giornaliero; il premium sblocca analisi illimitate. Eventuali prove gratuite vengono mostrate al checkout.';

const _monetizationDetails = [
  _MonetizationDetail(
    icon: Icons.all_inclusive,
    title: 'Analisi illimitate',
    body: 'Rimuovi il limite giornaliero del piano gratuito.',
  ),
  _MonetizationDetail(
    icon: Icons.history,
    title: 'Storico locale completo',
    body: 'Rivedi e riusa le bozze generate.',
  ),
];

class EntryPage extends StatelessWidget {
  const EntryPage({super.key});

  void _openAnalyzer(BuildContext context) {
    Navigator.of(context).pushNamed('/analyzer');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const _EntryBackground(key: ValueKey('entry_background')),
          SafeArea(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _EntryHero(
                        key: const ValueKey('entry_hero'),
                        onOpenAnalyzer: () => _openAnalyzer(context)),
                    const SizedBox(height: 36),
                    SectionTitle(
                      key: const ValueKey('section_perche'),
                      label: 'Perché usarlo',
                      textTheme: textTheme,
                    ),
                    const SizedBox(height: 12),
                    const _EntryFeatureList(
                      key: ValueKey('entry_features'),
                      features: _entryFeatures,
                    ),
                    const SizedBox(height: 32),
                    SectionTitle(
                      key: const ValueKey('section_dati'),
                      label: 'Come proteggiamo i tuoi dati',
                      textTheme: textTheme,
                    ),
                    const SizedBox(height: 12),
                    const _EntryFeatureList(
                      key: ValueKey('trust_highlights'),
                      features: _trustHighlights,
                      icon: Icons.shield_outlined,
                    ),
                    const SizedBox(height: 32),
                    SectionTitle(
                      key: const ValueKey('section_stato'),
                      label: 'Stato del cervello',
                      textTheme: textTheme,
                    ),
                    const SizedBox(height: 18),
                    const _StatusBoard(
                      key: ValueKey('status_board'),
                      statuses: _riskStatuses,
                    ),
                    const SizedBox(height: 32),
                    const MonetizationCard(key: ValueKey('monetization_card')),
                    const SizedBox(height: 12),
                    const PrivacyDisclosureLink(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryHero extends StatelessWidget {
  const _EntryHero({super.key, required this.onOpenAnalyzer});

  final VoidCallback onOpenAnalyzer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bureaucracy',
          style: textTheme.displayLarge?.copyWith(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Analizza notifiche, dossier di sanzioni e richieste amministrative con un solo flusso intelligente.',
          style: textTheme.bodyLarge?.copyWith(
            color: Colors.white70,
            height: 1.8,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 26),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: onOpenAnalyzer,
              icon: const Icon(Icons.hourglass_bottom, size: 20),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('Apri Analyzer',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8BFFB7),
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: 6,
                shadowColor: Colors.black45,
              ),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: () => _showDemoInfo(context),
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
              child: const Text('Mostra demo'),
            )
          ],
        ),
        const SizedBox(height: 18),
        const Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            _AppBadge(
                key: ValueKey('badge_app_store'),
                icon: Icons.apple,
                label: 'App Store Ready'),
          ],
        ),
      ],
    );
  }

  void _showDemoInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF10151F),
        title: const Text('Demo protetto', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Mostra demo disponibile solo durante presentazioni live. Contatta il team per ricevere accesso temporaneo.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.greenAccent),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.label, required this.textTheme});

  final String label;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: textTheme.titleMedium?.copyWith(
        color: _withOpacity(Colors.white, 0.85),
        letterSpacing: 0.8,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _EntryFeatureList extends StatelessWidget {
  const _EntryFeatureList({
    super.key,
    required this.features,
    this.icon = Icons.check_circle_outline,
  });

  final List<String> features;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: Colors.greenAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  feature,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    height: 1.6,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StatusBoard extends StatelessWidget {
  const _StatusBoard({super.key, required this.statuses});

  final List<_StatusData> statuses;

  @override
  Widget build(BuildContext context) {
    final baseBorder = BorderRadius.circular(24);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1420),
        borderRadius: baseBorder,
        border: Border.all(color: Colors.white10),
        boxShadow: const [
          BoxShadow(
              color: Colors.black26, blurRadius: 18, offset: Offset(0, 12)),
        ],
      ),
      child: Column(
        children: List.generate(statuses.length, (index) {
          final status = statuses[index];
          return Padding(
            padding:
                EdgeInsets.only(bottom: index == statuses.length - 1 ? 0 : 14),
            child: _StatusIndicator(
              key: ValueKey('status_${status.label}'),
              data: status,
            ),
          );
        }),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({super.key, required this.data});

  final _StatusData data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_withOpacity(data.accent, 0.1), const Color(0xFF0B111B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _withOpacity(data.accent, 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.label,
            style: textTheme.titleSmall?.copyWith(
                color: data.accent,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            data.status,
            style: textTheme.bodyMedium?.copyWith(
                color: Colors.white, fontWeight: FontWeight.w600, height: 1.4),
          ),
          const SizedBox(height: 8),
          Text(
            data.description,
            style: textTheme.bodySmall?.copyWith(
                color: Colors.white70, height: 1.5, letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }
}

class _AppBadge extends StatelessWidget {
  const _AppBadge({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.white70, letterSpacing: 0.4),
          ),
        ],
      ),
    );
  }
}

class _StatusData {
  const _StatusData({
    required this.label,
    required this.status,
    required this.description,
    required this.accent,
  });

  final String label;
  final String status;
  final String description;
  final Color accent;
}

class _MonetizationDetail {
  const _MonetizationDetail(
      {required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;
}

class MonetizationCard extends StatelessWidget {
  const MonetizationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x2011323D), Color(0xFF050B14)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
        boxShadow: const [
          BoxShadow(
              color: Colors.black38, blurRadius: 18, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monetizzazione & store',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Sblocca analisi illimitate e rimuovi il limite giornaliero gratuito.',
            style: textTheme.bodyMedium
                ?.copyWith(color: Colors.white70, height: 1.6),
          ),
          const SizedBox(height: 8),
          Text(
            _pricingCopy,
            style: textTheme.bodySmall?.copyWith(
              color: Colors.white60,
              height: 1.5,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 18),
          Column(
            children: _monetizationDetails
                .map((detail) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        children: [
                          Icon(detail.icon,
                              color: Colors.greenAccent, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  detail.title,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  detail.body,
                                  style: textTheme.bodySmall?.copyWith(
                                      color: Colors.white70, height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class PrivacyDisclosureLink extends StatelessWidget {
  const PrivacyDisclosureLink({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => Navigator.of(context).pushNamed('/privacy'),
      icon: const Icon(
        Icons.privacy_tip_outlined,
        color: Colors.white70,
        size: 20,
      ),
      label: const Text(
        'Privacy & sicurezza',
        style: TextStyle(color: Colors.white70, letterSpacing: 0.4),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        alignment: Alignment.centerLeft,
      ),
    );
  }
}

Color _withOpacity(Color color, double opacity) {
  final alpha = (opacity * 255).round();
  if (alpha <= 0) return color.withAlpha(0);
  if (alpha >= 255) return color.withAlpha(255);
  return color.withAlpha(alpha);
}

class _EntryBackground extends StatelessWidget {
  const _EntryBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF090F16), Color(0xFF050609)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 16,
            right: 32,
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(120),
                gradient: const RadialGradient(
                  colors: [Color(0x26FFFFFF), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -30,
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(140),
                gradient: const RadialGradient(
                  colors: [Color(0x4C69F0AE), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
