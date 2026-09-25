package com.bagye.bagyesrushrider

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val navigationBubbleChannel = "bagyesrush/navigation_bubble"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // See NavigationBubbleHandler.kt — the Android Bubbles counterpart to
        // NavigationReturnNotifier's cross-platform notification.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, navigationBubbleChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "show" -> {
                        val title = call.argument<String>("title") ?: ""
                        val text = call.argument<String>("text") ?: ""
                        val logo = call.argument<ByteArray>("logo")
                        if (logo == null) {
                            result.success(false)
                        } else {
                            result.success(
                                NavigationBubbleHandler.show(applicationContext, title, text, logo)
                            )
                        }
                    }
                    "cancel" -> {
                        NavigationBubbleHandler.cancel(applicationContext)
                        result.success(null)
                    }
                    "openBubbleSettings" -> {
                        NavigationBubbleHandler.openBubbleSettings(applicationContext)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
