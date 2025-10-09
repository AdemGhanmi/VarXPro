// offside_service.dart
import 'dart:io';
import 'package:VarXPro/views/pages/offsidePage/model/offside_model.dart';
import 'package:dio/dio.dart';

class OffsideService {
  late Dio _dio;

  OffsideService() {
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://offside.varxpro.com',
    );

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
  }

  Future<PingResponse> ping() async {
    try {
      print('DEBUG: Starting ping request to /api/ping');
      final response = await _dio.get('/api/ping');
      print('DEBUG: Ping response status: ${response.statusCode}');
      print('DEBUG: Ping response data: ${response.data}');
      print('DEBUG: Ping response data type: ${response.data.runtimeType}');
      if (response.data == null) {
        throw Exception('Ping response data is null');
      }
      return PingResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      print('DEBUG: DioException in ping: ${e.type}');
      print('DEBUG: DioException response: ${e.response}');
      print('DEBUG: DioException message: ${e.message}');
      if (e.response != null) {
        throw Exception('API Error: ${e.response!.statusCode} - ${e.response!.statusMessage}');
      } else {
        throw Exception('Network Error: ${e.message}');
      }
    } catch (e) {
      print('DEBUG: General exception in ping: $e');
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
    Response? response; // Declare outside try for catch access
    try {
      print('DEBUG: Starting detectOffsideSingle with image: ${image.path}');
      print('DEBUG: Attack direction: $attackDirection');
      print('DEBUG: Line start: $lineStart');
      print('DEBUG: Line end: $lineEnd');
      print('DEBUG: Save: $save');

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
        'show_lines': '1',
        'line_on_field_only': '1',
      });

      print('DEBUG: FormData prepared, sending POST to /api/offside/frame');

      response = await _dio.post(
        '/api/offside/frame',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      print('DEBUG: detectOffsideSingle response status: ${response.statusCode}');
      print('DEBUG: detectOffsideSingle response data type: ${response.data.runtimeType}');
      if (response.data == null) {
        throw Exception('Response data is null');
      }
      if (response.data is! Map<String, dynamic>) {
        throw Exception('Response data is not a Map: ${response.data.runtimeType}');
      }

      final jsonData = response.data as Map<String, dynamic>;
      print('DEBUG: Response keys: ${jsonData.keys.toList()}'); // Print keys to see structure
      print('DEBUG: Full response data: $jsonData'); // Full data for inspection

      // Try to parse, catch specific error
      try {
        return OffsideFrameResponse.fromJson(jsonData);
      } catch (parseError) {
        print('DEBUG: Parsing error in fromJson: $parseError');
        print('DEBUG: Likely a null field expected as Map. Check model for nullable fields.');
        rethrow; // Rethrow to handle upstream
      }

    } on DioException catch (e) {
      print('DEBUG: DioException in detectOffsideSingle: ${e.type}');
      print('DEBUG: DioException response: ${e.response}');
      print('DEBUG: DioException message: ${e.message}');
      print('DEBUG: DioException request options: ${e.requestOptions}');
      if (e.response != null) {
        final errorData = e.response!.data;
        print('DEBUG: Error response data: $errorData');
        print('DEBUG: Error response data type: ${errorData.runtimeType}');
        final errorMsg = errorData is Map ? errorData['error'] ?? 'Unknown error' : 'Unknown error';
        print('DEBUG: Extracted error message: $errorMsg');
        throw Exception('API Error: ${e.response!.statusCode} - $errorMsg');
      } else {
        throw Exception('Network Error: ${e.message}');
      }
    } catch (e) {
      print('DEBUG: General exception in detectOffsideSingle: $e');
      if (response != null) {
        print('DEBUG: Response data at failure: ${response.data}');
      }
      print('DEBUG: Stack trace: ${StackTrace.current}');
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
      print('DEBUG: Starting detectOffsideBatch');
      print('DEBUG: Images count: ${images?.length ?? 0}');
      print('DEBUG: Zip file: ${zipFile?.path}');
      print('DEBUG: Attack direction: $attackDirection');
      print('DEBUG: Line mode: $lineMode');
      print('DEBUG: Line start: $lineStart');
      print('DEBUG: Line end: $lineEnd');

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
        MapEntry('show_lines', '1'),
        MapEntry('line_on_field_only', '1'),
        if (lineMode == 'fixed' && lineStart != null && lineEnd != null) ...{
          MapEntry('line_start_x', lineStart[0].toString()),
          MapEntry('line_start_y', lineStart[1].toString()),
          MapEntry('line_end_x', lineEnd[0].toString()),
          MapEntry('line_end_y', lineEnd[1].toString()),
        },
      ]);

      print('DEBUG: FormData prepared, sending POST to /api/offside/frames');

      final response = await _dio.post(
        '/api/offside/frames',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );

      print('DEBUG: detectOffsideBatch response status: ${response.statusCode}');
      print('DEBUG: detectOffsideBatch response data: ${response.data}');
      print('DEBUG: detectOffsideBatch response data type: ${response.data.runtimeType}');

      if (response.data == null) {
        throw Exception('Response data is null');
      }
      if (response.data is! Map<String, dynamic>) {
        throw Exception('Response data is not a Map: ${response.data.runtimeType}');
      }

      final jsonData = response.data as Map<String, dynamic>;
      print('DEBUG: Batch Response keys: ${jsonData.keys.toList()}');

      return OffsideBatchResponse.fromJson(jsonData);
    } on DioException catch (e) {
      print('DEBUG: DioException in detectOffsideBatch: ${e.type}');
      print('DEBUG: DioException response: ${e.response}');
      print('DEBUG: DioException message: ${e.message}');
      print('DEBUG: DioException request options: ${e.requestOptions}');
      if (e.response != null) {
        final errorData = e.response!.data;
        print('DEBUG: Error response data: $errorData');
        print('DEBUG: Error response data type: ${errorData.runtimeType}');
        final errorMsg = errorData is Map ? errorData['error'] ?? 'Unknown error' : 'Unknown error';
        print('DEBUG: Extracted error message: $errorMsg');
        throw Exception('API Error: ${e.response!.statusCode} - $errorMsg');
      } else {
        throw Exception('Network Error: ${e.message}');
      }
    } catch (e) {
      print('DEBUG: General exception in detectOffsideBatch: $e');
      print('DEBUG: Stack trace: ${StackTrace.current}');
      throw Exception('Failed to process batch offside detection: $e');
    }
  }

  Future<RunsResponse> listRuns() async {
    try {
      print('DEBUG: Starting listRuns request to /api/runs');
      final response = await _dio.get('/api/runs');
      print('DEBUG: listRuns response status: ${response.statusCode}');
      print('DEBUG: listRuns response data: ${response.data}');
      print('DEBUG: listRuns response data type: ${response.data.runtimeType}');

      if (response.data == null) {
        throw Exception('Response data is null');
      }
      if (response.data is! Map<String, dynamic>) {
        throw Exception('Response data is not a Map: ${response.data.runtimeType}');
      }

      final runsResponse = RunsResponse.fromJson(response.data as Map<String, dynamic>);

      print('DEBUG: Found ${runsResponse.runs.length} runs, fetching resultsJson...');

      final runs = await Future.wait(runsResponse.runs.map((run) async {
        if (run.resultsJson != null) {
          try {
            print('DEBUG: Fetching resultsJson for run ${run.run}: ${run.resultsJson}');
            final jsonResponse = await _dio.get(run.resultsJson!);
            print('DEBUG: resultsJson response status: ${jsonResponse.statusCode}');
            print('DEBUG: resultsJson response data: ${jsonResponse.data}');
            print('DEBUG: resultsJson response data type: ${jsonResponse.data.runtimeType}');

            if (jsonResponse.data == null) {
              throw Exception('resultsJson data is null');
            }
            if (jsonResponse.data is! Map<String, dynamic>) {
              throw Exception('resultsJson data is not a Map: ${jsonResponse.data.runtimeType}');
            }

            print('DEBUG: Successfully fetched resultsJson for run ${run.run}');
            return Run(
              run: run.run,
              resultsJson: run.resultsJson,
              resultsJsonContent: jsonResponse.data as Map<String, dynamic>,
            );
          } catch (e) {
            print('DEBUG: Failed to fetch resultsJson for run ${run.run}: $e');
            return Run(
              run: run.run,
              resultsJson: run.resultsJson,
              resultsJsonContent: {'error': 'Failed to load JSON: $e'},
            );
          }
        }
        return run;
      }));

      print('DEBUG: listRuns completed successfully');
      return RunsResponse(ok: runsResponse.ok, runs: runs);
    } on DioException catch (e) {
      print('DEBUG: DioException in listRuns: ${e.type}');
      print('DEBUG: DioException response: ${e.response}');
      print('DEBUG: DioException message: ${e.message}');
      if (e.response != null) {
        throw Exception('API Error: ${e.response!.statusCode} - ${e.response!.statusMessage}');
      } else {
        throw Exception('Network Error: ${e.message}');
      }
    } catch (e) {
      print('DEBUG: General exception in listRuns: $e');
      print('DEBUG: Stack trace: ${StackTrace.current}');
      throw Exception('Failed to list runs: $e');
    }
  }
}