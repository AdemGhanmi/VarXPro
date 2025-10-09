import 'dart:io';
import 'dart:math';
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/views/pages/TrackingAndGoalAnalysis/model/analysis_result.dart';
import 'package:VarXPro/views/pages/TrackingAndGoalAnalysis/widgets/file_picker_widget.dart';
import 'package:VarXPro/views/pages/TrackingAndGoalAnalysis/controller/tracking_controller.dart';
import 'package:VarXPro/views/pages/TrackingAndGoalAnalysis/service/tracking_service.dart';
import 'package:VarXPro/views/setting/provider/history_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';
import 'package:fl_chart/fl_chart.dart';

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
  final _attackingTeamController = TextEditingController();
  final _lineStartXController = TextEditingController(text: '640');
  final _lineStartYController = TextEditingController(text: '0');
  final _lineEndXController = TextEditingController(text: '640');
  final _lineEndYController = TextEditingController(text: '480');
  bool _showTrails = true;
  bool _showSkeleton = true;
  bool _showBoxes = true;
  bool _showIds = true;
  bool _offsideEnabled = false;
  String _attackDirection = 'right';
  int _visibleRows = 10;
  bool _showAllRows = false;
  bool _showLottie = true;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  bool _analysisCompleted = false;

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
    _attackingTeamController.dispose();
    _lineStartXController.dispose();
    _lineStartYController.dispose();
    _lineEndXController.dispose();
    _lineEndYController.dispose();
    _glowController.dispose();
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
            Center(
              child: Directionality(
                textDirection: currentLang == 'ar'
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: Lottie.asset(
                  'assets/lotties/GoalAnalysis.json',
                  width: screenWidth * 0.8,
                  height: MediaQuery.of(context).size.height * 0.5,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return BlocProvider(
      create: (context) =>
          TrackingBloc(context.read<TrackingService>())
            ..add(CheckHealthEvent()),
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
            Directionality(
              textDirection: currentLang == 'ar'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: BlocConsumer<TrackingBloc, TrackingState>(
                listener: (context, state) {
                  if (state.cleanResponse != null && state.cleanResponse!.ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Text(
                              '✅',
                              style: GoogleFonts.roboto(
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                Translations.getPlayerTrackingText(
                                  'artifactsCleaned',
                                  currentLang,
                                ),
                                style: GoogleFonts.roboto(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: AppColors.getTertiaryColor(
                          seedColor,
                          mode,
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                    context.read<TrackingBloc>().emit(
                      TrackingState(health: state.health),
                    );
                  }
                  if (state.error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Text(
                              '⚠️',
                              style: GoogleFonts.roboto(
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${Translations.getPlayerTrackingText('error', currentLang)}: ${state.error}',
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
                      ),
                    );
                  }
                  if (!state.isLoading &&
                      state.analyzeResponse != null &&
                      !_analysisCompleted) {
                    _analysisCompleted = true;
                    // Log to history on successful analysis
                    final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
                    historyProvider.addHistoryItem('Player Tracking', 'Player tracking analysis completed');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Text('✅', style: GoogleFonts.roboto(fontSize: 20)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                Translations.getPlayerTrackingText(
                                  'Analysis complete! View results.',
                                  currentLang,
                                ),
                              ),
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
                        textDirection: currentLang == 'ar'
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '⏳',
                                style: GoogleFonts.roboto(
                                  fontSize: 60,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(height: 16),
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation(
                                  AppColors.getTertiaryColor(seedColor, mode),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                child: Text(
                                  Translations.getPlayerTrackingText(
                                    'Analyzing video... This may take 10-30 minutes or longer.',
                                    currentLang,
                                  ),
                                  style: GoogleFonts.roboto(
                                    color: AppColors.getTextColor(mode),
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                Translations.getPlayerTrackingText(
                                  'Play Tic-Tac-Toe while waiting!',
                                  currentLang,
                                ),
                                style: GoogleFonts.roboto(
                                  color: AppColors.getTextColor(mode),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TicTacToeGame(currentLanguage: currentLang),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) {
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
                            SizedBox(height: constraints.maxWidth * 0.05),
                            // Config Form Section - Added divider for better organization
                            Card(
                              color: Colors.transparent,
                              elevation: 0,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '⚙️',
                                        style: GoogleFonts.roboto(fontSize: 24),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildSectionHeader(
                                        Translations.getPlayerTrackingText(
                                          'analysisConfiguration',
                                          currentLang,
                                        ),
                                        mode,
                                        seedColor,
                                      ),
                                    ],
                                  ),
                                  const Divider(
                                    color: Colors.grey,
                                    thickness: 1,
                                    height: 30,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: constraints.maxWidth * 0.03),
                            _buildConfigForm(
                              constraints,
                              context,
                              currentLang,
                              mode,
                              seedColor,
                            ),
                            // Results Section - Added divider
                            if (state.analyzeResponse != null) ...[
                              SizedBox(height: constraints.maxWidth * 0.05),
                              Card(
                                color: Colors.transparent,
                                elevation: 0,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '📊',
                                          style: GoogleFonts.roboto(
                                            fontSize: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${Translations.getPlayerTrackingText('Analysis Results', currentLang)}',
                                          style: GoogleFonts.roboto(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.getTextColor(mode),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(
                                      color: Colors.grey,
                                      thickness: 1,
                                      height: 30,
                                    ),
                                  ],
                                ),
                              ),
                              _buildResults(
                                state.analyzeResponse!,
                                constraints,
                                currentLang,
                                mode,
                                seedColor,
                              ),
                              SizedBox(height: constraints.maxWidth * 0.05),
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: () => context
                                      .read<TrackingBloc>()
                                      .add(CleanArtifactsEvent()),
                                  icon: Text(
                                    '🗑️',
                                    style: GoogleFonts.roboto(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                  label: Text(
                                    Translations.getPlayerTrackingText(
                                      'cleanArtifacts',
                                      currentLang,
                                    ),
                                    style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    minimumSize: Size(
                                      constraints.maxWidth * 0.3,
                                      50,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            SizedBox(height: kBottomNavigationBarHeight + 16),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(
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

  Widget _buildConfigForm(
    BoxConstraints constraints,
    BuildContext context,
    String currentLang,
    int mode,
    Color seedColor,
  ) {
    return Card(
      color: AppColors.getSurfaceColor(mode).withOpacity(0.8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              FilePickerWidget(
                onFilePicked: (File file) {
                  setState(() {
                    _analysisCompleted = false;
                  });
                  if (_formKey.currentState?.validate() ?? false) {
                    context.read<TrackingBloc>().add(
                      AnalyzeVideoEvent(
                        video: file,
                        detectionConfidence: double.parse(
                          _detectionConfidenceController.text,
                        ),
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
                        offsideEnabled: _offsideEnabled,
                        attackDirection: _offsideEnabled ? _attackDirection : null,
                        attackingTeam: _offsideEnabled && _attackingTeamController.text.isNotEmpty 
                            ? _attackingTeamController.text.toUpperCase() 
                            : null,
                        lineStart: _offsideEnabled 
                            ? [int.parse(_lineStartXController.text), int.parse(_lineStartYController.text)] 
                            : null,
                        lineEnd: _offsideEnabled 
                            ? [int.parse(_lineEndXController.text), int.parse(_lineEndYController.text)] 
                            : null,
                      ),
                    );
                  }
                },
                buttonText:
                    '🎥 ${Translations.getPlayerTrackingText('pickAndAnalyzeVideo', currentLang)}',
                fileType: FileType.video,
                mode: mode,
                seedColor: seedColor,
              ),
              SizedBox(height: constraints.maxWidth * 0.04),
              TextFormField(
                controller: _detectionConfidenceController,
                decoration: InputDecoration(
                  labelText:
                      '🎯 ${Translations.getPlayerTrackingText('detectionConfidence', currentLang)}',
                  labelStyle: GoogleFonts.roboto(
                    color: AppColors.getTertiaryColor(seedColor, mode),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.getTertiaryColor(
                        seedColor,
                        mode,
                      ).withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.getTertiaryColor(
                        seedColor,
                        mode,
                      ).withOpacity(0.3),
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
                secondary: Text('🛤️', style: GoogleFonts.roboto(fontSize: 20)),
                title: Text(
                  Translations.getPlayerTrackingText('showTrails', currentLang),
                  style: GoogleFonts.roboto(
                    color: AppColors.getTextColor(mode),
                    fontSize: 14,
                  ),
                ),
                value: _showTrails,
                activeColor: AppColors.getTertiaryColor(seedColor, mode),
                onChanged: (val) => setState(() => _showTrails = val),
              ),
              SwitchListTile(
                secondary: Text('🦴', style: GoogleFonts.roboto(fontSize: 20)),
                title: Text(
                  Translations.getPlayerTrackingText(
                    'showSkeleton',
                    currentLang,
                  ),
                  style: GoogleFonts.roboto(
                    color: AppColors.getTextColor(mode),
                    fontSize: 14,
                  ),
                ),
                value: _showSkeleton,
                activeColor: AppColors.getTertiaryColor(seedColor, mode),
                onChanged: (val) => setState(() => _showSkeleton = val),
              ),
              SwitchListTile(
                secondary: Text('📦', style: GoogleFonts.roboto(fontSize: 20)),
                title: Text(
                  Translations.getPlayerTrackingText('showBoxes', currentLang),
                  style: GoogleFonts.roboto(
                    color: AppColors.getTextColor(mode),
                    fontSize: 14,
                  ),
                ),
                value: _showBoxes,
                activeColor: AppColors.getTertiaryColor(seedColor, mode),
                onChanged: (val) => setState(() => _showBoxes = val),
              ),
              SwitchListTile(
                secondary: Text('🔢', style: GoogleFonts.roboto(fontSize: 20)),
                title: Text(
                  Translations.getPlayerTrackingText('showIds', currentLang),
                  style: GoogleFonts.roboto(
                    color: AppColors.getTextColor(mode),
                    fontSize: 14,
                  ),
                ),
                value: _showIds,
                activeColor: AppColors.getTertiaryColor(seedColor, mode),
                onChanged: (val) => setState(() => _showIds = val),
              ),
              SizedBox(height: constraints.maxWidth * 0.04),
              TextFormField(
                controller: _trailLengthController,
                decoration: InputDecoration(
                  labelText:
                      '🛤️ ${Translations.getPlayerTrackingText('trailLength', currentLang)}',
                  labelStyle: GoogleFonts.roboto(
                    color: AppColors.getTertiaryColor(seedColor, mode),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.getTertiaryColor(
                        seedColor,
                        mode,
                      ).withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.getTertiaryColor(
                        seedColor,
                        mode,
                      ).withOpacity(0.3),
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
              Row(
                children: [
                  Text('⚽', style: GoogleFonts.roboto(fontSize: 20)),
                  const SizedBox(width: 4),
                  Text(
                    Translations.getPlayerTrackingText(
                      'goalPostsCoordinates',
                      currentLang,
                    ),
                    style: GoogleFonts.roboto(
                      color: AppColors.getTextColor(mode),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: constraints.maxWidth * 0.03),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _goalLeftXController,
                      decoration: InputDecoration(
                        labelText: Translations.getPlayerTrackingText(
                          'leftX',
                          currentLang,
                        ),
                        labelStyle: GoogleFonts.roboto(
                          color: AppColors.getTertiaryColor(seedColor, mode),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.getTertiaryColor(
                              seedColor,
                              mode,
                            ).withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.getTertiaryColor(
                              seedColor,
                              mode,
                            ).withOpacity(0.3),
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.getSurfaceColor(
                          mode,
                        ).withOpacity(0.6),
                      ),
                      style: GoogleFonts.roboto(
                        color: AppColors.getTextColor(mode),
                      ),
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
                          'leftY',
                          currentLang,
                        ),
                        labelStyle: GoogleFonts.roboto(
                          color: AppColors.getTertiaryColor(seedColor, mode),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.getTertiaryColor(
                              seedColor,
                              mode,
                            ).withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.getTertiaryColor(
                              seedColor,
                              mode,
                            ).withOpacity(0.3),
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.getSurfaceColor(
                          mode,
                        ).withOpacity(0.6),
                      ),
                      style: GoogleFonts.roboto(
                        color: AppColors.getTextColor(mode),
                      ),
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
                          'rightX',
                          currentLang,
                        ),
                        labelStyle: GoogleFonts.roboto(
                          color: AppColors.getTertiaryColor(seedColor, mode),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.getTertiaryColor(
                              seedColor,
                              mode,
                            ).withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.getTertiaryColor(
                              seedColor,
                              mode,
                            ).withOpacity(0.3),
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.getSurfaceColor(
                          mode,
                        ).withOpacity(0.6),
                      ),
                      style: GoogleFonts.roboto(color: AppColors.getTextColor(mode)), // إضافة الـ style المفقود
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
                          'rightY',
                          currentLang,
                        ),
                        labelStyle: GoogleFonts.roboto(
                          color: AppColors.getTertiaryColor(seedColor, mode),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.getTertiaryColor(
                              seedColor,
                              mode,
                            ).withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.getTertiaryColor(
                              seedColor,
                              mode,
                            ).withOpacity(0.3),
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.getSurfaceColor(
                          mode,
                        ).withOpacity(0.6),
                      ),
                      style: GoogleFonts.roboto(
                        color: AppColors.getTextColor(mode),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter Y coordinate' : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: constraints.maxWidth * 0.04),
              SwitchListTile(
                secondary: Text('🚩', style: GoogleFonts.roboto(fontSize: 20)),
                title: Text(
                  Translations.getPlayerTrackingText('enableOffsideDetection', currentLang),
                  style: GoogleFonts.roboto(
                    color: AppColors.getTextColor(mode),
                    fontSize: 14,
                  ),
                ),
                value: _offsideEnabled,
                activeColor: AppColors.getTertiaryColor(seedColor, mode),
                onChanged: (val) => setState(() => _offsideEnabled = val),
              ),
              if (_offsideEnabled) ...[
                SizedBox(height: constraints.maxWidth * 0.03),
                _buildSectionHeader(
                  Translations.getPlayerTrackingText('offsideConfiguration', currentLang),
                  mode,
                  seedColor,
                ),
                SizedBox(height: constraints.maxWidth * 0.03),
                DropdownButtonFormField<String>(
                  value: _attackDirection,
                  decoration: InputDecoration(
                    labelText: Translations.getPlayerTrackingText('attackDirection', currentLang),
                    labelStyle: GoogleFonts.roboto(
                      color: AppColors.getTertiaryColor(seedColor, mode),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.3),
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.getSurfaceColor(mode).withOpacity(0.6),
                  ),
                  items: ['right', 'left', 'up', 'down']
                      .map((direction) => DropdownMenuItem(
                            value: direction,
                            child: Text(direction),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _attackDirection = value;
                      });
                    }
                  },
                ),
                SizedBox(height: constraints.maxWidth * 0.03),
                TextFormField(
                  controller: _attackingTeamController,
                  decoration: InputDecoration(
                    labelText: Translations.getPlayerTrackingText('attackingTeam', currentLang),
                    labelStyle: GoogleFonts.roboto(
                      color: AppColors.getTertiaryColor(seedColor, mode),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.3),
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.getSurfaceColor(mode).withOpacity(0.6),
                  ),
                  style: GoogleFonts.roboto(color: AppColors.getTextColor(mode)),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (!['A', 'B'].contains(value.toUpperCase())) {
                        return 'Must be A or B';
                      }
                    }
                    return null;
                  },
                ),
                SizedBox(height: constraints.maxWidth * 0.03),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _lineStartXController,
                        decoration: InputDecoration(
                          labelText: Translations.getPlayerTrackingText('lineStartX', currentLang),
                          labelStyle: GoogleFonts.roboto(
                            color: AppColors.getTertiaryColor(seedColor, mode),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.3),
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.getSurfaceColor(mode).withOpacity(0.6),
                        ),
                        style: GoogleFonts.roboto(color: AppColors.getTextColor(mode)),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'Enter X' : null,
                      ),
                    ),
                    SizedBox(width: constraints.maxWidth * 0.02),
                    Expanded(
                      child: TextFormField(
                        controller: _lineStartYController,
                        decoration: InputDecoration(
                          labelText: Translations.getPlayerTrackingText('lineStartY', currentLang),
                          labelStyle: GoogleFonts.roboto(
                            color: AppColors.getTertiaryColor(seedColor, mode),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.3),
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.getSurfaceColor(mode).withOpacity(0.6),
                        ),
                        style: GoogleFonts.roboto(color: AppColors.getTextColor(mode)),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'Enter Y' : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: constraints.maxWidth * 0.03),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _lineEndXController,
                        decoration: InputDecoration(
                          labelText: Translations.getPlayerTrackingText('lineEndX', currentLang),
                          labelStyle: GoogleFonts.roboto(
                            color: AppColors.getTertiaryColor(seedColor, mode),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.3),
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.getSurfaceColor(mode).withOpacity(0.6),
                        ),
                        style: GoogleFonts.roboto(color: AppColors.getTextColor(mode)),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'Enter X' : null,
                      ),
                    ),
                    SizedBox(width: constraints.maxWidth * 0.02),
                    Expanded(
                      child: TextFormField(
                        controller: _lineEndYController,
                        decoration: InputDecoration(
                          labelText: Translations.getPlayerTrackingText('lineEndY', currentLang),
                          labelStyle: GoogleFonts.roboto(
                            color: AppColors.getTertiaryColor(seedColor, mode),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.3),
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.getSurfaceColor(mode).withOpacity(0.6),
                        ),
                        style: GoogleFonts.roboto(color: AppColors.getTextColor(mode)),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'Enter Y' : null,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(
    AnalyzeResponse response,
    BoxConstraints constraints,
    String currentLang,
    int mode,
    Color seedColor,
  ) {
    final baseUrl = "https://tracking.varxpro.com";
    final goalAnalysis =
        response.summary['goal_analysis'] as List<dynamic>? ?? [];
    final offsideFrames = response.summary['offside_frames']?.toString() ?? '0';
    final offsidesTotal = response.summary['offsides_total']?.toString() ?? '0';

    return Card(
      color: AppColors.getSurfaceColor(mode).withOpacity(0.8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultItem(
              '📹 ${Translations.getPlayerTrackingText('framesProcessed', currentLang)}',
              response.frames.toString(),
              false,
              mode,
              seedColor,
            ),
            _buildResultItem(
              '👥 ${Translations.getPlayerTrackingText('playerCount', currentLang)}',
              response.summary['player_unique_count']?.toString() ?? '0',
              false,
              mode,
              seedColor,
            ),
            if (offsideFrames != '0') ...[
              _buildResultItem(
                '🚩 ${Translations.getPlayerTrackingText('offsideFrames', currentLang)}',
                offsideFrames,
                false,
                mode,
                seedColor,
              ),
              _buildResultItem(
                '🚩 ${Translations.getPlayerTrackingText('totalOffsides', currentLang)}',
                offsidesTotal,
                true,
                mode,
                seedColor,
              ),
            ],
            // Processed Video with Controls
            if (response.artifacts['video_url'] != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('▶️', style: GoogleFonts.roboto(fontSize: 20)),
                  const SizedBox(width: 4),
                  Text(
                    Translations.getPlayerTrackingText(
                      'processedVideo',
                      currentLang,
                    ),
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextColor(mode),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: Colors.black,
                      insetPadding: EdgeInsets.zero,
                      child: SizedBox(
                        width: double.maxFinite,
                        height: double.maxFinite,
                        child: ControlledVideoPlayer(
                          url: "$baseUrl${response.artifacts['video_url']}",
                        ),
                      ),
                    ),
                  );
                },
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * 0.95,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.getTertiaryColor(
                        seedColor,
                        mode,
                      ).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ControlledVideoPlayer(
                      url: "$baseUrl${response.artifacts['video_url']}",
                    ),
                  ),
                ),
              ),
            ],
            // Analysis Image
            if (response.artifacts['analysis_url'] != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('📊', style: GoogleFonts.roboto(fontSize: 20)),
                  const SizedBox(width: 4),
                  Text(
                    Translations.getPlayerTrackingText(
                      'analysisPlot',
                      currentLang,
                    ),
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextColor(mode),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.9,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.getTertiaryColor(
                      seedColor,
                      mode,
                    ).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          child: Image.network(
                            "$baseUrl${response.artifacts['analysis_url']}",
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    },
                    child: Image.network(
                      "$baseUrl${response.artifacts['analysis_url']}",
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: Text(
                          '❌ ${Translations.getPlayerTrackingText('failedToLoadImage', currentLang)}',
                          style: GoogleFonts.roboto(
                            color: Colors.red,
                            fontSize: 14,
                          ),
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
            // Goal Analysis Chart - محسن
            if (goalAnalysis.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('📈', style: GoogleFonts.roboto(fontSize: 20)),
                  const SizedBox(width: 4),
                  Text(
                    Translations.getPlayerTrackingText(
                      'metricsChart',
                      currentLang,
                    ),
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextColor(mode),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.9,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.getTertiaryColor(
                      seedColor,
                      mode,
                    ).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GestureDetector(
                    onTap: () {
                      // Full screen chart dialog
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          child: SizedBox(
                            width: double.maxFinite,
                            height: double.maxFinite,
                            child: GoalAnalysisChart(
                              goalAnalysis: goalAnalysis,
                            ),
                          ),
                        ),
                      );
                    },
                    child: GoalAnalysisChart(goalAnalysis: goalAnalysis),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(
    String label,
    String value,
    bool isOffside,
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
                color: AppColors.getTextColor(mode).withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.getTertiaryColor(
                  seedColor,
                  mode,
                ).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: GoogleFonts.roboto(
                  color: isOffside
                      ? Colors.redAccent
                      : AppColors.getTertiaryColor(seedColor, mode),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// New Controlled Video Player Widget with Pause/Replay
class ControlledVideoPlayer extends StatefulWidget {
  final String url;

  const ControlledVideoPlayer({super.key, required this.url});

  @override
  State<ControlledVideoPlayer> createState() => _ControlledVideoPlayerState();
}

class _ControlledVideoPlayerState extends State<ControlledVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() {});
        _controller.addListener(_onPlayerStateChanged);
      });
  }

  void _onPlayerStateChanged() {
    if (!mounted) return;
    setState(() {
      _isPlaying = _controller.value.isPlaying;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onPlayerStateChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modeProvider = Provider.of<ModeProvider>(context);
    final mode = modeProvider.currentMode;
    final seedColor = AppColors.seedColors[mode] ?? AppColors.seedColors[1]!;

    return Column(
      children: [
        if (_controller.value.isInitialized)
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        else
          const Center(child: CircularProgressIndicator()),
        if (_controller.value.isInitialized) ...[
          // Control bar under the video
          SizedBox(
            height: 60,
            child: Container(
              color: Colors.black54,
              child: Column(
                children: [
                  // Progress bar
                  Expanded(
                    child: VideoProgressIndicator(
                      _controller,
                      allowScrubbing: true,
                      colors: VideoProgressColors(
                        playedColor: AppColors.getTertiaryColor(seedColor, mode),
                        bufferedColor: AppColors.getSurfaceColor(mode),
                        backgroundColor: AppColors.getTextColor(mode).withOpacity(0.24),
                      ),
                    ),
                  ),
                  // Buttons row
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.replay, color: Colors.white, size: 24),
                          onPressed: () {
                            _controller.seekTo(const Duration());
                            setState(() {
                              _isPlaying = true;
                            });
                            _controller.play();
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPlaying = !_isPlaying;
                            });
                            if (_isPlaying) {
                              _controller.play();
                            } else {
                              _controller.pause();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// Goal Analysis Chart Widget - محسن
class GoalAnalysisChart extends StatelessWidget {
  final List<dynamic> goalAnalysis;

  const GoalAnalysisChart({super.key, required this.goalAnalysis});

  @override
  Widget build(BuildContext context) {
    final modeProvider = Provider.of<ModeProvider>(context);
    final mode = modeProvider.currentMode;
    final seedColor = AppColors.seedColors[mode] ?? AppColors.seedColors[1]!;

    List<FlSpot> spots = goalAnalysis
        .asMap()
        .entries
        .map(
          (entry) => FlSpot(
            entry.value['frame'].toDouble(),
            entry.value['open_percentage'].toDouble(),
          ),
        )
        .toList();

    return SizedBox(
      height: 300, // زيادة الارتفاع للوضوح
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 20,
            verticalInterval: 100,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.getTextColor(mode).withOpacity(0.2),
              strokeWidth: 1,
            ),
            getDrawingVerticalLine: (value) => FlLine(
              color: AppColors.getTextColor(mode).withOpacity(0.2),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: spots.isNotEmpty ? spots.last.x / 5 : 1,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}',
                  style: GoogleFonts.roboto(
                    fontSize: 10,
                    color: AppColors.getTextColor(mode),
                  ),
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 20,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}%',
                  style: GoogleFonts.roboto(
                    fontSize: 10,
                    color: AppColors.getTextColor(mode),
                  ),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: AppColors.getTextColor(mode).withOpacity(0.3)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.getTertiaryColor(seedColor, mode),
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.getTertiaryColor(seedColor, mode),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.getTertiaryColor(
                  seedColor,
                  mode,
                ).withOpacity(0.3),
              ),
            ),
          ],
          minX: 0,
          maxX: spots.isNotEmpty ? spots.last.x : 1,
          minY: 0,
          maxY: 100,
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
      if (board[i][0] == board[i][1] &&
          board[i][1] == board[i][2] &&
          board[i][0] != '') {
        return board[i][0];
      }
    }
    // Check columns
    for (int i = 0; i < 3; i++) {
      if (board[0][i] == board[1][i] &&
          board[1][i] == board[2][i] &&
          board[0][i] != '') {
        return board[0][i];
      }
    }
    // Check diagonals
    if (board[0][0] == board[1][1] &&
        board[1][1] == board[2][2] &&
        board[0][0] != '') {
      return board[0][0];
    }
    if (board[0][2] == board[1][1] &&
        board[1][1] == board[2][0] &&
        board[0][2] != '') {
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
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 16.0; // Add extra space for navbar

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const SizedBox(width: 4),
              Text(
                '🎮 ${Translations.getPlayerTrackingText('Tic-Tac-Toe', widget.currentLanguage)}',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextColor(modeProvider.currentMode),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                      color: AppColors.getTertiaryColor(
                        seedColor,
                        modeProvider.currentMode,
                      ).withOpacity(0.5),
                    ),
                    color: AppColors.getBackgroundColor(
                      modeProvider.currentMode,
                    ),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (winner == 'Draw')
                    Text(
                      '😑',
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        color: Colors.grey,
                      ),
                    )
                  else
                    Text(
                      winner == 'X' ? '😊' : '😠',
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        color: winner == 'X' ? Colors.green : Colors.red,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      winner == 'Draw'
                          ? '🤝 ${Translations.getPlayerTrackingText("It's a draw!", widget.currentLanguage)}'
                          : '$winner${Translations.getPlayerTrackingText(' wins!', widget.currentLanguage)} 🏆',
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTertiaryColor(
                          seedColor,
                          modeProvider.currentMode,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: resetGame,
                icon: Text('🔄', style: GoogleFonts.roboto(fontSize: 18)),
                label: Text(
                  '${Translations.getPlayerTrackingText('Reset Game', widget.currentLanguage)}',
                  style: GoogleFonts.roboto(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.getTertiaryColor(
                    seedColor,
                    modeProvider.currentMode,
                  ),
                  foregroundColor: AppColors.getTextColor(modeProvider.currentMode),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}