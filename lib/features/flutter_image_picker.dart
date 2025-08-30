import 'package:image_picker_bundle/image_picker_bundle.dart';

class FlutterImagePicker {
  static const MethodChannel _channel = MethodChannel('image_picker_bundle');

  /// Pick image from gallery
  static Future<Uint8List?> pickFromGallery({
    int quality = 100,
    int? maxWidth,
    int? maxHeight,
  }) async {
    final Uint8List? imageBytes = await _channel.invokeMethod(
      'pickFromGallery',
      {
        'quality': quality,
        'maxWidth': maxWidth,
        'maxHeight': maxHeight,
      },
    );
    return imageBytes;
  }

  /// Pick image from camera
  static Future<Uint8List?> pickFromCamera({
    int quality = 100,
    int? maxWidth,
    int? maxHeight,
  }) async {
    final Uint8List? imageBytes = await _channel.invokeMethod(
      'pickFromCamera',
      {
        'quality': quality,
        'maxWidth': maxWidth,
        'maxHeight': maxHeight,
      },
    );
    return imageBytes;
  }
}
