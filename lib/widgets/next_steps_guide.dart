import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A helpful guide showing users what to do after generating a document
class NextStepsGuide extends StatelessWidget {
  final DateTime fineDate;
  final String? recipientEmail;
  final VoidCallback? onNeedPecHelp;

  const NextStepsGuide({
    super.key,
    required this.fineDate,
    this.recipientEmail,
    this.onNeedPecHelp,
  });

  int get _daysRemaining {
    final deadline = fineDate.add(const Duration(days: 60));
    return deadline.difference(DateTime.now()).inDays;
  }

  bool get _isUrgent => _daysRemaining <= 7;
  bool get _isExpired => _daysRemaining < 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A2332),
            Color(0xFF0F1620),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isExpired
              ? Colors.red.withAlpha(100)
              : _isUrgent
                  ? Colors.orange.withAlpha(100)
                  : Colors.greenAccent.withAlpha(60),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _buildHeader(),

          // Deadline warning
          _buildDeadlineInfo(),

          // Steps
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _buildStep(
                  number: 1,
                  title: 'Verifica il testo',
                  description: 'Leggi attentamente la bozza e personalizzala con i tuoi dati. '
                      'Controlla che le informazioni siano corrette.',
                  icon: Icons.edit_note,
                ),
                _buildStep(
                  number: 2,
                  title: 'Trova il destinatario',
                  description: 'L\'indirizzo PEC a cui inviare si trova sul verbale della multa, '
                      'solitamente in alto o nel footer del documento.',
                  icon: Icons.search,
                  actionLabel: recipientEmail != null ? 'Copia indirizzo' : null,
                  onAction: recipientEmail != null
                      ? () {
                          // Copy to clipboard handled by parent
                        }
                      : null,
                ),
                _buildStep(
                  number: 3,
                  title: 'Invia tramite PEC',
                  description: 'La PEC (Posta Elettronica Certificata) ha valore legale. '
                      'Se non ne hai una, puoi attivarla online in pochi minuti.',
                  icon: Icons.mail_outline,
                  actionLabel: 'Non ho una PEC',
                  onAction: onNeedPecHelp,
                ),
                _buildStep(
                  number: 4,
                  title: 'Conserva la ricevuta',
                  description: 'Dopo l\'invio riceverai una ricevuta di accettazione e di consegna. '
                      'Salvale: sono la prova che hai inviato nei termini.',
                  icon: Icons.folder_copy_outlined,
                  isLast: true,
                ),
              ],
            ),
          ),

          // Alternative method
          _buildAlternativeMethod(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withAlpha(15),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.route_outlined,
              color: Colors.greenAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Come procedere',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Segui questi passaggi per inviare il ricorso',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineInfo() {
    final Color bgColor;
    final Color textColor;
    final IconData icon;
    final String message;

    if (_isExpired) {
      bgColor = Colors.red.withAlpha(20);
      textColor = Colors.redAccent;
      icon = Icons.warning_amber_rounded;
      message = 'Attenzione: i 60 giorni sono scaduti. '
          'Potresti non essere piu in tempo per il ricorso ordinario.';
    } else if (_isUrgent) {
      bgColor = Colors.orange.withAlpha(20);
      textColor = Colors.orange;
      icon = Icons.schedule;
      message = 'Hai ancora $_daysRemaining giorni per inviare il ricorso. '
          'Ti consigliamo di procedere il prima possibile.';
    } else {
      bgColor = Colors.blue.withAlpha(15);
      textColor = Colors.lightBlueAccent;
      icon = Icons.info_outline;
      message = 'Hai $_daysRemaining giorni di tempo per inviare il ricorso '
          '(entro 60 giorni dalla notifica).';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required int number,
    required String title,
    required String description,
    required IconData icon,
    String? actionLabel,
    VoidCallback? onAction,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Number and line
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.greenAccent.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: Colors.white12,
              ),
          ],
        ),
        const SizedBox(width: 14),
        // Content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                if (actionLabel != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onAction,
                    child: Text(
                      actionLabel,
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.greenAccent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlternativeMethod() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.local_post_office_outlined,
            color: Colors.white38,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: 'Alternativa: ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: 'Puoi anche inviare il ricorso tramite raccomandata A/R. '
                        'Fa fede la data di spedizione (timbro postale).',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog showing PEC provider options
class PecProvidersDialog extends StatelessWidget {
  const PecProvidersDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1F2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.mail_lock_outlined,
                    color: Colors.greenAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Attiva una PEC',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white54),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'La PEC costa pochi euro all\'anno e ti serve per comunicazioni ufficiali con la PA.',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _buildProvider(
              context,
              name: 'Aruba PEC',
              price: '\u20AC5/anno',
              url: 'https://www.pec.it',
              recommended: true,
            ),
            _buildProvider(
              context,
              name: 'Legalmail',
              price: '\u20AC6/anno',
              url: 'https://www.legalmail.it',
            ),
            _buildProvider(
              context,
              name: 'Register PEC',
              price: '\u20AC5/anno',
              url: 'https://www.register.it/pec/',
            ),
            const SizedBox(height: 16),
            const Text(
              'L\'attivazione richiede circa 10-15 minuti e un documento d\'identita.',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProvider(
    BuildContext context, {
    required String name,
    required String price,
    required String url,
    bool recommended = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: recommended
                  ? Colors.greenAccent.withAlpha(10)
                  : Colors.white.withAlpha(5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: recommended
                    ? Colors.greenAccent.withAlpha(50)
                    : Colors.white12,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (recommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withAlpha(30),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Consigliato',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        price,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.open_in_new,
                  color: Colors.white38,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
