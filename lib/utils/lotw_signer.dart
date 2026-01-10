import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pointycastle/export.dart';
import 'package:asn1lib/asn1lib.dart';

class LotwSigner {
  static const MethodChannel _ch = MethodChannel('lotw_signer');

  /// Sign data using P12 certificate
  /// Returns Base64-encoded signature
  static Future<String> sign({
    required String data,
    required Uint8List p12Bytes,
    required String password,
  }) async {
    if (Platform.isAndroid) {
      return _signViaPlatformChannel(data, p12Bytes, password);
    } else {
      return _signPureDart(data, p12Bytes, password);
    }
  }

  /// Extract certificate from P12
  /// Returns Base64-encoded DER certificate
  static Future<String> getCertificate({
    required Uint8List p12Bytes,
    required String password,
  }) async {
    if (Platform.isAndroid) {
      return _getCertViaPlatformChannel(p12Bytes, password);
    } else {
      return _getCertPureDart(p12Bytes, password);
    }
  }

  // ============ Platform Channel Methods (Android) ============

  static Future<String> _signViaPlatformChannel(
    String data,
    Uint8List p12Bytes,
    String password,
  ) async {
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

  static Future<String> _getCertViaPlatformChannel(
    Uint8List p12Bytes,
    String password,
  ) async {
    final res = await _ch.invokeMethod<Map>('getCertificate', {
      'p12': p12Bytes,
      'password': password,
    });
    if (res == null) throw Exception('Null result from platform');
    final ok = res['ok'] == true;
    if (!ok) throw Exception(res['error'] ?? 'Unknown certificate error');
    return res['certificate'] as String;
  }

  // ============ Pure Dart Methods (Windows/Desktop) ============

  static Future<String> _signPureDart(
    String data,
    Uint8List p12Bytes,
    String password,
  ) async {
    final p12 = _Pkcs12Parser.parse(p12Bytes, password);
    if (p12.privateKey == null) {
      throw Exception('No private key found in P12');
    }

    // Sign with SHA1withRSA (OID 1.3.14.3.2.26 = 06052b0e03021a)
    final signer = RSASigner(SHA1Digest(), '06052b0e03021a');
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(p12.privateKey!));

    final dataBytes = Uint8List.fromList(utf8.encode(data));
    final signature = signer.generateSignature(dataBytes);

    return base64.encode(signature.bytes);
  }

  static Future<String> _getCertPureDart(
    Uint8List p12Bytes,
    String password,
  ) async {
    final p12 = _Pkcs12Parser.parse(p12Bytes, password);
    if (p12.certificate == null) {
      throw Exception('No certificate found in P12');
    }
    return base64.encode(p12.certificate!);
  }
}

/// Parsed PKCS#12 contents
class _Pkcs12Contents {
  final RSAPrivateKey? privateKey;
  final Uint8List? certificate;

  _Pkcs12Contents({this.privateKey, this.certificate});
}

/// PKCS#12 Parser for extracting keys and certificates
class _Pkcs12Parser {
  // OIDs
  static const oidPkcs12PbeWithSha1And3KeyTripleDesCbc = '1.2.840.113549.1.12.1.3';
  static const oidPkcs12PbeWithSha1And40BitRc2Cbc = '1.2.840.113549.1.12.1.6';
  static const oidPbeWithSha1AndDesCbc = '1.2.840.113549.1.5.10';
  static const oidPbes2 = '1.2.840.113549.1.5.13';
  static const oidPbkdf2 = '1.2.840.113549.1.5.12';
  static const oidAes128Cbc = '2.16.840.1.101.3.4.1.2';
  static const oidAes256Cbc = '2.16.840.1.101.3.4.1.42';
  static const oidDesEdeCbc = '1.2.840.113549.3.7';
  static const oidPkcs8ShroudedKeyBag = '1.2.840.113549.1.12.10.1.2';
  static const oidCertBag = '1.2.840.113549.1.12.10.1.3';
  static const oidX509Cert = '1.2.840.113549.1.9.22.1';
  static const oidRsaEncryption = '1.2.840.113549.1.1.1';
  static const oidData = '1.2.840.113549.1.7.1';
  static const oidEncryptedData = '1.2.840.113549.1.7.6';
  static const oidHmacSha1 = '1.2.840.113549.2.7';
  static const oidHmacSha256 = '1.2.840.113549.2.9';

  static _Pkcs12Contents parse(Uint8List p12Bytes, String password) {
    RSAPrivateKey? privateKey;
    Uint8List? certificate;

    try {
      print('P12 Parser: Starting parse, ${p12Bytes.length} bytes');
      final parser = ASN1Parser(p12Bytes);
      final pfx = parser.nextObject() as ASN1Sequence;
      print('P12 Parser: PFX has ${pfx.elements.length} elements');

      // PFX structure: version, authSafe, macData (optional)
      final authSafe = pfx.elements[1] as ASN1Sequence;
      final contentType = (authSafe.elements[0] as ASN1ObjectIdentifier).oi.join('.');
      print('P12 Parser: Content type: $contentType');

      if (contentType != oidData) {
        throw Exception('Unexpected content type: $contentType');
      }

      // Get the AuthenticatedSafe content
      final content = authSafe.elements[1] as ASN1Object;
      print('P12 Parser: Content tag: 0x${content.tag.toRadixString(16)}');
      Uint8List authSafeContent;

      if (content is ASN1OctetString) {
        authSafeContent = content.valueBytes();
      } else if (content.tag == 0xA0) {
        // Context-specific [0]
        final inner = ASN1Parser(content.valueBytes()).nextObject();
        if (inner is ASN1OctetString) {
          authSafeContent = inner.valueBytes();
        } else {
          authSafeContent = content.valueBytes();
        }
      } else {
        authSafeContent = content.valueBytes();
      }
      print('P12 Parser: AuthSafe content: ${authSafeContent.length} bytes');

      // Parse AuthenticatedSafe (sequence of ContentInfo)
      final authSafeParser = ASN1Parser(authSafeContent);
      final authSafeSeq = authSafeParser.nextObject() as ASN1Sequence;
      print('P12 Parser: AuthSafe has ${authSafeSeq.elements.length} content infos');

      for (var i = 0; i < authSafeSeq.elements.length; i++) {
        final contentInfo = authSafeSeq.elements[i];
        if (contentInfo is! ASN1Sequence) {
          print('P12 Parser: ContentInfo[$i] is not a sequence');
          continue;
        }

        final bagContentType = (contentInfo.elements[0] as ASN1ObjectIdentifier).oi.join('.');
        print('P12 Parser: ContentInfo[$i] type: $bagContentType');

        if (bagContentType == oidData) {
          // Unencrypted data - may contain cert bag or key bag
          final dataContent = _extractContextContent(contentInfo.elements[1]);
          print('P12 Parser: Processing unencrypted data: ${dataContent.length} bytes');
          _processSafeBags(dataContent, password, (key, cert) {
            if (key != null) {
              print('P12 Parser: Found private key in unencrypted data');
              privateKey = key;
            }
            if (cert != null && certificate == null) {
              print('P12 Parser: Found certificate in unencrypted data (keeping first)');
              certificate = cert;
            }
          });
        } else if (bagContentType == oidEncryptedData) {
          // Encrypted data
          final encData = _extractContextContent(contentInfo.elements[1]);
          print('P12 Parser: Decrypting encrypted data: ${encData.length} bytes');
          final decrypted = _decryptEncryptedData(encData, password);
          if (decrypted != null) {
            print('P12 Parser: Decrypted to ${decrypted.length} bytes');
            _processSafeBags(decrypted, password, (key, cert) {
              if (key != null) {
                print('P12 Parser: Found private key in encrypted data');
                privateKey = key;
              }
              if (cert != null && certificate == null) {
                print('P12 Parser: Found certificate in encrypted data (keeping first)');
                certificate = cert;
              }
            });
          } else {
            print('P12 Parser: Decryption failed');
          }
        }
      }

      print('P12 Parser: Done. Key found: ${privateKey != null}, Cert found: ${certificate != null}');
    } catch (e, stack) {
      print('P12 Parser Error: $e');
      print('Stack: $stack');
      throw Exception('Failed to parse P12: $e');
    }

    return _Pkcs12Contents(privateKey: privateKey, certificate: certificate);
  }

  static Uint8List _extractContextContent(ASN1Object obj) {
    if (obj is ASN1OctetString) {
      return obj.valueBytes();
    }
    if (obj.tag == 0xA0) {
      final parser = ASN1Parser(obj.valueBytes());
      final inner = parser.nextObject();
      if (inner is ASN1OctetString) {
        return inner.valueBytes();
      }
      return obj.valueBytes();
    }
    return obj.valueBytes();
  }

  static void _processSafeBags(
    Uint8List data,
    String password,
    void Function(RSAPrivateKey?, Uint8List?) callback,
  ) {
    try {
      final parser = ASN1Parser(data);
      final bags = parser.nextObject() as ASN1Sequence;
      print('P12 Parser: Processing ${bags.elements.length} safe bags');

      for (var i = 0; i < bags.elements.length; i++) {
        final bag = bags.elements[i];
        if (bag is! ASN1Sequence) {
          print('P12 Parser: Bag[$i] is not a sequence');
          continue;
        }

        final bagId = (bag.elements[0] as ASN1ObjectIdentifier).oi.join('.');
        print('P12 Parser: Bag[$i] type: $bagId');
        final bagValue = _extractContextContent(bag.elements[1]);

        if (bagId == oidPkcs8ShroudedKeyBag) {
          // Encrypted private key
          print('P12 Parser: Found shrouded key bag, decrypting...');
          final key = _decryptPrivateKey(bagValue, password);
          if (key != null) {
            print('P12 Parser: Key decryption successful');
            callback(key, null);
          } else {
            print('P12 Parser: Key decryption failed');
          }
        } else if (bagId == oidCertBag) {
          // Certificate bag
          print('P12 Parser: Found cert bag');
          final cert = _extractCertificate(bagValue);
          if (cert != null) callback(null, cert);
        }
      }
    } catch (e) {
      print('P12 Parser: Error processing safe bags: $e');
    }
  }

  static RSAPrivateKey? _decryptPrivateKey(Uint8List encryptedData, String password) {
    try {
      final parser = ASN1Parser(encryptedData);
      final encKeyInfo = parser.nextObject() as ASN1Sequence;

      final algId = encKeyInfo.elements[0] as ASN1Sequence;
      final algOid = (algId.elements[0] as ASN1ObjectIdentifier).oi.join('.');
      print('P12 Parser: Key encryption algorithm: $algOid');
      final encData = (encKeyInfo.elements[1] as ASN1OctetString).valueBytes();

      Uint8List? decrypted;

      if (algOid == oidPkcs12PbeWithSha1And3KeyTripleDesCbc) {
        print('P12 Parser: Using PBE-SHA1-3DES');
        final params = algId.elements[1] as ASN1Sequence;
        final salt = (params.elements[0] as ASN1OctetString).valueBytes();
        final iterations = (params.elements[1] as ASN1Integer).valueAsBigInteger.toInt();
        print('P12 Parser: Salt: ${salt.length} bytes, iterations: $iterations');
        decrypted = _decryptPbe3Des(encData, password, salt, iterations);
      } else if (algOid == oidPbes2) {
        print('P12 Parser: Using PBES2');
        decrypted = _decryptPbes2(encData, password, algId.elements[1] as ASN1Sequence);
      } else {
        print('P12 Parser: Unknown encryption algorithm: $algOid');
      }

      if (decrypted == null) {
        print('P12 Parser: Decryption returned null');
        return null;
      }

      print('P12 Parser: Decrypted key data: ${decrypted.length} bytes');
      // Parse PKCS#8 PrivateKeyInfo
      final key = _parsePrivateKeyInfo(decrypted);
      if (key == null) {
        print('P12 Parser: Failed to parse PKCS#8 PrivateKeyInfo');
      }
      return key;
    } catch (e) {
      print('P12 Parser: Error decrypting private key: $e');
      return null;
    }
  }

  static Uint8List? _decryptEncryptedData(Uint8List data, String password) {
    try {
      final parser = ASN1Parser(data);
      final encData = parser.nextObject() as ASN1Sequence;

      // EncryptedData: version, encryptedContentInfo
      final encContentInfo = encData.elements[1] as ASN1Sequence;
      final algId = encContentInfo.elements[1] as ASN1Sequence;
      final algOid = (algId.elements[0] as ASN1ObjectIdentifier).oi.join('.');
      print('P12 Parser: EncryptedData algorithm: $algOid');

      Uint8List encContent;
      final contentElement = encContentInfo.elements[2];
      if (contentElement is ASN1OctetString) {
        encContent = contentElement.valueBytes();
      } else if (contentElement.tag == 0x80) {
        encContent = contentElement.valueBytes();
      } else {
        encContent = _extractContextContent(contentElement);
      }
      print('P12 Parser: Encrypted content: ${encContent.length} bytes');

      if (algOid == oidPkcs12PbeWithSha1And3KeyTripleDesCbc) {
        print('P12 Parser: Using PBE-SHA1-3DES for encrypted data');
        final params = algId.elements[1] as ASN1Sequence;
        final salt = (params.elements[0] as ASN1OctetString).valueBytes();
        final iterations = (params.elements[1] as ASN1Integer).valueAsBigInteger.toInt();
        return _decryptPbe3Des(encContent, password, salt, iterations);
      } else if (algOid == oidPkcs12PbeWithSha1And40BitRc2Cbc) {
        print('P12 Parser: Using PBE-SHA1-RC2-40 for encrypted data');
        final params = algId.elements[1] as ASN1Sequence;
        final salt = (params.elements[0] as ASN1OctetString).valueBytes();
        final iterations = (params.elements[1] as ASN1Integer).valueAsBigInteger.toInt();
        return _decryptPbeRc2(encContent, password, salt, iterations);
      } else if (algOid == oidPbes2) {
        print('P12 Parser: Using PBES2 for encrypted data');
        return _decryptPbes2(encContent, password, algId.elements[1] as ASN1Sequence);
      }

      print('P12 Parser: Unknown encryption algorithm for encrypted data');
      return null;
    } catch (e) {
      print('P12 Parser: Error decrypting encrypted data: $e');
      return null;
    }
  }

  static Uint8List? _decryptPbe3Des(
    Uint8List data,
    String password,
    Uint8List salt,
    int iterations,
  ) {
    try {
      // Derive key and IV using PKCS#12 key derivation
      final passwordBytes = _passwordToBytes(password);
      final key = _pkcs12Derive(passwordBytes, salt, iterations, 1, 24); // 24 bytes for 3DES
      final iv = _pkcs12Derive(passwordBytes, salt, iterations, 2, 8); // 8 bytes IV

      // Decrypt with 3DES-CBC
      final cipher = CBCBlockCipher(DESedeEngine());
      cipher.init(false, ParametersWithIV(KeyParameter(key), iv));

      final decrypted = Uint8List(data.length);
      var offset = 0;
      while (offset < data.length) {
        offset += cipher.processBlock(data, offset, decrypted, offset);
      }

      // Remove PKCS#7 padding
      return _removePadding(decrypted);
    } catch (e) {
      return null;
    }
  }

  static Uint8List? _decryptPbeRc2(
    Uint8List data,
    String password,
    Uint8List salt,
    int iterations,
  ) {
    try {
      final passwordBytes = _passwordToBytes(password);
      final key = _pkcs12Derive(passwordBytes, salt, iterations, 1, 5); // 40 bits = 5 bytes
      final iv = _pkcs12Derive(passwordBytes, salt, iterations, 2, 8);

      final cipher = CBCBlockCipher(RC2Engine());
      cipher.init(false, ParametersWithIV(KeyParameter(key), iv));

      final decrypted = Uint8List(data.length);
      var offset = 0;
      while (offset < data.length) {
        offset += cipher.processBlock(data, offset, decrypted, offset);
      }

      return _removePadding(decrypted);
    } catch (e) {
      return null;
    }
  }

  static Uint8List? _decryptPbes2(
    Uint8List data,
    String password,
    ASN1Sequence params,
  ) {
    try {
      final kdfParams = params.elements[0] as ASN1Sequence;
      final encParams = params.elements[1] as ASN1Sequence;

      final kdfAlg = (kdfParams.elements[0] as ASN1ObjectIdentifier).oi.join('.');
      print('P12 Parser: PBES2 KDF algorithm: $kdfAlg');
      if (kdfAlg != oidPbkdf2) {
        print('P12 Parser: Unknown KDF algorithm');
        return null;
      }

      final pbkdf2Params = kdfParams.elements[1] as ASN1Sequence;
      final salt = (pbkdf2Params.elements[0] as ASN1OctetString).valueBytes();
      final iterations = (pbkdf2Params.elements[1] as ASN1Integer).valueAsBigInteger.toInt();
      print('P12 Parser: PBKDF2 salt: ${salt.length} bytes, iterations: $iterations');

      // Check for PRF algorithm (optional, defaults to HMAC-SHA1)
      String prfAlg = oidHmacSha1;
      int? explicitKeyLength;
      for (var i = 2; i < pbkdf2Params.elements.length; i++) {
        final elem = pbkdf2Params.elements[i];
        if (elem is ASN1Integer) {
          explicitKeyLength = elem.valueAsBigInteger.toInt();
          print('P12 Parser: Explicit key length: $explicitKeyLength');
        } else if (elem is ASN1Sequence) {
          prfAlg = (elem.elements[0] as ASN1ObjectIdentifier).oi.join('.');
          print('P12 Parser: PRF algorithm: $prfAlg');
        }
      }

      final encAlg = (encParams.elements[0] as ASN1ObjectIdentifier).oi.join('.');
      final iv = (encParams.elements[1] as ASN1OctetString).valueBytes();
      print('P12 Parser: PBES2 encryption: $encAlg, IV: ${iv.length} bytes');

      int keyLength;
      BlockCipher cipher;

      if (encAlg == oidAes128Cbc) {
        keyLength = 16;
        cipher = CBCBlockCipher(AESEngine());
      } else if (encAlg == oidAes256Cbc) {
        keyLength = 32;
        cipher = CBCBlockCipher(AESEngine());
      } else if (encAlg == oidDesEdeCbc) {
        keyLength = 24;
        cipher = CBCBlockCipher(DESedeEngine());
      } else {
        print('P12 Parser: Unknown PBES2 encryption algorithm: $encAlg');
        return null;
      }

      // Use explicit key length if provided
      if (explicitKeyLength != null) {
        keyLength = explicitKeyLength;
      }

      // Select hash for PBKDF2 based on PRF
      Digest hashDigest;
      int hmacBlockSize;
      if (prfAlg == oidHmacSha256) {
        hashDigest = SHA256Digest();
        hmacBlockSize = 64;
      } else {
        // Default to SHA1
        hashDigest = SHA1Digest();
        hmacBlockSize = 64;
      }

      // PBKDF2
      final pbkdf2 = PBKDF2KeyDerivator(HMac(hashDigest, hmacBlockSize));
      pbkdf2.init(Pbkdf2Parameters(salt, iterations, keyLength));
      final key = pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
      print('P12 Parser: Derived key: ${key.length} bytes');

      cipher.init(false, ParametersWithIV(KeyParameter(key), iv));

      final decrypted = Uint8List(data.length);
      var offset = 0;
      while (offset < data.length) {
        offset += cipher.processBlock(data, offset, decrypted, offset);
      }

      final result = _removePadding(decrypted);
      print('P12 Parser: Decrypted PBES2: ${result?.length ?? 0} bytes');
      return result;
    } catch (e) {
      print('P12 Parser: Error in PBES2 decryption: $e');
      return null;
    }
  }

  static Uint8List _passwordToBytes(String password) {
    // PKCS#12 uses BMPString (UTF-16BE) with null terminator
    final result = <int>[];
    for (var i = 0; i < password.length; i++) {
      final c = password.codeUnitAt(i);
      result.add((c >> 8) & 0xFF);
      result.add(c & 0xFF);
    }
    result.add(0);
    result.add(0);
    return Uint8List.fromList(result);
  }

  static Uint8List _pkcs12Derive(
    Uint8List password,
    Uint8List salt,
    int iterations,
    int id,
    int length,
  ) {
    const u = 20; // SHA1 hash length
    const v = 64; // SHA1 block size

    // Construct D
    final d = Uint8List(v);
    for (var i = 0; i < v; i++) {
      d[i] = id;
    }

    // Construct S
    final sLen = v * ((salt.length + v - 1) ~/ v);
    final s = Uint8List(sLen);
    for (var i = 0; i < sLen; i++) {
      s[i] = salt[i % salt.length];
    }

    // Construct P
    final pLen = v * ((password.length + v - 1) ~/ v);
    final p = Uint8List(pLen);
    for (var i = 0; i < pLen; i++) {
      p[i] = password[i % password.length];
    }

    // I = S || P
    final input = Uint8List(sLen + pLen);
    input.setRange(0, sLen, s);
    input.setRange(sLen, sLen + pLen, p);

    final digest = SHA1Digest();
    final result = <int>[];

    while (result.length < length) {
      // A = H^iterations(D || I)
      var a = Uint8List(v + input.length);
      a.setRange(0, v, d);
      a.setRange(v, v + input.length, input);

      for (var i = 0; i < iterations; i++) {
        digest.reset();
        a = Uint8List(u);
        final temp = Uint8List(v + input.length);
        temp.setRange(0, v, d);
        temp.setRange(v, v + input.length, input);
        if (i == 0) {
          digest.update(temp, 0, temp.length);
        } else {
          digest.update(a, 0, a.length);
        }
        digest.doFinal(a, 0);

        if (i == 0) {
          for (var j = 1; j < iterations; j++) {
            digest.reset();
            final prev = Uint8List.fromList(a);
            digest.update(prev, 0, prev.length);
            digest.doFinal(a, 0);
          }
          break;
        }
      }

      result.addAll(a);

      if (result.length >= length) break;

      // B = A repeated to fill v bytes
      final b = Uint8List(v);
      for (var i = 0; i < v; i++) {
        b[i] = a[i % u];
      }

      // I = I + B + 1 (treating each v-byte block as a big integer)
      for (var i = 0; i < input.length ~/ v; i++) {
        var carry = 1;
        for (var j = v - 1; j >= 0; j--) {
          final idx = i * v + j;
          carry += input[idx] + b[j];
          input[idx] = carry & 0xFF;
          carry >>= 8;
        }
      }
    }

    return Uint8List.fromList(result.sublist(0, length));
  }

  static Uint8List? _removePadding(Uint8List data) {
    if (data.isEmpty) return null;
    final padLen = data[data.length - 1];
    if (padLen > data.length || padLen > 16) return data;
    // Verify padding
    for (var i = 0; i < padLen; i++) {
      if (data[data.length - 1 - i] != padLen) return data;
    }
    return Uint8List.fromList(data.sublist(0, data.length - padLen));
  }

  static RSAPrivateKey? _parsePrivateKeyInfo(Uint8List data) {
    try {
      print('P12 Parser: Parsing PKCS#8, data length: ${data.length}');
      print('P12 Parser: First bytes: ${data.take(20).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

      final parser = ASN1Parser(data);
      final keyInfo = parser.nextObject() as ASN1Sequence;
      print('P12 Parser: KeyInfo has ${keyInfo.elements.length} elements');

      for (var i = 0; i < keyInfo.elements.length; i++) {
        print('P12 Parser: KeyInfo[$i] tag: 0x${keyInfo.elements[i].tag.toRadixString(16)}, type: ${keyInfo.elements[i].runtimeType}');
      }

      // PrivateKeyInfo: version, algorithm, privateKey
      final privateKeyOctet = keyInfo.elements[2] as ASN1OctetString;
      print('P12 Parser: PrivateKey octet: ${privateKeyOctet.valueBytes().length} bytes');

      final keyParser = ASN1Parser(privateKeyOctet.valueBytes());
      final rsaKey = keyParser.nextObject() as ASN1Sequence;
      print('P12 Parser: RSAKey has ${rsaKey.elements.length} elements');

      // RSAPrivateKey: version, n, e, d, p, q, dp, dq, qInv
      final n = (rsaKey.elements[1] as ASN1Integer).valueAsBigInteger;
      final e = (rsaKey.elements[2] as ASN1Integer).valueAsBigInteger;
      final d = (rsaKey.elements[3] as ASN1Integer).valueAsBigInteger;
      final p = (rsaKey.elements[4] as ASN1Integer).valueAsBigInteger;
      final q = (rsaKey.elements[5] as ASN1Integer).valueAsBigInteger;

      print('P12 Parser: RSA key parsed successfully');
      return RSAPrivateKey(n, d, p, q);
    } catch (e) {
      print('P12 Parser: Error parsing PKCS#8: $e');
      return null;
    }
  }

  static Uint8List? _extractCertificate(Uint8List data) {
    try {
      final parser = ASN1Parser(data);
      final certBag = parser.nextObject() as ASN1Sequence;

      final certId = (certBag.elements[0] as ASN1ObjectIdentifier).oi.join('.');
      if (certId != oidX509Cert) return null;

      final certValue = _extractContextContent(certBag.elements[1]);
      return certValue;
    } catch (e) {
      return null;
    }
  }
}
