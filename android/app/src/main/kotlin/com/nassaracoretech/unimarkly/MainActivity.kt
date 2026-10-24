package com.nassaracoretech.unimarkly

import android.content.Intent
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * Besides hosting Flutter, this receives documents other apps open with
 * UniMarkLy (VIEW) or send to it (SEND), copies them to the app's private
 * cache, and tells the Dart side.
 *
 * Events are held until Dart says it is ready, so a document that started the
 * app is not lost, and each intent is handled once.
 */
class MainActivity : FlutterActivity() {
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    private var channel: MethodChannel? = null
    private var dartReady = false
    private val held = mutableListOf<Map<String, Any?>>()
    private var incoming: IncomingFiles? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val files = IncomingFiles(contentResolver, cacheDir)
        incoming = files
        worker.execute { files.prune(PRUNE_AFTER_MILLIS) }

        val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel = ch
        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                "ready" -> {
                    dartReady = true
                    val pending = ArrayList(held)
                    held.clear()
                    result.success(pending)
                }
                else -> result.notImplemented()
            }
        }
        handle(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handle(intent)
    }

    override fun onDestroy() {
        channel?.setMethodCallHandler(null)
        channel = null
        dartReady = false
        super.onDestroy()
    }

    private fun handle(intent: Intent?) {
        val files = incoming ?: return
        if (intent == null) return
        // Coming back to the app from the recent-apps list replays the intent
        // that first started it; that document was already handled.
        if (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0) return

        val uris = files.urisIn(intent)
        if (uris.isEmpty()) return

        // Mark the intent as handled so a rotation or a second delivery does
        // not open the same document again.
        intent.action = Intent.ACTION_MAIN
        intent.data = null
        intent.clipData = null
        intent.removeExtra(Intent.EXTRA_STREAM)

        emit(mapOf("type" to "started", "count" to uris.size))
        worker.execute {
            val copied = mutableListOf<Map<String, Any?>>()
            val failures = mutableListOf<Map<String, Any?>>()
            for (uri in uris) {
                when (val r = files.copy(uri)) {
                    is CopyResult.Ok -> copied.add(r.file.toMap())
                    is CopyResult.Failed -> failures.add(r.failure.toMap())
                }
            }
            main.post { emit(mapOf("type" to "files", "files" to copied, "failures" to failures)) }
        }
    }

    private fun emit(event: Map<String, Any?>) {
        val ch = channel
        if (ch == null || !dartReady) {
            held.add(event)
        } else {
            ch.invokeMethod("event", event)
        }
    }

    companion object {
        const val CHANNEL = "com.nassaracoretech.unimarkly/incoming"
        private const val PRUNE_AFTER_MILLIS = 24L * 60 * 60 * 1000
    }
}
