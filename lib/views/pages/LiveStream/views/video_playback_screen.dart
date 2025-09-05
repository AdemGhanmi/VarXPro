import 'dart:io';
import 'package:VarXPro/model/appColor.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/lang/translation.dart';
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:logger/logger.dart';

class VideoPlaybackScreen extends StatefulWidget {
  final String filePath;
  const VideoPlaybackScreen({super.key, required this.filePath});

  @override
  State<VideoPlaybackScreen> createState() => _VideoPlaybackScreenState();
}

class _VideoPlaybackScreenState extends State<VideoPlaybackScreen> with TickerProviderStateMixin {
  late VideoPlayerController _controller;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  final Logger _logger = Logger();

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _initializePlayer();

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

  Future<void> _initializePlayer() async {
    try {
      _controller = VideoPlayerController.file(File(widget.filePath));
      await _controller.initialize();
      final modeProvider = Provider.of<ModeProvider>(context, listen: false);
      final seedColor = AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!;
      _chewieController = ChewieController(
        videoPlayerController: _controller,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        fullScreenByDefault: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.getLabelColor(seedColor, modeProvider.currentMode),
          handleColor: AppColors.getLabelColor(seedColor, modeProvider.currentMode),
          backgroundColor: Colors.grey,
          bufferedColor: Colors.grey.withOpacity(0.5),
        ),
      );
      setState(() => _isInitialized = true);
      _logger.i("VideoPlaybackScreen initialized successfully");
    } catch (e, stackTrace) {
      _logger.e("Error loading video", error: e, stackTrace: stackTrace);
      if (mounted) {
        final modeProvider = Provider.of<ModeProvider>(context, listen: false);
        final seedColor = AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!;
        final lang = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${Translations.translate('error_loading_video', lang)}: $e',
              style: GoogleFonts.roboto(color: AppColors.getTextColor(modeProvider.currentMode)),
            ),
            backgroundColor: AppColors.getLabelColor(seedColor, modeProvider.currentMode),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    try {
      _controller.dispose();
      _chewieController?.dispose();
      _glowController.stop();
      _glowController.dispose();
      _logger.i("VideoPlaybackScreen resources disposed successfully");
    } catch (e, stackTrace) {
      _logger.e("Error disposing VideoPlaybackScreen resources", error: e, stackTrace: stackTrace);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modeProvider = Provider.of<ModeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final lang = languageProvider.currentLanguage;
    final seedColor = AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!;
    final textPrimary = AppColors.getTextColor(modeProvider.currentMode);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode),
        title: Text(
          Translations.translate('recording_playback', lang),
          style: GoogleFonts.roboto(
            color: textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: AppColors.getLabelColor(seedColor, modeProvider.currentMode)),
            onPressed: () async {
              try {
                await Share.shareXFiles(
                  [XFile(widget.filePath)],
                  text: Translations.translate('check_out_this_recording', lang),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${Translations.translate('error_sharing', lang)}: $e',
                      style: GoogleFonts.roboto(
                        color: AppColors.getTextColor(modeProvider.currentMode),
                      ),
                    ),
                    backgroundColor: AppColors.getLabelColor(seedColor, modeProvider.currentMode),
                  ),
                );
              }
            },
            tooltip: Translations.translate('share', lang),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(Translations.translate('confirm_delete', lang)),
                  content: Text(
                    Translations.translate('delete_recording_confirm', lang),
                  ),
                  actions: [
                    TextButton(
                      child: Text(Translations.translate('cancel', lang)),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    TextButton(
                      child: Text(
                        Translations.translate('delete', lang),
                        style: TextStyle(color: Colors.red),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                try {
                  await File(widget.filePath).delete();
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          Translations.translate('recording_deleted', lang),
                        ),
                        backgroundColor: AppColors.getLabelColor(seedColor, modeProvider.currentMode),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${Translations.translate('error_deleting', lang)}: $e',
                          style: GoogleFonts.roboto(
                            color: AppColors.getTextColor(modeProvider.currentMode),
                          ),
                        ),
                        backgroundColor: AppColors.getLabelColor(seedColor, modeProvider.currentMode),
                      ),
                    );
                  }
                }
              }
            },
            tooltip: Translations.translate('delete', lang),
          ),
        ],
      ),
      body: Center(
        child: _isInitialized
            ? Chewie(controller: _chewieController!)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.getLabelColor(seedColor, modeProvider.currentMode),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    Translations.translate('loading_recording', lang),
                    style: GoogleFonts.roboto(color: textPrimary, fontSize: 16),
                  ),
                ],
              ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _glowAnimation,
        child: FloatingActionButton(
          backgroundColor: AppColors.getLabelColor(seedColor, modeProvider.currentMode),
          child: Icon(
            _isInitialized && _controller.value.isPlaying
                ? Icons.pause
                : Icons.play_arrow,
            color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode),
          ),
          onPressed: () {
            if (_isInitialized) {
              setState(() {
                _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play();
              });
            }
          },
        ),
      ),
    );
  }
}