import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'image_picker_bundle_method_channel.dart';

abstract class ImagePickerBundlePlatform extends PlatformInterface {
  /// Constructs a ImagePickerBundlePlatform.
  ImagePickerBundlePlatform() : super(token: _token);

  static final Object _token = Object();

  static ImagePickerBundlePlatform _instance = MethodChannelImagePickerBundle();

  /// The default instance of [ImagePickerBundlePlatform] to use.
  ///
  /// Defaults to [MethodChannelImagePickerBundle].
  static ImagePickerBundlePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ImagePickerBundlePlatform] when
  /// they register themselves.
  static set instance(ImagePickerBundlePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
