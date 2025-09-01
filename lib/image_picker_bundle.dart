
import 'image_picker_bundle_platform_interface.dart';

export 'package:image_picker_bundle/image_picker_bundle.dart';
export 'dart:async';
export 'dart:typed_data';
export 'package:flutter/services.dart';

export 'features/flutter_image_picker.dart';
export 'dart:io';


class ImagePickerBundle {
  Future<String?> getPlatformVersion() {
    return ImagePickerBundlePlatform.instance.getPlatformVersion();
  }
}
