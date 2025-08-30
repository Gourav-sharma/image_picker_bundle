import 'package:image_picker_bundle/image_picker_bundle.dart';

class FlutterImagePicker {
  static const MethodChannel _channel = MethodChannel('image_picker_bundle');

  /// Pick single image from gallery
  static Future<Uint8List?> pickFromGallery() async {
    final Uint8List? imageBytes =
    await _channel.invokeMethod('pickFromGallery');
    return imageBytes;
  }

  /// Pick single image from camera
  static Future<Uint8List?> pickFromCamera() async {
    final Uint8List? imageBytes =
    await _channel.invokeMethod('pickFromCamera');
    return imageBytes;
  }

  /// Pick multiple images with limit
  static Future<List<Uint8List>?> pickMultiFromGallery({int limit = 5}) async {
    final List<dynamic>? result =
    await _channel.invokeMethod('pickMultiFromGallery', {"limit": limit});
    return result?.map((e) => e as Uint8List).toList();
  }

  /// Record video (returns file path)
  static Future<String?> recordVideo() async {
    final String? path = await _channel.invokeMethod('recordVideo');
    return path;
  }
}
