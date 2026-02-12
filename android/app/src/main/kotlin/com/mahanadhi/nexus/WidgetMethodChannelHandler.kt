package com.mahanadhi.nexus

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Handles MethodChannel communication between Flutter and Android Widgets.
 */
class WidgetMethodChannelHandler(private val activity: Activity) {
    
    companion object {
        private const val CHANNEL = "com.mahanadhi.nexus/widget"
    }
    
    fun setupChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                // Garage Widget
                "updateGarageWidget" -> handleUpdateGarageWidget(call, result)
                "requestPinGarageWidget" -> handlePinGarageWidget(result)
                "getGarageWidgetCount" -> handleGetGarageWidgetCount(result)
                
                // Quick Transaction Widget
                "updateQuickTransactionWidget" -> handleUpdateQuickTransactionWidget(call, result)
                "requestPinQuickTransactionWidget" -> handlePinQuickTransactionWidget(result)
                
                // Balance Widget
                "updateBalanceWidget" -> handleUpdateBalanceWidget(call, result)
                "requestPinBalanceWidget" -> handlePinBalanceWidget(result)
                
                // Common
                "areWidgetsSupported" -> result.success(true)
                "refreshAllWidgets" -> handleRefreshAllWidgets(result)
                
                else -> result.notImplemented()
            }
        }
    }
    
    // ============== GARAGE WIDGET ==============
    
    private fun handleUpdateGarageWidget(call: MethodCall, result: MethodChannel.Result) {
        try {
            val vehicleName = call.argument<String>("vehicleName") ?: "My Vehicle"
            val odometer = call.argument<Double>("odometer") ?: 0.0
            val mileage = call.argument<Double>("mileage") ?: 0.0
            val lastFuelDate = call.argument<String>("lastFuelDate") ?: "No data"
            val fuelPrice = call.argument<Double>("fuelPrice") ?: 0.0
            
            val prefs = activity.getSharedPreferences(
                GarageWidgetProvider.PREFS_NAME,
                Context.MODE_PRIVATE
            )
            prefs.edit().apply {
                putString(GarageWidgetProvider.KEY_VEHICLE_NAME, vehicleName)
                putFloat(GarageWidgetProvider.KEY_ODOMETER, odometer.toFloat())
                putFloat(GarageWidgetProvider.KEY_MILEAGE, mileage.toFloat())
                putString(GarageWidgetProvider.KEY_LAST_FUEL_DATE, lastFuelDate)
                putFloat(GarageWidgetProvider.KEY_FUEL_PRICE, fuelPrice.toFloat())
                apply()
            }
            
            updateWidget(GarageWidgetProvider::class.java)
            result.success(true)
        } catch (e: Exception) {
            result.error("UPDATE_ERROR", e.message, null)
        }
    }
    
    private fun handlePinGarageWidget(result: MethodChannel.Result) {
        pinWidget(GarageWidgetProvider::class.java, result)
    }
    
    private fun handleGetGarageWidgetCount(result: MethodChannel.Result) {
        getWidgetCount(GarageWidgetProvider::class.java, result)
    }
    
    // ============== QUICK TRANSACTION WIDGET ==============
    
    private fun handleUpdateQuickTransactionWidget(call: MethodCall, result: MethodChannel.Result) {
        try {
            val todaySpent = call.argument<Double>("todaySpent") ?: 0.0
            val weekSpent = call.argument<Double>("weekSpent") ?: 0.0
            val lastTransaction = call.argument<String>("lastTransaction") ?: "No transactions"
            val lastAmount = call.argument<Double>("lastAmount") ?: 0.0
            val topCategory = call.argument<String>("topCategory") ?: "None"
            
            val prefs = activity.getSharedPreferences(
                QuickTransactionWidgetProvider.PREFS_NAME,
                Context.MODE_PRIVATE
            )
            prefs.edit().apply {
                putFloat(QuickTransactionWidgetProvider.KEY_TODAY_SPENT, todaySpent.toFloat())
                putFloat(QuickTransactionWidgetProvider.KEY_WEEK_SPENT, weekSpent.toFloat())
                putString(QuickTransactionWidgetProvider.KEY_LAST_TRANSACTION, lastTransaction)
                putFloat(QuickTransactionWidgetProvider.KEY_LAST_AMOUNT, lastAmount.toFloat())
                putString(QuickTransactionWidgetProvider.KEY_TOP_CATEGORY, topCategory)
                apply()
            }
            
            updateWidget(QuickTransactionWidgetProvider::class.java)
            result.success(true)
        } catch (e: Exception) {
            result.error("UPDATE_ERROR", e.message, null)
        }
    }
    
    private fun handlePinQuickTransactionWidget(result: MethodChannel.Result) {
        pinWidget(QuickTransactionWidgetProvider::class.java, result)
    }
    
    // ============== BALANCE WIDGET ==============
    
    private fun handleUpdateBalanceWidget(call: MethodCall, result: MethodChannel.Result) {
        try {
            val totalBalance = call.argument<Double>("totalBalance") ?: 0.0
            val monthIncome = call.argument<Double>("monthIncome") ?: 0.0
            val monthExpense = call.argument<Double>("monthExpense") ?: 0.0
            val savingsRate = call.argument<Double>("savingsRate") ?: 0.0
            val pendingBills = call.argument<Int>("pendingBills") ?: 0
            
            val prefs = activity.getSharedPreferences(
                BalanceWidgetProvider.PREFS_NAME,
                Context.MODE_PRIVATE
            )
            prefs.edit().apply {
                putFloat(BalanceWidgetProvider.KEY_TOTAL_BALANCE, totalBalance.toFloat())
                putFloat(BalanceWidgetProvider.KEY_MONTH_INCOME, monthIncome.toFloat())
                putFloat(BalanceWidgetProvider.KEY_MONTH_EXPENSE, monthExpense.toFloat())
                putFloat(BalanceWidgetProvider.KEY_SAVINGS_RATE, savingsRate.toFloat())
                putInt(BalanceWidgetProvider.KEY_PENDING_BILLS, pendingBills)
                apply()
            }
            
            updateWidget(BalanceWidgetProvider::class.java)
            result.success(true)
        } catch (e: Exception) {
            result.error("UPDATE_ERROR", e.message, null)
        }
    }
    
    private fun handlePinBalanceWidget(result: MethodChannel.Result) {
        pinWidget(BalanceWidgetProvider::class.java, result)
    }
    
    // ============== HELPER METHODS ==============
    
    private fun <T> updateWidget(widgetClass: Class<T>) {
        val intent = Intent(activity, widgetClass).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
        }
        
        val appWidgetManager = AppWidgetManager.getInstance(activity)
        val componentName = ComponentName(activity, widgetClass)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
        
        intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
        activity.sendBroadcast(intent)
    }
    
    private fun <T> pinWidget(widgetClass: Class<T>, result: MethodChannel.Result) {
        try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                val appWidgetManager = AppWidgetManager.getInstance(activity)
                val componentName = ComponentName(activity, widgetClass)
                
                if (appWidgetManager.isRequestPinAppWidgetSupported) {
                    appWidgetManager.requestPinAppWidget(componentName, null, null)
                    result.success(true)
                } else {
                    result.success(false)
                }
            } else {
                result.success(false)
            }
        } catch (e: Exception) {
            result.error("PIN_ERROR", e.message, null)
        }
    }
    
    private fun <T> getWidgetCount(widgetClass: Class<T>, result: MethodChannel.Result) {
        try {
            val appWidgetManager = AppWidgetManager.getInstance(activity)
            val componentName = ComponentName(activity, widgetClass)
            val widgetIds = appWidgetManager.getAppWidgetIds(componentName)
            result.success(widgetIds.size)
        } catch (e: Exception) {
            result.success(0)
        }
    }
    
    private fun handleRefreshAllWidgets(result: MethodChannel.Result) {
        try {
            updateWidget(GarageWidgetProvider::class.java)
            updateWidget(QuickTransactionWidgetProvider::class.java)
            updateWidget(BalanceWidgetProvider::class.java)
            result.success(true)
        } catch (e: Exception) {
            result.error("REFRESH_ERROR", e.message, null)
        }
    }
}
