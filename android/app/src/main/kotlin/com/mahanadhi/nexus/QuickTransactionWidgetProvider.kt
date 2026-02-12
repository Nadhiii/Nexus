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
 * Android Home Screen Widget for Quick Transaction.
 * Shows spending summary and allows quick transaction entry.
 */
class QuickTransactionWidgetProvider : AppWidgetProvider() {

    companion object {
        const val PREFS_NAME = "nexus_quick_transaction_widget"
        const val KEY_TODAY_SPENT = "today_spent"
        const val KEY_WEEK_SPENT = "week_spent"
        const val KEY_LAST_TRANSACTION = "last_transaction"
        const val KEY_LAST_AMOUNT = "last_amount"
        const val KEY_TOP_CATEGORY = "top_category"
        
        const val ACTION_ADD_EXPENSE = "com.mahanadhi.nexus.ACTION_ADD_EXPENSE"
        const val ACTION_ADD_INCOME = "com.mahanadhi.nexus.ACTION_ADD_INCOME"
        const val ACTION_VIEW_TRANSACTIONS = "com.mahanadhi.nexus.ACTION_VIEW_TRANSACTIONS"
        const val ACTION_REFRESH_TRANSACTION = "com.mahanadhi.nexus.ACTION_REFRESH_TRANSACTION"
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
            ACTION_ADD_EXPENSE -> {
                launchApp(context, "/transaction/add?type=expense")
            }
            ACTION_ADD_INCOME -> {
                launchApp(context, "/transaction/add?type=income")
            }
            ACTION_VIEW_TRANSACTIONS -> {
                launchApp(context, "/transactions")
            }
            ACTION_REFRESH_TRANSACTION -> {
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
        val componentName = android.content.ComponentName(context, QuickTransactionWidgetProvider::class.java)
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
        
        val todaySpent = prefs.getFloat(KEY_TODAY_SPENT, 0f)
        val weekSpent = prefs.getFloat(KEY_WEEK_SPENT, 0f)
        val lastTransaction = prefs.getString(KEY_LAST_TRANSACTION, "No transactions") ?: "No transactions"
        val lastAmount = prefs.getFloat(KEY_LAST_AMOUNT, 0f)
        val topCategory = prefs.getString(KEY_TOP_CATEGORY, "None") ?: "None"

        val views = RemoteViews(context.packageName, R.layout.widget_quick_transaction)
        val currencyFormat = NumberFormat.getCurrencyInstance(Locale("en", "IN"))

        // Set spending data
        views.setTextViewText(R.id.widget_today_spent, currencyFormat.format(todaySpent.toDouble()))
        views.setTextViewText(R.id.widget_week_spent, currencyFormat.format(weekSpent.toDouble()))
        views.setTextViewText(R.id.widget_last_transaction, lastTransaction)
        views.setTextViewText(R.id.widget_last_amount, currencyFormat.format(lastAmount.toDouble()))
        views.setTextViewText(R.id.widget_top_category, topCategory)

        // Set up click intents
        val addExpenseIntent = Intent(context, QuickTransactionWidgetProvider::class.java).apply {
            action = ACTION_ADD_EXPENSE
        }
        val addExpensePendingIntent = PendingIntent.getBroadcast(
            context, 0, addExpenseIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_add_expense_btn, addExpensePendingIntent)

        val addIncomeIntent = Intent(context, QuickTransactionWidgetProvider::class.java).apply {
            action = ACTION_ADD_INCOME
        }
        val addIncomePendingIntent = PendingIntent.getBroadcast(
            context, 1, addIncomeIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_add_income_btn, addIncomePendingIntent)

        val viewIntent = Intent(context, QuickTransactionWidgetProvider::class.java).apply {
            action = ACTION_VIEW_TRANSACTIONS
        }
        val viewPendingIntent = PendingIntent.getBroadcast(
            context, 2, viewIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_container, viewPendingIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
