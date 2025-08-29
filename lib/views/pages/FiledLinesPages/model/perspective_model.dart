// lib/views/pages/FiledLinesPages/model/perspective_model.dart
class HealthResponse {
  final String status;
  final bool calibrated;
  final Map<String, int>? dstSize;

  HealthResponse({
    required this.status,
    required this.calibrated,
    this.dstSize,
  });

  factory HealthResponse.fromJson(Map<String, dynamic> json) {
    return HealthResponse(
      status: json['status'] as String,
      calibrated: json['calibrated'] as bool,
      dstSize: json['dst_size'] != null
          ? Map<String, int>.from(json['dst_size'] as Map)
          : null,
    );
  }
}

class DetectLinesResponse {
  final bool ok;
  final String? uploadUrl;
  final String? annotatedUrl;
  final List<List<int>>? lines;

  DetectLinesResponse({
    required this.ok,
    this.uploadUrl,
    this.annotatedUrl,
    this.lines,
  });

  factory DetectLinesResponse.fromJson(Map<String, dynamic> json) {
    return DetectLinesResponse(
      ok: json['ok'] as bool,
      uploadUrl: json['upload_url'] as String?,
      annotatedUrl: json['annotated_url'] as String?,
      lines: json['lines'] != null
          ? (json['lines'] as List).map((l) => List<int>.from(l as List)).toList()
          : null,
    );
  }
}

class CalibrationResponse {
  final bool ok;
  final Map<String, int>? dstSize;
  final bool? saved;
  final String? calibrationUrl;

  CalibrationResponse({
    required this.ok,
    this.dstSize,
    this.saved,
    this.calibrationUrl,
  });

  factory CalibrationResponse.fromJson(Map<String, dynamic> json) {
    return CalibrationResponse(
      ok: json['ok'] as bool,
      dstSize: json['dst_size'] != null
          ? Map<String, int>.from(json['dst_size'] as Map)
          : null,
      saved: json['saved'] as bool?,
      calibrationUrl: json['calibration_url'] as String?,
    );
  }
}

class LoadCalibrationResponse {
  final bool ok;
  final Map<String, int>? dstSize;
  final String? calibrationFile;

  LoadCalibrationResponse({
    required this.ok,
    this.dstSize,
    this.calibrationFile,
  });

  factory LoadCalibrationResponse.fromJson(Map<String, dynamic> json) {
    return LoadCalibrationResponse(
      ok: json['ok'] as bool,
      dstSize: json['dst_size'] != null
          ? Map<String, int>.from(json['dst_size'] as Map)
          : null,
      calibrationFile: json['calibration_file'] as String?,
    );
  }
}

class TransformFrameResponse {
  final bool ok;
  final String? originalUrl;
  final String? birdsEyeUrl;

  TransformFrameResponse({
    required this.ok,
    this.originalUrl,
    this.birdsEyeUrl,
  });

  factory TransformFrameResponse.fromJson(Map<String, dynamic> json) {
    return TransformFrameResponse(
      ok: json['ok'] as bool,
      originalUrl: json['original_url'] as String?,
      birdsEyeUrl: json['birds_eye_url'] as String?,
    );
  }
}

class TransformVideoResponse {
  final bool ok;
  final String? inputUrl;
  final String? outputUrl;
  final int? frames;
  final Map<String, int>? dstSize;

  TransformVideoResponse({
    required this.ok,
    this.inputUrl,
    this.outputUrl,
    this.frames,
    this.dstSize,
  });

  factory TransformVideoResponse.fromJson(Map<String, dynamic> json) {
    return TransformVideoResponse(
      ok: json['ok'] as bool,
      inputUrl: json['input_url'] as String?,
      outputUrl: json['output_url'] as String?,
      frames: json['frames'] as int?,
      dstSize: json['dst_size'] != null
          ? Map<String, int>.from(json['dst_size'] as Map)
          : null,
    );
  }
}

class TransformPointResponse {
  final bool ok;
  final List<double>? input;
  final List<double>? output;
  final String? error;

  TransformPointResponse({
    required this.ok,
    this.input,
    this.output,
    this.error,
  });

  factory TransformPointResponse.fromJson(Map<String, dynamic> json) {
    return TransformPointResponse(
      ok: json['ok'] as bool,
      input: json['input'] != null
          ? List<double>.from((json['input'] as List).map((x) => x.toDouble()))
          : null,
      output: json['output'] != null
          ? List<double>.from((json['output'] as List).map((x) => x.toDouble()))
          : null,
      error: json['error'] as String?,
    );
  }
}

class CleanResponse {
  final bool ok;
  final int? removed;
  final String? error;

  CleanResponse({
    required this.ok,
    this.removed,
    this.error,
  });

  factory CleanResponse.fromJson(Map<String, dynamic> json) {
    return CleanResponse(
      ok: json['ok'] as bool,
      removed: json['removed'] as int?,
      error: json['error'] as String?,
    );
  }
}
