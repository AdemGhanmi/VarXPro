
import 'dart:io';
import 'package:VarXPro/views/pages/TrackingAndGoalAnalysis/Widgets/VideoPlayerWidget.dart';
import 'package:VarXPro/views/pages/TrackingAndGoalAnalysis/model/analysis_result.dart';
import 'package:VarXPro/views/pages/TrackingAndGoalAnalysis/widgets/file_picker_widget.dart';
import 'package:VarXPro/views/pages/TrackingAndGoalAnalysis/controller/tracking_controller.dart';
import 'package:VarXPro/views/pages/TrackingAndGoalAnalysis/service/tracking_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class EnhancedSoccerPlayerTrackingAndGoalAnalysisPage extends StatefulWidget {
  const EnhancedSoccerPlayerTrackingAndGoalAnalysisPage({super.key});

  @override
  _EnhancedSoccerPlayerTrackingAndGoalAnalysisPageState createState() =>
      _EnhancedSoccerPlayerTrackingAndGoalAnalysisPageState();
}

class _EnhancedSoccerPlayerTrackingAndGoalAnalysisPageState
    extends State<EnhancedSoccerPlayerTrackingAndGoalAnalysisPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _detectionConfidenceController = TextEditingController(text: '0.4');
  final _trailLengthController = TextEditingController(text: '30');
  final _goalLeftXController = TextEditingController(text: '100');
  final _goalLeftYController = TextEditingController(text: '100');
  final _goalRightXController = TextEditingController(text: '500');
  final _goalRightYController = TextEditingController(text: '100');
  bool _showTrails = true;
  bool _showSkeleton = true;
  bool _showBoxes = true;
  bool _showIds = true;
  int _visibleRows = 10;
  bool _showAllRows = false;
  bool _showLottie = true;
  late AnimationController _glowController;
  late AnimationController _scanController;
  late Animation<double> _glowAnimation;

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

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showLottie = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _detectionConfidenceController.dispose();
    _trailLengthController.dispose();
    _goalLeftXController.dispose();
    _goalLeftYController.dispose();
    _goalRightXController.dispose();
    _goalRightYController.dispose();
    _glowController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final modeProvider = Provider.of<ModeProvider>(context);
    final currentLang = langProvider.currentLanguage;
    final mode = modeProvider.currentMode;
    final seedColor = AppColors.seedColors[mode] ?? AppColors.seedColors[1]!;
    final screenWidth = MediaQuery.of(context).size.width;

    if (_showLottie) {
      return Scaffold(
        backgroundColor: AppColors.getBackgroundColor(mode),
        body: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _FootballGridPainter(mode),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.getBodyGradient(mode),
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
                      mode: mode,
                      seedColor: seedColor,
                    ),
                  );
                },
              ),
            ),
            Center(
              child: Lottie.asset(
                'assets/lotties/GoalAnalysis.json',
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
          TrackingBloc(context.read<TrackingService>())..add(CheckHealthEvent()),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _FootballGridPainter(mode),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.getBodyGradient(mode),
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
                      mode: mode,
                      seedColor: seedColor,
                    ),
                  );
                },
              ),
            ),
            BlocConsumer<TrackingBloc, TrackingState>(
              listener: (context, state) {
                if (state.cleanResponse != null && state.cleanResponse!.ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        Translations.getPlayerTrackingText(
                            'artifactsCleaned', currentLang),
                        style: GoogleFonts.roboto(
                          color: AppColors.getTextColor(mode),
                          fontSize: 14,
                        ),
                      ),
                      backgroundColor: AppColors.getTertiaryColor(seedColor, mode),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                  context.read<TrackingBloc>().emit(TrackingState(
                        health: state.health,
                      ));
                }
                if (state.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${Translations.getPlayerTrackingText('error', currentLang)}: ${state.error}',
                        style: GoogleFonts.roboto(
                          color: AppColors.getTextColor(mode),
                          fontSize: 14,
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
              },
              builder: (context, state) {
                if (state.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(
                          AppColors.getTertiaryColor(seedColor, mode)),
                    ),
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: EdgeInsets.all(constraints.maxWidth * 0.04),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [                          
                          SizedBox(height: constraints.maxWidth * 0.05),
                          // Config Form
                          _buildSectionHeader(
                              Translations.getPlayerTrackingText(
                                  'analysisConfiguration', currentLang),
                              mode,
                              seedColor),
                          SizedBox(height: constraints.maxWidth * 0.03),
                          _buildConfigForm(
                              constraints, context, currentLang, mode, seedColor),
                          // Results
                          if (state.analyzeResponse != null) ...[
                            SizedBox(height: constraints.maxWidth * 0.05),
                            _buildResults(state.analyzeResponse!, constraints,
                                currentLang, mode, seedColor),
                            SizedBox(height: constraints.maxWidth * 0.05),
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: () => context
                                    .read<TrackingBloc>()
                                    .add(CleanArtifactsEvent()),
                                icon: const Icon(Icons.delete, size: 18),
                                label: Text(
                                  Translations.getPlayerTrackingText(
                                      'cleanArtifacts', currentLang),
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: AppColors.getTextColor(mode),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  minimumSize:
                                      Size(constraints.maxWidth * 0.3, 50),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(
      String label, String value, int mode, Color seedColor) {
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
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.roboto(
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
      style: GoogleFonts.roboto(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.getTextColor(mode),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildConfigForm(BoxConstraints constraints, BuildContext context,
      String currentLang, int mode, Color seedColor) {
    return Card(
      color: AppColors.getSurfaceColor(mode).withOpacity(0.8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              FilePickerWidget(
                onFilePicked: (File file) {
                  if (_formKey.currentState?.validate() ?? false) {
                    context.read<TrackingBloc>().add(AnalyzeVideoEvent(
                          video: file,
                          detectionConfidence:
                              double.parse(_detectionConfidenceController.text),
                          showTrails: _showTrails,
                          showSkeleton: _showSkeleton,
                          showBoxes: _showBoxes,
                          showIds: _showIds,
                          trailLength: int.parse(_trailLengthController.text),
                          goalLeft: [
                            int.parse(_goalLeftXController.text),
                            int.parse(_goalLeftYController.text),
                          ],
                          goalRight: [
                            int.parse(_goalRightXController.text),
                            int.parse(_goalRightYController.text),
                          ],
                        ));
                  }
                },
                buttonText: Translations.getPlayerTrackingText(
                    'pickAndAnalyzeVideo', currentLang),
                fileType: FileType.video,
                mode: mode,
                seedColor: seedColor,
              ),
              SizedBox(height: constraints.maxWidth * 0.04),
              TextFormField(
                controller: _detectionConfidenceController,
                decoration: InputDecoration(
                  labelText: Translations.getPlayerTrackingText(
                      'detectionConfidence', currentLang),
                  labelStyle: GoogleFonts.roboto(
                      color: AppColors.getTertiaryColor(seedColor, mode)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.getTertiaryColor(seedColor, mode)
                          .withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.getTertiaryColor(seedColor, mode)
                          .withOpacity(0.3),
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.getSurfaceColor(mode).withOpacity(0.6),
                ),
                style: GoogleFonts.roboto(color: AppColors.getTextColor(mode)),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  final num = double.tryParse(value);
                  if (num == null || num < 0 || num > 1) {
                    return 'Must be between 0 and 1';
                  }
                  return null;
                },
              ),
              SizedBox(height: constraints.maxWidth * 0.04),
              SwitchListTile(
                title: Text(
                  Translations.getPlayerTrackingText('showTrails', currentLang),
                  style: GoogleFonts.roboto(
                      color: AppColors.getTextColor(mode), fontSize: 14),
                ),
                value: _showTrails,
                activeColor: AppColors.getTertiaryColor(seedColor, mode),
                onChanged: (val) => setState(() => _showTrails = val),
              ),
              SwitchListTile(
                title: Text(
                  Translations.getPlayerTrackingText('showSkeleton', currentLang),
                  style: GoogleFonts.roboto(
                      color: AppColors.getTextColor(mode), fontSize: 14),
                ),
                value: _showSkeleton,
                activeColor: AppColors.getTertiaryColor(seedColor, mode),
                onChanged: (val) => setState(() => _showSkeleton = val),
              ),
              SwitchListTile(
                title: Text(
                  Translations.getPlayerTrackingText('showBoxes', currentLang),
                  style: GoogleFonts.roboto(
                      color: AppColors.getTextColor(mode), fontSize: 14),
                ),
                value: _showBoxes,
                activeColor: AppColors.getTertiaryColor(seedColor, mode),
                onChanged: (val) => setState(() => _showBoxes = val),
              ),
              SwitchListTile(
                title: Text(
                  Translations.getPlayerTrackingText('showIds', currentLang),
                  style: GoogleFonts.roboto(
                      color: AppColors.getTextColor(mode), fontSize: 14),
                ),
                value: _showIds,
                activeColor: AppColors.getTertiaryColor(seedColor, mode),
                onChanged: (val) => setState(() => _showIds = val),
              ),
              SizedBox(height: constraints.maxWidth * 0.04),
              TextFormField(
                controller: _trailLengthController,
                decoration: InputDecoration(
                  labelText: Translations.getPlayerTrackingText(
                      'trailLength', currentLang),
                  labelStyle: GoogleFonts.roboto(
                      color: AppColors.getTertiaryColor(seedColor, mode)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.getTertiaryColor(seedColor, mode)
                          .withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.getTertiaryColor(seedColor, mode)
                          .withOpacity(0.3),
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.getSurfaceColor(mode).withOpacity(0.6),
                ),
                style: GoogleFonts.roboto(color: AppColors.getTextColor(mode)),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'Enter trail length' : null,
              ),
              SizedBox(height: constraints.maxWidth * 0.04),
              Text(
                Translations.getPlayerTrackingText(
                    'goalPostsCoordinates', currentLang),
                style: GoogleFonts.roboto(
                  color: AppColors.getTextColor(mode),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: constraints.maxWidth * 0.03),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _goalLeftXController,
                      decoration: InputDecoration(
                        labelText: Translations.getPlayerTrackingText(
                            'leftX', currentLang),
                        labelStyle: GoogleFonts.roboto(
                            color: AppColors.getTertiaryColor(seedColor, mode)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.getTertiaryColor(seedColor, mode)
                                .withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.getTertiaryColor(seedColor, mode)
                                .withOpacity(0.3),
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.getSurfaceColor(mode).withOpacity(0.6),
                      ),
                      style: GoogleFonts.roboto(color: AppColors.getTextColor(mode)),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter X coordinate' : null,
                    ),
                  ),
                  SizedBox(width: constraints.maxWidth * 0.02),
                  Expanded(
                    child: TextFormField(
                      controller: _goalLeftYController,
                      decoration: InputDecoration(
                        labelText: Translations.getPlayerTrackingText(
                            'leftY', currentLang),
                        labelStyle: GoogleFonts.roboto(
                            color: AppColors.getTertiaryColor(seedColor, mode)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.getTertiaryColor(seedColor, mode)
                                .withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.getTertiaryColor(seedColor, mode)
                                .withOpacity(0.3),
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.getSurfaceColor(mode).withOpacity(0.6),
                      ),
                      style: GoogleFonts.roboto(color: AppColors.getTextColor(mode)),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter Y coordinate' : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: constraints.maxWidth * 0.03),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _goalRightXController,
                      decoration: InputDecoration(
                        labelText: Translations.getPlayerTrackingText(
                            'rightX', currentLang),
                        labelStyle: GoogleFonts.roboto(
                            color: AppColors.getTertiaryColor(seedColor, mode)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.getTertiaryColor(seedColor, mode)
                                .withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.getTertiaryColor(seedColor, mode)
                                .withOpacity(0.3),
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.getSurfaceColor(mode).withOpacity(0.6),
                      ),
                      style: GoogleFonts.roboto(color: AppColors.getTextColor(mode)),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter X coordinate' : null,
                    ),
                  ),
                  SizedBox(width: constraints.maxWidth * 0.02),
                  Expanded(
                    child: TextFormField(
                      controller: _goalRightYController,
                      decoration: InputDecoration(
                        labelText: Translations.getPlayerTrackingText(
                            'rightY', currentLang),
                        labelStyle: GoogleFonts.roboto(
                            color: AppColors.getTertiaryColor(seedColor, mode)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.getTertiaryColor(seedColor, mode)
                                .withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.getTertiaryColor(seedColor, mode)
                                .withOpacity(0.3),
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.getSurfaceColor(mode).withOpacity(0.6),
                      ),
                      style: GoogleFonts.roboto(color: AppColors.getTextColor(mode)),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter Y coordinate' : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(AnalyzeResponse response, BoxConstraints constraints,
      String currentLang, int mode, Color seedColor) {
    final baseUrl = "https://tracking.varxpro.com";

    return Card(
      color: AppColors.getSurfaceColor(mode).withOpacity(0.8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultItem(
                Translations.getPlayerTrackingText(
                    'framesProcessed', currentLang),
                response.frames.toString(),
                false,
                mode,
                seedColor),
            _buildResultItem(
                Translations.getPlayerTrackingText('playerCount', currentLang),
                response.summary['player_count']?.toString() ?? '0',
                false,
                mode,
                seedColor),
            // Processed Video
            if (response.artifacts['video_url'] != null) ...[
              const SizedBox(height: 12),
              Text(
                Translations.getPlayerTrackingText('processedVideo', currentLang),
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextColor(mode),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight * 0.4,
                  maxWidth: constraints.maxWidth * 0.9,
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
                  child: VideoPlayerWidget(
                    url: "$baseUrl${response.artifacts['video_url']}",
                  ),
                ),
              ),
            ],
            // Analysis Image
            if (response.artifacts['analysis_url'] != null) ...[
              const SizedBox(height: 12),
              Text(
                Translations.getPlayerTrackingText('analysisPlot', currentLang),
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextColor(mode),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxWidth * 0.5,
                  maxWidth: constraints.maxWidth * 0.9,
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
                    "$baseUrl${response.artifacts['analysis_url']}",
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Text(
                      Translations.getPlayerTrackingText(
                          'failedToLoadImage', currentLang),
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
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          valueColor: AlwaysStoppedAnimation(
                              AppColors.getTertiaryColor(seedColor, mode)),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
            // Metrics Chart
            if (response.artifacts['metrics_url'] != null) ...[
              const SizedBox(height: 12),
              Text(
                Translations.getPlayerTrackingText('metricsChart', currentLang),
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextColor(mode),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxWidth * 0.5,
                  maxWidth: constraints.maxWidth * 0.9,
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
                    "$baseUrl${response.artifacts['metrics_url']}",
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Text(
                      Translations.getPlayerTrackingText(
                          'failedToLoadChart', currentLang),
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
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          valueColor: AlwaysStoppedAnimation(
                              AppColors.getTertiaryColor(seedColor, mode)),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
            // Results Table
            if (response.artifacts['results_url'] != null) ...[
              const SizedBox(height: 12),
              Text(
                Translations.getPlayerTrackingText('resultsTable', currentLang),
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextColor(mode),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<http.Response>(
                future:
                    http.get(Uri.parse("$baseUrl${response.artifacts['results_url']}")),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(
                            AppColors.getTertiaryColor(seedColor, mode)),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Text(
                      Translations.getPlayerTrackingText(
                          'errorLoadingResults', currentLang),
                      style: GoogleFonts.roboto(
                        color: Colors.redAccent,
                        fontSize: 14,
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data?.body == null) {
                    return Text(
                      Translations.getPlayerTrackingText(
                          'noResultsData', currentLang),
                      style: GoogleFonts.roboto(
                        color: AppColors.getTextColor(mode),
                        fontSize: 14,
                      ),
                    );
                  }
                  final csvContent = snapshot.data!.body;
                  final List<String> lines = csvContent
                      .split('\n')
                      .where((line) => line.isNotEmpty)
                      .toList();
                  if (lines.isEmpty) {
                    return Text(
                      Translations.getPlayerTrackingText('emptyCSV', currentLang),
                      style: GoogleFonts.roboto(
                        color: AppColors.getTextColor(mode),
                        fontSize: 14,
                      ),
                    );
                  }
                  final List<List<String>> data = lines.map((line) {
                    return line.split(',').map((e) => e.trim()).toList();
                  }).toList();
                  final List<String> headers = data[0];
                  final int colCount = headers.length;
                  final List<DataRow> rows = data.sublist(1).map((row) {
                    List<String> adjusted = List.from(row);
                    while (adjusted.length < colCount) {
                      adjusted.add('');
                    }
                    if (adjusted.length > colCount) {
                      adjusted = adjusted.sublist(0, colCount);
                    }
                    return DataRow(
                      cells: adjusted
                          .map((cell) => DataCell(
                                Text(
                                  cell,
                                  style: GoogleFonts.roboto(
                                    color: AppColors.getTextColor(mode),
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                    );
                  }).toList();

                  final rowsToShow =
                      _showAllRows ? rows : rows.take(_visibleRows).toList();

                  return Column(
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth * 0.9,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.getTertiaryColor(seedColor, mode)
                                .withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: constraints.maxWidth > 600 ? 20 : 10,
                            dataRowMinHeight: 40,
                            dataRowMaxHeight: 48,
                            headingRowHeight: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            columns: headers
                                .map(
                                  (header) => DataColumn(
                                    label: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      child: Text(
                                        header,
                                        style: GoogleFonts.roboto(
                                          fontSize:
                                              constraints.maxWidth > 600 ? 14 : 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.getTertiaryColor(
                                              seedColor, mode),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            rows: rowsToShow.asMap().entries.map((entry) {
                              final index = entry.key;
                              final row = entry.value;
                              return DataRow(
                                color: WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.hovered)) {
                                    return AppColors.getTertiaryColor(seedColor, mode)
                                        .withOpacity(0.1);
                                  }
                                  return index % 2 == 0
                                      ? AppColors.getSurfaceColor(mode)
                                          .withOpacity(0.4)
                                      : AppColors.getBackgroundColor(mode)
                                          .withOpacity(0.4);
                                }),
                                cells: row.cells,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      if (rows.length > _visibleRows) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!_showAllRows) ...[
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _visibleRows += 10;
                                    if (_visibleRows >= rows.length) {
                                      _showAllRows = true;
                                    }
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.getTertiaryColor(
                                          seedColor, mode)
                                      .withOpacity(0.2),
                                  foregroundColor:
                                      AppColors.getTertiaryColor(seedColor, mode),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  Translations.getPlayerTrackingText(
                                      'showMore', currentLang),
                                  style: GoogleFonts.roboto(fontSize: 14),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _showAllRows = !_showAllRows;
                                  if (!_showAllRows) {
                                    _visibleRows = 10;
                                  }
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.getTertiaryColor(
                                        seedColor, mode)
                                    .withOpacity(0.2),
                                foregroundColor:
                                    AppColors.getTertiaryColor(seedColor, mode),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                _showAllRows
                                    ? Translations.getPlayerTrackingText(
                                        'showLess', currentLang)
                                    : Translations.getPlayerTrackingText(
                                        'showAll', currentLang),
                                style: GoogleFonts.roboto(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(
      String label, String value, bool isOffside, int mode, Color seedColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.roboto(
              color: AppColors.getTextColor(mode).withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.roboto(
                color: isOffside
                    ? Colors.redAccent
                    : AppColors.getTertiaryColor(seedColor, mode),
                fontSize: 14,
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
    final rect = Rect.fromLTWH(inset, inset * 2, size.width - inset * 2, size.height - inset * 4);
    canvas.drawRect(rect, fieldPaint);

    final midX = rect.center.dy;
    canvas.drawLine(Offset(rect.left + rect.width / 2 - 100, midX), Offset(rect.left + rect.width / 2 + 100, midX), fieldPaint);
    canvas.drawCircle(Offset(rect.left + rect.width / 2, midX), 30, fieldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScanLinePainter extends CustomPainter {
  final double progress;
  final int mode;
  final Color seedColor;

  _ScanLinePainter({required this.progress, required this.mode, required this.seedColor});

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
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, y),
        radius: size.width * 0.25,
      ));

    canvas.drawCircle(Offset(size.width / 2, y), size.width * 0.25, glow);
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.mode != mode;
}

