import 'dart:async';
import 'dart:io';
import 'package:VarXPro/model/appColor.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';
import 'package:logger/logger.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

class StreamVideoController extends ChangeNotifier {
  final Logger _logger = Logger();

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
      errorMessage =
          "Le live de $channelName ne pas disponible pour le moment.";
      isPlayerReady = false;
      _safeNotify();
    }
  }

  Future<void> requestPermissions() async {
    try {
      final statuses = await [
        Permission.microphone, 
        Permission.storage, 
        if (Platform.isAndroid) Permission.manageExternalStorage, 
        if (Platform.isAndroid && Platform.version.split('.').first == '10')
          Permission.storage, 
      ].request();

      bool allGranted = statuses.values.every((status) => status.isGranted);
      if (!allGranted) {
        throw Exception('Permissions not granted');
      }

      _safeNotify();
    } catch (e) {
      _logger.e("Permission request failed: $e");
      errorMessage = "Permissions not granted. Recording cannot start.";
      _safeNotify();
    }
  }


 Future<void> startRecording(
    BuildContext context,
    String channelName,
    String title,
    String message,
  ) async {
    try {
      final fileName =
          'stream_${channelName}_${DateTime.now().millisecondsSinceEpoch}';
      bool started = await FlutterScreenRecording.startRecordScreenAndAudio(
        fileName,
      );
      if (!started) {
        throw Exception('Failed to start screen recording');
      }

      isRecording = true;
      recordingDuration = 0;
      showControls = true;
      errorMessage = null;

      recordingTimer?.cancel();
      recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        recordingDuration++;
        _safeNotify();
      });

      _resetControlsTimer();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('🟢 Recording started')));
      _safeNotify();
    } catch (e, stackTrace) {
      _logger.e("Error starting recording", error: e, stackTrace: stackTrace);
      errorMessage = "Error starting recording: $e";
      isRecording = false;
      _safeNotify();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to start recording: $e')),
      );
    }
  }

Future<String?> stopRecording(BuildContext context) async {
  recordingTimer?.cancel();
  recordingTimer = null;
  controlsTimer?.cancel();
  controlsTimer = null;

  try {
    final String? filePath = await FlutterScreenRecording.stopRecordScreen;
    isRecording = false;
    showControls = true;

    if (filePath != null && filePath.isNotEmpty) {
      // Fix: check حجم الفايل
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found after recording');
      }
      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('Recorded file is empty (0 bytes) – try recording longer');
      }
      
      await saveToGallery(context, filePath);
      finalVideoPath = filePath;
      _resetControlsTimer();
      _safeNotify();
      return filePath;
    } else {
      throw Exception('No file path returned from recording');
    }
  } catch (e, stackTrace) {
    _logger.e("Error stopping recording", error: e, stackTrace: stackTrace);
    errorMessage = "Error stopping recording: $e";
    isRecording = false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ Failed to stop recording: $e')),
    );
    _safeNotify();
    return null;
  }
}

Future<void> saveToGallery(BuildContext context, String filePath) async {
  if (!File(filePath).existsSync()) {
    _logger.e('Recording file does not exist: $filePath');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('❌ No recording file created')),
    );
    return;
  }

  await MediaStore.ensureInitialized();
  
  MediaStore.appFolder = 'VarXPro';  
  

  try {
    final mediaStore = MediaStore();
    await mediaStore.saveFile(
      tempFilePath: filePath,
      dirType: DirType.video,
      dirName: DirName.dcim,
    );
    _logger.i('Recording saved to DCIM at path: $filePath');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Recording saved to DCIM gallery')),
    );
  } catch (e) {
    _logger.e('Failed to save video to DCIM: $e');
    try {
      final mediaStore = MediaStore();
      await mediaStore.saveFile(
        tempFilePath: filePath,
        dirType: DirType.video,
        dirName: DirName.movies,
        relativePath: 'VarXPro/Recordings',  // مجلد فرعي للـ recordings
      );
      _logger.i('Fallback save to Movies succeeded');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Recording saved to Movies/VarXPro gallery')),
      );
    } catch (fallbackE) {
      _logger.e('Fallback save also failed: $fallbackE');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to save recording: $fallbackE')),
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
