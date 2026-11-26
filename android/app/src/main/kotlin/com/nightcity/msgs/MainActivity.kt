package com.nightcity.msgs

import android.content.ActivityNotFoundException
import android.content.Intent
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "nightcity/sms")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isDefault" -> result.success(SmsStore.isDefault(this))

                    "requestDefault" -> {
                        try {
                            startActivity(Intent("android.settings.DEFAULT_APPS_SETTINGS"))
                        } catch (_: ActivityNotFoundException) {
                            startActivity(Intent("android.settings.SETTINGS"))
                        }
                        result.success(true)
                    }

                    "threads" -> result.success(SmsStore.threads(this))

                    "messages" -> {
                        val threadId = call.argument<Number>("threadId")?.toLong()
                        if (threadId == null) result.error("bad_args", "threadId is required", null)
                        else result.success(SmsStore.messages(this, threadId))
                    }

                    "send" -> {
                        val address = call.argument<String>("address")
                        val body = call.argument<String>("body")
                        if (address == null || body == null) {
                            result.error("bad_args", "address and body are required", null)
                        } else {
                            SmsStore.send(this, address, body)
                            result.success(null)
                        }
                    }

                    "markRead" -> {
                        val threadId = call.argument<Number>("threadId")?.toLong()
                        if (threadId == null) result.error("bad_args", "threadId is required", null)
                        else {
                            SmsStore.markRead(this, threadId)
                            result.success(null)
                        }
                    }

                    "threadIdFor" -> {
                        val address = call.argument<String>("address")
                        if (address == null) result.error("bad_args", "address is required", null)
                        else result.success(SmsStore.threadIdFor(this, address))
                    }

                    "initialAddress" -> result.success(intent.getStringExtra("address"))

                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "nightcity/sms/events")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }

    companion object {
        @Volatile
        private var eventSink: EventChannel.EventSink? = null

        /** Called from BroadcastReceiver.onReceive, which may run off the UI thread. */
        @JvmStatic
        fun emit(event: Map<String, Any>) {
            Handler(Looper.getMainLooper()).post {
                eventSink?.success(event)
            }
        }
    }
}
