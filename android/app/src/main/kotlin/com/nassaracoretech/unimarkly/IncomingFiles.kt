package com.nassaracoretech.unimarkly

import android.content.ContentResolver
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import java.io.File
import java.io.FileNotFoundException
import java.io.IOException
import java.util.UUID

/** One document copied into the app's private cache, ready to hand to Flutter. */
data class CopiedFile(
    val id: String,
    val path: String,
    val name: String,
    val mime: String?,
    val size: Long,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "id" to id,
        "path" to path,
        "name" to name,
        "mime" to mime,
        "size" to size,
    )
}

/** A document that arrived but could not be copied, with the reason in plain words. */
data class CopyFailure(val name: String, val message: String) {
    fun toMap(): Map<String, Any?> = mapOf("name" to name, "message" to message)
}

sealed class CopyResult {
    data class Ok(val file: CopiedFile) : CopyResult()
    data class Failed(val failure: CopyFailure) : CopyResult()
}

/**
 * Receives documents from other apps.
 *
 * A document arrives as a `content://` URI. It is not a file path, and the
 * permission to read it may last only as long as the app that sent it. So each
 * document is streamed straight into a private copy under the cache folder
 * (never into shared storage), and everything after that works on the copy.
 * The original is only ever read.
 */
class IncomingFiles(
    private val resolver: ContentResolver,
    cacheDir: File,
    private val maxBytes: Long = DEFAULT_MAX_BYTES,
) {
    private val root = File(cacheDir, FOLDER)

    /** The documents an intent carries: the data of a VIEW, or the streams of a SEND. */
    fun urisIn(intent: Intent): List<Uri> {
        val action = intent.action
        if (action != Intent.ACTION_VIEW && action != Intent.ACTION_SEND && action != Intent.ACTION_SEND_MULTIPLE) {
            return emptyList()
        }
        val found = LinkedHashSet<Uri>()
        intent.data?.let { found.add(it) }
        if (action != Intent.ACTION_VIEW) {
            @Suppress("DEPRECATION")
            if (Build.VERSION.SDK_INT >= 33) {
                intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)?.let { found.add(it) }
                intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)?.let { found.addAll(it) }
            } else {
                (intent.getParcelableExtra<android.os.Parcelable>(Intent.EXTRA_STREAM) as? Uri)?.let { found.add(it) }
                intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)?.let { found.addAll(it) }
            }
        }
        val clip = intent.clipData
        if (clip != null) {
            for (i in 0 until clip.itemCount) clip.getItemAt(i).uri?.let { found.add(it) }
        }
        return found.toList()
    }

    /** Copies [uri] into its own folder under the cache and reports the result. */
    fun copy(uri: Uri): CopyResult {
        val shownName = safeName(displayName(uri))

        if (uri.scheme != ContentResolver.SCHEME_CONTENT) {
            return failed(
                shownName,
                "This file was sent in a way UniMarkLy does not accept. Open it from the Files app, " +
                    "or share it from the app that has it.",
            )
        }

        val declared = declaredSize(uri)
        if (declared != null && declared > maxBytes) return failed(shownName, tooLarge())

        val folder = File(root, UUID.randomUUID().toString())
        val target = File(folder, shownName)
        try {
            if (!folder.mkdirs()) return failed(shownName, "There is no room to keep a copy of this file on the phone.")
            val input = resolver.openInputStream(uri)
                ?: return cleanup(folder, shownName, "The app that sent this file did not let UniMarkLy read it. Try sharing it again.")
            var total = 0L
            input.use { source ->
                target.outputStream().use { sink ->
                    val buffer = ByteArray(64 * 1024)
                    while (true) {
                        val n = source.read(buffer)
                        if (n < 0) break
                        total += n
                        if (total > maxBytes) return cleanup(folder, shownName, tooLarge())
                        sink.write(buffer, 0, n)
                    }
                }
            }
            return CopyResult.Ok(
                CopiedFile(
                    id = UUID.randomUUID().toString(),
                    path = target.absolutePath,
                    name = shownName,
                    mime = resolver.getType(uri),
                    size = total,
                ),
            )
        } catch (e: SecurityException) {
            return cleanup(folder, shownName, "UniMarkLy is not allowed to read this file. Open it from the Files app, or share it again.")
        } catch (e: FileNotFoundException) {
            return cleanup(folder, shownName, "The file is no longer available. Open it again from where you found it.")
        } catch (e: IOException) {
            val full = e.message?.contains("ENOSPC") == true || e.message?.contains("No space") == true
            return cleanup(
                folder,
                shownName,
                if (full) "The phone is out of storage space, so the file could not be opened. Free some space and try again."
                else "The file could not be read. It may have been moved or deleted.",
            )
        }
    }

    /** Deletes copies older than [olderThanMillis]; called when the app starts. */
    fun prune(olderThanMillis: Long, now: Long = System.currentTimeMillis()) {
        val folders = root.listFiles() ?: return
        for (f in folders) {
            if (now - f.lastModified() > olderThanMillis) f.deleteRecursively()
        }
    }

    private fun displayName(uri: Uri): String? {
        if (uri.scheme == ContentResolver.SCHEME_CONTENT) {
            try {
                resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { c ->
                    if (c.moveToFirst()) {
                        val i = c.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                        if (i >= 0 && !c.isNull(i)) return c.getString(i)
                    }
                }
            } catch (_: Exception) {
                // Fall back to the last part of the address.
            }
        }
        return uri.lastPathSegment
    }

    private fun declaredSize(uri: Uri): Long? {
        try {
            resolver.query(uri, arrayOf(OpenableColumns.SIZE), null, null, null)?.use { c ->
                if (c.moveToFirst()) {
                    val i = c.getColumnIndex(OpenableColumns.SIZE)
                    if (i >= 0 && !c.isNull(i)) return c.getLong(i)
                }
            }
        } catch (_: Exception) {
        }
        return null
    }

    private fun tooLarge() =
        "This file is too large to open here. Share it with another app, or open it on a computer."

    private fun failed(name: String, message: String) = CopyResult.Failed(CopyFailure(name, message))

    private fun cleanup(folder: File, name: String, message: String): CopyResult {
        folder.deleteRecursively()
        return failed(name, message)
    }

    companion object {
        const val FOLDER = "incoming"
        const val DEFAULT_MAX_BYTES: Long = 200L * 1024 * 1024
        private val BAD = Regex("[\\p{Cntrl}:*?\"<>|]")

        /**
         * A file name that is safe to create: no folders, no control characters,
         * no leading dots, not too long, and never empty. The extension is kept.
         */
        fun safeName(raw: String?): String {
            var n = (raw ?: "").substringAfterLast('/').substringAfterLast('\\')
            n = BAD.replace(n, "_").trim().trimStart('.').trim()
            if (n.length > MAX_NAME) {
                val ext = n.substringAfterLast('.', "")
                n = if (ext.isNotEmpty() && ext.length <= 10) {
                    n.substring(0, MAX_NAME - ext.length - 1) + "." + ext
                } else {
                    n.substring(0, MAX_NAME)
                }
            }
            return if (n.isEmpty()) "document" else n
        }

        private const val MAX_NAME = 120
    }
}
