package com.nightcity.msgs

import android.Manifest
import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.ContactsContract
import android.provider.Telephony
import android.telephony.SmsManager

object SmsStore {
    private val SMS: Uri = Uri.parse("content://sms")

    fun isDefault(ctx: Context) = Telephony.Sms.getDefaultSmsPackage(ctx) == ctx.packageName

    /** one row per thread, newest first. groups in code (fine for mvp, optimize later). */
    fun threads(ctx: Context): List<Map<String, Any?>> {
        val map = LinkedHashMap<Long, MutableMap<String, Any?>>()
        ctx.contentResolver.query(
            SMS, arrayOf("thread_id", "address", "body", "date", "type", "read"),
            null, null, "date DESC"
        )?.use { c ->
            while (c.moveToNext()) {
                val tid = c.getLong(0)
                val type = c.getInt(4)
                if (type == 3) continue // drafts
                val t = map.getOrPut(tid) {
                    mutableMapOf(
                        "id" to tid,
                        "address" to (c.getString(1) ?: ""),
                        "snippet" to (c.getString(2) ?: ""),
                        "date" to c.getLong(3),
                        "type" to type,
                        "unread" to 0
                    )
                }
                if (type == 1 && c.getInt(5) == 0) t["unread"] = (t["unread"] as Int) + 1
            }
        }
        val names = HashMap<String, String?>()
        return map.values.map { t ->
            val a = t["address"] as String
            t["name"] = names.getOrPut(a) { contactName(ctx, a) }
            t
        }
    }

    fun messages(ctx: Context, threadId: Long): List<Map<String, Any?>> {
        val out = ArrayList<Map<String, Any?>>()
        ctx.contentResolver.query(
            SMS, arrayOf("_id", "address", "body", "date", "type"),
            "thread_id=?", arrayOf(threadId.toString()), "date ASC"
        )?.use { c ->
            while (c.moveToNext()) {
                if (c.getInt(4) == 3) continue
                out.add(mapOf(
                    "id" to c.getLong(0),
                    "address" to (c.getString(1) ?: ""),
                    "body" to (c.getString(2) ?: ""),
                    "date" to c.getLong(3),
                    "type" to c.getInt(4)
                ))
            }
        }
        return out
    }

    fun markRead(ctx: Context, threadId: Long) {
        if (!isDefault(ctx)) return
        try {
            val v = ContentValues().apply { put("read", 1); put("seen", 1) }
            ctx.contentResolver.update(SMS, v, "thread_id=? AND read=0", arrayOf(threadId.toString()))
        } catch (_: SecurityException) {}
    }

    fun threadIdFor(ctx: Context, address: String): Long = try {
        Telephony.Threads.getOrCreateThreadId(ctx, address)
    } catch (_: Exception) { -1L }

    fun send(ctx: Context, address: String, body: String) {
        val sm: SmsManager = if (Build.VERSION.SDK_INT >= 31)
            ctx.getSystemService(SmsManager::class.java)
        else @Suppress("DEPRECATION") SmsManager.getDefault()
        val parts = sm.divideMessage(body)
        if (parts.size > 1) sm.sendMultipartTextMessage(address, null, parts, null, null)
        else sm.sendTextMessage(address, null, body, null, null)
        // default sms app is responsible for writing its own sent msgs
        if (isDefault(ctx)) store(ctx, Telephony.Sms.Sent.CONTENT_URI, address, body, System.currentTimeMillis(), true)
    }

    fun store(ctx: Context, uri: Uri, address: String, body: String, date: Long, read: Boolean) {
        val v = ContentValues().apply {
            put("address", address)
            put("body", body)
            put("date", date)
            put("read", if (read) 1 else 0)
            put("seen", if (read) 1 else 0)
        }
        ctx.contentResolver.insert(uri, v)
    }

    fun contactName(ctx: Context, number: String): String? {
        if (number.isBlank() ||
            ctx.checkSelfPermission(Manifest.permission.READ_CONTACTS) != PackageManager.PERMISSION_GRANTED
        ) return null
        return try {
            val uri = Uri.withAppendedPath(ContactsContract.PhoneLookup.CONTENT_FILTER_URI, Uri.encode(number))
            ctx.contentResolver.query(uri, arrayOf(ContactsContract.PhoneLookup.DISPLAY_NAME), null, null, null)
                ?.use { if (it.moveToFirst()) it.getString(0) else null }
        } catch (_: Exception) { null }
    }
}
