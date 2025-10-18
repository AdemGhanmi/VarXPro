import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/views/pages/RefereeTraking/controller/referee_controller.dart';
import 'package:VarXPro/views/pages/RefereeTraking/service/referee_api_service.dart';
import 'package:VarXPro/views/pages/RefereeTraking/widgets/file_picker_widget.dart';
import 'package:VarXPro/views/pages/RefereeTraking/widgets/video_player_widget.dart';
import 'package:VarXPro/views/setting/provider/history_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

const String baseUrl = 'https://allvarx.varxpro.com';

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

  // New state for inputs
  File? _videoFile;
  File? _refLogFile;
  String? _decisionsJson;
  String _attack = 'left';
  String _attackingTeam = 'team1';
  String _inputMode = 'none'; // 'none', 'file' or 'inline'

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

    Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  void _evaluateDecisions() {
    if (_videoFile == null) {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      _showSnackBar(Translations.getTranslation('missingVideoFile', languageProvider.currentLanguage));
      return;
    }

    context.read<RefereeBloc>().add(AnalyzeVideoEvent(
      video: _videoFile!,
      attack: _attack,
      attacking_team: _attackingTeam,
      refLog: _inputMode == 'file' ? _refLogFile : null,
      decisionsJson: _inputMode == 'inline' ? _decisionsJson : null,
    ));
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modeProvider = Provider.of<ModeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    final seedColor =
        AppColors.seedColors[modeProvider.currentMode] ??
        AppColors.seedColors[1]!;

    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
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
              child: ScaleTransition(
                scale: _glowAnimation,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors
                          .getTertiaryColor(seedColor, modeProvider.currentMode)
                          .withOpacity(0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.getTertiaryColor(
                                seedColor, modeProvider.currentMode)
                            .withOpacity(0.25),
                        blurRadius: 28,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: Lottie.asset(
                    'assets/lotties/refere.json',
                    width: screenWidth * 0.7,
                    height: screenHeight * 0.4,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return BlocProvider(
      create: (context) => RefereeBloc(RefereeService())..add(CheckHealthEvent()),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: _FancyAppBar(
          title: Translations.getTranslation('Referee Tracking System', languageProvider.currentLanguage),
          mode: modeProvider.currentMode,
          seedColor: seedColor,
          onBack: () => Navigator.pop(context),
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

                  final historyProvider =
                      Provider.of<HistoryProvider>(context, listen: false);
                  historyProvider.addHistoryItem(
                      'Referee Tracking', Translations.getTranslation('Decision evaluation analysis completed', languageProvider.currentLanguage));

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Text('✅',
                              style: GoogleFonts.roboto(
                                  fontSize: 20, color: Colors.white)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              Translations.getTranslation(
                                  'Evaluation complete! View results.',
                                  languageProvider.currentLanguage),
                              style: GoogleFonts.roboto(color: Colors.white),
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
                  return SafeArea(
                    child: Center(
                      child: Directionality(
                        textDirection:
                            languageProvider.currentLanguage == 'ar'
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: isLargeScreen ? 24 : 16,
                            vertical: 12,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('⏳',
                                  style: GoogleFonts.roboto(
                                      fontSize: 60, color: Colors.orange)),
                              const SizedBox(height: 16),
                              _GlassCard(
                                mode: modeProvider.currentMode,
                                seedColor: seedColor,
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  children: [
                                    LinearProgressIndicator(
                                      minHeight: 6,
                                      valueColor: AlwaysStoppedAnimation(
                                        AppColors.getTertiaryColor(
                                          seedColor,
                                          modeProvider.currentMode,
                                        ),
                                      ),
                                      backgroundColor:
                                          Colors.white.withOpacity(0.12),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      Translations.getTranslation(
                                          'Evaluating referee decisions... This may take a few minutes.',
                                          languageProvider.currentLanguage),
                                      style: GoogleFonts.roboto(
                                        color: AppColors.getTextColor(
                                          modeProvider.currentMode,
                                        ),
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
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
                                width: isLargeScreen
                                    ? screenWidth * 0.6
                                    : screenWidth * 0.9,
                                child: TicTacToeGame(
                                  currentLanguage:
                                      languageProvider.currentLanguage,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return SafeArea(
                  child: Directionality(
                    textDirection: languageProvider.currentLanguage == 'ar'
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isLargeScreen ? 24 : 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),

                          // Health
                          _SectionTitle(
                            emoji: '🩺',
                            title: Translations.getTranslation(
                                'API Status',
                                languageProvider.currentLanguage),
                            mode: modeProvider.currentMode,
                          ),
                          _GlassCard(
                            mode: modeProvider.currentMode,
                            seedColor: seedColor,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _StatusDot(
                                      ok: state.health?.status == 'ok',
                                      color: state.health?.status == 'ok'
                                          ? AppColors.getTertiaryColor(
                                              seedColor,
                                              modeProvider.currentMode,
                                            )
                                          : Colors.redAccent,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      state.health?.status ??
                                          Translations.getTranslation(
                                              'Unknown',
                                              languageProvider
                                                  .currentLanguage),
                                      style: GoogleFonts.roboto(
                                        fontSize: 16,
                                        color: state.health?.status == 'ok'
                                            ? AppColors.getTertiaryColor(
                                                seedColor,
                                                modeProvider.currentMode,
                                              )
                                            : Colors.redAccent,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                _KeyValueRow(
                                  mode: modeProvider.currentMode,
                                  label: Translations.getTranslation(
                                      'Model Loaded: ',
                                      languageProvider.currentLanguage),
                                  value:
                                      '${state.health?.modelLoaded ?? false}',
                                ),
                                if (state.health?.classes != null)
                                  _KeyValueRow(
                                    mode: modeProvider.currentMode,
                                    label: Translations.getTranslation('Classes: ',
                                        languageProvider.currentLanguage),
                                    value: state.health!.classes!.values
                                        .join(", "),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Input Setup
                          _SectionTitle(
                            emoji: '⚙️',
                            title: Translations.getTranslation(
                                'Decision Evaluation Setup',
                                languageProvider.currentLanguage),
                            mode: modeProvider.currentMode,
                          ),
                          Builder(
                            builder: (innerContext) {
                              return _GlassCard(
                                mode: modeProvider.currentMode,
                                seedColor: seedColor,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Attack Direction
                                    _SubTitle(
                                      emoji: '⚔️',
                                      title: Translations.getTranslation(
                                          'Attack Direction',
                                          languageProvider.currentLanguage),
                                      mode: modeProvider.currentMode,
                                    ),
                                    DropdownButtonFormField<String>(
                                      value: _attack,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.1),
                                      ),
                                      items: ['left', 'right']
                                          .map((direction) => DropdownMenuItem(
                                                value: direction,
                                                child: Text(direction.toUpperCase()),
                                              ))
                                          .toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _attack = value;
                                          });
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 12),

                                    // Attacking Team
                                    _SubTitle(
                                      emoji: '👥',
                                      title: Translations.getTranslation(
                                          'Attacking Team',
                                          languageProvider.currentLanguage),
                                      mode: modeProvider.currentMode,
                                    ),
                                    DropdownButtonFormField<String>(
                                      value: _attackingTeam,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.1),
                                      ),
                                      items: ['team1', 'team2']
                                          .map((team) => DropdownMenuItem(
                                                value: team,
                                                child: Text(team.toUpperCase()),
                                              ))
                                          .toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _attackingTeam = value;
                                          });
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 12),

                                    // Decisions Input Mode
                                    _SubTitle(
                                      emoji: '📋',
                                      title: Translations.getTranslation(
                                          'Referee Decisions Input (Optional for AI-only analysis)',
                                          languageProvider.currentLanguage),
                                      mode: modeProvider.currentMode,
                                    ),
                                    RadioListTile<String>(
                                      title: Text(Translations.getTranslation(
                                          'No Referee Log (AI Events Only)',
                                          languageProvider.currentLanguage)),
                                      value: 'none',
                                      groupValue: _inputMode,
                                      onChanged: (value) {
                                        setState(() {
                                          _inputMode = value!;
                                          _refLogFile = null;
                                          _decisionsJson = null;
                                        });
                                      },
                                    ),
                                    RadioListTile<String>(
                                      title: Text(Translations.getTranslation(
                                          'Referee Log File (JSON)',
                                          languageProvider.currentLanguage)),
                                      value: 'file',
                                      groupValue: _inputMode,
                                      onChanged: (value) {
                                        setState(() {
                                          _inputMode = value!;
                                          _decisionsJson = null;
                                        });
                                      },
                                    ),
                                    RadioListTile<String>(
                                      title: Text(Translations.getTranslation(
                                          'Inline Decisions JSON',
                                          languageProvider.currentLanguage)),
                                      value: 'inline',
                                      groupValue: _inputMode,
                                      onChanged: (value) {
                                        setState(() {
                                          _inputMode = value!;
                                          _refLogFile = null;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    if (_inputMode == 'file')
                                      FilePickerWidget(
                                        onFilePicked: (file) {
                                          setState(() {
                                            _refLogFile = file;
                                          });
                                        },
                                        buttonText: Translations.getTranslation(
                                            'Pick Referee Log (JSON)',
                                            languageProvider.currentLanguage),
                                        allowedExtensions: const ['json'],
                                      )
                                    else if (_inputMode == 'inline')
                                      TextFormField(
                                        maxLines: 6,
                                        initialValue: _decisionsJson,
                                        decoration: InputDecoration(
                                          labelText: Translations.getTranslation(
                                              'Decisions JSON Array',
                                              languageProvider.currentLanguage),
                                          hintText:
                                              '[{"t":12.4,"type":"BallOut","decision":"throw-in"}, ...]',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white.withOpacity(0.1),
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _decisionsJson = value;
                                          });
                                        },
                                      ),
                                    const SizedBox(height: 12),

                                    // Video
                                    _SubTitle(
                                      emoji: '📹',
                                      title: Translations.getTranslation(
                                          'Match Video',
                                          languageProvider.currentLanguage),
                                      mode: modeProvider.currentMode,
                                    ),
                                    FilePickerWidget(
                                      onFilePicked: (file) {
                                        setState(() {
                                          _videoFile = file;
                                          _analysisCompleted = false;
                                        });
                                        innerContext.read<RefereeBloc>().add(AnalyzeVideoEvent(
                                          video: file,
                                          attack: _attack,
                                          attacking_team: _attackingTeam,
                                          refLog: _inputMode == 'file' ? _refLogFile : null,
                                          decisionsJson: _inputMode == 'inline' ? _decisionsJson : null,
                                        ));
                                      },
                                      buttonText: Translations.getTranslation(
                                          'Pick Match Video (MP4)',
                                          languageProvider.currentLanguage),
                                      allowedExtensions: const ['mp4'],
                                    ),
                                    if (_videoFile != null) ...[
                                      const SizedBox(height: 12),
                                      _SubTitle(
                                        emoji: '▶️',
                                        title: 'Selected Video Preview',
                                        mode: modeProvider.currentMode,
                                      ),
                                      VideoPlayerWidget(videoUrl: _videoFile!.path),
                                    ],
                                    const SizedBox(height: 10),
                                    Text(
                                      Translations.getTranslation(
                                          'Supported: MP4 • Referee log optional for full evaluation.',
                                          languageProvider.currentLanguage),
                                      style: GoogleFonts.roboto(
                                        fontSize: 12.5,
                                        color: AppColors.getTextColor(
                                          modeProvider.currentMode,
                                        ).withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () => _evaluateDecisions(),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.getTertiaryColor(
                                              seedColor, modeProvider.currentMode),
                                          foregroundColor: AppColors.getTextColor(
                                              modeProvider.currentMode),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding:
                                              const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        child: Text(
                                          '🚀 ${Translations.getTranslation('Analyze Video', languageProvider.currentLanguage)}',
                                          style: GoogleFonts.roboto(fontSize: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          // Results
                          if (state.analyzeResponse != null) ...[
                            const SizedBox(height: 16),
                           
                            if (state.analyzeResponse!.aiEvents.isEmpty)
                            
                              ...state.analyzeResponse!.aiEvents.map((event) =>
                                  Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _GlassCard(
                                  mode: modeProvider.currentMode,
                                  seedColor: seedColor,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '⏱️ ${event.t.toStringAsFixed(2)}s',
                                              style: GoogleFonts.roboto(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              event.type,
                                              style: GoogleFonts.roboto(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.getTertiaryColor(
                                                    seedColor,
                                                    modeProvider.currentMode),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          Translations.getTranslation('detailsEvent', languageProvider.currentLanguage) + ': ${jsonEncode(event.details)}',
                                          style: GoogleFonts.roboto(
                                            fontSize: 14,
                                            color: AppColors.getTextColor(
                                                modeProvider.currentMode)
                                                .withOpacity(0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )),

                            // Evaluation (only if provided)
                            if (state.analyzeResponse!.evaluation != null) ...[
                              const SizedBox(height: 16),

                              // Summary
                              _GlassCard(
                                mode: modeProvider.currentMode,
                                seedColor: seedColor,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _SubTitle(
                                      emoji: '📈',
                                      title: Translations.getTranslation('Evaluation Summary',
                                          languageProvider.currentLanguage),
                                      mode: modeProvider.currentMode,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildSummaryItem(
                                      '🎯 ${Translations.getTranslation('Accuracy', languageProvider.currentLanguage)}',
                                      '${(state.analyzeResponse!.evaluation!.accuracy * 100).toStringAsFixed(1)}%',
                                      modeProvider.currentMode,
                                      seedColor,
                                    ),
                                    _buildSummaryItem(
                                      '✅ ${Translations.getTranslation('Correct', languageProvider.currentLanguage)}',
                                      '${state.analyzeResponse!.evaluation!.correct} / ${state.analyzeResponse!.evaluation!.total}',
                                      modeProvider.currentMode,
                                      seedColor,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Per Decision
                              _SectionTitle(
                                emoji: '📋',
                                title: Translations.getTranslation(
                                    'Per Decision Details',
                                    languageProvider.currentLanguage),
                                mode: modeProvider.currentMode,
                              ),
                              _GlassCard(
                                mode: modeProvider.currentMode,
                                seedColor: seedColor,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columns: [
                                      DataColumn(
                                        label: Text(
                                          Translations.getTranslation(
                                              'Time (s)',
                                              languageProvider.currentLanguage),
                                          style: GoogleFonts.roboto(
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          Translations.getTranslation(
                                              'Type',
                                              languageProvider.currentLanguage),
                                          style: GoogleFonts.roboto(
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          Translations.getTranslation(
                                              'Decision',
                                              languageProvider.currentLanguage),
                                          style: GoogleFonts.roboto(
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          Translations.getTranslation(
                                              'Match',
                                              languageProvider.currentLanguage),
                                          style: GoogleFonts.roboto(
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                    rows: state.analyzeResponse!.evaluation!.perDecision
                                        .map((decision) => DataRow(cells: [
                                              DataCell(
                                                Text(decision.t.toStringAsFixed(2)),
                                              ),
                                              DataCell(
                                                Text(decision.type),
                                              ),
                                              DataCell(
                                                Text(decision.decision),
                                              ),
                                              DataCell(
                                                Icon(
                                                  decision.match
                                                      ? Icons.check_circle
                                                      : Icons.cancel,
                                                  color: decision.match
                                                      ? Colors.green
                                                      : Colors.red,
                                                ),
                                              ),
                                            ]))
                                        .toList(),
                                  ),
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 16),
                              _GlassCard(
                                mode: modeProvider.currentMode,
                                seedColor: seedColor,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    Translations.getTranslation(
                                        'No referee decisions provided. Only AI events are shown.',
                                        languageProvider.currentLanguage),
                                    style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      color: AppColors.getTextColor(
                                          modeProvider.currentMode),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],

                          const SizedBox(height: 24),
                        ],
                      ),
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
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.roboto(
                color: AppColors.getTextColor(mode).withOpacity(0.75),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.16),
                    AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.25),
                ),
              ),
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: GoogleFonts.roboto(
                  color: AppColors.getTextColor(mode),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==== Fancy AppBar ====
class _FancyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final int mode;
  final Color seedColor;
  final VoidCallback onBack;

  const _FancyAppBar({
    required this.title,
    required this.mode,
    required this.seedColor,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: onBack,
        icon: Icon(Icons.arrow_back,
            color: AppColors.getTextColor(mode), size: 22),
      ),
      title: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [
            AppColors.getTertiaryColor(seedColor, mode),
            AppColors.getPrimaryColor(seedColor, mode),
          ],
        ).createShader(bounds),
        child: Text(
          title,
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 6);
}

// ==== Small UI bits ====
class _SectionTitle extends StatelessWidget {
  final String emoji;
  final String title;
  final int mode;
  const _SectionTitle({
    required this.emoji,
    required this.title,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 2, right: 2),
      child: Row(
        children: [
          Text(emoji, style: GoogleFonts.roboto(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.getTextColor(mode),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubTitle extends StatelessWidget {
  final String emoji;
  final String title;
  final int mode;
  const _SubTitle({
    required this.emoji,
    required this.title,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: GoogleFonts.roboto(fontSize: 20)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w700,
              color: AppColors.getTextColor(mode),
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  final bool ok;
  final Color color;
  const _StatusDot({required this.ok, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12, height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final int mode;
  final Color seedColor;
  final EdgeInsetsGeometry? padding;

  const _GlassCard({
    required this.child,
    required this.mode,
    required this.seedColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(mode).withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.22),
        ),
        boxShadow: [
          BoxShadow(
            color:
                AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 3,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ==== Painters ====
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

// ==== Mini-Game ====
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

  bool isBoardFull() =>
      board.every((r) => r.every((c) => c != ''));

  void aiMove() {
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
    for (int i = 0; i < 3; i++) {
      if (board[i][0] == board[i][1] &&
          board[i][1] == board[i][2] &&
          board[i][0] != '') return board[i][0];
    }
    for (int i = 0; i < 3; i++) {
      if (board[0][i] == board[1][i] &&
          board[1][i] == board[2][i] &&
          board[0][i] != '') return board[0][i];
    }
    if (board[0][0] == board[1][1] &&
        board[1][1] == board[2][2] &&
        board[0][0] != '') return board[0][0];
    if (board[0][2] == board[1][1] &&
        board[1][1] == board[2][0] &&
        board[0][2] != '') return board[0][2];

    if (board.every((r) => r.every((c) => c != ''))) return 'Draw';
    return '';
  }

  bool checkWinner(int row, int col) {
    final player = board[row][col];
    if (board[row].every((c) => c == player)) return true;
    if (board.every((r) => r[col] == player)) return true;
    if (row == col &&
        board[0][0] == player &&
        board[1][1] == player &&
        board[2][2] == player) return true;
    if (row + col == 2 &&
        board[0][2] == player &&
        board[1][1] == player &&
        board[2][0] == player) return true;
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
          color: AppColors.getTertiaryColor(seedColor, modeProvider.currentMode)
              .withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '🎮 ${Translations.getTranslation('Tic-Tac-Toe', widget.currentLanguage)}',
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
            width: isLargeScreen ? 300 : screenWidth * 0.9,
            child: GridView.builder(
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
                        color: AppColors
                                .getTertiaryColor(seedColor, modeProvider.currentMode)
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
                    Text('😑',
                        style:
                            GoogleFonts.roboto(fontSize: 20, color: Colors.grey))
                  else
                    Text(
                      winner == 'X' ? '😊' : '😠',
                      style: GoogleFonts.roboto(
                          fontSize: 20,
                          color: winner == 'X' ? Colors.green : Colors.red),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      winner == 'Draw'
                          ? '🤝 ${Translations.getTranslation("It\'s a draw!", widget.currentLanguage)}'
                          : '$winner${Translations.getTranslation(' wins!', widget.currentLanguage)} 🏆',
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTertiaryColor(
                            seedColor, modeProvider.currentMode),
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
                Translations.getTranslation('Reset Game', widget.currentLanguage),
                style: GoogleFonts.roboto(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.getTertiaryColor(seedColor, modeProvider.currentMode),
                foregroundColor: AppColors.getTextColor(modeProvider.currentMode),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  final int mode;
  final String label;
  final String value;

  const _KeyValueRow({
    super.key,
    required this.mode,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: AppColors.getTextColor(mode).withOpacity(0.75),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.getTextColor(mode).withOpacity(0.15),
                ),
                color: AppColors.getSurfaceColor(mode).withOpacity(0.35),
              ),
              child: Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextColor(mode),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}