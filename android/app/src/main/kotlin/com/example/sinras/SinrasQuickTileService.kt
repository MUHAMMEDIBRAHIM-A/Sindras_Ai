package com.example.sinras

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import androidx.core.app.NotificationCompat

class SinrasQuickTileService : TileService() {

    override fun onClick() {
        super.onClick()
        val tile = qsTile ?: return

        if (tile.state == Tile.STATE_INACTIVE) {
            tile.state = Tile.STATE_ACTIVE
            tile.label = "SINRAS: ON"
            tile.updateTile()
            sendNotification("SINRAS PRO AI Activated", "Voice HUD and Hardware Guardrails are active.")
        } else {
            tile.state = Tile.STATE_INACTIVE
            tile.label = "SINRAS: OFF"
            tile.updateTile()
            sendNotification("SINRAS PRO AI Deactivated", "Voice HUD and System Overlay paused.")
        }
    }

    private fun sendNotification(title: String, message: String) {
        val channelId = "sinras_quick_tile_channel"
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "SINRAS Status Updates",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            manager.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle(title)
            .setContentText(message)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setAutoCancel(true)
            .build()

        manager.notify(1001, notification)
    }
}
