package com.nightcity.msgs

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

object Notifier {
    private const val CH = "messages"

    fun show(ctx: Context, address: String, body: String) {
        val nm = ctx.getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= 26) {
            nm.createNotificationChannel(NotificationChannel(CH, "Messages", NotificationManager.IMPORTANCE_HIGH))
        }
        val open = Intent(ctx, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("address", address)
        }
        val pi = PendingIntent.getActivity(
            ctx, address.hashCode(), open,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val n = NotificationCompat.Builder(ctx, CH)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(SmsStore.contactName(ctx, address) ?: address)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setColor(0xFFFCEE09.toInt())
            .setAutoCancel(true)
            .setContentIntent(pi)
            .build()
        try { nm.notify(address.hashCode(), n) } catch (_: SecurityException) {}
    }
}
