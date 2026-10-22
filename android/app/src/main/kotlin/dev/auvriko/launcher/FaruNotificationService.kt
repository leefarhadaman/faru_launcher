package dev.auvriko.launcher

import android.content.pm.PackageManager
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class FaruNotificationService : NotificationListenerService() {

    companion object {
        // Singleton reference so MainActivity can query current notifications
        @Volatile
        var instance: FaruNotificationService? = null

        fun getActiveNotifications(): List<Map<String, Any?>> {
            val svc = instance ?: return emptyList()
            return try {
                svc.activeNotifications?.mapNotNull { sbn -> sbn.toMap(svc) } ?: emptyList()
            } catch (_: Exception) {
                emptyList()
            }
        }

        fun dismissNotification(key: String) {
            try {
                instance?.cancelNotification(key)
            } catch (_: Exception) {}
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
    }

    override fun onDestroy() {
        instance = null
        super.onDestroy()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        // Broadcast to Flutter via MainActivity channel when a new notification arrives
        MainActivity.notificationChannel?.invokeMethod("onNotificationsChanged", null)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        MainActivity.notificationChannel?.invokeMethod("onNotificationsChanged", null)
    }
}

private fun StatusBarNotification.toMap(ctx: NotificationListenerService): Map<String, Any?>? {
    return try {
        val extras = notification?.extras ?: return null
        val title = extras.getCharSequence("android.title")?.toString() ?: ""
        val text  = extras.getCharSequence("android.text")?.toString()
                 ?: extras.getCharSequence("android.bigText")?.toString() ?: ""
        if (title.isBlank() && text.isBlank()) return null

        val appLabel = try {
            ctx.packageManager
                .getApplicationLabel(
                    if (Build.VERSION.SDK_INT >= 33)
                        ctx.packageManager.getApplicationInfo(packageName,
                            PackageManager.ApplicationInfoFlags.of(0L))
                    else
                        @Suppress("DEPRECATION")
                        ctx.packageManager.getApplicationInfo(packageName, 0)
                ).toString()
        } catch (_: Exception) { packageName }

        mapOf(
            "key"       to key,
            "packageName" to packageName,
            "appLabel"  to appLabel,
            "title"     to title,
            "text"      to text,
            "postTime"  to postTime,
            "ongoing"   to isOngoing,
        )
    } catch (_: Exception) { null }
}
