package com.example.sinras

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.CountDownTimer
import android.os.IBinder
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat

class CallOverlayService : Service() {

    private var windowManager: WindowManager? = null
    private var bubbleView: View? = null
    private var countDownTimer: CountDownTimer? = null
    private var isAiCancelled = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        createCallBubbleOverlay()
    }

    private fun createCallBubbleOverlay() {
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#EE0F172A")) // Dark blue semi-transparent
            setPadding(24, 20, 24, 20)
        }

        val tvTitle = TextView(this).apply {
            text = "📞 SINRAS Call Assistant"
            setTextColor(Color.WHITE)
            textSize = 13f
        }

        val tvTimer = TextView(this).apply {
            text = "Auto-answering in 5s..."
            setTextColor(Color.parseColor("#38BDF8")) // Cyan
            textSize = 12f
            setPadding(0, 8, 0, 8)
        }

        val tvHint = TextView(this).apply {
            text = "Tap: AI OFF | Long Press: Answer Now"
            setTextColor(Color.LTGRAY)
            textSize = 10f
        }

        layout.addView(tvTitle)
        layout.addView(tvTimer)
        layout.addView(tvHint)

        // Single Tap -> Turn OFF AI for this call
        layout.setOnClickListener {
            isAiCancelled = true
            countDownTimer?.cancel()
            sendSummaryNotification("Incoming Call", "AI auto-answer turned OFF by user. Ringing normally.")
            stopSelf()
        }

        // Long Press -> Answer Instantly
        layout.setOnLongClickListener {
            countDownTimer?.cancel()
            triggerAiCallAnswering()
            true
        }

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
            gravity = Gravity.CENTER_HORIZONTAL or Gravity.TOP
            y = 200
        }

        bubbleView = layout
        windowManager?.addView(bubbleView, params)

        startCountdown(tvTimer)
    }

    private fun startCountdown(tvTimer: TextView) {
        countDownTimer = object : CountDownTimer(5000, 1000) {
            override fun onTick(millisUntilFinished: Long) {
                val seconds = millisUntilFinished / 1000
                tvTimer.text = "Auto-answering in ${seconds}s..."
            }

            override fun onFinish() {
                if (!isAiCancelled) {
                    triggerAiCallAnswering()
                }
            }
        }.start()
    }

    private fun triggerAiCallAnswering() {
        sendSummaryNotification(
            "Call Answered by SINRAS AI",
            "Greeting spoken: 'Sorry, they are currently unavailable. Please leave a message after the tone.' Recording started."
        )
        stopSelf()
    }

    private fun sendSummaryNotification(title: String, summary: String) {
        val channelId = "sinras_call_summary_channel"
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Call Assistant Summaries",
                NotificationManager.IMPORTANCE_HIGH
            )
            manager.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle(title)
            .setContentText(summary)
            .setSmallIcon(android.R.drawable.ic_menu_call)
            .setAutoCancel(true)
            .build()

        manager.notify(2002, notification)
    }

    override fun onDestroy() {
        super.onDestroy()
        countDownTimer?.cancel()
        if (bubbleView != null) {
            windowManager?.removeView(bubbleView)
        }
    }
}
