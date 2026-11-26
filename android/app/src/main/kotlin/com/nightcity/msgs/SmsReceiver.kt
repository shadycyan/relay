package com.nightcity.msgs

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony

class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_DELIVER_ACTION) return
        val msgs = Telephony.Sms.Intents.getMessagesFromIntent(intent) ?: return
        // multipart sms arrive as several pdus, glue them per sender
        msgs.groupBy { it.displayOriginatingAddress ?: "" }.forEach { (addr, parts) ->
            val body = parts.joinToString("") { it.displayMessageBody ?: "" }
            SmsStore.store(ctx, Telephony.Sms.Inbox.CONTENT_URI, addr, body, parts.first().timestampMillis, false)
            Notifier.show(ctx, addr, body)
        }
        MainActivity.emit(mapOf("type" to "incoming"))
    }
}
