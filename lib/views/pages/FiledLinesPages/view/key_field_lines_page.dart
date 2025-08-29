import 'dart:io';
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/views/pages/FiledLinesPages/widgets/CalibrationForm.dart';
import 'package:VarXPro/views/pages/FiledLinesPages/widgets/LoadCalibrationForm.dart';
import 'package:VarXPro/views/pages/FiledLinesPages/widgets/TransformPointForm.dart';
import 'package:VarXPro/views/pages/FiledLinesPages/widgets/VideoPlayerWidget.dart';
import 'package:VarXPro/views/pages/FiledLinesPages/widgets/VideoTransformForm.dart';
import 'package:VarXPro/views/pages/FiledLinesPages/controller/perspective_controller.dart';
import 'package:VarXPro/views/pages/FiledLinesPages/service/perspective_service.dart';
import 'package:VarXPro/views/pages/FiledLinesPages/widgets/image_picker_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart'; 
import 'dart:async'; 

class KeyFieldLinesPage extends StatefulWidget {
  const KeyFieldLinesPage({super.key});

  @override
  _KeyFieldLinesPageState createState() => _KeyFieldLinesPageState();
}

class _KeyFieldLinesPageState extends State<KeyFieldLinesPage> {
  bool _hasShownCleanSnackBar = false;
  bool _showSplash = true; // State to control splash screen visibility

  @override
  void initState() {
    super.initState();
    // Start a timer to hide the splash screen after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final modeProvider = Provider.of<ModeProvider>(context);
    final currentLang = langProvider.currentLanguage;
    final seedColor = AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!;

    // Show Lottie animation if splash screen is active
    if (_showSplash) {
      return Scaffold(
        backgroundColor: AppColors.getBackgroundColor(modeProvider.currentMode),
        body: Center(
          child: Lottie.asset(
            'assets/lotties/terrain.json',
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.5,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    // Main content after splash screen
    return BlocProvider(
      create: (context) => PerspectiveBloc(PerspectiveService())..add(CheckHealthEvent()),
      child: Scaffold(
        backgroundColor: AppColors.getBackgroundColor(modeProvider.currentMode),
        body: Container(
          decoration: BoxDecoration(
            gradient: AppColors.getBodyGradient(modeProvider.currentMode),
          ),
          child: BlocConsumer<PerspectiveBloc, PerspectiveState>(
            listener: (context, state) {
              if (state.error != null) {
                print('Error in listener: ${state.error}');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${Translations.getPlayerTrackingText('error', currentLang)}: ${state.error}',
                      style: TextStyle(
                        color: AppColors.getTextColor(modeProvider.currentMode),
                      ),
                    ),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
              if (state.cleanResponse?.ok == true && !_hasShownCleanSnackBar) {
                print('Clean response received: ${state.cleanResponse}');
                setState(() {
                  _hasShownCleanSnackBar = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      Translations.getPlayerTrackingText('artifactsCleaned', currentLang),
                      style: TextStyle(
                        color: AppColors.getTextColor(modeProvider.currentMode),
                      ),
                    ),
                    backgroundColor: AppColors.getTertiaryColor(seedColor, modeProvider.currentMode),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 3),
                    onVisible: () {
                      Future.delayed(const Duration(milliseconds: 1000), () {
                        if (context.mounted) {
                          print('Dispatching ResetCleanResponseEvent');
                          context.read<PerspectiveBloc>().add(ResetCleanResponseEvent());
                        }
                      });
                    },
                  ),
                );
              }
            },
            builder: (context, state) {
              print('Builder called with state: isLoading=${state.isLoading}, health=${state.health}');
              final bool calibrated = state.health?.calibrated ?? false;
              if (state.isLoading) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(
                      AppColors.getTertiaryColor(seedColor, modeProvider.currentMode),
                    ),
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      print('Manual refresh triggered');
                      context.read<PerspectiveBloc>().add(CheckHealthEvent());
                    },
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(constraints.maxWidth * 0.04),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // API Status Section
                          Card(
                            color: AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.8),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    Translations.getPlayerTrackingText('apiStatus', currentLang),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.getTextColor(modeProvider.currentMode),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: state.health != null && state.health!.status == 'ok'
                                              ? AppColors.getTertiaryColor(seedColor, modeProvider.currentMode)
                                              : Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        state.health != null && state.health!.status == 'ok'
                                            ? Translations.getPlayerTrackingText('connected', currentLang)
                                            : Translations.getPlayerTrackingText('disconnected', currentLang),
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: state.health != null && state.health!.status == 'ok'
                                              ? AppColors.getTertiaryColor(seedColor, modeProvider.currentMode)
                                              : Colors.redAccent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (state.health != null) ...[
                                    _buildStatusItem(
                                      Translations.getPlayerTrackingText('status', currentLang),
                                      state.health!.status ?? Translations.getPlayerTrackingText('unknown', currentLang),
                                      modeProvider.currentMode,
                                      seedColor,
                                    ),
                                    _buildStatusItem(
                                      'Calibrated',
                                      state.health!.calibrated.toString(),
                                      modeProvider.currentMode,
                                      seedColor,
                                    ),
                                    if (state.health!.dstSize != null)
                                      _buildStatusItem(
                                        'Output Size',
                                        '${state.health!.dstSize!['width']}x${state.health!.dstSize!['height']}',
                                        modeProvider.currentMode,
                                        seedColor,
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: constraints.maxWidth * 0.05),

                          // Load Calibration by Name
                          _buildSectionHeader(
                            Translations.getOffsideText('loadCalibrationByName', currentLang),
                            modeProvider.currentMode,
                            seedColor,
                          ),
                          SizedBox(height: constraints.maxWidth * 0.03),
                          LoadCalibrationForm(
                            mode: modeProvider.currentMode,
                            seedColor: seedColor,
                            currentLang: currentLang,
                          ),
                          SizedBox(height: constraints.maxWidth * 0.03),
                          _buildSectionHeader(
                            Translations.getOffsideText('loadCalibrationByFile', currentLang),
                            modeProvider.currentMode,
                            seedColor,
                          ),
                          SizedBox(height: constraints.maxWidth * 0.03),
                          ImagePickerWidget(
                            onImagePicked: (File file) {
                              context.read<PerspectiveBloc>().add(LoadCalibrationByFileEvent(file));
                            },
                            buttonText: Translations.getOffsideText('selectCalibrationFile', currentLang),
                            isCalibration: true,
                            mode: modeProvider.currentMode,
                            seedColor: seedColor,
                          ),
                          if (state.loadCalibrationResponse != null && state.loadCalibrationResponse!.ok) ...[
                            SizedBox(height: constraints.maxWidth * 0.03),
                            Card(
                              color: AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.8),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildResultItem(
                                      Translations.getOffsideText('calibrationLoaded', currentLang),
                                      state.loadCalibrationResponse!.ok.toString(),
                                      state.loadCalibrationResponse!.ok,
                                      modeProvider.currentMode,
                                      seedColor,
                                    ),
                                    if (state.loadCalibrationResponse!.calibrationFile != null)
                                      _buildResultItem(
                                        Translations.getOffsideText('calibrationFile', currentLang),
                                        state.loadCalibrationResponse!.calibrationFile!,
                                        false,
                                        modeProvider.currentMode,
                                        seedColor,
                                      ),
                                    if (state.loadCalibrationResponse!.dstSize != null)
                                      _buildResultItem(
                                        Translations.getOffsideText('dstSize', currentLang),
                                        '${state.loadCalibrationResponse!.dstSize!['width']}x${state.loadCalibrationResponse!.dstSize!['height']}',
                                        false,
                                        modeProvider.currentMode,
                                        seedColor,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          SizedBox(height: constraints.maxWidth * 0.05),

                          // Detect Field Lines
                          _buildSectionHeader(
                            Translations.getOffsideText('detectFieldLines', currentLang),
                            modeProvider.currentMode,
                            seedColor,
                          ),
                          SizedBox(height: constraints.maxWidth * 0.03),
                          ImagePickerWidget(
                            onImagePicked: (File image) {
                              context.read<PerspectiveBloc>().add(DetectLinesEvent(image));
                            },
                            buttonText: Translations.getOffsideText('selectImageForDetection', currentLang),
                            mode: modeProvider.currentMode,
                            seedColor: seedColor,
                          ),
                          if (state.detectLinesResponse != null && state.detectLinesResponse!.ok) ...[
                            SizedBox(height: constraints.maxWidth * 0.05),
                            Card(
                              color: AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.8),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildResultItem(
                                      Translations.getOffsideText('success', currentLang),
                                      state.detectLinesResponse!.ok.toString(),
                                      state.detectLinesResponse!.ok,
                                      modeProvider.currentMode,
                                      seedColor,
                                    ),
                                    _buildResultItem(
                                      Translations.getOffsideText('detectedLines', currentLang),
                                      '${state.detectLinesResponse!.lines?.length ?? 0} lines found',
                                      state.detectLinesResponse!.lines != null && state.detectLinesResponse!.lines!.isNotEmpty,
                                      modeProvider.currentMode,
                                      seedColor,
                                    ),
                                    if (state.detectLinesResponse!.uploadUrl != null)
                                      _buildResultItem(
                                        Translations.getOffsideText('uploadedImageUrl', currentLang),
                                        state.detectLinesResponse!.uploadUrl!,
                                        false,
                                        modeProvider.currentMode,
                                        seedColor,
                                      ),
                                    if (state.detectLinesResponse!.annotatedUrl != null)
                                      _buildResultItem(
                                        Translations.getOffsideText('annotatedImageUrl', currentLang),
                                        state.detectLinesResponse!.annotatedUrl!,
                                        false,
                                        modeProvider.currentMode,
                                        seedColor,
                                      ),
                                    if (state.detectLinesResponse!.lines != null) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        Translations.getOffsideText('linesCoordinates', currentLang),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.getTextColor(modeProvider.currentMode),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...state.detectLinesResponse!.lines!.map((line) => Text(
                                            line.toString(),
                                            style: TextStyle(
                                              color: AppColors.getTextColor(modeProvider.currentMode).withOpacity(0.7),
                                            ),
                                          )),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            if (state.detectLinesResponse!.annotatedUrl != null) ...[
                              SizedBox(height: constraints.maxWidth * 0.03),
                              Text(
                                Translations.getOffsideText('annotatedImage', currentLang),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.getTextColor(modeProvider.currentMode),
                                ),
                              ),
                              SizedBox(height: constraints.maxWidth * 0.02),
                              Container(
                                constraints: BoxConstraints(
                                  maxHeight: constraints.maxWidth * 0.5,
                                  maxWidth: constraints.maxWidth * 0.9,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.getTertiaryColor(seedColor, modeProvider.currentMode).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: '${PerspectiveService.baseUrl}${state.detectLinesResponse!.annotatedUrl}',
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation(
                                          AppColors.getTertiaryColor(seedColor, modeProvider.currentMode),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: AppColors.getSurfaceColor(modeProvider.currentMode),
                                      child: const Center(
                                        child: Icon(
                                          Icons.error_outline,
                                          color: Colors.redAccent,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],

                          // Set Calibration
                          SizedBox(height: constraints.maxWidth * 0.05),
                          _buildSectionHeader(
                            Translations.getOffsideText('setCalibration', currentLang),
                            modeProvider.currentMode,
                            seedColor,
                          ),
                          SizedBox(height: constraints.maxWidth * 0.03),
                          CalibrationForm(
                            mode: modeProvider.currentMode,
                            seedColor: seedColor,
                            currentLang: currentLang,
                          ),
                          if (state.calibrationResponse != null && state.calibrationResponse!.ok) ...[
                            SizedBox(height: constraints.maxWidth * 0.03),
                            Card(
                              color: AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.8),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildResultItem(
                                      Translations.getOffsideText('calibrationSet', currentLang),
                                      state.calibrationResponse!.ok.toString(),
                                      state.calibrationResponse!.ok,
                                      modeProvider.currentMode,
                                      seedColor,
                                    ),
                                    if (state.calibrationResponse!.dstSize != null)
                                      _buildResultItem(
                                        Translations.getOffsideText('dstSize', currentLang),
                                        '${state.calibrationResponse!.dstSize!['width']}x${state.calibrationResponse!.dstSize!['height']}',
                                        false,
                                        modeProvider.currentMode,
                                        seedColor,
                                      ),
                                    if (state.calibrationResponse!.saved == true)
                                      _buildResultItem(
                                        Translations.getOffsideText('saved', currentLang),
                                        state.calibrationResponse!.saved.toString(),
                                        state.calibrationResponse!.saved!,
                                        modeProvider.currentMode,
                                        seedColor,
                                      ),
                                    if (state.calibrationResponse!.calibrationUrl != null)
                                      _buildResultItem(
                                        Translations.getOffsideText('calibrationUrl', currentLang),
                                        state.calibrationResponse!.calibrationUrl!,
                                        false,
                                        modeProvider.currentMode,
                                        seedColor,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          // Transform Image
                          SizedBox(height: constraints.maxWidth * 0.05),
                          _buildSectionHeader(
                            Translations.getOffsideText('transformImage', currentLang),
                            modeProvider.currentMode,
                            seedColor,
                          ),
                          SizedBox(height: constraints.maxWidth * 0.03),
                          ImagePickerWidget(
                            onImagePicked: (File image) {
                              if (calibrated) {
                                context.read<PerspectiveBloc>().add(TransformFrameEvent(image));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      Translations.getOffsideText('pleaseCalibrateFirst', currentLang),
                                      style: TextStyle(
                                        color: AppColors.getTextColor(modeProvider.currentMode),
                                      ),
                                    ),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            },
                            buttonText: Translations.getOffsideText('selectImageToTransform', currentLang),
                            mode: modeProvider.currentMode,
                            seedColor: seedColor,
                          ),
                          if (state.transformFrameResponse != null &&
                              state.transformFrameResponse!.birdsEyeUrl != null &&
                              state.transformFrameResponse!.ok) ...[
                            SizedBox(height: constraints.maxWidth * 0.03),
                            Card(
                              color: AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.8),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildResultItem(
                                      Translations.getOffsideText('success', currentLang),
                                      state.transformFrameResponse!.ok.toString(),
                                      state.transformFrameResponse!.ok,
                                      modeProvider.currentMode,
                                      seedColor,
                                    ),
                                    if (state.transformFrameResponse!.originalUrl != null)
                                      _buildResultItem(
                                        Translations.getOffsideText('originalUrl', currentLang),
                                        state.transformFrameResponse!.originalUrl!,
                                        false,
                                        modeProvider.currentMode,
                                        seedColor,
                                      ),
                                    if (state.transformFrameResponse!.birdsEyeUrl != null)
                                      _buildResultItem(
                                        Translations.getOffsideText('birdsEyeUrl', currentLang),
                                        state.transformFrameResponse!.birdsEyeUrl!,
                                        false,
                                        modeProvider.currentMode,
                                        seedColor,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: constraints.maxWidth * 0.03),
                            Text(
                              Translations.getOffsideText('transformedImage', currentLang),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.getTextColor(modeProvider.currentMode),
                              ),
                            ),
                            SizedBox(height: constraints.maxWidth * 0.02),
                            Container(
                              constraints: BoxConstraints(
                                maxHeight: constraints.maxWidth * 0.5,
                                maxWidth: constraints.maxWidth * 0.9,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.getTertiaryColor(seedColor, modeProvider.currentMode).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: '${PerspectiveService.baseUrl}${state.transformFrameResponse!.birdsEyeUrl}',
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation(
                                        AppColors.getTertiaryColor(seedColor, modeProvider.currentMode),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: AppColors.getSurfaceColor(modeProvider.currentMode),
                                    child: const Center(
                                      child: Icon(
                                        Icons.error_outline,
                                        color: Colors.redAccent,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],

                          // Transform Video
                          SizedBox(height: constraints.maxWidth * 0.05),
                          _buildSectionHeader(
                            Translations.getOffsideText('transformVideo', currentLang),
                            modeProvider.currentMode,
                            seedColor,
                          ),
                          SizedBox(height: constraints.maxWidth * 0.03),
                          VideoTransformForm(
                            mode: modeProvider.currentMode,
                            seedColor: seedColor,
                            currentLang: currentLang,
                          ),
                          if (state.transformVideoResponse != null && state.transformVideoResponse!.ok) ...[
                            SizedBox(height: constraints.maxWidth * 0.03),
                            Card(
                              color: AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.8),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildResultItem(
                                      Translations.getOffsideText('success', currentLang),
                                      state.transformVideoResponse!.ok.toString(),
                                      state.transformVideoResponse!.ok,
                                      modeProvider.currentMode,
                                      seedColor,
                                    ),
                                    if (state.transformVideoResponse!.inputUrl != null)
                                      _buildResultItem(
                                        Translations.getOffsideText('inputUrl', currentLang),
                                        state.transformVideoResponse!.inputUrl!,
                                        false,
                                        modeProvider.currentMode,
                                        seedColor,
                                      ),
                                    if (state.transformVideoResponse!.outputUrl != null)
                                      _buildResultItem(
                                        Translations.getOffsideText('outputUrl', currentLang),
                                        state.transformVideoResponse!.outputUrl!,
                                        false,
                                        modeProvider.currentMode,
                                        seedColor,
                                      ),
                                    if (state.transformVideoResponse!.frames != null)
                                      _buildResultItem(
                                        Translations.getOffsideText('processedFrames', currentLang),
                                        state.transformVideoResponse!.frames.toString(),
                                        false,
                                        modeProvider.currentMode,
                                        seedColor,
                                      ),
                                    if (state.transformVideoResponse!.dstSize != null)
                                      _buildResultItem(
                                        Translations.getOffsideText('dstSize', currentLang),
                                        '${state.transformVideoResponse!.dstSize!['width']}x${state.transformVideoResponse!.dstSize!['height']}',
                                        false,
                                        modeProvider.currentMode,
                                        seedColor,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            if (state.transformVideoResponse!.outputUrl != null) ...[
                              SizedBox(height: constraints.maxWidth * 0.03),
                              Text(
                                Translations.getOffsideText('transformedVideo', currentLang),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.getTextColor(modeProvider.currentMode),
                                ),
                              ),
                              SizedBox(height: constraints.maxWidth * 0.02),
                              VideoPlayerWidget(
                                videoUrl: '${PerspectiveService.baseUrl}${state.transformVideoResponse!.outputUrl}',
                                mode: modeProvider.currentMode,
                                seedColor: seedColor,
                              ),
                            ],
                          ],

                          // Transform Points
                          SizedBox(height: constraints.maxWidth * 0.05),
                          _buildSectionHeader(
                            Translations.getOffsideText('transformPoints', currentLang),
                            modeProvider.currentMode,
                            seedColor,
                          ),
                          SizedBox(height: constraints.maxWidth * 0.03),
                          TransformPointForm(
                            mode: modeProvider.currentMode,
                            seedColor: seedColor,
                            currentLang: currentLang,
                          ),
                          if (state.transformPointResponse != null && state.transformPointResponse!.ok) ...[
                            SizedBox(height: constraints.maxWidth * 0.03),
                            Card(
                              color: AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.8),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildResultItem(
                                      Translations.getOffsideText('success', currentLang),
                                      state.transformPointResponse!.ok.toString(),
                                      state.transformPointResponse!.ok,
                                      modeProvider.currentMode,
                                      seedColor,
                                    ),
                                    if (state.transformPointResponse!.input != null)
                                      _buildResultItem(
                                        Translations.getOffsideText('input', currentLang),
                                        state.transformPointResponse!.input.toString(),
                                        false,
                                        modeProvider.currentMode,
                                        seedColor,
                                      ),
                                    if (state.transformPointResponse!.output != null)
                                      _buildResultItem(
                                        Translations.getOffsideText('output', currentLang),
                                        state.transformPointResponse!.output.toString(),
                                        false,
                                        modeProvider.currentMode,
                                        seedColor,
                                      ),
                                    if (state.transformPointResponse!.error != null)
                                      _buildResultItem(
                                        Translations.getOffsideText('error', currentLang),
                                        state.transformPointResponse!.error!,
                                        true,
                                        modeProvider.currentMode,
                                        seedColor,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (state.inversePointResponse != null && state.inversePointResponse!.ok) ...[
                            SizedBox(height: constraints.maxWidth * 0.03),
                            Card(
                              color: AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.8),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildResultItem(
                                      Translations.getOffsideText('successInverse', currentLang),
                                      state.inversePointResponse!.ok.toString(),
                                      state.inversePointResponse!.ok,
                                      modeProvider.currentMode,
                                      seedColor,
                                    ),
                                    if (state.inversePointResponse!.input != null)
                                      _buildResultItem(
                                        Translations.getOffsideText('inputInverse', currentLang),
                                        state.inversePointResponse!.input.toString(),
                                        false,
                                        modeProvider.currentMode,
                                        seedColor,
                                      ),
                                    if (state.inversePointResponse!.output != null)
                                      _buildResultItem(
                                        Translations.getOffsideText('outputInverse', currentLang),
                                        state.inversePointResponse!.output.toString(),
                                        false,
                                        modeProvider.currentMode,
                                        seedColor,
                                      ),
                                    if (state.inversePointResponse!.error != null)
                                      _buildResultItem(
                                        Translations.getOffsideText('errorInverse', currentLang),
                                        state.inversePointResponse!.error!,
                                        true,
                                        modeProvider.currentMode,
                                        seedColor,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          // Maintenance
                          SizedBox(height: constraints.maxWidth * 0.05),
                          _buildSectionHeader(
                            Translations.getPlayerTrackingText('cleanArtifacts', currentLang),
                            modeProvider.currentMode,
                            seedColor,
                          ),
                          SizedBox(height: constraints.maxWidth * 0.03),
                          ElevatedButton(
                            onPressed: () {
                              print('Clean button pressed');
                              setState(() {
                                _hasShownCleanSnackBar = false;
                              });
                              context.read<PerspectiveBloc>().add(CleanEvent());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: AppColors.getTextColor(modeProvider.currentMode),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              Translations.getPlayerTrackingText('cleanArtifacts', currentLang),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.getTextColor(modeProvider.currentMode),
                              ),
                            ),
                          ),
                          SizedBox(height: constraints.maxWidth * 0.1),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, int mode, Color seedColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: AppColors.getTextColor(mode).withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.getTextColor(mode),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int mode, Color seedColor) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.getTextColor(mode),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildResultItem(String label, String value, bool isSuccess, int mode, Color seedColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: AppColors.getTextColor(mode).withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: isSuccess ? AppColors.getTertiaryColor(seedColor, mode) : Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}