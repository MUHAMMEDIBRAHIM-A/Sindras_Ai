package com.example.sinras

import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

class SafetyOverlayService : Service() {

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        createFloatingOverlay()
    }

    private fun createFloatingOverlay() {
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setBackgroundColor(Color.parseColor("#CC111827")) // Semi-transparent dark bg
            setPadding(16, 12, 16, 12)
        }

        val title = TextView(this).apply {
            text = "🛡️ SINRAS"
            setTextColor(Color.WHITE)
            textSize = 12f
            setPadding(0, 0, 12, 0)
        }

        val btnPause = Button(this).apply {
            text = "PAUSE"
            textSize = 10f
            setBackgroundColor(Color.parseColor("#EAB308")) // Yellow
            setOnClickListener {
                // Trigger pause
                stopSelf()
            }
        }

        val btnStop = Button(this).apply {
            text = "STOP"
            textSize = 10f
            setBackgroundColor(Color.parseColor("#EF4444")) // Red
            setOnClickListener {
                stopSelf()
            }
        }

        val btnExit = Button(this).apply {
            text = "EXIT"
            textSize = 10f
            setBackgroundColor(Color.parseColor("#6B7280")) // Gray
            setOnClickListener {
                stopSelf()
            }
        }

        layout.addView(title)
        layout.addView(btnPause)
        layout.addView(btnStop)
        layout.addView(btnExit)

        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.END
            x = 20
            y = 100
        }

        overlayView = layout
        windowManager?.addView(overlayView, params)
    }

    override fun onDestroy() {
        super.onDestroy()
        if (overlayView != null) {
            windowManager?.removeView(overlayView)
        }
    }
}
