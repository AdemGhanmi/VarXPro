import 'package:VarXPro/model/appColor.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/views/pages/LiveStream/controller/video_player_controller.dart';
import 'package:VarXPro/views/pages/LiveStream/views/video_playback_screen.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';

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

class _VideoFullScreenPageState extends State<VideoFullScreenPage> with TickerProviderStateMixin {
  final StreamVideoController _controller = StreamVideoController();
  final Logger _logger = Logger();
  Offset _recordButtonPosition = const Offset(20, 20);

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _controller.initializePlayer(widget.streamUrl);
    _controller.requestPermissions();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _glowAnimation = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _glowController.repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context)?.isCurrent == true) {
      if (!_glowController.isAnimating) _glowController.repeat(reverse: true);
    } else {
      _glowController.stop();
    }
  }

  @override
  void dispose() {
    _glowController.stop();
    _glowController.dispose();
    // Ensure orientation is restored before disposing controller
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]).then((_) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      try {
        _controller.dispose();
        _logger.i("VideoFullScreenPage disposed successfully");
      } catch (e, stackTrace) {
        _logger.e("Error disposing VideoFullScreenPage", error: e, stackTrace: stackTrace);
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final modeProvider = Provider.of<ModeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final lang = languageProvider.currentLanguage;
    final seedColor = AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!;
    final primaryColor = AppColors.getPrimaryColor(seedColor, modeProvider.currentMode);
    final textPrimary = AppColors.getTextColor(modeProvider.currentMode);

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(modeProvider.currentMode),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return GestureDetector(
            onTap: _controller.toggleControls,
            child: Stack(
              children: [
                if (_controller.errorMessage != null)
                  _buildErrorScreen(languageProvider, primaryColor, textPrimary)
                else if (_controller.isPlayerReady &&
                    _controller.videoController != null &&
                    _controller.chewieController != null)
                  Center(
                    child: AspectRatio(
                      aspectRatio: _controller.videoController!.value.aspectRatio,
                      child: Chewie(controller: _controller.chewieController!),
                    ),
                  ),
                _buildControlsOverlay(languageProvider, textPrimary),
                _buildFloatingRecordButton(
                  context,
                  screenSize,
                  languageProvider,
                  textPrimary,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorScreen(
    LanguageProvider languageProvider,
    Color primaryColor,
    Color textPrimary,
  ) {
    final lang = languageProvider.currentLanguage;
    final modeProvider = Provider.of<ModeProvider>(context, listen: false);
    final seedColor = AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.getLabelColor(seedColor, modeProvider.currentMode).withOpacity(0.1),
            ),
            child: Icon(
              Icons.error_outline,
              color: AppColors.getLabelColor(seedColor, modeProvider.currentMode),
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _controller.errorMessage!,
            style: GoogleFonts.roboto(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _controller.initializePlayer(widget.streamUrl),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.getLabelColor(seedColor, modeProvider.currentMode),
              foregroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 2,
            ),
            child: Text(
              Translations.translate('retry', lang),
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsOverlay(
    LanguageProvider languageProvider,
    Color textPrimary,
  ) {
    final lang = languageProvider.currentLanguage;
    return AnimatedOpacity(
      opacity: _controller.showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        ignoring: !_controller.showControls,
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.black.withOpacity(0.5),
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: textPrimary),
                onPressed: () => Navigator.pop(context),
                tooltip: Translations.translate('quit', lang),
              ),
              title: Text(
                widget.channelName ??
                    Translations.translate('playback_in_progress', lang),
                style: GoogleFonts.roboto(
                  color: textPrimary,
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
                        const Icon(
                          Icons.circle,
                          color: Colors.red,
                          size: 12,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_controller.recordingDuration} s',
                          style: GoogleFonts.roboto(color: textPrimary),
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

  Widget _buildFloatingRecordButton(
    BuildContext context,
    Size screenSize,
    LanguageProvider languageProvider,
    Color textPrimary,
  ) {
    final lang = languageProvider.currentLanguage;
    final modeProvider = Provider.of<ModeProvider>(context, listen: false);
    final seedColor = AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!;
    final recordColor = _controller.isRecording ? Colors.red : AppColors.getLabelColor(seedColor, modeProvider.currentMode);
    return Positioned(
      left: _recordButtonPosition.dx.clamp(0, screenSize.width - 60),
      top: _recordButtonPosition.dy.clamp(0, screenSize.height - 60),
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _recordButtonPosition = Offset(
              (_recordButtonPosition.dx + details.delta.dx).clamp(
                0,
                screenSize.width - 60,
              ),
              (_recordButtonPosition.dy + details.delta.dy).clamp(
                0,
                screenSize.height - 60,
              ),
            );
          });
        },
        child: ScaleTransition(
          scale: _glowAnimation,
          child: FloatingActionButton(
            backgroundColor: recordColor,
            mini: true,
            child: Icon(
              _controller.isRecording ? Icons.stop : Icons.fiber_manual_record,
              color: textPrimary,
              size: 20,
            ),
            onPressed: () async {
              if (_controller.isRecording) {
                final videoPath = await _controller.stopRecording();
                if (videoPath != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        Translations.translate('recording_saved', lang),
                        style: GoogleFonts.roboto(
                          color: AppColors.getTextColor(modeProvider.currentMode),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      backgroundColor: AppColors.getLabelColor(seedColor, modeProvider.currentMode),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      action: SnackBarAction(
                        label: Translations.translate('view', lang),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  VideoPlaybackScreen(filePath: videoPath),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }
              } else {
                await _controller.startRecording(
                  widget.channelName ?? 'video',
                  Translations.translate('recording_in_progress', lang),
                  "${Translations.translate('recording', lang)} ${widget.channelName}",
                );
              }

              if (_controller.errorMessage != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _controller.errorMessage!,
                      style: GoogleFonts.roboto(
                        color: AppColors.getTextColor(modeProvider.currentMode),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor: AppColors.getLabelColor(seedColor, modeProvider.currentMode),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}