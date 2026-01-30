import 'dart:typed_data';

/// Image validation result
class ImageValidationResult {
  final bool isValid;
  final String? mimeType;
  final String? error;

  const ImageValidationResult._({
    required this.isValid,
    this.mimeType,
    this.error,
  });

  factory ImageValidationResult.valid(String mimeType) =>
      ImageValidationResult._(isValid: true, mimeType: mimeType);

  factory ImageValidationResult.invalid(String error) =>
      ImageValidationResult._(isValid: false, error: error);
}

/// Validates image files by checking magic bytes
class ImageValidator {
  ImageValidator._();

  /// Maximum allowed file size (10 MB)
  static const int maxFileSize = 10 * 1024 * 1024;

  /// Minimum file size (at least some bytes for headers)
  static const int minFileSize = 8;

  /// JPEG magic bytes: FF D8 FF
  static const List<int> jpegMagicBytes = [0xFF, 0xD8, 0xFF];

  /// PNG magic bytes: 89 50 4E 47 0D 0A 1A 0A
  static const List<int> pngMagicBytes = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

  /// HEIC magic bytes (check for 'ftyp' box with heic/mif1/msf1)
  static const List<int> ftypMagicBytes = [0x66, 0x74, 0x79, 0x70]; // 'ftyp'

  /// Validate image bytes
  static ImageValidationResult validate(Uint8List bytes) {
    // Check file size
    if (bytes.length < minFileSize) {
      return ImageValidationResult.invalid(
        'File troppo piccolo per essere un\'immagine valida',
      );
    }

    if (bytes.length > maxFileSize) {
      return ImageValidationResult.invalid(
        'File troppo grande (max ${maxFileSize ~/ (1024 * 1024)} MB)',
      );
    }

    // Check for JPEG
    if (_matchesMagicBytes(bytes, jpegMagicBytes)) {
      return ImageValidationResult.valid('image/jpeg');
    }

    // Check for PNG
    if (_matchesMagicBytes(bytes, pngMagicBytes)) {
      return ImageValidationResult.valid('image/png');
    }

    // Check for HEIC (common on iOS)
    if (_isHeicImage(bytes)) {
      return ImageValidationResult.valid('image/heic');
    }

    return ImageValidationResult.invalid(
      'Formato immagine non supportato. Usa JPEG, PNG o HEIC.',
    );
  }

  /// Check if bytes start with the given magic bytes
  static bool _matchesMagicBytes(Uint8List bytes, List<int> magic) {
    if (bytes.length < magic.length) return false;

    for (var i = 0; i < magic.length; i++) {
      if (bytes[i] != magic[i]) return false;
    }
    return true;
  }

  /// Check for HEIC/HEIF format (common on iOS)
  /// HEIC files have 'ftyp' box at offset 4, followed by brand
  static bool _isHeicImage(Uint8List bytes) {
    if (bytes.length < 12) return false;

    // Check for 'ftyp' at offset 4
    if (bytes[4] != 0x66 || // 'f'
        bytes[5] != 0x74 || // 't'
        bytes[6] != 0x79 || // 'y'
        bytes[7] != 0x70) { // 'p'
      return false;
    }

    // Check for HEIC brands: heic, heix, mif1, msf1
    final brand = String.fromCharCodes(bytes.sublist(8, 12));
    return brand == 'heic' ||
        brand == 'heix' ||
        brand == 'mif1' ||
        brand == 'msf1' ||
        brand == 'hevc';
  }

  /// Quick check if bytes look like a valid image
  static bool isValidImage(Uint8List bytes) {
    return validate(bytes).isValid;
  }

  /// Get MIME type from bytes, or null if invalid
  static String? getMimeType(Uint8List bytes) {
    return validate(bytes).mimeType;
  }
}
