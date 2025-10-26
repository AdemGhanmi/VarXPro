///// views/pages/RefereeTraking/referee_tracking_system_page.dart
import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'dart:ui';
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/views/pages/FauteDetectiong/view/pdf_viewer.dart';
import 'package:VarXPro/views/pages/RefereeTraking/controller/referee_controller.dart';
import 'package:VarXPro/views/pages/RefereeTraking/model/referee_analysis.dart';
import 'package:VarXPro/views/pages/RefereeTraking/service/referee_api_service.dart';
import 'package:VarXPro/views/pages/RefereeTraking/widgets/file_picker_widget.dart';
import 'package:VarXPro/views/pages/RefereeTraking/widgets/video_player_widget.dart';
import 'package:VarXPro/views/setting/provider/history_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

const String baseUrl = 'https://evalrefereemax.varxpro.com';

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

  late RefereeService _downloadService;

  @override
  void initState() {
    super.initState();

    _downloadService = RefereeService();

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

  void _evaluateDecisions(BuildContext innerContext) {
    if (_videoFile == null) {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      _showSnackBar(Translations.getTranslation('missingVideoFile', languageProvider.currentLanguage));
      return;
    }

    innerContext.read<RefereeBloc>().add(AnalyzeVideoEvent(
      video: _videoFile!,
    ));
  }

  Future<void> _saveVideo(AnalyzeResponse response) async {
    try {
      final fullUrl = response.videoUrl.startsWith('http') ? response.videoUrl : baseUrl + response.videoUrl;
      final localPath = await _downloadService.downloadFile(fullUrl);
      final success = await GallerySaver.saveVideo(localPath);
      if (success ?? false) {
        _showSnackBar(Translations.getTranslation('Video saved to gallery!', Provider.of<LanguageProvider>(context, listen: false).currentLanguage));
      } else {
        _showSnackBar(Translations.getTranslation('Failed to save video', Provider.of<LanguageProvider>(context, listen: false).currentLanguage));
      }
      await File(localPath).delete();
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  Future<void> _savePdf(AnalyzeResponse response) async {
    try {
      final fullUrl = response.reportUrl.startsWith('http') ? response.reportUrl : baseUrl + response.reportUrl;
      final localPath = await _downloadService.downloadFile(fullUrl);
      await Share.shareXFiles(
        [XFile(localPath)],
        text: Translations.getTranslation('Referee Evaluation Report', Provider.of<LanguageProvider>(context, listen: false).currentLanguage),
      );
      await File(localPath).delete();
    } catch (e) {
      _showSnackBar('Error: $e');
    }
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
        body: Center(
          child: Lottie.asset(
            'assets/lotties/refere.json',
            width: screenWidth * 0.8,
            height: screenHeight * 0.5,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    return BlocProvider(
      create: (context) => RefereeBloc(RefereeService()),
      child: Scaffold(
        backgroundColor: AppColors.getBackgroundColor(modeProvider.currentMode),
        appBar: _FancyAppBar(
          title: Translations.getTranslation('Referee Tracking System', languageProvider.currentLanguage),
          mode: modeProvider.currentMode,
          seedColor: seedColor,
          onBack: () => Navigator.pop(context),
        ),
        body: Stack(
          children: [
            // Fond animé + grille terrain
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.getBodyGradient(
                    modeProvider.currentMode,
                  ),
                ),
                child: CustomPaint(
                  painter: _FootballGridPainter(modeProvider.currentMode),
                ),
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
                          context.read<RefereeBloc>().add(AnalyzeVideoEvent(video: _videoFile!));
                        },
                      ),
                    ),
                  );
                }

                if (!state.isLoading &&
                    state.analyzeResponse != null &&
                    state.analyzeResponse!.ok &&
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
                final response = state.analyzeResponse;
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
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),

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
                                        title: Translations.getTranslation(
                                            'Selected Video Preview',
                                            languageProvider.currentLanguage),
                                        mode: modeProvider.currentMode,
                                      ),
                                      VideoPlayerWidget(
                                        videoSource: _videoFile!.path,
                                        isNetwork: false,
                                      ),
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
                                        onPressed: () => _evaluateDecisions(innerContext),
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
                          if (response != null && response.ok) ...[
                            const SizedBox(height: 20),

                            // Referee Evaluation
                            if (response.refereeEvaluation != null) ...[
                              _SectionTitle(
                                emoji: '📊',
                                title: Translations.getTranslation(
                                    'Referee Evaluation',
                                    languageProvider.currentLanguage),
                                mode: modeProvider.currentMode,
                              ),
                              _GlassCard(
                                mode: modeProvider.currentMode,
                                seedColor: seedColor,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _SubTitle(
                                      emoji: '🏆',
                                      title: '${Translations.getTranslation('Overall Score', languageProvider.currentLanguage)}: ${response.refereeEvaluation!.overallScore.toStringAsFixed(1)} - ${Translations.getTranslation('Grade', languageProvider.currentLanguage)}: ${response.refereeEvaluation!.grade}',
                                      mode: modeProvider.currentMode,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      response.refereeEvaluation!.notes['en'] ?? '',
                                      style: GoogleFonts.roboto(
                                        fontSize: 14,
                                        color: AppColors.getTextColor(modeProvider.currentMode).withOpacity(0.8),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      Translations.getTranslation(
                                          'Criteria Details',
                                          languageProvider.currentLanguage),
                                      style: GoogleFonts.roboto(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: DataTable(
                                        columns: [
                                          DataColumn(
                                            label: Text(
                                              Translations.getTranslation(
                                                  'Criterion',
                                                  languageProvider.currentLanguage),
                                              style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              Translations.getTranslation(
                                                  'Raw Value',
                                                  languageProvider.currentLanguage),
                                              style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              Translations.getTranslation(
                                                  'Score (%)',
                                                  languageProvider.currentLanguage),
                                              style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              Translations.getTranslation(
                                                  'Weight (%)',
                                                  languageProvider.currentLanguage),
                                              style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                        rows: response.refereeEvaluation!.criteria.map((criterion) => DataRow(cells: [
                                              DataCell(Text(
                                                criterion.label,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              )),
                                              DataCell(Text(
                                                criterion.rawValue?.toString() ?? 'N/A',
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              )),
                                              DataCell(Text(
                                                criterion.score != null ? '${(criterion.score! * 100).toStringAsFixed(1)}%' : 'N/A',
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              )),
                                              DataCell(Text(
                                                '${(criterion.weight * 100).toStringAsFixed(1)}%',
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              )),
                                            ])).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Metrics
                            _SectionTitle(
                              emoji: '📈',
                              title: Translations.getTranslation(
                                  'Performance Metrics',
                                  languageProvider.currentLanguage),
                              mode: modeProvider.currentMode,
                            ),
                            _GlassCard(
                              mode: modeProvider.currentMode,
                              seedColor: seedColor,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SubTitle(
                                    emoji: '🏃',
                                    title: Translations.getTranslation(
                                        'Referee Summary',
                                        languageProvider.currentLanguage),
                                    mode: modeProvider.currentMode,
                                  ),
                                  _KeyValueRow(
                                    mode: modeProvider.currentMode,
                                    label: Translations.getTranslation(
                                        'Total Distance',
                                        languageProvider.currentLanguage),
                                    value: '${response.metrics['referee_summary']?['total_distance_m']?.toStringAsFixed(2) ?? 'N/A'} m',
                                  ),
                                  _KeyValueRow(
                                    mode: modeProvider.currentMode,
                                    label: Translations.getTranslation(
                                        'Average Speed',
                                        languageProvider.currentLanguage),
                                    value: '${response.metrics['referee_summary']?['avg_speed_kmh']?.toStringAsFixed(1) ?? 'N/A'} km/h',
                                  ),
                                  _KeyValueRow(
                                    mode: modeProvider.currentMode,
                                    label: Translations.getTranslation(
                                        'Max Speed',
                                        languageProvider.currentLanguage),
                                    value: '${response.metrics['referee_summary']?['max_speed_kmh']?.toStringAsFixed(1) ?? 'N/A'} km/h',
                                  ),
                                  _KeyValueRow(
                                    mode: modeProvider.currentMode,
                                    label: Translations.getTranslation(
                                        'Avg Distance to Ball',
                                        languageProvider.currentLanguage),
                                    value: '${response.metrics['referee_summary']?['avg_ref_ball_distance_m']?.toStringAsFixed(2) ?? 'N/A'} m',
                                  ),
                                  _KeyValueRow(
                                    mode: modeProvider.currentMode,
                                    label: Translations.getTranslation(
                                        'Min Distance to Ball',
                                        languageProvider.currentLanguage),
                                    value: '${response.metrics['referee_summary']?['min_ref_ball_distance_m']?.toStringAsFixed(2) ?? 'N/A'} m',
                                  ),
                                  _KeyValueRow(
                                    mode: modeProvider.currentMode,
                                    label: Translations.getTranslation(
                                        'Sprint Count',
                                        languageProvider.currentLanguage),
                                    value: '${response.metrics['referee_summary']?['sprint_count_(>=25kmh_1s)'] ?? 0}',
                                  ),
                                  const SizedBox(height: 16),
                                  _SubTitle(
                                    emoji: '⚽',
                                    title: Translations.getTranslation(
                                        'Possession Summary',
                                        languageProvider.currentLanguage),
                                    mode: modeProvider.currentMode,
                                  ),
                                  _KeyValueRow(
                                    mode: modeProvider.currentMode,
                                    label: Translations.getTranslation(
                                        'Total Distance in Possession',
                                        languageProvider.currentLanguage),
                                    value: '${response.metrics['possession_summary']?['total_distance_while_in_possession_m']?.toStringAsFixed(2) ?? 'N/A'} m',
                                  ),
                                  _KeyValueRow(
                                    mode: modeProvider.currentMode,
                                    label: Translations.getTranslation(
                                        'Avg Speed in Possession',
                                        languageProvider.currentLanguage),
                                    value: '${response.metrics['possession_summary']?['avg_speed_kmh_while_in_possession']?.toStringAsFixed(1) ?? 'N/A'} km/h',
                                  ),
                                  _KeyValueRow(
                                    mode: modeProvider.currentMode,
                                    label: Translations.getTranslation(
                                        'Max Speed in Possession',
                                        languageProvider.currentLanguage),
                                    value: '${response.metrics['possession_summary']?['max_speed_kmh_while_in_possession']?.toStringAsFixed(1) ?? 'N/A'} km/h',
                                  ),
                                  _KeyValueRow(
                                    mode: modeProvider.currentMode,
                                    label: Translations.getTranslation(
                                        'Sprint Count in Possession',
                                        languageProvider.currentLanguage),
                                    value: '${response.metrics['possession_summary']?['sprint_count_while_in_possession'] ?? 0}',
                                  ),
                                  const SizedBox(height: 16),
                                  _SubTitle(
                                    emoji: '🏆',
                                    title: Translations.getTranslation(
                                        'Top Ball Carriers',
                                        languageProvider.currentLanguage),
                                    mode: modeProvider.currentMode,
                                  ),
                                  const SizedBox(height: 8),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columns: [
                                        DataColumn(
                                          label: Text(
                                            Translations.getTranslation(
                                                'Player ID',
                                                languageProvider.currentLanguage),
                                            style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            Translations.getTranslation(
                                                'Distance (m)',
                                                languageProvider.currentLanguage),
                                            style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            Translations.getTranslation(
                                                'Time(s)',
                                                languageProvider.currentLanguage),
                                            style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                      rows: (response.metrics['top_ball_carriers'] as List<dynamic>?)?.map((p) => DataRow(cells: [
                                            DataCell(Text(
                                              p['player_id'].toString(),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            )),
                                            DataCell(Text(
                                              p['distance_in_possession_m'].toStringAsFixed(2),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            )),
                                            DataCell(Text(
                                              p['possession_time_s'].toStringAsFixed(2),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            )),
                                          ])).toList() ?? [],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Downloads
                            _SectionTitle(
                              emoji: '⬇️',
                              title: Translations.getTranslation(
                                  'Downloads & Output',
                                  languageProvider.currentLanguage),
                              mode: modeProvider.currentMode,
                            ),
                            _GlassCard(
                              mode: modeProvider.currentMode,
                              seedColor: seedColor,
                              child: Column(
                                children: [
                                  // Processed Video
                                  _SubTitle(
                                    emoji: '🎥',
                                    title: Translations.getTranslation(
                                        'Processed Video',
                                        languageProvider.currentLanguage),
                                    mode: modeProvider.currentMode,
                                  ),
                                  VideoPlayerWidget(
                                    videoSource: response.videoUrl.startsWith('http') ? response.videoUrl : baseUrl + response.videoUrl,
                                    isNetwork: true,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.photo_library),
                                          label: Text(Translations.getTranslation(
                                              'Save Video to Gallery',
                                              languageProvider.currentLanguage)),
                                          onPressed: () => _saveVideo(response),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Report PDF
                                  _SubTitle(
                                    emoji: '📄',
                                    title: Translations.getTranslation(
                                        'Referee Evaluation Report',
                                        languageProvider.currentLanguage),
                                    mode: modeProvider.currentMode,
                                  ),
                                  FutureBuilder<String>(
                                    future: _downloadService.downloadFile(response.reportUrl.startsWith('http') ? response.reportUrl : baseUrl + response.reportUrl),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(child: CircularProgressIndicator());
                                      }
                                      if (snapshot.hasError || !snapshot.hasData) {
                                        return Text(Translations.getTranslation(
                                            'Failed to load PDF',
                                            languageProvider.currentLanguage));
                                      }
                                      final pdfPath = snapshot.data!;
                                      return Column(
                                        children: [
                                          Container(
                                            height: 300,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                            ),
                                            child: PdfViewer(
                                              pdfPath: pdfPath,
                                              mode: modeProvider.currentMode,
                                              seedColor: seedColor,
                                              currentLang: languageProvider.currentLanguage,
                                              document: PdfDocument.openFile(pdfPath),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  icon: const Icon(Icons.download),
                                                  label: Text(Translations.getTranslation(
                                                      'Save Report PDF',
                                                      languageProvider.currentLanguage)),
                                                  onPressed: () => _savePdf(response),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.blue,
                                                    foregroundColor: Colors.white,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ] else if (response != null && !response.ok) ...[
                            const SizedBox(height: 16),
                            _GlassCard(
                              mode: modeProvider.currentMode,
                              seedColor: seedColor,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  Translations.getTranslation(
                                      'Analysis failed. Please try again.',
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
    final bg = AppColors.getSurfaceColor(mode).withOpacity(0.5);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: padding ?? const EdgeInsets.all(16),
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
        child: child,
      ),
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