import 'dart:io';
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoViewer extends StatefulWidget {
  final String? videoUrl;
  final File? videoFile;
  final int mode;
  final Color seedColor;
  final String currentLang;

  const VideoViewer({
    super.key,
    this.videoUrl,
    this.videoFile,
    required this.mode,
    required this.seedColor,
    required this.currentLang,
  });

  @override
  State<VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<VideoViewer> {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      if (widget.videoFile != null && widget.videoFile!.existsSync()) {
        _controller = VideoPlayerController.file(widget.videoFile!);
      } else if (widget.videoUrl != null) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl!));
      } else {
        setState(() => _error = Translations.getFoulDetectionText('noVideoSource', widget.currentLang));
        return;
      }

      await _controller!.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _controller!,
        autoPlay: true,
        looping: true,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.getTertiaryColor(widget.seedColor, widget.mode),
          handleColor: AppColors.getTertiaryColor(widget.seedColor, widget.mode),
          backgroundColor: AppColors.getSurfaceColor(widget.mode).withOpacity(0.6),
          bufferedColor: AppColors.getSurfaceColor(widget.mode).withOpacity(0.4),
        ),
      );

      setState(() => _isInitialized = true);
    } catch (e) {
      setState(() {
        _error = '${Translations.getFoulDetectionText('failedToLoadVideo', widget.currentLang)}: $e';
        _isInitialized = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        decoration: BoxDecoration(
          gradient: AppColors.getBodyGradient(widget.mode),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeVideoPlayer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.getSecondaryColor(widget.seedColor, widget.mode),
                  foregroundColor: AppColors.getTextColor(widget.mode),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  Translations.getFoulDetectionText('retry', widget.currentLang),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (!_isInitialized || _chewieController == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: AppColors.getBodyGradient(widget.mode),
        ),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.getTertiaryColor(widget.seedColor, widget.mode)),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.getBodyGradient(widget.mode),
      ),
      child: Chewie(controller: _chewieController!),
    );
  }
}
