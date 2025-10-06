import 'dart:io';
import 'dart:math';
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/views/pages/RefereeTraking/controller/referee_controller.dart';
import 'package:VarXPro/views/pages/RefereeTraking/service/referee_api_service.dart';
import 'package:VarXPro/views/pages/RefereeTraking/widgets/file_picker_widget.dart';
import 'package:VarXPro/views/pages/RefereeTraking/widgets/video_player_widget.dart';
import 'package:VarXPro/views/setting/provider/history_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

const String baseUrl = 'https://refereetrackingsystem.varxpro.com';

class RefereeTrackingSystemPage extends StatefulWidget {
  const RefereeTrackingSystemPage({super.key});

  @override
  _RefereeTrackingSystemPageState createState() =>
      _RefereeTrackingSystemPageState();
}

class _RefereeTrackingSystemPageState extends State<RefereeTrackingSystemPage>
    with TickerProviderStateMixin {
  bool _showSplash = true;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation; 
  late AnimationController _scanController;
  bool _analysisCompleted = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modeProvider = Provider.of<ModeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final seedColor =
        AppColors.seedColors[modeProvider.currentMode] ??
        AppColors.seedColors[1]!;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLargeScreen = screenWidth > 600;
    final isMediumScreen = screenWidth > 400 && screenWidth <= 600;

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
                    gradient: AppColors.getBodyGradient(
                      modeProvider.currentMode,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _scanController,
                builder: (context, _) {
                  final t = _scanController.value;
                  return CustomPaint(
                    painter: _ScanLinePainter(
                      progress: t,
                      mode: modeProvider.currentMode,
                      seedColor: seedColor,
                    ),
                  );
                },
              ),
            ),
            Center(
              child: Lottie.asset(
                'assets/lotties/refere.json',
                width: screenWidth * 0.8,
                height: screenHeight * 0.5,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      );
    }

    return BlocProvider(
      create: (context) =>
          RefereeBloc(context.read<RefereeService>())..add(CheckHealthEvent()),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Referee Tracking System',
            style: GoogleFonts.roboto(
              fontSize: isLargeScreen ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextColor(modeProvider.currentMode),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: AppColors.getTextColor(modeProvider.currentMode),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _FootballGridPainter(modeProvider.currentMode),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.getBodyGradient(
                      modeProvider.currentMode,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _scanController,
                builder: (context, _) {
                  final t = _scanController.value;
                  return CustomPaint(
                    painter: _ScanLinePainter(
                      progress: t,
                      mode: modeProvider.currentMode,
                      seedColor: seedColor,
                    ),
                  );
                },
              ),
            ),
            BlocConsumer<RefereeBloc, RefereeState>(
              listener: (context, state) {
                if (state.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Text('⚠️', style: GoogleFonts.roboto(fontSize: 20)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.error!,
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      action: SnackBarAction(
                        label: Translations.getTranslation(
                            'Retry', languageProvider.currentLanguage),
                        textColor: Colors.white,
                        onPressed: () {
                          context.read<RefereeBloc>().add(CheckHealthEvent());
                        },
                      ),
                    ),
                  );
                }
                if (!state.isLoading &&
                    state.analyzeResponse != null &&
                    !_analysisCompleted) {
                  _analysisCompleted = true;
                  // Log to history on successful analysis
                  final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
                  historyProvider.addHistoryItem('Referee Tracking', 'Referee tracking analysis completed');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Text('✅', style: GoogleFonts.roboto(fontSize: 20)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(Translations.getTranslation(
                                'Analysis complete! View results.',
                                languageProvider.currentLanguage)),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state.isLoading) {
                  return Center(
                    child: Directionality(
                      textDirection: languageProvider.currentLanguage == 'ar'
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('⏳', style: GoogleFonts.roboto(fontSize: 60, color: Colors.orange)),
                            const SizedBox(height: 16),
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(
                                AppColors.getTertiaryColor(
                                  seedColor,
                                  modeProvider.currentMode,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                Translations.getTranslation(
                                    'Analyzing video... This may take 10-30 minutes or longer.',
                                    languageProvider.currentLanguage),
                                style: GoogleFonts.roboto(
                                  color: AppColors.getTextColor(
                                    modeProvider.currentMode,
                                  ),
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              Translations.getTranslation(
                                  'Play Tic-Tac-Toe while waiting!',
                                  languageProvider.currentLanguage),
                              style: GoogleFonts.roboto(
                                color: AppColors.getTextColor(
                                  modeProvider.currentMode,
                                ),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: isLargeScreen ? screenWidth * 0.6 : screenWidth * 0.8,
                              child: TicTacToeGame(
                                  currentLanguage: languageProvider.currentLanguage),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return Directionality(
                  textDirection: languageProvider.currentLanguage == 'ar'
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        // Health Status
                        _buildResponsiveCard(
                          context,
                          isLargeScreen,
                          isMediumScreen,
                          modeProvider.currentMode,
                          seedColor,
                          children: [
                            Row(
                              children: [
                                Text('🩺', style: GoogleFonts.roboto(fontSize: 24)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${Translations.getTranslation(
                                        'API Status', languageProvider.currentLanguage)}',
                                    style: GoogleFonts.roboto(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.getTextColor(
                                        modeProvider.currentMode,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: state.health?.status == 'ok'
                                        ? AppColors.getTertiaryColor(
                                            seedColor,
                                            modeProvider.currentMode,
                                          )
                                        : Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  state.health?.status ??
                                      Translations.getTranslation(
                                          'Unknown',
                                          languageProvider.currentLanguage),
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    color: state.health?.status == 'ok'
                                        ? AppColors.getTertiaryColor(
                                            seedColor,
                                            modeProvider.currentMode,
                                          )
                                        : Colors.redAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text('🤖', style: GoogleFonts.roboto(fontSize: 16)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${Translations.getTranslation('Model Loaded: ', languageProvider.currentLanguage)}${state.health?.modelLoaded ?? false}',
                                    style: GoogleFonts.roboto(
                                      color: AppColors.getTextColor(
                                        modeProvider.currentMode,
                                      ),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (state.health?.classes != null)
                              Row(
                                children: [
                                  Text('📚', style: GoogleFonts.roboto(fontSize: 16)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${Translations.getTranslation('Classes: ', languageProvider.currentLanguage)}${state.health!.classes!.values.join(", ")}',
                                      style: GoogleFonts.roboto(
                                        color: AppColors.getTextColor(
                                          modeProvider.currentMode,
                                        ),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Video Picker
                        _buildResponsiveCard(
                          context,
                          isLargeScreen,
                          isMediumScreen,
                          modeProvider.currentMode,
                          seedColor,
                          children: [
                            Row(
                              children: [
                                Text('📹', style: GoogleFonts.roboto(fontSize: 24)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${Translations.getTranslation(
                                        'Upload Video for Analysis', languageProvider.currentLanguage)}',
                                    style: GoogleFonts.roboto(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.getTextColor(
                                        modeProvider.currentMode,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            FilePickerWidget(
                              onFilePicked: (File file) {
                                setState(() {
                                  _analysisCompleted = false;
                                });
                                context.read<RefereeBloc>().add(
                                      AnalyzeVideoEvent(video: file),
                                    );
                              },
                              buttonText: '🎥 ${Translations.getTranslation(
                                  'Upload Video for Analysis', languageProvider.currentLanguage)}',
                              allowedExtensions: ['mp4'],
                            ),
                          ],
                        ),

                        // Analysis Results
                        if (state.analyzeResponse != null &&
                            state.analyzeResponse!.ok) ...[
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Text('📊', style: GoogleFonts.roboto(fontSize: 24)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${Translations.getTranslation(
                                      'Analysis Results', languageProvider.currentLanguage)}',
                                  style: GoogleFonts.roboto(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.getTextColor(
                                      modeProvider.currentMode,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Summary
                          _buildResponsiveCard(
                            context,
                            isLargeScreen,
                            isMediumScreen,
                            modeProvider.currentMode,
                            seedColor,
                            children: [
                              Row(
                                children: [
                                  Text('📈', style: GoogleFonts.roboto(fontSize: 20)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${Translations.getTranslation(
                                          'Summary', languageProvider.currentLanguage)}',
                                      style: GoogleFonts.roboto(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.getTextColor(
                                          modeProvider.currentMode,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildSummaryItem(
                                '🏃 ${Translations.getTranslation('Total Distance',
                                    languageProvider.currentLanguage)}',
                                '${state.analyzeResponse!.summary.totalDistanceKm.toStringAsFixed(2)} km',
                                modeProvider.currentMode,
                                seedColor,
                              ),
                              _buildSummaryItem(
                                '⚡ ${Translations.getTranslation('Average Speed',
                                    languageProvider.currentLanguage)}',
                                '${state.analyzeResponse!.summary.avgSpeedKmH.toStringAsFixed(2)} km/h',
                                modeProvider.currentMode,
                                seedColor,
                              ),
                              _buildSummaryItem(
                                '🚀 ${Translations.getTranslation('Max Speed',
                                    languageProvider.currentLanguage)}',
                                '${state.analyzeResponse!.summary.maxSpeedKmH.toStringAsFixed(2)} km/h',
                                modeProvider.currentMode,
                                seedColor,
                              ),
                              _buildSummaryItem(
                                '💨 ${Translations.getTranslation(
                                    'Sprints', languageProvider.currentLanguage)}',
                                '${state.analyzeResponse!.summary.sprints}',
                                modeProvider.currentMode,
                                seedColor,
                              ),
                              _buildSummaryItem(
                                '⏰ ${Translations.getTranslation(
                                    'First Half Distance',
                                    languageProvider.currentLanguage)}',
                                '${state.analyzeResponse!.summary.distanceFirstHalfKm.toStringAsFixed(2)} km',
                                modeProvider.currentMode,
                                seedColor,
                              ),
                              _buildSummaryItem(
                                '🏁 ${Translations.getTranslation(
                                    'Second Half Distance',
                                    languageProvider.currentLanguage)}',
                                '${state.analyzeResponse!.summary.distanceSecondHalfKm.toStringAsFixed(2)} km',
                                modeProvider.currentMode,
                                seedColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Download Buttons
                          _buildResponsiveCard(
                            context,
                            isLargeScreen,
                            isMediumScreen,
                            modeProvider.currentMode,
                            seedColor,
                            children: [
                              Row(
                                children: [
                                  Text('📥', style: GoogleFonts.roboto(fontSize: 20)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${Translations.getTranslation(
                                          'Downloads', languageProvider.currentLanguage)}',
                                      style: GoogleFonts.roboto(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.getTextColor(
                                          modeProvider.currentMode,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  if (constraints.maxWidth < 600) {
                                    return Column(
                                      children: [
                                        _buildDownloadButton(
                                          '📄',
                                          '${Translations.getTranslation(
                                              'Download Report TXT', languageProvider.currentLanguage)}',
                                          () async {
                                            final url =
                                                '$baseUrl${state.analyzeResponse!.artifacts.reportUrl}';
                                            if (await canLaunchUrl(Uri.parse(url))) {
                                              await launchUrl(Uri.parse(url));
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    Translations.getTranslation(
                                                        'Could not open report',
                                                        languageProvider.currentLanguage),
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          modeProvider.currentMode,
                                          seedColor,
                                        ),
                                        const SizedBox(height: 10),
                                        _buildDownloadButton(
                                          '📊',
                                          '${Translations.getTranslation(
                                              'Download Metrics CSV', languageProvider.currentLanguage)}',
                                          () async {
                                            final url =
                                                '$baseUrl${state.analyzeResponse!.artifacts.metricsUrl}';
                                            if (await canLaunchUrl(Uri.parse(url))) {
                                              await launchUrl(Uri.parse(url));
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    Translations.getTranslation(
                                                        'Could not open metrics CSV',
                                                        languageProvider.currentLanguage),
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          modeProvider.currentMode,
                                          seedColor,
                                        ),
                                      ],
                                    );
                                  } else {
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildDownloadButton(
                                          '📄',
                                          '${Translations.getTranslation(
                                              'Download Report TXT', languageProvider.currentLanguage)}',
                                          () async {
                                            final url =
                                                '$baseUrl${state.analyzeResponse!.artifacts.reportUrl}';
                                            if (await canLaunchUrl(Uri.parse(url))) {
                                              await launchUrl(Uri.parse(url));
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    Translations.getTranslation(
                                                        'Could not open report',
                                                        languageProvider.currentLanguage),
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          modeProvider.currentMode,
                                          seedColor,
                                        ),
                                        _buildDownloadButton(
                                          '📊',
                                          '${Translations.getTranslation(
                                              'Download Metrics CSV', languageProvider.currentLanguage)}',
                                          () async {
                                            final url =
                                                '$baseUrl${state.analyzeResponse!.artifacts.metricsUrl}';
                                            if (await canLaunchUrl(Uri.parse(url))) {
                                              await launchUrl(Uri.parse(url));
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    Translations.getTranslation(
                                                        'Could not open metrics CSV',
                                                        languageProvider.currentLanguage),
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          modeProvider.currentMode,
                                          seedColor,
                                        ),
                                      ],
                                    );
                                  }
                                },
                              ),
                            ],
                          ),

                          // Report Text
                          _buildResponsiveCard(
                            context,
                            isLargeScreen,
                            isMediumScreen,
                            modeProvider.currentMode,
                            seedColor,
                            children: [
                              ExpansionTile(
                                leading: Text('📖', style: GoogleFonts.roboto(fontSize: 24, color: Colors.brown)),
                                title: Text(
                                  '${Translations.getTranslation(
                                      'Full Report', languageProvider.currentLanguage)}',
                                  style: GoogleFonts.roboto(
                                    color: AppColors.getTextColor(
                                      modeProvider.currentMode,
                                    ),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: SelectableText(
                                      state.reportText ??
                                          Translations.getTranslation(
                                              'No report available',
                                              languageProvider.currentLanguage),
                                      style: GoogleFonts.roboto(
                                        color: AppColors.getTextColor(
                                          modeProvider.currentMode,
                                        ),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Visualizations
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Text('👁️', style: GoogleFonts.roboto(fontSize: 20)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${Translations.getTranslation(
                                      'Visualizations', languageProvider.currentLanguage)}',
                                  style: GoogleFonts.roboto(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.getTextColor(
                                      modeProvider.currentMode,
                                    ),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          _buildImageContainer(
                            '$baseUrl${state.analyzeResponse!.artifacts.heatmapUrl}',
                            screenWidth,
                            modeProvider.currentMode,
                            seedColor,
                            languageProvider.currentLanguage,
                            '🔥 Heatmap',
                          ),
                          _buildImageContainer(
                            '$baseUrl${state.analyzeResponse!.artifacts.speedPlotUrl}',
                            screenWidth,
                            modeProvider.currentMode,
                            seedColor,
                            languageProvider.currentLanguage,
                            '⚡ Speed Plot',
                          ),
                          _buildImageContainer(
                            '$baseUrl${state.analyzeResponse!.artifacts.proximityPlotUrl}',
                            screenWidth,
                            modeProvider.currentMode,
                            seedColor,
                            languageProvider.currentLanguage,
                            '📍 Proximity Plot',
                          ),

                          // Output Video
                          const SizedBox(height: 20),
                          _buildResponsiveCard(
                            context,
                            isLargeScreen,
                            isMediumScreen,
                            modeProvider.currentMode,
                            seedColor,
                            children: [
                              Row(
                                children: [
                                  Text('▶️', style: GoogleFonts.roboto(fontSize: 20, color: Colors.red)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${Translations.getTranslation(
                                          'Output Video', languageProvider.currentLanguage)}',
                                      style: GoogleFonts.roboto(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.getTextColor(
                                          modeProvider.currentMode,
                                        ),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: isLargeScreen ? 300 : 200,
                                child: VideoPlayerWidget(
                                  videoUrl:
                                      '$baseUrl${state.analyzeResponse!.artifacts.outputVideoUrl}',
                                ),
                              ),
                            ],
                          ),

                          // Sample Frames
                          if (state.analyzeResponse!.artifacts.sampleFramesUrls
                              .isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildResponsiveCard(
                              context,
                              isLargeScreen,
                              isMediumScreen,
                              modeProvider.currentMode,
                              seedColor,
                              children: [
                                Row(
                                  children: [
                                    Text('📸', style: GoogleFonts.roboto(fontSize: 20, color: Colors.orange)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${Translations.getTranslation(
                                            'Sample Frames', languageProvider.currentLanguage)}',
                                        style: GoogleFonts.roboto(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.getTextColor(
                                            modeProvider.currentMode,
                                          ),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: isLargeScreen ? 250 : 150,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: state
                                        .analyzeResponse!.artifacts.sampleFramesUrls.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: GestureDetector(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => Dialog(
                                                child: Image.network(
                                                  '$baseUrl${state.analyzeResponse!.artifacts.sampleFramesUrls[index]}',
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (context, error, stackTrace) =>
                                                      Text(
                                                    Translations.getTranslation(
                                                        'Failed to load frame',
                                                        languageProvider.currentLanguage),
                                                    style: GoogleFonts.roboto(
                                                      color: AppColors.getTextColor(
                                                        modeProvider.currentMode,
                                                      ),
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            constraints: BoxConstraints(
                                              maxWidth: isLargeScreen ? 200 : 150,
                                              maxHeight: isLargeScreen ? 250 : 150,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: AppColors.getTertiaryColor(
                                                  seedColor,
                                                  modeProvider.currentMode,
                                                ).withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Image.network(
                                                '$baseUrl${state.analyzeResponse!.artifacts.sampleFramesUrls[index]}',
                                                fit: BoxFit.contain,
                                                errorBuilder:
                                                    (context, error, stackTrace) => Container(
                                                  color: Colors.grey[300],
                                                  child: Text('❌', style: GoogleFonts.roboto(fontSize: 50, color: Colors.red)),
                                                ),
                                                loadingBuilder:
                                                    (context, child, loadingProgress) {
                                                  if (loadingProgress == null) return child;
                                                  return Center(
                                                    child: CircularProgressIndicator(
                                                      value: loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                          ? loadingProgress
                                                                  .cumulativeBytesLoaded /
                                                              (loadingProgress
                                                                      .expectedTotalBytes ??
                                                                  1)
                                                          : null,
                                                      valueColor:
                                                          AlwaysStoppedAnimation(
                                                        AppColors.getTertiaryColor(
                                                          seedColor,
                                                          modeProvider.currentMode,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Clean Button
                          const SizedBox(height: 20),
                          _buildResponsiveCard(
                            context,
                            isLargeScreen,
                            isMediumScreen,
                            modeProvider.currentMode,
                            seedColor,
                            children: [
                              Row(
                                children: [
                                  Text('🧹', style: GoogleFonts.roboto(fontSize: 20, color: Colors.red)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${Translations.getTranslation(
                                          'Clean Server Files', languageProvider.currentLanguage)}',
                                      style: GoogleFonts.roboto(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.getTextColor(
                                          modeProvider.currentMode,
                                        ),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      context.read<RefereeBloc>().add(CleanFilesEvent()),
                                  icon: Text('🗑️', style: GoogleFonts.roboto(fontSize: 18, color: Colors.white)),
                                  label: Text('${Translations.getTranslation(
                                      'Clean Files', languageProvider.currentLanguage)}'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              if (state.cleanResponse != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    children: [
                                      Text('✅', style: GoogleFonts.roboto(fontSize: 16, color: Colors.green)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '${Translations.getTranslation('Cleaned ', languageProvider.currentLanguage)}${state.cleanResponse!.removed}${Translations.getTranslation(' files', languageProvider.currentLanguage)}',
                                          style: GoogleFonts.roboto(
                                            color: AppColors.getTextColor(
                                              modeProvider.currentMode,
                                            ),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveCard(
    BuildContext context,
    bool isLargeScreen,
    bool isMediumScreen,
    int mode,
    Color seedColor, {
    required List<Widget> children,
  }) {
    return Card(
      color: AppColors.getSurfaceColor(mode).withOpacity(0.8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(isLargeScreen ? 24.0 : (isMediumScreen ? 20.0 : 16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    int mode,
    Color seedColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.roboto(
                color: AppColors.getTextColor(mode).withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: GoogleFonts.roboto(
                  color: AppColors.getTextColor(mode),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton(
    String iconEmoji,
    String label,
    VoidCallback onPressed,
    int mode,
    Color seedColor,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Text(iconEmoji, style: GoogleFonts.roboto(fontSize: 18)),
        label: Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.getTertiaryColor(seedColor, mode),
          foregroundColor: AppColors.getTextColor(mode),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildImageContainer(
    String url,
    double screenWidth,
    int mode,
    Color seedColor,
    String currentLanguage,
    String title,
  ) {
    final isLargeScreen = screenWidth > 600;
    return Card(
      color: AppColors.getSurfaceColor(
        mode,
      ).withOpacity(0.8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(isLargeScreen ? 20.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('🖼️', style: GoogleFonts.roboto(fontSize: 20, color: Colors.teal)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextColor(
                        mode,
                      ),
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                      child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Text(
                      Translations.getTranslation('Failed to load image', currentLanguage),
                      style: GoogleFonts.roboto(
                        color: AppColors.getTextColor(mode),
                        fontSize: 14,
                      ),
                    ),
                  )),
                );
              },
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: screenWidth * 0.5,
                  maxWidth: screenWidth * 0.9,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: Text('❌', style: GoogleFonts.roboto(fontSize: 50, color: Colors.red)),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  (loadingProgress.expectedTotalBytes ?? 1)
                              : null,
                          valueColor: AlwaysStoppedAnimation(
                            AppColors.getTertiaryColor(seedColor, mode),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FootballGridPainter extends CustomPainter {
  final int mode;

  _FootballGridPainter(this.mode);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.getTextColor(mode).withOpacity(0.04)
      ..strokeWidth = 0.5;

    final step = size.width > 600 ? 60.0 : 50.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final fieldPaint = Paint()
      ..color = AppColors.getTextColor(mode).withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final inset = size.width > 600 ? 50.0 : 40.0;
    final rect = Rect.fromLTWH(
      inset,
      inset * 2,
      size.width - inset * 2,
      size.height - inset * 4,
    );
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

class _ScanLinePainter extends CustomPainter {
  final double progress;
  final int mode;
  final Color seedColor;

  _ScanLinePainter({
    required this.progress,
    required this.mode,
    required this.seedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    final line = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          AppColors.getPrimaryColor(seedColor, mode).withOpacity(0.2),
          AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 0.55, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, y - 80, size.width, 160));

    canvas.drawRect(Rect.fromLTWH(0, y - 80, size.width, 160), line);

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.getPrimaryColor(seedColor, mode).withOpacity(0.1),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width / 2, y),
          radius: size.width * 0.25,
        ),
      );

    canvas.drawCircle(Offset(size.width / 2, y), size.width * 0.25, glow);
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.mode != mode;
}

class TicTacToeGame extends StatefulWidget {
  final String currentLanguage;

  const TicTacToeGame({super.key, required this.currentLanguage});

  @override
  _TicTacToeGameState createState() => _TicTacToeGameState();
}

class _TicTacToeGameState extends State<TicTacToeGame> {
  late List<List<String>> board;
  late String currentPlayer;
  late bool gameOver;
  late String winner;

  @override
  void initState() {
    super.initState();
    resetGame();
  }

  void resetGame() {
    setState(() {
      board = List.generate(3, (_) => List.generate(3, (_) => ''));
      currentPlayer = 'X';
      gameOver = false;
      winner = '';
    });
  }

  void makeMove(int row, int col) {
    if (board[row][col] == '' && !gameOver) {
      setState(() {
        board[row][col] = currentPlayer;
        if (checkWinner(row, col)) {
          gameOver = true;
          winner = currentPlayer;
        } else if (isBoardFull()) {
          gameOver = true;
          winner = 'Draw';
        } else {
          currentPlayer = currentPlayer == 'X' ? 'O' : 'X';
          if (currentPlayer == 'O') {
            aiMove();
          }
        }
      });
    }
  }

  bool isBoardFull() {
    return board.every((r) => r.every((c) => c != ''));
  }

  void aiMove() {
    // AI is 'O', uses minimax to find the best move
    int bestScore = -1000;
    List<int> bestMove = [-1, -1];

    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (board[i][j] == '') {
          board[i][j] = 'O';
          int score = minimax(board, 0, false);
          board[i][j] = '';
          if (score > bestScore) {
            bestScore = score;
            bestMove = [i, j];
          }
        }
      }
    }

    if (bestMove[0] != -1 && bestMove[1] != -1) {
      int row = bestMove[0];
      int col = bestMove[1];
      board[row][col] = 'O';
      if (checkWinner(row, col)) {
        gameOver = true;
        winner = 'O';
      } else if (isBoardFull()) {
        gameOver = true;
        winner = 'Draw';
      } else {
        currentPlayer = 'X';
      }
      setState(() {});
    }
  }

  int minimax(List<List<String>> board, int depth, bool isMaximizing) {
    String result = checkGameOver(board);
    if (result != '') {
      if (result == 'O') return 10 - depth;
      if (result == 'X') return depth - 10;
      return 0;
    }

    if (isMaximizing) {
      int bestScore = -1000;
      for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
          if (board[i][j] == '') {
            board[i][j] = 'O';
            int score = minimax(board, depth + 1, false);
            board[i][j] = '';
            bestScore = max(score, bestScore);
          }
        }
      }
      return bestScore;
    } else {
      int bestScore = 1000;
      for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
          if (board[i][j] == '') {
            board[i][j] = 'X';
            int score = minimax(board, depth + 1, true);
            board[i][j] = '';
            bestScore = min(score, bestScore);
          }
        }
      }
      return bestScore;
    }
  }

  String checkGameOver(List<List<String>> board) {
    // Check rows
    for (int i = 0; i < 3; i++) {
      if (board[i][0] == board[i][1] && board[i][1] == board[i][2] && board[i][0] != '') {
        return board[i][0];
      }
    }
    // Check columns
    for (int i = 0; i < 3; i++) {
      if (board[0][i] == board[1][i] && board[1][i] == board[2][i] && board[0][i] != '') {
        return board[0][i];
      }
    }
    // Check diagonals
    if (board[0][0] == board[1][1] && board[1][1] == board[2][2] && board[0][0] != '') {
      return board[0][0];
    }
    if (board[0][2] == board[1][1] && board[1][1] == board[2][0] && board[0][2] != '') {
      return board[0][2];
    }
    // Check draw
    if (board.every((r) => r.every((c) => c != ''))) {
      return 'Draw';
    }
    return '';
  }

  bool checkWinner(int row, int col) {
    final player = board[row][col];
    // Check row
    if (board[row].every((c) => c == player)) return true;
    // Check column
    if (board.every((r) => r[col] == player)) return true;
    // Check diagonal
    if (row == col &&
        board[0][0] == player &&
        board[1][1] == player &&
        board[2][2] == player) {
      return true;
    }
    // Check anti-diagonal
    if (row + col == 2 &&
        board[0][2] == player &&
        board[1][1] == player &&
        board[2][0] == player) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final modeProvider = Provider.of<ModeProvider>(context);
    final seedColor =
        AppColors.seedColors[modeProvider.currentMode] ??
        AppColors.seedColors[1]!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;
    return Container(
      padding: EdgeInsets.all(isLargeScreen ? 20.0 : 16.0),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getTertiaryColor(seedColor, modeProvider.currentMode).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '🎮 ${Translations.getTranslation(
                      'Tic-Tac-Toe', widget.currentLanguage)}',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextColor(modeProvider.currentMode),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: isLargeScreen ? 300 : screenWidth * 0.8,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                final row = index ~/ 3;
                final col = index % 3;
                return GestureDetector(
                  onTap: () => makeMove(row, col),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.getTertiaryColor(seedColor, modeProvider.currentMode)
                            .withOpacity(0.5),
                      ),
                      color: AppColors.getBackgroundColor(modeProvider.currentMode),
                    ),
                    child: Center(
                      child: Text(
                        board[row][col],
                        style: GoogleFonts.roboto(
                          fontSize: isLargeScreen ? 50 : 40,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextColor(modeProvider.currentMode),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (gameOver)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (winner == 'Draw')
                    Text('😑', style: GoogleFonts.roboto(fontSize: 20, color: Colors.grey))
                  else
                    Text(
                      winner == 'X' ? '😊' : '😠',
                      style: GoogleFonts.roboto(fontSize: 20, color: winner == 'X' ? Colors.green : Colors.red),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      winner == 'Draw'
                          ? '🤝 ${Translations.getTranslation("It's a draw!", widget.currentLanguage)}'
                          : '$winner${Translations.getTranslation(' wins!', widget.currentLanguage)} 🏆',
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTertiaryColor(seedColor, modeProvider.currentMode),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: resetGame,
              icon: Text('🔄', style: GoogleFonts.roboto(fontSize: 18)),
              label: Text(
                '${Translations.getTranslation(
                    'Reset Game', widget.currentLanguage)}',
                style: GoogleFonts.roboto(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.getTertiaryColor(seedColor, modeProvider.currentMode),
                foregroundColor: AppColors.getTextColor(modeProvider.currentMode),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}