package com.example.super_note

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Looper
import android.provider.Settings
import android.util.Log
import androidx.core.content.FileProvider
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
    private val UPDATE_CHANNEL = "com.example.super_note/update"
    private val TAG = "SuperNote"

    override fun attachBaseContext(newBase: android.content.Context?) {
        Log.i(TAG, "attachBaseContext: START")
        writeLogToFile("attachBaseContext: START")
        super.attachBaseContext(newBase)
        writeLogToFile("attachBaseContext: END")
        Log.i(TAG, "attachBaseContext: END")
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        Log.i(TAG, "onCreate: START")
        writeLogToFile("onCreate: START")
        installCrashHandler()
        super.onCreate(savedInstanceState)
        writeLogToFile("onCreate: END")
        Log.i(TAG, "onCreate: END")
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

        // Storage channel
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

        // Update channel — returns content:// URI via FileProvider
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPDATE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getUriForFile" -> {
                    try {
                        val path = call.argument<String>("path")
                        if (path != null) {
                            val file = File(path)
                            val uri = FileProvider.getUriForFile(
                                this,
                                "${packageName}.fileProvider",
                                file
                            )
                            result.success(uri.toString())
                        } else {
                            result.error("INVALID_PATH", "Path is null", null)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "FileProvider error: $e")
                        result.error("FILE_PROVIDER_ERROR", e.message, null)
                    }
                }
                "getSupportedAbis" -> {
                    result.success(Build.SUPPORTED_ABIS.toList())
                }
                "installApk" -> {
                    try {
                        val path = call.argument<String>("path")
                        if (path != null) {
                            val file = File(path)
                            val uri = FileProvider.getUriForFile(
                                this,
                                "${packageName}.fileProvider",
                                file
                            )
                            val installIntent = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(uri, "application/vnd.android.package-archive")
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(installIntent)
                            result.success(true)
                        } else {
                            result.error("INVALID_PATH", "Path is null", null)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Install APK error: $e")
                        result.success(false)
                    }
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

    private fun writeLogToFile(text: String) {
        try {
            val dir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS), "SuperNote")
            if (!dir.exists()) dir.mkdirs()
            val file = File(dir, "startup_log.txt")
            val ts = java.text.SimpleDateFormat("HH:mm:ss.SSS", java.util.Locale.US).format(java.util.Date())
            file.appendText("[$ts] $text\n")
        } catch (e: Exception) {
            Log.e(TAG, "writeLogToFile failed: $e")
        }
    }
}
