package com.nightcity.msgs

import android.app.Service
import android.content.Intent
import android.os.IBinder

class RespondViaMessageService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val to = intent?.data?.schemeSpecificPart?.substringBefore('?')
        val text = intent?.getStringExtra(Intent.EXTRA_TEXT)
        if (!to.isNullOrBlank() && !text.isNullOrBlank()) SmsStore.send(this, to, text)
        stopSelf(startId)
        return START_NOT_STICKY
    }
}
