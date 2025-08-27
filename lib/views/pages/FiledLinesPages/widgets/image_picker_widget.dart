// lib/views/pages/FiledLinesPages/widgets/image_picker_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ImagePickerWidget extends StatelessWidget {
  final Function(File) onImagePicked;
  final String buttonText;
  final bool isVideo;
  final bool isCalibration;

  const ImagePickerWidget({
    super.key,
    required this.onImagePicked,
    this.buttonText = 'Pick Image',
    this.isVideo = false,
    this.isCalibration = false,
  });

  Future<void> _pickImage(BuildContext context) async {
    PermissionStatus status;

    if (Platform.isAndroid) {
      status = isVideo
          ? await Permission.videos.request()
          : isCalibration
              ? await Permission.storage.request()
              : await Permission.photos.request();
    } else {
      status = isVideo
          ? await Permission.photos.request()
          : await Permission.photos.request();
    }

    if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Please grant ${isVideo ? "video" : isCalibration ? "storage" : "photo"} access')),
      );
      return;
    }
    if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${isVideo ? "Video" : isCalibration ? "Storage" : "Photo"} access denied. Enable in settings.'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => openAppSettings(),
          ),
        ),
      );
      return;
    }

    final picker = ImagePicker();
    try {
      final pickedFile = isVideo
          ? await picker.pickVideo(source: ImageSource.gallery)
          : await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        if (isCalibration && !file.path.endsWith('.npz')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Calibration file must be .npz')),
          );
          return;
        }
        if (isVideo && !file.path.endsWith('.mp4')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video must be .mp4')),
          );
          return;
        }
        if (!isVideo && !isCalibration &&
            !file.path.endsWith('.jpg') && !file.path.endsWith('.png')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image must be .jpg or .png')),
          );
          return;
        }
        onImagePicked(file);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _pickImage(context),
      child: Text(buttonText),
    );
  }
}