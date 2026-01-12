package com.mahanadhi.nexus

import android.content.Context
import androidx.car.app.Screen
import androidx.car.app.CarContext
import androidx.car.app.CarToast
import androidx.car.app.model.Action
import androidx.car.app.model.MessageTemplate
import androidx.car.app.model.ParkedOnlyOnClickListener
import androidx.car.app.model.Template
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Main screen for Android Auto integration in Nexus app.
 * Displays financial dashboard information suitable for car display.
 */
class NexusAndroidAutoScreen(carContext: CarContext) : Screen(carContext) {
  private var currentTitle = "Nexus"
  private var currentContent = "Loading Dashboard..."
  private var dashboardData: Map<String, String>? = null

  override fun onGetTemplate(): Template {
    val message = buildDisplayMessage()
    
    return MessageTemplate.Builder(message)
      .setTitle("Nexus Dashboard")
      .setHeaderAction(Action.APP_ICON)
      .addAction(
        Action.Builder()
          .setTitle("Refresh")
          .setOnClickListener(ParkedOnlyOnClickListener.create {
            CarToast.makeText(carContext, "Refreshing Dashboard...", CarToast.LENGTH_SHORT).show()
            invalidate()
          })
          .build()
      )
      .build()
  }

  private fun buildDisplayMessage(): String {
    return if (dashboardData != null) {
      """
      Balance: ${dashboardData!!["totalBalance"] ?: "N/A"}
      Income: ${dashboardData!!["monthlyIncome"] ?: "N/A"}
      Expense: ${dashboardData!!["monthlyExpense"] ?: "N/A"}
      Savings: ${dashboardData!!["savingsRate"] ?: "N/A"}
      """.trimIndent()
    } else {
      currentContent
    }
  }

  fun updateTitle(title: String) {
    currentTitle = title
    invalidate()
  }

  fun updateContent(content: String) {
    currentContent = content
    invalidate()
  }

  fun updateDashboardData(data: Map<String, String>) {
    dashboardData = data
    invalidate()
  }
}

/**
 * Platform Channel handler for Android Auto operations
 */
class AndroidAutoMethodChannelHandler(
  private val context: Context
) {
  companion object {
    private const val CHANNEL_NAME = "com.mahanadhi.nexus/android_auto"
  }

  private var currentScreen: NexusAndroidAutoScreen? = null
  private var methodChannel: MethodChannel? = null

  /**
   * Initialize Android Auto with the given Flutter engine
   */
  fun setupChannel(flutterEngine: FlutterEngine) {
    methodChannel = MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      CHANNEL_NAME
    )
    
    methodChannel?.setMethodCallHandler { call, result ->
      when (call.method) {
        "initializeAndroidAuto" -> {
          initializeAndroidAuto(result)
        }
        "updateAppState" -> {
          val title = call.argument<String>("title") ?: "Nexus"
          val content = call.argument<String>("content") ?: ""
          val data = call.argument<Map<String, Any>>("data") ?: emptyMap()
          updateAppState(title, content, data, result)
        }
        "updateDashboardSummary" -> {
          val summary = mapOf(
            "totalBalance" to (call.argument<String>("totalBalance") ?: "N/A"),
            "monthlyIncome" to (call.argument<String>("monthlyIncome") ?: "N/A"),
            "monthlyExpense" to (call.argument<String>("monthlyExpense") ?: "N/A"),
            "savingsRate" to (call.argument<String>("savingsRate") ?: "N/A")
          )
          updateDashboardSummary(summary, result)
        }
        "updateRecentTransactions" -> {
          val transactions = call.argument<List<Map<String, Any>>>("transactions") ?: emptyList()
          updateRecentTransactions(transactions, result)
        }
        "sendAlert" -> {
          val title = call.argument<String>("title") ?: "Alert"
          val message = call.argument<String>("message") ?: ""
          val alertType = call.argument<String>("alertType") ?: "info"
          sendAlert(title, message, alertType, result)
        }
        "handleAction" -> {
          val actionId = call.argument<String>("actionId") ?: ""
          handleAction(actionId, result)
        }
        "isConnected" -> {
          result.success(true)
        }
        else -> {
          result.notImplemented()
        }
      }
    }
  }

  private fun initializeAndroidAuto(result: MethodChannel.Result) {
    try {
      result.success(true)
    } catch (e: Exception) {
      result.error("INIT_FAILED", "Failed to initialize Android Auto: ${e.message}", null)
    }
  }

  private fun updateAppState(
    title: String,
    content: String,
    data: Map<String, Any>,
    result: MethodChannel.Result
  ) {
    try {
      currentScreen?.apply {
        updateTitle(title)
        updateContent(content)
      }
      result.success(true)
    } catch (e: Exception) {
      result.error("UPDATE_FAILED", "Failed to update app state: ${e.message}", null)
    }
  }

  private fun updateDashboardSummary(
    summary: Map<String, String>,
    result: MethodChannel.Result
  ) {
    try {
      currentScreen?.updateDashboardData(summary)
      result.success(true)
    } catch (e: Exception) {
      result.error("UPDATE_FAILED", "Failed to update dashboard: ${e.message}", null)
    }
  }

  private fun updateRecentTransactions(
    transactions: List<Map<String, Any>>,
    result: MethodChannel.Result
  ) {
    try {
      result.success(true)
    } catch (e: Exception) {
      result.error("UPDATE_FAILED", "Failed to update transactions: ${e.message}", null)
    }
  }

  private fun sendAlert(
    title: String,
    message: String,
    alertType: String,
    result: MethodChannel.Result
  ) {
    try {
      result.success(true)
    } catch (e: Exception) {
      result.error("ALERT_FAILED", "Failed to send alert: ${e.message}", null)
    }
  }

  private fun handleAction(
    actionId: String,
    result: MethodChannel.Result
  ) {
    try {
      println("Android Auto action handled: $actionId")
      result.success(true)
    } catch (e: Exception) {
      result.error("ACTION_FAILED", "Failed to handle action: ${e.message}", null)
    }
  }
}
