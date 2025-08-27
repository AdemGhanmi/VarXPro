// lib/views/pages/FiledLinesPages/service/perspective_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:VarXPro/views/pages/FiledLinesPages/model/perspective_model.dart';

class PerspectiveService {
  static const String baseUrl = 'http://192.168.1.18:8001';

  final Dio _dio;

  PerspectiveService({String? baseUrl})
      : _dio = Dio(BaseOptions(baseUrl: baseUrl ?? PerspectiveService.baseUrl));

  Future<HealthResponse> checkHealth() async {
    try {
      final response = await _dio.get('/health');
      return HealthResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to check health: $e');
    }
  }

  Future<DetectLinesResponse> detectLines(File image) async {
    try {
      if (!image.path.endsWith('.jpg') && !image.path.endsWith('.png')) {
        throw Exception('Only .jpg or .png images are supported');
      }
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(image.path, filename: 'image.jpg'),
      });
      final response = await _dio.post('/detect-lines', data: formData);
      return DetectLinesResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to detect lines: $e');
    }
  }

  Future<CalibrationResponse> setCalibration({
    required List<List<double>> sourcePoints,
    required int dstWidth,
    required int dstHeight,
    String? saveAs,
  }) async {
    try {
      final response = await _dio.post(
        '/set-calibration',
        data: {
          'source_points': sourcePoints,
          'dst_width': dstWidth,
          'dst_height': dstHeight,
          if (saveAs != null) 'save_as': saveAs,
        },
      );
      return CalibrationResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to set calibration: $e');
    }
  }

  Future<LoadCalibrationResponse> loadCalibrationByName(String name) async {
    try {
      final response = await _dio.post(
        '/load-calibration',
        data: {'name': name},
      );
      return LoadCalibrationResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load calibration: $e');
    }
  }

  Future<LoadCalibrationResponse> loadCalibrationByFile(File calibrationFile) async {
    try {
      if (!calibrationFile.path.endsWith('.npz')) {
        throw Exception('Calibration file must be .npz');
      }
      final formData = FormData.fromMap({
        'calibration': await MultipartFile.fromFile(
          calibrationFile.path,
          filename: 'calibration.npz',
        ),
      });
      final response = await _dio.post('/load-calibration', data: formData);
      return LoadCalibrationResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load calibration file: $e');
    }
  }

  Future<TransformFrameResponse> transformFrame(File image) async {
    try {
      if (!image.path.endsWith('.jpg') && !image.path.endsWith('.png')) {
        throw Exception('Only .jpg or .png images are supported');
      }
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(image.path, filename: 'image.jpg'),
      });
      final response = await _dio.post('/transform-frame', data: formData);
      return TransformFrameResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to transform frame: $e');
    }
  }

  Future<TransformVideoResponse> transformVideo(
    File video, {
    bool overlayLines = true,
    String codec = 'mp4v',
  }) async {
    try {
      if (!video.path.endsWith('.mp4')) {
        throw Exception('Only .mp4 videos are supported');
      }
      if (!['mp4v', 'h264'].contains(codec)) {
        throw Exception('Unsupported codec: $codec. Use mp4v or h264');
      }
      final formData = FormData.fromMap({
        'video': await MultipartFile.fromFile(video.path, filename: 'video.mp4'),
        'overlay_lines': overlayLines ? '1' : '0',
        'codec': codec,
      });
      final response = await _dio.post('/transform-video', data: formData);
      return TransformVideoResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to transform video: $e');
    }
  }

  Future<TransformPointResponse> transformPoint(double x, double y) async {
    try {
      final response = await _dio.post(
        '/transform-point',
        data: {'x': x, 'y': y},
      );
      return TransformPointResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to transform point: $e');
    }
  }

  Future<TransformPointResponse> inverseTransformPoint(double x, double y) async {
    try {
      final response = await _dio.post(
        '/inverse-transform-point',
        data: {'x': x, 'y': y},
      );
      return TransformPointResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to inverse transform point: $e');
    }
  }

  Future<CleanResponse> clean() async {
    try {
      final response = await _dio.post('/clean');
      return CleanResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to clean: $e');
    }
  }
}