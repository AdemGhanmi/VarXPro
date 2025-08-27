import 'dart:io';
import 'package:VarXPro/views/pages/FauteDetectiong/service/FoulDetectionService.dart';
import 'package:flutter/material.dart';
import '../model/foul_detection.dart';

class FoulDetectionController extends ChangeNotifier {
  final FoulDetectionService _service = FoulDetectionService();

  AnalysisResult? _result;
  List<Run> _runs = [];
  bool _isLoading = false;
  String? _error;
  List<List<dynamic>>? _csvData;
  String? _videoUrl;
  String? _pdfPath; // local path
  File? _cachedVideoFile;

  // getters
  AnalysisResult? get result => _result;
  List<Run> get runs => _runs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<List<dynamic>>? get csvData => _csvData;
  String? get videoUrl => _videoUrl;
  String? get pdfPath => _pdfPath;
  File? get cachedVideoFile => _cachedVideoFile;

  Future<void> pingServer() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _service.ping();
      if (response['ok'] != true) _error = 'Server ping failed';
    } catch (e) {
      _error = 'Failed to ping server: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> analyzeVideo({File? videoFile, String? videoPath}) async {
    _isLoading = true;
    _error = null;
    _result = null;
    _csvData = null;
    _videoUrl = null;
    _pdfPath = null;
    _cachedVideoFile = null;
    notifyListeners();

    try {
      _result = await _service.analyzeVideo(
        videoFile: videoFile,
        videoPath: videoPath,
        saveVideo: true,
        maxFrames: 300,
      );

      if (!(_result?.ok ?? false)) {
        _error = _result?.error ?? 'Unknown error occurred';
      } else {
        // video
        _videoUrl = _result!.annotatedVideoUrl;
        if (_videoUrl != null) {
          _cachedVideoFile = await _service.downloadFile(_videoUrl!, 'annotated_video.mp4');
        }

        // csv
        if (_result!.eventsCsvUrl != null) {
          _csvData = await _service.loadCsvData(_result!.eventsCsvUrl!);
        }

        // pdf
        if (_result!.reportPdfUrl != null) {
          final file = await _service.downloadFile(_result!.reportPdfUrl!, 'report.pdf');
          _pdfPath = file.path;
        }
      }
    } catch (e) {
      _error = 'Analysis failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRuns() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _runs = await _service.listRuns();
    } catch (e) {
      _error = 'Failed to fetch runs: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load previous run by its folder name (from /api/runs).
  Future<void> loadPreviousRun(String runFolder) async {
    _isLoading = true;
    _error = null;
    _result = null;
    _csvData = null;
    _videoUrl = null;
    _pdfPath = null;
    _cachedVideoFile = null;
    notifyListeners();

    try {
      final summary = await _service.getRunSummary(runFolder);

      // Build file URLs from summary.json (server returns absolute paths; we rebuild /api/files/<rel>)
      final files = _service.buildRunFileUrlsFromSummary(runFolder, summary);

      // Video
      if (files.videoUrl != null) {
        _videoUrl = files.videoUrl;
        _cachedVideoFile = await _service.downloadFile(_videoUrl!, 'annotated_video_prev.mp4');
      }
      // CSV
      if (files.csvUrl != null) {
        _csvData = await _service.loadCsvData(files.csvUrl!);
      }
      // PDF
      if (files.pdfUrl != null) {
        final file = await _service.downloadFile(files.pdfUrl!, 'report_prev.pdf');
        _pdfPath = file.path;
      }

      // also expose minimal summary counts if available
      _result = AnalysisResult(
        ok: true,
        summary: summary.toSummary(),
        annotatedVideoUrl: files.videoUrl,
        eventsCsvUrl: files.csvUrl,
        reportPdfUrl: files.pdfUrl,
        snapshotsDir: summary.snapshotsDirRel,
        runDir: runFolder,
      );
    } catch (e) {
      _error = 'Failed to load previous run: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearData() {
    _csvData = null;
    _videoUrl = null;
    _pdfPath = null;
    _cachedVideoFile = null;
    notifyListeners();
  }
}
