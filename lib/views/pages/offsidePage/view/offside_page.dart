// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:VarXPro/model/appColor.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/views/pages/offsidePage/controller/offside_controller.dart';
import 'package:VarXPro/views/pages/offsidePage/model/offside_model.dart';
import 'package:VarXPro/views/pages/offsidePage/service/offside_service.dart';
import 'package:VarXPro/views/pages/offsidePage/widgets/OffsideForm.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
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

class _OffsidePageState extends State<OffsidePage> with TickerProviderStateMixin {
  bool _showSplash = true;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  VideoPlayerController? _videoController;
  String? _lastVideoUrl;
  MediaStore? _mediaStore;

  // Overlay timer
  final ValueNotifier<int> _waitSeconds = ValueNotifier<int>(0);
  Timer? _waitTicker;

  @override
  void initState() {
    super.initState();
    debugPrint('=== OffsidePage initState started ===');
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _glowAnimation = Tween(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showSplash = false);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await MediaStore.ensureInitialized();
      MediaStore.appFolder = 'VarXPro'; // Fix: Set the app folder to resolve AppFolderNotSetException
      if (mounted) {
        setState(() {
          _mediaStore = MediaStore();
        });
      }
    });
    debugPrint('=== OffsidePage initState completed ===');
  }

  @override
  void dispose() {
    debugPrint('=== OffsidePage dispose started ===');
    _waitTicker?.cancel();
    _waitSeconds.dispose();
    _glowController.dispose();
    _videoController?.dispose();
    super.dispose();
    debugPrint('=== OffsidePage dispose completed ===');
  }

  void _initVideoPlayer(String url) {
    debugPrint('=== _initVideoPlayer called with URL: $url ===');
    if (_lastVideoUrl == url && _videoController != null && _videoController!.value.isInitialized) {
      debugPrint('=== Video already initialized, skipping ===');
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
    }).catchError((e) => debugPrint('=== Video init error: $e ==='));
  }

  /// Downloads a remote media to a temp file and returns the local path.
  Future<String> _downloadToTemp(String url, {required bool isVideo}) async {
    try {
      final dir = await getTemporaryDirectory();
      String ext = '';
      final seg = Uri.parse(url).pathSegments;
      if (seg.isNotEmpty && seg.last.contains('.')) {
        ext = '.${seg.last.split('.').last}';
      } else {
        ext = isVideo ? '.mp4' : '.jpg';
      }
      final savePath = '${dir.path}/varx_${DateTime.now().millisecondsSinceEpoch}$ext';
      debugPrint('=== Downloading to $savePath ===');
      final dio = Dio();
      await dio.download(url, savePath, options: Options(responseType: ResponseType.bytes));
      return savePath;
    } catch (e) {
      debugPrint('=== Download error: $e ===');
      rethrow;
    }
  }

  Future<bool> _ensureStoragePermission() async {
    if (Platform.isAndroid) {
      // Try modern read permissions first (Android 13+), fall back to storage
      final perms = await [
        Permission.storage,
        Permission.photos, // no-op on some versions but harmless if supported
        Permission.videos, // idem
      ].request();
      final granted = perms.values.any((s) => s.isGranted);
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission requise pour enregistrer dans les téléchargements ❌'), backgroundColor: Colors.red),
        );
      }
      return granted;
    }
    // iOS: Assume handled by file ops or fallback
    return true;
  }

  Future<void> _saveToDownloads(String url, {bool isVideo = false}) async {
    try {
      debugPrint('=== Saving to downloads: $url (video: $isVideo) ===');
      final ok = await _ensureStoragePermission();
      if (!ok) return;

      if (_mediaStore == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('MediaStore non initialisé ❌'), backgroundColor: Colors.red),
        );
        return;
      }

      if (!Platform.isAndroid) {
        // For iOS, save to documents directory
        final dir = await getApplicationDocumentsDirectory();
        final fileName = 'VarXPro_${DateTime.now().millisecondsSinceEpoch}${isVideo ? '.mp4' : '.jpg'}';
        final savePath = '${dir.path}/$fileName';
        final dio = Dio();
        await dio.download(url, savePath);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isVideo ? 'Vidéo enregistrée 📹' : 'Image enregistrée 📸'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      // Download to temp first
      final tempPath = await _downloadToTemp(url, isVideo: isVideo);

      final success = await _mediaStore!.saveFile(
        tempFilePath: tempPath,
        dirType: DirType.download,
        dirName: DirName.download,
        // relativePath removed since appFolder is set globally
      );

      if (success != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isVideo ? 'Vidéo enregistrée dans Téléchargements 📹' : 'Image enregistrée dans Téléchargements 📸'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de l’enregistrement ❌'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('=== Save error: $e ===');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur enregistrement: $e ❌'), backgroundColor: Colors.red),
      );
    }
  }

  /// ---------- Fullscreen viewer (Image)
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
              backgroundColor: Colors.black.withOpacity(0.9),
              insetPadding: const EdgeInsets.all(0),
              child: Stack(
                children: [
                  InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    scaleEnabled: true,
                    panEnabled: true,
                    boundaryMargin: const EdgeInsets.all(80),
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
                    child: IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close, size: 28, color: Colors.white),
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

  /// ---------- Fullscreen viewer (Video + enhanced controls)
  void _openVideoFullscreen(String url) {
    final isReadyNotifier = ValueNotifier(false);
    final scaleNotifier = ValueNotifier(1.0);
    final showControlsNotifier = ValueNotifier(true);
    VideoPlayerController? dialogController;

    dialogController = VideoPlayerController.networkUrl(Uri.parse(url));
    dialogController.initialize().then((_) {
      isReadyNotifier.value = true;
      dialogController!.play();
    }).catchError((e) => debugPrint('=== Dialog video init error: $e ==='));

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
                                    // Rewind 10s
                                    IconButton(
                                      iconSize: 56,
                                      onPressed: () {
                                        final currentPos = dialogController!.value.position;
                                        Duration target = currentPos - const Duration(seconds: 10);
                                        Duration newPos = target < Duration.zero ? Duration.zero : (target > dialogController.value.duration ? dialogController.value.duration : target);
                                        dialogController.seekTo(newPos);
                                      },
                                      icon: const Icon(Icons.replay_10, color: Colors.white),
                                    ),
                                    // Play/Pause
                                    IconButton(
                                      iconSize: 56,
                                      onPressed: () {
                                        if (dialogController!.value.isPlaying) {
                                          dialogController.pause();
                                        } else {
                                          dialogController.play();
                                        }
                                      },
                                      icon: Icon(
                                        dialogController.value.isPlaying ? Icons.pause : Icons.play_arrow,
                                        color: Colors.white,
                                      ),
                                    ),
                                    // Forward 10s
                                    IconButton(
                                      iconSize: 56,
                                      onPressed: () {
                                        final currentPos = dialogController!.value.position;
                                        Duration target = currentPos + const Duration(seconds: 10);
                                        Duration newPos = target < Duration.zero ? Duration.zero : (target > dialogController.value.duration ? dialogController.value.duration : target);
                                        dialogController.seekTo(newPos);
                                      },
                                      icon: const Icon(Icons.forward_10, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            // Download button in controls
                            if (showControls && isReady)
                              Positioned(
                                bottom: 50,
                                right: 16,
                                child: IconButton(
                                  onPressed: () => _saveToDownloads(url, isVideo: true),
                                  icon: const Icon(Icons.download, color: Colors.green, size: 28),
                                ),
                              ),
                            Positioned(
                              top: 40,
                              right: 16,
                              child: IconButton(
                                onPressed: () {
                                  dialogController?.dispose();
                                  Navigator.of(ctx).pop();
                                },
                                icon: const Icon(Icons.close, size: 28, color: Colors.white),
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

  // Overlay control
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

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final modeProvider = Provider.of<ModeProvider>(context);
    final currentLang = langProvider.currentLanguage;
    final mode = modeProvider.currentMode;
    final seedColor = AppColors.seedColors[mode] ?? AppColors.seedColors[1]!;

    if (_showSplash) {
      return Scaffold(
        backgroundColor: AppColors.getBackgroundColor(mode),
        body: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _FootballGridPainter(mode),
                child: Container(decoration: BoxDecoration(gradient: AppColors.getBodyGradient(mode))),
              ),
            ),
            Center(
              child: ScaleTransition(
                scale: _glowAnimation,
                child: Lottie.asset('assets/lotties/offside.json', width: MediaQuery.of(context).size.width * 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return BlocProvider(
      create: (_) {
        final bloc = OffsideBloc(OffsideService())..add(PingEvent());
        return bloc;
      },
      child: Builder(builder: (blocContext) {
        return BlocConsumer<OffsideBloc, OffsideState>(
          listener: (context, state) {
            if (state.isLoading) {
              _startWaitTimer();
            } else {
              _stopWaitTimer();
            }

            if (state.videoResponse?.annotatedVideoUrl != null) {
              _initVideoPlayer(state.videoResponse!.annotatedVideoUrl!);
            }
            if (state.error != null && state.error!.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error!, style: GoogleFonts.roboto(color: Colors.white)),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          },
          builder: (context, state) {
            return Scaffold(
              backgroundColor: AppColors.getBackgroundColor(mode),
              body: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _FootballGridPainter(mode),
                      child: Container(decoration: BoxDecoration(gradient: AppColors.getBodyGradient(mode))),
                    ),
                  ),
                  SafeArea(
                    child: LayoutBuilder(builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          constraints.maxWidth * 0.04,
                          constraints.maxWidth * 0.04,
                          constraints.maxWidth * 0.04,
                          kBottomNavigationBarHeight + constraints.maxWidth * 0.06,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionHeader('Single Frame Detection 📸', mode, seedColor),
                            const SizedBox(height: 8),
                            OffsideForm(
                              constraints: constraints,
                              currentLang: currentLang,
                              mode: mode,
                              seedColor: seedColor,
                            ),
                            if (state.isLoading) ...[
                              const SizedBox(height: 18),
                              _ProgressCard(
                                upload: state.uploadProgress,
                                download: state.downloadProgress,
                                cancellable: state.cancellable,
                                onCancel: () => context.read<OffsideBloc>().add(CancelCurrentRequestEvent()),
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
                                onOpenImage: (fileOrUrl) => _openImageFullscreen(file: fileOrUrl.$1, url: fileOrUrl.$2),
                                onSaveImage: (url) => _saveToDownloads(url),
                                onSaveFile: (file) async {
                                  if (_mediaStore == null || !Platform.isAndroid) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Sauvegarde non supportée sur cette plateforme ❌'), backgroundColor: Colors.red),
                                    );
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
                                      // relativePath removed since appFolder is set
                                    );
                                    if (success != null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Image enregistrée dans Téléchargements 📸'), backgroundColor: Colors.green),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Échec de l’enregistrement ❌'), backgroundColor: Colors.red),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Erreur: $e ❌'), backgroundColor: Colors.red),
                                    );
                                  }
                                },
                              ),
                            ],
                            const SizedBox(height: 20),
                            if (state.videoResponse != null) ...[
                              const SizedBox(height: 12),
                              _VideoResultCard(
                                resp: state.videoResponse!,
                                controller: _videoController,
                                mode: mode,
                                seedColor: seedColor,
                                onOpenVideo: (url) => _openVideoFullscreen(url),
                                onSaveVideo: () => _saveToDownloads(state.videoResponse!.annotatedVideoUrl!, isVideo: true),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ),

                  // ===== Fancy waiting overlay with mini-game =====
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
      }),
    );
  }
}

/// ---------- UI WIDGETS + Glass helpers

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  const _GlassCard({required this.child, this.padding = const EdgeInsets.all(16), this.radius = 16, super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.06),
                Colors.white.withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 18,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.15),
        border: Border.all(color: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.35)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(text, style: GoogleFonts.roboto(fontSize: 12)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int mode;
  final Color seedColor;
  const _SectionHeader(this.title, this.mode, this.seedColor, {super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 24, color: AppColors.getTertiaryColor(seedColor, mode)),
        const SizedBox(width: 10),
        Text(title, style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

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
    _downloadAnimation = Tween<double>(begin: 0.0, end: widget.download).animate(CurvedAnimation(parent: _downloadController, curve: Curves.easeInOut));
    if (widget.download > 0) _downloadController.forward();
  }

  @override
  void didUpdateWidget(_ProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.download != oldWidget.download) {
      _downloadAnimation = Tween<double>(begin: _downloadAnimation.value, end: widget.download).animate(
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
    return _GlassCard(
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
  const _LabeledBar({required this.label, required this.value, required this.mode, required this.seedColor});

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).clamp(0, 100).toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(label, style: GoogleFonts.roboto(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('$pct%'),
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

class _FrameResultCard extends StatelessWidget {
  final OffsideFrameResponse resp;
  final File? picked;
  final int mode;
  final Color seedColor;
  final void Function((File?, String?)) onOpenImage;
  final void Function(String) onSaveImage;
  final void Function(File) onSaveFile;

  const _FrameResultCard({
    required this.resp,
    required this.picked,
    required this.mode,
    required this.seedColor,
    required this.onOpenImage,
    required this.onSaveImage,
    required this.onSaveFile,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOff = resp.offsideResolved;
    final String verdictText = isOff ? 'OFFSIDE 🚩' : 'ONSIDE ⚽';
    final Color verdictColor = isOff ? Colors.redAccent : Colors.lightGreenAccent;

    return _GlassCard(
      radius: 18,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: verdictColor.withOpacity(0.15),
                border: Border.all(color: verdictColor.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(verdictText, style: GoogleFonts.roboto(fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 10),
            if (resp.attackingTeam != null) _Chip('🔵 Attacking: ${resp.attackingTeam}', seedColor, mode),
            if (resp.attackDirection != null) Padding(padding: const EdgeInsets.only(left: 8.0), child: _Chip('➡️ Dir: ${resp.attackDirection}', seedColor, mode)),
            if (resp.offsidesCount > 0) Padding(padding: const EdgeInsets.only(left: 8.0), child: _Chip('🚩 Offsides: ${resp.offsidesCount}', seedColor, mode)),
          ],
        ),
        if (resp.secondLastDefenderProjection != null) ...[
          const SizedBox(height: 8),
          _Chip('🛡️ 2nd Last Defender Proj: ${resp.secondLastDefenderProjection!.toStringAsFixed(2)}', seedColor, mode),
        ],
        if (resp.reason != null && resp.reason!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text('Reason: ${resp.reason}', style: GoogleFonts.roboto(fontSize: 14, fontStyle: FontStyle.italic)),
          ),
        ],
        if (resp.players != null && resp.players!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('👥 Players Detected: ${resp.players!.length}', style: GoogleFonts.roboto(fontWeight: FontWeight.w600)),
        ],
        const SizedBox(height: 12),
        if (picked != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Picked Image 📷', style: GoogleFonts.roboto(fontWeight: FontWeight.w700)),
              IconButton(onPressed: () => onSaveFile(picked!), icon: const Icon(Icons.download, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => onOpenImage((picked, null)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(picked!, height: 200, width: double.infinity, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (resp.annotatedImageUrl != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Annotated Image 🎯', style: GoogleFonts.roboto(fontWeight: FontWeight.w700)),
              IconButton(onPressed: () => onSaveImage(resp.annotatedImageUrl!), icon: const Icon(Icons.download, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => onOpenImage((null, resp.annotatedImageUrl)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(resp.annotatedImageUrl!, height: 220, width: double.infinity, fit: BoxFit.cover),
            ),
          ),
        ],
      ]),
    );
  }
}

class _VideoResultCard extends StatelessWidget {
  final OffsideVideoResponse resp;
  final VideoPlayerController? controller;
  final int mode;
  final Color seedColor;
  final void Function(String url) onOpenVideo;
  final VoidCallback onSaveVideo;

  const _VideoResultCard({
    required this.resp,
    required this.controller,
    required this.mode,
    required this.seedColor,
    required this.onOpenVideo,
    required this.onSaveVideo,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOff = resp.offsideResolved;
    final String verdictText = isOff ? 'OFFSIDE 🚩' : 'ONSIDE ⚽';
    final Color verdictColor = isOff ? Colors.redAccent : Colors.lightGreenAccent;

    return _GlassCard(
      radius: 18,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: verdictColor.withOpacity(0.15),
                border: Border.all(color: verdictColor.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(verdictText, style: GoogleFonts.roboto(fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 10),
            if (resp.attackingTeam != null) _Chip('🔵 Attacking: ${resp.attackingTeam}', seedColor, mode),
            if (resp.attackDirection != null)
              Padding(padding: const EdgeInsets.only(left: 8.0), child: _Chip('➡️ Dir: ${resp.attackDirection}', seedColor, mode)),
            if (resp.offsidesCount > 0)
              Padding(padding: const EdgeInsets.only(left: 8.0), child: _Chip('🚩 Offsides: ${resp.offsidesCount}', seedColor, mode)),
          ],
        ),
        if (resp.secondLastDefenderProjection != null) ...[
          const SizedBox(height: 8),
          _Chip('🛡️ 2nd Last Defender Proj: ${resp.secondLastDefenderProjection!.toStringAsFixed(2)}', seedColor, mode),
        ],
        if (resp.reason != null && resp.reason!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text('Reason: ${resp.reason}', style: GoogleFonts.roboto(fontSize: 14, fontStyle: FontStyle.italic)),
          ),
        ],
        if (resp.players != null && resp.players!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('👥 Players Detected: ${resp.players!.length}', style: GoogleFonts.roboto(fontWeight: FontWeight.w600)),
        ],
        const SizedBox(height: 12),
        if (resp.annotatedVideoUrl != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Annotated Video 🎥', style: GoogleFonts.roboto(fontWeight: FontWeight.w700)),
              IconButton(onPressed: onSaveVideo, icon: const Icon(Icons.download, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => onOpenVideo(resp.annotatedVideoUrl!),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: (controller != null && controller!.value.isInitialized) ? controller!.value.aspectRatio : 16 / 9,
                child: (controller != null && controller!.value.isInitialized)
                    ? Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          VideoPlayer(controller!),
                          VideoProgressIndicator(controller!, allowScrubbing: true),
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                              child: const Text('Tap for Fullscreen + Controls (Rewind/Play/Forward) 🎞️', style: TextStyle(color: Colors.white, fontSize: 11)),
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
      ]),
    );
  }
}

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
                    _GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Génération en cours…', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text(
                                  'Veuillez patienter, nous analysons votre vidéo et traçons les lignes offside.',
                                  style: GoogleFonts.manrope(fontSize: 13, color: Colors.white70),
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
                                border: Border.all(color: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.35)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(_fmt(s), style: GoogleFonts.roboto(fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _GlassCard(
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
                      child: _GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mini-jeu : Keepy-Up ⚽', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            Expanded(child: _KeepyUpGame(seedColor: seedColor, mode: mode)),
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

/// Mini-jeu V2: أسرع، حركة أفقية، شرارات، هابتيك، و restart سريع.
class _KeepyUpGame extends StatefulWidget {
  final Color seedColor;
  final int mode;
  const _KeepyUpGame({required this.seedColor, required this.mode});
  @override
  State<_KeepyUpGame> createState() => _KeepyUpGameState();
}

class _KeepyUpGameState extends State<_KeepyUpGame> with SingleTickerProviderStateMixin {
  late Ticker _ticker;

  // وضعية الكورة (0..1 نسبية للمساحة)
  double x = 0.5;
  double y = 0.5;

  // السرعات
  double vx = 0.0;
  double vy = 0.0;

  // دوران
  double rotation = 0.0;
  double rotSpeed = 0.0;

  // صعوبة/جاذبية
  double gravityBase = 2.1;   // جاذبية أساسية أعلى → نزول أسرع
  double gravityBoost = 2.0;  // جاذبية إضافية تزيد كلما الكورة طالعة

  // أرضية/جدران
  final double ground = 0.92;
  final double wallLeft = 0.08;
  final double wallRight = 0.92;

  // سكور/كومبو/سرعة
  int score = 0;
  int combo = 0;
  double speedMultiplier = 1.0;
  double timeSinceStart = 0.0;

  // حالة اللعبة
  bool gameOver = false;
  Timer? _resetTimer;

  // Particles
  final List<_Particle> particles = [];
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _resetGame();
    _ticker = createTicker(_tick)..start();
  }

  void _resetGame() {
    x = 0.5; y = 0.55;
    vx = 0; vy = 0;
    rotation = 0; rotSpeed = 0;
    score = 0; combo = 0;
    speedMultiplier = 1.0;
    timeSinceStart = 0.0;
    gameOver = false;
    particles.clear();
    _resetTimer?.cancel();
    setState(() {});
  }

  void _scheduleFastRestart() {
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) _resetGame();
    });
  }

  void _spawnBurst({required double px, required double py, int count = 14, double power = 1.0}) {
    for (int i = 0; i < count; i++) {
      final a = _rand.nextDouble() * pi * 2;
      final r = (_rand.nextDouble() * 0.012 + 0.006) * power;
      particles.add(_Particle(
        x: px,
        y: py,
        vx: cos(a) * r,
        vy: sin(a) * r,
        life: 0.7 + _rand.nextDouble() * 0.4,
      ));
    }
  }

  void _tick(Duration d) {
    if (gameOver) return;

    const dt = 1 / 60.0;
    timeSinceStart += dt;

    speedMultiplier = 1.0 + min(0.5, timeSinceStart * 0.03) + min(0.4, combo * 0.03);

    final dynG = (gravityBase + gravityBoost * (1 - y).clamp(0, 1)) * speedMultiplier;
    vy += dynG * dt;

    x += vx * dt;
    y += vy * dt;

    rotation += rotSpeed * dt;
    rotSpeed *= 0.985; 
    vx *= 0.996;      

    if (x <= wallLeft) {
      x = wallLeft;
      vx = -vx * 0.85;
      rotSpeed = -rotSpeed * 0.9;
      HapticFeedback.lightImpact();
      _spawnBurst(px: x, py: y, count: 10, power: 0.9);
    } else if (x >= wallRight) {
      x = wallRight;
      vx = -vx * 0.85;
      rotSpeed = -rotSpeed * 0.9;
      HapticFeedback.lightImpact();
      _spawnBurst(px: x, py: y, count: 10, power: 0.9);
    }

    if (y >= ground) {
      y = ground;
      vy = -vy * 0.92;            
      rotSpeed = -rotSpeed * 0.9;
      HapticFeedback.mediumImpact();
      _spawnBurst(px: x, py: y, count: 18, power: 1.2);

      if (vy.abs() < 0.6) {
        gameOver = true;
        combo = 0;
        _scheduleFastRestart();
      }
    }

    for (int i = particles.length - 1; i >= 0; i--) {
      final p = particles[i];
      p.life -= dt;
      if (p.life <= 0) {
        particles.removeAt(i);
      } else {
        p.vy += (dynG * 0.15) * dt;
        p.x += p.vx;
        p.y += p.vy;
      }
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    _resetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (d) {
        if (gameOver) {
          _resetGame();
          return;
        }
        final size = context.size ?? const Size(1, 1);
        final tapX = (d.localPosition.dx / size.width).clamp(0.0, 1.0);
        final tapY = (d.localPosition.dy / size.height).clamp(0.0, 1.0);

        final dx = tapX - x;
        final dy = tapY - y;
        final dist = sqrt(dx * dx + dy * dy);

        const r = 0.11;

        if (dist < r) {
          final underBall = tapY > y; 
          final perfect = underBall && (tapY - y) < 0.06 && dx.abs() < 0.05;

          final baseUp = 3.8 + (combo * 0.12);
          vy = -baseUp * (perfect ? 1.15 : 1.0) * speedMultiplier;

          final horiz = (x - tapX) * (perfect ? 9.0 : 6.0) * (1 + combo * 0.05);
          vx += horiz * speedMultiplier;

          rotSpeed += vx * 3.8;

          if (perfect) {
            combo += 3;
            score += 3;
            HapticFeedback.heavyImpact();
            _spawnBurst(px: x, py: y, count: 24, power: 1.6);
          } else {
            combo += 1;
            score += 1;
            HapticFeedback.selectionClick();
            _spawnBurst(px: x, py: y, count: 14, power: 1.2);
          }
        } else {
          vy = -2.6 * speedMultiplier;
          vx += (x - tapX) * 4.5 * speedMultiplier;
          combo = max(0, combo - 1);
          rotSpeed += vx * 2.2;
          HapticFeedback.lightImpact();
          _spawnBurst(px: tapX, py: tapY, count: 8, power: 0.8);
        }
      },
      child: LayoutBuilder(builder: (ctx, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final ballPx = Offset(x * w, y * h);

        return Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.getSurfaceColor(widget.mode).withOpacity(0.25),
                      Colors.green.withOpacity(0.15),
                      Colors.black.withOpacity(0.2),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.7, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomPaint(painter: _GrassPainter()),
              ),
            ),

            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _WallsPainter(
                    leftX: wallLeft * w,
                    rightX: wallRight * w,
                    groundY: ground * h,
                    color: AppColors.getTextColor(widget.mode).withOpacity(0.08),
                  ),
                ),
              ),
            ),

            
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ParticlesPainter(particles: particles, color: AppColors.getTertiaryColor(widget.seedColor, widget.mode)),
                ),
              ),
            ),

            Positioned(
              left: ballPx.dx - 24,
              top:  ballPx.dy - 24,
              child: Transform.rotate(
                angle: rotation,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Colors.white.withOpacity(0.9), AppColors.getTertiaryColor(widget.seedColor, widget.mode)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.getTertiaryColor(widget.seedColor, widget.mode).withOpacity(0.6),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(child: Text('⚽', style: TextStyle(fontSize: 20))),
                ),
              ),
            ),

            Positioned(
              top: 8,
              right: 12,
              child: _GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('Score: $score', style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 12)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: combo >= 10 ? Colors.red : (combo >= 5 ? Colors.orange : Colors.blue),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('x$combo', style: GoogleFonts.manrope(color: Colors.white, fontSize: 10)),
                      ),
                    ]),
                    if (speedMultiplier > 1.0)
                      Text('Speed: ${(speedMultiplier * 100).round()}%', style: GoogleFonts.manrope(fontSize: 9, color: Colors.yellow)),
                  ],
                ),
              ),
            ),

            if (gameOver)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.35),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sports_soccer, size: 64, color: Colors.white54),
                      Text('Game Over! Score: $score', style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text('Tap to restart ⚡', style: GoogleFonts.manrope(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _Particle {
  double x, y, vx, vy, life;
  _Particle({required this.x, required this.y, required this.vx, required this.vy, required this.life});
}

class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final Color color;
  _ParticlesPainter({required this.particles, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    for (final part in particles) {
      final t = part.life.clamp(0.0, 1.0);
      p.color = color.withOpacity(0.2 + 0.6 * t);
      final r = 3.0 * t + 1.0;
      canvas.drawCircle(Offset(part.x * size.width, part.y * size.height), r, p);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) => true;
}

class _WallsPainter extends CustomPainter {
  final double leftX, rightX, groundY;
  final Color color;
  _WallsPainter({required this.leftX, required this.rightX, required this.groundY, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    // حيطان خفيفة
    canvas.drawLine(Offset(leftX, 0), Offset(leftX, size.height), paint);
    canvas.drawLine(Offset(rightX, 0), Offset(rightX, size.height), paint);
    // الأرضية
    canvas.drawLine(Offset(0, groundY), Offset(size.width, groundY), paint..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant _WallsPainter oldDelegate) => false;
}

// Painter simple pour herbe au sol
class _GrassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.3)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;
    final groundY = size.height * 0.92;
    final rand = Random(42);
    for (int i = 0; i < size.width / 6; i++) { // plus d'herbe pour densité
      final x = i * 6.0 + rand.nextDouble() * 3;
      canvas.drawLine(Offset(x, groundY), Offset(x + rand.nextDouble() * 3 - 1.5, groundY - 25), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
// Updated _FootballGridPainter with subtler opacities for a fuller yet less intense background
class _FootballGridPainter extends CustomPainter {
  final int mode;
  _FootballGridPainter(this.mode);
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.getTextColor(mode).withOpacity(0.03)  // Reduced from 0.06 for subtler grid
      ..strokeWidth = 0.5;
    const step = 50.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final fieldPaint = Paint()
      ..color = AppColors.getTextColor(mode).withOpacity(0.06)  // Reduced from 0.12 for softer field outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final inset = 40.0;
    final rect = Rect.fromLTWH(inset, inset * 2, size.width - inset * 2, size.height - inset * 4);
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