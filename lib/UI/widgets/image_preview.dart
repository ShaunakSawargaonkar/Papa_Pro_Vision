import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:typed_data';

class ImagePreview extends StatelessWidget {

  final CameraController cameraController;
  final Uint8List? imageBytes;
  final bool hasUploadedImage;

  ImagePreview({super.key, required this.cameraController, this.imageBytes, required this.hasUploadedImage});

  @override
  Widget build(BuildContext context) {
    if (hasUploadedImage && imageBytes != Uint8List(0)) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green, width: 3),
        ),
        child: Image.memory(
          imageBytes!,
          fit: BoxFit.cover,
          width: cameraController.value.previewSize!.height,
          height: cameraController.value.previewSize!.width,
        ),
      );
    } else {
      return CameraPreview(cameraController);
    }
  }
}