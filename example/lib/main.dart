import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:image_picker_bundle/image_picker_bundle.dart';
import 'package:video_player/video_player.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _imagePickerBundlePlugin = ImagePickerBundle();

  @override
  void initState() {
    super.initState();
    // initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await _imagePickerBundlePlugin.getPlatformVersion() ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: PickerDemo(),
      ),
    );
  }
}class PickerDemo extends StatefulWidget {
  @override
  _PickerDemoState createState() => _PickerDemoState();
}

class _PickerDemoState extends State<PickerDemo> {
  Uint8List? _image;
  List<Uint8List>? _images;
  String? _video;
  VideoPlayerController? _videoController;

  Future<void> _pickSingle() async {
    final image = await FlutterImagePicker.pickFromGallery();
    setState(() => _image = image);
  }

  Future<void> _pickMulti() async {
    final images = await FlutterImagePicker.pickMultiFromGallery(limit: 0);
    setState(() => _images = images);
  }

  Future<void> _pickCameraImage() async {
    final image = await FlutterImagePicker.pickFromCamera();
    setState(() => _image = image);
  }



  Future<void> _recordVideo() async {
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
      final uri = Uri.parse(_video!);
      _videoController = VideoPlayerController.contentUri(uri);
      await _videoController!.initialize();
      setState(() {});
      _videoController!.play();
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
            child: const Icon(Icons.videocam),
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
