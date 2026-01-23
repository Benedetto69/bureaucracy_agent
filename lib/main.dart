import 'dart:io';

import 'package:bureaucracy_agent/models/document_history.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bureaucracy_agent/screens/entry_page.dart';
import 'package:bureaucracy_agent/services/api_service.dart';
import 'package:bureaucracy_agent/theme/app_theme.dart';
import 'package:bureaucracy_agent/services/history_storage.dart';
import 'package:bureaucracy_agent/services/subscription_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const BureaucracyAgentApp());
}

class BureaucracyAgentApp extends StatelessWidget {
  const BureaucracyAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bureaucracy',
      theme: AppTheme.build(),
      home: const EntryPage(),
      routes: {
        '/analyzer': (_) => const SchermataRisoluzione(),
      },
    );
  }
}

class SchermataRisoluzione extends StatefulWidget {
  const SchermataRisoluzione({super.key});

  @override
  State<SchermataRisoluzione> createState() => _SchermataRisoluzioneState();
}

class _SchermataRisoluzioneState extends State<SchermataRisoluzione> {
  final DocumentAnalyzerApi _api = DocumentAnalyzerApi();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _userIdController =
      TextEditingController(text: 'cliente-000');
  final TextEditingController _jurisdictionController =
      TextEditingController(text: 'Milano');
  final TextEditingController _amountController =
      TextEditingController(text: '500');
  DateTime _issueDate = DateTime.now();
  String _esitoIA = "Inserisci i dettagli della multa e attiva il cervello.";
  String? _errorMessage;
  bool _isLoading = false;
  bool _isGeneratingDocument = false;
  List<AnalysisIssue> _issues = [];
  Summary? _summary;
  String? _serverTime;
  String? _lastPayloadId;
  File? _pickedImage;
  String? _ocrText;
  bool _isProcessingImage = false;
  final ImagePicker _picker = ImagePicker();
  final List<DocumentHistoryEntry> _documentHistory = [];
  DocumentHistoryStorage? _historyStorage;
  SubscriptionService? _subscriptionService;
  SubscriptionStatus? _subscriptionStatus;
  bool _pushAlertsEnabled = true;
  bool _emailAlertsEnabled = false;

  @override
  void initState() {
    super.initState();
    _initializeHistory();
    _initializeSubscription();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _userIdController.dispose();
    _jurisdictionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _initializeHistory() async {
    try {
      final storage = await DocumentHistoryStorage.create();
      final loaded = await storage.loadHistory();
      if (!mounted) return;
      setState(() {
        _historyStorage = storage;
        _documentHistory
          ..clear()
          ..addAll(loaded);
      });
    } catch (error) {
      debugPrint('Impossibile caricare la cronologia: $error');
    }
  }

  Future<void> _initializeSubscription() async {
    try {
      final service = await SubscriptionService.create();
      final status = service.loadStatus();
      if (!mounted) return;
      setState(() {
        _subscriptionService = service;
        _subscriptionStatus = status;
      });
    } catch (error) {
      debugPrint('Impossibile inizializzare l’abbonamento: $error');
    }
  }

  Future<void> _avviaAnalisi() async {
    final description = _descriptionController.text.trim();
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (description.isEmpty) {
      setState(() => _errorMessage = 'Descrivi il caso prima di inviare.');
      return;
    }

    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Inserisci un importo valido (> 0).');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _esitoIA = "L'algoritmo sta interrogando il cervello...";
    });

    final payload = AnalyzePayload(
      documentId: DateTime.now().millisecondsSinceEpoch.toString(),
      source: SourceType.ocr,
      metadata: Metadata(
        userId: _userIdController.text.trim(),
        issueDate: _issueDate,
        amount: amount,
        jurisdiction: _jurisdictionController.text.trim(),
      ),
      alertPreferences: AlertPreferences(
        pushNotifications: _pushAlertsEnabled,
        emailSummaries: _emailAlertsEnabled,
      ),
      text: description,
    );

    try {
      final response = await _api.analyzeDocument(payload);
      setState(() {
        _issues = response.results;
        _summary = response.summary;
        _serverTime = response.serverTime
            .toLocal()
            .toIso8601String()
            .replaceFirst('T', ' ');
        _esitoIA = response.summary.nextStep;
        _lastPayloadId = payload.documentId;
      });
    } on ApiException catch (error) {
      setState(() {
        _errorMessage =
            'Errore ${error.statusCode ?? ''}: ${error.message}'.trim();
        _issues = [];
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Impossibile contattare il cervello: $error';
        _issues = [];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDocument(ImageSource source) async {
    try {
      final XFile? file =
          await _picker.pickImage(source: source, imageQuality: 75);
      if (file == null) return;
      setState(() {
        _isProcessingImage = true;
        _pickedImage = File(file.path);
        _errorMessage = null;
      });
      final extracted = await _runTextRecognition(file);
      setState(() {
        _ocrText = extracted;
        if (extracted.isNotEmpty) {
          _descriptionController.text = extracted;
        }
      });
    } catch (error) {
      setState(() => _errorMessage = 'OCR fallita: $error');
    } finally {
      setState(() => _isProcessingImage = false);
    }
  }

  Future<String> _runTextRecognition(XFile file) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final fileName = file.name;
    return 'Simulazione OCR per $fileName: rilevati importo e termine.';
  }

  Future<void> _scegliData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _issueDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2032),
      helpText: 'Data della notificazione',
    );
    if (picked != null) {
      setState(() => _issueDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Bureaucracy · Analyzer'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF070B10),
              Color(0xFF05070C),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionTitle('Descrizione del caso'),
                const SizedBox(height: 8),
                _buildDescriptionField(),
                const SizedBox(height: 24),
                _sectionTitle('Metadata minimali'),
                const SizedBox(height: 8),
                _buildMetadataInputs(),
                const SizedBox(height: 18),
                _buildDateRow(),
                const SizedBox(height: 24),
                _buildDocumentScanner(),
                const SizedBox(height: 28),
                Center(child: _buildAnalyzeButton()),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 20),
                  _buildErrorBanner(),
                ],
                const SizedBox(height: 20),
                _buildSummarySection(),
                const SizedBox(height: 16),
                _buildRiskStats(),
                const SizedBox(height: 18),
                _buildPremiumPerksCard(),
                const SizedBox(height: 16),
                _buildAlertSettings(),
                const SizedBox(height: 16),
                _buildPremiumCta(),
                const SizedBox(height: 18),
                _buildDocumentActions(),
                const SizedBox(height: 18),
                ..._issues.map((issue) => _buildIssueCard(issue)),
                if (_documentHistory.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  _sectionTitle('Storico bozze generate', compact: true),
                  const SizedBox(height: 12),
                  _buildDocumentHistory(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIssueCard(AnalysisIssue issue) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '[${issue.type.name.toUpperCase()}] ${issue.issue}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: issue.references.map((ref) {
                return Tooltip(
                  message: ref.url.toString(),
                  child: Chip(
                    label: Text(
                      '${ref.citation} (${ref.source.name.toUpperCase()})',
                      overflow: TextOverflow.ellipsis,
                    ),
                    backgroundColor: Colors.blueGrey.shade800,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text('Azioni consigliate:',
                style: TextStyle(color: Colors.grey[300])),
            ...issue.actions.map((action) => Row(
                  children: [
                    const Icon(Icons.chevron_right,
                        size: 20, color: Colors.greenAccent),
                    Expanded(
                      child: Text(
                        action,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String label, {bool compact = false}) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.white70,
        fontWeight: FontWeight.bold,
        letterSpacing: compact ? 0.6 : 0.4,
        fontSize: compact ? 14 : 16,
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionController,
      maxLines: 5,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF121519),
        hintText:
            'Racconta testo della multa, clausole sospette o ritardi nella notifica.',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildMetadataInputs() {
    return Column(
      children: [
        TextField(
          controller: _userIdController,
          decoration: InputDecoration(
            labelText: 'Client ID',
            filled: true,
            fillColor: const Color(0xFF121519),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _jurisdictionController,
                decoration: InputDecoration(
                  labelText: 'Giurisdizione',
                  filled: true,
                  fillColor: const Color(0xFF121519),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Importo contestato',
                  filled: true,
                  fillColor: const Color(0xFF121519),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Data di notifica',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
        TextButton(
          onPressed: _scegliData,
          style: TextButton.styleFrom(
            foregroundColor: Colors.greenAccent,
          ),
          child: Text(
            _issueDate.toIso8601String().split('T').first,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzeButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _avviaAnalisi,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.greenAccent,
        foregroundColor: Colors.black,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text(
              'AVVIA ANALISI DEL CERVELLO',
              style: TextStyle(letterSpacing: 1),
            ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(244, 67, 54, 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.redAccent.withAlpha(80)),
      ),
      child: Text(
        _errorMessage!,
        style: const TextStyle(color: Colors.redAccent),
      ),
    );
  }

  Widget _buildSummarySection() {
    final riskLevel = _summary?.riskLevel;
    final riskLabel = riskLevel?.name.toUpperCase() ?? 'STRATEGIA IN ATTESA';
    final nextStep = _summary?.nextStep ?? _esitoIA;
    final serverTimeLabel =
        _serverTime != null ? 'Aggiornato ${_serverTime!}' : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF141B2A),
            Color(0xFF0E121A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 14,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildRiskBadge(riskLevel),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rischio stimato: $riskLabel',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (serverTimeLabel != null)
                      Text(
                        serverTimeLabel,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            nextStep,
            style: const TextStyle(fontSize: 16, color: Colors.greenAccent),
          ),
          const SizedBox(height: 16),
          _buildMetadataChips(),
        ],
      ),
    );
  }

  Widget _buildRiskStats() {
    final stats = _calculateRiskStats();
    if (stats.isEmpty) {
      return const SizedBox();
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: stats
          .map(
            (stat) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF10131A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(stat.icon, color: stat.color, size: 20),
                  const SizedBox(height: 6),
                  Text(
                    stat.label,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stat.value.toString(),
                    style: TextStyle(
                      color: stat.color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  List<_RiskStat> _calculateRiskStats() {
    final counts = <IssueType, int>{};
    for (final issue in _issues) {
      counts.update(issue.type, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts.entries
        .map((entry) => _RiskStat(
              label: entry.key.name.toUpperCase(),
              value: entry.value,
              color: _riskColor(_mapIssueTypeToRisk(entry.key)),
              icon: _mapIssueTypeToIcon(entry.key),
            ))
        .toList();
  }

  RiskLevel _mapIssueTypeToRisk(IssueType type) {
    switch (type) {
      case IssueType.substance:
        return RiskLevel.high;
      case IssueType.process:
        return RiskLevel.medium;
      case IssueType.formality:
        return RiskLevel.low;
    }
  }

  IconData _mapIssueTypeToIcon(IssueType type) {
    switch (type) {
      case IssueType.process:
        return Icons.calendar_month;
      case IssueType.formality:
        return Icons.document_scanner;
      case IssueType.substance:
        return Icons.gavel;
    }
  }

  Widget _buildPremiumPerksCard() {
    const perks = [
      'Report illimitati con storico cifrato',
      'Alert prioritari su push + email',
      'Generazione automatica di PEC/ricorsi',
      'Supporto dedicato + revisione legale',
    ];
    final status =
        _subscriptionStatus ?? const SubscriptionStatus(state: SubscriptionState.free);
    final isActive = status.isActive;
    final actionLabel = isActive
        ? 'Premium attivo'
        : status.state == SubscriptionState.trial
            ? 'Passa a premium'
            : 'Inizia la prova gratuita';
    final action = isActive
        ? null
        : (status.state == SubscriptionState.trial ? _subscribePremium : _startTrial);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF111922),
            Color(0xFF050709),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color.fromRGBO(105, 240, 174, 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.workspace_premium, color: Colors.greenAccent),
              SizedBox(width: 10),
              Text(
                'Premium task force',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            status.label,
            style: const TextStyle(color: Colors.greenAccent, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ...perks.map(_buildBenefitRow),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: action,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  action == null ? Colors.greenAccent.withAlpha((0.6 * 255).round()) : Colors.greenAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(action == null ? 'Premium attivo' : actionLabel),
          ),
          if (!isActive)
            TextButton(
              onPressed: _subscribePremium,
              style: TextButton.styleFrom(foregroundColor: Colors.greenAccent),
              child: const Text('Mostra piani e prezzi'),
            ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentActions() {
    final hasIssues = _issues.isNotEmpty;
    final ready = hasIssues && !_isGeneratingDocument;
    return ElevatedButton.icon(
      onPressed: ready ? _generaDocumento : null,
      icon: _isGeneratingDocument
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.description_outlined),
      label: const Text('Genera bozza PEC/Ricorso'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.greenAccent,
        foregroundColor: Colors.black,
      ),
    );
  }

  Widget _buildPremiumCta() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F131A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.greenAccent.withAlpha(140)),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_border, color: Colors.greenAccent),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Sblocca analisi illimitate, alert prioritari e storage sicuro.',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Aggiorna'),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F131A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alert prioritari',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ricevi notifiche push o email quando aumenta il rischio o arriva una nuova issue.',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Push priority alert'),
            subtitle: const Text('Vibrazione e badge subito sul device'),
            value: _pushAlertsEnabled,
            activeThumbColor: Colors.greenAccent,
            activeTrackColor: Colors.greenAccent,
            onChanged: (value) => _applyAlertToggle(value, true),
          ),
          SwitchListTile(
            title: const Text('Email summary giornaliero'),
            subtitle: const Text('Report automatico con next steps'),
            value: _emailAlertsEnabled,
            activeThumbColor: Colors.greenAccent,
            activeTrackColor: Colors.greenAccent,
            onChanged: (value) => _applyAlertToggle(value, false),
          ),
        ],
      ),
    );
  }

  void _applyAlertToggle(bool value, bool push) {
    setState(() {
      if (push) {
        _pushAlertsEnabled = value;
      } else {
        _emailAlertsEnabled = value;
      }
    });
    final label = push ? 'Push alert' : 'Email summary';
    final status = value ? 'attivato' : 'disattivato';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label $status'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _startTrial() async {
    final service = _subscriptionService;
    if (service == null) return;
    await service.startTrial();
    await _reloadSubscriptionStatus('Prova gratuita attivata: 7 giorni');
  }

  Future<void> _subscribePremium() async {
    final service = _subscriptionService;
    if (service == null) return;
    await service.subscribe();
    await _reloadSubscriptionStatus('Abbonamento premium attivo');
  }

  Future<void> _reloadSubscriptionStatus(String message) async {
    final service = _subscriptionService;
    if (service == null) return;
    final status = service.loadStatus();
    if (!mounted) return;
    setState(() => _subscriptionStatus = status);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _generaDocumento() async {
    if (_issues.isEmpty) return;
    setState(() => _isGeneratingDocument = true);
    final issue = _issues.first;
    final documentId =
        _lastPayloadId ?? DateTime.now().millisecondsSinceEpoch.toString();
    final request = DocumentRequest(
      documentId: documentId,
      userId: _userIdController.text.trim(),
      issueType: issue.type,
      actions: issue.actions,
      references: issue.references,
      summaryNextStep: _summary?.nextStep ?? _esitoIA,
    );
    try {
      final document = await _api.generateDocument(request);
      await _showDocumentModal(document);
    } on ApiException catch (error) {
      setState(() {
        _errorMessage = 'Errore generazione documento: ${error.message}';
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Impossibile generare il documento: $error';
      });
    } finally {
      setState(() => _isGeneratingDocument = false);
    }
  }

  Future<void> _showDocumentModal(DocumentResponse document) async {
    final response = await showModalBottomSheet<DocumentResponse>(
      context: context,
      backgroundColor: const Color(0xFF0F1117),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(document.title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(document.body,
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 12),
            ...document.recommendations.map((rec) => Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 18, color: Colors.lightGreen),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(rec,
                            style: const TextStyle(color: Colors.white))),
                  ],
                )),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(document),
              child: const Text('Chiudi'),
            ),
          ],
        ),
      ),
    );
    if (response != null) {
      setState(() => _documentHistory.insert(
          0, DocumentHistoryEntry(response, DateTime.now())));
      await _persistDocumentHistory();
    }
  }

  Future<void> _persistDocumentHistory() async {
    final storage = _historyStorage;
    if (storage == null) return;
    try {
      await storage.saveHistory(_documentHistory);
    } catch (error) {
      debugPrint('Impossibile salvare la cronologia: $error');
    }
  }

  Widget _buildDocumentScanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10131A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Scannerizza o carica un documento',
              style: TextStyle(
                  color: Colors.blueGrey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_pickedImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _pickedImage!,
                fit: BoxFit.cover,
                height: 180,
              ),
            ),
          if (_isProcessingImage) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          if (_ocrText != null && _ocrText!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Testo estratto:',
                style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            const SizedBox(height: 4),
            Text(_ocrText!, style: const TextStyle(color: Colors.white70)),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () => _pickDocument(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Fotografa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickDocument(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Carica galleria'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskBadge(RiskLevel? level) {
    final color = _riskColor(level);
    final label = level?.name.toUpperCase() ?? 'ATTESA';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha((0.25 * 255).round()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataChips() {
    final chips = <Widget>[
      _metadataChip('Cliente', _userIdController.text.trim()),
      _metadataChip('Giurisdizione', _jurisdictionController.text.trim()),
      _metadataChip('Importo', _formattedCurrency()),
      _metadataChip('Notifica', _formattedIssueDate()),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: chips,
    );
  }

  Widget _metadataChip(String label, String value) {
    return Chip(
      label: Text(
        '$label: $value',
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
      backgroundColor: Colors.blueGrey.shade900,
      side: const BorderSide(color: Colors.blueGrey),
    );
  }

  String _formattedCurrency() {
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    return '€ ${amount.toStringAsFixed(2)}';
  }

  String _formattedIssueDate() {
    return _issueDate.toIso8601String().split('T').first;
  }

  Color _riskColor(RiskLevel? level) {
    switch (level) {
      case RiskLevel.high:
        return Colors.redAccent;
      case RiskLevel.medium:
        return Colors.amberAccent;
      case RiskLevel.low:
        return Colors.greenAccent;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _buildDocumentHistory() {
    return Column(
      children: _documentHistory.map((entry) {
        return Card(
          color: const Color(0xFF1D1E24),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.document.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                Text(
                  entry.document.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.timestamp.toIso8601String().split('T').first,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.greenAccent),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: entry.document.body));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Testo copiato negli appunti')),
                        );
                      },
                    )
                  ],
                )
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RiskStat {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  _RiskStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
}
