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
  late Animation<double> _glowAnimation; // Added declaration
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
                height: MediaQuery.of(context).size.height * 0.5,
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
                      content: Text(
                        state.error!,
                        style: GoogleFonts.roboto(
                          color: AppColors.getTextColor(
                            modeProvider.currentMode,
                          ),
                          fontSize: 14,
                        ),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(Translations.getTranslation(
                          'Analysis complete! View results.',
                          languageProvider.currentLanguage)),
                      backgroundColor: Colors.green,
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
                            TicTacToeGame(
                                currentLanguage: languageProvider.currentLanguage),
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
                        Card(
                          color: AppColors.getSurfaceColor(
                            modeProvider.currentMode,
                          ).withOpacity(0.8),
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
                                  Translations.getTranslation(
                                      'API Status', languageProvider.currentLanguage),
                                  style: GoogleFonts.roboto(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.getTextColor(
                                      modeProvider.currentMode,
                                    ),
                                  ),
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
                                Text(
                                  '${Translations.getTranslation('Model Loaded: ', languageProvider.currentLanguage)}${state.health?.modelLoaded ?? false}',
                                  style: GoogleFonts.roboto(
                                    color: AppColors.getTextColor(
                                      modeProvider.currentMode,
                                    ),
                                    fontSize: 14,
                                  ),
                                ),
                                if (state.health?.classes != null)
                                  Text(
                                    '${Translations.getTranslation('Classes: ', languageProvider.currentLanguage)}${state.health!.classes!.values.join(", ")}',
                                    style: GoogleFonts.roboto(
                                      color: AppColors.getTextColor(
                                        modeProvider.currentMode,
                                      ),
                                      fontSize: 14,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Video Picker
                        FilePickerWidget(
                          onFilePicked: (File file) {
                            setState(() {
                              _analysisCompleted = false;
                            });
                            context.read<RefereeBloc>().add(
                                  AnalyzeVideoEvent(video: file),
                                );
                          },
                          buttonText: Translations.getTranslation(
                              'Upload Video for Analysis',
                              languageProvider.currentLanguage),
                          allowedExtensions: ['mp4'],
                        ),

                        // Analysis Results
                        if (state.analyzeResponse != null &&
                            state.analyzeResponse!.ok) ...[
                          const SizedBox(height: 20),
                          Text(
                            Translations.getTranslation(
                                'Analysis Results', languageProvider.currentLanguage),
                            style: GoogleFonts.roboto(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.getTextColor(
                                modeProvider.currentMode,
                              ),
                            ),
                          ),
                          // Summary
                          Card(
                            color: AppColors.getSurfaceColor(
                              modeProvider.currentMode,
                            ).withOpacity(0.8),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSummaryItem(
                                    Translations.getTranslation('Total Distance',
                                        languageProvider.currentLanguage),
                                    '${state.analyzeResponse!.summary.totalDistanceKm.toStringAsFixed(2)} km',
                                    modeProvider.currentMode,
                                    seedColor,
                                  ),
                                  _buildSummaryItem(
                                    Translations.getTranslation('Average Speed',
                                        languageProvider.currentLanguage),
                                    '${state.analyzeResponse!.summary.avgSpeedKmH.toStringAsFixed(2)} km/h',
                                    modeProvider.currentMode,
                                    seedColor,
                                  ),
                                  _buildSummaryItem(
                                    Translations.getTranslation('Max Speed',
                                        languageProvider.currentLanguage),
                                    '${state.analyzeResponse!.summary.maxSpeedKmH.toStringAsFixed(2)} km/h',
                                    modeProvider.currentMode,
                                    seedColor,
                                  ),
                                  _buildSummaryItem(
                                    Translations.getTranslation(
                                        'Sprints', languageProvider.currentLanguage),
                                    '${state.analyzeResponse!.summary.sprints}',
                                    modeProvider.currentMode,
                                    seedColor,
                                  ),
                                  _buildSummaryItem(
                                    Translations.getTranslation(
                                        'First Half Distance',
                                        languageProvider.currentLanguage),
                                    '${state.analyzeResponse!.summary.distanceFirstHalfKm.toStringAsFixed(2)} km',
                                    modeProvider.currentMode,
                                    seedColor,
                                  ),
                                  _buildSummaryItem(
                                    Translations.getTranslation(
                                        'Second Half Distance',
                                        languageProvider.currentLanguage),
                                    '${state.analyzeResponse!.summary.distanceSecondHalfKm.toStringAsFixed(2)} km',
                                    modeProvider.currentMode,
                                    seedColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Download Buttons
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 600) {
                                return Column(
                                  children: [
                                    ElevatedButton(
                                      onPressed: () async {
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
                                      child: Text(Translations.getTranslation(
                                          'Download Report TXT',
                                          languageProvider.currentLanguage)),
                                    ),
                                    const SizedBox(height: 10),
                                    ElevatedButton(
                                      onPressed: () async {
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
                                      child: Text(Translations.getTranslation(
                                          'Download Metrics CSV',
                                          languageProvider.currentLanguage)),
                                    ),
                                  ],
                                );
                              } else {
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () async {
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
                                      child: Text(Translations.getTranslation(
                                          'Download Report TXT',
                                          languageProvider.currentLanguage)),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
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
                                      child: Text(Translations.getTranslation(
                                          'Download Metrics CSV',
                                          languageProvider.currentLanguage)),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),

                          // Report Text
                          ExpansionTile(
                            title: Text(
                              Translations.getTranslation(
                                  'Full Report', languageProvider.currentLanguage),
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
                                padding: const EdgeInsets.all(8.0),
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

                          // Visualizations
                          const SizedBox(height: 20),
                          Text(
                            Translations.getTranslation(
                                'Heatmap', languageProvider.currentLanguage),
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.bold,
                              color: AppColors.getTextColor(
                                modeProvider.currentMode,
                              ),
                              fontSize: 16,
                            ),
                          ),
                          _buildImageContainer(
                            '$baseUrl${state.analyzeResponse!.artifacts.heatmapUrl}',
                            screenWidth,
                            modeProvider.currentMode,
                            seedColor,
                            languageProvider.currentLanguage,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            Translations.getTranslation(
                                'Speed Plot', languageProvider.currentLanguage),
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.bold,
                              color: AppColors.getTextColor(
                                modeProvider.currentMode,
                              ),
                              fontSize: 16,
                            ),
                          ),
                          _buildImageContainer(
                            '$baseUrl${state.analyzeResponse!.artifacts.speedPlotUrl}',
                            screenWidth,
                            modeProvider.currentMode,
                            seedColor,
                            languageProvider.currentLanguage,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            Translations.getTranslation(
                                'Proximity Plot', languageProvider.currentLanguage),
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.bold,
                              color: AppColors.getTextColor(
                                modeProvider.currentMode,
                              ),
                              fontSize: 16,
                            ),
                          ),
                          _buildImageContainer(
                            '$baseUrl${state.analyzeResponse!.artifacts.proximityPlotUrl}',
                            screenWidth,
                            modeProvider.currentMode,
                            seedColor,
                            languageProvider.currentLanguage,
                          ),

                          // Output Video
                          const SizedBox(height: 20),
                          Text(
                            Translations.getTranslation(
                                'Output Video', languageProvider.currentLanguage),
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.bold,
                              color: AppColors.getTextColor(
                                modeProvider.currentMode,
                              ),
                              fontSize: 16,
                            ),
                          ),
                          VideoPlayerWidget(
                            videoUrl:
                                '$baseUrl${state.analyzeResponse!.artifacts.outputVideoUrl}',
                          ),

                          // Sample Frames
                          if (state.analyzeResponse!.artifacts.sampleFramesUrls
                              .isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Text(
                              Translations.getTranslation(
                                  'Sample Frames', languageProvider.currentLanguage),
                              style: GoogleFonts.roboto(
                                fontWeight: FontWeight.bold,
                                color: AppColors.getTextColor(
                                  modeProvider.currentMode,
                                ),
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(
                              height: 200,
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
                                        constraints: const BoxConstraints(
                                          maxWidth: 150,
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
                                            width: 150,
                                            fit: BoxFit.contain,
                                            errorBuilder:
                                                (context, error, stackTrace) => Text(
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

                          // Clean Button
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () =>
                                context.read<RefereeBloc>().add(CleanFilesEvent()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(Translations.getTranslation(
                                'Clean Server Files',
                                languageProvider.currentLanguage)),
                          ),
                          if (state.cleanResponse != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
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
          Text(
            '$label: ',
            style: GoogleFonts.roboto(
              color: AppColors.getTextColor(mode).withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.roboto(
              color: AppColors.getTextColor(mode),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContainer(
    String url,
    double screenWidth,
    int mode,
    Color seedColor,
    String currentLanguage,
  ) {
    return GestureDetector(
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
            errorBuilder: (context, error, stackTrace) => Text(
              Translations.getTranslation('Failed to load image', currentLanguage),
              style: GoogleFonts.roboto(
                color: AppColors.getTextColor(mode),
                fontSize: 14,
              ),
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

    const step = 50.0;
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

    final inset = 40.0;
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
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextColor(modeProvider.currentMode),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (gameOver)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                winner == 'Draw'
                    ? Translations.getTranslation(
                        'It\'s a draw!', widget.currentLanguage)
                    : '$winner${Translations.getTranslation(' wins!', widget.currentLanguage)}',
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTertiaryColor(seedColor, modeProvider.currentMode),
                ),
              ),
            ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: resetGame,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  AppColors.getTertiaryColor(seedColor, modeProvider.currentMode),
              foregroundColor: AppColors.getTextColor(modeProvider.currentMode),
            ),
            child: Text(
              Translations.getTranslation('Reset Game', widget.currentLanguage),
              style: GoogleFonts.roboto(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}