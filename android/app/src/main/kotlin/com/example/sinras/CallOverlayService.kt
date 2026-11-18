package com.example.sinras

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Color
import android.graphics.PixelFormat
import android.media.MediaRecorder
import android.os.Build
import android.os.CountDownTimer
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.telecom.TelecomManager
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class CallOverlayService : Service(), TextToSpeech.OnInitListener {

    companion object {
        const val EXTRA_CALLER_NUMBER = "extra_caller_number"
        const val EXTRA_IS_SILENT_OR_DND = "extra_is_silent_or_dnd"
        private const val CHANNEL_ID = "sinras_call_summary_channel"
        private const val FOREGROUND_NOTIFICATION_ID = 2001
        private const val SUMMARY_NOTIFICATION_ID = 2002
        private const val TAG = "CallOverlayService"
    }

    private var windowManager: WindowManager? = null
    private var bubbleView: View? = null
    private var countDownTimer: CountDownTimer? = null
    private var isAiCancelled = false
    private var callerNumber: String = "Unknown Caller"
    private var isSilentOrDnd: Boolean = false

    private var textToSpeech: TextToSpeech? = null
    private var isTtsReady = false
    private var mediaRecorder: MediaRecorder? = null
    private var currentRecordingFile: File? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as? WindowManager
        createNotificationChannel()
        textToSpeech = TextToSpeech(applicationContext, this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        callerNumber = intent?.getStringExtra(EXTRA_CALLER_NUMBER) ?: "Unknown Caller"
        isSilentOrDnd = intent?.getBooleanExtra(EXTRA_IS_SILENT_OR_DND, false) ?: false

        startForegroundNotification()

        if (bubbleView == null) {
            createCallBubbleOverlay()
        }

        return START_NOT_STICKY
    }

    private fun startForegroundNotification() {
        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("SINRAS Call Assistant Active")
            .setContentText("Monitoring incoming call from $callerNumber")
            .setSmallIcon(android.R.drawable.ic_menu_call)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                startForeground(
                    FOREGROUND_NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                )
            } else {
                startForeground(FOREGROUND_NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            Log.w(TAG, "startForeground fallback: ${e.message}")
            try {
                startForeground(FOREGROUND_NOTIFICATION_ID, notification)
            } catch (_: Exception) {}
        }
    }

    private fun createCallBubbleOverlay() {
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#EE0F172A")) // Dark slate semi-transparent
            setPadding(32, 24, 32, 24)
        }

        val tvTitle = TextView(this).apply {
            text = "📞 SINRAS Call Assistant"
            setTextColor(Color.WHITE)
            textSize = 13f
        }

        val tvCaller = TextView(this).apply {
            text = callerNumber
            setTextColor(Color.parseColor("#38BDF8")) // Cyan
            textSize = 14f
            setPadding(0, 4, 0, 4)
        }

        val tvTimer = TextView(this).apply {
            text = "Auto-answering in 5s..."
            setTextColor(Color.parseColor("#4ADE80")) // Green
            textSize = 12f
            setPadding(0, 4, 0, 8)
        }

        val tvHint = TextView(this).apply {
            text = "Single Tap: AI OFF | Long Press: Answer Now"
            setTextColor(Color.LTGRAY)
            textSize = 10f
        }

        layout.addView(tvTitle)
        layout.addView(tvCaller)
        layout.addView(tvTimer)
        layout.addView(tvHint)

        // Single Tap -> Turn OFF AI for this call (normal ringing)
        layout.setOnClickListener {
            isAiCancelled = true
            countDownTimer?.cancel()
            sendSummaryNotification(
                "Call from $callerNumber",
                "AI auto-answer turned OFF by user. Ringing normally.",
                isImportant = false,
                recordingPath = null
            )
            removeBubble()
            stopSelf()
        }

        // Long Press -> Answer Instantly via AI
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
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.CENTER_HORIZONTAL or Gravity.TOP
            y = 180
        }

        bubbleView = layout
        try {
            windowManager?.addView(bubbleView, params)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to add overlay view", e)
        }

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
        removeBubble()

        // 1. Accept ringing call via TelecomManager (API 26+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val telecomManager = getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
            try {
                @Suppress("DEPRECATION")
                telecomManager?.acceptRingingCall()
                Log.d(TAG, "Call accepted via TelecomManager")
            } catch (e: SecurityException) {
                Log.e(TAG, "ANSWER_PHONE_CALLS permission not granted", e)
            } catch (e: Exception) {
                Log.e(TAG, "Error accepting ringing call", e)
            }
        }

        // 2. Play Cute Female Greeting via TextToSpeech
        val greeting = "Sorry, they are currently unavailable. Please leave a message after the tone."
        speakGreeting(greeting)

        // 3. Start Recording Audio after a brief delay
        Handler(Looper.getMainLooper()).postDelayed({
            startAudioRecording()
        }, 1500)

        // 4. Conclude voicemail session after 15 seconds of recording
        Handler(Looper.getMainLooper()).postDelayed({
            stopAudioRecordingAndPostSummary()
        }, 16500)
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            textToSpeech?.let { tts ->
                tts.language = Locale.US
                tts.setPitch(1.2f)       // Cute female pitch
                tts.setSpeechRate(0.9f)   // Natural conversational speed
                isTtsReady = true
            }
        }
    }

    private fun speakGreeting(greeting: String) {
        if (isTtsReady && textToSpeech != null) {
            textToSpeech?.speak(greeting, TextToSpeech.QUEUE_FLUSH, null, "GREETING_ID")
        }
    }

    private fun startAudioRecording() {
        try {
            val recordingsDir = File(getExternalFilesDir(null), "Recordings/SINRAS_Calls").apply { mkdirs() }
            val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
            val safeNumber = callerNumber.replace(Regex("[^0-9+]"), "_")
            currentRecordingFile = File(recordingsDir, "call_${safeNumber}_$timestamp.m4a")

            mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                MediaRecorder(applicationContext)
            } else {
                @Suppress("DEPRECATION")
                MediaRecorder()
            }.apply {
                setAudioSource(MediaRecorder.AudioSource.MIC)
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                setOutputFile(currentRecordingFile?.absolutePath)
                prepare()
                start()
            }
            Log.d(TAG, "Call recording started at: ${currentRecordingFile?.absolutePath}")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start MediaRecorder", e)
        }
    }

    private fun stopAudioRecordingAndPostSummary() {
        try {
            mediaRecorder?.apply {
                stop()
                release()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping MediaRecorder", e)
        } finally {
            mediaRecorder = null
        }

        // Call classification heuristic
        val isImportant = isSilentOrDnd || (callerNumber.length > 5 && !callerNumber.startsWith("1800"))
        val classification = if (isImportant) "[IMPORTANT]" else "[NORMAL]"
        val recordingName = currentRecordingFile?.name ?: "call_recording.m4a"

        sendSummaryNotification(
            title = "$classification Voicemail from $callerNumber",
            summary = "Greeting spoken. Caller voicemail saved to Recordings/SINRAS_Calls/$recordingName",
            isImportant = isImportant,
            recordingPath = currentRecordingFile?.absolutePath
        )

        stopSelf()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "SINRAS Call Assistant",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Summaries and notifications for incoming calls processed by SINRAS AI"
                enableLights(true)
                lightColor = Color.CYAN
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun sendSummaryNotification(title: String, summary: String, isImportant: Boolean, recordingPath: String?) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(summary)
            .setStyle(NotificationCompat.BigTextStyle().bigText(summary))
            .setSmallIcon(android.R.drawable.ic_menu_call)
            .setPriority(if (isImportant) NotificationCompat.PRIORITY_HIGH else NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .build()

        manager.notify(SUMMARY_NOTIFICATION_ID, notification)
    }

    private fun removeBubble() {
        if (bubbleView != null) {
            try {
                windowManager?.removeView(bubbleView)
            } catch (e: Exception) {
                Log.e(TAG, "Error removing bubble view", e)
            }
            bubbleView = null
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        countDownTimer?.cancel()
        removeBubble()
        try {
            textToSpeech?.stop()
            textToSpeech?.shutdown()
        } catch (_: Exception) {}

        try {
            mediaRecorder?.release()
        } catch (_: Exception) {}
    }
}
