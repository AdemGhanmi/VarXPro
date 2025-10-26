// Updated BallGoalPage code with full translation compatibility
import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/views/pages/BallGoalPage/controller/ballgoal_controller.dart';
import 'package:VarXPro/views/pages/BallGoalPage/model/ballgoal_model.dart';
import 'package:VarXPro/views/pages/BallGoalPage/service/ballgoal_service.dart';
import 'package:VarXPro/views/pages/BallGoalPage/widgets/image_picker_widget.dart';
import 'package:VarXPro/views/setting/provider/history_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:video_player/video_player.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class BallGoalPage extends StatefulWidget {
  const BallGoalPage({super.key});

  @override
  _BallGoalPageState createState() => _BallGoalPageState();
}

class _BallGoalPageState extends State<BallGoalPage> {
  bool _showSplash = true;

  VideoPlayerController? _videoController;
  String? _lastVideoUrl;
  MediaStore? _mediaStore;

  late final BallGoalBloc _bloc;

  final ValueNotifier<int> _waitSeconds = ValueNotifier<int>(0);
  Timer? _waitTicker;

  @override
  void initState() {
    super.initState();
    _bloc = BallGoalBloc(BallGoalService())..add(PingEvent());
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

  Future<bool> _ensureStoragePermission(BuildContext context) async {
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
              Translations.getBallGoalText('permissionRequiredSaveDownloads', context.watch<LanguageProvider>().currentLanguage),
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
    String url, {
    bool isVideo = false,
  }) async {
    try {
      final ok = await _ensureStoragePermission(context);
      if (!ok) return;

      if (_mediaStore == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Translations.getBallGoalText('mediaStoreNotInitialized', context.watch<LanguageProvider>().currentLanguage)),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!Platform.isAndroid) {
        final dir = await getApplicationDocumentsDirectory();
        final fileName =
            'VarXPro_${DateTime.now().millisecondsSinceEpoch}${isVideo ? '.mp4' : '.jpg'}';
        final savePath = '${dir.path}/$fileName';
        final dio = Dio();
        await dio.download(url, savePath);
        _toastSuccess(
          context,
          isVideo ? Translations.getBallGoalText('videoSaved', context.watch<LanguageProvider>().currentLanguage) : Translations.getBallGoalText('imageSaved', context.watch<LanguageProvider>().currentLanguage),
        );
        return;
      }

      final tempPath = await _downloadToTemp(url, isVideo: isVideo);
      final success = await _mediaStore!.saveFile(
        tempFilePath: tempPath,
        dirType: DirType.download,
        dirName: DirName.download,
      );

      if (success != null) {
        _toastSuccess(
          context,
          isVideo
              ? Translations.getBallGoalText('videoSavedDownloads', context.watch<LanguageProvider>().currentLanguage)
              : Translations.getBallGoalText('imageSavedDownloads', context.watch<LanguageProvider>().currentLanguage),
        );
      } else {
        _toastError(context, Translations.getBallGoalText('saveFailure', context.watch<LanguageProvider>().currentLanguage));
      }
    } catch (e) {
      _toastError(context, '${Translations.getBallGoalText('saveError', context.watch<LanguageProvider>().currentLanguage)} $e');
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

  // =================== Fullscreen viewers ===================
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
                                          dialogController.value.aspectRatio,
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
                                                      dialogController
                                                          .value
                                                          .duration
                                                  ? dialogController
                                                        .value
                                                        .duration
                                                  : target);
                                        dialogController.seekTo(newPos);
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
                                                      dialogController
                                                          .value
                                                          .duration
                                                  ? dialogController
                                                        .value
                                                        .duration
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
                                  onTap: () => _saveToDownloads(
                                    context,
                                    url,
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

  // ========================================================
  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final modeProvider = Provider.of<ModeProvider>(context);
    final currentLang = langProvider.currentLanguage;
    final mode = modeProvider.currentMode;
    final seedColor = AppColors.seedColors[mode] ?? AppColors.seedColors[1]!;
    final size = MediaQuery.of(context).size;
    final textPrimary = AppColors.getTextColor(mode);
    final textSecondary = textPrimary.withOpacity(0.7);
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    if (_showSplash) {
      return Scaffold(
        backgroundColor: AppColors.getBackgroundColor(mode),
        body: Center(
          child: Lottie.asset(
            'assets/lotties/FoulDetection.json',
            width: size.width * 0.8,
            height: size.height * 0.5,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    final testConfigs = [
      {'type': 'corner', 'label': Translations.getBallGoalText('cornerKick', currentLang), 'icon': Icons.turn_right},
      {'type': 'touch', 'label': Translations.getBallGoalText('touchline', currentLang), 'icon': Icons.straighten},
      {'type': 'goal', 'label': Translations.getBallGoalText('goalLine', currentLang), 'icon': Icons.flag},
      {'type': 'six_meter', 'label': Translations.getBallGoalText('sixMeterBox', currentLang), 'icon': Icons.aspect_ratio},
    ];

    return BlocProvider.value(
      value: _bloc,
      child: Builder(
        builder: (blocContext) {
          return BlocConsumer<BallGoalBloc, BallGoalState>(
            listener: (context, state) {
              if (state.isLoading) {
                _startWaitTimer();
              } else {
                _stopWaitTimer();
              }

              if (state.ballInOutVideoResponse?.fileUrl != null) {
                _initVideoPlayer(state.ballInOutVideoResponse!.fileUrl!);
              }

              if (state.error != null) {
                _toastError(context, state.error!);
              }

              if (state.ballInOutResponse?.ok == true ||
                  state.ballInOutVideoResponse?.ok == true) {
                final historyProvider = Provider.of<HistoryProvider>(
                  context,
                  listen: false,
                );
                final title = state.currentTestType != null
                    ? '${Translations.getBallGoalText('eventTestLabel', currentLang).replaceAll('{label}', state.currentTestType!)}'
                    : Translations.getBallGoalText('ballInOut', currentLang);
                historyProvider.addHistoryItem(title, Translations.getTranslation('Analysis complete! View results.', currentLang));
              }
            },
            builder: (context, state) {
              final onSaveVideo = () {
                if (state.ballInOutVideoResponse?.fileUrl != null) {
                  _saveToDownloads(
                    context,
                    state.ballInOutVideoResponse!.fileUrl!,
                    isVideo: true,
                  );
                }
              };
              final onOpenVideo = (String url) => _openVideoFullscreen(url);

              return Scaffold(
                backgroundColor: Colors.transparent,
                body: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.getBodyGradient(mode),
                        ),
                        child: CustomPaint(painter: _FootballGridPainter(mode)),
                      ),
                    ),
                    SafeArea(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          16,
                          isPortrait ? 12 : 8,
                          16,
                          16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (state.error != null)
                              GlassCard(
                                mode: mode,
                                padding: const EdgeInsets.all(14),
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
                                        '${Translations.getBallGoalText('error', currentLang)}: ${state.error}',
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
                            // Image Ball In/Out Section
                            GlassCard(
                              mode: mode,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionHeader(
                                    icon: Icons.sports_soccer,
                                    title: Translations.getBallGoalText(
                                      'ballInOut',
                                      currentLang,
                                    ),
                                    mode: mode,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    Translations.getBallGoalText(
                                      'selectImageForBallInOut',
                                      currentLang,
                                    ),
                                    style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      color: textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ImagePickerWidget(
                                    onImagePicked: (File file) =>
                                        context.read<BallGoalBloc>().add(
                                          BallInOutEvent(
                                            file,
                                            isVideo: false,
                                            testType: null,
                                          ),
                                        ),
                                    buttonText: Translations.getBallGoalText(
                                      'selectImageForBallInOut',
                                      currentLang,
                                    ),
                                    isVideo: false,
                                    mode: mode,
                                    seedColor: seedColor,
                                  ),
                                  const SizedBox(height: 12),
                                  if (state.isLoading &&
                                      state.currentTestType == null)
                                    const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  if (state.ballInOutResponse != null)
                                    _BallInOutResult(
                                      response: state.ballInOutResponse!,
                                      mode: mode,
                                      seedColor: seedColor,
                                      currentLang: currentLang,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            // Specific Event Tests Section
                            GlassCard(
                              mode: mode,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionHeader(
                                    icon: Icons.videocam,
                                    title: Translations.getBallGoalText('specificEventTests', currentLang),
                                    mode: mode,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    Translations.getBallGoalText('uploadVideoTestEvents', currentLang),
                                    style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      color: textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ...testConfigs.map<Widget>((config) {
                                    final type = config['type'] as String;
                                    final label = config['label'] as String;
                                    final icon = config['icon'] as IconData;
                                    final isActive =
                                        state.currentTestType == type;
                                    final testButtonText = Translations.getBallGoalText('testLabel', currentLang).replaceAll('{label}', label);
                                    final analyzingText = Translations.getBallGoalText('analyzingLabel', currentLang).replaceAll('{label}', label);
                                    final detectionText = Translations.getBallGoalText('detectionForEvent', currentLang)
                                        .replaceAll('{eventName}', label)
                                        .replaceAll('{result}', isActive ? Translations.getBallGoalText('yes', currentLang) : Translations.getBallGoalText('no', currentLang));
                                    final eventTestSubLabel = Translations.getBallGoalText('eventTestLabel', currentLang).replaceAll('{label}', label);
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 20,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Test Header
                                          Row(
                                            children: [
                                              Icon(
                                                icon,
                                                color: seedColor.withOpacity(
                                                  0.8,
                                                ),
                                                size: 22,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                label,
                                                style: GoogleFonts.roboto(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  color: textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          // Picker Button
                                          Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: isActive
                                                  ? seedColor.withOpacity(0.1)
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isActive
                                                    ? seedColor
                                                    : Colors.transparent,
                                                width: isActive ? 2 : 0,
                                              ),
                                            ),
                                            child: ImagePickerWidget(
                                              onImagePicked: (File file) =>
                                                  context
                                                      .read<BallGoalBloc>()
                                                      .add(
                                                        BallInOutEvent(
                                                          file,
                                                          isVideo: true,
                                                          testType: type,
                                                        ),
                                                      ),
                                              buttonText: testButtonText,
                                              isVideo: true,
                                              mode: mode,
                                              seedColor: seedColor,
                                              enabled: !state.isLoading,
                                            ),
                                          ),
                                          // Conditional Result or Loading under this button
                                          if (isActive) ...[
                                            const SizedBox(height: 16),
                                            if (state.isLoading) ...[
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: seedColor.withOpacity(
                                                    0.05,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: seedColor
                                                        .withOpacity(0.3),
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    CircularProgressIndicator(
                                                      color: seedColor,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        analyzingText,
                                                        style:
                                                            GoogleFonts.roboto(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  textPrimary,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ] else if (state
                                                    .ballInOutVideoResponse !=
                                                null) ...[
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: seedColor.withOpacity(
                                                    0.05,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: seedColor
                                                        .withOpacity(0.3),
                                                  ),
                                                ),
                                                child: _SpecificTestResult(
                                                  response: state
                                                      .ballInOutVideoResponse!,
                                                  testType: type,
                                                  mode: mode,
                                                  seedColor: seedColor,
                                                  currentLang: currentLang,
                                                  controller: _videoController,
                                                  onOpenVideo: onOpenVideo,
                                                  onSaveVideo: onSaveVideo,
                                                  label: label,
                                                  detectionText: detectionText,
                                                  eventTestSubLabel: eventTestSubLabel,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                          ],
                        ),
                      ),
                    ),
                    if (state.isLoading && state.currentTestType == null)
                      _LoadingOverlay(
                        seedColor: seedColor,
                        mode: mode,
                        secondsNotifier: _waitSeconds,
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

  Color _getResultColor(String result, int mode) {
    final textPrimary = AppColors.getTextColor(mode);
    final r = result.toLowerCase();
    if (r.contains('in') || r.contains('play'))
      return Colors.green.withOpacity(0.85);
    if (r.contains('out')) return Colors.red.withOpacity(0.9);
    return textPrimary;
  }
}

// Updated _SpecificTestResult with translation params
class _SpecificTestResult extends StatelessWidget {
  final BallInOutVideoResponse response;
  final String testType;
  final int mode;
  final Color seedColor;
  final String currentLang;
  final VideoPlayerController? controller;
  final Function(String) onOpenVideo;
  final VoidCallback onSaveVideo;
  final String label;
  final String detectionText;
  final String eventTestSubLabel;

  const _SpecificTestResult({
    required this.response,
    required this.testType,
    required this.mode,
    required this.seedColor,
    required this.currentLang,
    required this.controller,
    required this.onOpenVideo,
    required this.onSaveVideo,
    required this.label,
    required this.detectionText,
    required this.eventTestSubLabel,
  });

  @override
  Widget build(BuildContext context) {
    final expectedState = _getExpectedState(testType);
    final relevantEvents = response.ballEvents.where((e) {
      final state = e['state'] as String?;
      return state?.toLowerCase() == expectedState.toLowerCase();
    }).toList();

    final count = relevantEvents.length;
    final detected = count > 0;
    final yesNo = detected ? Translations.getBallGoalText('yes', currentLang) : Translations.getBallGoalText('no', currentLang);
    final detectedStatus = detected ? 'DETECTED' : 'NOT DETECTED';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TestEvaluationBadge(detected: detected, eventName: label, currentLang: currentLang),
        const SizedBox(height: 12),
        _DecisionBanner(
          mode: mode,
          decision: detectedStatus,
          color: detected
              ? Colors.green.withOpacity(0.85)
              : Colors.red.withOpacity(0.9),
          subLabel: eventTestSubLabel,
        ),

        if (response.fileUrl != null) ...[
          const SizedBox(height: 16),
          _VideoResultCard(
            resp: response,
            controller: controller,
            mode: mode,
            seedColor: seedColor,
            onOpenVideo: onOpenVideo,
            onSaveVideo: onSaveVideo,
            currentLang: currentLang,
          ),
        ],
      ],
    );
  }

  String _getExpectedState(String testType) {
    switch (testType) {
      case 'corner':
        return 'corner_kick';
      case 'touch':
        return 'touchline';
      case 'goal':
        return 'goal';
      case 'six_meter':
        return 'six_meter';
      default:
        return testType;
    }
  }
}

// Updated _TestEvaluationBadge with translation
class _TestEvaluationBadge extends StatelessWidget {
  final bool detected;
  final String eventName;
  final String currentLang;

  const _TestEvaluationBadge({required this.detected, required this.eventName, required this.currentLang});

  @override
  Widget build(BuildContext context) {
    final color = detected ? Colors.green : Colors.redAccent;
    final yesNo = detected ? Translations.getBallGoalText('yes', currentLang) : Translations.getBallGoalText('no', currentLang);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(
            detected ? Icons.check_circle : Icons.cancel,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${Translations.getBallGoalText('detectionForEvent', currentLang).replaceAll('{eventName}', eventName).replaceAll('{result}', yesNo)}',
              style: GoogleFonts.roboto(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Updated _VideoResultCard with translation
class _VideoResultCard extends StatefulWidget {
  final BallInOutVideoResponse resp;
  final VideoPlayerController? controller;
  final int mode;
  final Color seedColor;
  final void Function(String url) onOpenVideo;
  final VoidCallback onSaveVideo;
  final String currentLang;

  const _VideoResultCard({
    required this.resp,
    required this.controller,
    required this.mode,
    required this.seedColor,
    required this.onOpenVideo,
    required this.onSaveVideo,
    required this.currentLang,
  });

  @override
  State<_VideoResultCard> createState() => _VideoResultCardState();
}

class _VideoResultCardState extends State<_VideoResultCard> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.resp.fileUrl != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${Translations.getBallGoalText('annotatedVideo', widget.currentLang)} 🎥',
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
            onTap: () => widget.onOpenVideo(widget.resp.fileUrl!),
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
                                '${Translations.getBallGoalText('tapToRestart', widget.currentLang)} 🎞️',
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
        ],
      ],
    );
  }
}

// Updated _LoadingOverlay with translation
class _LoadingOverlay extends StatelessWidget {
  final Color seedColor;
  final int mode;
  final ValueNotifier<int> secondsNotifier;
  final String currentLang;
  const _LoadingOverlay({
    required this.seedColor,
    required this.mode,
    required this.secondsNotifier,
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
                                  Translations.getBallGoalText('generationInProgress', currentLang),
                                  style: GoogleFonts.manrope(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.getTextColor(mode),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  Translations.getBallGoalText('pleaseWaitAnalyzingMedia', currentLang),
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
                    const SizedBox(height: 16),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Lottie.asset(
                              'assets/lotties/FoulDetection.json',
                              width: 120,
                              height: 120,
                              repeat: true,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              Translations.getBallGoalText('analysisInProgress', currentLang),
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

// Rest of the code remains the same (GlassCard, _SectionHeader, _SummaryItem, _DecisionBanner, _EvaluationBadge, _BallInOutResult, _BallInOutVideoResult, _FootballGridPainter, _HoloIconButton, _HoloRoundButton)
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

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final int mode;
  final Color seedColor;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.mode,
    required this.seedColor,
  });

  @override
  Widget build(BuildContext context) {
    final txt = AppColors.getTextColor(mode);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getPrimaryColor(seedColor, mode).withOpacity(0.055),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.getPrimaryColor(seedColor, mode).withOpacity(0.75),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.roboto(
                    color: txt.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.roboto(
                    color: txt,
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionBanner extends StatelessWidget {
  final int mode;
  final String decision;
  final Color color;
  final String subLabel;

  const _DecisionBanner({
    required this.mode,
    required this.decision,
    required this.color,
    required this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    final txt = AppColors.getTextColor(mode);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.18),
            blurRadius: 16,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subLabel,
                  style: GoogleFonts.roboto(
                    color: txt.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 12.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  decision,
                  style: GoogleFonts.roboto(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EvaluationBadge extends StatelessWidget {
  final String outcome;
  final String currentLang;

  const _EvaluationBadge({required this.outcome, required this.currentLang});

  @override
  Widget build(BuildContext context) {
    final isSuccess = outcome.toLowerCase() == 'success';
    final color = isSuccess ? Colors.green : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(isSuccess ? Icons.check_circle : Icons.cancel, color: color),
          const SizedBox(width: 8),
          Text(
            '${Translations.getBallGoalText('analysisSuccess', currentLang)}: ${outcome.toUpperCase()}',
            style: GoogleFonts.roboto(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _BallInOutResult extends StatelessWidget {
  final BallInOutResponse response;
  final int mode;
  final Color seedColor;
  final String currentLang;

  const _BallInOutResult({
    required this.response,
    required this.mode,
    required this.seedColor,
    required this.currentLang,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EvaluationBadge(
          outcome: response.ok ? 'success' : 'failed',
          currentLang: currentLang,
        ),
        const SizedBox(height: 8),
        _DecisionBanner(
          mode: mode,
          decision: response.result,
          color: _getResultColor(response.result, mode),
          subLabel: Translations.getBallGoalText('ballState', currentLang),
        ),
      ],
    );
  }

  Color _getResultColor(String result, int mode) {
    final textPrimary = AppColors.getTextColor(mode);
    final r = result.toLowerCase();
    if (r.contains('in') || r.contains('play'))
      return Colors.green.withOpacity(0.85);
    if (r.contains('out')) return Colors.red.withOpacity(0.9);
    return textPrimary;
  }
}

class _BallInOutVideoResult extends StatelessWidget {
  final BallInOutVideoResponse response;
  final int mode;
  final Color seedColor;
  final String currentLang;
  final VideoPlayerController? controller;
  final Function(String) onOpenVideo;
  final VoidCallback onSaveVideo;

  const _BallInOutVideoResult({
    required this.response,
    required this.mode,
    required this.seedColor,
    required this.currentLang,
    required this.controller,
    required this.onOpenVideo,
    required this.onSaveVideo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EvaluationBadge(
          outcome: response.ok ? 'success' : 'failed',
          currentLang: currentLang,
        ),
        const SizedBox(height: 8),
        if (response.bestBallEvent != null)
          _DecisionBanner(
            mode: mode,
            decision:
                response.bestBallEvent!['state']?.toUpperCase() ?? 'UNKNOWN',
            color: _getResultColor(
              response.bestBallEvent!['state'] ?? '',
              mode,
            ),
            subLabel: Translations.getBallGoalText(
              'bestBallEvent',
              currentLang,
            ),
          ),
        const SizedBox(height: 8),
        Text(
          Translations.getBallGoalText('ballEvents', currentLang),
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.getTextColor(mode),
          ),
        ),
        const SizedBox(height: 6),
        if (response.ballEvents.isEmpty)
          Text(
            Translations.getBallGoalText('noBallEvents', currentLang),
            style: GoogleFonts.roboto(
              color: AppColors.getTextColor(mode).withOpacity(0.7),
            ),
          )
        else
          Column(
            children: response.ballEvents
                .map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _SummaryItem(
                      icon: Icons.timer,
                      label: 'Frame: ${event['frame'] ?? 'N/A'}',
                      value: event['state']?.toUpperCase() ?? 'UNKNOWN',
                      mode: mode,
                      seedColor: seedColor,
                    ),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 12),
        Text(
          Translations.getBallGoalText('offsideEvents', currentLang),
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.getTextColor(mode),
          ),
        ),
        const SizedBox(height: 6),
        if (response.offsideEvents.isEmpty)
          Text(
            Translations.getBallGoalText('noOffsideEvents', currentLang),
            style: GoogleFonts.roboto(
              color: AppColors.getTextColor(mode).withOpacity(0.7),
            ),
          )
        else
          Column(
            children: response.offsideEvents
                .map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _SummaryItem(
                      icon: Icons.flag,
                      label: 'Frame: ${event['frame'] ?? 'N/A'}',
                      value:
                          'OFFSIDE (Margin: ${event['margin']?.toStringAsFixed(2) ?? 'N/A'})',
                      mode: mode,
                      seedColor: seedColor,
                    ),
                  ),
                )
                .toList(),
          ),
        if (response.counts != null) ...[
          const SizedBox(height: 8),
          _SummaryItem(
            icon: Icons.calculate,
            label: Translations.getBallGoalText('totalOuts', currentLang),
            value: response.counts!['total_outs']?.toString() ?? '0',
            mode: mode,
            seedColor: seedColor,
          ),
          _SummaryItem(
            icon: Icons.calculate,
            label: Translations.getBallGoalText('totalOffsides', currentLang),
            value: response.counts!['total_offsides']?.toString() ?? '0',
            mode: mode,
            seedColor: seedColor,
          ),
        ],
        if (response.fileUrl != null) ...[
          const SizedBox(height: 12),
          _VideoResultCard(
            resp: response,
            controller: controller,
            mode: mode,
            seedColor: seedColor,
            onOpenVideo: onOpenVideo,
            onSaveVideo: onSaveVideo,
            currentLang: currentLang,
          ),
        ],
      ],
    );
  }

  Color _getResultColor(String result, int mode) {
    final textPrimary = AppColors.getTextColor(mode);
    final r = result.toLowerCase();
    if (r.contains('in') || r.contains('play'))
      return Colors.green.withOpacity(0.85);
    if (r.contains('out')) return Colors.red.withOpacity(0.9);
    return textPrimary;
  }
}

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