import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import '../model/offside_model.dart';

class OffsideService {
  late Dio _dio;

 OffsideService() {
  debugPrint('=== OffsideService constructor started ===');
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://offsidev3.varxpro.com',  
  );
  debugPrint('=== Raw baseUrl before trim: "${baseUrl}" (length: ${baseUrl.length}) ===');  
  final trimmedBaseUrl = baseUrl.trim();  
  debugPrint('=== Trimmed baseUrl: "${trimmedBaseUrl}" (length: ${trimmedBaseUrl.length}) ===');
  
  _dio = Dio(
    BaseOptions(
      baseUrl: trimmedBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 30),
      headers: {'Accept': 'application/json'},
    ),
  );
  debugPrint('=== OffsideService constructor completed, Dio baseUrl: ${trimmedBaseUrl} ===');
}
  Future<PingResponse> ping() async {
    debugPrint('=== Ping started ===');
    try {
      final resp = await _dio.get('/health',
          options: Options(receiveTimeout: const Duration(seconds: 10)));
      debugPrint('=== Ping response status: ${resp.statusCode}, data: ${resp.data} ===');
      if (resp.data is Map<String, dynamic>) {
        final result = PingResponse.fromJson(resp.data as Map<String, dynamic>);
        debugPrint('=== Ping result: ok=${result.ok}, model=${result.model}, opencv=${result.opencv} ===');
        return result;
      }
      final result = PingResponse(ok: false, model: '', opencv: '');
      debugPrint('=== Ping fallback result: $result ===');
      return result;
    } on DioException catch (e) {
      debugPrint('=== Ping DioException: type=${e.type}, message=${e.message}, response=${e.response?.data} ===');
      throw Exception('Ping failed: ${e.message}');
    } catch (e) {
      debugPrint('=== Ping general error: $e ===');
      rethrow;
    }
  }

  Future<OffsideFrameResponse> detectOffsideSingle({
    required File image,
    String attackDirection = 'right',
    List<int>? lineStart,
    List<int>? lineEnd,
    bool returnFile = false,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    debugPrint('=== detectOffsideSingle started: image=${image.path}, attackDirection=$attackDirection, lineStart=$lineStart, lineEnd=$lineEnd, returnFile=$returnFile ===');
    final offsideParams = <String, dynamic>{
      'enable': true,
      'use_ball_for_line': true,
      'enforce_active_play': false,
      'active_play_speed_thresh': 15,
      'frame_line_mode': 'perspective',
      'line_color': '#FF3030',
      'direction': attackDirection,
    };

    if (lineStart != null && lineEnd != null) {
      offsideParams['line_mode'] = 'fixed';
      offsideParams['line_start_x'] = lineStart[0];
      offsideParams['line_start_y'] = lineStart[1];
      offsideParams['line_end_x'] = lineEnd[0];
      offsideParams['line_end_y'] = lineEnd[1];
      debugPrint('=== Fixed line params added: $offsideParams ===');
    }

    final paramsMap = <String, dynamic>{
      'auto_team_colors': true,
      'offside': offsideParams,
      'player_conf': 0.30,
      'save_output': true,
      'return_file': returnFile,
      'include_map': false,
    };
    debugPrint('=== Full params map: $paramsMap ===');

    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(image.path, filename: 'frame.jpg'),
      'params': jsonEncode(paramsMap),
    });
    debugPrint('=== FormData prepared, sending POST to /predict/image ===');

    final resp = await _dio.post(
      '/predict/image',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        receiveTimeout: const Duration(minutes: 5),
        responseType: returnFile ? ResponseType.bytes : ResponseType.json,
      ),
      cancelToken: cancelToken,
      onSendProgress: (sent, total) {
        debugPrint('=== Image upload progress: $sent / $total ===');
        onSendProgress?.call(sent, total);
      },
      onReceiveProgress: (received, total) {
        debugPrint('=== Image download progress: $received / $total ===');
        onReceiveProgress?.call(received, total);
      },
    );

    debugPrint('=== Image response status: ${resp.statusCode}, data type: ${resp.data.runtimeType}, data: ${resp.data} ===');
    if (resp.data is! Map<String, dynamic>) {
      debugPrint('=== Unexpected image response type: ${resp.data.runtimeType} ===');
      throw Exception('Unexpected image response type: ${resp.data.runtimeType}');
    }
    final data = resp.data as Map<String, dynamic>;
    final outputPath = (data['output_path'] ?? '') as String;
    final meta = (data['meta'] ?? {}) as Map<String, dynamic>;
    final String fullImageUrl = _dio.options.baseUrl + outputPath.substring(1);
    debugPrint('=== Image outputPath: $outputPath, fullUrl: $fullImageUrl, meta: $meta ===');
    final result = OffsideFrameResponse.fromJson(meta, annotatedImageUrl: fullImageUrl);
    debugPrint('=== Image detection result: $result ===');
    return result;
  }

  Future<OffsideVideoResponse> detectOffsideVideo({
    required File video,
    String attackDirection = 'right',
    List<int>? lineStart,
    List<int>? lineEnd,
    bool returnFile = false,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    debugPrint('=== detectOffsideVideo started: video=${video.path}, attackDirection=$attackDirection, lineStart=$lineStart, lineEnd=$lineEnd, returnFile=$returnFile ===');
    final offsideParams = <String, dynamic>{
      'enable': true,
      'use_ball_for_line': true,
      'enforce_active_play': false,
      'active_play_speed_thresh': 15,
      'frame_line_mode': 'perspective',
      'direction': attackDirection,
    };

    if (lineStart != null && lineEnd != null) {
      offsideParams['line_mode'] = 'fixed';
      offsideParams['line_start_x'] = lineStart[0];
      offsideParams['line_start_y'] = lineStart[1];
      offsideParams['line_end_x'] = lineEnd[0];
      offsideParams['line_end_y'] = lineEnd[1];
      debugPrint('=== Fixed line params added: $offsideParams ===');
    }

    final paramsMap = <String, dynamic>{
      'auto_team_colors': true,
      'offside': offsideParams,
      'player_conf': 0.30,
      'return_file': returnFile,
      'include_map': false,
      'save_output': true,
    };
    debugPrint('=== Full params map: $paramsMap ===');

    final formData = FormData.fromMap({
      'video': await MultipartFile.fromFile(video.path, filename: 'video.mp4'),
      'params': jsonEncode(paramsMap),
    });
    debugPrint('=== FormData prepared, sending POST to /predict/video ===');

    final resp = await _dio.post(
      '/predict/video',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        receiveTimeout: const Duration(minutes: 30),
        responseType: returnFile ? ResponseType.bytes : ResponseType.json,
      ),
      cancelToken: cancelToken,
      onSendProgress: (sent, total) {
        debugPrint('=== Video upload progress: $sent / $total ===');
        onSendProgress?.call(sent, total);
      },
      onReceiveProgress: (received, total) {
        debugPrint('=== Video download progress: $received / $total ===');
        onReceiveProgress?.call(received, total);
      },
    );

    debugPrint('=== Video response status: ${resp.statusCode}, data type: ${resp.data.runtimeType}, data: ${resp.data} ===');
    if (resp.data is! Map<String, dynamic>) {
      debugPrint('=== Unexpected video response type: ${resp.data.runtimeType} ===');
      throw Exception('Unexpected video response type: ${resp.data.runtimeType}');
    }
    final data = resp.data as Map<String, dynamic>;
    final outputPath = (data['output_path'] ?? '') as String;
    final meta = (data['meta'] ?? {}) as Map<String, dynamic>;
    final String fullVideoUrl = _dio.options.baseUrl + outputPath.substring(1);
    debugPrint('=== Video outputPath: $outputPath, fullUrl: $fullVideoUrl, meta: $meta ===');
    final result = OffsideVideoResponse.fromJson(meta, annotatedVideoUrl: fullVideoUrl);
    debugPrint('=== Video detection result: $result ===');
    return result;
  }
}