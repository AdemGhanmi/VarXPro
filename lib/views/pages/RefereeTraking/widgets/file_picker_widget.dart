// views/pages/RefereeTraking/widgets/file_picker_widget.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:provider/provider.dart';

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
    final modeProvider = Provider.of<ModeProvider>(context, listen: false);
    PermissionStatus status;
    if (Platform.isAndroid) {
      if (allowedExtensions.contains('mp4') || allowedExtensions.contains('video')) {
        status = await Permission.videos.request();
      } else {
        status = await Permission.photos.request();
      }
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
    } else {
      status = await Permission.photos.request();
    }

    if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please grant file access to pick files',
            style: TextStyle(
              color: AppColors.getTextColor(modeProvider.currentMode),
            ),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'File access denied. Enable in settings.',
            style: TextStyle(
              color: AppColors.getTextColor(modeProvider.currentMode),
            ),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          action: SnackBarAction(
            label: 'Settings',
            textColor: Colors.white,
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
        SnackBar(
          content: Text(
            'No file selected',
            style: TextStyle(
              color: AppColors.getTextColor(modeProvider.currentMode),
            ),
          ),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final modeProvider = Provider.of<ModeProvider>(context);
    final seedColor = AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!;
    return ElevatedButton(
      onPressed: () => _pickFile(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.getSecondaryColor(seedColor, modeProvider.currentMode),
        foregroundColor: AppColors.getTextColor(modeProvider.currentMode),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text(
        buttonText,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}