package com.mahanadhi.nexus

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import java.text.NumberFormat
import java.util.Locale

/**
 * Android Home Screen Widget for the Garage feature.
 * Displays current vehicle info, mileage, and fuel status.
 */
class GarageWidgetProvider : AppWidgetProvider() {

    companion object {
        const val PREFS_NAME = "nexus_garage_widget"
        const val KEY_VEHICLE_NAME = "vehicle_name"
        const val KEY_ODOMETER = "odometer"
        const val KEY_MILEAGE = "mileage"
        const val KEY_LAST_FUEL_DATE = "last_fuel_date"
        const val KEY_FUEL_PRICE = "fuel_price"
        
        const val ACTION_LOG_FUEL = "com.mahanadhi.nexus.ACTION_LOG_FUEL"
        const val ACTION_VIEW_GARAGE = "com.mahanadhi.nexus.ACTION_VIEW_GARAGE"
        const val ACTION_REFRESH = "com.mahanadhi.nexus.ACTION_REFRESH"
    }

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
        
        when (intent.action) {
            ACTION_LOG_FUEL -> {
                // Launch app to fuel logging screen
                launchApp(context, "/garage/fuel")
            }
            ACTION_VIEW_GARAGE -> {
                // Launch app to garage main screen
                launchApp(context, "/garage")
            }
            ACTION_REFRESH -> {
                // Request data refresh from Flutter
                refreshWidgetData(context)
            }
        }
    }

    private fun launchApp(context: Context, route: String) {
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        intent?.apply {
            putExtra("route", route)
            putExtra("tabIndex", 3)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        context.startActivity(intent)
    }

    private fun refreshWidgetData(context: Context) {
        // This would normally communicate with Flutter via MethodChannel
        // For now, we'll trigger an update with existing data
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val componentName = android.content.ComponentName(context, GarageWidgetProvider::class.java)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
        
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        // Load saved data from SharedPreferences
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        
        val vehicleName = prefs.getString(KEY_VEHICLE_NAME, "My Vehicle") ?: "My Vehicle"
        val odometer = prefs.getFloat(KEY_ODOMETER, 0f)
        val mileage = prefs.getFloat(KEY_MILEAGE, 0f)
        val lastFuelDate = prefs.getString(KEY_LAST_FUEL_DATE, "No data") ?: "No data"
        val fuelPrice = prefs.getFloat(KEY_FUEL_PRICE, 0f)

        val views = RemoteViews(context.packageName, R.layout.widget_garage)

        // Set vehicle info
        views.setTextViewText(R.id.widget_vehicle_name, vehicleName)
        views.setTextViewText(
            R.id.widget_odometer,
            "${NumberFormat.getInstance(Locale("en", "IN")).format(odometer.toInt())} km"
        )
        
        // Set mileage
        if (mileage > 0) {
            views.setTextViewText(R.id.widget_mileage, String.format("%.1f km/L", mileage))
        } else {
            views.setTextViewText(R.id.widget_mileage, "-- km/L")
        }

        // Set fuel info
        if (fuelPrice > 0) {
            views.setTextViewText(
                R.id.widget_fuel_price,
                "₹${String.format("%.2f", fuelPrice)}/L"
            )
        } else {
            views.setTextViewText(R.id.widget_fuel_price, "No fuel data")
        }
        views.setTextViewText(R.id.widget_last_fuel_date, lastFuelDate)

        // Set click intents
        val logFuelIntent = Intent(context, GarageWidgetProvider::class.java).apply {
            action = ACTION_LOG_FUEL
        }
        val logFuelPendingIntent = PendingIntent.getBroadcast(
            context, 0, logFuelIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_log_fuel_button, logFuelPendingIntent)

        val viewGarageIntent = Intent(context, GarageWidgetProvider::class.java).apply {
            action = ACTION_VIEW_GARAGE
        }
        val viewGaragePendingIntent = PendingIntent.getBroadcast(
            context, 1, viewGarageIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_container, viewGaragePendingIntent)

        val refreshIntent = Intent(context, GarageWidgetProvider::class.java).apply {
            action = ACTION_REFRESH
        }
        val refreshPendingIntent = PendingIntent.getBroadcast(
            context, 2, refreshIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_refresh_button, refreshPendingIntent)

        // Update the widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
