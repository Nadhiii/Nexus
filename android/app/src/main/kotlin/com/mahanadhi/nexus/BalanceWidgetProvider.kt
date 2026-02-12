package com.mahanadhi.nexus

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import java.text.NumberFormat
import java.util.Locale

/**
 * Android Home Screen Widget for Balance Overview.
 * Shows total balance, income/expense summary, and financial health.
 */
class BalanceWidgetProvider : AppWidgetProvider() {

    companion object {
        const val PREFS_NAME = "nexus_balance_widget"
        const val KEY_TOTAL_BALANCE = "total_balance"
        const val KEY_MONTH_INCOME = "month_income"
        const val KEY_MONTH_EXPENSE = "month_expense"
        const val KEY_SAVINGS_RATE = "savings_rate"
        const val KEY_PENDING_BILLS = "pending_bills"
        
        const val ACTION_VIEW_DASHBOARD = "com.mahanadhi.nexus.ACTION_VIEW_DASHBOARD"
        const val ACTION_VIEW_ACCOUNTS = "com.mahanadhi.nexus.ACTION_VIEW_ACCOUNTS"
        const val ACTION_REFRESH_BALANCE = "com.mahanadhi.nexus.ACTION_REFRESH_BALANCE"
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
            ACTION_VIEW_DASHBOARD -> {
                launchApp(context, "/dashboard")
            }
            ACTION_VIEW_ACCOUNTS -> {
                launchApp(context, "/accounts")
            }
            ACTION_REFRESH_BALANCE -> {
                refreshWidgetData(context)
            }
        }
    }

    private fun launchApp(context: Context, route: String) {
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        intent?.apply {
            putExtra("route", route)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        context.startActivity(intent)
    }

    private fun refreshWidgetData(context: Context) {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val componentName = android.content.ComponentName(context, BalanceWidgetProvider::class.java)
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
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        
        val totalBalance = prefs.getFloat(KEY_TOTAL_BALANCE, 0f)
        val monthIncome = prefs.getFloat(KEY_MONTH_INCOME, 0f)
        val monthExpense = prefs.getFloat(KEY_MONTH_EXPENSE, 0f)
        val savingsRate = prefs.getFloat(KEY_SAVINGS_RATE, 0f)
        val pendingBills = prefs.getInt(KEY_PENDING_BILLS, 0)

        val views = RemoteViews(context.packageName, R.layout.widget_balance)
        val currencyFormat = NumberFormat.getCurrencyInstance(Locale("en", "IN"))

        // Set balance data
        views.setTextViewText(R.id.widget_total_balance, currencyFormat.format(totalBalance.toDouble()))
        views.setTextViewText(R.id.widget_month_income, "+${currencyFormat.format(monthIncome.toDouble())}")
        views.setTextViewText(R.id.widget_month_expense, "-${currencyFormat.format(monthExpense.toDouble())}")
        
        // Savings rate with color indicator
        val savingsText = String.format("%.1f%%", savingsRate)
        views.setTextViewText(R.id.widget_savings_rate, savingsText)
        
        // Set savings rate color based on value
        val savingsColor = when {
            savingsRate >= 20 -> android.graphics.Color.parseColor("#4CAF50") // Green
            savingsRate >= 10 -> android.graphics.Color.parseColor("#FF9800") // Orange
            else -> android.graphics.Color.parseColor("#F44336") // Red
        }
        views.setTextColor(R.id.widget_savings_rate, savingsColor)

        // Pending bills
        val pendingText = if (pendingBills > 0) "$pendingBills pending" else "No pending bills"
        views.setTextViewText(R.id.widget_pending_bills, pendingText)

        // Set up click intents
        val dashboardIntent = Intent(context, BalanceWidgetProvider::class.java).apply {
            action = ACTION_VIEW_DASHBOARD
        }
        val dashboardPendingIntent = PendingIntent.getBroadcast(
            context, 0, dashboardIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_container, dashboardPendingIntent)

        val accountsIntent = Intent(context, BalanceWidgetProvider::class.java).apply {
            action = ACTION_VIEW_ACCOUNTS
        }
        val accountsPendingIntent = PendingIntent.getBroadcast(
            context, 1, accountsIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_accounts_btn, accountsPendingIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
