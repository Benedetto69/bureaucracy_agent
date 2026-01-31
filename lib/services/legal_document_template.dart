import 'package:intl/intl.dart';

import 'document_analyzer_models.dart';

/// Generates properly formatted legal documents for Italian traffic fine appeals
class LegalDocumentTemplate {
  LegalDocumentTemplate._();

  static final _dateFormat = DateFormat('dd/MM/yyyy', 'it_IT');
  static final _longDateFormat = DateFormat('d MMMM yyyy', 'it_IT');

  /// Generate a complete PEC/Ricorso document
  static FormattedDocument generateRicorso({
    required DocumentResponse apiResponse,
    required String senderName,
    required String senderAddress,
    required String senderFiscalCode,
    required String senderPec,
    required String recipientEntity,
    required String recipientPec,
    required String fineNumber,
    required DateTime fineDate,
    required double fineAmount,
    required String plateNumber,
    required String violationDescription,
    required List<AnalysisIssue> issues,
    String? additionalNotes,
  }) {
    final today = DateTime.now();
    final buffer = StringBuffer();

    // === HEADER ===
    buffer.writeln('RACCOMANDATA A/R - PEC');
    buffer.writeln();
    buffer.writeln('Spett.le');
    buffer.writeln(recipientEntity.toUpperCase());
    buffer.writeln('PEC: $recipientPec');
    buffer.writeln();
    buffer.writeln('e p.c.');
    buffer.writeln('PREFETTURA DI ________________');
    buffer.writeln('(compilare se ricorso al Prefetto)');
    buffer.writeln();

    // === OGGETTO ===
    buffer.writeln('=' * 60);
    buffer.writeln('OGGETTO: RICORSO AVVERSO VERBALE DI CONTESTAZIONE');
    buffer.writeln('N. $fineNumber DEL ${_dateFormat.format(fineDate)}');
    buffer.writeln('=' * 60);
    buffer.writeln();

    // === DATI RICORRENTE ===
    buffer.writeln('Il/La sottoscritto/a:');
    buffer.writeln();
    buffer.writeln('Cognome e Nome: $senderName');
    buffer.writeln('Codice Fiscale: $senderFiscalCode');
    buffer.writeln('Residente in: $senderAddress');
    buffer.writeln('PEC: $senderPec');
    buffer.writeln('Telefono: ________________');
    buffer.writeln();

    // === PREMESSO CHE ===
    buffer.writeln('-' * 60);
    buffer.writeln('PREMESSO CHE');
    buffer.writeln('-' * 60);
    buffer.writeln();
    buffer.writeln(
        '- in data ${_dateFormat.format(fineDate)} veniva notificato il verbale '
        'di contestazione n. $fineNumber;');
    buffer.writeln();
    buffer.writeln(
        '- il suddetto verbale contestava la violazione: $violationDescription;');
    buffer.writeln();
    buffer.writeln(
        '- l\'importo richiesto ammonta a Euro ${fineAmount.toStringAsFixed(2)};');
    buffer.writeln();
    buffer.writeln('- il veicolo interessato reca targa: $plateNumber;');
    buffer.writeln();

    // === RILEVA ===
    buffer.writeln('-' * 60);
    buffer.writeln('RILEVA');
    buffer.writeln('-' * 60);
    buffer.writeln();

    // Organize issues by type
    final formalityIssues =
        issues.where((i) => i.type == IssueType.formality).toList();
    final processIssues =
        issues.where((i) => i.type == IssueType.process).toList();
    final substanceIssues =
        issues.where((i) => i.type == IssueType.substance).toList();

    int issueNumber = 1;

    if (formalityIssues.isNotEmpty) {
      buffer.writeln('*** VIZI DI FORMA ***');
      buffer.writeln();
      for (final issue in formalityIssues) {
        buffer.writeln('$issueNumber) ${issue.issue}');
        buffer.writeln();
        if (issue.references.isNotEmpty) {
          buffer.writeln('   Riferimenti normativi:');
          for (final ref in issue.references) {
            buffer.writeln('   - ${ref.citation}');
          }
          buffer.writeln();
        }
        issueNumber++;
      }
    }

    if (processIssues.isNotEmpty) {
      buffer.writeln('*** VIZI DI PROCEDURA ***');
      buffer.writeln();
      for (final issue in processIssues) {
        buffer.writeln('$issueNumber) ${issue.issue}');
        buffer.writeln();
        if (issue.references.isNotEmpty) {
          buffer.writeln('   Riferimenti normativi:');
          for (final ref in issue.references) {
            buffer.writeln('   - ${ref.citation}');
          }
          buffer.writeln();
        }
        issueNumber++;
      }
    }

    if (substanceIssues.isNotEmpty) {
      buffer.writeln('*** VIZI DI MERITO ***');
      buffer.writeln();
      for (final issue in substanceIssues) {
        buffer.writeln('$issueNumber) ${issue.issue}');
        buffer.writeln();
        if (issue.references.isNotEmpty) {
          buffer.writeln('   Riferimenti normativi:');
          for (final ref in issue.references) {
            buffer.writeln('   - ${ref.citation}');
          }
          buffer.writeln();
        }
        issueNumber++;
      }
    }

    // === ADDITIONAL NOTES ===
    if (additionalNotes != null && additionalNotes.isNotEmpty) {
      buffer.writeln('*** ULTERIORI OSSERVAZIONI ***');
      buffer.writeln();
      buffer.writeln(additionalNotes);
      buffer.writeln();
    }

    // === DIRITTO ===
    buffer.writeln('-' * 60);
    buffer.writeln('DIRITTO');
    buffer.writeln('-' * 60);
    buffer.writeln();
    buffer.writeln(
        'Il presente ricorso e\' proposto ai sensi e per gli effetti:');
    buffer.writeln();
    buffer.writeln(
        '- dell\'art. 203 del Codice della Strada (D.Lgs. 285/1992) - '
        'Ricorso al Prefetto;');
    buffer.writeln();
    buffer.writeln(
        '- dell\'art. 204-bis del Codice della Strada - Ricorso al '
        'Giudice di Pace;');
    buffer.writeln();
    buffer.writeln(
        '- degli artt. 22 e ss. della Legge 689/1981 - Opposizione a '
        'ordinanza-ingiunzione;');
    buffer.writeln();
    buffer.writeln(
        '- dei principi generali in materia di legittimita\' degli '
        'atti amministrativi.');
    buffer.writeln();

    // === CHIEDE / P.Q.M. ===
    buffer.writeln('-' * 60);
    buffer.writeln('TUTTO CIO\' PREMESSO E CONSIDERATO');
    buffer.writeln('-' * 60);
    buffer.writeln();
    buffer.writeln('Il/La sottoscritto/a');
    buffer.writeln();
    buffer.writeln('CHIEDE');
    buffer.writeln();
    buffer.writeln(
        '1. L\'annullamento del verbale di contestazione n. $fineNumber '
        'del ${_dateFormat.format(fineDate)} per i motivi sopra esposti;');
    buffer.writeln();
    buffer.writeln(
        '2. In subordine, la riduzione della sanzione al minimo edittale;');
    buffer.writeln();
    buffer.writeln(
        '3. La sospensione dell\'efficacia esecutiva del provvedimento '
        'impugnato nelle more del giudizio;');
    buffer.writeln();
    buffer.writeln('4. Con vittoria di spese e competenze.');
    buffer.writeln();

    // === DOCUMENTI ALLEGATI ===
    buffer.writeln('-' * 60);
    buffer.writeln('DOCUMENTI ALLEGATI');
    buffer.writeln('-' * 60);
    buffer.writeln();
    buffer.writeln('1. Copia del verbale di contestazione n. $fineNumber;');
    buffer.writeln('2. Copia del documento di identita\' del ricorrente;');
    buffer.writeln('3. Copia del codice fiscale;');
    buffer.writeln(
        '4. Documentazione fotografica (se disponibile): ________________;');
    buffer.writeln('5. Altra documentazione: ________________.');
    buffer.writeln();

    // === FIRMA ===
    buffer.writeln('-' * 60);
    buffer.writeln();
    buffer.writeln('Luogo e data: ________________, ${_longDateFormat.format(today)}');
    buffer.writeln();
    buffer.writeln('In fede,');
    buffer.writeln();
    buffer.writeln();
    buffer.writeln('_______________________________');
    buffer.writeln('(Firma del ricorrente)');
    buffer.writeln();

    // === DISCLAIMER ===
    buffer.writeln();
    buffer.writeln('=' * 60);
    buffer.writeln('AVVERTENZE');
    buffer.writeln('=' * 60);
    buffer.writeln();
    buffer.writeln(
        '* Questa bozza e\' stata generata automaticamente e richiede '
        'VERIFICA e PERSONALIZZAZIONE.');
    buffer.writeln(
        '* Compilare tutti i campi contrassegnati con "________________".');
    buffer.writeln(
        '* Verificare i riferimenti normativi e la loro applicabilita\' '
        'al caso specifico.');
    buffer.writeln(
        '* Per importi elevati o casi complessi, si consiglia la '
        'consulenza di un avvocato.');
    buffer.writeln(
        '* Il termine per il ricorso al Prefetto e\' di 60 giorni dalla '
        'notifica.');
    buffer.writeln(
        '* Il termine per il ricorso al Giudice di Pace e\' di 30 giorni '
        'dalla notifica.');

    return FormattedDocument(
      title: 'Ricorso Verbale n. $fineNumber',
      body: buffer.toString(),
      shortSummary: _generateShortSummary(issues),
      issueCount: issues.length,
      mainIssueType: _getMainIssueType(issues),
    );
  }

  /// Generate a simpler opposition letter (for minor cases)
  static FormattedDocument generateLetteraOpposizione({
    required String senderName,
    required String recipientEntity,
    required String fineNumber,
    required DateTime fineDate,
    required double fineAmount,
    required String mainIssue,
    required List<String> supportingPoints,
  }) {
    final today = DateTime.now();
    final buffer = StringBuffer();

    buffer.writeln('Spett.le $recipientEntity');
    buffer.writeln();
    buffer.writeln(
        'Oggetto: Opposizione al verbale n. $fineNumber del ${_dateFormat.format(fineDate)}');
    buffer.writeln();
    buffer.writeln('Il/La sottoscritto/a $senderName, con la presente,');
    buffer.writeln();
    buffer.writeln('COMUNICA');
    buffer.writeln();
    buffer.writeln(
        'di voler proporre opposizione al verbale in oggetto per i seguenti motivi:');
    buffer.writeln();
    buffer.writeln(mainIssue);
    buffer.writeln();

    if (supportingPoints.isNotEmpty) {
      buffer.writeln('A supporto di quanto sopra si evidenzia che:');
      for (var i = 0; i < supportingPoints.length; i++) {
        buffer.writeln('${i + 1}. ${supportingPoints[i]}');
      }
      buffer.writeln();
    }

    buffer.writeln('Si chiede pertanto l\'annullamento del verbale impugnato.');
    buffer.writeln();
    buffer.writeln('Distinti saluti.');
    buffer.writeln();
    buffer.writeln('________________, ${_longDateFormat.format(today)}');
    buffer.writeln();
    buffer.writeln(senderName);
    buffer.writeln('_______________________________');

    return FormattedDocument(
      title: 'Opposizione Verbale n. $fineNumber',
      body: buffer.toString(),
      shortSummary: mainIssue,
      issueCount: supportingPoints.length + 1,
      mainIssueType: 'generale',
    );
  }

  static String _generateShortSummary(List<AnalysisIssue> issues) {
    if (issues.isEmpty) return 'Nessun vizio rilevato';

    final types = <String>[];
    if (issues.any((i) => i.type == IssueType.formality)) {
      types.add('vizi di forma');
    }
    if (issues.any((i) => i.type == IssueType.process)) {
      types.add('vizi procedurali');
    }
    if (issues.any((i) => i.type == IssueType.substance)) {
      types.add('vizi di merito');
    }

    return 'Rilevati ${issues.length} problemi: ${types.join(", ")}';
  }

  static String _getMainIssueType(List<AnalysisIssue> issues) {
    if (issues.isEmpty) return 'nessuno';

    // Priority: substance > process > formality
    if (issues.any((i) => i.type == IssueType.substance)) return 'merito';
    if (issues.any((i) => i.type == IssueType.process)) return 'procedura';
    return 'forma';
  }
}

/// A properly formatted legal document
class FormattedDocument {
  final String title;
  final String body;
  final String shortSummary;
  final int issueCount;
  final String mainIssueType;

  const FormattedDocument({
    required this.title,
    required this.body,
    required this.shortSummary,
    required this.issueCount,
    required this.mainIssueType,
  });
}

/// Data needed to generate a complete ricorso
class RicorsoData {
  final String senderName;
  final String senderAddress;
  final String senderFiscalCode;
  final String senderPec;
  final String recipientEntity;
  final String recipientPec;
  final String fineNumber;
  final DateTime fineDate;
  final double fineAmount;
  final String plateNumber;
  final String violationDescription;
  final String? additionalNotes;

  const RicorsoData({
    required this.senderName,
    required this.senderAddress,
    required this.senderFiscalCode,
    required this.senderPec,
    required this.recipientEntity,
    required this.recipientPec,
    required this.fineNumber,
    required this.fineDate,
    required this.fineAmount,
    required this.plateNumber,
    required this.violationDescription,
    this.additionalNotes,
  });
}
