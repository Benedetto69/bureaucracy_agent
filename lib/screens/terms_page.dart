import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1420),
        title: const Text('Termini di Servizio'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          const Text(
            'Utilizzando Bureaucracy Analyzer accetti i seguenti termini.',
            style: TextStyle(fontSize: 16, height: 1.6),
          ),
          const SizedBox(height: 18),
          const _SectionBullet(
            title: 'Servizio offerto',
            description:
                'L\'app analizza documenti burocratici e fornisce suggerimenti a scopo informativo. Non costituisce consulenza legale e non sostituisce il parere di un professionista.',
          ),
          const _SectionBullet(
            title: 'Abbonamenti Premium',
            description:
                'Gli abbonamenti si rinnovano automaticamente alla scadenza, salvo disdetta almeno 24 ore prima. Il pagamento viene addebitato sul tuo account iTunes.',
          ),
          const _SectionBullet(
            title: 'Gestione abbonamento',
            description:
                'Puoi gestire o cancellare il tuo abbonamento in qualsiasi momento dalle Impostazioni del dispositivo > [Il tuo nome] > Abbonamenti.',
          ),
          const _SectionBullet(
            title: 'Limitazione responsabilita\'',
            description:
                'Le informazioni fornite hanno scopo orientativo. Per questioni legali rilevanti consulta sempre un professionista qualificato.',
          ),
          const _SectionBullet(
            title: 'Utilizzo consentito',
            description:
                'Ti impegni a utilizzare l\'app solo per scopi leciti e a non tentare di aggirare le limitazioni tecniche.',
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.check, size: 20),
            label: const Text('Ho capito, torna all\'app'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8BFFB7),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionBullet extends StatelessWidget {
  const _SectionBullet({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: Colors.white70, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }
}
