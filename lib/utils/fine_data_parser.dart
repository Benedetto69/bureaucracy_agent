import 'package:flutter/foundation.dart';

/// Utility to extract fine data from OCR text
/// Optimized for Italian traffic fines (verbali di contestazione)
class FineDataParser {
  FineDataParser._();

  /// Parse OCR text and extract fine data
  static FineData? parse(String text) {
    if (text.isEmpty) return null;

    // Normalize text for better matching
    final cleanText = _normalizeOcrText(text);
    final lowerText = cleanText.toLowerCase();

    debugPrint('[FineDataParser] Parsing text (${text.length} chars)');

    final fineNumber = _extractFineNumber(cleanText);
    final amount = _extractAmount(cleanText, lowerText);
    final date = _extractDate(cleanText, lowerText);
    final plate = _extractPlateNumber(cleanText);

    debugPrint('[FineDataParser] Results: number=$fineNumber, amount=$amount, date=$date, plate=$plate');

    return FineData(
      fineNumber: fineNumber,
      amount: amount,
      notificationDate: date,
      plateNumber: plate,
    );
  }

  /// Normalize OCR text to fix common recognition errors
  static String _normalizeOcrText(String text) {
    return text
        // Fix common OCR errors
        .replaceAll(RegExp(r'[lI|](?=\d)'), '1') // l, I, | before digit -> 1
        .replaceAll(RegExp(r'(?<=\d)[lI|]'), '1') // l, I, | after digit -> 1
        .replaceAll(RegExp(r'[oO](?=\d{2})'), '0') // O before 2 digits -> 0
        .replaceAll(RegExp(r'(?<=\d)[oO](?=\d)'), '0') // O between digits -> 0
        .replaceAll(RegExp(r'\s+'), ' ') // Multiple spaces -> single
        .trim();
  }

  /// Extract fine/verbale number
  static String? _extractFineNumber(String text) {
    final patterns = [
      // Most specific patterns first
      RegExp(r'VERBALE\s*(?:N[.°]?|NR[.°]?|NUMERO)?\s*[:\s]*(\d{4,}[\w/\-]*)', caseSensitive: false),
      RegExp(r'N[.°]?\s*VERBALE\s*[:\s]*(\d{4,}[\w/\-]*)', caseSensitive: false),
      RegExp(r'PROT(?:OCOLLO)?[.\s]*(?:N[.°]?)?\s*[:\s]*(\d{4,}[\w/\-]*)', caseSensitive: false),
      RegExp(r'PRATICA\s*(?:N[.°]?)?\s*[:\s]*([\w\d]{4,}[\w/\-]*)', caseSensitive: false),
      RegExp(r'RIF(?:ERIMENTO)?[.\s]*[:\s]*(\d{4,}[\w/\-]*)', caseSensitive: false),
      // Fallback: any long number sequence that looks like a reference
      RegExp(r'(?:N[.°]?|NR[.°]?)\s*[:\s]*(\d{5,})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.group(1) != null) {
        final result = match.group(1)!.trim();
        debugPrint('[FineDataParser] Found fine number: $result');
        return result;
      }
    }
    return null;
  }

  /// Extract amount from text - improved for Italian fine formats
  static double? _extractAmount(String text, String lowerText) {
    // First, try to find amounts with specific labels (most reliable)
    final labeledPatterns = [
      // Italian fine specific labels
      RegExp(r'(?:IMPORTO|SOMMA)\s*(?:DA\s*)?(?:PAGARE|VERSARE)[:\s]*(?:EURO|EUR|[\u20AC€])?\s*(\d{1,4}[.,]\d{2})', caseSensitive: false),
      RegExp(r'(?:IMPORTO|SOMMA)\s*(?:DA\s*)?(?:PAGARE|VERSARE)[:\s]*(?:EURO|EUR|[\u20AC€])?\s*(\d{1,4})[,.\s]', caseSensitive: false),
      RegExp(r'SANZIONE\s*(?:PECUNIARIA|AMMINISTRATIVA)?[:\s]*(?:EURO|EUR|[\u20AC€])?\s*(\d{1,4}[.,]\d{2})', caseSensitive: false),
      RegExp(r'TOTALE\s*(?:DA\s*PAGARE)?[:\s]*(?:EURO|EUR|[\u20AC€])?\s*(\d{1,4}[.,]\d{2})', caseSensitive: false),
      RegExp(r'IMPORTO[:\s]*(?:EURO|EUR|[\u20AC€])?\s*(\d{1,4}[.,]\d{2})', caseSensitive: false),
      // With currency before amount
      RegExp(r'(?:EURO|EUR|[\u20AC€])\s*(\d{1,4}[.,]\d{2})', caseSensitive: false),
      RegExp(r'(?:EURO|EUR|[\u20AC€])\s*(\d{2,4})(?:[.,\s]|$)', caseSensitive: false),
      // Amount followed by euro
      RegExp(r'(\d{1,4}[.,]\d{2})\s*(?:EURO|EUR|[\u20AC€])', caseSensitive: false),
      RegExp(r'(\d{2,4})[.,]00\s*(?:EURO|EUR|[\u20AC€])', caseSensitive: false),
    ];

    for (final pattern in labeledPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.group(1) != null) {
        final amountStr = match.group(1)!
            .replaceAll(',', '.')
            .replaceAll(RegExp(r'\s'), '');
        var amount = double.tryParse(amountStr);

        // If no decimal part, might be missing .00
        if (amount != null && amount == amount.truncate() && amount > 10) {
          // Check if this looks like a whole number fine
          if (!amountStr.contains('.')) {
            // Keep as is, it's probably correct
          }
        }

        if (amount != null && amount >= 10 && amount <= 5000) {
          debugPrint('[FineDataParser] Found amount: $amount from "$amountStr"');
          return amount;
        }
      }
    }

    // Fallback: look for any reasonable amount pattern
    final fallbackPattern = RegExp(r'(\d{2,3})[.,](\d{2})');
    for (final match in fallbackPattern.allMatches(text)) {
      final whole = match.group(1)!;
      final decimal = match.group(2)!;
      final amount = double.tryParse('$whole.$decimal');
      if (amount != null && amount >= 20 && amount <= 2000) {
        // Check context - avoid dates like 15.03
        final start = match.start > 10 ? match.start - 10 : 0;
        final context = text.substring(start, match.start).toLowerCase();
        if (!context.contains('data') && !context.contains('/') && !context.contains('-')) {
          debugPrint('[FineDataParser] Found fallback amount: $amount');
          return amount;
        }
      }
    }

    return null;
  }

  /// Extract notification date - improved with more Italian patterns
  static DateTime? _extractDate(String text, String lowerText) {
    // First, try to find dates with specific labels (most reliable)
    final labeledDatePatterns = [
      // Notification date specific
      RegExp(r'DATA\s*(?:DI\s*)?NOTIFICA[:\s]*(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})', caseSensitive: false),
      RegExp(r'NOTIFICATO\s*(?:IL)?[:\s]*(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})', caseSensitive: false),
      RegExp(r'DATA\s*(?:DEL\s*)?VERBALE[:\s]*(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})', caseSensitive: false),
      RegExp(r'DATA\s*ACCERTAMENTO[:\s]*(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})', caseSensitive: false),
      RegExp(r'(?:DEL|IL|IN\s*DATA)[:\s]*(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})', caseSensitive: false),
      RegExp(r'GIORNO[:\s]*(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})', caseSensitive: false),
    ];

    for (final pattern in labeledDatePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final date = _parseMatchedDate(match.group(1)!, match.group(2)!, match.group(3)!);
        if (date != null) {
          debugPrint('[FineDataParser] Found labeled date: $date');
          return date;
        }
      }
    }

    // Try to find dates with Italian month names
    final months = {
      'gennaio': 1, 'febbraio': 2, 'marzo': 3, 'aprile': 4,
      'maggio': 5, 'giugno': 6, 'luglio': 7, 'agosto': 8,
      'settembre': 9, 'ottobre': 10, 'novembre': 11, 'dicembre': 12,
      'gen': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'mag': 5, 'giu': 6,
      'lug': 7, 'ago': 8, 'set': 9, 'ott': 10, 'nov': 11, 'dic': 12,
    };

    final textDatePattern = RegExp(
      r'(\d{1,2})\s*(gennaio|febbraio|marzo|aprile|maggio|giugno|luglio|agosto|settembre|ottobre|novembre|dicembre|gen|feb|mar|apr|mag|giu|lug|ago|set|ott|nov|dic)[.\s]*(\d{2,4})',
      caseSensitive: false,
    );

    final textMatch = textDatePattern.firstMatch(lowerText);
    if (textMatch != null) {
      final day = int.tryParse(textMatch.group(1)!);
      final monthName = textMatch.group(2)!.toLowerCase();
      var year = int.tryParse(textMatch.group(3)!);

      if (day != null && year != null && months.containsKey(monthName)) {
        if (year < 100) year += 2000;
        final date = _tryCreateDate(year, months[monthName]!, day);
        if (date != null) {
          debugPrint('[FineDataParser] Found text date: $date');
          return date;
        }
      }
    }

    // Fallback: any date in dd/mm/yyyy format
    final genericDatePattern = RegExp(r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})');
    final allDates = <DateTime>[];

    for (final match in genericDatePattern.allMatches(text)) {
      final date = _parseMatchedDate(match.group(1)!, match.group(2)!, match.group(3)!);
      if (date != null) {
        allDates.add(date);
      }
    }

    // Return the most recent valid date (likely the notification date)
    if (allDates.isNotEmpty) {
      allDates.sort((a, b) => b.compareTo(a));
      debugPrint('[FineDataParser] Found fallback date: ${allDates.first}');
      return allDates.first;
    }

    return null;
  }

  static DateTime? _parseMatchedDate(String dayStr, String monthStr, String yearStr) {
    final day = int.tryParse(dayStr);
    final month = int.tryParse(monthStr);
    var year = int.tryParse(yearStr);

    if (day == null || month == null || year == null) return null;
    if (year < 100) year += 2000;

    return _tryCreateDate(year, month, day);
  }

  static DateTime? _tryCreateDate(int year, int month, int day) {
    // Validate ranges
    if (day < 1 || day > 31 || month < 1 || month > 12) return null;
    if (year < 2020 || year > 2030) return null;

    try {
      final date = DateTime(year, month, day);
      // Check if date is valid (handles month/day overflow)
      if (date.day != day || date.month != month) return null;
      // Check if date is not in the future and not too old
      if (date.isAfter(DateTime.now().add(const Duration(days: 1)))) return null;
      if (date.isBefore(DateTime(2020))) return null;
      return date;
    } catch (_) {
      return null;
    }
  }

  /// Extract plate number
  static String? _extractPlateNumber(String text) {
    final patterns = [
      // With label (most reliable)
      RegExp(r'TARGA[:\s]+([A-Z]{2}\s*\d{3}\s*[A-Z]{2})', caseSensitive: false),
      RegExp(r'TARGATO[:\s]+([A-Z]{2}\s*\d{3}\s*[A-Z]{2})', caseSensitive: false),
      RegExp(r'VEICOLO[:\s]+.*?([A-Z]{2}\s*\d{3}\s*[A-Z]{2})', caseSensitive: false),
      // Standalone Italian plate format
      RegExp(r'\b([A-Z]{2}\s*\d{3}\s*[A-Z]{2})\b', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.group(1) != null) {
        final plate = match.group(1)!.replaceAll(RegExp(r'\s+'), '').toUpperCase();
        debugPrint('[FineDataParser] Found plate: $plate');
        return plate;
      }
    }
    return null;
  }
}

/// Parsed fine data
class FineData {
  final String? fineNumber;
  final double? amount;
  final DateTime? notificationDate;
  final String? plateNumber;

  const FineData({
    this.fineNumber,
    this.amount,
    this.notificationDate,
    this.plateNumber,
  });

  bool get hasAnyData =>
      fineNumber != null ||
      amount != null ||
      notificationDate != null ||
      plateNumber != null;

  @override
  String toString() =>
      'FineData(fineNumber: $fineNumber, amount: $amount, date: $notificationDate, plate: $plateNumber)';
}
