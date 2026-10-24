package com.nassaracoretech.unimarkly

import android.content.ContentProvider
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.database.MatrixCursor
import android.net.Uri
import android.provider.OpenableColumns
import androidx.test.core.app.ApplicationProvider
import java.io.ByteArrayInputStream
import java.io.File
import java.io.InputStream
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

/** Answers the two columns a file manager or mail app answers with. */
class NameProvider : ContentProvider() {
    var name: String? = null
    var size: Long? = null

    override fun onCreate() = true
    override fun query(uri: Uri, p: Array<String>?, s: String?, a: Array<String>?, o: String?): Cursor {
        val c = MatrixCursor(arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE))
        c.addRow(arrayOf<Any?>(name, size))
        return c
    }
    override fun getType(uri: Uri): String? = "application/pdf"
    override fun insert(uri: Uri, values: ContentValues?): Uri? = null
    override fun delete(uri: Uri, s: String?, a: Array<String>?) = 0
    override fun update(uri: Uri, v: ContentValues?, s: String?, a: Array<String>?) = 0
}

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class IncomingFilesTest {
    private lateinit var context: Context
    private lateinit var cache: File
    private lateinit var provider: NameProvider

    @Before
    fun setUp() {
        context = ApplicationProvider.getApplicationContext()
        cache = File(context.cacheDir, "test-" + System.nanoTime()).also { it.mkdirs() }
        provider = Robolectric.setupContentProvider(NameProvider::class.java, "test.docs")
    }

    @After
    fun tearDown() {
        cache.deleteRecursively()
    }

    private fun files(max: Long = IncomingFiles.DEFAULT_MAX_BYTES) = IncomingFiles(context.contentResolver, cache, max)

    private fun uri(path: String, bytes: ByteArray = ByteArray(0)): Uri {
        val u = Uri.parse("content://test.docs/$path")
        shadowOf(context.contentResolver).registerInputStream(u, ByteArrayInputStream(bytes))
        return u
    }

    private fun ok(r: CopyResult): CopiedFile {
        assertTrue("expected a copy but got $r", r is CopyResult.Ok)
        return (r as CopyResult.Ok).file
    }

    private fun failure(r: CopyResult): CopyFailure {
        assertTrue("expected a failure but got $r", r is CopyResult.Failed)
        return (r as CopyResult.Failed).failure
    }

    // ---- copying ----

    @Test
    fun copiesTheBytesIntoItsOwnFolderUnderTheCache() {
        provider.name = "Results.pdf"
        val bytes = ByteArray(300_000) { (it % 251).toByte() } // more than one buffer
        val copied = ok(files().copy(uri("doc/1", bytes)))

        val f = File(copied.path)
        assertTrue(f.exists())
        assertTrue(f.canonicalPath.startsWith(cache.canonicalPath + File.separator + "incoming" + File.separator))
        assertEquals("Results.pdf", f.name)
        assertEquals(bytes.size.toLong(), copied.size)
        assertTrue(bytes.contentEquals(f.readBytes()))
        assertEquals("application/pdf", copied.mime)
    }

    @Test
    fun theSameDocumentOpenedTwiceGetsTwoCopiesAndNothingIsOverwritten() {
        provider.name = "a.csv"
        val first = ok(files().copy(uri("doc/2", "one".toByteArray())))
        val second = ok(files().copy(uri("doc/2b", "two".toByteArray())))
        assertNotEquals(first.path, second.path)
        assertEquals("one", File(first.path).readText())
        assertEquals("two", File(second.path).readText())
        assertNotEquals(first.id, second.id)
    }

    @Test
    fun aNameWithFoldersOrOddCharactersCanNotEscapeTheCopyFolder() {
        provider.name = "../../../data/data/app/databases/main.db"
        val copied = ok(files().copy(uri("doc/3", byteArrayOf(1, 2, 3))))
        assertEquals("main.db", copied.name)
        assertTrue(File(copied.path).canonicalPath.startsWith(cache.canonicalPath))

        assertEquals("a_b_c_.pdf", IncomingFiles.safeName("a:b*c?.pdf"))
        assertEquals("passwd", IncomingFiles.safeName("..\\..\\etc\\passwd"))
        assertEquals("hidden.txt", IncomingFiles.safeName(".hidden.txt"))
        assertEquals("document", IncomingFiles.safeName(""))
        assertEquals("document", IncomingFiles.safeName(null))
        assertEquals("document", IncomingFiles.safeName("../.."))
    }

    @Test
    fun aVeryLongNameIsShortenedButKeepsItsExtension() {
        val name = IncomingFiles.safeName("x".repeat(400) + ".xlsx")
        assertTrue(name.length <= 120)
        assertTrue(name.endsWith(".xlsx"))
    }

    @Test
    fun withoutADisplayNameTheLastPartOfTheAddressIsUsed() {
        provider.name = null
        val copied = ok(files().copy(uri("storage/report.docx", byteArrayOf(9))))
        assertEquals("report.docx", copied.name)
    }

    // ---- refusals ----

    @Test
    fun aFileAddressIsRefusedAndNothingIsCreated() {
        val result = files().copy(Uri.parse("file:///data/data/com.nassaracoretech.unimarkly/databases/x.db"))
        val failure = failure(result)
        assertTrue(failure.message.contains("does not accept"))
        assertFalse(File(cache, "incoming").exists())
    }

    @Test
    fun aFileLargerThanTheLimitIsRefusedBeforeAndWhileCopying() {
        provider.name = "big.pdf"
        provider.size = 5_000
        val declared = failure(files(max = 1_000).copy(uri("doc/big1", ByteArray(5_000))))
        assertTrue(declared.message.contains("too large"))

        // The size a sender declares can be wrong, so the count is enforced as it copies.
        provider.size = null
        val counted = failure(files(max = 1_000).copy(uri("doc/big2", ByteArray(5_000))))
        assertTrue(counted.message.contains("too large"))

        // No half-written copy is left behind.
        val left = File(cache, "incoming").listFiles()?.toList() ?: emptyList()
        assertTrue("left behind: $left", left.isEmpty())
    }

    @Test
    fun aDocumentThatCanNotBeOpenedIsReportedWithAReason() {
        provider.name = "gone.pdf"
        // Nothing registered for this address: the sender no longer has it.
        val failure = failure(files().copy(Uri.parse("content://test.docs/doc/gone")))
        assertEquals("gone.pdf", failure.name)
        assertTrue(failure.message.isNotEmpty())
        assertTrue((File(cache, "incoming").listFiles() ?: emptyArray()).isEmpty())
    }

    // ---- what an intent carries ----

    @Test
    fun aViewIntentCarriesItsData() {
        val u = Uri.parse("content://test.docs/doc/v")
        val intent = Intent(Intent.ACTION_VIEW).setDataAndType(u, "application/pdf")
        assertEquals(listOf(u), files().urisIn(intent))
    }

    @Test
    fun aSendIntentCarriesItsStream() {
        val u = Uri.parse("content://test.docs/doc/s")
        val intent = Intent(Intent.ACTION_SEND).setType("application/pdf").putExtra(Intent.EXTRA_STREAM, u)
        assertEquals(listOf(u), files().urisIn(intent))
    }

    @Test
    fun aSendMultipleIntentCarriesEveryStreamOnce() {
        val a = Uri.parse("content://test.docs/doc/a")
        val b = Uri.parse("content://test.docs/doc/b")
        val intent = Intent(Intent.ACTION_SEND_MULTIPLE).setType("image/jpeg")
            .putParcelableArrayListExtra(Intent.EXTRA_STREAM, arrayListOf(a, b, a))
        assertEquals(listOf(a, b), files().urisIn(intent))
    }

    @Test
    fun otherIntentsCarryNothing() {
        val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        assertTrue(files().urisIn(launcher).isEmpty())
        val other = Intent(Intent.ACTION_EDIT).setData(Uri.parse("content://test.docs/doc/e"))
        assertTrue(files().urisIn(other).isEmpty())
    }

    // ---- housekeeping ----

    @Test
    fun oldCopiesAreRemovedAndNewOnesKept() {
        provider.name = "k.csv"
        val kept = ok(files().copy(uri("doc/k", byteArrayOf(1))))
        val old = ok(files().copy(uri("doc/o", byteArrayOf(2))))
        File(old.path).parentFile!!.setLastModified(System.currentTimeMillis() - 3 * 24 * 3600 * 1000L)

        files().prune(24 * 3600 * 1000L)

        assertTrue(File(kept.path).exists())
        assertFalse(File(old.path).exists())
    }
}
