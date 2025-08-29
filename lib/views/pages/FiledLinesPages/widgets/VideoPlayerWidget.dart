import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:VarXPro/model/appcolor.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final int mode;
  final Color seedColor;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    required this.mode,
    required this.seedColor,
  });

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    await _videoPlayerController.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: false,
      looping: false,
      allowFullScreen: true,
      allowMuting: true,
      showControls: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: AppColors.getTertiaryColor(widget.seedColor, widget.mode),
        handleColor: AppColors.getTertiaryColor(widget.seedColor, widget.mode),
        backgroundColor: AppColors.getSurfaceColor(widget.mode).withOpacity(0.7),
        bufferedColor: AppColors.getSurfaceColor(widget.mode).withOpacity(0.5),
      ),
    );
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.getTertiaryColor(widget.seedColor, widget.mode)),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getTertiaryColor(widget.seedColor, widget.mode).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 200,
          child: Chewie(controller: _chewieController),
        ),
      ),
    );
  }
}
