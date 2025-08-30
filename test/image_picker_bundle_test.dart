import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_bundle/image_picker_bundle.dart';
import 'package:image_picker_bundle/image_picker_bundle_platform_interface.dart';
import 'package:image_picker_bundle/image_picker_bundle_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockImagePickerBundlePlatform
    with MockPlatformInterfaceMixin
    implements ImagePickerBundlePlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final ImagePickerBundlePlatform initialPlatform = ImagePickerBundlePlatform.instance;

  test('$MethodChannelImagePickerBundle is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelImagePickerBundle>());
  });

  test('getPlatformVersion', () async {
    ImagePickerBundle imagePickerBundlePlugin = ImagePickerBundle();
    MockImagePickerBundlePlatform fakePlatform = MockImagePickerBundlePlatform();
    ImagePickerBundlePlatform.instance = fakePlatform;

    expect(await imagePickerBundlePlugin.getPlatformVersion(), '42');
  });
}
