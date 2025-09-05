
import 'dart:async';
import 'package:VarXPro/views/pages/LiveStream/service/permission_service.dart';
import 'package:VarXPro/views/pages/LiveStream/service/recording_service.dart';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:video_player/video_player.dart';

class StreamVideoController extends ChangeNotifier {
  final PermissionService _permissionService = PermissionService();
  final RecordingService _recordingService = RecordingService();
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

  Future<void> initializePlayer(String streamUrl) async {
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
          playedColor: const Color(0xFFFFC107),
          handleColor: const Color(0xFFFFC107),
          backgroundColor: const Color(0xFF424242),
          bufferedColor: const Color(0xFF424242).withOpacity(0.5),
        ),
      );

      isPlayerReady = true;
      errorMessage = null;
      _safeNotify();
    } catch (e, stackTrace) {
      _logger.e("Error initializing player", error: e, stackTrace: stackTrace);
      errorMessage = "Error loading video: $e";
      isPlayerReady = false;
      _safeNotify();
    }
  }

  Future<void> requestPermissions() async {
    try {
      await _permissionService.requestPermissions();
    } catch (e) {
      _logger.e("Permission error", error: e);
      errorMessage = "Permission denied";
    }
    _safeNotify();
  }

  Future<void> startRecording(String channelName, String title, String message) async {
    try {
      isRecording = true;
      recordingDuration = 0;
      showControls = true;
      errorMessage = null;

      await _recordingService.startRecording(channelName, title, message);

      recordingTimer?.cancel();
      recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        recordingDuration++;
        _safeNotify();
      });

      _resetControlsTimer();
      _safeNotify();
    } catch (e, stackTrace) {
      _logger.e("Error starting recording", error: e, stackTrace: stackTrace);
      errorMessage = "Error recording: $e";
      isRecording = false;
      _safeNotify();
      await stopRecording();
    }
  }

  Future<String?> stopRecording() async {
    recordingTimer?.cancel();
    recordingTimer = null;
    controlsTimer?.cancel();
    controlsTimer = null;

    try {
      final videoPath = await _recordingService.stopRecording();
      if (videoPath == null) throw Exception('Recording failed');

      isRecording = false;
      showControls = true;
      finalVideoPath = videoPath;

      _resetControlsTimer();
      _safeNotify();
      return videoPath;
    } catch (e, stackTrace) {
      _logger.e("Error stopping recording", error: e, stackTrace: stackTrace);
      errorMessage = "Error: $e";
      isRecording = false;
      _safeNotify();
      return null;
    }
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
