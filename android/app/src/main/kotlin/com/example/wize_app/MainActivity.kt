package com.example.wize // <-- your actual package name

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.wize/sos"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Check if launched from shortcut intent
        val intentData = intent?.data
        if (intentData != null && intentData.toString() == "sos://trigger") {
            // Send message to Flutter
            MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger, CHANNEL)
                .invokeMethod("triggerSOS", null)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
    }
}