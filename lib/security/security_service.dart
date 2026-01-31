import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SecurityServiceException implements Exception {
  final String message;

  SecurityServiceException(this.message);

  @override
  String toString() => 'SecurityServiceException: $message';
}

class SecurityService {
  static const MethodChannel _channel =
      MethodChannel('bureaucracy_agent/security');
  static const String _expectedSignature =
      '/9BffBaoarx2Z5ywPACIxJXoXrNlMm1PW2ej3hB6MgU=';

  static Future<void> enforceDeviceIntegrity() async {
    if (kDebugMode) {
      return;
    }

    final compromised = await _isDeviceCompromised();
    if (compromised) {
      throw SecurityServiceException('Dispositivo compromesso rilevato (root/jailbreak).');
    }

    // Skip signature validation for iOS App Store/TestFlight builds
    // Apple re-signs the app, making fingerprint validation impossible.
    // App Store integrity is guaranteed by Apple's code signing.
    final isAppStoreOrTestFlight = await _isAppStoreOrTestFlight();
    if (isAppStoreOrTestFlight) {
      return;
    }

    final fingerprint = await _channel.invokeMethod<String>('getSigningFingerprint');
    if (fingerprint == null || fingerprint.isEmpty) {
      throw SecurityServiceException('Impossibile leggere la firma binaria.');
    }
    if (fingerprint != _expectedSignature) {
      throw SecurityServiceException('Firma binaria non valida: possibile manomissione.');
    }
  }

  static Future<bool> _isAppStoreOrTestFlight() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAppStoreOrTestFlight');
      return result ?? false;
    } catch (_) {
      // If method not implemented, assume it might be App Store
      return true;
    }
  }

  static Future<bool> _isDeviceCompromised() async {
    final compromised = await _channel.invokeMethod<bool>('isDeviceCompromised');
    return compromised ?? false;
  }
}
