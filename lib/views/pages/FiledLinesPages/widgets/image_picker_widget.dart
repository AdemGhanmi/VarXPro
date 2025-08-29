import 'dart:io';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';

class ImagePickerWidget extends StatelessWidget {
  final Function(File) onImagePicked;
  final String buttonText;
  final bool isVideo;
  final bool isCalibration;
  final int mode;
  final Color seedColor;

  const ImagePickerWidget({
    super.key,
    required this.onImagePicked,
    this.buttonText = 'Pick Image',
    this.isVideo = false,
    this.isCalibration = false,
    required this.mode,
    required this.seedColor,
  });

  Future<void> _pickFile(BuildContext context) async {
    PermissionStatus status;

    if (Platform.isAndroid) {
      status = isVideo
          ? await Permission.videos.request()
          : isCalibration
              ? await Permission.storage.request()
              : await Permission.photos.request();
    } else {
      status = isVideo ? await Permission.photos.request() : await Permission.photos.request();
    }

    if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Translations.getOffsideText(
                isVideo
                    ? 'photoAccessDenied'
                    : isCalibration
                        ? 'fileAccessDenied'
                        : 'photoAccessDenied',
                context.read<LanguageProvider>().currentLanguage),
            style: TextStyle(color: AppColors.getTextColor(mode)),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Translations.getOffsideText(
                isVideo
                    ? 'photoAccessPermanentlyDenied'
                    : isCalibration
                        ? 'fileAccessPermanentlyDenied'
                        : 'photoAccessPermanentlyDenied',
                context.read<LanguageProvider>().currentLanguage),
            style: TextStyle(color: AppColors.getTextColor(mode)),
          ),
          action: SnackBarAction(
            label: Translations.getOffsideText('settings', context.read<LanguageProvider>().currentLanguage),
            onPressed: () => openAppSettings(),
            textColor: AppColors.getTextColor(mode),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      File? file;
      if (isCalibration) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['npz'],
        );
        if (result != null && result.files.single.path != null) {
          file = File(result.files.single.path!);
          if (!file.path.endsWith('.npz')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  Translations.getOffsideText('calibrationFileMustBeNpz', context.read<LanguageProvider>().currentLanguage),
                  style: TextStyle(color: AppColors.getTextColor(mode)),
                ),
                backgroundColor: Colors.redAccent,
              ),
            );
            return;
          }
        }
      } else {
        final picker = ImagePicker();
        final pickedFile = isVideo
            ? await picker.pickVideo(source: ImageSource.gallery)
            : await picker.pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          file = File(pickedFile.path);
          if (isVideo && !file.path.endsWith('.mp4')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  Translations.getOffsideText('videoMustBeMp4', context.read<LanguageProvider>().currentLanguage),
                  style: TextStyle(color: AppColors.getTextColor(mode)),
                ),
                backgroundColor: Colors.redAccent,
              ),
            );
            return;
          }
          if (!isVideo &&
              !isCalibration &&
              !file.path.endsWith('.jpg') &&
              !file.path.endsWith('.png')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  Translations.getOffsideText('imageMustBeJpgOrPng', context.read<LanguageProvider>().currentLanguage),
                  style: TextStyle(color: AppColors.getTextColor(mode)),
                ),
                backgroundColor: Colors.redAccent,
              ),
            );
            return;
          }
        }
      }
      if (file != null) {
        onImagePicked(file);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Translations.getOffsideText('noFileSelected', context.read<LanguageProvider>().currentLanguage),
              style: TextStyle(color: AppColors.getTextColor(mode)),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${Translations.getOffsideText('errorPickingImage', context.read<LanguageProvider>().currentLanguage)}: $e',
            style: TextStyle(color: AppColors.getTextColor(mode)),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _pickFile(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.getTertiaryColor(seedColor, mode),
        foregroundColor: AppColors.getTextColor(mode),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        buttonText,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.getTextColor(mode),
        ),
      ),
    );
  }
}
