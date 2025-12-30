package com.example.qlogger_ui

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayInputStream
import java.security.KeyStore
import java.security.PrivateKey
import java.security.Signature
import android.util.Base64

class MainActivity: FlutterActivity() {
    private val CHANNEL = "lotw_signer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sign" -> {
                        try {
                            val data = call.argument<String>("data") ?: ""
                            val p12 = call.argument<ByteArray>("p12") ?: ByteArray(0)
                            val password = call.argument<String>("password") ?: ""

                            if (data.isEmpty()) throw IllegalArgumentException("data is empty")
                            if (p12.isEmpty()) throw IllegalArgumentException("p12 is empty")

                            val signatureB64 = signWithPkcs12(p12, password, data)
                            result.success(mapOf("ok" to true, "signature_b64" to signatureB64))
                        } catch (e: Exception) {
                            result.success(mapOf("ok" to false, "error" to (e.message ?: e.toString())))
                        }
                    }
                    "getCertificate" -> {
                        try {
                            val p12 = call.argument<ByteArray>("p12") ?: ByteArray(0)
                            val password = call.argument<String>("password") ?: ""

                            if (p12.isEmpty()) throw IllegalArgumentException("p12 is empty")

                            val certB64 = getCertificateFromPkcs12(p12, password)
                            result.success(mapOf("ok" to true, "certificate" to certB64))
                        } catch (e: Exception) {
                            result.success(mapOf("ok" to false, "error" to (e.message ?: e.toString())))
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun signWithPkcs12(p12Bytes: ByteArray, password: String, data: String): String {
        val ks = KeyStore.getInstance("PKCS12")
        // Empty string password is valid for PKCS12
        ks.load(ByteArrayInputStream(p12Bytes), password.toCharArray())

        val aliases = ks.aliases()
        if (!aliases.hasMoreElements()) throw IllegalStateException("No alias in PKCS12")

        val alias = aliases.nextElement()
        val key = ks.getKey(alias, password.toCharArray()) as? PrivateKey
            ?: throw IllegalStateException("No private key for alias=$alias")

        // SHA1withRSA - same as existing Dart RSASigner with SHA1Digest
        val sig = Signature.getInstance("SHA1withRSA")
        sig.initSign(key)
        sig.update(data.toByteArray(Charsets.UTF_8))

        return Base64.encodeToString(sig.sign(), Base64.NO_WRAP)
    }

    private fun getCertificateFromPkcs12(p12Bytes: ByteArray, password: String): String {
        val ks = KeyStore.getInstance("PKCS12")
        ks.load(ByteArrayInputStream(p12Bytes), password.toCharArray())

        val aliases = ks.aliases()
        if (!aliases.hasMoreElements()) throw IllegalStateException("No alias in PKCS12")

        val alias = aliases.nextElement()
        val cert = ks.getCertificate(alias)
            ?: throw IllegalStateException("No certificate for alias=$alias")

        return Base64.encodeToString(cert.encoded, Base64.NO_WRAP)
    }
}
