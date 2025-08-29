import 'dart:io';
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/views/pages/FauteDetectiong/controller/foul_detection_controller.dart';
import 'package:VarXPro/views/pages/FauteDetectiong/view/csv_viewer.dart';
import 'package:VarXPro/views/pages/FauteDetectiong/view/pdf_viewer.dart';
import 'package:VarXPro/views/pages/FauteDetectiong/view/video_viewer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart'; // Added Lottie package
import 'dart:async'; // Added for Timer

class FoulDetectionPage extends StatefulWidget {
  const FoulDetectionPage({super.key});

  @override
  State<FoulDetectionPage> createState() => _FoulDetectionPageState();
}

class _FoulDetectionPageState extends State<FoulDetectionPage> {
  final FoulDetectionController _controller = FoulDetectionController();
  int _selectedTab = 0;
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
        // Initialize controller actions after splash screen
        _controller.pingServer();
        _controller.fetchRuns();
      }
    });
  }

  Future<void> _pickAndAnalyzeVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video, allowMultiple: false);
    if (result != null && result.files.single.path != null) {
      await _controller.analyzeVideo(videoFile: File(result.files.single.path!));
      setState(() {
        _selectedTab = 0;
      });
    }
  }

  void _openPreviousRunDialog(BuildContext context, String currentLang, int mode, Color seedColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.getSurfaceColor(mode).withOpacity(0.9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        if (_controller.runs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              Translations.getFoulDetectionText('noRuns', currentLang),
              style: TextStyle(color: AppColors.getTextColor(mode)),
            ),
          );
        }
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  Translations.getFoulDetectionText('previousRuns', currentLang),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.getTextColor(mode),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _controller.runs.length,
                  itemBuilder: (context, i) {
                    final run = _controller.runs[i];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.getSurfaceColor(mode).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          run.run,
                          style: TextStyle(
                            color: AppColors.getTextColor(mode),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${Translations.getFoulDetectionText('events', currentLang)}: ${run.eventsCount ?? "N/A"}, '
                          '${Translations.getFoulDetectionText('video', currentLang)}: ${run.annotatedVideo == true ? Translations.getFoulDetectionText('yes', currentLang) : Translations.getFoulDetectionText('no', currentLang)}, '
                          '${Translations.getFoulDetectionText('pdf', currentLang)}: ${run.reportPdf == true ? Translations.getFoulDetectionText('yes', currentLang) : Translations.getFoulDetectionText('no', currentLang)}',
                          style: TextStyle(
                            color: AppColors.getTextColor(mode).withOpacity(0.7),
                          ),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await _controller.loadPreviousRun(run.run);
                            setState(() => _selectedTab = 0);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.getSecondaryColor(seedColor, mode),
                            foregroundColor: AppColors.getTextColor(mode),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            Translations.getFoulDetectionText('open', currentLang),
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryView(BuildContext context, String currentLang, int mode, Color seedColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.getBodyGradient(mode),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_controller.error != null)
              Card(
                color: AppColors.getSurfaceColor(mode).withOpacity(0.8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${Translations.getFoulDetectionText('error', currentLang)}: ${_controller.error!}',
                          style: TextStyle(
                            color: Colors.redAccent,
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _controller.isLoading ? null : _pickAndAnalyzeVideo,
                    icon: Icon(Icons.upload_file, color: AppColors.getTextColor(mode)),
                    label: Text(
                      Translations.getFoulDetectionText('uploadAndAnalyze', currentLang),
                      style: TextStyle(color: AppColors.getTextColor(mode)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.getSecondaryColor(seedColor, mode),
                      foregroundColor: AppColors.getTextColor(mode),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                      style: TextStyle(color: AppColors.getTertiaryColor(seedColor, mode)),
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
            if (_controller.result != null && _controller.result!.ok) ...[
              Card(
                color: AppColors.getSurfaceColor(mode).withOpacity(0.8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Translations.getFoulDetectionText('analysisSummary', currentLang),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextColor(mode),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_controller.result!.summary != null) ...[
                        _buildSummaryItem(Translations.getFoulDetectionText('fps', currentLang), _controller.result!.summary!.fps.toStringAsFixed(1), mode, seedColor),
                        _buildSummaryItem(Translations.getFoulDetectionText('resolution', currentLang), '${_controller.result!.summary!.width}x${_controller.result!.summary!.height}', mode, seedColor),
                        _buildSummaryItem(Translations.getFoulDetectionText('totalFrames', currentLang), _controller.result!.summary!.totalFrames.toString(), mode, seedColor),
                        _buildSummaryItem(Translations.getFoulDetectionText('eventsDetected', currentLang), _controller.result!.summary!.eventsCount.toString(), mode, seedColor),
                      ] else
                        Text(
                          Translations.getFoulDetectionText('summaryNotAvailable', currentLang),
                          style: TextStyle(color: AppColors.getTextColor(mode).withOpacity(0.7)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              Translations.getFoulDetectionText('previousRuns', currentLang),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextColor(mode),
              ),
            ),
            const SizedBox(height: 8),
            if (_controller.runs.isEmpty)
              Text(
                Translations.getFoulDetectionText('noRuns', currentLang),
                style: TextStyle(color: AppColors.getTextColor(mode).withOpacity(0.7)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _controller.runs.length,
                itemBuilder: (context, index) {
                  final run = _controller.runs[index];
                  return Card(
                    color: AppColors.getSurfaceColor(mode).withOpacity(0.8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        run.run,
                        style: TextStyle(
                          color: AppColors.getTextColor(mode),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${Translations.getFoulDetectionText('events', currentLang)}: ${run.eventsCount ?? "N/A"}, '
                        '${Translations.getFoulDetectionText('video', currentLang)}: ${run.annotatedVideo == true ? Translations.getFoulDetectionText('yes', currentLang) : Translations.getFoulDetectionText('no', currentLang)}, '
                        '${Translations.getFoulDetectionText('pdf', currentLang)}: ${run.reportPdf == true ? Translations.getFoulDetectionText('yes', currentLang) : Translations.getFoulDetectionText('no', currentLang)}',
                        style: TextStyle(
                          color: AppColors.getTextColor(mode).withOpacity(0.7),
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.open_in_new,
                          color: AppColors.getTertiaryColor(seedColor, mode),
                        ),
                        onPressed: () async {
                          await _controller.loadPreviousRun(run.run);
                          setState(() => _selectedTab = 0);
                        },
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

  Widget _buildSummaryItem(String label, String value, int mode, Color seedColor) {
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
          Text(
            value,
            style: TextStyle(
              color: AppColors.getTextColor(mode),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView(BuildContext context, String currentLang, int mode, Color seedColor) {
    if (_controller.isLoading) {
      return Container(
        decoration: BoxDecoration(
          gradient: AppColors.getBodyGradient(mode),
        ),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.getTertiaryColor(seedColor, mode)),
          ),
        ),
      );
    }
    switch (_selectedTab) {
      case 0:
        return _buildSummaryView(context, currentLang, mode, seedColor);
      case 1:
        return _controller.cachedVideoFile != null || _controller.videoUrl != null
            ? VideoViewer(videoUrl: _controller.videoUrl, videoFile: _controller.cachedVideoFile, mode: mode, seedColor: seedColor, currentLang: currentLang)
            : Container(
                decoration: BoxDecoration(
                  gradient: AppColors.getBodyGradient(mode),
                ),
                child: Center(
                  child: Text(
                    Translations.getFoulDetectionText('noVideoAvailable', currentLang),
                    style: TextStyle(color: AppColors.getTextColor(mode)),
                  ),
                ),
              );
      case 2:
        return _controller.csvData != null
            ? CsvViewer(csvData: _controller.csvData!, mode: mode, seedColor: seedColor, currentLang: currentLang)
            : Container(
                decoration: BoxDecoration(
                  gradient: AppColors.getBodyGradient(mode),
                ),
                child: Center(
                  child: Text(
                    Translations.getFoulDetectionText('noCsvAvailable', currentLang),
                    style: TextStyle(color: AppColors.getTextColor(mode)),
                  ),
                ),
              );
      case 3:
        return _controller.pdfPath != null
            ? PdfViewer(pdfPath: _controller.pdfPath!, mode: mode, seedColor: seedColor, currentLang: currentLang)
            : Container(
                decoration: BoxDecoration(
                  gradient: AppColors.getBodyGradient(mode),
                ),
                child: Center(
                  child: Text(
                    Translations.getFoulDetectionText('noPdfAvailable', currentLang),
                    style: TextStyle(color: AppColors.getTextColor(mode)),
                  ),
                ),
              );
      default:
        return _buildSummaryView(context, currentLang, mode, seedColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modeProvider = Provider.of<ModeProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final currentLang = langProvider.currentLanguage;
    final seedColor = AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!;

    // Show Lottie animation if splash screen is active
    if (_showSplash) {
      return Scaffold(
        backgroundColor: AppColors.getBackgroundColor(modeProvider.currentMode),
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

    // Main content after splash screen
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(modeProvider.currentMode),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => _buildCurrentView(context, currentLang, modeProvider.currentMode, seedColor),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.getSurfaceColor(modeProvider.currentMode),
          boxShadow: [
            BoxShadow(
              color: AppColors.getShadowColor(seedColor, modeProvider.currentMode),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          currentIndex: _selectedTab,
          onTap: (index) => setState(() => _selectedTab = index),
          selectedItemColor: AppColors.getTertiaryColor(seedColor, modeProvider.currentMode),
          unselectedItemColor: AppColors.getTextColor(modeProvider.currentMode).withOpacity(0.6),
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.info),
              label: Translations.getFoulDetectionText('summary', currentLang),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.video_file),
              label: Translations.getFoulDetectionText('video', currentLang),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.table_chart),
              label: Translations.getFoulDetectionText('csv', currentLang),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.picture_as_pdf),
              label: Translations.getFoulDetectionText('pdf', currentLang),
            ),
          ],
        ),
      ),
    );
  }
}