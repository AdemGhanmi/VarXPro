import 'dart:io';
import 'package:VarXPro/views/pages/offsidePage/model/offside_model.dart';
import 'package:dio/dio.dart';

class OffsideService {
  late Dio _dio;

  OffsideService() {
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://192.168.1.18:8000',
    );

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
  }

  Future<PingResponse> ping() async {
    try {
      final response = await _dio.get('/api/ping');
      return PingResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('API Error: ${e.response!.statusCode} - ${e.response!.statusMessage}');
      } else {
        throw Exception('Network Error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to ping API: $e');
    }
  }

  Future<OffsideFrameResponse> detectOffsideSingle({
    required File image,
    String attackDirection = 'right',
    List<int>? lineStart,
    List<int>? lineEnd,
    bool save = true,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(image.path, filename: 'frame.jpg'),
        'attack_direction': attackDirection,
        if (lineStart != null && lineEnd != null) ...{
          'line_start_x': lineStart[0].toString(),
          'line_start_y': lineStart[1].toString(),
          'line_end_x': lineEnd[0].toString(),
          'line_end_y': lineEnd[1].toString(),
        },
        'save': save.toString(),
      });

      final response = await _dio.post(
        '/api/offside/frame',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      return OffsideFrameResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data;
        final errorMsg = errorData is Map ? errorData['error'] ?? 'Unknown error' : 'Unknown error';
        throw Exception('API Error: ${e.response!.statusCode} - $errorMsg');
      } else {
        throw Exception('Network Error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to detect offside: $e');
    }
  }

  Future<OffsideBatchResponse> detectOffsideBatch({
    List<File>? images,
    File? zipFile,
    String attackDirection = 'right',
    String lineMode = 'auto',
    List<int>? lineStart,
    List<int>? lineEnd,
  }) async {
    try {
      final formData = FormData();

      if (images != null && images.isNotEmpty) {
        for (var file in images) {
          formData.files.add(MapEntry(
            'files',
            await MultipartFile.fromFile(file.path,
                filename: 'frame_${DateTime.now().millisecondsSinceEpoch}.jpg'),
          ));
        }
      }

      if (zipFile != null) {
        formData.files.add(MapEntry(
          'zip',
          await MultipartFile.fromFile(zipFile.path, filename: 'frames.zip'),
        ));
      }

      formData.fields.addAll([
        MapEntry('attack_direction', attackDirection),
        MapEntry('line_mode', lineMode),
        if (lineMode == 'fixed' && lineStart != null && lineEnd != null) ...{
          MapEntry('line_start_x', lineStart[0].toString()),
          MapEntry('line_start_y', lineStart[1].toString()),
          MapEntry('line_end_x', lineEnd[0].toString()),
          MapEntry('line_end_y', lineEnd[1].toString()),
        },
      ]);

      final response = await _dio.post(
        '/api/offside/frames',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );

      return OffsideBatchResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data;
        final errorMsg = errorData is Map ? errorData['error'] ?? 'Unknown error' : 'Unknown error';
        throw Exception('API Error: ${e.response!.statusCode} - $errorMsg');
      } else {
        throw Exception('Network Error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to process batch offside detection: $e');
    }
  }

  Future<RunsResponse> listRuns() async {
    try {
      final response = await _dio.get('/api/runs');
      final runsResponse = RunsResponse.fromJson(response.data);

      final runs = await Future.wait(runsResponse.runs.map((run) async {
        if (run.resultsJson != null) {
          try {
            final jsonResponse = await _dio.get(run.resultsJson!);
            return Run(
              run: run.run,
              resultsJson: run.resultsJson,
              resultsJsonContent: jsonResponse.data,
            );
          } catch (e) {
            return Run(
              run: run.run,
              resultsJson: run.resultsJson,
              resultsJsonContent: {'error': 'Failed to load JSON: $e'},
            );
          }
        }
        return run;
      }));

      return RunsResponse(ok: runsResponse.ok, runs: runs);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('API Error: ${e.response!.statusCode} - ${e.response!.statusMessage}');
      } else {
        throw Exception('Network Error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to list runs: $e');
    }
  }
}