import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:image_picker_bundle/image_picker_bundle.dart';


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
    initPlatformState();
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

  Future<void> _pickGallery() async {
    final img = await FlutterImagePicker.pickFromGallery();
    setState(() => _image = img);
  }

  Future<void> _pickCamera() async {
    final img = await FlutterImagePicker.pickFromCamera();
    setState(() => _image = img);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Flutter Image Picker Plugin")),
      body: Center(
        child: _image == null
            ? Text("No image selected")
            : Image.memory(_image!),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _pickGallery,
            child: Icon(Icons.photo),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _pickCamera,
            child: Icon(Icons.camera_alt),
          ),
        ],
      ),
    );
  }
}
