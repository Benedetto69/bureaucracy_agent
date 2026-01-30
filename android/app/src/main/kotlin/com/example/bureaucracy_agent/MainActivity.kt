package com.example.bureaucracy_agent

import android.content.pm.PackageManager
import android.util.Base64
import java.io.File
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
  private val securityChannel = "bureaucracy_agent/security"

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, securityChannel)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "getSigningFingerprint" -> result.success(getSigningFingerprint())
          "isDeviceCompromised" -> result.success(isDeviceCompromised())
          else -> result.notImplemented()
        }
      }
  }

  private fun getSigningFingerprint(): String? {
    return try {
      val flags = PackageManager.GET_SIGNING_CERTIFICATES
        val packageInfo = packageManager.getPackageInfo(packageName, flags)
        val signer = packageInfo.signingInfo.apkContentsSigners.firstOrNull()?.toByteArray() ?: return null
        val digest = MessageDigest.getInstance("SHA-256").digest(signer)
        Base64.encodeToString(digest, Base64.NO_WRAP)
      } catch (exception: Exception) {
        null
      }
    }

  private fun isDeviceCompromised(): Boolean {
    val buildTags = android.os.Build.TAGS
    if (buildTags != null && buildTags.contains("test-keys")) {
      return true
    }
    val suPaths = listOf(
      "/system/app/Superuser.apk",
      "/sbin/su",
      "/system/bin/su",
      "/system/xbin/su",
      "/data/local/xbin/su",
      "/data/local/bin/su",
      "/system/sd/xbin/su",
      "/system/bin/failsafe/su",
      "/data/local/su"
    )
    if (suPaths.any { File(it).exists() }) {
      return true
    }
    return try {
      val process = Runtime.getRuntime().exec(arrayOf("/system/xbin/which", "su"))
      val result = process.inputStream.bufferedReader().readLine()
      !result.isNullOrEmpty()
    } catch (exception: Exception) {
      false
    }
  }
}
