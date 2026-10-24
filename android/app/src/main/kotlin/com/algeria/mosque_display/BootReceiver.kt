package com.algeria.mosque_display

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val CHANNEL_ID = "mosque_display_boot"
        private const val NOTIFICATION_ID = 777
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        val validActions = setOf(
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_LOCKED_BOOT_COMPLETED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON"
        )

        if (action in validActions) {
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }

            // Strategy 1: Direct activity launch (Android 7 - 9, and Android 10+ with granted permissions)
            try {
                context.startActivity(launchIntent)
            } catch (_: Exception) {
            }

            // Strategy 2: High-priority FullScreenIntent notification (Official bypass for Android 10-14 background restrictions)
            try {
                val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }

                val pendingIntent = PendingIntent.getActivity(context, 0, launchIntent, flags)
                val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager

                if (notificationManager != null) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val channel = NotificationChannel(
                            CHANNEL_ID,
                            "Mosque Display Autostart",
                            NotificationManager.IMPORTANCE_HIGH
                        ).apply {
                            description = "Starts mosque display on TV power on"
                            setSound(null, null)
                        }
                        notificationManager.createNotificationChannel(channel)
                    }

                    val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        Notification.Builder(context, CHANNEL_ID)
                    } else {
                        @Suppress("DEPRECATION")
                        Notification.Builder(context)
                    }

                    builder.setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
                        .setContentTitle("منارة المساجد")
                        .setContentText("تشغيل تلقائي...")
                        .setFullScreenIntent(pendingIntent, true)
                        .setAutoCancel(true)

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        builder.setCategory(Notification.CATEGORY_ALARM)
                            .setPriority(Notification.PRIORITY_MAX)
                    }

                    notificationManager.notify(NOTIFICATION_ID, builder.build())
                }
            } catch (_: Exception) {
            }
        }
    }
}
