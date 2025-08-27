// lib/widgets/file_picker_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class FilePickerWidget extends StatelessWidget {
  final Function(File) onFilePicked;
  final String buttonText;
  final FileType fileType;

  const FilePickerWidget({
    super.key,
    required this.onFilePicked,
    this.buttonText = 'Pick File',
    this.fileType = FileType.any,
  });

  Future<void> _pickFile(BuildContext context) async {
    // Request permission
    PermissionStatus status;
    if (Platform.isAndroid) {
      status = await Permission.videos.request();
    } else {
      status = await Permission.photos.request();
    }

    if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please grant video access to pick files')),
      );
      return;
    }
    if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Video access denied. Enable in settings.'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => openAppSettings(),
          ),
        ),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(type: fileType);
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
