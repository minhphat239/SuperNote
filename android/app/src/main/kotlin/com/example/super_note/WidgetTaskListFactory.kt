package com.example.super_note

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray
import org.json.JSONObject

class WidgetTaskListFactory(
    private val context: Context,
    private val intent: Intent
) : RemoteViewsService.RemoteViewsFactory {

    private var tasks = mutableListOf<TaskItem>()

    data class TaskItem(
        val id: String,
        val title: String,
        val isDone: Boolean,
        val categoryLabel: String,
        val categoryColor: Int,
        val dueTime: String,
        val isOverdue: Boolean
    )

    override fun onCreate() {}

    override fun onDataSetChanged() {
        tasks.clear()
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val todayTasks = prefs.getString("today_tasks", "[]") ?: "[]"

        try {
            val jsonArray = JSONArray(todayTasks)
            for (i in 0 until jsonArray.length()) {
                val obj = jsonArray.getJSONObject(i)
                tasks.add(TaskItem(
                    id = obj.optString("id", ""),
                    title = obj.optString("title", ""),
                    isDone = obj.optBoolean("isDone", false),
                    categoryLabel = obj.optString("categoryLabel", ""),
                    categoryColor = try {
                        Color.parseColor("#${obj.optString("categoryColor", "FF00F5FF")}")
                    } catch (e: Exception) {
                        Color.parseColor("#FF00F5FF")
                    },
                    dueTime = obj.optString("dueTime", ""),
                    isOverdue = obj.optBoolean("isOverdue", false)
                ))
            }
        } catch (e: Exception) {
            // Empty list on error
        }
    }

    override fun onDestroy() {
        tasks.clear()
    }

    override fun getCount(): Int = tasks.size

    override fun getViewAt(position: Int): RemoteViews {
        if (position >= tasks.size) return RemoteViews(context.packageName, R.layout.widget_task_item)

        val task = tasks[position]
        val views = RemoteViews(context.packageName, R.layout.widget_task_item).apply {
            setTextViewText(R.id.task_title, task.title)

            // Category bar color
            setInt(R.id.task_category_bar, "setBackgroundColor", task.categoryColor)

            // Time
            if (task.dueTime.isNotEmpty()) {
                setViewVisibility(R.id.task_time, View.VISIBLE)
                setTextViewText(R.id.task_time, task.dueTime)
            } else {
                setViewVisibility(R.id.task_time, View.GONE)
            }

            // Checkbox state
            if (task.isDone) {
                setImageViewResource(R.id.task_checkbox, R.drawable.widget_checkbox_checked)
                // Strike through title
                setTextColor(R.id.task_title, Color.parseColor("#60FFFFFF"))
            } else {
                setImageViewResource(R.id.task_checkbox, R.drawable.widget_checkbox_unchecked)
                if (task.isOverdue) {
                    setTextColor(R.id.task_title, Color.parseColor("#FFFF6B6B"))
                } else {
                    setTextColor(R.id.task_title, Color.parseColor("#FFFFFFFF"))
                }
            }

            // Fill intent for click handling
            val fillIntent = Intent().apply {
                putExtra("task_id", task.id)
                putExtra("task_position", position)
            }
            setOnClickFillInIntent(R.id.task_checkbox, fillIntent)
        }

        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = false
}
