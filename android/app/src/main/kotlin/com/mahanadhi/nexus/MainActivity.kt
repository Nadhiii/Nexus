package com.mahanadhi.nexus

import android.os.Bundle
import androidx.core.view.WindowCompat
import com.google.android.material.color.DynamicColors
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
// Removed invalid MethodChannelHelper import

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        DynamicColors.applyToActivitiesIfAvailable(this.application)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize Android Auto Platform Channel handler
        val androidAutoHandler = AndroidAutoMethodChannelHandler(this)
        androidAutoHandler.setupChannel(flutterEngine)
    }
}
