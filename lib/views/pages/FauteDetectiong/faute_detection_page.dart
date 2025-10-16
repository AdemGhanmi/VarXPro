import 'dart:io';
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/views/pages/FauteDetectiong/controller/foul_detection_controller.dart';
import 'package:VarXPro/views/pages/FauteDetectiong/view/pdf_viewer.dart';
import 'package:VarXPro/views/pages/FauteDetectiong/view/video_viewer.dart';
import 'package:VarXPro/views/setting/provider/history_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class FoulDetectionPage extends StatefulWidget {
  const FoulDetectionPage({super.key});

  @override
  State<FoulDetectionPage> createState() => _FoulDetectionPageState();
}

class _FoulDetectionPageState extends State<FoulDetectionPage> with TickerProviderStateMixin {
  final FoulDetectionController _controller = FoulDetectionController();
  final ScrollController _scrollController = ScrollController();
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
        _controller.pingServer();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

  Widget _buildSummaryView(BuildContext context, String currentLang, int mode, Color seedColor) {
    final textPrimary = AppColors.getTextColor(mode);
    final textSecondary = AppColors.getTextColor(mode).withOpacity(0.7);
    final cardColor = AppColors.getSurfaceColor(mode);
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.all(isPortrait ? 20 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error Card
          if (_controller.error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    cardColor.withOpacity(0.9),
                    cardColor.withOpacity(0.7),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.redAccent,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
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
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        color: AppColors.getTertiaryColor(seedColor, mode),
                        size: 24,
                      ),
                      onPressed: () {
                        _controller.pingServer();
                      },
                    ),
                  ],
                ),
              ),
            ),
          // Upload and Analyze Button
          Container(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _controller.isLoading ? null : _pickAndAnalyzeVideo,
              icon: Icon(Icons.upload_file, color: textPrimary, size: 20),
              label: Text(
                Translations.getFoulDetectionText('uploadAndAnalyze', currentLang),
                style: GoogleFonts.roboto(
                  color: textPrimary,
                  fontSize: isPortrait ? 16 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getSecondaryColor(seedColor, mode),
                foregroundColor: textPrimary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: AppColors.getSecondaryColor(seedColor, mode).withOpacity(0.3),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Analysis Summary
          if (_controller.result != null && _controller.result!.ok)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    cardColor.withOpacity(0.9),
                    cardColor.withOpacity(0.7),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          color: AppColors.getPrimaryColor(seedColor, mode),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          Translations.getFoulDetectionText('analysisSummary', currentLang),
                          style: GoogleFonts.roboto(
                            fontSize: isPortrait ? 24 : 20,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_controller.result!.summary != null) ...[
                      ...[
                        _buildSummaryItem(
                          Icons.speed,
                          Translations.getFoulDetectionText('fps', currentLang),
                          _controller.result!.summary!.fps.toStringAsFixed(1),
                          mode,
                          seedColor,
                          isPortrait,
                        ),
                        _buildSummaryItem(
                          Icons.aspect_ratio,
                          Translations.getFoulDetectionText('resolution', currentLang),
                          '${_controller.result!.summary!.width}x${_controller.result!.summary!.height}',
                          mode,
                          seedColor,
                          isPortrait,
                        ),
                        _buildSummaryItem(
                          Icons.layers,
                          Translations.getFoulDetectionText('totalFrames', currentLang),
                          _controller.result!.summary!.totalFrames.toString(),
                          mode,
                          seedColor,
                          isPortrait,
                        ),
                        _buildSummaryItem(
                          Icons.flag,
                          Translations.getFoulDetectionText('eventsDetected', currentLang),
                          _controller.result!.summary!.eventsCount.toString(),
                          mode,
                          seedColor,
                          isPortrait,
                        ),
                      ].expand((item) => [item, const SizedBox(height: 8)]).toList()..removeLast(),
                    ] else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: textSecondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          Translations.getFoulDetectionText('summaryNotAvailable', currentLang),
                          style: GoogleFonts.roboto(
                            color: textSecondary,
                            fontSize: isPortrait ? 16 : 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          // Video Viewer
          _buildSectionHeader(
            Icons.play_circle_outline,
            Translations.getFoulDetectionText('video', currentLang),
            textPrimary,
            isPortrait,
          ),
          const SizedBox(height: 12),
          Container(
            height: isPortrait ? 220 : 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  cardColor.withOpacity(0.9),
                  cardColor.withOpacity(0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
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
                      borderRadius: BorderRadius.circular(16),
                      color: cardColor.withOpacity(0.8),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.video_file_outlined,
                            size: 48,
                            color: textSecondary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            Translations.getFoulDetectionText('noVideoAvailable', currentLang),
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
          ),
          const SizedBox(height: 24),
          // PDF Viewer
          _buildSectionHeader(
            Icons.picture_as_pdf,
            Translations.getFoulDetectionText('pdf', currentLang),
            textPrimary,
            isPortrait,
          ),
          const SizedBox(height: 12),
          Container(
            height: isPortrait ? 420 : 360,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  cardColor.withOpacity(0.9),
                  cardColor.withOpacity(0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
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
                      borderRadius: BorderRadius.circular(16),
                      color: cardColor.withOpacity(0.8),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.picture_as_pdf_outlined,
                            size: 48,
                            color: textSecondary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            Translations.getFoulDetectionText('noPdfAvailable', currentLang),
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
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    IconData icon,
    String label,
    String value,
    int mode,
    Color seedColor,
    bool isPortrait,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getPrimaryColor(seedColor, mode).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.getPrimaryColor(seedColor, mode).withOpacity(0.6),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.roboto(
                    color: AppColors.getTextColor(mode).withOpacity(0.7),
                    fontSize: isPortrait ? 14 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
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
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, Color textColor, bool isPortrait) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.getSecondaryColor(AppColors.seedColors[1]!, 1).withOpacity(0.8),
          size: 28,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.roboto(
            fontSize: isPortrait ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: 0.5,
          ),
        ),
      ],
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
                          const SizedBox(height: 20),
                          Text(
                            Translations.getFoulDetectionText('loading', currentLang),
                            style: GoogleFonts.roboto(
                              color: AppColors.getTextColor(mode).withOpacity(0.7),
                              fontSize: MediaQuery.of(context).orientation == Orientation.portrait ? 18 : 16,
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