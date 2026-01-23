import 'package:flutter/material.dart';

const _entryFeatures = [
  'Analisi automatica basata su OCR, metadati e regole proprietarie.',
  'Summary con rischio stimato (low/medium/high) e next step operativo.',
  'Bozza PEC/ricorso pronta: un colpo di schermo e hai il testo consigliato.',
  'Conserva lo storico delle analisi, copia il contenuto e riutilizza il contesto.',
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
          const _EntryBackground(),
          SafeArea(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _EntryHero(
                      onOpenAnalyzer: () => _openAnalyzer(context),
                    ),
                    const SizedBox(height: 34),
                    Text(
                      'Perché usarlo',
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _EntryFeatureList(features: _entryFeatures),
                    const SizedBox(height: 28),
                    const MonetizationCard(),
                    const SizedBox(height: 32),
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
  const _EntryHero({required this.onOpenAnalyzer});

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
            fontSize: 36,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Analizza notifiche, dossier di sanzioni e richieste amministrative con un solo flusso intelligente.',
          style: textTheme.bodyLarge?.copyWith(
            color: Colors.white70,
            height: 1.6,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: onOpenAnalyzer,
              icon: const Icon(Icons.hourglass_bottom),
              label: const Text('Apri Analyzer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: onOpenAnalyzer,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
              ),
              child: const Text('Mostra demo'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Monitora i report, chiudi i documenti e condividi lo status del rischio.',
          style: textTheme.bodyMedium?.copyWith(
            color: Colors.white60,
            fontSize: 14,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _EntryFeatureList extends StatelessWidget {
  const _EntryFeatureList({required this.features});

  final List<String> features;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle_outline,
                  size: 18, color: Colors.greenAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  feature,
                  style: textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                    height: 1.55,
                    letterSpacing: 0.3,
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

class MonetizationCard extends StatelessWidget {
  const MonetizationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F131B),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monetizzazione & store',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sblocca piani premium con report multipli, storage sicuro e alert prioritari via push.',
            style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          const _MonetizationRow(
            icon: Icons.lock_outline,
            text:
                'Abbonamento mensile o annuale con prova gratuita di 7 giorni.',
          ),
          const SizedBox(height: 10),
          const _MonetizationRow(
            icon: Icons.storefront,
            text:
                'Disponibile su App Store + Google Play con acquisti in-app per funzionalità avanzate.',
          ),
        ],
      ),
    );
  }
}

class _MonetizationRow extends StatelessWidget {
  const _MonetizationRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.greenAccent, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }
}

class _EntryBackground extends StatelessWidget {
  const _EntryBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0C121A),
            Color(0xFF05070C),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 40,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color.fromRGBO(255, 255, 255, 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x2669F0AE),
                    Colors.transparent,
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
