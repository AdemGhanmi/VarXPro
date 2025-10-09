// lib/views/pages/TrackingAndGoalAnalysis/widgets/file_picker_widget.dart
import 'dart:io';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/lang/translation.dart';
import 'package:provider/provider.dart';

class FilePickerWidget extends StatelessWidget {
  final Function(File) onFilePicked;
  final String buttonText;
  final FileType fileType;
  final int? mode;
  final Color? seedColor;

  const FilePickerWidget({
    super.key,
    required this.onFilePicked,
    required this.buttonText,
    this.fileType = FileType.any,
    this.mode,
    this.seedColor,
  });

  Future<void> _pickFile(BuildContext context) async {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLang = langProvider.currentLanguage;
    PermissionStatus status;
    if (Platform.isAndroid) {
      status = await Permission.videos.request();
    } else {
      status = await Permission.photos.request();
    }

    if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Translations.getRefereeTrackingText('fileAccessDenied', currentLang),
            style: TextStyle(
              color: AppColors.getTextColor(mode ?? 1),
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
            Translations.getRefereeTrackingText('fileAccessPermanentlyDenied', currentLang),
            style: TextStyle(
              color: AppColors.getTextColor(mode ?? 1),
            ),
          ),
          action: SnackBarAction(
            label: Translations.getRefereeTrackingText('settings', currentLang),
            onPressed: () => openAppSettings(),
            textColor: AppColors.getTertiaryColor(seedColor ?? AppColors.seedColors[1]!, mode ?? 1),
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

    final result = await FilePicker.platform.pickFiles(type: fileType);
    if (result != null && result.files.single.path != null) {
      onFilePicked(File(result.files.single.path!));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Translations.getRefereeTrackingText('noFileSelected', currentLang),
            style: TextStyle(
              color: AppColors.getTextColor(mode ?? 1),
            ),
          ),
          backgroundColor: Colors.redAccent,
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
    final mode = this.mode ?? Provider.of<ModeProvider>(context).currentMode;
    final seedColor = this.seedColor ?? AppColors.seedColors[mode]!;
    return ElevatedButton.icon(
      onPressed: () => _pickFile(context),
      icon: Icon(Icons.upload_file, color: AppColors.getTextColor(mode)),
      label: Text(
        buttonText,
        style: TextStyle(color: AppColors.getTextColor(mode)),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.getSecondaryColor(seedColor, mode),
        foregroundColor: AppColors.getTextColor(mode),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }
}