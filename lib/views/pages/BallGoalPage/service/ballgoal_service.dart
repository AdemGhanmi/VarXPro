// lib/views/pages/BallGoalPage/service/ballgoal_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:VarXPro/views/pages/BallGoalPage/model/ballgoal_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// Callback de progrès (bytes envoyés/reçus, total).
typedef ProgressCallback = void Function(int count, int total);

class BallGoalService {
  static const String defaultBaseUrl = 'https://varxpromax.varxpro.com';

  final Dio _dio;
  final bool _debug;

  BallGoalService({
    String? baseUrl,
    bool? debug, // si null => suit kDebugMode
  })  : _debug = debug ?? kDebugMode,
        _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? defaultBaseUrl,
            connectTimeout: const Duration(minutes: 15),
            receiveTimeout: const Duration(minutes: 15),
            sendTimeout: const Duration(minutes: 15),
            responseType: ResponseType.json,
            followRedirects: false,
            validateStatus: (status) => status != null && status < 500,
            headers: const {'Accept': 'application/json'},
          ),
        ) {
    // Interceptor de timing + cURL
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.extra['__startAt'] = DateTime.now().millisecondsSinceEpoch;
          if (_debug) {
            _d('➡️  [REQ] ${options.method} ${options.uri}');
            if (options.data is FormData) {
              final fd = options.data as FormData;
              for (final e in fd.files) {
                _d('   • form-file "${e.key}" -> ${e.value.filename}');
              }
              for (final e in fd.fields) {
                _d('   • form-field "${e.key}" = ${_truncate(e.value)}');
              }
            } else if (options.data != null) {
              _d('   • data: ${_pretty(options.data)}');
            }
            _d('   • headers: ${options.headers}');
            _maybePrintCurl(options);
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          final started = response.requestOptions.extra['__startAt'] as int?;
          final durMs = started == null
              ? null
              : (DateTime.now().millisecondsSinceEpoch - started);
          if (_debug) {
            final sizeHint = _sizeHint(response);
            _d('✅ [RES] ${response.statusCode} ${response.requestOptions.uri}'
                '${durMs != null ? ' (${durMs}ms)' : ''}${sizeHint.isNotEmpty ? ' • $sizeHint' : ''}');
            if (response.data != null) {
              _d('   • body: ${_pretty(response.data)}');
            }
          }
          handler.next(response);
        },
        onError: (e, handler) {
          if (_debug) {
            final req = e.requestOptions;
            _d('🛑 [ERR] ${req.method} ${req.uri}');
            _d('   • type: ${e.type}');
            _d('   • message: ${e.message}');
            if (e.response != null) {
              _d('   • status: ${e.response?.statusCode}');
              _d('   • data: ${_pretty(e.response?.data)}');
            }
            _maybePrintCurl(req);
          }
          handler.next(e);
        },
      ),
    );

    // LogInterceptor optionnel (après notre wrapper). Garde-le court.
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        requestHeader: false,
        responseHeader: false,
      ),
    );
  }

  /// Test rapide de santé API (si un /health existe).
  Future<Map<String, dynamic>> health() async {
    try {
      final res = await _dio.get('/health');
      return (res.data as Map).cast<String, dynamic>();
    } catch (e) {
      throw _handleDioError(e, 'health');
    }
  }

  /// Détection image (ball in/out + events)
  Future<BallInOutResponse> ballInOut(
    File image, {
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      if (_debug) {
        _d('📸 [ballInOut] fichier: ${image.path}');
        _d('   • taille: ${_fileSize(image)}');
      }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          image.path,
          filename: 'frame.jpg',
        ),
      });

      final sw = Stopwatch()..start();
      final response = await _dio.post(
        '/events_image',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: (s, t) {
          if (_debug) _d('   ⬆️  upload: $s / $t bytes');
          onSendProgress?.call(s, t);
        },
        onReceiveProgress: (r, t) {
          if (_debug) _d('   ⬇️  download: $r / $t bytes');
          onReceiveProgress?.call(r, t);
        },
      );
      if (_debug) _d('⏱️  [ballInOut] ${sw.elapsedMilliseconds}ms');

      return BallInOutResponse.fromJson(
        (response.data as Map).cast<String, dynamic>(),
      );
    } catch (e) {
      throw _handleDioError(e, 'ball in/out');
    }
  }

  /// Détection vidéo (ball in/out + events)
  Future<BallInOutVideoResponse> ballInOutVideo(
    File video, {
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      if (_debug) {
        _d('🎞️  [ballInOutVideo] fichier: ${video.path}');
        _d('   • taille: ${_fileSize(video)}');
      }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          video.path,
          filename: 'video.mp4',
        ),
      });

      final sw = Stopwatch()..start();
      final response = await _dio.post(
        '/events_video',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: (s, t) {
          if (_debug) _d('   ⬆️  upload: $s / $t bytes');
          onSendProgress?.call(s, t);
        },
        onReceiveProgress: (r, t) {
          if (_debug) _d('   ⬇️  download: $r / $t bytes');
          onReceiveProgress?.call(r, t);
        },
      );
      if (_debug) _d('⏱️  [ballInOutVideo] ${sw.elapsedMilliseconds}ms');

      return BallInOutVideoResponse.fromJson(
        (response.data as Map).cast<String, dynamic>(),
      );
    } catch (e) {
      throw _handleDioError(e, 'ball in/out video');
    }
  }

  /* ====================== Helpers debug & erreurs ====================== */

  void _d(String msg) {
    if (_debug) debugPrint(msg);
  }

  static String _fileSize(File f) {
    try {
      final bytes = f.lengthSync();
      if (bytes < 1024) return '$bytes B';
      final kb = bytes / 1024;
      if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
      final mb = kb / 1024;
      return '${mb.toStringAsFixed(2)} MB';
    } catch (_) {
      return 'inconnue';
    }
  }

  static String _pretty(dynamic data) {
    try {
      if (data is String) return _truncate(data, 1200);
      return _truncate(const JsonEncoder.withIndent('  ').convert(data), 1200);
    } catch (_) {
      return data.toString();
    }
  }

  static String _truncate(String s, [int max = 800]) {
    if (s.length <= max) return s;
    return '${s.substring(0, max)} … (+${s.length - max} chars)';
    }

  static String _sizeHint(Response res) {
    final clen = res.headers.map['content-length']?.firstOrNull;
    if (clen != null) {
      final n = int.tryParse(clen);
      if (n != null) {
        if (n < 1024) return '$n B';
        final kb = n / 1024;
        if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
        return '${(kb / 1024).toStringAsFixed(2)} MB';
      }
    }
    return '';
  }

  void _maybePrintCurl(RequestOptions o) {
    if (!_debug) return;
    try {
      final b = StringBuffer('curl -X ${o.method} "${o.uri}"');
      o.headers.forEach((k, v) {
        // évite d’imprimer des tokens sensibles si besoin
        b.write(' -H ${_q('$k: $v')}');
      });

      if (o.data is FormData) {
        final fd = o.data as FormData;
        for (final f in fd.files) {
          final filename = f.value.filename ?? 'file.bin';
          // ATTENTION: sur iOS/Android le chemin local est valable côté appareil.
          // cURL est imprimé pour debug/inspiration.
          b.write(' -F ${_q('${f.key}=@$filename')}');
        }
        for (final field in fd.fields) {
          b.write(' -F ${_q('${field.key}=${field.value}')}');
        }
      } else if (o.data != null) {
        final body = (o.data is String) ? o.data as String : jsonEncode(o.data);
        b.write(' --data ${_q(body)}');
        b.write(' -H "Content-Type: ${o.contentType ?? 'application/json'}"');
      }
      _d('🐚 cURL:\n$b');
    } catch (_) {
      // ignore
    }
  }

  static String _q(String s) => "'${s.replaceAll("'", r"'\''")}'";

  Exception _handleDioError(dynamic e, String operation) {
    if (e is DioException) {
      // timeouts
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return Exception(
          'Connection timeout during $operation. The server may be processing the media; vérifiez la taille/durée et réessayez.',
        );
      }
      // HTTP avec payload JSON
      final status = e.response?.statusCode;
      if (status == 400) {
        final data = e.response?.data as Map<String, dynamic>?;
        return Exception('Bad request during $operation: ${data?['error'] ?? 'Invalid input'}');
      } else if (status == 413) {
        return Exception('Payload too large during $operation (413). Réduisez la taille/longueur du média.');
      } else if (status == 415) {
        return Exception('Unsupported media type during $operation (415).');
      } else if (status == 429) {
        return Exception('Too many requests during $operation (429). Réessayez plus tard.');
      } else if (status == 500) {
        final data = e.response?.data as Map<String, dynamic>?;
        return Exception('Server error during $operation: ${data?['error'] ?? 'Internal server error'}');
      }

      // erreurs réseau
      if (e.type == DioExceptionType.connectionError) {
        return Exception('Network error during $operation. Vérifiez votre connexion internet.');
      }

      // fallback Dio
      return Exception('Failed to $operation: ${e.message}');
    }

    // fallback générique
    return Exception('Failed to $operation: ${e.toString()}');
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
