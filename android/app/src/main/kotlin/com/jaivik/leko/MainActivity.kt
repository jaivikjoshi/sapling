package com.jaivik.leko

import android.content.ComponentName
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "leko/notification_import"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasPermission" -> result.success(hasNotificationListenerAccess())
                "requestPermission" -> {
                    startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                    result.success(hasNotificationListenerAccess())
                }
                "preview" -> {
                    val userId = call.argument<String>("userId")
                    result.success(
                        BankNotificationListenerService.readDrafts(this, userId)
                    )
                }
                "setActiveUserId" -> {
                    BankNotificationListenerService.setActiveUserId(
                        this,
                        call.argument<String>("userId")
                    )
                    result.success(null)
                }
                "clearDraftsForUser" -> {
                    val userId = call.argument<String>("userId")
                    if (!userId.isNullOrBlank()) {
                        BankNotificationListenerService.clearDraftsForUser(this, userId)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun hasNotificationListenerAccess(): Boolean {
        val enabledListeners = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners"
        ) ?: return false
        val componentName = ComponentName(
            this,
            BankNotificationListenerService::class.java
        ).flattenToString()
        return enabledListeners
            .split(":")
            .any { it.equals(componentName, ignoreCase = true) }
    }
}
