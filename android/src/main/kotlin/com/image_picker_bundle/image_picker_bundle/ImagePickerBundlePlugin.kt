package com.image_picker_bundle.image_picker_bundle

import android.app.Activity
import android.content.Intent
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File

/** ImagePickerBundlePlugin */
class ImagePickerBundlePlugin: FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {
  private lateinit var channel: MethodChannel
  private var activity: Activity? = null
  private var resultPending: MethodChannel.Result? = null

  private val REQUEST_GALLERY = 1001
  private val REQUEST_CAMERA = 1002

  private var cameraImageUri: Uri? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "image_picker_bundle")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    resultPending = result
    when (call.method) {
      "pickFromGallery" -> {
        val intent = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
        activity?.startActivityForResult(intent, REQUEST_GALLERY)
      }
      "pickFromCamera" -> {
        val imageFile = createImageFile()
        cameraImageUri = FileProvider.getUriForFile(
          activity!!,
          "${activity!!.packageName}.fileprovider",
          imageFile
        )
        val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
        intent.putExtra(MediaStore.EXTRA_OUTPUT, cameraImageUri)
        intent.addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
        activity?.startActivityForResult(intent, REQUEST_CAMERA)
      }
      else -> result.notImplemented()
    }
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addActivityResultListener { requestCode, resultCode, data ->
      if (resultCode == Activity.RESULT_OK) {
        when (requestCode) {
          REQUEST_GALLERY -> {
            val uri = data?.data
            if (uri != null) {
              val bitmap = MediaStore.Images.Media.getBitmap(activity!!.contentResolver, uri)
              sendBitmap(bitmap)
            } else {
              resultPending?.success(null)
            }
            true
          }
          REQUEST_CAMERA -> {
            if (cameraImageUri != null) {
              val stream = activity!!.contentResolver.openInputStream(cameraImageUri!!)
              val bitmap = BitmapFactory.decodeStream(stream)
              sendBitmap(bitmap)
            } else {
              resultPending?.success(null)
            }
            true
          }
          else -> false
        }
      } else {
        resultPending?.success(null)
        false
      }
    }
  }

  private fun sendBitmap(bitmap: android.graphics.Bitmap) {
    val stream = ByteArrayOutputStream()
    bitmap.compress(android.graphics.Bitmap.CompressFormat.JPEG, 100, stream)
    resultPending?.success(stream.toByteArray())
    resultPending = null
  }

  private fun createImageFile(): File {
    val storageDir = activity!!.getExternalFilesDir(Environment.DIRECTORY_PICTURES)
    return File.createTempFile(
      "IMG_${System.currentTimeMillis()}_",
      ".jpg",
      storageDir
    )
  }

  override fun onDetachedFromActivityForConfigChanges() {}
  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    onAttachedToActivity(binding)
  }
  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
