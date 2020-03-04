import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Camera extends StatefulWidget {
  @override
  _CameraState createState() => _CameraState();
}

class _CameraState extends State<Camera> {
  File image;
  @override
  void initState() {
    super.initState();
    pickImage();
  }

  Future<void> pickImage() async {
    image =
        await ImagePicker.pickImage(source: ImageSource.camera, maxWidth: 1024);
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
