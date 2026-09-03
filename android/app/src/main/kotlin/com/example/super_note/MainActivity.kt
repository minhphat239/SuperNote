package com.example.super_note

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Looper
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.PrintWriter
import java.io.StringWriter
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.super_note/storage"
    private val TAG = "SuperNote"

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        // Install native crash handler BEFORE anything else
        installCrashHandler()
        Log.i(TAG, "onCreate: starting...")
        super.onCreate(savedInstanceState)
        Log.i(TAG, "onCreate: super completed")
    }

    private fun installCrashHandler() {
        val defaultHandler = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            try {
                val timestamp = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US).format(Date())
                val sw = StringWriter()
                throwable.printStackTrace(PrintWriter(sw))
                val crashText = """
                    |
                    |===== NATIVE CRASH at $timestamp =====
                    |Thread: ${thread.name}
                    |Error: ${throwable.message}
                    |Stack:
                    |$sw
                    """.trimMargin()

                Log.e(TAG, crashText)

                // Write to Documents/SuperNote/
                try {
                    val dir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS), "SuperNote")
                    if (!dir.exists()) dir.mkdirs()
                    val file = File(dir, "startup_log.txt")
                    file.appendText("$crashText\n")
                } catch (_: Exception) {}

                // Also write to app cache (always works)
                try {
                    val file = File(cacheDir, "crash_log.txt")
                    file.appendText("$crashText\n")
                } catch (_: Exception) {}

            } catch (_: Exception) {}

            // Let the default handler show the crash dialog
            defaultHandler?.uncaughtException(thread, throwable)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        Log.i(TAG, "configureFlutterEngine: starting...")
        super.configureFlutterEngine(flutterEngine)
        Log.i(TAG, "configureFlutterEngine: super completed")

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isManageStorageGranted" -> {
                    result.success(isManageStorageGranted())
                }
                "requestManageStorage" -> {
                    requestManageStorage()
                    result.success(true)
                }
                "openAppSettings" -> {
                    openAppSettings()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        Log.i(TAG, "configureFlutterEngine: done")
    }

    private fun isManageStorageGranted(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else {
            true
        }
    }

    private fun requestManageStorage() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION).apply {
                data = Uri.parse("package:$packageName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        }
    }

    private fun openAppSettings() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.parse("package:$packageName")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }
}
