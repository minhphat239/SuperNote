package com.example.super_note

import android.app.Application
import android.os.Environment
import android.util.Log
import androidx.work.Configuration
import androidx.work.WorkManager
import java.io.File
import java.io.PrintWriter
import java.io.StringWriter
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class SuperNoteApplication : Application(), Configuration.Provider {
    companion object {
        private const val TAG = "SuperNote"
    }

    override fun onCreate() {
        super.onCreate()
        Log.i(TAG, "Application.onCreate: START")
        writeLog("Application.onCreate: START")
        installCrashHandler()
        writeLog("Application.onCreate: END")
        Log.i(TAG, "Application.onCreate: END")
    }

    override val workManagerConfiguration: Configuration
        get() = Configuration.Builder()
            .setMinimumLoggingLevel(android.util.Log.INFO)
            .build()

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
                    |Error: ${throwable.javaClass.name}: ${throwable.message}
                    |Stack:
                    |$sw
                    """.trimMargin()

                Log.e(TAG, crashText)
                writeLog(crashText)

                try {
                    val file = File(cacheDir, "crash_log.txt")
                    file.appendText("$crashText\n")
                } catch (_: Exception) {}

            } catch (_: Exception) {}

            defaultHandler?.uncaughtException(thread, throwable)
        }
    }

    private fun writeLog(text: String) {
        try {
            val dir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS), "SuperNote")
            if (!dir.exists()) dir.mkdirs()
            val file = File(dir, "startup_log.txt")
            val ts = SimpleDateFormat("HH:mm:ss.SSS", Locale.US).format(Date())
            file.appendText("[$ts] $text\n")
        } catch (e: Exception) {
            Log.e(TAG, "writeLog failed: $e")
        }
    }
}
