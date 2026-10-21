package dev.faru.faru_launcher

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "dev.faru.launcher/apps"
    private var methodChannel: MethodChannel? = null
    private var packageReceiverRegistered = false

    private val packageChangeReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val action = intent?.action ?: return
            if (action == Intent.ACTION_PACKAGE_ADDED ||
                action == Intent.ACTION_PACKAGE_REMOVED ||
                action == Intent.ACTION_PACKAGE_REPLACED
            ) {
                methodChannel?.invokeMethod("onPackagesChanged", null)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        )
        methodChannel = channel

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getApps" -> {
                    try {
                        result.success(getLaunchableApps())
                    } catch (e: Exception) {
                        result.error("APP_DISCOVERY_FAILED", e.message, null)
                    }
                }
                "launchApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName.isNullOrBlank()) {
                        result.error("INVALID_ARGUMENT", "packageName is required", null)
                    } else {
                        try {
                            val intent = packageManager.getLaunchIntentForPackage(packageName)
                            if (intent == null) {
                                result.error("APP_NOT_LAUNCHABLE", "No launch activity found", null)
                            } else {
                                startActivity(intent)
                                result.success(true)
                            }
                        } catch (e: Exception) {
                            result.error("LAUNCH_FAILED", e.message, null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onStart() {
        super.onStart()
        registerPackageReceiverIfNeeded()
    }

    override fun onStop() {
        unregisterPackageReceiverIfNeeded()
        super.onStop()
    }

    override fun onDestroy() {
        unregisterPackageReceiverIfNeeded()
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        super.onDestroy()
    }

    private fun registerPackageReceiverIfNeeded() {
        if (packageReceiverRegistered) return
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_PACKAGE_ADDED)
            addAction(Intent.ACTION_PACKAGE_REMOVED)
            addAction(Intent.ACTION_PACKAGE_REPLACED)
            addDataScheme("package")
        }
        if (Build.VERSION.SDK_INT >= 33) {
            registerReceiver(packageChangeReceiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(packageChangeReceiver, filter)
        }
        packageReceiverRegistered = true
    }

    private fun unregisterPackageReceiverIfNeeded() {
        if (!packageReceiverRegistered) return
        try {
            unregisterReceiver(packageChangeReceiver)
        } catch (_: IllegalArgumentException) {
            // Receiver was already unregistered.
        } finally {
            packageReceiverRegistered = false
        }
    }

    private fun getLaunchableApps(): List<Map<String, String>> {
        val intent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }

        val activities = if (Build.VERSION.SDK_INT >= 33) {
            packageManager.queryIntentActivities(
                intent,
                PackageManager.ResolveInfoFlags.of(0L)
            )
        } else {
            @Suppress("DEPRECATION")
            packageManager.queryIntentActivities(intent, 0)
        }

        return activities
            .mapNotNull { info ->
                val activityInfo = info.activityInfo ?: return@mapNotNull null
                mapOf(
                    "label" to info.loadLabel(packageManager).toString(),
                    "packageName" to activityInfo.packageName
                )
            }
            .distinctBy { it["packageName"] }
            .sortedBy { it["label"]?.lowercase() }
    }
}
