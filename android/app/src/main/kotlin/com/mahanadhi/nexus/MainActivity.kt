package com.mahanadhi.nexus

import android.os.Bundle
import androidx.core.view.WindowCompat
import com.google.android.material.color.DynamicColors
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        DynamicColors.applyToActivitiesIfAvailable(this.application)
    }
}
