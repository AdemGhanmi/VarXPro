import 'dart:io';
import 'package:VarXPro/views/pages/FauteDetectiong/service/FoulDetectionService.dart';
import 'package:flutter/material.dart';
import '../model/foul_detection.dart';

class FoulDetectionController extends ChangeNotifier {
  final FoulDetectionService _service = FoulDetectionService();

  AnalysisResult? _result;
  String? _version;
  bool _isLoading = false;
  String? _error;
  String? _imageUrl;
  File? _inputVideoFile;

  // getters
  AnalysisResult? get result => _result;
  String? get version => _version;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get imageUrl => _imageUrl;
  File? get inputVideoFile => _inputVideoFile;

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

  Future<void> fetchVersion() async {
    try {
      final response = await _service.getVersion();
      _version = response['version']?.toString();
      notifyListeners();
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> analyzeVideo({File? videoFile, String? videoPath, String? refereeDecision}) async {
    _isLoading = true;
    _error = null;
    _result = null;
    _imageUrl = null;
    _inputVideoFile = videoFile;
    notifyListeners();

    try {
      _result = await _service.analyzeVideo(
        videoFile: videoFile,
        videoPath: videoPath,
        refereeDecision: refereeDecision,
      );

      if (!(_result?.ok ?? false)) {
        _error = _result?.error ?? 'Unknown error occurred';
      } else {
        // Snapshot image URL (prepend base if relative)
        if (_result!.inference?.snapshotPath != null) {
          _imageUrl = 'https://offsidev4.varxpro.com${_result!.inference!.snapshotPath}';
        }
      }
    } catch (e) {
      _error = 'Analysis failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearData() {
    _imageUrl = null;
    _inputVideoFile = null;
    notifyListeners();
  }
}