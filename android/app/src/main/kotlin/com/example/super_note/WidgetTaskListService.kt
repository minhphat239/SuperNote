package com.example.super_note

import android.content.Intent
import android.widget.RemoteViewsService

class WidgetTaskListService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return WidgetTaskListFactory(applicationContext, intent)
    }
}
