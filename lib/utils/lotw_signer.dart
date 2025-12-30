import 'package:flutter/services.dart';

class LotwSigner {
  static const MethodChannel _ch = MethodChannel('lotw_signer');

  /// Sign data using P12 certificate via platform channel
  /// Returns Base64-encoded signature
  static Future<String> sign({
    required String data,
    required Uint8List p12Bytes,
    required String password,
  }) async {
    final res = await _ch.invokeMethod<Map>('sign', {
      'data': data,
      'p12': p12Bytes,
      'password': password,
    });
    if (res == null) throw Exception('Null result from platform');
    final ok = res['ok'] == true;
    if (!ok) throw Exception(res['error'] ?? 'Unknown signing error');
    return res['signature_b64'] as String;
  }

  /// Extract certificate from P12 via platform channel
  /// Returns Base64-encoded DER certificate
  static Future<String> getCertificate({
    required Uint8List p12Bytes,
    required String password,
  }) async {
    final res = await _ch.invokeMethod<Map>('getCertificate', {
      'p12': p12Bytes,
      'password': password,
    });
    if (res == null) throw Exception('Null result from platform');
    final ok = res['ok'] == true;
    if (!ok) throw Exception(res['error'] ?? 'Unknown certificate error');
    return res['certificate'] as String;
  }
}
