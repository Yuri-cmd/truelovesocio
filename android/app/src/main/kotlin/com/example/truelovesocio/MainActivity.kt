package com.truelove.truelovesocio

import android.content.ContentValues
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream

class MainActivity: FlutterActivity() {
	private val CHANNEL = "app.channel.documents"

	override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			when (call.method) {
				"saveFileToDownloads" -> {
					val path = call.argument<String>("path") ?: run {
						result.error("INVALID_ARGS", "path is null", null); return@setMethodCallHandler
					}
					val displayName = call.argument<String>("displayName") ?: File(path).name
					try {
						val out = saveFileToDownloads(path, displayName)
						result.success(out)
					} catch (e: Exception) {
						result.error("SAVE_FAILED", e.message, null)
					}
				}
				else -> result.notImplemented()
			}
		}
	}

	@Throws(Exception::class)
	private fun saveFileToDownloads(srcPath: String, displayName: String): String {
		val srcFile = File(srcPath)
		if (!srcFile.exists()) throw Exception("Source file not found: $srcPath")

		val resolver = applicationContext.contentResolver

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
			val contentValues = ContentValues().apply {
				put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
				put(MediaStore.MediaColumns.MIME_TYPE, "image/jpeg")
				put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
				put(MediaStore.MediaColumns.IS_PENDING, 1)
			}

			val collection = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
			val uri = resolver.insert(collection, contentValues) ?: throw Exception("Failed to create new MediaStore record")

			resolver.openOutputStream(uri).use { outStream ->
				FileInputStream(srcFile).use { input ->
					input.copyTo(outStream!!)
				}
			}

			// Make the file visible
			contentValues.clear()
			contentValues.put(MediaStore.MediaColumns.IS_PENDING, 0)
			resolver.update(uri, contentValues, null, null)

			return uri.toString()
		} else {
			// For older devices write directly to Downloads folder
			val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
			if (!downloadsDir.exists()) downloadsDir.mkdirs()
			val dest = File(downloadsDir, displayName)

			FileInputStream(srcFile).use { input ->
				FileOutputStream(dest).use { out ->
					input.copyTo(out)
				}
			}

			// Refresh media store so file appears in Downloads
			MediaScannerConnection.scanFile(applicationContext, arrayOf(dest.absolutePath), null, null)

			return dest.absolutePath
		}
	}
}
