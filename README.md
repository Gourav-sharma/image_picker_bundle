# image_picker_bundle

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/to/develop-plugins),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Usage

To use this plugin, add `image_picker_bundle` as a dependency in your
pubspec.yaml file.

```yaml
dependencies:
  image_picker_bundle: ^0.0.1
```


## Example

```dart
import 'package:image_picker_bundle/image_picker_bundle.dart';

class PickerDemo extends StatefulWidget {
  @override
  _PickerDemoState createState() => _PickerDemoState();
}

class _PickerDemoState extends State<PickerDemo> {
  Uint8List? _image;
  List<Uint8List>? _images;
  String? _video;
  VideoPlayerController? _videoController;

  /// Check and request permission
  Future<bool> _requestPermission(Permission permission) async {
    final status = await permission.request();
    return status.isGranted;
  }

  Future<void> _pickSingle() async {
    final image = await FlutterImagePicker.pickFromGallery();
    if (mounted) setState(() => _image = image);
  }

  Future<void> _pickMulti() async {
    final images = await FlutterImagePicker.pickMultiFromGallery(limit: 5);
    if (mounted) setState(() => _images = images);
  }

  Future<void> _pickCameraImage() async {
    if (!await _requestPermission(Permission.camera)) return;
    final image = await FlutterImagePicker.pickFromCamera();
    if (mounted) setState(() => _image = image);
  }

  Future<void> _recordVideo() async {
    if (!await _requestPermission(Permission.camera)) return;
    final video = await FlutterImagePicker.recordVideo();
    await _playVideo(video);
  }

  Future<void> _pickVideoFromGallery() async {
    final video = await FlutterImagePicker.pickVideoFromGallery();
    await _playVideo(video);
  }

  Future<void> _playVideo(String? video) async {
    if (video != null) {
      _video = video;

      // Dispose old controller before creating new one
      _videoController?.dispose();

      final uri = Uri.parse(_video!);
      _videoController = VideoPlayerController.contentUri(uri);

      try {
        await _videoController!.initialize();
        if (mounted) setState(() {});
        _videoController!.play();
      } catch (e) {
        debugPrint("Video init error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Flutter Image Picker Plugin")),
      body: Center(
        child: _image == null && _images == null && _video == null
            ? const Text("No media selected")
            : _images != null
            ? ListView.builder(
          itemCount: _images!.length,
          itemBuilder: (context, index) =>
              Image.memory(_images![index]),
        )
            : _video != null &&
            _videoController != null &&
            _videoController!.value.isInitialized
            ? AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        )
            : _image != null
            ? Image.memory(_image!)
            : const Text("No media selected"),
      ),
      floatingActionButton: Wrap(
        spacing: 10,
        direction: Axis.horizontal,
        children: [
          FloatingActionButton(
            heroTag: "gallery",
            onPressed: _pickSingle,
            child: const Icon(Icons.photo),
          ),
          FloatingActionButton(
            heroTag: "multi",
            onPressed: _pickMulti,
            child: const Icon(Icons.collections),
          ),
          FloatingActionButton(
            heroTag: "cameraImg",
            onPressed: _pickCameraImage,
            child: const Icon(Icons.camera_alt),
          ),
          FloatingActionButton(
            heroTag: "recordVideo",
            onPressed: _recordVideo,
            child: const Icon(Icons.videocam),
          ),
          FloatingActionButton(
            heroTag: "pickVideoFromGallery",
            onPressed: _pickVideoFromGallery,
            child: const Icon(Icons.video_collection_outlined),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
}
```

## Permissions

### Android

Add the following permissions to your AndroidManifest.xml file:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />


<provider
android:name="androidx.core.content.FileProvider"
android:authorities="${applicationId}.fileprovider"
android:exported="false"
android:grantUriPermissions="true">
<meta-data
    android:name="android.support.FILE_PROVIDER_PATHS"
    android:resource="@xml/file_paths" />
</provider>
```

### iOS
Add the following permissions to your Info.plist file:

```info.plist
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to pick images.</string>
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to take photos.</string>
<key>NSMicrophoneUsageDescription</key>
<string>We need access to your microphone to record videos.</string>
```


