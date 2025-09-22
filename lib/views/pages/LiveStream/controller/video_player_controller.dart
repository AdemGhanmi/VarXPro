import 'dart:async';
import 'dart:io';
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:provider/provider.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:video_player/video_player.dart';

class StreamVideoController extends ChangeNotifier {
  final Logger _logger = Logger();
  static const platform = MethodChannel('screen_service_channel');

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  bool isPlayerReady = false;
  String? errorMessage;

  bool isRecording = false;
  int recordingDuration = 0;
  Timer? recordingTimer;

  String? finalVideoPath;
  bool showControls = true;
  Timer? controlsTimer;

  bool _isDisposed = false;

  VideoPlayerController? get videoController => _videoController;
  ChewieController? get chewieController => _chewieController;

  Future<void> initializePlayer(String streamUrl, String channelName) async {
    try {
      _videoController?.dispose();
      _chewieController?.dispose();

      _videoController = VideoPlayerController.networkUrl(Uri.parse(streamUrl));
      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: false,
        showControls: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.seedColors[1]!,
          handleColor: AppColors.seedColors[1]!,
          backgroundColor: AppColors.getTextColor(1).withOpacity(0.3),
          bufferedColor: AppColors.getTextColor(1).withOpacity(0.5),
        ),
      );

      isPlayerReady = true;
      errorMessage = null;
      _safeNotify();
    } catch (e, stackTrace) {
      _logger.e("Error initializing player", error: e, stackTrace: stackTrace);
      errorMessage = Translations.translate('error_loading_video', 'en') + ': $channelName';
      isPlayerReady = false;
      _safeNotify();
    }
  }

  Future<void> requestPermissions() async {
    _safeNotify();
  }

  Future<void> startRecording(
    BuildContext context,
    String channelName,
    String title,
    String message,
  ) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLang = languageProvider.currentLanguage ?? 'en';
    
    try {
      isRecording = true;
      recordingDuration = 0;
      showControls = true;
      errorMessage = null;

      final fileName =
          'stream_${channelName}_${DateTime.now().millisecondsSinceEpoch}';
      await platform.invokeMethod('startRecording', <String, dynamic>{
        'fileName': fileName,
        'notificationTitle': title,
        'notificationText': message,
      });

      recordingTimer?.cancel();
      recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        recordingDuration++;
        _safeNotify();
      });

      _resetControlsTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Translations.translate('recording_in_progress', currentLang),
            style: GoogleFonts.roboto(color: AppColors.onPrimaryColor),
          ),
          backgroundColor: AppColors.seedColors[1]!,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _safeNotify();
    } catch (e, stackTrace) {
      _logger.e("Error starting recording", error: e, stackTrace: stackTrace);
      errorMessage = Translations.translate('error', currentLang) + ': $e';
      isRecording = false;
      _safeNotify();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Translations.translate('error', currentLang) + ': $e',
            style: GoogleFonts.roboto(color: AppColors.onPrimaryColor),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<String?> stopRecording(BuildContext context) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLang = languageProvider.currentLanguage ?? 'en';
    
    recordingTimer?.cancel();
    recordingTimer = null;
    controlsTimer?.cancel();
    controlsTimer = null;

    try {
      final filePath = await platform.invokeMethod<String>('stopRecording');
      isRecording = false;
      showControls = true;

      if (filePath != null && filePath.isNotEmpty) {
        await saveToGallery(context, filePath);
        finalVideoPath = filePath;
      } else {
        throw Exception(Translations.translate('no_file_selected', currentLang));
      }

      _resetControlsTimer();
      _safeNotify();
      return filePath;
    } catch (e, stackTrace) {
      _logger.e("Error stopping recording", error: e, stackTrace: stackTrace);
      errorMessage = Translations.translate('error', currentLang) + ': $e';
      isRecording = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Translations.translate('error', currentLang) + ': $e',
            style: GoogleFonts.roboto(color: AppColors.onPrimaryColor),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _safeNotify();
      return null;
    }
  }

  Future<void> saveToGallery(BuildContext context, String filePath) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLang = languageProvider.currentLanguage ?? 'en';
    
    if (!File(filePath).existsSync()) {
      _logger.e('Recording file does not exist: $filePath');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Translations.translate('no_file_selected', currentLang),
            style: GoogleFonts.roboto(color: AppColors.onPrimaryColor),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final mediaStore = MediaStore();
      await mediaStore.saveFile(
        tempFilePath: filePath,
        dirType: DirType.video,
        dirName: DirName.dcim,
        relativePath: 'AI_Tactical',
      );
      _logger.i('Recording saved to DCIM/AI_Tactical at path: $filePath');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Translations.translate('recording_saved', currentLang),
            style: GoogleFonts.roboto(color: AppColors.onPrimaryColor),
          ),
          backgroundColor: AppColors.seedColors[1]!,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      _logger.e('Failed to save video to DCIM: $e');
      try {
        final mediaStore = MediaStore();
        await mediaStore.saveFile(
          tempFilePath: filePath,
          dirType: DirType.video,
          dirName: DirName.movies,
          relativePath: 'AI_Tactical',
        );
        _logger.i('Fallback save to Movies/AI_Tactical succeeded');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Translations.translate('recording_saved', currentLang),
              style: GoogleFonts.roboto(color: AppColors.onPrimaryColor),
            ),
            backgroundColor: AppColors.seedColors[1]!,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (fallbackE) {
        _logger.e('Fallback save also failed: $fallbackE');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Translations.translate('error', currentLang) + ': $fallbackE',
              style: GoogleFonts.roboto(color: AppColors.onPrimaryColor),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void play() {
    _videoController?.play();
    _safeNotify();
  }

  void pause() {
    _videoController?.pause();
    _safeNotify();
  }

  double get volume => _videoController?.value.volume ?? 0.0;

  bool get isPlaying => _videoController?.value.isPlaying ?? false;

  Future<void> setVolume(double vol) async {
    await _videoController?.setVolume(vol);
    _safeNotify();
  }

  void toggleControls() {
    showControls = !showControls;
    controlsTimer?.cancel();
    if (showControls) _resetControlsTimer();
    _safeNotify();
  }

  void _resetControlsTimer() {
    controlsTimer?.cancel();
    controlsTimer = Timer(const Duration(seconds: 3), () {
      showControls = false;
      _safeNotify();
    });
  }

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    recordingTimer?.cancel();
    controlsTimer?.cancel();

    try {
      _videoController?.pause();
      _videoController?.dispose();
      _chewieController?.dispose();
    } catch (e) {
      _logger.w("Dispose error: $e");
    }

    super.dispose();
  }
}