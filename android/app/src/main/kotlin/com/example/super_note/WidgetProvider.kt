package com.example.super_note

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class WidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(
                android.content.ComponentName(context, WidgetProvider::class.java)
            )
            for (appWidgetId in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_task_list)

            // Read data from HomeWidget SharedPreferences
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val todayCount = prefs.getString("today_count", "0") ?: "0"
            val todayTasks = prefs.getString("today_tasks", "[]") ?: "[]"

            // Update header
            views.setTextViewText(R.id.widget_header_title, "Hôm nay")
            views.setTextViewText(R.id.widget_header_count, "$todayCount việc")

            // Parse tasks and populate list
            try {
                val tasksArray = org.json.JSONArray(todayTasks)

                if (tasksArray.length() == 0) {
                    views.setViewVisibility(R.id.widget_empty_text, android.view.View.VISIBLE)
                    views.setViewVisibility(R.id.widget_task_list, android.view.View.GONE)
                } else {
                    views.setViewVisibility(R.id.widget_empty_text, android.view.View.GONE)
                    views.setViewVisibility(R.id.widget_task_list, android.view.View.VISIBLE)

                    // Use RemoteViewsService for list
                    val intent = Intent(context, WidgetTaskListService::class.java).apply {
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                        data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
                    }
                    views.setRemoteAdapter(R.id.widget_task_list, intent)
                }
            } catch (e: Exception) {
                views.setViewVisibility(R.id.widget_empty_text, android.view.View.VISIBLE)
                views.setViewVisibility(R.id.widget_task_list, android.view.View.GONE)
            }

            // Set click intent to open app
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            val pendingIntent = android.app.PendingIntent.getActivity(
                context, 0, launchIntent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_header_title, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
