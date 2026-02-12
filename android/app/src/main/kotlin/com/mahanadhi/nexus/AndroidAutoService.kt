package com.mahanadhi.nexus

import android.content.Context
import androidx.car.app.CarAppService
import androidx.car.app.Screen
import androidx.car.app.CarContext
import androidx.car.app.CarToast
import androidx.car.app.model.Action
import androidx.car.app.model.MessageTemplate
import androidx.car.app.model.Pane
import androidx.car.app.model.PaneTemplate
import androidx.car.app.model.Row
import androidx.car.app.model.ParkedOnlyOnClickListener
import androidx.car.app.model.Template
import androidx.car.app.Session
import androidx.car.app.validation.HostValidator
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Main screen for Android Auto integration in Nexus app.
 * Displays Garage information - vehicle details, mileage, and fuel logging.
 */
class NexusAndroidAutoScreen(carContext: CarContext) : Screen(carContext) {
  private var currentMode = DisplayMode.GARAGE
  private var garageData: GarageDisplayData? = null
  private var dashboardData: Map<String, String>? = null

  enum class DisplayMode {
    GARAGE,
    DASHBOARD
  }

  override fun onGetTemplate(): Template {
    return when (currentMode) {
      DisplayMode.GARAGE -> buildGarageTemplate()
      DisplayMode.DASHBOARD -> buildDashboardTemplate()
    }
  }

  private fun buildGarageTemplate(): Template {
    val paneBuilder = Pane.Builder()

    garageData?.let { data ->
      // Vehicle Name Row
      paneBuilder.addRow(
        Row.Builder()
          .setTitle(data.vehicleName)
          .addText("🏍️ Your Vehicle")
          .build()
      )

      // Odometer Row
      paneBuilder.addRow(
        Row.Builder()
          .setTitle("Odometer")
          .addText("${data.formattedOdometer} km")
          .build()
      )

      // Mileage Row
      paneBuilder.addRow(
        Row.Builder()
          .setTitle("Average Mileage")
          .addText("${data.formattedMileage} km/L")
          .build()
      )

      // Last Fuel Row
      paneBuilder.addRow(
        Row.Builder()
          .setTitle("Last Fuel")
          .addText("₹${data.lastFuelPrice}/L • ${data.lastFuelDate}")
          .build()
      )

      // Service reminder if due
      if (data.serviceDueSoon) {
        paneBuilder.addRow(
          Row.Builder()
            .setTitle("⚠️ Service Reminder")
            .addText("Service due at ${data.nextServiceKm} km")
            .build()
        )
      }
    } ?: run {
      paneBuilder.addRow(
        Row.Builder()
          .setTitle("No Vehicle Data")
          .addText("Open Nexus to sync your garage")
          .build()
      )
    }

    // Add Log Fuel action
    paneBuilder.addAction(
      Action.Builder()
        .setTitle("🛢️ Log Fuel")
        .setOnClickListener(ParkedOnlyOnClickListener.create {
          CarToast.makeText(carContext, "Opening Fuel Log...", CarToast.LENGTH_SHORT).show()
          // This would trigger the Flutter side to handle fuel logging
          notifyFuelLogRequested()
        })
        .build()
    )

    return PaneTemplate.Builder(paneBuilder.build())
      .setTitle("Nexus Garage")
      .setHeaderAction(Action.APP_ICON)
      .build()
  }

  private fun buildDashboardTemplate(): Template {
    val message = if (dashboardData != null) {
      """
      Balance: ${dashboardData!!["totalBalance"] ?: "N/A"}
      Income: ${dashboardData!!["monthlyIncome"] ?: "N/A"}
      Expense: ${dashboardData!!["monthlyExpense"] ?: "N/A"}
      Savings: ${dashboardData!!["savingsRate"] ?: "N/A"}
      """.trimIndent()
    } else {
      "Loading Dashboard..."
    }
    
    return MessageTemplate.Builder(message)
      .setTitle("Nexus Dashboard")
      .setHeaderAction(Action.APP_ICON)
      .addAction(
        Action.Builder()
          .setTitle("Garage")
          .setOnClickListener(ParkedOnlyOnClickListener.create {
            currentMode = DisplayMode.GARAGE
            invalidate()
          })
          .build()
      )
      .addAction(
        Action.Builder()
          .setTitle("Refresh")
          .setOnClickListener(ParkedOnlyOnClickListener.create {
            CarToast.makeText(carContext, "Refreshing...", CarToast.LENGTH_SHORT).show()
            invalidate()
          })
          .build()
      )
      .build()
  }

  private fun notifyFuelLogRequested() {
    // This would communicate back to Flutter
    // For now, show a toast
    CarToast.makeText(carContext, "Please complete fuel log in the app", CarToast.LENGTH_LONG).show()
  }

  fun updateGarageData(data: GarageDisplayData) {
    garageData = data
    invalidate()
  }

  fun updateDashboardData(data: Map<String, String>) {
    dashboardData = data
    invalidate()
  }

  fun switchToGarage() {
    currentMode = DisplayMode.GARAGE
    invalidate()
  }

  fun switchToDashboard() {
    currentMode = DisplayMode.DASHBOARD
    invalidate()
  }
}

/**
 * Android Auto CarAppService entry point.
 */
class NexusCarAppService : CarAppService() {
  override fun createHostValidator(): HostValidator {
    // Allow all hosts for development; tighten for production.
    return HostValidator.ALLOW_ALL_HOSTS_VALIDATOR
  }

  override fun onCreateSession(): Session {
    return object : Session() {
      override fun onCreateScreen(intent: android.content.Intent): Screen {
        val screen = NexusAndroidAutoScreen(carContext)
        AndroidAutoMethodChannelHandler.activeScreen = screen
        return screen
      }
    }
  }
}

/**
 * Data class for Garage display on Android Auto
 */
data class GarageDisplayData(
  val vehicleName: String,
  val odometer: Double,
  val mileage: Double,
  val lastFuelPrice: Double,
  val lastFuelDate: String,
  val nextServiceKm: Int,
  val serviceDueSoon: Boolean
) {
  val formattedOdometer: String
    get() = String.format("%,.0f", odometer)
  
  val formattedMileage: String
    get() = if (mileage > 0) String.format("%.1f", mileage) else "--"
}

/**
 * Platform Channel handler for Android Auto operations
 */
class AndroidAutoMethodChannelHandler(
  private val context: Context
) {
  companion object {
    private const val CHANNEL_NAME = "com.mahanadhi.nexus/android_auto"
    var activeScreen: NexusAndroidAutoScreen? = null
  }

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
        "updateGarageData" -> {
          val data = GarageDisplayData(
            vehicleName = call.argument<String>("vehicleName") ?: "My Vehicle",
            odometer = call.argument<Double>("odometer") ?: 0.0,
            mileage = call.argument<Double>("mileage") ?: 0.0,
            lastFuelPrice = call.argument<Double>("lastFuelPrice") ?: 0.0,
            lastFuelDate = call.argument<String>("lastFuelDate") ?: "No data",
            nextServiceKm = call.argument<Int>("nextServiceKm") ?: 0,
            serviceDueSoon = call.argument<Boolean>("serviceDueSoon") ?: false
          )
          updateGarageData(data, result)
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
        "switchToGarage" -> {
          activeScreen?.switchToGarage()
          result.success(true)
        }
        "switchToDashboard" -> {
          activeScreen?.switchToDashboard()
          result.success(true)
        }
        "sendAlert" -> {
          val title = call.argument<String>("title") ?: "Alert"
          val message = call.argument<String>("message") ?: ""
          val alertType = call.argument<String>("alertType") ?: "info"
          sendAlert(title, message, alertType, result)
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

  private fun updateGarageData(data: GarageDisplayData, result: MethodChannel.Result) {
    try {
      activeScreen?.updateGarageData(data)
      result.success(true)
    } catch (e: Exception) {
      result.error("UPDATE_FAILED", "Failed to update garage: ${e.message}", null)
    }
  }

  private fun updateAppState(
    title: String,
    content: String,
    data: Map<String, Any>,
    result: MethodChannel.Result
  ) {
    try {
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
      activeScreen?.updateDashboardData(summary)
      result.success(true)
    } catch (e: Exception) {
      result.error("UPDATE_FAILED", "Failed to update dashboard: ${e.message}", null)
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
}
