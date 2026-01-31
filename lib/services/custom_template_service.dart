import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modello per un template personalizzato
class CustomTemplate {
  final String id;
  final String name;
  final String category; // 'prefetto', 'giudice_pace', 'autotutela'
  final String subject;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDefault;

  const CustomTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.subject,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.isDefault = false,
  });

  CustomTemplate copyWith({
    String? id,
    String? name,
    String? category,
    String? subject,
    String? body,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDefault,
  }) {
    return CustomTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'subject': subject,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isDefault': isDefault,
      };

  factory CustomTemplate.fromJson(Map<String, dynamic> json) => CustomTemplate(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        subject: json['subject'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        isDefault: json['isDefault'] as bool? ?? false,
      );

  /// Placeholder disponibili nel template
  static const List<TemplatePlaceholder> availablePlaceholders = [
    TemplatePlaceholder(
      key: '[NOME_COGNOME]',
      description: 'Nome e cognome del ricorrente',
      example: 'Mario Rossi',
    ),
    TemplatePlaceholder(
      key: '[INDIRIZZO]',
      description: 'Indirizzo completo',
      example: 'Via Roma 1, 20100 Milano',
    ),
    TemplatePlaceholder(
      key: '[CODICE_FISCALE]',
      description: 'Codice fiscale',
      example: 'RSSMRA80A01H501Z',
    ),
    TemplatePlaceholder(
      key: '[PEC_MITTENTE]',
      description: 'Indirizzo PEC del mittente',
      example: 'mario.rossi@pec.it',
    ),
    TemplatePlaceholder(
      key: '[DESTINATARIO]',
      description: 'Ente destinatario',
      example: 'Prefettura di Milano',
    ),
    TemplatePlaceholder(
      key: '[PEC_DESTINATARIO]',
      description: 'PEC del destinatario',
      example: 'protocollo@pec.prefettura.milano.it',
    ),
    TemplatePlaceholder(
      key: '[NUMERO_VERBALE]',
      description: 'Numero del verbale/multa',
      example: '2024/12345',
    ),
    TemplatePlaceholder(
      key: '[DATA_VERBALE]',
      description: 'Data del verbale',
      example: '15/01/2024',
    ),
    TemplatePlaceholder(
      key: '[IMPORTO]',
      description: 'Importo della multa',
      example: '150,00',
    ),
    TemplatePlaceholder(
      key: '[TARGA]',
      description: 'Targa del veicolo',
      example: 'AB123CD',
    ),
    TemplatePlaceholder(
      key: '[MOTIVAZIONI]',
      description: 'Motivazioni del ricorso (generate dall\'analisi)',
      example: 'Vizio di notifica...',
    ),
    TemplatePlaceholder(
      key: '[DATA_ODIERNA]',
      description: 'Data corrente',
      example: '31/01/2024',
    ),
  ];
}

/// Placeholder per i template
class TemplatePlaceholder {
  final String key;
  final String description;
  final String example;

  const TemplatePlaceholder({
    required this.key,
    required this.description,
    required this.example,
  });
}

/// Categoria template
enum TemplateCategory {
  prefetto('prefetto', 'Ricorso al Prefetto', '60 giorni'),
  giudicePace('giudice_pace', 'Ricorso al Giudice di Pace', '30 giorni'),
  autotutela('autotutela', 'Istanza di Autotutela', 'Nessun termine');

  final String id;
  final String label;
  final String deadline;

  const TemplateCategory(this.id, this.label, this.deadline);
}

/// Servizio per gestire i template personalizzati
class CustomTemplateService {
  static const String _storageKey = 'custom_templates';
  static const String _defaultTemplateKey = 'default_template_id';

  /// Carica tutti i template salvati
  static Future<List<CustomTemplate>> loadTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString == null || jsonString.isEmpty) {
        return _getBuiltInTemplates();
      }
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final templates = jsonList
          .map((json) => CustomTemplate.fromJson(json as Map<String, dynamic>))
          .toList();
      // Aggiungi template built-in se non presenti
      final builtIn = _getBuiltInTemplates();
      for (final bt in builtIn) {
        if (!templates.any((t) => t.id == bt.id)) {
          templates.add(bt);
        }
      }
      return templates;
    } catch (e) {
      debugPrint('Errore caricamento template: $e');
      return _getBuiltInTemplates();
    }
  }

  /// Salva un template
  static Future<void> saveTemplate(CustomTemplate template) async {
    final templates = await loadTemplates();
    final index = templates.indexWhere((t) => t.id == template.id);
    if (index >= 0) {
      templates[index] = template;
    } else {
      templates.add(template);
    }
    await _persistTemplates(templates);
  }

  /// Elimina un template
  static Future<void> deleteTemplate(String templateId) async {
    final templates = await loadTemplates();
    templates.removeWhere((t) => t.id == templateId && !t.id.startsWith('builtin_'));
    await _persistTemplates(templates);
  }

  /// Imposta il template predefinito per una categoria
  static Future<void> setDefaultTemplate(String templateId, String category) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_defaultTemplateKey}_$category', templateId);
  }

  /// Ottieni il template predefinito per una categoria
  static Future<CustomTemplate?> getDefaultTemplate(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final defaultId = prefs.getString('${_defaultTemplateKey}_$category');
    final templates = await loadTemplates();

    if (defaultId != null) {
      final template = templates.where((t) => t.id == defaultId).firstOrNull;
      if (template != null) return template;
    }

    // Fallback al built-in
    return templates.where((t) => t.category == category && t.id.startsWith('builtin_')).firstOrNull;
  }

  /// Duplica un template
  static Future<CustomTemplate> duplicateTemplate(CustomTemplate template) async {
    final now = DateTime.now();
    final newTemplate = template.copyWith(
      id: 'custom_${now.millisecondsSinceEpoch}',
      name: '${template.name} (copia)',
      createdAt: now,
      updatedAt: now,
      isDefault: false,
    );
    await saveTemplate(newTemplate);
    return newTemplate;
  }

  /// Esporta template come JSON
  static String exportTemplate(CustomTemplate template) {
    return const JsonEncoder.withIndent('  ').convert(template.toJson());
  }

  /// Importa template da JSON
  static Future<CustomTemplate?> importTemplate(String jsonString) async {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final now = DateTime.now();
      final template = CustomTemplate.fromJson(json).copyWith(
        id: 'imported_${now.millisecondsSinceEpoch}',
        createdAt: now,
        updatedAt: now,
        isDefault: false,
      );
      await saveTemplate(template);
      return template;
    } catch (e) {
      debugPrint('Errore importazione template: $e');
      return null;
    }
  }

  static Future<void> _persistTemplates(List<CustomTemplate> templates) async {
    final prefs = await SharedPreferences.getInstance();
    // Salva solo template personalizzati, non built-in
    final customTemplates = templates.where((t) => !t.id.startsWith('builtin_')).toList();
    final jsonString = jsonEncode(customTemplates.map((t) => t.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }

  /// Template built-in predefiniti
  static List<CustomTemplate> _getBuiltInTemplates() {
    final now = DateTime.now();
    return [
      CustomTemplate(
        id: 'builtin_prefetto',
        name: 'Ricorso Prefetto (Standard)',
        category: 'prefetto',
        subject: 'RICORSO EX ART. 203 C.D.S. - Verbale n. [NUMERO_VERBALE]',
        body: '''Ill.mo Sig. PREFETTO DI [DESTINATARIO]

OGGETTO: Ricorso avverso verbale di contestazione n. [NUMERO_VERBALE] del [DATA_VERBALE]

Il/La sottoscritto/a [NOME_COGNOME], nato/a a ___________ il ___________, residente in [INDIRIZZO], C.F. [CODICE_FISCALE], proprietario/conducente del veicolo targato [TARGA],

PREMESSO CHE

- In data [DATA_VERBALE] veniva notificato il verbale di contestazione n. [NUMERO_VERBALE] per l'importo di Euro [IMPORTO];
- Il/La sottoscritto/a ritiene tale verbale illegittimo e/o infondato per i seguenti motivi:

[MOTIVAZIONI]

CHIEDE

L'annullamento del verbale in oggetto per i motivi sopra esposti.

Si allegano:
- Copia del verbale impugnato
- Copia del documento di identita
- [Eventuali altri documenti]

Luogo e data: ___________, [DATA_ODIERNA]

Firma: ___________________________

---
Indirizzo PEC mittente: [PEC_MITTENTE]
Indirizzo PEC destinatario: [PEC_DESTINATARIO]''',
        createdAt: now,
        updatedAt: now,
        isDefault: true,
      ),
      CustomTemplate(
        id: 'builtin_giudice_pace',
        name: 'Ricorso Giudice di Pace (Standard)',
        category: 'giudice_pace',
        subject: 'RICORSO EX ART. 204-BIS C.D.S. - Verbale n. [NUMERO_VERBALE]',
        body: '''ILL.MO GIUDICE DI PACE DI [DESTINATARIO]

RICORSO

Il/La sottoscritto/a [NOME_COGNOME], nato/a a ___________ il ___________, residente in [INDIRIZZO], C.F. [CODICE_FISCALE],

RICORRENTE

CONTRO

Comune di ___________ / Prefettura di ___________

RESISTENTE

OGGETTO: Opposizione a verbale di contestazione n. [NUMERO_VERBALE] del [DATA_VERBALE] - Importo Euro [IMPORTO]

FATTO

In data [DATA_VERBALE] veniva elevato nei confronti del ricorrente il verbale n. [NUMERO_VERBALE] per la presunta violazione di ___________, relativo al veicolo targato [TARGA].

DIRITTO

Il ricorrente impugna il suddetto verbale per i seguenti motivi:

[MOTIVAZIONI]

CONCLUSIONI

Voglia l'Ill.mo Giudice di Pace, contrariis reiectis:
- Annullare il verbale impugnato;
- Condannare l'Amministrazione resistente al pagamento delle spese di lite.

Si producono:
1. Copia del verbale impugnato
2. Copia del documento di identita
3. [Altri documenti]

Luogo e data: ___________, [DATA_ODIERNA]

Firma: ___________________________

Valore della causa: Euro [IMPORTO]
Contributo unificato: Euro ___ (calcolato in base al valore)''',
        createdAt: now,
        updatedAt: now,
        isDefault: true,
      ),
      CustomTemplate(
        id: 'builtin_autotutela',
        name: 'Istanza di Autotutela (Standard)',
        category: 'autotutela',
        subject: 'ISTANZA DI ANNULLAMENTO IN AUTOTUTELA - Verbale n. [NUMERO_VERBALE]',
        body: '''Spett.le [DESTINATARIO]
[PEC_DESTINATARIO]

OGGETTO: Istanza di annullamento in autotutela del verbale n. [NUMERO_VERBALE] del [DATA_VERBALE]

Il/La sottoscritto/a [NOME_COGNOME], nato/a a ___________ il ___________, residente in [INDIRIZZO], C.F. [CODICE_FISCALE],

ESPONE

- Di aver ricevuto il verbale di contestazione n. [NUMERO_VERBALE] del [DATA_VERBALE] relativo al veicolo targato [TARGA], per l'importo di Euro [IMPORTO];

- Che il suddetto verbale risulta viziato per i seguenti motivi:

[MOTIVAZIONI]

CHIEDE

L'annullamento in autotutela del verbale in oggetto, ai sensi dell'art. 21-nonies della Legge 241/1990, per manifesta illegittimita dello stesso.

In subordine, chiede che venga disposta la rettifica dell'importo/sanzione applicata.

Si allegano:
- Copia del verbale
- Documentazione a supporto
- Copia documento di identita

Distinti saluti.

Luogo e data: ___________, [DATA_ODIERNA]

Firma: ___________________________

Recapiti:
PEC: [PEC_MITTENTE]
Tel: ___________''',
        createdAt: now,
        updatedAt: now,
        isDefault: true,
      ),
    ];
  }
}
