import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

import '../model/foul_detection.dart';

class FoulDetectionService {
  static const String _host = 'https://fouldetection.varxpro.com';
  static const String _baseApi = '$_host/api';

  Future<Map<String, dynamic>> ping() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseApi/ping'))
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<AnalysisResult> analyzeVideo({
    File? videoFile,
    String? videoPath,
    bool saveVideo = true,
    int? maxFrames,
  }) async {
    if (videoFile == null && videoPath == null) {
      throw Exception('Either videoFile or videoPath must be provided');
    }

    try {
      if (videoFile != null) {
        final request = http.MultipartRequest('POST', Uri.parse('$_baseApi/analyze'))
          ..fields['save_video'] = saveVideo.toString()
          ..fields['max_frames'] = (maxFrames ?? '').toString()
          ..files.add(await http.MultipartFile.fromPath('file', videoFile.path));

        final streamed = await request.send().timeout(const Duration(minutes: 10));
        final response = await http.Response.fromStream(streamed);
        return AnalysisResult.fromJson(_handleResponse(response));
      } else {
        final response = await http
            .post(
              Uri.parse('$_baseApi/analyze'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'video_path': videoPath,
                'save_video': saveVideo,
                'max_frames': maxFrames,
              }),
            )
            .timeout(const Duration(minutes: 10));
        return AnalysisResult.fromJson(_handleResponse(response));
      }
    } catch (e) {
      throw Exception('Analysis request failed: $e');
    }
  }

  Future<List<Run>> listRuns() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseApi/runs'))
          .timeout(const Duration(seconds: 20));
      final json = _handleResponse(response);
      return (json['runs'] as List).map((r) => Run.fromJson(r)).toList();
    } catch (e) {
      throw Exception('Failed to fetch runs: $e');
    }
  }

  /// Load /api/files/<runFolder>/summary.json (the backend writes it after analyze)
  Future<RunSummaryJson> getRunSummary(String runFolder) async {
    final url = '$_baseApi/files/$runFolder/summary.json';
    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('summary.json not found for run: $runFolder');
    }
    final Map<String, dynamic> j = jsonDecode(utf8.decode(response.bodyBytes));
    return RunSummaryJson.fromJson(runFolder, j);
  }

  /// Build accessible file URLs based on summary.json content.
  RunFilesUrls buildRunFileUrlsFromSummary(String runFolder, RunSummaryJson s) {
    // Helper to compute relative path under /api/files
    String? _toFilesUrlFromAbs(String? absPath) {
      if (absPath == null) return null;
      // Normalize Windows backslashes to forward slashes for consistent URL handling
      absPath = absPath.replaceAll('\\', '/');
      // Backend serves only paths under /runs/ via /api/files/<rel>
      final idx = absPath.indexOf('runs/');
      if (idx < 0) return null;
      final rel = absPath.substring(idx + 'runs/'.length);
      return '$_baseApi/files/$rel';
    }

    // video: take basename if needed
    String? videoUrl = _toFilesUrlFromAbs(s.video);
    if (videoUrl == null) {
      // fallback: search default name pattern inside runFolder
      // we cannot list directory; assume only one mp4
      final guess = '$_baseApi/files/$runFolder/annotated.mp4';
      videoUrl = guess; // may 404 if not exists; caller will handle
    }

    final csvUrl = _toFilesUrlFromAbs(s.eventsCsv) ?? '$_baseApi/files/$runFolder/events.csv';
    final pdfUrl = _toFilesUrlFromAbs(s.reportPdf) ?? '$_baseApi/files/$runFolder/report.pdf';

    return RunFilesUrls(videoUrl: videoUrl, csvUrl: csvUrl, pdfUrl: pdfUrl);
  }

  Future<File> downloadFile(String url, String fileName) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(minutes: 2));
      if (response.statusCode != 200) {
        throw Exception('Failed to download file: ${response.statusCode}');
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } catch (e) {
      throw Exception('Download failed: $e');
    }
  }

  Future<List<List<dynamic>>> loadCsvData(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(minutes: 1));
      if (response.statusCode != 200) {
        throw Exception('Failed to download CSV: ${response.statusCode}');
      }
      final csvString = utf8.decode(response.bodyBytes);
      final csvData = const CsvToListConverter().convert(csvString);
      return csvData;
    } catch (e) {
      throw Exception('Failed to load CSV: $e');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    throw Exception('Request failed: ${response.statusCode} - ${response.body}');
  }
}