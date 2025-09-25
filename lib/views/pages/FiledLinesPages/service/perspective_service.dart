import 'dart:io';
import 'package:dio/dio.dart';
import 'package:VarXPro/views/pages/FiledLinesPages/model/perspective_model.dart';

class PerspectiveService {
  static const String defaultBaseUrl = 'http://192.168.1.18:8001';
  final Dio _dio;

  PerspectiveService({String? baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? defaultBaseUrl,
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
          validateStatus: (status) => status != null && status < 500,
        )) {
    _dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
  }

  Future<bool> isCalibrated() async {
    try {
      final response = await _dio.get('/health');
      final health = HealthResponse.fromJson(response.data as Map<String, dynamic>);
      return health.calibrated;
    } catch (e) {
      return false;
    }
  }

  Future<HealthResponse> checkHealth() async {
    try {
      final response = await _dio.get('/health');
      return HealthResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleDioError(e, 'check health');
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
      throw _handleDioError(e, 'detect lines');
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
        if (saveAs != null && saveAs.isNotEmpty) 'save_as': saveAs,
      };
      final response = await _dio.post(
        '/set-calibration',
        data: data,
        options: Options(contentType: 'application/json'),
      );
      return CalibrationResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleDioError(e, 'set calibration');
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
      throw _handleDioError(e, 'load calibration by name');
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
      throw _handleDioError(e, 'load calibration by file');
    }
  }

  Future<TransformFrameResponse> transformFrame(File image) async {
    if (!await isCalibrated()) {
      throw Exception('API not calibrated. Please set or load calibration first.');
    }
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
      throw _handleDioError(e, 'transform frame');
    }
  }

  Future<TransformVideoResponse> transformVideo(
    File video, {
    bool overlayLines = true,
    String codec = 'mp4v',
    Function(int, int)? onProgress,
  }) async {
    if (!await isCalibrated()) {
      throw Exception('API not calibrated. Please set or load calibration first.');
    }
    try {
      final fileSize = await video.length();
      if (fileSize > 100 * 1024 * 1024) {
        throw Exception('Video file is too large (max 100MB)');
      }
      final formData = FormData.fromMap({
        'video': await MultipartFile.fromFile(video.path, filename: 'video.mp4'),
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
        onSendProgress: onProgress,
      );
      return TransformVideoResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleDioError(e, 'transform video');
    }
  }

  Future<TransformPointResponse> transformPoint(double x, double y) async {
    if (!await isCalibrated()) {
      throw Exception('API not calibrated. Please set or load calibration first.');
    }
    try {
      final response = await _dio.post(
        '/transform-point',
        data: {'x': x, 'y': y},
        options: Options(contentType: 'application/json'),
      );
      return TransformPointResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleDioError(e, 'transform point');
    }
  }

  Future<TransformPointResponse> inverseTransformPoint(double x, double y) async {
    if (!await isCalibrated()) {
      throw Exception('API not calibrated. Please set or load calibration first.');
    }
    try {
      final response = await _dio.post(
        '/inverse-transform-point',
        data: {'x': x, 'y': y},
        options: Options(contentType: 'application/json'),
      );
      return TransformPointResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleDioError(e, 'inverse transform point');
    }
  }

  Future<CleanResponse> clean() async {
    try {
      final response = await _dio.post('/clean', options: Options(contentType: 'application/json'));
      return CleanResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleDioError(e, 'clean artifacts');
    }
  }

  Exception _handleDioError(dynamic e, String operation) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return Exception('Connection timeout during $operation. Please try again.');
      } else if (e.response?.statusCode == 400) {
        final data = e.response?.data as Map<String, dynamic>?;
        return Exception('Bad request during $operation: ${data?['error'] ?? 'Invalid input'}');
      } else if (e.response?.statusCode == 500) {
        final data = e.response?.data as Map<String, dynamic>?;
        return Exception('Server error during $operation: ${data?['error'] ?? 'Internal server error'}');
      } else if (e.type == DioExceptionType.connectionError) {
        return Exception('Network error during $operation. Please check your connection.');
      }
    }
    return Exception('Failed to $operation: ${e.toString()}');
  }
}