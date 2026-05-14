package com.legendarysoftware.redpdf.signpdf_scanpdf

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.redpdf/download"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "saveToDownloads") {
                    val bytes = call.argument<ByteArray>("bytes")
                    val fileName = call.argument<String>("fileName")
                    val subDir = call.argument<String>("subDir") ?: "RedPdf_sign"

                    if (bytes == null || fileName == null) {
                        result.error("INVALID_ARGS", "bytes and fileName are required", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val savedPath = saveToDownloads(bytes, fileName, subDir)
                        result.success(savedPath)
                    } catch (e: Exception) {
                        result.error("SAVE_ERROR", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun saveToDownloads(bytes: ByteArray, fileName: String, subDir: String): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Android 10+ — use MediaStore (no permissions needed)
            val contentValues = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, "application/pdf")
                put(MediaStore.Downloads.RELATIVE_PATH, "Download/$subDir")
            }

            val resolver = contentResolver
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
                ?: throw Exception("Failed to create MediaStore entry")

            resolver.openOutputStream(uri)?.use { outputStream ->
                outputStream.write(bytes)
                outputStream.flush()
            } ?: throw Exception("Failed to open output stream")

            return "${Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)}/$subDir/$fileName"
        } else {
            // Android 9 and below — direct file write
            val dir = File(
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
                subDir
            )
            if (!dir.exists()) dir.mkdirs()

            val file = File(dir, fileName)
            file.writeBytes(bytes)
            return file.absolutePath
        }
    }
}
