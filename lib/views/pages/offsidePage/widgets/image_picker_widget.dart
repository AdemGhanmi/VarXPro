// File: lib/views/pages/offsidePage/widgets/ImagePickerWidget.dart
import 'dart:io';
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart'; // ✅ ensure exactly this case
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class ImagePickerWidget extends StatelessWidget {
  final Function(File) onImagePicked;
  final String buttonText;
  final int mode;
  final Color seedColor;
  const ImagePickerWidget({
    super.key,
    required this.onImagePicked,
    required this.buttonText,
    required this.mode,
    required this.seedColor,
  });

  Future<bool> _ensureGalleryPermission() async {
    final statuses = await [
      Permission.photos,
      Permission.storage,
      Permission.videos,
      Permission.mediaLibrary,
    ].request();
    return statuses.values.any((s) => s.isGranted || s.isLimited);
  }

  Future<void> _pickImage(BuildContext context) async {
    final currentLang = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;

    final ok = await _ensureGalleryPermission();
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: AppColors.getTextColor(mode)),
              const SizedBox(width: 8),
              Text(
                Translations.getOffsideText('photoAccessDenied', currentLang),
                style: TextStyle(color: AppColors.getTextColor(mode)),
              ),
            ],
          ),
          backgroundColor: AppColors.getSurfaceColor(mode),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        onImagePicked(File(pickedFile.path));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.image_not_supported, color: AppColors.getTextColor(mode)),
                const SizedBox(width: 8),
                Text(
                  Translations.getOffsideText('noImageSelected', currentLang),
                  style: TextStyle(color: AppColors.getTextColor(mode)),
                ),
              ],
            ),
            backgroundColor: AppColors.getSurfaceColor(mode),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${Translations.getOffsideText('errorPickingImage', currentLang)}: $e',
                  style: TextStyle(color: AppColors.getTextColor(mode)),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.getSurfaceColor(mode),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _pickImage(context),
      icon: Icon(Icons.photo_camera, color: AppColors.getTextColor(mode)),
      label: Text(buttonText, style: TextStyle(color: AppColors.getTextColor(mode))),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.getTertiaryColor(seedColor, mode),
        foregroundColor: AppColors.getTextColor(mode),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        shadowColor: AppColors.getShadowColor(seedColor, mode),
      ),
    );
  }
}
