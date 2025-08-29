// lib/views/pages/FiledLinesPages/service/perspective_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:VarXPro/views/pages/FiledLinesPages/model/perspective_model.dart';

class PerspectiveService {
  static const String baseUrl = 'http://192.168.1.18:8001';

  final Dio _dio;

  PerspectiveService({String? baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? PerspectiveService.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        )) {
    _dio.interceptors.add(LogInterceptor(responseBody: true));
  }

  Future<HealthResponse> checkHealth() async {
    try {
      final response = await _dio.get('/health');
      return HealthResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to check health: $e');
    }
  }

  Future<DetectLinesResponse> detectLines(File image) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(image.path, filename: 'image.jpg'),
      });
      
      final response = await _dio.post(
        '/detect-lines', 
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      
      return DetectLinesResponse.fromJson(response.data as Map<String, dynamic>);
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
      final data = {
        'source_points': sourcePoints,
        'dst_width': dstWidth,
        'dst_height': dstHeight,
      };
      
      if (saveAs != null && saveAs.isNotEmpty) {
        data['save_as'] = saveAs;
      }
      
      final response = await _dio.post(
        '/set-calibration',
        data: data,
        options: Options(contentType: 'application/json'),
      );
      
      return CalibrationResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to set calibration: $e');
    }
  }

  Future<LoadCalibrationResponse> loadCalibrationByName(String name) async {
    try {
      final response = await _dio.post(
        '/load-calibration',
        data: {'name': name},
        options: Options(contentType: 'application/json'),
      );
      
      return LoadCalibrationResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load calibration: $e');
    }
  }

  Future<LoadCalibrationResponse> loadCalibrationByFile(File calibrationFile) async {
    try {
      final formData = FormData.fromMap({
        'calibration': await MultipartFile.fromFile(
          calibrationFile.path,
          filename: 'calibration.npz',
        ),
      });
      
      final response = await _dio.post(
        '/load-calibration', 
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      
      return LoadCalibrationResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load calibration file: $e');
    }
  }

  Future<TransformFrameResponse> transformFrame(File image) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(image.path, filename: 'image.jpg'),
      });
      
      final response = await _dio.post(
        '/transform-frame', 
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      
      return TransformFrameResponse.fromJson(response.data as Map<String, dynamic>);
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
    // Validate file size (e.g., max 100MB)
    final fileSize = await video.length();
    if (fileSize > 100 * 1024 * 1024) {
      throw Exception('Video file is too large (max 100MB)');
    }

    final formData = FormData.fromMap({
      'video': await MultipartFile.fromFile(
        video.path,
        filename: 'video.mp4',
      ),
      'overlay_lines': overlayLines ? '1' : '0',
      'codec': codec,
    });

    final response = await _dio.post(
      '/transform-video',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        receiveTimeout: const Duration(minutes: 5),
        sendTimeout: const Duration(minutes: 5),
      ),
      onSendProgress: (sent, total) {
        print('Upload progress: ${(sent / total * 100).toStringAsFixed(2)}%');
      },
    );

    return TransformVideoResponse.fromJson(response.data as Map<String, dynamic>);
  } catch (e) {
    throw Exception('Failed to transform video: $e');
  }
}

  Future<TransformPointResponse> transformPoint(double x, double y) async {
    try {
      final response = await _dio.post(
        '/transform-point',
        data: {'x': x, 'y': y},
        options: Options(contentType: 'application/json'),
      );
      
      return TransformPointResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to transform point: $e');
    }
  }

  Future<TransformPointResponse> inverseTransformPoint(double x, double y) async {
    try {
      final response = await _dio.post(
        '/inverse-transform-point',
        data: {'x': x, 'y': y},
        options: Options(contentType: 'application/json'),
      );
      
      return TransformPointResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to inverse transform point: $e');
    }
  }

  Future<CleanResponse> clean() async {
    try {
      final response = await _dio.post('/clean');
      return CleanResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to clean: $e');
    }
  }
}
