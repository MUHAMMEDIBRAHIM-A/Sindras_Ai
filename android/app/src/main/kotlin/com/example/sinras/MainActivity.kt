package com.example.sinras

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.wifi.WifiManager
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val HARDWARE_CHANNEL = "sinras/hardware"
    private val PRIVACY_CHANNEL = "sinras/privacy"
    private val OVERLAY_CHANNEL = "sinras/overlay"
    private val APPS_CHANNEL = "sinras/apps"
    private val AUTOMATION_CHANNEL = "sinras/automation"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Hardware Connectivity Control Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HARDWARE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "toggleWifi" -> {
                    val enable = call.argument<Boolean>("enable") ?: false
                    val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                        @Suppress("DEPRECATION")
                        wifiManager.isWifiEnabled = enable
                        result.success(true)
                    } else {
                        startActivity(Intent(Settings.ACTION_WIFI_SETTINGS))
                        result.success(true)
                    }
                }
                "toggleBluetooth" -> {
                    startActivity(Intent(Settings.ACTION_BLUETOOTH_SETTINGS))
                    result.success(true)
                }
                "openVoiceInputSettings" -> {
                    try {
                        startActivity(Intent(Settings.ACTION_VOICE_INPUT_SETTINGS))
                        result.success(true)
                    } catch (e: Exception) {
                        startActivity(Intent(Settings.ACTION_SETTINGS))
                        result.success(true)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // 2. Strict Privacy & Payment Lock Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PRIVACY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAppProtected" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    val isProtected = isBankingOrPaymentApp(packageName)
                    result.success(isProtected)
                }
                else -> result.notImplemented()
            }
        }

        // 3. Floating Overlay Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OVERLAY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startSafetyOverlay" -> {
                    val intent = Intent(this, SafetyOverlayService::class.java)
                    startService(intent)
                    result.success(true)
                }
                "stopSafetyOverlay" -> {
                    val intent = Intent(this, SafetyOverlayService::class.java)
                    stopService(intent)
                    result.success(true)
                }
                "startCallBubble" -> {
                    val intent = Intent(this, CallOverlayService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // 4. Installed Apps Scanner & Whitelisting Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APPS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    val pm = packageManager
                    val packages = pm.getInstalledApplications(PackageManager.GET_META_DATA)
                    val appList = mutableListOf<Map<String, Any>>()

                    for (app in packages) {
                        val isUserApp = (app.flags and ApplicationInfo.FLAG_SYSTEM) == 0 ||
                                pm.getLaunchIntentForPackage(app.packageName) != null

                        if (isUserApp && app.packageName != packageName) {
                            val appName = pm.getApplicationLabel(app).toString()
                            val pkgName = app.packageName
                            val isLocked = isBankingOrPaymentApp(pkgName)

                            val appMap = mapOf(
                                "name" to appName,
                                "package" to pkgName,
                                "isLocked" to isLocked
                            )
                            appList.add(appMap)
                        }
                    }
                    result.success(appList)
                }
                "launchApp" -> {
                    val pkgName = call.argument<String>("package") ?: ""
                    if (isBankingOrPaymentApp(pkgName)) {
                        result.error("PRIVACY_LOCK", "Access to banking/payment app is blocked.", null)
                    } else {
                        val launchIntent = packageManager.getLaunchIntentForPackage(pkgName)
                        if (launchIntent != null) {
                            startActivity(launchIntent)
                            result.success(true)
                        } else {
                            result.error("LAUNCH_FAILED", "App launch intent unavailable.", null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }

        // 5. Universal UI Automation Channel (Accessibility Service Bridge)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUTOMATION_CHANNEL).setMethodCallHandler { call, result ->
            val service = SinrasAccessibilityService.instance
            if (service == null) {
                result.error("SERVICE_DISABLED", "SinrasAccessibilityService is not enabled in Settings.", null)
                return@setMethodCallHandler
            }

            when (call.method) {
                "prepareWhatsAppMessage" -> {
                    val contact = call.argument<String>("contact") ?: ""
                    val message = call.argument<String>("message") ?: ""
                    val success = service.prepareWhatsAppMessage(contact, message)
                    result.success(success)
                }
                "clickNodeByText", "clickByText" -> {
                    val text = call.argument<String>("text") ?: ""
                    val success = service.clickNodeByText(text)
                    result.success(success)
                }
                "setInputText" -> {
                    val query = call.argument<String>("query") ?: call.argument<String>("text") ?: ""
                    val textToSet = call.argument<String>("value") ?: call.argument<String>("textToSet") ?: ""
                    val success = service.setInputText(query, textToSet)
                    result.success(success)
                }
                "scrollForward" -> {
                    val success = service.scrollForward()
                    result.success(success)
                }
                "scrollBackward" -> {
                    val success = service.scrollBackward()
                    result.success(success)
                }
                "toggleWifi" -> {
                    val enable = call.argument<Boolean>("enable") ?: false
                    val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                        @Suppress("DEPRECATION")
                        wifiManager.isWifiEnabled = enable
                        result.success(true)
                    } else {
                        startActivity(Intent(Settings.ACTION_WIFI_SETTINGS))
                        result.success(true)
                    }
                }
                "toggleBluetooth" -> {
                    startActivity(Intent(Settings.ACTION_BLUETOOTH_SETTINGS))
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isBankingOrPaymentApp(pkgName: String): Boolean {
        val lower = pkgName.lowercase()
        return lower.contains("gpay") ||
                lower.contains("phonepe") ||
                lower.contains("paytm") ||
                lower.contains("bank") ||
                lower.contains("cred") ||
                lower.contains("upi") ||
                lower.contains("finance")
    }
}
