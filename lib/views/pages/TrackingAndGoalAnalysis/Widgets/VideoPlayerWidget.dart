// lib/views/pages/TrackingAndGoalAnalysis/widgets/video_player_widget.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:provider/provider.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String url;
  const VideoPlayerWidget({super.key, required this.url});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() => _isInitialized = true);
        _controller.play();
      }).catchError((error) {
        setState(() {
          _isInitialized = false;
          _error = error.toString();
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = Provider.of<ModeProvider>(context).currentMode;
    final seedColor = AppColors.seedColors[mode] ?? AppColors.seedColors[1]!;
    if (_error != null) {
      return Column(
        children: [
          const Icon(
            Icons.error,
            color: Colors.redAccent,
            size: 40,
          ),
          Text(
            'Video Error: $_error',
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 14,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _error = null;
                _isInitialized = false;
                _controller =
                    VideoPlayerController.networkUrl(Uri.parse(widget.url))
                      ..initialize().then((_) {
                        setState(() => _isInitialized = true);
                        _controller.play();
                      }).catchError((error) {
                        setState(() {
                          _isInitialized = false;
                          _error = error.toString();
                        });
                      });
              });
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.2),
              foregroundColor: AppColors.getTertiaryColor(seedColor, mode),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      );
    }
    if (!_isInitialized) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppColors.getTertiaryColor(seedColor, mode)),
        ),
      );
    }
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          VideoPlayer(_controller),
          VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
            colors: VideoProgressColors(
              playedColor: AppColors.getTertiaryColor(seedColor, mode),
              bufferedColor: AppColors.getSurfaceColor(mode),
              backgroundColor: AppColors.getTextColor(mode).withOpacity(0.24),
            ),
          ),
        ],
      ),
    );
  }
}