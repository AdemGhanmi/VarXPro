import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/views/pages/offsidePage/controller/offside_controller.dart';
import 'package:VarXPro/views/pages/offsidePage/model/offside_model.dart';
import 'package:VarXPro/views/pages/offsidePage/service/offside_service.dart';
import 'package:VarXPro/views/pages/offsidePage/widgets/OffsideForm.dart';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

// ====== Base URL pour les fichiers si l’API renvoie des chemins relatifs ======
const String kVideoBaseUrl = 'https://offsidevideo.varxpro.com';

bool _isAbs(String? u) {
  if (u == null) return false;
  final s = u.trim().toLowerCase();
  return s.startsWith('http://') || s.startsWith('https://');
}

/// Transforme /download/... → https://domain/download/...
String? _abs(String? pathOrUrl) {
  if (pathOrUrl == null || pathOrUrl.trim().isEmpty) return null;
  if (_isAbs(pathOrUrl)) return pathOrUrl;
  // s’assure d’avoir un seul slash
  if (pathOrUrl.startsWith('/')) return '$kVideoBaseUrl$pathOrUrl';
  return '$kVideoBaseUrl/$pathOrUrl';
}

class OffsidePage extends StatefulWidget {
  const OffsidePage({super.key});
  @override
  State<OffsidePage> createState() => _OffsidePageState();
}

class _OffsidePageState extends State<OffsidePage> {
  bool _showSplash = true;

  VideoPlayerController? _videoController; // player principal (full output)
  String? _lastVideoUrl;
  MediaStore? _mediaStore;

  late final OffsideBloc _bloc;

  final ValueNotifier<int> _waitSeconds = ValueNotifier<int>(0);
  Timer? _waitTicker;

  @override
  void initState() {
    super.initState();

    _bloc = OffsideBloc(OffsideService())..add(PingEvent());

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showSplash = false);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await MediaStore.ensureInitialized();
      MediaStore.appFolder = 'VarXPro';
      if (mounted) setState(() => _mediaStore = MediaStore());
    });
  }

  @override
  void dispose() {
    _waitTicker?.cancel();
    _waitSeconds.dispose();
    _videoController?.dispose();
    _bloc.close();
    super.dispose();
  }

  // ---------------------- Video helpers (main output) ----------------------
  void _initVideoPlayer(String url) {
    if (_lastVideoUrl == url &&
        _videoController != null &&
        _videoController!.value.isInitialized) {
      return;
    }
    _videoController?.dispose();
    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    _videoController = c;
    c
        .initialize()
        .then((_) {
          if (!mounted) return;
          setState(() {});
          c.play();
          c.setLooping(false);
          _lastVideoUrl = url;
        })
        .catchError((e) => debugPrint('video init error: $e'));
  }

  // ---------------------- Download helpers ----------------------
  Future<String> _downloadToTemp(String url, {required bool isVideo}) async {
    final dir = await getTemporaryDirectory();
    String ext = '';
    final seg = Uri.parse(url).pathSegments;
    if (seg.isNotEmpty && seg.last.contains('.')) {
      ext = '.${seg.last.split('.').last}';
    } else {
      ext = isVideo ? '.mp4' : '.jpg';
    }
    final savePath =
        '${dir.path}/varx_${DateTime.now().millisecondsSinceEpoch}$ext';
    final dio = Dio();
    await dio.download(
      url,
      savePath,
      options: Options(responseType: ResponseType.bytes),
    );
    return savePath;
  }

  Future<bool> _ensureStoragePermission(
    BuildContext context,
    String currentLang,
  ) async {
    if (Platform.isAndroid) {
      final statuses = await [
        Permission.storage,
        Permission.photos,
        Permission.videos,
      ].request();
      final granted = statuses.values.any((s) => s.isGranted || s.isLimited);
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Translations.getOffsideText(
                'permissionRequiredSaveDownloads',
                currentLang,
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return granted;
    }
    return true;
  }

  Future<void> _saveToDownloads(
    BuildContext context,
    String url,
    String currentLang, {
    bool isVideo = false,
  }) async {
    try {
      final ok = await _ensureStoragePermission(context, currentLang);
      if (!ok) return;

      if (_mediaStore == null && Platform.isAndroid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Translations.getOffsideText(
                'mediaStoreNotInitialized',
                currentLang,
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final resolved = _abs(url) ?? url;

      if (!Platform.isAndroid) {
        final dir = await getApplicationDocumentsDirectory();
        final fileName =
            'VarXPro_${DateTime.now().millisecondsSinceEpoch}${isVideo ? '.mp4' : '.jpg'}';
        final savePath = '${dir.path}/$fileName';
        final dio = Dio();
        await dio.download(resolved, savePath);
        _toastSuccess(
          context,
          isVideo
              ? Translations.getOffsideText('videoSaved', currentLang)
              : Translations.getOffsideText('imageSaved', currentLang),
        );
        return;
      }

      final tempPath = await _downloadToTemp(resolved, isVideo: isVideo);
      final success = await _mediaStore!.saveFile(
        tempFilePath: tempPath,
        dirType: DirType.download,
        dirName: DirName.download,
      );

      if (success != null) {
        _toastSuccess(
          context,
          isVideo
              ? Translations.getOffsideText('videoSavedDownloads', currentLang)
              : Translations.getOffsideText('imageSavedDownloads', currentLang),
        );
      } else {
        _toastError(
          context,
          Translations.getOffsideText('saveFailure', currentLang),
        );
      }
    } catch (e) {
      _toastError(
        context,
        '${Translations.getOffsideText('saveError', currentLang)} $e',
      );
    }
  }

  void _toastSuccess(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _toastError(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ---------------------- Wait timer ----------------------
  void _startWaitTimer() {
    _waitTicker?.cancel();
    _waitSeconds.value = 0;
    _waitTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      _waitSeconds.value++;
    });
  }

  void _stopWaitTimer() {
    _waitTicker?.cancel();
  }

  // ========================================================
  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final modeProvider = Provider.of<ModeProvider>(context);
    final currentLang = langProvider.currentLanguage;
    final mode = modeProvider.currentMode;
    final seedColor = AppColors.seedColors[mode] ?? AppColors.seedColors[1]!;
    final textPrimary = AppColors.getTextColor(mode);
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    if (_showSplash) {
      return Scaffold(
        backgroundColor: AppColors.getBackgroundColor(mode),
        body: Center(
          child: Lottie.asset(
            'assets/lotties/offside.json',
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.5,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    return BlocProvider.value(
      value: _bloc,
      child: Builder(
        builder: (blocContext) {
          return BlocConsumer<OffsideBloc, OffsideState>(
            listener: (context, state) {
              if (state.isLoading) {
                _startWaitTimer();
              } else {
                _stopWaitTimer();
              }

              final u = state.videoResponse?.fileUrl;
              if (u != null) _initVideoPlayer(_abs(u) ?? u);

              if (state.error != null && state.error!.isNotEmpty) {
                _toastError(context, state.error!);
              }
            },
            builder: (context, state) {
              return Scaffold(
                backgroundColor: AppColors.getBackgroundColor(mode),
                body: Stack(
                  children: [
                    // Fond animé + grille terrain
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.getBodyGradient(mode),
                        ),
                        child: CustomPaint(painter: _FootballGridPainter(mode)),
                      ),
                    ),

                    // =============== CONTENT ===============
                    SafeArea(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          isPortrait ? 12 : 8,
                          16,
                          16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Erreur
                            if (state.error != null)
                              GlassCard(
                                mode: mode,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.redAccent,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        state.error!,
                                        style: GoogleFonts.roboto(
                                          color: Colors.redAccent,
                                          fontSize: isPortrait ? 15 : 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Single Frame Detection
                            _SectionHeader(
                              icon: Icons.photo_camera,
                              title: Translations.getOffsideText(
                                'singleFrameDetection',
                                currentLang,
                              ),
                              mode: mode,
                            ),
                            const SizedBox(height: 10),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                return GlassCard(
                                  mode: mode,
                                  child: OffsideForm(
                                    constraints: constraints,
                                    currentLang: currentLang,
                                    mode: mode,
                                    seedColor: seedColor,
                                  ),
                                );
                              },
                            ),

                            if (state.isLoading) ...[
                              const SizedBox(height: 18),
                              _ProgressCard(
                                upload: state.uploadProgress,
                                download: state.downloadProgress,
                                cancellable: state.cancellable,
                                onCancel: () {
                                  final bloc = context.read<OffsideBloc>();
                                  if (!bloc.isClosed) {
                                    bloc.add(CancelCurrentRequestEvent());
                                  }
                                },
                                mode: mode,
                                seedColor: seedColor,
                                currentLang: currentLang,
                              ),
                            ],

                            if (state.offsideFrameResponse != null) ...[
                              const SizedBox(height: 20),
                              _FrameResultCard(
                                resp: state.offsideFrameResponse!,
                                picked: state.pickedImage,
                                mode: mode,
                                seedColor: seedColor,
                                onOpenImage: (fileOrUrl) =>
                                    _openImageFullscreen(
                                      file: fileOrUrl.$1,
                                      url: fileOrUrl.$2,
                                    ),
                                onSaveImage: (url) =>
                                    _saveToDownloads(context, url, currentLang),
                                onSaveFile: (file) async {
                                  if (_mediaStore == null ||
                                      !Platform.isAndroid) {
                                    _toastError(
                                      context,
                                      Translations.getOffsideText(
                                        'saveNotSupportedPlatform',
                                        currentLang,
                                      ),
                                    );
                                    return;
                                  }
                                  try {
                                    final tempDir =
                                        await getTemporaryDirectory();
                                    final tempPath =
                                        '${tempDir.path}/temp_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
                                    await file.copy(tempPath);
                                    final success = await _mediaStore!.saveFile(
                                      tempFilePath: tempPath,
                                      dirType: DirType.download,
                                      dirName: DirName.download,
                                    );
                                    if (success != null) {
                                      _toastSuccess(
                                        context,
                                        Translations.getOffsideText(
                                          'imageSavedDownloadsSuccess',
                                          currentLang,
                                        ),
                                      );
                                    } else {
                                      _toastError(
                                        context,
                                        Translations.getOffsideText(
                                          'saveFailureGeneric',
                                          currentLang,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    _toastError(
                                      context,
                                      '${Translations.getOffsideText('errorGeneric', currentLang)} $e',
                                    );
                                  }
                                },
                                currentLang: currentLang,
                              ),
                            ],

                            const SizedBox(height: 20),

                            if (state.videoResponse != null) ...[
                              _SectionHeader(
                                icon: Icons.play_circle_outline,
                                title: Translations.getOffsideText(
                                  'videoAnalysis',
                                  currentLang,
                                ),
                                mode: mode,
                              ),
                              const SizedBox(height: 10),
                              _VideoResultCard(
                                resp: state.videoResponse!,
                                controller: _videoController,
                                mode: mode,
                                seedColor: seedColor,
                                onOpenVideo: (url) =>
                                    _openVideoFullscreen(_abs(url) ?? url),
                                onSaveVideo: () {
                                  final u = state.videoResponse!.fileUrl;
                                  if (u != null) {
                                    _saveToDownloads(
                                      context,
                                      _abs(u) ?? u,
                                      currentLang,
                                      isVideo: true,
                                    );
                                  }
                                },
                                onOpenOffsideImage: (url) =>
                                    _openImageFullscreen(url: _abs(url)),
                                onSaveOffsideImage: (url) => _saveToDownloads(
                                  context,
                                  _abs(url) ?? url,
                                  currentLang,
                                ),
                                onOpenClipVideo: (url) =>
                                    _openVideoFullscreen(_abs(url) ?? url),
                                onSaveClipVideo: (url) => _saveToDownloads(
                                  context,
                                  _abs(url) ?? url,
                                  currentLang,
                                  isVideo: true,
                                ),
                                currentLang: currentLang,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    if (state.isLoading)
                      _LoadingOverlay(
                        seedColor: seedColor,
                        mode: mode,
                        secondsNotifier: _waitSeconds,
                        upload: state.uploadProgress,
                        download: state.downloadProgress,
                        currentLang: currentLang,
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // =================== Fullscreen viewers ===================
  void _openImageFullscreen({File? file, String? url}) {
    double scale = 1.0;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            return GestureDetector(
              onDoubleTap: () =>
                  setSt(() => scale = (scale == 1.0 ? 2.0 : 1.0)),
              child: Dialog(
                backgroundColor: Colors.black.withOpacity(0.92),
                insetPadding: const EdgeInsets.all(0),
                child: Stack(
                  children: [
                    InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Center(
                        child: Transform.scale(
                          scale: scale,
                          child: file != null
                              ? Image.file(file, fit: BoxFit.contain)
                              : (url != null
                                    ? Image.network(url, fit: BoxFit.contain)
                                    : const SizedBox.shrink()),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      right: 16,
                      child: _HoloIconButton(
                        icon: Icons.close,
                        onTap: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openVideoFullscreen(String url) {
    final isReadyNotifier = ValueNotifier(false);
    final scaleNotifier = ValueNotifier(1.0);
    final showControlsNotifier = ValueNotifier(true);
    VideoPlayerController? dialogController;

    dialogController = VideoPlayerController.networkUrl(Uri.parse(url));
    dialogController
        .initialize()
        .then((_) {
          isReadyNotifier.value = true;
          dialogController!.play();
        })
        .catchError((e) => debugPrint('dialog video init error: $e'));

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return ValueListenableBuilder<bool>(
          valueListenable: isReadyNotifier,
          builder: (ctx, isReady, _) {
            return ValueListenableBuilder<double>(
              valueListenable: scaleNotifier,
              builder: (ctx, scale, __) {
                return ValueListenableBuilder<bool>(
                  valueListenable: showControlsNotifier,
                  builder: (ctx, showControls, ___) {
                    return GestureDetector(
                      onTap: () => showControlsNotifier.value = !showControls,
                      onDoubleTap: () =>
                          scaleNotifier.value = (scale == 1.0 ? 2.0 : 1.0),
                      child: Dialog(
                        backgroundColor: Colors.black.withOpacity(0.95),
                        insetPadding: const EdgeInsets.all(0),
                        child: Stack(
                          children: [
                            if (isReady && dialogController != null)
                              InteractiveViewer(
                                minScale: 0.5,
                                maxScale: 4.0,
                                child: Center(
                                  child: Transform.scale(
                                    scale: scale,
                                    child: AspectRatio(
                                      aspectRatio:
                                          dialogController!.value.aspectRatio,
                                      child: Stack(
                                        alignment: Alignment.bottomCenter,
                                        children: [
                                          VideoPlayer(dialogController!),
                                          if (showControls)
                                            VideoProgressIndicator(
                                              dialogController!,
                                              allowScrubbing: true,
                                              colors: const VideoProgressColors(
                                                playedColor: Colors.white,
                                                bufferedColor: Colors.white30,
                                                backgroundColor: Colors.white10,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            else
                              const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            if (showControls &&
                                isReady &&
                                dialogController != null)
                              Positioned(
                                bottom: 50,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _HoloRoundButton(
                                      icon: Icons.replay_10,
                                      onTap: () {
                                        final currentPos =
                                            dialogController!.value.position;
                                        final target =
                                            currentPos -
                                            const Duration(seconds: 10);
                                        final newPos = target < Duration.zero
                                            ? Duration.zero
                                            : (target >
                                                      dialogController!
                                                          .value
                                                          .duration
                                                  ? dialogController!
                                                        .value
                                                        .duration
                                                  : target);
                                        dialogController!.seekTo(newPos);
                                      },
                                    ),
                                    const SizedBox(width: 12),
                                    _HoloRoundButton(
                                      icon: dialogController!.value.isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      onTap: () {
                                        if (dialogController!.value.isPlaying) {
                                          dialogController!.pause();
                                        } else {
                                          dialogController!.play();
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 12),
                                    _HoloRoundButton(
                                      icon: Icons.forward_10,
                                      onTap: () {
                                        final currentPos =
                                            dialogController!.value.position;
                                        final target =
                                            currentPos +
                                            const Duration(seconds: 10);
                                        final newPos = target < Duration.zero
                                            ? Duration.zero
                                            : (target >
                                                      dialogController!
                                                          .value
                                                          .duration
                                                  ? dialogController!
                                                        .value
                                                        .duration
                                                  : target);
                                        dialogController!.seekTo(newPos);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            if (showControls && isReady)
                              Positioned(
                                bottom: 50,
                                right: 16,
                                child: _HoloIconButton(
                                  icon: Icons.download,
                                  onTap: () => _saveToDownloads(
                                    context,
                                    url,
                                    context
                                        .read<LanguageProvider>()
                                        .currentLanguage,
                                    isVideo: true,
                                  ),
                                ),
                              ),
                            Positioned(
                              top: 40,
                              right: 16,
                              child: _HoloIconButton(
                                icon: Icons.close,
                                onTap: () {
                                  dialogController?.dispose();
                                  Navigator.of(ctx).pop();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    ).then((_) {
      dialogController?.dispose();
      isReadyNotifier.dispose();
      scaleNotifier.dispose();
      showControlsNotifier.dispose();
    });
  }
}

// =======================================================
// =================== Styled components =================
// =======================================================

class _HoloIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HoloIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.white.withOpacity(0.08),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(icon, size: 26, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _HoloRoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HoloRoundButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.08),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

// =======================================================
// ===================== Progress card ===================
// =======================================================

class _ProgressCard extends StatefulWidget {
  final double upload;
  final double download;
  final bool cancellable;
  final VoidCallback onCancel;
  final int mode;
  final Color seedColor;
  final String currentLang;
  const _ProgressCard({
    required this.upload,
    required this.download,
    required this.cancellable,
    required this.onCancel,
    required this.mode,
    required this.seedColor,
    required this.currentLang,
  });

  @override
  State<_ProgressCard> createState() => _ProgressCardState();
}

class _ProgressCardState extends State<_ProgressCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _downloadController;
  late Animation<double> _downloadAnimation;

  @override
  void initState() {
    super.initState();
    _downloadController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _downloadAnimation = Tween<double>(begin: 0.0, end: widget.download)
        .animate(
          CurvedAnimation(parent: _downloadController, curve: Curves.easeInOut),
        );
    if (widget.download > 0) _downloadController.forward();
  }

  @override
  void didUpdateWidget(_ProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.download != oldWidget.download) {
      _downloadAnimation =
          Tween<double>(
            begin: _downloadAnimation.value,
            end: widget.download,
          ).animate(
            CurvedAnimation(
              parent: _downloadController,
              curve: Curves.easeInOut,
            ),
          );
      _downloadController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _downloadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      mode: widget.mode,
      child: Column(
        children: [
          _LabeledBar(
            label: Translations.getOffsideText('uploading', widget.currentLang),
            value: widget.upload,
            mode: widget.mode,
            seedColor: widget.seedColor,
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _downloadAnimation,
            builder: (context, child) {
              return _LabeledBar(
                label: Translations.getOffsideText(
                  'processingDownloading',
                  widget.currentLang,
                ),
                value: _downloadAnimation.value,
                mode: widget.mode,
                seedColor: widget.seedColor,
              );
            },
          ),
          if (widget.cancellable) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: AppColors.getTertiaryColor(
                    widget.seedColor,
                    widget.mode,
                  ).withOpacity(0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: widget.onCancel,
              icon: const Icon(Icons.stop_circle_outlined),
              label: Text(
                Translations.getOffsideText('cancel', widget.currentLang),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LabeledBar extends StatelessWidget {
  final String label;
  final double value;
  final int mode;
  final Color seedColor;
  const _LabeledBar({
    required this.label,
    required this.value,
    required this.mode,
    required this.seedColor,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).clamp(0, 100).toStringAsFixed(0);
    final txt = AppColors.getTextColor(mode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w600,
                color: txt,
              ),
            ),
            const Spacer(),
            Text(
              '$pct%',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w800,
                color: txt,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value.isNaN ? 0 : value,
            minHeight: 10,
            backgroundColor: AppColors.getSurfaceColor(mode).withOpacity(0.4),
            color: AppColors.getTertiaryColor(seedColor, mode),
          ),
        ),
      ],
    );
  }
}

// =======================================================
// ===================== RESULT: Frame ===================
// =======================================================

class _FrameResultCard extends StatefulWidget {
  final OffsideFrameResponse resp;
  final File? picked;
  final int mode;
  final Color seedColor;
  final void Function((File?, String?)) onOpenImage;
  final void Function(String) onSaveImage;
  final void Function(File) onSaveFile;
  final String currentLang;

  const _FrameResultCard({
    required this.resp,
    required this.picked,
    required this.mode,
    required this.seedColor,
    required this.onOpenImage,
    required this.onSaveImage,
    required this.onSaveFile,
    required this.currentLang,
  });

  @override
  State<_FrameResultCard> createState() => _FrameResultCardState();
}

class _FrameResultCardState extends State<_FrameResultCard> {
  bool _resolveOffside() {
    // essaie de couvrir tous les cas possibles
    if (widget.resp.offsideResolved == true) return true;
    if (widget.resp.offsideLine != null) return true;
    if ((widget.resp.offsidesCount ?? 0) > 0) return true;
    final offEn = widget.resp.meta?['offside_enable'] == true;
    if (offEn) return true;
    // sinon offside non confirmé
    return false;
    // si tu as resp.offsideFound côté modèle, tu peux l’ajouter ici.
  }

  @override
  Widget build(BuildContext context) {
    final bool isOff = _resolveOffside();
    final String verdictText = isOff
        ? Translations.getOffsideText('offsideVerdict', widget.currentLang)
        : Translations.getOffsideText('onsideVerdict', widget.currentLang);
    final Color verdictColor = isOff
        ? Colors.redAccent
        : Colors.lightGreenAccent;

    final numPlayers =
        (widget.resp.meta?['meta']?['num_players'] as num?)?.toInt() ?? 0;

    final annotated = _abs(widget.resp.fileUrl);

    return GlassCard(
      mode: widget.mode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verdict + meta row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: verdictColor.withOpacity(0.15),
                  border: Border.all(color: verdictColor.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  verdictText,
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w800,
                    color: AppColors.getTextColor(widget.mode),
                  ),
                ),
              ),
              if (widget.resp.attackingTeam != null)
                _Chip(
                  Translations.getOffsideText(
                    'attackingTeam',
                    widget.currentLang,
                  ).replaceAll('{team}', widget.resp.attackingTeam!),
                  widget.seedColor,
                  widget.mode,
                ),
              if (widget.resp.attackDirection != null)
                _Chip(
                  Translations.getOffsideText(
                    'attackDirection',
                    widget.currentLang,
                  ).replaceAll('{direction}', widget.resp.attackDirection!),
                  widget.seedColor,
                  widget.mode,
                ),
              if ((widget.resp.offsidesCount ?? 0) > 0)
                _Chip(
                  Translations.getOffsideText(
                    'offsidesCount',
                    widget.currentLang,
                  ).replaceAll('{count}', widget.resp.offsidesCount.toString()),
                  widget.seedColor,
                  widget.mode,
                ),
              if (numPlayers > 0)
                _Chip(
                  Translations.getOffsideText(
                    'playersCount',
                    widget.currentLang,
                  ).replaceAll('{count}', numPlayers.toString()),
                  widget.seedColor,
                  widget.mode,
                ),
            ],
          ),

          if ((widget.resp.secondLastDefenderProjection ?? double.nan)
              .isFinite) ...[
            const SizedBox(height: 10),
            _Chip(
              Translations.getOffsideText(
                'secondLastDefenderProj',
                widget.currentLang,
              ).replaceAll(
                '{value}',
                widget.resp.secondLastDefenderProjection!.toStringAsFixed(2),
              ),
              widget.seedColor,
              widget.mode,
            ),
          ],

          if ((widget.resp.reason ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                Translations.getOffsideText(
                  'reason',
                  widget.currentLang,
                ).replaceAll('{reason}', widget.resp.reason!),
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: AppColors.getTextColor(widget.mode),
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          if (annotated != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Translations.getOffsideText(
                    'annotatedImage',
                    widget.currentLang,
                  ),
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w700,
                    color: AppColors.getTextColor(widget.mode),
                  ),
                ),
                IconButton(
                  onPressed: () => widget.onSaveImage(annotated),
                  icon: const Icon(Icons.download, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Pretty preview
            GestureDetector(
              onTap: () => widget.onOpenImage((null, annotated)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.06),
                        Colors.white.withOpacity(0.02),
                      ],
                    ),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.network(
                            annotated,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('Image load error: $error');
                              return Container(
                                color: Colors.grey[800],
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.error,
                                        color: Colors.red,
                                        size: 50,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        Translations.getOffsideText(
                                          'noImageAvailable',
                                          widget.currentLang,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              Translations.getOffsideText(
                                'tapToZoomOriginal',
                                widget.currentLang,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  Translations.getOffsideText(
                    'noImageAvailable',
                    widget.currentLang,
                  ),
                  style: GoogleFonts.roboto(
                    color: AppColors.getTextColor(widget.mode).withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],

          // Si tu veux ré-afficher l’image d’entrée choisie (désactivé dans ton code)
          // if (widget.picked != null) ...
        ],
      ),
    );
  }
}

// =======================================================
// ===================== RESULT: Video ===================
// =======================================================

class _VideoResultCard extends StatefulWidget {
  final OffsideVideoResponse resp;
  final VideoPlayerController? controller; // player principal (full output)
  final int mode;
  final Color seedColor;
  final void Function(String url) onOpenVideo;
  final VoidCallback onSaveVideo;
  final void Function(String) onOpenOffsideImage;
  final void Function(String) onSaveOffsideImage;
  final void Function(String url) onOpenClipVideo;
  final void Function(String url) onSaveClipVideo;
  final String currentLang;

  const _VideoResultCard({
    required this.resp,
    required this.controller,
    required this.mode,
    required this.seedColor,
    required this.onOpenVideo,
    required this.onSaveVideo,
    required this.onOpenOffsideImage,
    required this.onSaveOffsideImage,
    required this.onOpenClipVideo,
    required this.onSaveClipVideo,
    required this.currentLang,
  });

  @override
  State<_VideoResultCard> createState() => _VideoResultCardState();
}

class _VideoResultCardState extends State<_VideoResultCard> {
  bool _showDetails = false;

  bool _resolveOffside() {
    // couvre le JSON d’exemple: offside_found + autres signaux
    if (widget.resp.offsideResolved == true) return true;
    if (widget.resp.offsideFound == true) return true; // map de offside_found
    if (widget.resp.offsideLine != null) return true;
    if ((widget.resp.offsideFrames?.isNotEmpty ?? false)) return true;
    if (widget.resp.meta?['offside_enable'] == true) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final bool isOff = _resolveOffside();
    final String verdictText = isOff
        ? Translations.getOffsideText('offsideVerdict', widget.currentLang)
        : Translations.getOffsideText('onsideVerdict', widget.currentLang);
    final Color verdictColor = isOff
        ? Colors.redAccent
        : Colors.lightGreenAccent;

    // Prendre le premier event pour frame_image (exemple JSON a un seul)
    final firstEvent = widget.resp.events.isNotEmpty
        ? widget.resp.events.first
        : null;
    final fullImageUrl = firstEvent != null
        ? _abs(firstEvent.frameImage)
        : null;
    final outputVideoUrl = _abs(widget.resp.fileUrl);

    return GlassCard(
      mode: widget.mode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verdict seulement
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: verdictColor.withOpacity(0.15),
              border: Border.all(color: verdictColor.withOpacity(0.4)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              verdictText,
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w800,
                color: AppColors.getTextColor(widget.mode),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Frame Image si disponible (FIXED: Added loading/error builders)
          if (fullImageUrl != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Translations.getOffsideText('frameImage', widget.currentLang),
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w700,
                    color: AppColors.getTextColor(widget.mode),
                  ),
                ),
                IconButton(
                  onPressed: () => widget.onSaveOffsideImage(fullImageUrl),
                  icon: const Icon(Icons.download, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => widget.onOpenOffsideImage(fullImageUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.06),
                        Colors.white.withOpacity(0.02),
                      ],
                    ),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.network(
                            fullImageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('Image load error: $error');
                              return Container(
                                color: Colors.grey[800],
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.error,
                                        color: Colors.red,
                                        size: 50,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        Translations.getOffsideText(
                                          'noImageAvailable',
                                          widget.currentLang,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              Translations.getOffsideText(
                                'tapToZoomOriginal',
                                widget.currentLang,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Output Video si disponible
          if (outputVideoUrl != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Translations.getRefereeTrackingText(
                    'outputVideo',
                    widget.currentLang,
                  ),
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w700,
                    color: AppColors.getTextColor(widget.mode),
                  ),
                ),
                IconButton(
                  onPressed: widget.onSaveVideo,
                  icon: const Icon(Icons.download, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => widget.onOpenVideo(outputVideoUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio:
                      (widget.controller != null &&
                          widget.controller!.value.isInitialized)
                      ? widget.controller!.value.aspectRatio
                      : 16 / 9,
                  child:
                      (widget.controller != null &&
                          widget.controller!.value.isInitialized)
                      ? Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            VideoPlayer(widget.controller!),
                            VideoProgressIndicator(
                              widget.controller!,
                              allowScrubbing: true,
                            ),
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  Translations.getOffsideText(
                                    'tapFullscreenControls',
                                    widget.currentLang,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          height: 200,
                          color: Colors.black12,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(),
                        ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  Translations.getOffsideText(
                    'noOutputVideo',
                    widget.currentLang,
                  ),
                  style: GoogleFonts.roboto(
                    color: AppColors.getTextColor(widget.mode).withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ... (rest of the file remains the same: _InlineClipPlayer, _DetailRow, _Chip, _LoadingOverlay, GlassCard, _SectionHeader, _FootballGridPainter)
class _InlineClipPlayer extends StatefulWidget {
  final String url;
  final VoidCallback onTap; // open fullscreen

  const _InlineClipPlayer({required this.url, required this.onTap, super.key});

  @override
  State<_InlineClipPlayer> createState() => _InlineClipPlayerState();
}

class _InlineClipPlayerState extends State<_InlineClipPlayer> {
  VideoPlayerController? _c;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _c!
        .initialize()
        .then((_) {
          if (!mounted) return;
          setState(() => _ready = true);
          // on ne joue pas automatiquement; c’est un aperçu cliquable
          _c!.pause();
          _c!.setLooping(false);
        })
        .catchError((e) => debugPrint('clip init error: $e'));
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_ready)
              AspectRatio(
                aspectRatio: _c!.value.aspectRatio == 0
                    ? 16 / 9
                    : _c!.value.aspectRatio,
                child: VideoPlayer(_c!),
              )
            else
              Container(
                color: Colors.black,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            // overlay Play
            Positioned.fill(
              child: Material(
                color: Colors.black26,
                child: InkWell(
                  onTap: widget.onTap,
                  child: const Center(
                    child: Icon(
                      Icons.play_circle,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
            // petite barre de progression (lecture figée)
            if (_ready)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: VideoProgressIndicator(_c!, allowScrubbing: false),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final int mode;
  const _DetailRow(this.label, this.value, this.mode);

  @override
  Widget build(BuildContext context) {
    final txt = AppColors.getTextColor(mode);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w500,
              color: txt.withOpacity(0.8),
            ),
          ),
        ),
        Expanded(
          child: Text(value, style: GoogleFonts.roboto(color: txt)),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color seedColor;
  final int mode;
  const _Chip(this.text, this.seedColor, this.mode, {super.key});
  @override
  Widget build(BuildContext context) {
    final txt = AppColors.getTextColor(mode);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.15),
        border: Border.all(
          color: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.35),
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(text, style: GoogleFonts.roboto(fontSize: 12, color: txt)),
    );
  }
}

// =======================================================
// ===================== LOADING OVERLAY =================
// =======================================================

class _LoadingOverlay extends StatelessWidget {
  final Color seedColor;
  final int mode;
  final ValueNotifier<int> secondsNotifier;
  final double upload;
  final double download;
  final String currentLang;
  const _LoadingOverlay({
    required this.seedColor,
    required this.mode,
    required this.secondsNotifier,
    required this.upload,
    required this.download,
    required this.currentLang,
  });

  String _fmt(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final r = (s % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.getSurfaceColor(mode).withOpacity(0.55),
                  Colors.black.withOpacity(0.50),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    GlassCard(
                      mode: mode,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Translations.getOffsideText(
                                    'generationInProgress',
                                    currentLang,
                                  ),
                                  style: GoogleFonts.manrope(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.getTextColor(mode),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  Translations.getOffsideText(
                                    'pleaseWaitAnalyzing',
                                    currentLang,
                                  ),
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    color: AppColors.getTextColor(
                                      mode,
                                    ).withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ValueListenableBuilder<int>(
                            valueListenable: secondsNotifier,
                            builder: (_, s, __) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.getTertiaryColor(
                                  seedColor,
                                  mode,
                                ).withOpacity(0.12),
                                border: Border.all(
                                  color: AppColors.getTertiaryColor(
                                    seedColor,
                                    mode,
                                  ).withOpacity(0.35),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _fmt(s),
                                style: GoogleFonts.roboto(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.getTextColor(mode),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      mode: mode,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LabeledBar(
                            label: Translations.getOffsideText(
                              'upload',
                              currentLang,
                            ),
                            value: upload,
                            mode: mode,
                            seedColor: seedColor,
                          ),
                          const SizedBox(height: 8),
                          _LabeledBar(
                            label: Translations.getOffsideText(
                              'processingDownload',
                              currentLang,
                            ),
                            value: download,
                            mode: mode,
                            seedColor: seedColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Lottie.asset(
                              'assets/lotties/offside.json',
                              width: 120,
                              height: 120,
                              repeat: true,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              Translations.getOffsideText(
                                'analysisInProgress',
                                currentLang,
                              ),
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                color: AppColors.getTextColor(
                                  mode,
                                ).withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ======== Sub-Widgets design ========

class GlassCard extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final int mode;

  const GlassCard({
    super.key,
    required this.mode,
    this.child,
    this.padding,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.getSurfaceColor(mode).withOpacity(0.5);
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [bg, bg.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.getTextColor(mode).withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.02),
            blurRadius: 2,
            spreadRadius: -1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int mode;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final txt = AppColors.getTextColor(mode);
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.getSecondaryColor(
            AppColors.seedColors[1]!,
            1,
          ).withOpacity(0.85),
          size: 26,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: txt,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}

// ======== Background painter ========

class _FootballGridPainter extends CustomPainter {
  final int mode;

  _FootballGridPainter(this.mode);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.getTextColor(mode).withOpacity(0.045)
      ..strokeWidth = 0.5;

    const step = 48.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final fieldPaint = Paint()
      ..color = AppColors.getTextColor(mode).withOpacity(0.085)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const inset = 40.0;
    final rect = Rect.fromLTWH(
      inset,
      inset * 2,
      size.width - inset * 2,
      size.height - inset * 4,
    );

    // Terrain central + cercle
    canvas.drawRect(rect, fieldPaint);
    final midY = rect.center.dy;
    canvas.drawLine(
      Offset(rect.left + rect.width / 2 - 100, midY),
      Offset(rect.left + rect.width / 2 + 100, midY),
      fieldPaint,
    );
    canvas.drawCircle(Offset(rect.left + rect.width / 2, midY), 30, fieldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
