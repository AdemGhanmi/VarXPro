// File: lib/views/pages/offsidePage/service/offside_service.dart
// No changes needed - parsing is correct, events are handled in model

import 'dart:io'; 
import 'dart:convert';
import 'package:VarXPro/views/pages/offsidePage/model/offside_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';


class OffsideService {
  late Dio _dio;

  OffsideService() {
    debugPrint('=== OffsideService ctor ===');
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://offsidev3.varxpro.com',
    );
    final trimmedBaseUrl = baseUrl.trim();
    final normalizedBase = trimmedBaseUrl.endsWith('/') ? trimmedBaseUrl : '$trimmedBaseUrl/';
    _dio = Dio(
      BaseOptions(
        baseUrl: normalizedBase,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 30),
        headers: {'Accept': 'application/json'},
      ),
    );
    debugPrint('=== Dio baseUrl: ${_dio.options.baseUrl} ===');
  }

  String _toAbsoluteUrl(String? pathOrUrl, {String? baseUrl}) {
    if (pathOrUrl == null || pathOrUrl.trim().isEmpty) return '';
    final s = pathOrUrl.trim();
    final parsed = Uri.tryParse(s);
    if (parsed != null && parsed.hasScheme) return s;
    String p = s;
    if (p.startsWith('./')) p = p.substring(2);
    if (p.startsWith('/')) p = p.substring(1);
    final base = Uri.parse(baseUrl ?? _dio.options.baseUrl);
    final resolved = base.resolve(p);
    return resolved.toString();
  }

  String _dioErrorToString(DioException e) {
    final sc = e.response?.statusCode;
    final sm = e.response?.statusMessage;
    final data = e.response?.data;
    final t = e.type;
    final msg = [
      if (sc != null) 'HTTP $sc',
      if (sm != null && sm.isNotEmpty) sm,
      t.name,
      if (data != null) 'body=${data is String ? data : jsonEncode(data)}',
    ].join(' | ');
    return msg.isEmpty ? e.toString() : msg;
  }

  bool _hasMeaningfulModels(Map<String, dynamic> data) {
    final models = (data['models'] as Map?)?.cast<String, dynamic>() ?? const {};
    final f2d = (models['field_2d'] as Map?)?.cast<String, dynamic>() ?? const {};
    final f3d = (models['field_3d'] as Map?)?.cast<String, dynamic>() ?? const {};

    bool has2d = false;
    if (f2d.isNotEmpty) {
      final players = (f2d['players'] as List?) ?? const [];
      final ball = f2d['ball'];
      final line = f2d['offside_line'];
      final pitch = (f2d['pitch'] as Map?)?['corners'] as List?;
      has2d = players.isNotEmpty || ball != null || line != null || (pitch != null && pitch.isNotEmpty);
    }

    bool has3d = false;
    if (f3d.isNotEmpty) {
      final players = (f3d['players'] as List?) ?? const [];
      final ball = f3d['ball'];
      final line = f3d['offside_line'];
      final pitch = (f3d['pitch'] as Map?)?['corners'] as List?;
      final hom = f3d['homography_available'] == true;
      has3d = players.isNotEmpty || ball != null || line != null || (pitch != null && pitch.isNotEmpty) || hom;
    }

    return has2d || has3d;
  }

  void _logModelSummary(String endpoint, Map<String, dynamic> data) {
    final models = (data['models'] as Map?)?.cast<String, dynamic>() ?? const {};
    final f2d = (models['field_2d'] as Map?)?.cast<String, dynamic>() ?? const {};
    final players = (f2d['players'] as List?) ?? const [];
    final ball = f2d['ball'] != null;
    final line = f2d['offside_line'] != null;
    debugPrint('→ Endpoint: $endpoint | Players: ${players.length} | Ball: $ball | Line: $line');
  }

  Future<PingResponse> ping() async {
    debugPrint('=== PING: GET /health ===');
    try {
      final resp = await _dio.get(
        '/health',
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );
      debugPrint('→ Status: ${resp.statusCode}');
      debugPrint('→ Response: ${resp.data}');
      if (resp.data is Map<String, dynamic>) {
        return PingResponse.fromJson(resp.data as Map<String, dynamic>);
      }
      return PingResponse(ok: false, model: '', opencv: '');
    } on DioException catch (e) {
      debugPrint('❌ Ping failed: ${_dioErrorToString(e)}');
      throw Exception('Ping failed: ${_dioErrorToString(e)}');
    }
  }

  Future<OffsideFrameResponse> _parseFrameResponse({
    required Map<String, dynamic> json,
    required Map<String, dynamic> metaMerge,
  }) async {
    final serverMeta = (json['meta'] as Map<String, dynamic>? ?? const {});
    final mergedMeta = {...serverMeta, ...metaMerge};
    final models = (json['models'] as Map<String, dynamic>? ?? const {});
    final fileUrl = _toAbsoluteUrl(json['file_url'] as String?);
    final image2DUrl = _toAbsoluteUrl(json['image_2d_url'] as String?);
    final image3DUrl = _toAbsoluteUrl(json['image_3d_url'] as String?);
    return OffsideFrameResponse.fromJson(
      mergedMeta,
      models: models,
      fileUrl: fileUrl,
      image2DUrl: image2DUrl,
      image3DUrl: image3DUrl,
    );
  }

  Future<OffsideFrameResponse> detectOffsideSingle({
    required File image,
    String attackDirection = 'right',
    List<int>? lineStart,
    List<int>? lineEnd,
    bool returnFile = false,
    String? viewMode,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    debugPrint('=== detectOffsideSingle ===');
    debugPrint('→ Uploading image: ${image.path}');
    debugPrint('→ returnFile: $returnFile');
    debugPrint('→ viewMode: $viewMode');

    final offsideParams = <String, dynamic>{
      'offside_enable': true,
      'use_ball_for_line': true,
      'player_conf': 0.20,
      'keypt_conf': 0.40,
      if (viewMode != null) 'view_mode': viewMode,
    };

    final paramsMap = <String, dynamic>{
      'return_model': true,
      'return_file': false,
      'return_images': true,
      ...offsideParams,
    };

    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(image.path, filename: 'frame.jpg'),
      'params': jsonEncode(paramsMap),
    });

    final clientMeta = {
      'offside_enable': offsideParams['offside_enable'],
      if (attackDirection.isNotEmpty) 'attack_direction': attackDirection,
      if (lineStart != null && lineStart.length == 2)
        'fixed_line_start': lineStart,
      if (lineEnd != null && lineEnd.length == 2)
        'fixed_line_end': lineEnd,
    };

    debugPrint('=== Trying endpoint: /predict/image_model ===');
    try {
      final resp = await _dio.post(
        '/predict/image',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(minutes: 5),
          responseType: ResponseType.json,
        ),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      if (resp.data is! Map<String, dynamic>) {
        throw Exception('Unexpected image_model response type: ${resp.data.runtimeType}');
      }

      final data = Map<String, dynamic>.from(resp.data as Map);
      _logModelSummary('/predict/image', data);

      if (_hasMeaningfulModels(data)) {
        debugPrint('✔ /predict/image_model returned meaningful models');
        return _parseFrameResponse(json: data, metaMerge: clientMeta);
      } else {
        debugPrint('!  /predict/image_model returned empty models, trying next...');
      }
    } on DioException catch (e) {
      debugPrint('❌ /predict/image_model failed: ${_dioErrorToString(e)}');
      // fallthrough to legacy
    }

    // 2) Try legacy /predict/image (JSON path)
    debugPrint('=== Trying endpoint: /predict/image ===');
    try {
      final resp = await _dio.post(
        '/predict/image',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(minutes: 5),
          responseType: ResponseType.json, // IMPORTANT: expect JSON
        ),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      if (resp.data is! Map<String, dynamic>) {
        throw Exception('Unexpected image response type: ${resp.data.runtimeType}');
      }

      final data = Map<String, dynamic>.from(resp.data as Map);
      _logModelSummary('/predict/image', data);

      if (_hasMeaningfulModels(data)) {
        debugPrint('✔ /predict/image returned meaningful models');
      } else {
        debugPrint('!  /predict/image returned empty models too (will still parse & let UI fallback/dummy if enabled)');
      }

      return _parseFrameResponse(json: data, metaMerge: clientMeta);
    } on DioException catch (e) {
      debugPrint('❌ /predict/image failed: ${_dioErrorToString(e)}');
      throw Exception('/predict/image failed: ${_dioErrorToString(e)}');
    }
  }

  Future<OffsideVideoResponse> _parseVideoResponse({
    required Map<String, dynamic> json,
    required Map<String, dynamic> metaMerge,
    required String videoBaseUrl,
  }) async {
    final serverMeta = (json['meta'] as Map<String, dynamic>? ?? const {});
    final mergedMeta = {...serverMeta, ...metaMerge};
    final models = (json['models'] as Map<String, dynamic>? ?? const {});
    final outputVideo = json['output_video'] as String?;
    final fileUrl = outputVideo != null ? _toAbsoluteUrl(outputVideo, baseUrl: videoBaseUrl) : null;
    
    String? firstImageUrl;
    final events = json['events'] as List?;
    if (events != null && events.isNotEmpty) {
      final firstEvent = events[0] as Map<String, dynamic>?;
      if (firstEvent != null) {
        final frameImg = firstEvent['frame_image'] as String?;
        if (frameImg != null) {
          firstImageUrl = _toAbsoluteUrl(frameImg, baseUrl: videoBaseUrl);
        }
      }
    }
    final image2DUrl = firstImageUrl;

    return OffsideVideoResponse.fromJson(
      json, // Pass full json for new fields
      models: models,
      fileUrl: fileUrl,
      image2DUrl: image2DUrl,
      image3DUrl: null,
    );
  }

  Future<OffsideVideoResponse> detectOffsideVideo({
    required File video,
    String attackDirection = 'right',
    List<int>? lineStart,
    List<int>? lineEnd,
    bool returnFile = false,
    String? viewMode,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    debugPrint('=== detectOffsideVideo ===');
    debugPrint('→ Uploading video: ${video.path}');
    debugPrint('→ returnFile: $returnFile');
    debugPrint('→ viewMode: $viewMode');

    const videoBaseUrl = 'https://offsidevideo.varxpro.com';
    final videoDio = Dio(
      BaseOptions(
        baseUrl: videoBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 30),
        headers: {'Accept': 'application/json'},
      ),
    );

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(video.path, filename: 'input_video.mp4'),
    });

    final clientMeta = {
      'offside_enable': true,
      if (attackDirection.isNotEmpty) 'attack_direction': attackDirection,
      if (lineStart != null && lineStart.length == 2)
        'fixed_line_start': lineStart,
      if (lineEnd != null && lineEnd.length == 2)
        'fixed_line_end': lineEnd,
    };

    debugPrint('=== Trying endpoint: /offside/analyze ===');
    try {
      final resp = await videoDio.post(
        '/offside/analyze',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(minutes: 30),
          responseType: ResponseType.json,
        ),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      if (resp.data is! Map<String, dynamic>) {
        throw Exception('Unexpected video response type: ${resp.data.runtimeType}');
      }

      final data = Map<String, dynamic>.from(resp.data as Map);
      debugPrint('→ Video analysis: offside_found=${data['offside_found']} | frames=${(data['offside_frames'] as List?)?.length ?? 0}');

      return _parseVideoResponse(
        json: data,
        metaMerge: clientMeta,
        videoBaseUrl: videoBaseUrl,
      );
    } on DioException catch (e) {
      debugPrint('❌ /offside/analyze failed: ${_dioErrorToString(e)}');
      throw Exception('/offside/analyze failed: ${_dioErrorToString(e)}');
    }
  }
}