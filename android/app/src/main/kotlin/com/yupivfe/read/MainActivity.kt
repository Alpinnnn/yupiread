package com.yupivfe.read

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "Yupiread/shared_files"
    private var methodChannel: MethodChannel? = null
    private var hasProcessedIntent = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            // Handle method calls from Flutter if needed
            result.notImplemented()
        }
        
        // Handle shared files when Flutter engine is ready
        if (!hasProcessedIntent) {
            handleSharedIntent(intent)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleSharedIntent(intent)
    }

    private fun handleSharedIntent(intent: Intent?) {
        android.util.Log.d("MainActivity", "handleSharedIntent called with action: ${intent?.action}")
        
        when (intent?.action) {
            Intent.ACTION_SEND -> {
                val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                val mimeType = intent.type
                android.util.Log.d("MainActivity", "Found shared file: uri=$uri, mimeType=$mimeType")
                processFile(uri, mimeType, "SEND")
            }
            Intent.ACTION_VIEW -> {
                val uri = intent.data
                if (uri != null) {
                    val mimeType = intent.type ?: contentResolver.getType(uri)
                    android.util.Log.d("MainActivity", "Found open with file: uri=$uri, mimeType=$mimeType")
                    processFile(uri, mimeType, "VIEW")
                } else {
                    android.util.Log.w("MainActivity", "VIEW intent received but no data URI found")
                }
            }
        }
    }
    
    private fun processFile(uri: Uri?, mimeType: String?, action: String) {
        if (uri != null && mimeType != null) {
            try {
                // Copy file to app's internal storage
                val inputStream: InputStream? = contentResolver.openInputStream(uri)
                if (inputStream != null) {
                    val fileName = "${action.lowercase()}_${System.currentTimeMillis()}"
                    val extension = when {
                        mimeType.startsWith("image/") -> ".jpg"
                        mimeType == "application/pdf" -> ".pdf"
                        mimeType == "application/vnd.openxmlformats-officedocument.wordprocessingml.document" -> ".docx"
                        mimeType == "application/msword" -> ".doc"
                        mimeType == "text/plain" -> ".txt"
                        else -> ""
                    }
                    
                    val file = File(filesDir, "$fileName$extension")
                    val outputStream = FileOutputStream(file)
                    
                    inputStream.copyTo(outputStream)
                    inputStream.close()
                    outputStream.close()
                    
                    // Send file path to Flutter with delay to ensure Flutter is ready
                    android.util.Log.d("MainActivity", "Sending to Flutter: ${file.absolutePath}")
                    android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                        android.util.Log.d("MainActivity", "Invoking method channel")
                        val methodName = if (action == "VIEW") "handleOpenWithFile" else "handleSharedFile"
                        methodChannel?.invokeMethod(methodName, mapOf(
                            "filePath" to file.absolutePath,
                            "mimeType" to mimeType,
                            "action" to action
                        ))
                    }, 1000) // 1 second delay
                    
                    // Mark intent as processed
                    hasProcessedIntent = true
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
