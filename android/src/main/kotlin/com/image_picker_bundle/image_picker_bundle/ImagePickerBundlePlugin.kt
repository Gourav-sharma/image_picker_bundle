package com.image_picker_bundle.image_picker_bundle

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/** ImagePickerBundlePlugin */
class ImagePickerBundlePlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {
  private lateinit var channel: MethodChannel
  private var activity: Activity? = null
  private var resultPending: MethodChannel.Result? = null

  private val REQUEST_GALLERY_SINGLE = 1001
  private val REQUEST_CAMERA_IMAGE = 1002
  private val REQUEST_GALLERY_MULTI = 1003
  private val REQUEST_GALLERY_VIDEO = 1004
  private val REQUEST_CAMERA_VIDEO = 1005
  private val REQUEST_CAMERA_PERMISSION = 1100

  private var multiImageLimit: Int = 5
  private var cameraImageUri: Uri? = null
  private var pendingCameraAction: (() -> Unit)? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "image_picker_bundle")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    resultPending = result
    when (call.method) {
      "pickFromGallery" -> {
        val intent = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
        activity?.startActivityForResult(intent, REQUEST_GALLERY_SINGLE)
      }
      "pickMultiFromGallery" -> {
        multiImageLimit = (call.argument<Int>("limit") ?: 5)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
          val intent = Intent(MediaStore.ACTION_PICK_IMAGES).apply {
            type = "image/*"
            putExtra(MediaStore.EXTRA_PICK_IMAGES_MAX, multiImageLimit)
          }
          activity?.startActivityForResult(intent, REQUEST_GALLERY_MULTI)
        } else {
          val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
            type = "image/*"
            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("image/jpeg", "image/png", "image/jpg", "image/webp"))
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
          }
          activity?.startActivityForResult(intent, REQUEST_GALLERY_MULTI)
        }
      }
      "pickVideoFromGallery" -> {
        val intent = Intent(Intent.ACTION_PICK, MediaStore.Video.Media.EXTERNAL_CONTENT_URI)
        activity?.startActivityForResult(intent, REQUEST_GALLERY_VIDEO)
      }
      "recordVideo" -> {
        val intent = Intent(MediaStore.ACTION_VIDEO_CAPTURE)
        activity?.startActivityForResult(intent, REQUEST_CAMERA_VIDEO)
      }
      "pickFromCamera" -> {
        checkAndRequestCameraPermission {
          startCameraIntent()
        }
      }
      else -> result.notImplemented()
    }
  }

  /** ✅ Camera permission check */
  private fun checkAndRequestCameraPermission(onGranted: () -> Unit) {
    val act = activity ?: return
    if (ContextCompat.checkSelfPermission(act, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
      onGranted()
    } else {
      pendingCameraAction = onGranted
      ActivityCompat.requestPermissions(act, arrayOf(Manifest.permission.CAMERA), REQUEST_CAMERA_PERMISSION)
    }
  }

  /** ✅ Callback for permission */
  fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
    if (requestCode == REQUEST_CAMERA_PERMISSION) {
      if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
        pendingCameraAction?.invoke()
      } else {
        resultPending?.error("PERMISSION_DENIED", "Camera permission denied", null)
        resultPending = null
      }
      pendingCameraAction = null
      return true
    }
    return false
  }

  /** ✅ Start camera intent */
  private fun startCameraIntent() {
    val act = activity ?: return
    val imageFile = createImageFile()
    cameraImageUri = FileProvider.getUriForFile(
      act,
      "${act.packageName}.fileprovider",
      imageFile
    )
    val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
      putExtra(MediaStore.EXTRA_OUTPUT, cameraImageUri)
      addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
    }
    act.startActivityForResult(intent, REQUEST_CAMERA_IMAGE)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity

    binding.addActivityResultListener { requestCode, resultCode, data ->
      if (resultCode == Activity.RESULT_OK) {
        when (requestCode) {
          REQUEST_GALLERY_SINGLE -> {
            val uri = data?.data
            if (uri != null) {
              resultPending?.success(getPathFromUri(uri))
            } else {
              resultPending?.success(null)
            }
            resultPending = null
            true
          }
          REQUEST_GALLERY_MULTI -> {
            val clipData = data?.clipData
            val paths = ArrayList<String>()

            fun isImageUri(uri: Uri): Boolean {
              val type = activity!!.contentResolver.getType(uri)
              return type?.startsWith("image/") == true
            }

            if (clipData != null) {
              val count = minOf(clipData.itemCount, multiImageLimit)
              for (i in 0 until count) {
                val uri = clipData.getItemAt(i).uri
                if (isImageUri(uri)) {
                  getPathFromUri(uri)?.let { paths.add(it) }
                }
              }
              resultPending?.success(paths)
            } else {
              val uri = data?.data
              if (uri != null && isImageUri(uri)) {
                resultPending?.success(listOf(getPathFromUri(uri)))
              } else {
                resultPending?.success(null)
              }
            }
            resultPending = null
            true
          }
          REQUEST_GALLERY_VIDEO, REQUEST_CAMERA_VIDEO -> {
            val uri = data?.data
            resultPending?.success(uri?.path)
            resultPending = null
            true
          }
          REQUEST_CAMERA_IMAGE -> {
            if (cameraImageUri != null) {
              resultPending?.success(cameraImageUri?.path)
            } else {
              resultPending?.success(null)
            }
            resultPending = null
            true
          }
          else -> false
        }
      } else {
        resultPending?.success(null)
        resultPending = null
        false
      }
    }

    binding.addRequestPermissionsResultListener { requestCode, permissions, grantResults ->
      onRequestPermissionsResult(requestCode, permissions, grantResults)
    }
  }

  /** ✅ Convert URI to file path */
  private fun getPathFromUri(uri: Uri): String? {
    val act = activity ?: return null
    return try {
      val inputStream = act.contentResolver.openInputStream(uri) ?: return null
      val file = createTempFile("picked_", ".jpg", act.cacheDir)
      file.outputStream().use { output ->
        inputStream.copyTo(output)
      }
      file.absolutePath
    } catch (e: Exception) {
      e.printStackTrace()
      null
    }
  }

  private fun createImageFile(): File {
    val storageDir = activity!!.getExternalFilesDir(Environment.DIRECTORY_PICTURES)
    return File.createTempFile("IMG_${System.currentTimeMillis()}_", ".jpg", storageDir)
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
