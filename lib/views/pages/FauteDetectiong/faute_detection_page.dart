import 'dart:io';
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/views/pages/FauteDetectiong/controller/foul_detection_controller.dart';
import 'package:VarXPro/views/pages/FauteDetectiong/view/csv_viewer.dart';
import 'package:VarXPro/views/pages/FauteDetectiong/view/pdf_viewer.dart';
import 'package:VarXPro/views/pages/FauteDetectiong/view/video_viewer.dart';
import 'package:VarXPro/views/setting/provider/history_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class RunData {
  final String run;
  final int? eventsCount;
  final bool? annotatedVideo;
  final bool? reportPdf;

  RunData({
    required this.run,
    this.eventsCount,
    this.annotatedVideo,
    this.reportPdf,
  });
}

class FoulDetectionPage extends StatefulWidget {
  const FoulDetectionPage({super.key});

  @override
  State<FoulDetectionPage> createState() => _FoulDetectionPageState();
}

class _FoulDetectionPageState extends State<FoulDetectionPage> with TickerProviderStateMixin {
  final FoulDetectionController _controller = FoulDetectionController();
  final ScrollController _scrollController = ScrollController();
  bool _showSplash = true;
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.linear),
    );
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
        _controller.pingServer();
        _controller.fetchRuns();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _pickAndAnalyzeVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video, allowMultiple: false);
    if (result != null && result.files.single.path != null) {
      await _controller.analyzeVideo(videoFile: File(result.files.single.path!));
      // Log to history on successful analysis
      if (_controller.result != null && _controller.result!.ok) {
        final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
        final langProvider = Provider.of<LanguageProvider>(context, listen: false);
        historyProvider.addHistoryItem('Foul Detection', 'Foul detection analysis completed');
      }
      setState(() {});
    }
  }

  void _openPreviousRunDialog(BuildContext context, String currentLang, int mode, Color seedColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        if (_controller.runs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Text(
              Translations.getFoulDetectionText('noRuns', currentLang),
              style: GoogleFonts.roboto(
                color: AppColors.getTextColor(mode),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }
        return Container(
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    Translations.getFoulDetectionText('previousRuns', currentLang),
                    style: GoogleFonts.roboto(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextColor(mode),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _controller.runs.length,
                    itemBuilder: (context, i) {
                      final run = _controller.runs[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.getSurfaceColor(mode).withOpacity(0.8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            title: Text(
                              run.run,
                              style: GoogleFonts.roboto(
                                color: AppColors.getTextColor(mode),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${Translations.getFoulDetectionText('events', currentLang)}: ${run.eventsCount ?? "N/A"}, '
                              '${Translations.getFoulDetectionText('video', currentLang)}: ${run.annotatedVideo == true ? Translations.getFoulDetectionText('yes', currentLang) : Translations.getFoulDetectionText('no', currentLang)}, '
                              '${Translations.getFoulDetectionText('pdf', currentLang)}: ${run.reportPdf == true ? Translations.getFoulDetectionText('yes', currentLang) : Translations.getFoulDetectionText('no', currentLang)}',
                              style: GoogleFonts.roboto(
                                color: AppColors.getTextColor(mode).withOpacity(0.7),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: ElevatedButton(
                              onPressed: () async {
                                Navigator.of(ctx).pop();
                                await _controller.loadPreviousRun(run.run);
                                setState(() {});
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.getSecondaryColor(seedColor, mode),
                                foregroundColor: AppColors.getTextColor(mode),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              child: Text(
                                Translations.getFoulDetectionText('open', currentLang),
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
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
          ),
        );
      },
    );
  }

  Widget _buildSummaryView(BuildContext context, String currentLang, int mode, Color seedColor) {
    final textPrimary = AppColors.getTextColor(mode);
    final textSecondary = AppColors.getTextColor(mode).withOpacity(0.7);
    final cardColor = AppColors.getSurfaceColor(mode);
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.all(isPortrait ? 16 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error Card
          if (_controller.error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: cardColor.withOpacity(0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${Translations.getFoulDetectionText('error', currentLang)}: ${_controller.error!}',
                        style: GoogleFonts.roboto(
                          color: Colors.redAccent,
                          fontSize: isPortrait ? 16 : 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        color: AppColors.getTertiaryColor(seedColor, mode),
                      ),
                      onPressed: () {
                        _controller.pingServer();
                        _controller.fetchRuns();
                      },
                    ),
                  ],
                ),
              ),
            ),
          // Upload and Open Previous Run Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _controller.isLoading ? null : _pickAndAnalyzeVideo,
                  icon: Icon(Icons.upload_file, color: textPrimary),
                  label: Text(
                    Translations.getFoulDetectionText('uploadAndAnalyze', currentLang),
                    style: GoogleFonts.roboto(
                      color: textPrimary,
                      fontSize: isPortrait ? 14 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.getSecondaryColor(seedColor, mode),
                    foregroundColor: textPrimary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _controller.isLoading ? null : () => _openPreviousRunDialog(context, currentLang, mode, seedColor),
                  icon: Icon(Icons.history, color: AppColors.getTertiaryColor(seedColor, mode)),
                  label: Text(
                    Translations.getFoulDetectionText('openPreviousRun', currentLang),
                    style: GoogleFonts.roboto(
                      color: AppColors.getTertiaryColor(seedColor, mode),
                      fontSize: isPortrait ? 14 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.getTertiaryColor(seedColor, mode),
                    side: BorderSide(color: AppColors.getTertiaryColor(seedColor, mode)),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Analysis Summary
          if (_controller.result != null && _controller.result!.ok)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: cardColor.withOpacity(0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Translations.getFoulDetectionText('analysisSummary', currentLang),
                      style: GoogleFonts.roboto(
                        fontSize: isPortrait ? 24 : 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_controller.result!.summary != null) ...[
                      _buildSummaryItem(
                        Translations.getFoulDetectionText('fps', currentLang),
                        _controller.result!.summary!.fps.toStringAsFixed(1),
                        mode,
                        seedColor,
                        isPortrait,
                      ),
                      _buildSummaryItem(
                        Translations.getFoulDetectionText('resolution', currentLang),
                        '${_controller.result!.summary!.width}x${_controller.result!.summary!.height}',
                        mode,
                        seedColor,
                        isPortrait,
                      ),
                      _buildSummaryItem(
                        Translations.getFoulDetectionText('totalFrames', currentLang),
                        _controller.result!.summary!.totalFrames.toString(),
                        mode,
                        seedColor,
                        isPortrait,
                      ),
                      _buildSummaryItem(
                        Translations.getFoulDetectionText('eventsDetected', currentLang),
                        _controller.result!.summary!.eventsCount.toString(),
                        mode,
                        seedColor,
                        isPortrait,
                      ),
                    ] else
                      Text(
                        Translations.getFoulDetectionText('summaryNotAvailable', currentLang),
                        style: GoogleFonts.roboto(
                          color: textSecondary,
                          fontSize: isPortrait ? 16 : 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          // Video Viewer
          Text(
            Translations.getFoulDetectionText('video', currentLang),
            style: GoogleFonts.roboto(
              fontSize: isPortrait ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: isPortrait ? 200 : 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _controller.cachedVideoFile != null || _controller.videoUrl != null
                ? VideoViewer(
                    videoUrl: _controller.videoUrl,
                    videoFile: _controller.cachedVideoFile,
                    mode: mode,
                    seedColor: seedColor,
                    currentLang: currentLang,
                  )
                : Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: cardColor.withOpacity(0.8),
                    ),
                    child: Center(
                      child: Text(
                        Translations.getFoulDetectionText('noVideoAvailable', currentLang),
                        style: GoogleFonts.roboto(
                          color: textSecondary,
                          fontSize: isPortrait ? 16 : 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          // CSV Viewer
          Text(
            Translations.getFoulDetectionText('csv', currentLang),
            style: GoogleFonts.roboto(
              fontSize: isPortrait ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: isPortrait ? 300 : 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _controller.csvData != null
                ? CsvViewer(
                    csvData: _controller.csvData!,
                    mode: mode,
                    seedColor: seedColor,
                    currentLang: currentLang,
                  )
                : Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: cardColor.withOpacity(0.8),
                    ),
                    child: Center(
                      child: Text(
                        Translations.getFoulDetectionText('noCsvAvailable', currentLang),
                        style: GoogleFonts.roboto(
                          color: textSecondary,
                          fontSize: isPortrait ? 16 : 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          // PDF Viewer
          Text(
            Translations.getFoulDetectionText('pdf', currentLang),
            style: GoogleFonts.roboto(
              fontSize: isPortrait ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: isPortrait ? 400 : 350,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _controller.pdfPath != null
                ? PdfViewer(
                    pdfPath: _controller.pdfPath!,
                    mode: mode,
                    seedColor: seedColor,
                    currentLang: currentLang,
                  )
                : Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: cardColor.withOpacity(0.8),
                    ),
                    child: Center(
                      child: Text(
                        Translations.getFoulDetectionText('noPdfAvailable', currentLang),
                        style: GoogleFonts.roboto(
                          color: textSecondary,
                          fontSize: isPortrait ? 16 : 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, int mode, Color seedColor, bool isPortrait) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.roboto(
              color: AppColors.getTextColor(mode).withOpacity(0.7),
              fontSize: isPortrait ? 16 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.roboto(
              color: AppColors.getTextColor(mode),
              fontSize: isPortrait ? 16 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modeProvider = Provider.of<ModeProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final currentLang = langProvider.currentLanguage;
    final seedColor = AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!;
    final mode = modeProvider.currentMode;

    if (_showSplash) {
      return Scaffold(
        backgroundColor: AppColors.getBackgroundColor(mode),
        body: Center(
          child: Lottie.asset(
            'assets/lotties/FoulDetection.json',
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.5,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(mode),
      body: Stack(
        children: [
          // Background Grid
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
          // Scan Line Animation
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _scanAnimation,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ScanLinePainter(
                    progress: _scanAnimation.value,
                    mode: mode,
                    seedColor: seedColor,
                  ),
                );
              },
            ),
          ),
          // Main Content
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return _controller.isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(AppColors.getLabelColor(seedColor, mode)),
                            strokeWidth: 4,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            Translations.getFoulDetectionText('loading', currentLang),
                            style: GoogleFonts.roboto(
                              color: AppColors.getTextColor(mode).withOpacity(0.7),
                              fontSize: MediaQuery.of(context).orientation == Orientation.portrait ? 16 : 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _buildSummaryView(context, currentLang, mode, seedColor);
            },
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