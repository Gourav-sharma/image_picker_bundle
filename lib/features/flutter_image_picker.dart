import 'package:image_picker_bundle/image_picker_bundle.dart';

class FlutterImagePicker {
  static const MethodChannel _channel = MethodChannel('image_picker_bundle');

  /// Pick a single image from gallery
  static Future<File?> pickFromGallery() async {
    final result = await _channel.invokeMethod<String>('pickFromGallery');
    return result != null ? File(result) : null;
  }

  /// Pick multiple images from gallery with optional [limit]
  static Future<List<File>?> pickMultiFromGallery({int? limit}) async {
    final result = await _channel.invokeMethod<List<dynamic>>(
      'pickMultiFromGallery',
      {'limit': limit},
    );
    if (result == null) return null;
    return result.map((path) => File(path as String)).toList();
  }

  /// Pick an image from camera
  static Future<File?> pickFromCamera() async {
    final result = await _channel.invokeMethod<String>('pickFromCamera');
    return result != null ? File(result) : null;
  }

  /// Pick a video from gallery
  static Future<File?> pickVideoFromGallery() async {
    final result = await _channel.invokeMethod<String>('pickVideoFromGallery');
    return result != null ? File(result) : null;
  }

  /// Record a video from camera
  static Future<File?> recordVideo() async {
    final result = await _channel.invokeMethod<String>('recordVideo');
    return result != null ? File(result) : null;
  }
}
