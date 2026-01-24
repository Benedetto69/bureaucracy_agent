import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/document_history.dart';
import 'screens/entry_page.dart';
import 'screens/privacy_page.dart';
import 'services/api_service.dart';
import 'services/document_analyzer_models.dart';
import 'services/history_storage.dart';
import 'services/ocr_service.dart';
import 'theme/app_theme.dart';
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
        '/privacy': (_) => const PrivacyPage(),
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
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  bool _storeAvailable = false;
  bool _isPremium = false;
  bool _isPurchasing = false;
  String? _storeError;
  List<ProductDetails> _products = [];
  static const int _freeDailyLimit = 3;
  static const String _analysisCountKey = 'analysis_count';
  static const String _analysisCountDateKey = 'analysis_count_date';
  int _analysisCountToday = 0;
  String _analysisCountDate = '';
  static const _panelGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF121925),
      Color(0xFF090C12),
    ],
  );
  static const _panelBorderColor = Color(0xFF1C2336);
  static const _panelAccent = Color(0xFF51FFBD);
  static final List<AnalysisIssue> _offlineIssuesDemo = [
    AnalysisIssue(
      type: IssueType.substance,
      issue: 'Le clausole della contestazione sembrano applicare interessi non previsti dal tariffario.',
      confidence: 0.86,
      references: [
        Reference(
          source: ReferenceSource.norma,
          citation: 'Art. 3 Decreto 2025',
          url: Uri.parse('https://www.normattiva.it/uri-res/N2Ls?urn:nir:stato:decreto.2025'),
        ),
      ],
      actions: [
        'Segnala la discrepanza al team di supporto per revisione',
        'Prepara richiesta formale di rettifica entro 5 giorni',
      ],
    ),
    AnalysisIssue(
      type: IssueType.formality,
      issue: 'Manca il timbro del protocollo sul secondo foglio, necessario per la conformità.',
      confidence: 0.72,
      references: [
        Reference(
          source: ReferenceSource.policy,
          citation: 'Linee guida interne 2.1.4',
          url: Uri.parse('https://intranet.bureaucracy/labs/guidelines-2.1.4'),
        ),
      ],
      actions: [
        'Chiedere conferma dell’ufficio emittente e allegare prova fotografica',
        'Rifirmare il documento con timestamp aggiornato',
      ],
    ),
  ];
  static final Summary _offlineSummaryDemo = Summary(
    riskLevel: RiskLevel.medium,
    nextStep: 'Simulazione offline: pulisci i formati, allega la documentazione e invia per revisione manuale.',
  );

  @override
  void initState() {
    super.initState();
    _initializeHistory();
    _initializeStore();
    _initializeUsageLimits();
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
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

  Future<void> _initializeUsageLimits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayKey = _formatDay(DateTime.now());
      final storedDate = prefs.getString(_analysisCountDateKey);
      final storedCount = prefs.getInt(_analysisCountKey) ?? 0;
      final count = storedDate == todayKey ? storedCount : 0;
      if (storedDate != todayKey) {
        await prefs.setString(_analysisCountDateKey, todayKey);
        await prefs.setInt(_analysisCountKey, 0);
      }
      if (!mounted) return;
      setState(() {
        _analysisCountDate = todayKey;
        _analysisCountToday = count;
      });
    } catch (error) {
      debugPrint('Impossibile inizializzare limite giornaliero: $error');
    }
  }

  String _formatDay(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static const Set<String> _productIds = {
    'com.benedettoriba.bureaucracy.premium.monthly',
    'com.benedettoriba.bureaucracy.premium.annual',
  };

  Future<void> _initializeStore() async {
    try {
      final available = await _iap.isAvailable();
      if (!mounted) return;
      setState(() => _storeAvailable = available);
      if (!available) return;

      final response = await _iap.queryProductDetails(_productIds);
      if (!mounted) return;
      setState(() {
        _products = response.productDetails;
        _storeError = response.error?.message;
      });

      _purchaseSub = _iap.purchaseStream.listen(
        _handlePurchaseUpdates,
        onError: (error) {
          if (!mounted) return;
          setState(() => _storeError = 'Errore store: $error');
        },
      );
      await _iap.restorePurchases();
    } catch (error) {
      debugPrint('Impossibile inizializzare lo store: $error');
      if (!mounted) return;
      setState(() => _storeError = 'Store non disponibile: $error');
    }
  }

  Future<void> _recordAnalysisUsage() async {
    if (_isPremium) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayKey = _formatDay(DateTime.now());
      var count = _analysisCountToday;
      if (_analysisCountDate != todayKey) {
        count = 0;
      }
      count += 1;
      await prefs.setString(_analysisCountDateKey, todayKey);
      await prefs.setInt(_analysisCountKey, count);
      if (!mounted) return;
      setState(() {
        _analysisCountDate = todayKey;
        _analysisCountToday = count;
      });
    } catch (error) {
      debugPrint('Impossibile salvare limite giornaliero: $error');
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

    final todayKey = _formatDay(DateTime.now());
    if (_analysisCountDate != todayKey) {
      setState(() {
        _analysisCountDate = todayKey;
        _analysisCountToday = 0;
      });
    }

    if (!_isPremium && _analysisCountToday >= _freeDailyLimit) {
      setState(() {
        _errorMessage =
            'Limite giornaliero gratuito raggiunto. Passa a Premium per analisi illimitate.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _esitoIA = "L'algoritmo sta interrogando il cervello...";
    });

    var analysisSucceeded = false;
    final payload = AnalyzePayload(
      documentId: DateTime.now().millisecondsSinceEpoch.toString(),
      source: SourceType.ocr,
      metadata: Metadata(
        userId: _userIdController.text.trim(),
        issueDate: _issueDate,
        amount: amount,
        jurisdiction: _jurisdictionController.text.trim(),
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
      analysisSucceeded = true;
    } on SocketException catch (_) {
      _applyOfflineFallback(payload.documentId);
      analysisSucceeded = true;
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
      if (analysisSucceeded) {
        await _recordAnalysisUsage();
      }
    }
  }

  void _applyOfflineFallback(String documentId) {
    setState(() {
      _errorMessage =
          'Nessuna connessione col cervello: usiamo una simulazione offline.';
      _issues = [..._offlineIssuesDemo];
      _summary = _offlineSummaryDemo;
      _serverTime = DateTime.now()
          .toLocal()
          .toIso8601String()
          .replaceFirst('T', ' ');
      _lastPayloadId = documentId;
    });
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
        } else {
          _errorMessage = "Nessun testo rilevato nell'immagine.";
        }
      });
    } catch (error) {
      setState(() => _errorMessage = 'OCR fallita: $error');
    } finally {
      setState(() => _isProcessingImage = false);
    }
  }

  Future<String> _runTextRecognition(XFile file) async {
    try {
      // Real OCR on iOS via Vision; other platforms may throw MissingPluginException.
      final extracted = await OcrService.recognizeText(file.path);
      return extracted;
    } on MissingPluginException {
      // Non-iOS builds (or misconfigured iOS runner) will end up here.
      return '';
    } catch (error) {
      // Let caller surface a readable error banner.
      throw Exception('OCR non disponibile: $error');
    }
  }

  String _prepareOcrDisplayText(String text) {
    const breaker = '\u200B';
    return text.replaceAllMapped(
      RegExp(r'([_/\\\-.])'),
      (match) => '${match.group(0)}$breaker',
    );
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
                _buildCaseInputPanel(),
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

  Widget _buildCaseInputPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
      decoration: BoxDecoration(
        gradient: _panelGradient,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _panelBorderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 18,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF51FFBD),
                      Color(0xFF8CFFE1),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Descrizione del caso',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Più dettagli ci dai, più veloce diventa la strategia.',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildDescriptionField(),
          const SizedBox(height: 22),
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Metadata minimali',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Text(
                'Clienti verificati',
                style: TextStyle(color: _panelAccent, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMetadataInputs(),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFF1C2336), height: 0),
          const SizedBox(height: 16),
          _buildDateRow(),
          const SizedBox(height: 18),
          _buildDocumentScanner(),
          const SizedBox(height: 26),
          _buildAnalyzeButton(),
          if (!_isPremium) ...[
            const SizedBox(height: 10),
            Text(
              'Piano gratuito: $_analysisCountToday/$_freeDailyLimit analisi usate oggi.',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionController,
      maxLines: 5,
      style: const TextStyle(color: Colors.white),
      decoration: _glassDecoration(
        'Racconta testo, clausole sospette o ritardi',
        hint:
            'Più contesto ci dai, più intelligente sarà il prossimo step operativo.',
        icon: Icons.speaker_notes_outlined,
        alignLabel: true,
      ),
    );
  }

  InputDecoration _glassDecoration(
    String label, {
    String? hint,
    IconData? icon,
    bool alignLabel = false,
  }) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior:
          alignLabel ? FloatingLabelBehavior.never : FloatingLabelBehavior.always,
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
      filled: true,
      fillColor: const Color(0xFF0C131D),
      prefixIcon: icon == null
          ? null
          : Icon(
              icon,
              color: Colors.white38,
            ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildGlassField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: _glassDecoration(label, icon: icon),
    );
  }

  Widget _buildMetadataInputs() {
    return Column(
      children: [
        _buildGlassField(
          label: 'Client ID',
          controller: _userIdController,
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildGlassField(
                label: 'Giurisdizione',
                controller: _jurisdictionController,
                icon: Icons.location_city,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGlassField(
                label: 'Importo contestato',
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                icon: Icons.savings_outlined,
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
        const Expanded(
          child: Text(
            'Data di notifica',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 13,
            ),
          ),
        ),
        OutlinedButton(
          onPressed: _scegliData,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF1C2336)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            foregroundColor: Colors.white,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_month_outlined, size: 18),
              const SizedBox(width: 8),
              Text(
                _issueDate.toIso8601String().split('T').first,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentScanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B121F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF111928),
            Color(0xFF05080E),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.document_scanner_outlined, color: Colors.white70),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Scannerizza o carica un documento',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_isProcessingImage)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: ElevatedButton.icon(
                  onPressed: () => _pickDocument(ImageSource.camera),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA165FF),
                    foregroundColor: Colors.white,
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    minimumSize: const Size(0, 56),
                  ),
                  icon: const Icon(Icons.camera_alt_outlined, size: 20),
                  label: const Text(
                    'Fotografa',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      letterSpacing: 0.15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: OutlinedButton.icon(
                  onPressed: () => _pickDocument(ImageSource.gallery),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white70,
                    elevation: 0,
                    side: const BorderSide(color: Color(0xFF2E3648)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    minimumSize: const Size(0, 56),
                  ),
                  icon: const Icon(Icons.photo_library, size: 20),
                  label: const Text(
                    'Carica galleria',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 0.1,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_pickedImage != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                _pickedImage!,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
          ],
          if (_isProcessingImage) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          if (_ocrText != null && _ocrText!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Testo estratto', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              _prepareOcrDisplayText(_ocrText!),
              style: const TextStyle(color: Colors.white60, fontSize: 13),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF51FFBD),
            Color(0xFF1AE7B8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2251FFBD),
            blurRadius: 14,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _avviaAnalisi,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'AVVIA ANALISI DEL CERVELLO',
                style: TextStyle(
                  fontSize: 16,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
      'Analisi illimitate (sblocca il limite giornaliero)',
      'Storico locale delle bozze generate',
    ];
    final isActive = _isPremium;
    final monthly = _findProduct('com.benedettoriba.bureaucracy.premium.monthly');
    final annual = _findProduct('com.benedettoriba.bureaucracy.premium.annual');
    final priceLine = _buildPriceLine(monthly, annual);
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
            isActive ? 'Abbonamento attivo' : 'Sblocca tutte le funzionalità premium',
            style: TextStyle(
              color: isActive ? Colors.greenAccent : Colors.white70,
              fontSize: 13,
            ),
          ),
          if (priceLine.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              priceLine,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          ...perks.map(_buildBenefitRow),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: isActive || !_storeAvailable || _isPurchasing
                ? null
                : _showPurchaseOptions,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isActive || !_storeAvailable
                      ? Colors.greenAccent.withAlpha((0.6 * 255).round())
                      : Colors.greenAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              isActive
                  ? 'Premium attivo'
                  : _isPurchasing
                      ? 'Operazione in corso...'
                      : 'Sblocca premium',
            ),
          ),
          if (!isActive)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _storeAvailable ? _showPurchaseOptions : null,
                  style: TextButton.styleFrom(foregroundColor: Colors.greenAccent),
                  child: const Text('Mostra piani e prezzi'),
                ),
                TextButton(
                  onPressed: _storeAvailable ? _restorePurchases : null,
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  child: const Text('Ripristina acquisti'),
                ),
              ],
            ),
          if (_storeError != null)
            Text(
              _storeError!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          if (!_storeAvailable)
            const Text(
              'Store non disponibile al momento.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
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
              'Sblocca analisi illimitate e rimuovi il limite giornaliero gratuito.',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: _storeAvailable ? _showPurchaseOptions : null,
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

  ProductDetails? _findProduct(String id) {
    for (final product in _products) {
      if (product.id == id) return product;
    }
    return null;
  }

  String _buildPriceLine(ProductDetails? monthly, ProductDetails? annual) {
    if (monthly == null && annual == null) return '';
    final parts = <String>[];
    if (monthly != null) parts.add('Mensile ${monthly.price}');
    if (annual != null) parts.add('Annuale ${annual.price}');
    return parts.join(' • ');
  }

  Future<void> _showPurchaseOptions() async {
    final monthly = _findProduct('com.benedettoriba.bureaucracy.premium.monthly');
    final annual = _findProduct('com.benedettoriba.bureaucracy.premium.annual');
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0F1117),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Scegli il piano',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Eventuali prove gratuite vengono mostrate al checkout.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
            if (_storeError != null)
              Text(
                _storeError!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            if (monthly != null)
              ListTile(
                title: const Text('Mensile'),
                subtitle: Text(monthly.description),
                trailing: Text(monthly.price),
                onTap: _isPurchasing
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        _buy(monthly);
                      },
              ),
            if (annual != null)
              ListTile(
                title: const Text('Annuale'),
                subtitle: Text(annual.description),
                trailing: Text(annual.price),
                onTap: _isPurchasing
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        _buy(annual);
                      },
              ),
            if (monthly == null && annual == null)
              const Text(
                'Prodotti non disponibili al momento.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _restorePurchases,
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
              child: const Text('Ripristina acquisti'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _buy(ProductDetails product) async {
    if (!_storeAvailable) return;
    setState(() => _isPurchasing = true);
    final param = PurchaseParam(
      productDetails: product,
      applicationUserName: _userIdController.text.trim().isEmpty
          ? null
          : _userIdController.text.trim(),
    );
    try {
      await _iap.buyNonConsumable(purchaseParam: param);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isPurchasing = false;
        _storeError = 'Acquisto non riuscito: $error';
      });
    }
  }

  Future<void> _restorePurchases() async {
    if (!_storeAvailable) return;
    await _iap.restorePurchases();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ripristino acquisti avviato'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handlePurchaseUpdates(
      List<PurchaseDetails> purchases) async {
    var premium = _isPremium;
    final wasPremium = _isPremium;
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          if (mounted) setState(() => _isPurchasing = true);
          break;
        case PurchaseStatus.error:
          if (mounted) {
            setState(() {
              _isPurchasing = false;
              _storeError =
                  purchase.error?.message ?? 'Acquisto non riuscito.';
            });
          }
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (_productIds.contains(purchase.productID)) {
            premium = true;
          }
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;
        default:
          if (mounted) setState(() => _isPurchasing = false);
          break;
      }
    }
    if (!mounted) return;
    setState(() {
      _isPremium = premium;
      _isPurchasing = false;
    });
    if (!wasPremium && premium) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Premium attivo'),
          duration: Duration(seconds: 2),
        ),
      );
    }
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
