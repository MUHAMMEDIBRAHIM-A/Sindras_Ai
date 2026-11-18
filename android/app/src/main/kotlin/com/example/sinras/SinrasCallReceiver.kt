package com.example.sinras

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Build
import android.provider.Settings
import android.telephony.TelephonyManager
import android.util.Log

class SinrasCallReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "SinrasCallReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action == TelephonyManager.ACTION_PHONE_STATE_CHANGED) {
            val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
            Log.d(TAG, "Phone state changed: $state")

            if (state == TelephonyManager.EXTRA_STATE_RINGING) {
                @Suppress("DEPRECATION")
                val incomingNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER) ?: "Unknown Caller"

                val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
                val ringerMode = audioManager?.ringerMode ?: AudioManager.RINGER_MODE_NORMAL
                val isSilentOrVibrate = (ringerMode == AudioManager.RINGER_MODE_SILENT || ringerMode == AudioManager.RINGER_MODE_VIBRATE)

                val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                val isDnd = if (notificationManager != null) {
                    val filter = notificationManager.currentInterruptionFilter
                    filter != NotificationManager.INTERRUPTION_FILTER_ALL
                } else false

                // Only launch overlay if draw-over-apps is granted
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(context)) {
                    Log.w(TAG, "SYSTEM_ALERT_WINDOW not granted, skipping floating bubble")
                    return
                }

                val serviceIntent = Intent(context, CallOverlayService::class.java).apply {
                    putExtra(CallOverlayService.EXTRA_CALLER_NUMBER, incomingNumber)
                    putExtra(CallOverlayService.EXTRA_IS_SILENT_OR_DND, isSilentOrVibrate || isDnd)
                }

                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        context.startForegroundService(serviceIntent)
                    } else {
                        context.startService(serviceIntent)
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to start CallOverlayService", e)
                }
            } else if (state == TelephonyManager.EXTRA_STATE_IDLE) {
                try {
                    context.stopService(Intent(context, CallOverlayService::class.java))
                } catch (_: Exception) {}
            }
        }
    }
}
