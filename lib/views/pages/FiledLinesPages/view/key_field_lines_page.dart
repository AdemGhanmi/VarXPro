import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/views/pages/FiledLinesPages/model/perspective_model.dart';
import 'package:VarXPro/views/setting/provider/history_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/views/pages/FiledLinesPages/controller/perspective_controller.dart';
import 'package:VarXPro/views/pages/FiledLinesPages/service/perspective_service.dart';
//import 'package:VarXPro/views/pages/FiledLinesPages/widgets/CalibrationForm.dart';
//import 'package:VarXPro/views/pages/FiledLinesPages/widgets/LoadCalibrationForm.dart';
//import 'package:VarXPro/views/pages/FiledLinesPages/widgets/TransformPointForm.dart';
//import 'package:VarXPro/views/pages/FiledLinesPages/widgets/VideoPlayerWidget.dart';
//import 'package:VarXPro/views/pages/FiledLinesPages/widgets/VideoTransformForm.dart';
import 'package:VarXPro/views/pages/FiledLinesPages/widgets/image_picker_widget.dart';
//import 'package:url_launcher/url_launcher.dart';

class KeyFieldLinesPage extends StatefulWidget {
  const KeyFieldLinesPage({super.key});

  @override
  _KeyFieldLinesPageState createState() => _KeyFieldLinesPageState();
}

class _KeyFieldLinesPageState extends State<KeyFieldLinesPage> with TickerProviderStateMixin {
  bool _showSplash = true;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  bool _hasShownCleanSnackBar = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowAnimation = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final modeProvider = Provider.of<ModeProvider>(context);
    final currentLang = langProvider.currentLanguage;
    final seedColor = AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!;
    final screenWidth = MediaQuery.of(context).size.width;

    if (_showSplash) {
      return Scaffold(
        backgroundColor: AppColors.getBackgroundColor(modeProvider.currentMode),
        body: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _FootballGridPainter(modeProvider.currentMode),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.getBodyGradient(modeProvider.currentMode),
                  ),
                ),
              ),
            ),
            Center(
              child: Lottie.asset(
                'assets/lotties/terrain.json',
                width: screenWidth * 0.8,
                height: MediaQuery.of(context).size.height * 0.5,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      );
    }

    return BlocProvider(
      create: (context) => PerspectiveBloc(PerspectiveService())..add(CheckHealthEvent()),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _FootballGridPainter(modeProvider.currentMode),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.getBodyGradient(modeProvider.currentMode),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: BlocConsumer<PerspectiveBloc, PerspectiveState>(
                listener: (context, state) {
                  if (state.error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${Translations.getPlayerTrackingText('error', currentLang)}: ${state.error}',
                          style: GoogleFonts.roboto(
                            color: AppColors.getTextColor(modeProvider.currentMode),
                            fontSize: 14,
                          ),
                        ),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                  if (state.cleanResponse?.ok == true && !_hasShownCleanSnackBar) {
                    setState(() {
                      _hasShownCleanSnackBar = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          Translations.getPlayerTrackingText('artifactsCleaned', currentLang),
                          style: GoogleFonts.roboto(
                            color: AppColors.getTextColor(modeProvider.currentMode),
                            fontSize: 14,
                          ),
                        ),
                        backgroundColor: AppColors.getTertiaryColor(seedColor, modeProvider.currentMode),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onVisible: () {
                          Future.delayed(const Duration(milliseconds: 1000), () {
                            if (context.mounted) {
                              context.read<PerspectiveBloc>().add(ResetCleanResponseEvent());
                            }
                          });
                        },
                      ),
                    );
                  }
                  // Log to history on successful analysis (e.g., calibration, transform, etc.)
                  if (state.calibrationResponse?.ok == true ||
                      state.loadCalibrationResponse?.ok == true ||
                      state.detectLinesResponse?.ok == true ||
                      state.transformFrameResponse?.ok == true ||
                      state.transformVideoResponse?.ok == true ||
                      state.transformPointResponse?.ok == true) {
                    final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
                    historyProvider.addHistoryItem('Field Lines', 'Field lines analysis completed');
                  }
                },
                builder: (context, state) {
                  final bool calibrated = state.health?.calibrated ?? false;
                  return RefreshIndicator(
                    onRefresh: () async => context.read<PerspectiveBloc>().add(CheckHealthEvent()),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // API Status Section
                        
                          SizedBox(height: screenWidth * 0.05),

                          // /* COMMENTED: Load Calibration Section */
                          /*
                          _buildSectionCard(
                            emoji: '📥',
                            title: Translations.getOffsideText('loadCalibration', currentLang),
                            mode: modeProvider.currentMode,
                            seedColor: seedColor,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LoadCalibrationForm(mode: modeProvider.currentMode, seedColor: seedColor, currentLang: currentLang),
                                ImagePickerWidget(
                                  onImagePicked: (File file) => context.read<PerspectiveBloc>().add(LoadCalibrationByFileEvent(file)),
                                  buttonText: Translations.getOffsideText('selectCalibrationFile', currentLang),
                                  isCalibration: true,
                                  mode: modeProvider.currentMode,
                                  seedColor: seedColor,
                                ),
                                if (state.loadCalibrationResponse != null) _buildLoadCalibrationResult(state.loadCalibrationResponse!, modeProvider.currentMode, seedColor, currentLang),
                              ],
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.05),
                          */

                          // Detect Field Lines Section (KEPT AS IS)
                          _buildSectionCard(
                            emoji: '🔍',
                            title: Translations.getOffsideText('detectFieldLines', currentLang),
                            mode: modeProvider.currentMode,
                            seedColor: seedColor,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ImagePickerWidget(
                                  onImagePicked: (File image) => context.read<PerspectiveBloc>().add(DetectLinesEvent(image)),
                                  buttonText: Translations.getOffsideText('selectImageForDetection', currentLang),
                                  mode: modeProvider.currentMode,
                                  seedColor: seedColor,
                                ),
                                if (state.detectLinesResponse != null) _buildDetectLinesResult(state.detectLinesResponse!, modeProvider.currentMode, seedColor, currentLang, screenWidth),
                              ],
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.05),

                          // /* COMMENTED: Set Calibration Section */
                          /*
                          _buildSectionCard(
                            emoji: '⚙️',
                            title: Translations.getOffsideText('setCalibration', currentLang),
                            mode: modeProvider.currentMode,
                            seedColor: seedColor,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CalibrationForm(mode: modeProvider.currentMode, seedColor: seedColor, currentLang: currentLang),
                                if (state.calibrationResponse != null) _buildCalibrationResult(state.calibrationResponse!, modeProvider.currentMode, seedColor, currentLang),
                              ],
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.05),
                          */

                          // /* COMMENTED: Transform Image Section */
                          /*
                          _buildSectionCard(
                            emoji: '🖼️',
                            title: Translations.getOffsideText('transformImage', currentLang),
                            mode: modeProvider.currentMode,
                            seedColor: seedColor,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ImagePickerWidget(
                                  enabled: calibrated,
                                  onImagePicked: (File image) => context.read<PerspectiveBloc>().add(TransformFrameEvent(image)),
                                  buttonText: Translations.getOffsideText('selectImageToTransform', currentLang),
                                  mode: modeProvider.currentMode,
                                  seedColor: seedColor,
                                ),
                                if (!calibrated)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      Translations.getOffsideText('pleaseCalibrateFirst', currentLang),
                                      style: const TextStyle(color: Colors.redAccent),
                                    ),
                                  ),
                                if (state.transformFrameResponse != null) _buildTransformFrameResult(state.transformFrameResponse!, modeProvider.currentMode, seedColor, currentLang, screenWidth),
                              ],
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.05),
                          */

                          // /* COMMENTED: Transform Video Section */
                          /*
                          _buildSectionCard(
                            emoji: '🎥',
                            title: Translations.getOffsideText('transformVideo', currentLang),
                            mode: modeProvider.currentMode,
                            seedColor: seedColor,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                VideoTransformForm(mode: modeProvider.currentMode, seedColor: seedColor, currentLang: currentLang),
                                if (state.isLoading && state.uploadProgress != null)
                                  LinearProgressIndicator(
                                    value: state.uploadProgress,
                                    backgroundColor: AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.3),
                                    valueColor: AlwaysStoppedAnimation(AppColors.getTertiaryColor(seedColor, modeProvider.currentMode)),
                                  ),
                                if (state.transformVideoResponse != null) _buildTransformVideoResult(state.transformVideoResponse!, modeProvider.currentMode, seedColor, currentLang, screenWidth),
                              ],
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.05),
                          */

                          // /* COMMENTED: Transform Points Section */
                          /*
                          _buildSectionCard(
                            emoji: '📍',
                            title: Translations.getOffsideText('transformPoints', currentLang),
                            mode: modeProvider.currentMode,
                            seedColor: seedColor,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TransformPointForm(mode: modeProvider.currentMode, seedColor: seedColor, currentLang: currentLang),
                                if (state.transformPointResponse != null) _buildTransformPointResult(state.transformPointResponse!, modeProvider.currentMode, seedColor, currentLang),
                                if (state.inversePointResponse != null) _buildInverseTransformPointResult(state.inversePointResponse!, modeProvider.currentMode, seedColor, currentLang),
                              ],
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.05),
                          */

                          // /* COMMENTED: Clean Artifacts Section */
                          /*
                          _buildSectionCard(
                            emoji: '🧹',
                            title: Translations.getPlayerTrackingText('cleanArtifacts', currentLang),
                            mode: modeProvider.currentMode,
                            seedColor: seedColor,
                            child: ElevatedButton.icon(
                              onPressed: () => context.read<PerspectiveBloc>().add(CleanEvent()),
                              icon: Text(
                                '🧹',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.getTextColor(modeProvider.currentMode),
                                ),
                              ),
                              label: Text(
                                Translations.getPlayerTrackingText('cleanArtifacts', currentLang),
                                style: GoogleFonts.roboto(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.getTextColor(modeProvider.currentMode),
                                  fontSize: 14,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: AppColors.getTextColor(modeProvider.currentMode),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.1),
                          */

                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String emoji,
    required String title,
    required int mode,
    required Color seedColor,
    required Widget child,
  }) {
    return Card(
      color: AppColors.getSurfaceColor(mode).withOpacity(0.95),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.getSurfaceColor(mode).withOpacity(0.98),
              AppColors.getSurfaceColor(mode).withOpacity(0.92),
            ],
          ),
          border: Border.all(
            color: AppColors.getPrimaryColor(seedColor, mode).withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      emoji,
                      style: TextStyle(
                        fontSize: 24,
                        color: AppColors.getTertiaryColor(seedColor, mode),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextColor(mode),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(PerspectiveState state, int mode, Color seedColor, String currentLang) {
    return Card(
      color: AppColors.getSurfaceColor(mode).withOpacity(0.9),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: state.health?.status == 'ok' ? AppColors.getTertiaryColor(seedColor, mode) : Colors.redAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: state.health?.status == 'ok' ? AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.4) : Colors.redAccent.withOpacity(0.4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  state.health?.status == 'ok'
                      ? Translations.getPlayerTrackingText('connected', currentLang)
                      : Translations.getPlayerTrackingText('disconnected', currentLang),
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    color: state.health?.status == 'ok' ? AppColors.getTertiaryColor(seedColor, mode) : Colors.redAccent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            if (state.health != null) ...[
              const SizedBox(height: 12),
              _buildStatusItem(Translations.getPlayerTrackingText('status', currentLang), state.health!.status, mode, seedColor),
              _buildStatusItem('Calibrated', state.health!.calibrated.toString(), mode, seedColor),
              if (state.health!.dstSize != null)
                _buildStatusItem('Output Size', '${state.health!.dstSize!['width']}x${state.health!.dstSize!['height']}', mode, seedColor),
            ],
          ],
        ),
      ),
    );
  }

  // /* COMMENTED: _buildLoadCalibrationResult method */
  /*
  Widget _buildLoadCalibrationResult(LoadCalibrationResponse response, int mode, Color seedColor, String currentLang) {
    return Card(
      color: AppColors.getSurfaceColor(mode).withOpacity(0.9),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultItem(Translations.getOffsideText('calibrationLoaded', currentLang), response.ok.toString(), response.ok, mode, seedColor),
            if (response.calibrationFile != null)
              _buildResultItem(Translations.getOffsideText('calibrationFile', currentLang), response.calibrationFile!, false, mode, seedColor),
            if (response.dstSize != null)
              _buildResultItem(Translations.getOffsideText('dstSize', currentLang), '${response.dstSize!['width']}x${response.dstSize!['height']}', false, mode, seedColor),
          ],
        ),
      ),
    );
  }
  */

  Widget _buildDetectLinesResult(DetectLinesResponse response, int mode, Color seedColor, String currentLang, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: AppColors.getSurfaceColor(mode).withOpacity(0.95),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildResultItem(Translations.getOffsideText('success', currentLang), response.ok.toString(), response.ok, mode, seedColor),
                _buildResultItem(Translations.getOffsideText('detectedLines', currentLang), '${response.lines?.length ?? 0} lines found', response.lines?.isNotEmpty ?? false, mode, seedColor),
              ],
            ),
          ),
        ),
        if (response.annotatedUrl != null) ...[
          SizedBox(height: screenWidth * 0.04),
          Text(
            Translations.getOffsideText('annotatedImage', currentLang),
            style: GoogleFonts.roboto(fontWeight: FontWeight.bold, color: AppColors.getTextColor(mode), fontSize: 18, letterSpacing: 0.5),
          ),
          SizedBox(height: screenWidth * 0.03),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FullScreenImagePage(
                    imageUrl: '${PerspectiveService.defaultBaseUrl}${response.annotatedUrl}',
                    mode: mode,
                    seedColor: seedColor,
                  ),
                ),
              );
            },
            child: Container(
              constraints: BoxConstraints(maxHeight: screenWidth * 0.5, maxWidth: screenWidth * 0.95),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.3), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: '${PerspectiveService.defaultBaseUrl}${response.annotatedUrl}',
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Container(
                    height: screenWidth * 0.4,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(AppColors.getTertiaryColor(seedColor, mode)),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: screenWidth * 0.2,
                    child: Center(
                      child: Text(
                        Translations.getOffsideText('failedToLoadImage', currentLang),
                        style: GoogleFonts.roboto(color: AppColors.getTextColor(mode), fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // /* COMMENTED: _buildCalibrationResult method */
  /*
  Widget _buildCalibrationResult(CalibrationResponse response, int mode, Color seedColor, String currentLang) {
    return Card(
      color: AppColors.getSurfaceColor(mode).withOpacity(0.9),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultItem(Translations.getOffsideText('calibrationSet', currentLang), response.ok.toString(), response.ok, mode, seedColor),
            if (response.dstSize != null)
              _buildResultItem(Translations.getOffsideText('dstSize', currentLang), '${response.dstSize!['width']}x${response.dstSize!['height']}', false, mode, seedColor),
            if (response.saved == true) _buildResultItem(Translations.getOffsideText('saved', currentLang), response.saved.toString(), response.saved!, mode, seedColor),
            if (response.calibrationUrl != null) _buildResultItem(Translations.getOffsideText('calibrationUrl', currentLang), response.calibrationUrl!, false, mode, seedColor),
          ],
        ),
      ),
    );
  }
  */

  // /* COMMENTED: _buildTransformFrameResult method */
  /*
  Widget _buildTransformFrameResult(TransformFrameResponse response, int mode, Color seedColor, String currentLang, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: AppColors.getSurfaceColor(mode).withOpacity(0.9),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildResultItem(Translations.getOffsideText('success', currentLang), response.ok.toString(), response.ok, mode, seedColor),
                if (response.originalUrl != null) _buildResultItem(Translations.getOffsideText('originalUrl', currentLang), response.originalUrl!, false, mode, seedColor),
                if (response.birdsEyeUrl != null) _buildResultItem(Translations.getOffsideText('birdsEyeUrl', currentLang), response.birdsEyeUrl!, false, mode, seedColor),
              ],
            ),
          ),
        ),
        if (response.birdsEyeUrl != null) ...[
          SizedBox(height: screenWidth * 0.03),
          Text(
            Translations.getOffsideText('transformedImage', currentLang),
            style: GoogleFonts.roboto(fontWeight: FontWeight.bold, color: AppColors.getTextColor(mode), fontSize: 16),
          ),
          SizedBox(height: screenWidth * 0.02),
          Container(
            constraints: BoxConstraints(maxHeight: screenWidth * 0.5, maxWidth: screenWidth * 0.9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.3), width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: '${PerspectiveService.defaultBaseUrl}${response.birdsEyeUrl}',
                fit: BoxFit.contain,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(AppColors.getTertiaryColor(seedColor, mode)),
                  ),
                ),
                errorWidget: (context, url, error) => Text(
                  Translations.getOffsideText('failedToLoadImage', currentLang),
                  style: GoogleFonts.roboto(color: AppColors.getTextColor(mode), fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
  */

  // /* COMMENTED: _buildTransformVideoResult method */
  /*
  Widget _buildTransformVideoResult(TransformVideoResponse response, int mode, Color seedColor, String currentLang, double screenWidth) {
    final String fullOutputUrl = '${PerspectiveService.defaultBaseUrl}${response.outputUrl}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: AppColors.getSurfaceColor(mode).withOpacity(0.9),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildResultItem(Translations.getOffsideText('success', currentLang), response.ok.toString(), response.ok, mode, seedColor),
                if (response.inputUrl != null) _buildResultItem(Translations.getOffsideText('inputUrl', currentLang), response.inputUrl!, false, mode, seedColor),
                if (response.outputUrl != null)
                  _buildClickableResultItem(
                    label: Translations.getOffsideText('outputUrl', currentLang),
                    value: response.outputUrl!,
                    url: fullOutputUrl,
                    mode: mode,
                    seedColor: seedColor,
                  ),
                if (response.frames != null) _buildResultItem(Translations.getOffsideText('processedFrames', currentLang), response.frames.toString(), false, mode, seedColor),
                if (response.dstSize != null)
                  _buildResultItem(Translations.getOffsideText('dstSize', currentLang), '${response.dstSize!['width']}x${response.dstSize!['height']}', false, mode, seedColor),
              ],
            ),
          ),
        ),
        if (response.outputUrl != null) ...[
          SizedBox(height: screenWidth * 0.03),
          Text(
            Translations.getOffsideText('transformedVideo', currentLang),
            style: GoogleFonts.roboto(fontWeight: FontWeight.bold, color: AppColors.getTextColor(mode), fontSize: 16),
          ),
          SizedBox(height: screenWidth * 0.02),
          VideoPlayerWidget(videoUrl: fullOutputUrl, mode: mode, seedColor: seedColor),
        ],
      ],
    );
  }
  */

  // /* COMMENTED: _buildTransformPointResult method */
  /*
  Widget _buildTransformPointResult(TransformPointResponse response, int mode, Color seedColor, String currentLang) {
    return Card(
      color: AppColors.getSurfaceColor(mode).withOpacity(0.9),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultItem(Translations.getOffsideText('success', currentLang), response.ok.toString(), response.ok, mode, seedColor),
            if (response.input != null) _buildResultItem(Translations.getOffsideText('input', currentLang), response.input.toString(), false, mode, seedColor),
            if (response.output != null) _buildResultItem(Translations.getOffsideText('output', currentLang), response.output.toString(), false, mode, seedColor),
            if (response.error != null) _buildResultItem(Translations.getOffsideText('error', currentLang), response.error!, true, mode, seedColor),
          ],
        ),
      ),
    );
  }
  */

  // /* COMMENTED: _buildInverseTransformPointResult method */
  /*
  Widget _buildInverseTransformPointResult(TransformPointResponse response, int mode, Color seedColor, String currentLang) {
    return Card(
      color: AppColors.getSurfaceColor(mode).withOpacity(0.9),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultItem(Translations.getOffsideText('successInverse', currentLang), response.ok.toString(), response.ok, mode, seedColor),
            if (response.input != null) _buildResultItem(Translations.getOffsideText('inputInverse', currentLang), response.input.toString(), false, mode, seedColor),
            if (response.output != null) _buildResultItem(Translations.getOffsideText('outputInverse', currentLang), response.output.toString(), false, mode, seedColor),
            if (response.error != null) _buildResultItem(Translations.getOffsideText('errorInverse', currentLang), response.error!, true, mode, seedColor),
          ],
        ),
      ),
    );
  }
  */

  Widget _buildStatusItem(String label, String value, int mode, Color seedColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.getSurfaceColor(mode).withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text('$label: ', style: GoogleFonts.roboto(color: AppColors.getTextColor(mode).withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                style: GoogleFonts.roboto(color: AppColors.getTextColor(mode), fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(String label, String value, bool isSuccess, int mode, Color seedColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSuccess ? AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSuccess ? AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.3) : Colors.redAccent.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text('$label: ', style: GoogleFonts.roboto(color: AppColors.getTextColor(mode).withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                style: GoogleFonts.roboto(
                  color: isSuccess ? AppColors.getTertiaryColor(seedColor, mode) : Colors.redAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // /* COMMENTED: _buildClickableResultItem method */
  /*
  Widget _buildClickableResultItem({
    required String label,
    required String value,
    required String url,
    required int mode,
    required Color seedColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('$label: ', style: GoogleFonts.roboto(color: AppColors.getTextColor(mode).withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w600)),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final Uri uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(
                value,
                style: GoogleFonts.roboto(
                  color: AppColors.getTertiaryColor(seedColor, mode),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  */
}

class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;
  final int mode;
  final Color seedColor;

  const FullScreenImagePage({
    super.key,
    required this.imageUrl,
    required this.mode,
    required this.seedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.error, color: Colors.white, size: 50),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FootballGridPainter extends CustomPainter {
  final int mode;

  _FootballGridPainter(this.mode);

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42); // Seeded for consistency
    final gridPaint = Paint()
      ..color = AppColors.getTextColor(mode).withOpacity(0.03)
      ..strokeWidth = 0.5;

    const step = 50.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Add subtle particles for improved dynamic feel
    final particlePaint = Paint()
      ..color = AppColors.getTextColor(mode).withOpacity(0.08);
    for (int i = 0; i < 25; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 2 + 1;
      canvas.drawCircle(Offset(x, y), radius, particlePaint);
    }

    final fieldPaint = Paint()
      ..color = AppColors.getTextColor(mode).withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final inset = 40.0;
    final rect = Rect.fromLTWH(inset, inset * 2, size.width - inset * 2, size.height - inset * 4);
    canvas.drawRect(rect, fieldPaint);

    final midY = rect.top + rect.height / 2;
    canvas.drawLine(Offset(rect.left, midY), Offset(rect.right, midY), fieldPaint);
    canvas.drawCircle(Offset(rect.center.dx, midY), 30, fieldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}