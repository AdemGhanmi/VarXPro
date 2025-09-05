// views/pages/RefereeTraking/widgets/video_player_widget.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:provider/provider.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({super.key, required this.videoUrl});

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
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _controller.setLooping(true);
        }
      }).catchError((e) {
        if (mounted) {
          setState(() {
            _error = 'Failed to load video: $e';
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modeProvider = Provider.of<ModeProvider>(context);
    final seedColor = AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!;

    if (_error != null) {
      return Text(
        _error!,
        style: TextStyle(
          color: AppColors.getTextColor(modeProvider.currentMode),
          fontSize: 16,
        ),
      );
    }

    if (!_isInitialized) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(
            AppColors.getTertiaryColor(seedColor, modeProvider.currentMode),
          ),
        ),
      );
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (_controller.value.isPlaying) {
                    _controller.pause();
                  } else {
                    _controller.play();
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.getSecondaryColor(seedColor, modeProvider.currentMode),
                foregroundColor: AppColors.getTextColor(modeProvider.currentMode),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(_controller.value.isPlaying ? 'Pause' : 'Play'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _controller.seekTo(Duration.zero);
                  _controller.play();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.getSecondaryColor(seedColor, modeProvider.currentMode),
                foregroundColor: AppColors.getTextColor(modeProvider.currentMode),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Replay'),
            ),
          ],
        ),
      ],
    );
  }
}