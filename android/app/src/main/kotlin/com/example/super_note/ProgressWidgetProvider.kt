package com.example.super_note

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class ProgressWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_progress)

            // Read data from SharedPreferences
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val clockTime = prefs.getString("clock_time", "00:00") ?: "00:00"
            val clockDate = prefs.getString("clock_date", "01/01") ?: "01/01"
            val progressPercent = prefs.getString("today_progress_percent", "0") ?: "0"
            val todayCount = prefs.getString("today_count", "0") ?: "0"
            val doneCount = prefs.getString("today_done_count", "0") ?: "0"

            // Update clock
            views.setTextViewText(R.id.widget_clock_time, clockTime)
            views.setTextViewText(R.id.widget_clock_date, clockDate)

            // Update progress
            views.setTextViewText(R.id.widget_progress_percent, "$progressPercent%")
            views.setTextViewText(R.id.widget_progress_detail, "$doneCount/$todayCount việc đã hoàn thành")

            // Update progress bar width
            val progress = progressPercent.toIntOrNull() ?: 0
            val maxWidth = 200 // dp, will be scaled
            val progressWidth = (maxWidth * progress / 100).coerceAtLeast(0)

            // Click intent to open app
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            val pendingIntent = android.app.PendingIntent.getActivity(
                context, 2, launchIntent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_clock_time, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
