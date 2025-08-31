import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker_bundle/image_picker_bundle.dart';
import 'package:video_player/video_player.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _imagePickerBundlePlugin = ImagePickerBundle();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: PickerDemo(),
      ),
    );
  }
}

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
