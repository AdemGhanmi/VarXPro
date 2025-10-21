import 'dart:async';
import 'dart:io';
import 'dart:ui';
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

class OffsidePage extends StatefulWidget {
  const OffsidePage({super.key});
  @override
  State<OffsidePage> createState() => _OffsidePageState();
}

class _OffsidePageState extends State<OffsidePage> {
  bool _showSplash = true;

  VideoPlayerController? _videoController;
  String? _lastVideoUrl;
  MediaStore? _mediaStore;

  late final OffsideBloc _bloc;

  final ValueNotifier<int> _waitSeconds = ValueNotifier<int>(0);
  Timer? _waitTicker;

  /// 0 = original / 1 = 2D / 2 = 3D
  final ValueNotifier<int> _globalViewMode = ValueNotifier<int>(0);

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
    _globalViewMode.dispose();
    _bloc.close();
    super.dispose();
  }

  // ---------------------- Video helpers ----------------------
  void _initVideoPlayer(String url) {
    if (_lastVideoUrl == url &&
        _videoController != null &&
        _videoController!.value.isInitialized) {
      return;
    }
    _videoController?.dispose();
    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    _videoController = c;
    c.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      c.play();
      c.setLooping(false);
      _lastVideoUrl = url;
    }).catchError((e) => debugPrint('video init error: $e'));
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
    final savePath = '${dir.path}/varx_${DateTime.now().millisecondsSinceEpoch}$ext';
    final dio = Dio();
    await dio.download(url, savePath, options: Options(responseType: ResponseType.bytes));
    return savePath;
  }

  Future<bool> _ensureStoragePermission(BuildContext context) async {
    if (Platform.isAndroid) {
      final statuses = await [Permission.storage, Permission.photos, Permission.videos].request();
      final granted = statuses.values.any((s) => s.isGranted || s.isLimited);
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission requise pour enregistrer dans Téléchargements ❌'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return granted;
    }
    return true;
  }

  Future<void> _saveToDownloads(BuildContext context, String url, {bool isVideo = false}) async {
    try {
      final ok = await _ensureStoragePermission(context);
      if (!ok) return;

      if (_mediaStore == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('MediaStore non initialisé ❌'), backgroundColor: Colors.red),
        );
        return;
      }

      if (!Platform.isAndroid) {
        final dir = await getApplicationDocumentsDirectory();
        final fileName = 'VarXPro_${DateTime.now().millisecondsSinceEpoch}${isVideo ? '.mp4' : '.jpg'}';
        final savePath = '${dir.path}/$fileName';
        final dio = Dio();
        await dio.download(url, savePath);
        _toastSuccess(context, isVideo ? 'Vidéo enregistrée 📹' : 'Image enregistrée 📸');
        return;
      }

      final tempPath = await _downloadToTemp(url, isVideo: isVideo);
      final success = await _mediaStore!.saveFile(
        tempFilePath: tempPath,
        dirType: DirType.download,
        dirName: DirName.download,
      );

      if (success != null) {
        _toastSuccess(context, isVideo ? 'Vidéo enregistrée dans Téléchargements 📹' : 'Image enregistrée dans Téléchargements 📸');
      } else {
        _toastError(context, 'Échec de l’enregistrement ❌');
      }
    } catch (e) {
      _toastError(context, 'Erreur enregistrement: $e ❌');
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
    final textSecondary = textPrimary.withOpacity(0.7);
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

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

              if (state.videoResponse?.fileUrl != null) {
                _initVideoPlayer(state.videoResponse!.fileUrl!);
              }

              final r = state.offsideFrameResponse;
              if (r != null) {
                final has3D = r.field3D != null &&
                    ((r.field3D!.pitch != null && r.field3D!.pitch!.isNotEmpty) ||
                        r.field3D!.offsideLine != null ||
                        r.field3D!.players.isNotEmpty ||
                        r.field3D!.homographyAvailable);

                final has2D = r.field2D != null &&
                    ((r.field2D!.pitch != null && r.field2D!.pitch!.isNotEmpty) ||
                        r.field2D!.offsideLine != null ||
                        r.field2D!.players.isNotEmpty);

                // Default to original
                _globalViewMode.value = 0;
              }

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
                        child: CustomPaint(
                          painter: _FootballGridPainter(mode),
                        ),
                      ),
                    ),

                    // =============== CONTENT ===============
                    SafeArea(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(16, isPortrait ? 12 : 8, 16, 16),
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
                                    const Icon(Icons.error_outline, color: Colors.redAccent),
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
                              title: 'Single Frame Detection',
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
                              ),
                            ],

                            if (state.offsideFrameResponse != null) ...[
                              const SizedBox(height: 20),
                              _FrameResultCard(
                                resp: state.offsideFrameResponse!,
                                picked: state.pickedImage,
                                mode: mode,
                                seedColor: seedColor,
                                globalViewMode: _globalViewMode,
                                onOpenImage: (fileOrUrl) => _openImageFullscreen(file: fileOrUrl.$1, url: fileOrUrl.$2),
                                onSaveImage: (url) => _saveToDownloads(context, url),
                                onSaveFile: (file) async {
                                  if (_mediaStore == null || !Platform.isAndroid) {
                                    _toastError(context, 'Sauvegarde non supportée sur cette plateforme ❌');
                                    return;
                                  }
                                  try {
                                    final tempDir = await getTemporaryDirectory();
                                    final tempPath = '${tempDir.path}/temp_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
                                    await file.copy(tempPath);
                                    final success = await _mediaStore!.saveFile(
                                      tempFilePath: tempPath,
                                      dirType: DirType.download,
                                      dirName: DirName.download,
                                    );
                                    if (success != null) {
                                      _toastSuccess(context, 'Image enregistrée dans Téléchargements 📸');
                                    } else {
                                      _toastError(context, 'Échec de l’enregistrement ❌');
                                    }
                                  } catch (e) {
                                    _toastError(context, 'Erreur: $e ❌');
                                  }
                                },
                              ),
                            ],

                            const SizedBox(height: 20),

                            if (state.videoResponse != null) ...[
                              _SectionHeader(
                                icon: Icons.play_circle_outline,
                                title: 'Video Analysis',
                                mode: mode,
                              ),
                              const SizedBox(height: 10),
                              _VideoResultCard(
                                resp: state.videoResponse!,
                                controller: _videoController,
                                mode: mode,
                                seedColor: seedColor,
                                globalViewMode: _globalViewMode,
                                onOpenVideo: (url) => _openVideoFullscreen(url),
                                onSaveVideo: () {
                                  final u = state.videoResponse!.fileUrl;
                                  if (u != null) _saveToDownloads(context, u, isVideo: true);
                                },
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
        return StatefulBuilder(builder: (ctx, setSt) {
          return GestureDetector(
            onDoubleTap: () => setSt(() => scale = (scale == 1.0 ? 2.0 : 1.0)),
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
                            : (url != null ? Image.network(url, fit: BoxFit.contain) : const SizedBox.shrink()),
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
        });
      },
    );
  }

  void _openVideoFullscreen(String url) {
    final isReadyNotifier = ValueNotifier(false);
    final scaleNotifier = ValueNotifier(1.0);
    final showControlsNotifier = ValueNotifier(true);
    VideoPlayerController? dialogController;

    dialogController = VideoPlayerController.networkUrl(Uri.parse(url));
    dialogController.initialize().then((_) {
      isReadyNotifier.value = true;
      dialogController!.play();
    }).catchError((e) => debugPrint('dialog video init error: $e'));

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
                      onDoubleTap: () => scaleNotifier.value = (scale == 1.0 ? 2.0 : 1.0),
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
                                      aspectRatio: dialogController.value.aspectRatio,
                                      child: Stack(
                                        alignment: Alignment.bottomCenter,
                                        children: [
                                          VideoPlayer(dialogController),
                                          if (showControls)
                                            VideoProgressIndicator(
                                              dialogController,
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
                              const Center(child: CircularProgressIndicator(color: Colors.white)),
                            if (showControls && isReady && dialogController != null)
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
                                        final currentPos = dialogController!.value.position;
                                        final target = currentPos - const Duration(seconds: 10);
                                        final newPos = target < Duration.zero
                                            ? Duration.zero
                                            : (target > dialogController.value.duration
                                                ? dialogController.value.duration
                                                : target);
                                        dialogController.seekTo(newPos);
                                      },
                                    ),
                                    const SizedBox(width: 12),
                                    _HoloRoundButton(
                                      icon: dialogController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
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
                                        final currentPos = dialogController!.value.position;
                                        final target = currentPos + const Duration(seconds: 10);
                                        final newPos = target < Duration.zero
                                            ? Duration.zero
                                            : (target > dialogController.value.duration
                                                ? dialogController.value.duration
                                                : target);
                                        dialogController.seekTo(newPos);
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
                                  onTap: () => _saveToDownloads(context, url, isVideo: true),
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
  const _ProgressCard({
    required this.upload,
    required this.download,
    required this.cancellable,
    required this.onCancel,
    required this.mode,
    required this.seedColor,
  });

  @override
  State<_ProgressCard> createState() => _ProgressCardState();
}

class _ProgressCardState extends State<_ProgressCard> with SingleTickerProviderStateMixin {
  late AnimationController _downloadController;
  late Animation<double> _downloadAnimation;

  @override
  void initState() {
    super.initState();
    _downloadController = AnimationController(vsync: this, duration: const Duration(seconds: 5));
    _downloadAnimation = Tween<double>(begin: 0.0, end: widget.download).animate(
      CurvedAnimation(parent: _downloadController, curve: Curves.easeInOut),
    );
    if (widget.download > 0) _downloadController.forward();
  }

  @override
  void didUpdateWidget(_ProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.download != oldWidget.download) {
      _downloadAnimation = Tween<double>(
        begin: _downloadAnimation.value,
        end: widget.download,
      ).animate(
        CurvedAnimation(parent: _downloadController, curve: Curves.easeInOut),
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
          _LabeledBar(label: 'Uploading 📤', value: widget.upload, mode: widget.mode, seedColor: widget.seedColor),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _downloadAnimation,
            builder: (context, child) {
              return _LabeledBar(
                label: 'Processing/Downloading ⚙️',
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
                side: BorderSide(color: AppColors.getTertiaryColor(widget.seedColor, widget.mode).withOpacity(0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: widget.onCancel,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Cancel'),
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
        Row(children: [
          Text(label, style: GoogleFonts.roboto(fontWeight: FontWeight.w600, color: txt)),
          const Spacer(),
          Text('$pct%', style: GoogleFonts.roboto(fontWeight: FontWeight.w800, color: txt)),
        ]),
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
  final ValueListenable<int> globalViewMode;

  const _FrameResultCard({
    required this.resp,
    required this.picked,
    required this.mode,
    required this.seedColor,
    required this.onOpenImage,
    required this.onSaveImage,
    required this.onSaveFile,
    required this.globalViewMode,
  });

  @override
  State<_FrameResultCard> createState() => _FrameResultCardState();
}

class _FrameResultCardState extends State<_FrameResultCard> {
  bool _hasMeaningfulData(dynamic m) {
    if (m is Field2DModel) {
      return m.pitch != null || (m.frameSize['w'] ?? 0) > 0 || m.offsideLine != null || m.players.isNotEmpty;
    }
    if (m is Field3DModel) {
      return m.pitch != null || (m.fieldSizeM['length'] ?? 0) > 0 || m.homographyAvailable || m.offsideLine != null || m.players.isNotEmpty;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    bool isOff = widget.resp.offsideResolved;

    if (widget.resp.offsideLine != null) {
      isOff = true;
    } else {
      final offsideEnable = widget.resp.meta?['offside_enable'] == true;
      isOff = offsideEnable ? true : false;
    }

    final String verdictText = isOff ? 'OFFSIDE 🚩' : 'ONSIDE ⚽';
    final Color verdictColor = isOff ? Colors.redAccent : Colors.lightGreenAccent;

    final has2D = widget.resp.field2D != null && _hasMeaningfulData(widget.resp.field2D!);
    final has3D = widget.resp.field3D != null && _hasMeaningfulData(widget.resp.field3D!);

    final numPlayers = (widget.resp.meta?['meta']?['num_players'] as num?)?.toInt() ?? 0;

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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: verdictColor.withOpacity(0.15),
                  border: Border.all(color: verdictColor.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(verdictText, style: GoogleFonts.roboto(fontWeight: FontWeight.w800, color: AppColors.getTextColor(widget.mode))),
              ),
              if (widget.resp.attackingTeam != null)
                _Chip('🔵 Attacking: ${widget.resp.attackingTeam}', widget.seedColor, widget.mode),
              if (widget.resp.attackDirection != null)
                _Chip('➡️ Dir: ${widget.resp.attackDirection}', widget.seedColor, widget.mode),
              if ((widget.resp.offsidesCount ?? 0) > 0) _Chip('🚩 Offsides: ${widget.resp.offsidesCount}', widget.seedColor, widget.mode),
              if (numPlayers > 0) _Chip('👥 Players: $numPlayers', widget.seedColor, widget.mode),
            ],
          ),

          if ((widget.resp.secondLastDefenderProjection ?? double.nan).isFinite) ...[
            const SizedBox(height: 10),
            _Chip('🛡️ 2nd Last Defender Proj: ${widget.resp.secondLastDefenderProjection!.toStringAsFixed(2)}', widget.seedColor, widget.mode),
          ],

          if ((widget.resp.reason ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('Reason: ${widget.resp.reason}', style: GoogleFonts.roboto(fontSize: 14, fontStyle: FontStyle.italic, color: AppColors.getTextColor(widget.mode))),
            ),
          ],

          const SizedBox(height: 12),

          if (has2D || has3D) ...[
            _ViewModeSwitcher(globalViewMode: widget.globalViewMode, enable2D: has2D, enable3D: has3D),
            const SizedBox(height: 10),
          ],

          ValueListenableBuilder<int>(
            valueListenable: widget.globalViewMode,
            builder: (_, view, __) {
              String? currentUrl;
              String currentLabel = '';
              if (view == 0) {
                currentUrl = widget.resp.fileUrl;
                currentLabel = 'Annotated Image 🎯';
              } else if (view == 1) {
                currentUrl = widget.resp.image2DUrl;
                currentLabel = '2D Tactical View 🎯';
              } else if (view == 2) {
                currentUrl = widget.resp.image3DUrl;
                currentLabel = '3D Tactical View 🎯';
              }
              final viewName = view == 0 ? 'Original' : (view == 1 ? '2D' : '3D');

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (view == 0 && widget.picked != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Picked Image 📷', style: GoogleFonts.roboto(fontWeight: FontWeight.w700, color: AppColors.getTextColor(widget.mode))),
                        IconButton(onPressed: () => widget.onSaveFile(widget.picked!), icon: const Icon(Icons.download, color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => widget.onOpenImage((widget.picked, null)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(widget.picked!, height: 200, width: double.infinity, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (currentUrl != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(currentLabel, style: GoogleFonts.roboto(fontWeight: FontWeight.w700, color: AppColors.getTextColor(widget.mode))),
                        IconButton(onPressed: () => widget.onSaveImage(currentUrl!), icon: const Icon(Icons.download, color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Pretty preview
                    GestureDetector(
                      onTap: () => widget.onOpenImage((null, currentUrl)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.white.withOpacity(0.06),
                              Colors.white.withOpacity(0.02),
                            ]),
                          ),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Image.network(currentUrl, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  right: 10,
                                  bottom: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text('Tap to zoom • $viewName', style: const TextStyle(color: Colors.white, fontSize: 11)),
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
                        child: Text('No $viewName image available from backend', style: GoogleFonts.roboto(color: AppColors.getTextColor(widget.mode).withOpacity(0.7)), textAlign: TextAlign.center),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
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
  final VideoPlayerController? controller;
  final int mode;
  final Color seedColor;
  final void Function(String url) onOpenVideo;
  final VoidCallback onSaveVideo;
  final ValueListenable<int> globalViewMode;

  const _VideoResultCard({
    required this.resp,
    required this.controller,
    required this.mode,
    required this.seedColor,
    required this.onOpenVideo,
    required this.onSaveVideo,
    required this.globalViewMode,
  });

  @override
  State<_VideoResultCard> createState() => _VideoResultCardState();
}

class _VideoResultCardState extends State<_VideoResultCard> {
  bool _hasMeaningfulData(dynamic m) {
    if (m is Field2DModel) {
      return m.pitch != null || (m.frameSize['w'] ?? 0) > 0 || m.offsideLine != null || m.players.isNotEmpty;
    }
    if (m is Field3DModel) {
      return m.pitch != null || (m.fieldSizeM['length'] ?? 0) > 0 || m.homographyAvailable || m.offsideLine != null || m.players.isNotEmpty;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    bool isOff = widget.resp.offsideResolved;
    if (widget.resp.offsideLine != null) {
      isOff = true;
    } else {
      final offsideEnable = widget.resp.meta?['offside_enable'] == true;
      isOff = offsideEnable ? true : false;
    }

    final String verdictText = isOff ? 'OFFSIDE 🚩' : 'ONSIDE ⚽';
    final Color verdictColor = isOff ? Colors.redAccent : Colors.lightGreenAccent;

    final has2D = widget.resp.field2D != null && _hasMeaningfulData(widget.resp.field2D!);
    final has3D = widget.resp.field3D != null && _hasMeaningfulData(widget.resp.field3D!);

    final numPlayers = (widget.resp.meta?['meta']?['num_players'] as num?)?.toInt() ?? 0;

    return GlassCard(
      mode: widget.mode,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: verdictColor.withOpacity(0.15),
                border: Border.all(color: verdictColor.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(verdictText, style: GoogleFonts.roboto(fontWeight: FontWeight.w800, color: AppColors.getTextColor(widget.mode))),
            ),
            if (widget.resp.attackingTeam != null) _Chip('🔵 Attacking: ${widget.resp.attackingTeam}', widget.seedColor, widget.mode),
            if (widget.resp.attackDirection != null) _Chip('➡️ Dir: ${widget.resp.attackDirection}', widget.seedColor, widget.mode),
            if ((widget.resp.offsidesCount ?? 0) > 0) _Chip('🚩 Offsides: ${widget.resp.offsidesCount}', widget.seedColor, widget.mode),
            if (numPlayers > 0) _Chip('👥 Players: $numPlayers', widget.seedColor, widget.mode),
          ],
        ),

        if ((widget.resp.reason ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text('Reason: ${widget.resp.reason}', style: GoogleFonts.roboto(fontSize: 14, fontStyle: FontStyle.italic, color: AppColors.getTextColor(widget.mode))),
          ),
        ],

        const SizedBox(height: 12),

        if (has2D || has3D) ...[
          // ✅ fix: activer vraiment le switch 2D/3D si disponibles côté vidéo
          _ViewModeSwitcher(globalViewMode: widget.globalViewMode, enable2D: has2D, enable3D: has3D),
          const SizedBox(height: 10),
        ],

        ValueListenableBuilder<int>(
          valueListenable: widget.globalViewMode,
          builder: (_, view, __) {
            if (view == 0) {
              return Column(
                children: [
                  if (widget.resp.fileUrl != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Annotated Video 🎥', style: GoogleFonts.roboto(fontWeight: FontWeight.w700, color: AppColors.getTextColor(widget.mode))),
                        IconButton(onPressed: widget.onSaveVideo, icon: const Icon(Icons.download, color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => widget.onOpenVideo(widget.resp.fileUrl!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: (widget.controller != null && widget.controller!.value.isInitialized)
                              ? widget.controller!.value.aspectRatio
                              : 16 / 9,
                          child: (widget.controller != null && widget.controller!.value.isInitialized)
                              ? Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    VideoPlayer(widget.controller!),
                                    VideoProgressIndicator(widget.controller!, allowScrubbing: true),
                                    Positioned(
                                      right: 8,
                                      bottom: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                                        child: const Text('Tap for Fullscreen + Controls 🎞️', style: TextStyle(color: Colors.white, fontSize: 11)),
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
                  ],
                ],
              );
            } else {
              final viewName = view == 1 ? '2D' : '3D';
              // Placeholder premium tant que le backend ne renvoie pas un média vidéo pour 2D/3D
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$viewName Tactical View for Video', style: GoogleFonts.roboto(fontWeight: FontWeight.w700, color: AppColors.getTextColor(widget.mode), fontSize: 16)),
                  const SizedBox(height: 8),
                  Container(
                    height: 220,
                    decoration: BoxDecoration(color: Colors.grey.withOpacity(0.25), borderRadius: BorderRadius.circular(12)),
                    child: const Center(
                      child: Text('Tactical view for video coming soon', style: TextStyle(color: Colors.white54), textAlign: TextAlign.center),
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ]),
    );
  }
}

// =======================================================
// =================== VIEW SWITCHER (global) ============
// =======================================================

class _ViewModeSwitcher extends StatelessWidget {
  final ValueListenable<int> globalViewMode;
  final bool enable2D;
  final bool enable3D;
  const _ViewModeSwitcher({required this.globalViewMode, required this.enable2D, required this.enable3D});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: globalViewMode,
      builder: (_, v, __) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _ViewPill(label: 'Original', isActive: v == 0, onTap: () => (globalViewMode as ValueNotifier<int>).value = 0),
                _ViewPill(
                  label: '2D',
                  isActive: v == 1,
                  disabled: !enable2D,
                  onTap: () {
                    if (enable2D) (globalViewMode as ValueNotifier<int>).value = 1;
                  },
                ),
                _ViewPill(
                  label: '3D',
                  isActive: v == 2,
                  disabled: !enable3D,
                  onTap: () {
                    if (enable3D) (globalViewMode as ValueNotifier<int>).value = 2;
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ViewPill extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool disabled;
  final VoidCallback onTap;
  const _ViewPill({required this.label, required this.isActive, this.disabled = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final base = disabled ? 0.35 : 1.0;
    return AnimatedOpacity(
      opacity: base,
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: disabled ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: isActive
                  ? const LinearGradient(colors: [Color(0xFF5AE6FF), Color(0xFF5A8BFF)])
                  : null,
              color: isActive ? null : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(isActive ? 0.0 : 0.12)),
              boxShadow: isActive
                  ? const [
                      BoxShadow(color: Color(0x885AE6FF), blurRadius: 20, spreadRadius: 1, offset: Offset(0, 6)),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
        ),
      ),
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
        border: Border.all(color: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.35)),
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
  const _LoadingOverlay({
    required this.seedColor,
    required this.mode,
    required this.secondsNotifier,
    required this.upload,
    required this.download,
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
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Génération en cours…', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.getTextColor(mode))),
                                const SizedBox(height: 4),
                                Text(
                                  'Veuillez patienter, nous analysons votre média et traçons les lignes offside.',
                                  style: GoogleFonts.manrope(fontSize: 13, color: AppColors.getTextColor(mode).withOpacity(0.7)),
                                ),
                              ],
                            ),
                          ),
                          ValueListenableBuilder<int>(
                            valueListenable: secondsNotifier,
                            builder: (_, s, __) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.12),
                                border: Border.all(
                                  color: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.35),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(_fmt(s), style: GoogleFonts.roboto(fontWeight: FontWeight.w700, color: AppColors.getTextColor(mode))),
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
                          _LabeledBar(label: 'Upload 📤', value: upload, mode: mode, seedColor: seedColor),
                          const SizedBox(height: 8),
                          _LabeledBar(label: 'Processing/Download ⚙️', value: download, mode: mode, seedColor: seedColor),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: AppColors.getTertiaryColor(seedColor, mode)),
                            const SizedBox(height: 16),
                            Text('Analyse en cours...', style: GoogleFonts.manrope(fontSize: 16, color: AppColors.getTextColor(mode).withOpacity(0.7))),
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
        border: Border.all(color: AppColors.getTextColor(mode).withOpacity(0.08)),
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
          color: AppColors.getSecondaryColor(AppColors.seedColors[1]!, 1).withOpacity(0.85),
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
    final rect = Rect.fromLTWH(inset, inset * 2, size.width - inset * 2, size.height - inset * 4);

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