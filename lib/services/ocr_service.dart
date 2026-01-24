import 'package:flutter/services.dart';

/// Thin wrapper around native OCR implementations.
///
/// iOS: Vision (VNRecognizeTextRequest) via AppDelegate method channel.
/// Android/Web/Desktop: not implemented (caller should handle fallback).
class OcrService {
  static const MethodChannel _channel = MethodChannel('bureaucracy_agent/ocr');

  static Future<String> recognizeText(String imagePath) async {
    final result = await _channel.invokeMethod<String>(
      'recognizeText',
      {'path': imagePath},
    );
    return (result ?? '').trim();
  }
}

