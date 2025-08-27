import 'dart:io';
import 'package:VarXPro/views/pages/FauteDetectiong/controller/foul_detection_controller.dart';
import 'package:VarXPro/views/pages/FauteDetectiong/view/csv_viewer.dart';
import 'package:VarXPro/views/pages/FauteDetectiong/view/pdf_viewer.dart';
import 'package:VarXPro/views/pages/FauteDetectiong/view/video_viewer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class FoulDetectionPage extends StatefulWidget {
  const FoulDetectionPage({super.key});

  @override
  State<FoulDetectionPage> createState() => _FoulDetectionPageState();
}

class _FoulDetectionPageState extends State<FoulDetectionPage> {
  final FoulDetectionController _controller = FoulDetectionController();
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _controller.pingServer();
    _controller.fetchRuns();
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

  void _openPreviousRunDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D2B59).withOpacity(0.9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        if (_controller.runs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'No previous runs found.',
              style: TextStyle(color: Colors.white),
            ),
          );
        }
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Previous Runs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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
                        color: const Color(0xFF0A1B33),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          run.run,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Events: ${run.eventsCount ?? "N/A"}, '
                          'Video: ${run.annotatedVideo == true ? "Yes" : "No"}, '
                          'PDF: ${run.reportPdf == true ? "Yes" : "No"}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await _controller.loadPreviousRun(run.run);
                            setState(() => _selectedTab = 0);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF11FFB2),
                            foregroundColor: const Color(0xFF0A1B33),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Open',
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

  Widget _buildSummaryView() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF071628),
            Color(0xFF0D2B59),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_controller.error != null)
              Card(
                color: const Color(0xFF0D2B59).withOpacity(0.8),
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
                          _controller.error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.refresh,
                          color: const Color(0xFF11FFB2),
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
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload & Analyze'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF11FFB2),
                      foregroundColor: const Color(0xFF0A1B33),
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
                    onPressed: _controller.isLoading ? null : _openPreviousRunDialog,
                    icon: const Icon(Icons.history),
                    label: const Text('Open Previous Run'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF11FFB2),
                      side: const BorderSide(color: Color(0xFF11FFB2)),
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
                color: const Color(0xFF0D2B59).withOpacity(0.8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Analysis Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_controller.result!.summary != null) ...[
                        _buildSummaryItem('FPS', _controller.result!.summary!.fps.toStringAsFixed(1)),
                        _buildSummaryItem('Resolution', '${_controller.result!.summary!.width}x${_controller.result!.summary!.height}'),
                        _buildSummaryItem('Total Frames', _controller.result!.summary!.totalFrames.toString()),
                        _buildSummaryItem('Events Detected', _controller.result!.summary!.eventsCount.toString()),
                      ] else
                        const Text(
                          'Summary not available for this run',
                          style: TextStyle(color: Colors.white70),
                        ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Text(
              'Previous Runs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            if (_controller.runs.isEmpty)
              const Text(
                'No previous runs found.',
                style: TextStyle(color: Colors.white70),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _controller.runs.length,
                itemBuilder: (context, index) {
                  final run = _controller.runs[index];
                  return Card(
                    color: const Color(0xFF0D2B59).withOpacity(0.8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        run.run,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Events: ${run.eventsCount ?? "N/A"}, '
                        'Video: ${run.annotatedVideo == true ? "Yes" : "No"}, '
                        'PDF: ${run.reportPdf == true ? "Yes" : "No"}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.open_in_new,
                          color: const Color(0xFF11FFB2),
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

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    if (_controller.isLoading) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF071628),
              Color(0xFF0D2B59),
            ],
          ),
        ),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFF11FFB2)),
          ),
        ),
      );
    }
    switch (_selectedTab) {
      case 0:
        return _buildSummaryView();
      case 1:
        return _controller.cachedVideoFile != null || _controller.videoUrl != null
            ? VideoViewer(videoUrl: _controller.videoUrl, videoFile: _controller.cachedVideoFile)
            : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF071628),
                      Color(0xFF0D2B59),
                    ],
                  ),
                ),
                child: const Center(
                  child: Text(
                    'No video available',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
      case 2:
        return _controller.csvData != null
            ? CsvViewer(csvData: _controller.csvData!)
            : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF071628),
                      Color(0xFF0D2B59),
                    ],
                  ),
                ),
                child: const Center(
                  child: Text(
                    'No CSV data available',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
      case 3:
        return _controller.pdfPath != null
            ? PdfViewer(pdfPath: _controller.pdfPath!)
            : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF071628),
                      Color(0xFF0D2B59),
                    ],
                  ),
                ),
                child: const Center(
                  child: Text(
                    'No PDF available',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
      default:
        return _buildSummaryView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1B33),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => _buildCurrentView(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D2B59),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          currentIndex: _selectedTab,
          onTap: (index) => setState(() => _selectedTab = index),
          selectedItemColor: const Color(0xFF11FFB2),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.info),
              label: 'Summary',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.video_file),
              label: 'Video',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.table_chart),
              label: 'CSV',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.picture_as_pdf),
              label: 'PDF',
            ),
          ],
        ),
      ),
    );
  }
}