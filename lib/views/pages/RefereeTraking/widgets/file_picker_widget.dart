// lib/widgets/file_picker_widget.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class FilePickerWidget extends StatelessWidget {
  final Function(File) onFilePicked;
  final String buttonText;
  final List<String> allowedExtensions;

  const FilePickerWidget({
    super.key,
    required this.onFilePicked,
    this.buttonText = 'Pick File',
    this.allowedExtensions = const ['*'],
  });

  Future<void> _pickFile(BuildContext context) async {
    // Request permissions based on platform and file type
    PermissionStatus status;
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+), use granular media permissions
      if (allowedExtensions.contains('mp4') || allowedExtensions.contains('video')) {
        status = await Permission.videos.request(); // For videos
      } else {
        status = await Permission.photos.request(); // For images
      }
      // Fallback to storage permission for Android 12 and below if needed
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
    } else {
      // iOS: Use photos permission for both images and videos
      status = await Permission.photos.request();
    }

    if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please grant file access to pick files')),
      );
      return;
    }
    if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('File access denied. Enable in settings.'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => openAppSettings(),
          ),
        ),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );
    if (result != null && result.files.single.path != null) {
      onFilePicked(File(result.files.single.path!));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _pickFile(context),
      child: Text(buttonText),
    );
  }
}