import 'package:image_picker_bundle/image_picker_bundle.dart';

class FlutterImagePicker {
  static const MethodChannel _channel = MethodChannel('image_picker_bundle');

  /// Pick a single image from gallery
  static Future<Uint8List?> pickFromGallery() async {
    final result = await _channel.invokeMethod('pickFromGallery');
    return result != null ? Uint8List.fromList(List<int>.from(result)) : null;
  }

  /// Pick multiple images from gallery
  static Future<List<Uint8List>?> pickMultiFromGallery() async {
    final result = await _channel.invokeMethod('pickMultiFromGallery');
    if (result == null) return null;
    return (result as List).map((e) => Uint8List.fromList(List<int>.from(e))).toList();
  }

  /// Pick an image from camera
  static Future<Uint8List?> pickFromCamera() async {
    final result = await _channel.invokeMethod('pickFromCamera');
    return result != null ? Uint8List.fromList(List<int>.from(result)) : null;
  }

  /// Pick a video from gallery
  static Future<String?> pickVideoFromGallery() async {
    return await _channel.invokeMethod('pickVideoFromGallery');
  }

  /// Record a video from camera
  static Future<String?> recordVideo() async {
    return await _channel.invokeMethod('recordVideo');
  }
}
