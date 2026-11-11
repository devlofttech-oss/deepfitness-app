package com.deepfitness.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createDefaultNotificationChannel()
    }

    /**
     * Creates the channel the manifest names as the default.
     *
     * On Android 8 and above a notification whose channel does not exist
     * is dropped silently — the send reports success and nothing appears.
     * Creating it is idempotent, so doing it on every launch is fine and
     * means it exists before the first push can arrive.
     */
    private fun createDefaultNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            getString(R.string.default_notification_channel_id),
            getString(R.string.default_notification_channel_name),
            // High, so a class starting shortly shows as a heads-up
            // rather than waiting silently in the tray.
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = getString(R.string.default_notification_channel_description)
        }

        getSystemService(NotificationManager::class.java)
            ?.createNotificationChannel(channel)
    }
}
