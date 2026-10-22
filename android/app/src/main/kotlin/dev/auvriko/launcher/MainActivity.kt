package dev.auvriko.launcher

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.hardware.camera2.CameraManager
import android.net.wifi.WifiManager
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        // Accessed by FaruNotificationService to push events to Flutter
        @Volatile
        var notificationChannel: MethodChannel? = null
    }

    private val appsChannelName   = "dev.faru.launcher/apps"
    private val notifChannelName  = "dev.faru.launcher/notifications"
    private val toggleChannelName = "dev.faru.launcher/toggles"

    private var appsChannel: MethodChannel?   = null
    private var toggleChannel: MethodChannel? = null

    private var torchOn = false
    private var packageReceiverRegistered = false

    private val packageChangeReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val action = intent?.action ?: return
            if (action == Intent.ACTION_PACKAGE_ADDED  ||
                action == Intent.ACTION_PACKAGE_REMOVED ||
                action == Intent.ACTION_PACKAGE_REPLACED) {
                appsChannel?.invokeMethod("onPackagesChanged", null)
            }
        }
    }

    // ── configureFlutterEngine ─────────────────────────────────────────────
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // ── Apps channel (unchanged logic) ─────────────────────────────────
        val ac = MethodChannel(messenger, appsChannelName)
        appsChannel = ac
        ac.setMethodCallHandler { call, result ->
            when (call.method) {
                "getApps" -> try { result.success(getLaunchableApps()) }
                             catch (e: Exception) { result.error("APP_DISCOVERY_FAILED", e.message, null) }
                "launchApp" -> {
                    val pkg = call.argument<String>("packageName")
                    if (pkg.isNullOrBlank()) {
                        result.error("INVALID_ARGUMENT", "packageName required", null)
                    } else {
                        try {
                            val intent = packageManager.getLaunchIntentForPackage(pkg)
                            if (intent == null) result.error("NOT_LAUNCHABLE", "No launch activity", null)
                            else { startActivity(intent); result.success(true) }
                        } catch (e: Exception) { result.error("LAUNCH_FAILED", e.message, null) }
                    }
                }
                else -> result.notImplemented()
            }
        }

        // ── Notification channel ───────────────────────────────────────────
        val nc = MethodChannel(messenger, notifChannelName)
        notificationChannel = nc
        nc.setMethodCallHandler { call, result ->
            when (call.method) {
                "isPermissionGranted" -> result.success(isNotificationListenerEnabled())
                "requestPermission"   -> {
                    startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                    result.success(null)
                }
                "getNotifications"    -> result.success(FaruNotificationService.getActiveNotifications())
                "dismissNotification" -> {
                    val key = call.argument<String>("key")
                    if (key != null) FaruNotificationService.dismissNotification(key)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // ── Quick-toggle channel ───────────────────────────────────────────
        val tc = MethodChannel(messenger, toggleChannelName)
        toggleChannel = tc
        tc.setMethodCallHandler { call, result ->
            when (call.method) {
                "getStates"      -> result.success(getToggleStates())
                "toggleWifi"     -> { toggleWifi();     result.success(null) }
                "toggleBluetooth"-> { toggleBluetooth();result.success(null) }
                "toggleTorch"    -> { toggleTorch();    result.success(null) }
                "toggleAirplane" -> { openAirplaneSettings(); result.success(null) }
                "toggleDnd"      -> { openDndSettings();      result.success(null) }
                "openBrightness" -> { openDisplaySettings();  result.success(null) }
                "getBrightness"  -> result.success(getScreenBrightness())
                "setBrightness"  -> {
                    val v = call.argument<Int>("value") ?: 128
                    setScreenBrightness(v)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    // ── Lifecycle ──────────────────────────────────────────────────────────
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
        appsChannel?.setMethodCallHandler(null);   appsChannel   = null
        notificationChannel?.setMethodCallHandler(null); notificationChannel = null
        toggleChannel?.setMethodCallHandler(null); toggleChannel = null
        super.onDestroy()
    }

    // ── Package receiver ──────────────────────────────────────────────────
    private fun registerPackageReceiverIfNeeded() {
        if (packageReceiverRegistered) return
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_PACKAGE_ADDED)
            addAction(Intent.ACTION_PACKAGE_REMOVED)
            addAction(Intent.ACTION_PACKAGE_REPLACED)
            addDataScheme("package")
        }
        if (Build.VERSION.SDK_INT >= 33)
            registerReceiver(packageChangeReceiver, filter, Context.RECEIVER_EXPORTED)
        else
            registerReceiver(packageChangeReceiver, filter)
        packageReceiverRegistered = true
    }

    private fun unregisterPackageReceiverIfNeeded() {
        if (!packageReceiverRegistered) return
        try { unregisterReceiver(packageChangeReceiver) }
        catch (_: IllegalArgumentException) {}
        finally { packageReceiverRegistered = false }
    }

    // ── App list ──────────────────────────────────────────────────────────
    private fun getLaunchableApps(): List<Map<String, String>> {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val activities = if (Build.VERSION.SDK_INT >= 33)
            packageManager.queryIntentActivities(intent, PackageManager.ResolveInfoFlags.of(0L))
        else
            @Suppress("DEPRECATION") packageManager.queryIntentActivities(intent, 0)

        return activities.mapNotNull { info ->
            val ai = info.activityInfo ?: return@mapNotNull null
            mapOf("label" to info.loadLabel(packageManager).toString(),
                  "packageName" to ai.packageName)
        }.distinctBy { it["packageName"] }.sortedBy { it["label"]?.lowercase() }
    }

    // ── Notification helpers ──────────────────────────────────────────────
    private fun isNotificationListenerEnabled(): Boolean {
        val flat = Settings.Secure.getString(contentResolver,
            "enabled_notification_listeners") ?: return false
        return flat.contains(ComponentName(this, FaruNotificationService::class.java).flattenToString())
    }

    // ── Toggle helpers ────────────────────────────────────────────────────
    private fun getToggleStates(): Map<String, Any?> {
        val wifiMgr = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
        val wifiOn  = wifiMgr?.isWifiEnabled ?: false

        val btAdapter = (getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)
            ?.adapter
        val btOn = if (Build.VERSION.SDK_INT >= 31) {
            checkSelfPermission(android.Manifest.permission.BLUETOOTH_CONNECT) ==
                PackageManager.PERMISSION_GRANTED && btAdapter?.isEnabled == true
        } else {
            @Suppress("DEPRECATION") btAdapter?.isEnabled == true
        }

        val airplaneOn = Settings.Global.getInt(contentResolver,
            Settings.Global.AIRPLANE_MODE_ON, 0) != 0

        return mapOf(
            "wifi"      to wifiOn,
            "bluetooth" to btOn,
            "torch"     to torchOn,
            "airplane"  to airplaneOn,
            "brightness" to getScreenBrightness(),
        )
    }

    @Suppress("DEPRECATION")
    private fun toggleWifi() {
        val wm = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager ?: return
        if (Build.VERSION.SDK_INT < 29) {
            wm.isWifiEnabled = !wm.isWifiEnabled
        } else {
            // Android 10+: open wifi panel — direct toggling is restricted
            val panelIntent = Intent(Settings.Panel.ACTION_WIFI)
            panelIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(panelIntent)
        }
    }

    private fun toggleBluetooth() {
        val adapter = (getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)
            ?.adapter ?: return
        if (Build.VERSION.SDK_INT >= 31) {
            if (checkSelfPermission(android.Manifest.permission.BLUETOOTH_CONNECT)
                    != PackageManager.PERMISSION_GRANTED) {
                requestPermissions(arrayOf(android.Manifest.permission.BLUETOOTH_CONNECT), 1)
                return
            }
        }
        @Suppress("DEPRECATION")
        if (adapter.isEnabled) adapter.disable() else adapter.enable()
    }

    private fun toggleTorch() {
        val cm = getSystemService(Context.CAMERA_SERVICE) as? CameraManager ?: return
        try {
            val cameraId = cm.cameraIdList.firstOrNull() ?: return
            torchOn = !torchOn
            cm.setTorchMode(cameraId, torchOn)
        } catch (_: Exception) { torchOn = false }
    }

    private fun openAirplaneSettings() {
        startActivity(Intent(Settings.ACTION_AIRPLANE_MODE_SETTINGS)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    }

    private fun openDndSettings() {
        startActivity(Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    }

    private fun openDisplaySettings() {
        startActivity(Intent(Settings.ACTION_DISPLAY_SETTINGS)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    }

    private fun getScreenBrightness(): Int {
        return try {
            Settings.System.getInt(contentResolver, Settings.System.SCREEN_BRIGHTNESS)
        } catch (_: Exception) { 128 }
    }

    private fun setScreenBrightness(value: Int) {
        try {
            if (Settings.System.canWrite(this)) {
                Settings.System.putInt(contentResolver,
                    Settings.System.SCREEN_BRIGHTNESS, value.coerceIn(0, 255))
            } else {
                startActivity(Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            }
        } catch (_: Exception) {}
    }
}
