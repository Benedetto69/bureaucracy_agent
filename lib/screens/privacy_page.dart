import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1420),
        title: const Text('Privacy e sicurezza'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          const Text(
            'Bureaucracy Agent tratta i dati solo per offrirti analisi e bozze operative.',
            style: TextStyle(fontSize: 16, height: 1.6),
          ),
          const SizedBox(height: 18),
          const _SectionBullet(
            title: 'Dati trattati',
            description:
                'I dati inseriti (testo e metadati) vengono inviati al nostro server solo per generare l’analisi e la bozza richiesta. Non vengono condivisi con terze parti.',
          ),
          const _SectionBullet(
            title: 'Permessi richiesti',
            description:
                'Camera e libreria vengono usate esclusivamente per raccogliere documenti di riferimento; le descrizioni `NSCameraUsageDescription` e `NSPhotoLibraryUsageDescription` spiegano il motivo all’utente.',
          ),
          const _SectionBullet(
            title: 'Storage e cronologia',
            description:
                'Le bozze e lo storico vengono salvati localmente sul dispositivo. Puoi eliminarli rimuovendo l’app.',
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.check, size: 20),
            label: const Text('Ho capito, torna all’app'),
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
