import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/municipalities_database.dart';

/// Guida post-invio con checklist operativa per l'utente
class PostSubmissionGuide extends StatefulWidget {
  final String jurisdiction;
  final String fineNumber;
  final double amount;
  final DateTime notificationDate;
  final String documentType; // 'ricorso_prefetto', 'ricorso_gdp', 'autotutela'
  final VoidCallback? onComplete;

  const PostSubmissionGuide({
    required this.jurisdiction,
    required this.fineNumber,
    required this.amount,
    required this.notificationDate,
    this.documentType = 'ricorso_prefetto',
    this.onComplete,
    super.key,
  });

  @override
  State<PostSubmissionGuide> createState() => _PostSubmissionGuideState();
}

class _PostSubmissionGuideState extends State<PostSubmissionGuide> {
  final Set<String> _completedSteps = {};
  Municipality? _municipality;
  bool _isLoadingMunicipality = true;

  @override
  void initState() {
    super.initState();
    _loadMunicipality();
  }

  void _loadMunicipality() {
    final results = MunicipalitiesDatabase.search(widget.jurisdiction);
    setState(() {
      _municipality = results.isNotEmpty ? results.first : null;
      _isLoadingMunicipality = false;
    });
  }

  List<_GuideStep> get _steps {
    final isPrefetto = widget.documentType == 'ricorso_prefetto';
    final isGdP = widget.documentType == 'ricorso_gdp';

    return [
      _GuideStep(
        id: 'complete_document',
        title: 'Completa il documento',
        description: 'Compila tutti i campi tra parentesi quadre [...] con i tuoi dati reali',
        icon: Icons.edit_document,
        actions: [
          _StepAction(
            label: 'Rivedi bozza',
            icon: Icons.visibility,
            onTap: () => _showSnackbar('Torna alla bozza per modificarla'),
          ),
        ],
      ),
      _GuideStep(
        id: 'prepare_attachments',
        title: 'Prepara gli allegati',
        description: 'Documenti da allegare obbligatoriamente',
        icon: Icons.attach_file,
        checklistItems: [
          'Copia del verbale/multa',
          'Copia documento identità',
          'Copia codice fiscale',
          if (isGdP) 'Ricevuta contributo unificato (€43)',
          'Eventuali prove fotografiche',
        ],
      ),
      _GuideStep(
        id: 'find_pec',
        title: 'Trova la PEC del destinatario',
        description: _municipality != null
            ? 'PEC trovata per ${_municipality!.name}'
            : 'Cerca la PEC ufficiale del comune',
        icon: Icons.email,
        actions: [
          if (_municipality != null) ...[
            _StepAction(
              label: 'Copia PEC Polizia',
              icon: Icons.copy,
              onTap: () => _copyToClipboard(
                _municipality!.pecPoliziaMunicipale,
                'PEC Polizia Municipale copiata',
              ),
            ),
            if (isPrefetto)
              _StepAction(
                label: 'Copia PEC Prefettura',
                icon: Icons.copy,
                onTap: () => _copyToClipboard(
                  _municipality!.pecPrefettura,
                  'PEC Prefettura copiata',
                ),
              ),
          ],
          _StepAction(
            label: 'Cerca su IndicePA',
            icon: Icons.search,
            onTap: () => _launchUrl('https://indicepa.gov.it/ipa-portale/'),
          ),
        ],
        pecInfo: _municipality != null
            ? _PecInfo(
                poliziaMunicipale: _municipality!.pecPoliziaMunicipale,
                prefettura: _municipality!.pecPrefettura,
                protocollo: _municipality!.pecProtocollo,
              )
            : null,
      ),
      _GuideStep(
        id: 'send_pec',
        title: 'Invia tramite PEC',
        description: 'Usa la tua PEC personale o un servizio certificato',
        icon: Icons.send,
        checklistItems: [
          'Oggetto: "Ricorso avverso verbale n. ${widget.fineNumber}"',
          'Allega il documento PDF firmato',
          'Allega tutti i documenti richiesti',
          'Verifica che la PEC sia corretta',
          'Conserva la ricevuta di accettazione',
          'Conserva la ricevuta di consegna',
        ],
        actions: [
          _StepAction(
            label: 'Non hai una PEC?',
            icon: Icons.help_outline,
            onTap: () => _showPecProvidersDialog(),
          ),
        ],
      ),
      const _GuideStep(
        id: 'save_receipts',
        title: 'Salva le ricevute',
        description: 'Conserva le prove dell\'invio per almeno 5 anni',
        icon: Icons.folder,
        checklistItems: [
          'Screenshot/PDF della ricevuta di accettazione',
          'Screenshot/PDF della ricevuta di consegna',
          'Copia del documento inviato',
          'Data e ora esatta dell\'invio',
        ],
      ),
      _GuideStep(
        id: 'wait_response',
        title: 'Attendi la risposta',
        description: isPrefetto
            ? 'Il Prefetto ha 180 giorni per rispondere'
            : 'Il Giudice fisserà un\'udienza',
        icon: Icons.hourglass_empty,
        infoText: isPrefetto
            ? 'Se non ricevi risposta entro 180 giorni, il ricorso si considera accolto per silenzio-assenso.'
            : 'Riceverai una comunicazione con la data dell\'udienza. Preparati a presentarti o a delegare un avvocato.',
      ),
      _GuideStep(
        id: 'track_status',
        title: 'Monitora lo stato',
        description: 'Tieni traccia dell\'esito del ricorso',
        icon: Icons.track_changes,
        actions: [
          _StepAction(
            label: 'Segna come "In attesa"',
            icon: Icons.pending_actions,
            onTap: () => _showSnackbar('Stato aggiornato'),
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final completedCount = _completedSteps.length;
    final totalSteps = steps.length;
    final progress = totalSteps > 0 ? completedCount / totalSteps : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F1117), Color(0xFF0A0D12)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(progress, completedCount, totalSteps),
          if (_isLoadingMunicipality)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: steps.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildStepCard(steps[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(double progress, int completed, int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.checklist, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guida all\'invio',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Segui questi passaggi per completare l\'invio',
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(
                      progress == 1.0 ? Colors.green : Colors.blue,
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$completed/$total',
                style: TextStyle(
                  color: progress == 1.0 ? Colors.green : Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(_GuideStep step) {
    final isCompleted = _completedSteps.contains(step.id);

    return Container(
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green.withAlpha(15)
            : const Color(0xFF151922),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? Colors.green.withAlpha(60) : Colors.white10,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: GestureDetector(
            onTap: () => _toggleStep(step.id),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green
                    : step.icon == Icons.email
                        ? Colors.blue.withAlpha(30)
                        : Colors.white10,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isCompleted ? Icons.check : step.icon,
                color: isCompleted ? Colors.white : Colors.white70,
                size: 20,
              ),
            ),
          ),
          title: Text(
            step.title,
            style: TextStyle(
              color: isCompleted ? Colors.green.shade300 : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text(
            step.description,
            style: TextStyle(
              color: isCompleted ? Colors.green.shade200.withAlpha(150) : Colors.white54,
              fontSize: 12,
            ),
          ),
          trailing: Checkbox(
            value: isCompleted,
            onChanged: (_) => _toggleStep(step.id),
            activeColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          children: [
            if (step.checklistItems != null) ...[
              ...step.checklistItems!.map((item) => _buildChecklistItem(item)),
              const SizedBox(height: 12),
            ],
            if (step.pecInfo != null) ...[
              _buildPecInfoCard(step.pecInfo!),
              const SizedBox(height: 12),
            ],
            if (step.infoText != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.withAlpha(40)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        step.infoText!,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (step.actions != null && step.actions!.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: step.actions!.map(_buildActionButton).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(String item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.white38, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPecInfoCard(_PecInfo info) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified, color: Colors.green, size: 16),
              SizedBox(width: 6),
              Text(
                'Indirizzi PEC trovati',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildPecRow('Polizia Municipale', info.poliziaMunicipale),
          const SizedBox(height: 6),
          _buildPecRow('Prefettura', info.prefettura),
          const SizedBox(height: 6),
          _buildPecRow('Protocollo Comune', info.protocollo),
        ],
      ),
    );
  }

  Widget _buildPecRow(String label, String pec) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => _copyToClipboard(pec, '$label copiata'),
            child: Text(
              pec,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                decoration: TextDecoration.underline,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        IconButton(
          onPressed: () => _copyToClipboard(pec, '$label copiata'),
          icon: const Icon(Icons.copy, size: 14, color: Colors.white38),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        ),
      ],
    );
  }

  Widget _buildActionButton(_StepAction action) {
    return OutlinedButton.icon(
      onPressed: action.onTap,
      icon: Icon(action.icon, size: 16),
      label: Text(action.label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white70,
        side: const BorderSide(color: Colors.white24),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _toggleStep(String stepId) {
    setState(() {
      if (_completedSteps.contains(stepId)) {
        _completedSteps.remove(stepId);
      } else {
        _completedSteps.add(stepId);
      }
    });

    if (_completedSteps.length == _steps.length) {
      widget.onComplete?.call();
    }
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackbar(message);
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showPecProvidersDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1117),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Come ottenere una PEC',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Per inviare un ricorso via PEC hai bisogno di una casella di Posta Elettronica Certificata. '
                'Ecco alcuni provider:',
                style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              _buildProviderTile('Aruba PEC', 'Da €5/anno', 'https://www.pec.it'),
              _buildProviderTile('Register PEC', 'Da €5.50/anno', 'https://www.register.it/pec/'),
              _buildProviderTile('Legalmail', 'Da €6/anno', 'https://www.legalmail.it'),
              _buildProviderTile('Poste Italiane', 'Da €5.50/anno', 'https://postecert.poste.it'),
              const SizedBox(height: 12),
              const Text(
                'Alternativa: puoi inviare il ricorso tramite raccomandata A/R.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderTile(String name, String price, String url) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(name, style: const TextStyle(color: Colors.white)),
      subtitle: Text(price, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      trailing: TextButton(
        onPressed: () => _launchUrl(url),
        child: const Text('Visita'),
      ),
    );
  }
}

class _GuideStep {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final List<String>? checklistItems;
  final List<_StepAction>? actions;
  final _PecInfo? pecInfo;
  final String? infoText;

  const _GuideStep({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.checklistItems,
    this.actions,
    this.pecInfo,
    this.infoText,
  });
}

class _StepAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _StepAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class _PecInfo {
  final String poliziaMunicipale;
  final String prefettura;
  final String protocollo;

  const _PecInfo({
    required this.poliziaMunicipale,
    required this.prefettura,
    required this.protocollo,
  });
}
