import 'dart:io';
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:VarXPro/model/appcolor.dart';

class RecordingService {
  Future<String> getRecordingFilePath(String channelName, {bool saveToDownloads = false}) async {
    Directory publicDir;
    if (Platform.isAndroid) {
      if (saveToDownloads) {
        publicDir = Directory('/storage/emulated/0/Download');
      } else {
        publicDir = Directory('/storage/emulated/0/Movies/AI_Tactical');
      }
      if (!await publicDir.exists()) {
        await publicDir.create(recursive: true);
      }
    } else if (Platform.isIOS) {
      publicDir = await getApplicationDocumentsDirectory();
    } else {
      publicDir = await getTemporaryDirectory();
    }

    final fileName =
        'Recording_${channelName}_${DateTime.now().millisecondsSinceEpoch}.mp4';
    return p.join(publicDir.path, fileName);
  }

  Future<void> startRecording(
    BuildContext context,
    String channelName,
    String title,
    String message,
    {bool saveToDownloads = false}
  ) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLang = languageProvider.currentLanguage ?? 'en';
    final filePath = await getRecordingFilePath(channelName, saveToDownloads: saveToDownloads);
    
    try {
      await FlutterScreenRecording.startRecordScreen(
        "Recording $channelName",
        titleNotification: title,
        messageNotification: message,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Translations.translate('recording_in_progress', currentLang),
            style: GoogleFonts.roboto(color: AppColors.onPrimaryColor),
          ),
          backgroundColor: AppColors.seedColors[1]!,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Translations.translate('error', currentLang) + ': $e',
            style: GoogleFonts.roboto(color: AppColors.onPrimaryColor),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<String?> stopRecording(BuildContext context) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLang = languageProvider.currentLanguage ?? 'en';
    
    try {
      final filePath = await FlutterScreenRecording.stopRecordScreen;
      if (filePath != null && await File(filePath).exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Translations.translate('recording_saved', currentLang) + ': $filePath',
              style: GoogleFonts.roboto(color: AppColors.onPrimaryColor),
            ),
            backgroundColor: AppColors.seedColors[1]!,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        return filePath;
      } else {
        throw Exception(Translations.translate('no_file_selected', currentLang));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Translations.translate('error', currentLang) + ': $e',
            style: GoogleFonts.roboto(color: AppColors.onPrimaryColor),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return null;
    }
  }
}