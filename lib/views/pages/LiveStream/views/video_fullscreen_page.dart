import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/views/pages/LiveStream/controller/video_player_controller.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class VideoFullScreenPage extends StatefulWidget {
  final String streamUrl;
  final String? channelName;

  const VideoFullScreenPage({
    super.key,
    required this.streamUrl,
    this.channelName,
  });

  @override
  State<VideoFullScreenPage> createState() => _VideoFullScreenPageState();
}

class _VideoFullScreenPageState extends State<VideoFullScreenPage> {
  final StreamVideoController _controller = StreamVideoController();
  bool _isLandscape = true;

  @override
  void initState() {
    super.initState();
    _setOrientation(landscape: true);
    _controller.initializePlayer(
      widget.streamUrl,
      widget.channelName ?? Translations.translate('unknown', 'en'),
    );
    _controller.requestPermissions();
  }

  void _setOrientation({required bool landscape}) {
    if (landscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    setState(() {
      _isLandscape = landscape;
    });
  }

  @override
  void dispose() {
    _setOrientation(landscape: false);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ModeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentLang = languageProvider.currentLanguage ?? 'en';
    final seedColor =
        AppColors.seedColors[themeProvider.currentMode] ??
        AppColors.seedColors[1]!;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(themeProvider.currentMode),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return GestureDetector(
              onTap: _controller.toggleControls,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.getBodyGradient(
                        themeProvider.currentMode,
                      ),
                    ),
                  ),
                  if (_controller.errorMessage != null)
                    _buildErrorScreen(languageProvider, seedColor, currentLang)
                  else if (!_controller.isPlayerReady)
                    _buildLoadingScreen(languageProvider, currentLang)
                  else if (_controller.isPlayerReady &&
                      _controller.videoController != null &&
                      _controller.chewieController != null)
                    Center(
                      child: AspectRatio(
                        aspectRatio:
                            _controller.videoController!.value.aspectRatio,
                        child: Chewie(
                          controller: _controller.chewieController!,
                        ),
                      ),
                    ),
                  _buildControlsOverlay(
                    languageProvider,
                    currentLang,
                    seedColor,
                  ),
                  if (_controller.isPlayerReady)
                    _buildBottomControls(
                      languageProvider,
                      currentLang,
                      themeProvider,
                      seedColor,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorScreen(
    LanguageProvider languageProvider,
    Color seedColor,
    String currentLang,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: seedColor.withOpacity(0.1),
            ),
            child: Icon(Icons.error_outline, color: seedColor, size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            _controller.errorMessage!,
            style: GoogleFonts.roboto(
              color: AppColors.getTextColor(
                Provider.of<ModeProvider>(context).currentMode,
              ),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _controller.initializePlayer(
              widget.streamUrl,
              widget.channelName ??
                  Translations.translate('unknown', currentLang),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: seedColor,
              foregroundColor: AppColors.onPrimaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 2,
            ),
            child: Text(
              Translations.translate('retry', currentLang),
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.onPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen(
    LanguageProvider languageProvider,
    String currentLang,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.seedColors[1]!),
          ),
          const SizedBox(height: 20),
          Text(
            "${Translations.translate('loading', currentLang)} ${widget.channelName ?? Translations.translate('unknown', currentLang)}...",
            style: GoogleFonts.roboto(
              color: AppColors.getTextColor(
                Provider.of<ModeProvider>(context).currentMode,
              ),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsOverlay(
    LanguageProvider languageProvider,
    String currentLang,
    Color seedColor,
  ) {
    return AnimatedOpacity(
      opacity: _controller.showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        ignoring: !_controller.showControls,
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.getAppBarGradient(
                    Provider.of<ModeProvider>(context).currentMode,
                  ),
                ),
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: AppColors.onPrimaryColor),
                onPressed: () async {
                  // نوقّف الريكورد إذا مازال يخدم
                  if (_controller.isRecording) {
                    await _controller.stopRecording(context);
                  }
                  // نحرّر الريسورس متاع الفيديو
                  _controller.dispose();

                  // نرجع للشاشة السابقة
                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
                tooltip: Translations.translate('quit', currentLang),
              ),

              title: Text(
                widget.channelName ??
                    Translations.translate('playback_in_progress', currentLang),
                style: GoogleFonts.roboto(
                  color: AppColors.onPrimaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: true,
              actions: [
                if (_controller.isRecording)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.circle, color: Colors.red, size: 12),
                        const SizedBox(width: 8),
                        Text(
                          '${_controller.recordingDuration} s',
                          style: GoogleFonts.roboto(
                            color: AppColors.onPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(
    LanguageProvider languageProvider,
    String currentLang,
    ModeProvider themeProvider,
    Color seedColor,
  ) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: _controller.showControls ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: IgnorePointer(
          ignoring: !_controller.showControls,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  seedColor.withOpacity(0.7),
                  seedColor.withOpacity(0.3),
                ],
              ),
            ),
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _controller.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: AppColors.onPrimaryColor,
                    size: 32,
                  ),
                  onPressed: () {
                    if (_controller.isPlaying) {
                      _controller.pause();
                    } else {
                      _controller.play();
                    }
                  },
                ),
                Expanded(
                  child: VideoProgressIndicator(
                    _controller.videoController!,
                    allowScrubbing: true,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    colors: VideoProgressColors(
                      playedColor: seedColor,
                      bufferedColor: AppColors.onPrimaryColor.withOpacity(0.5),
                      backgroundColor: AppColors.onPrimaryColor.withOpacity(
                        0.2,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _controller.volume > 0 ? Icons.volume_up : Icons.volume_off,
                    color: AppColors.onPrimaryColor,
                    size: 24,
                  ),
                  onPressed: () {
                    final newVolume = _controller.volume > 0 ? 0.0 : 1.0;
                    _controller.setVolume(newVolume);
                  },
                ),
                SizedBox(
                  width: 60,
                  child: Slider(
                    value: _controller.volume,
                    onChanged: (value) {
                      _controller.setVolume(value);
                    },
                    activeColor: AppColors.onPrimaryColor,
                    inactiveColor: AppColors.onPrimaryColor.withOpacity(0.3),
                    min: 0.0,
                    max: 1.0,
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: AppColors.getSurfaceColor(themeProvider.currentMode),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      if (_controller.isRecording) {
                        final filePath = await _controller.stopRecording(context);
                        if (filePath != null) {
                          _controller.finalVideoPath = filePath; 
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تم حفظ التسجيل في: $filePath'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else {
                        await _controller.startRecording(
                          context,
                          widget.channelName ?? 'قناة غير معروفة',
                          'بدء التسجيل',
                          'جاري تسجيل البث المباشر...',
                        );
                      }
                    },
                    splashColor: seedColor.withOpacity(0.2),
                    highlightColor: seedColor.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        _controller.isRecording
                            ? Icons.stop_circle
                            : Icons.fiber_manual_record,
                        color: _controller.isRecording ? Colors.red : seedColor,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: AppColors.getSurfaceColor(themeProvider.currentMode),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      _setOrientation(landscape: !_isLandscape);
                    },
                    splashColor: seedColor.withOpacity(0.2),
                    highlightColor: seedColor.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        _isLandscape ? Icons.portrait : Icons.landscape,
                        color: seedColor,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}