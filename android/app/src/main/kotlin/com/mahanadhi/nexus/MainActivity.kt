package com.mahanadhi.nexus

import android.os.Bundle
import android.content.Intent
import androidx.core.view.WindowCompat
import com.google.android.material.color.DynamicColors
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
// Removed invalid MethodChannelHelper import

class MainActivity : FlutterFragmentActivity() {
    private var intentChannel: io.flutter.plugin.common.MethodChannel? = null
    private var pendingTabIndex: Int? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        DynamicColors.applyToActivitiesIfAvailable(this.application)

        handleIncomingIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIncomingIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize Android Auto Platform Channel handler
        val androidAutoHandler = AndroidAutoMethodChannelHandler(this)
        androidAutoHandler.setupChannel(flutterEngine)
        
        // Initialize Home Screen Widget handler
        val widgetHandler = WidgetMethodChannelHandler(this)
        widgetHandler.setupChannel(flutterEngine)

        intentChannel = io.flutter.plugin.common.MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.mahanadhi.nexus/intent"
        )

        pendingTabIndex?.let { tabIndex ->
            sendTabIndexToFlutter(tabIndex)
            pendingTabIndex = null
        }
    }

    private fun handleIncomingIntent(intent: Intent?) {
        if (intent == null) return
        val tabIndex = intent.getIntExtra("tabIndex", -1)
        if (tabIndex >= 0) {
            sendTabIndexToFlutter(tabIndex)
        }
    }

    private fun sendTabIndexToFlutter(tabIndex: Int) {
        if (intentChannel == null) {
            pendingTabIndex = tabIndex
            return
        }
        intentChannel?.invokeMethod(
            "navigateToTab",
            mapOf("tabIndex" to tabIndex)
        )
    }
}
