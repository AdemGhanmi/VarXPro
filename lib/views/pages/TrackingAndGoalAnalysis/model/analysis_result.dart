// lib/models/tracking_model.dart
class HealthResponse {
  final String status;
  final bool modelLoaded;
  final Map<String, dynamic>? classes;
  final Map<String, dynamic>? defaults;

  HealthResponse({
    required this.status,
    required this.modelLoaded,
    this.classes,
    this.defaults,
  });

  factory HealthResponse.fromJson(Map<String, dynamic> json) {
    return HealthResponse(
      status: json['status'] as String,
      modelLoaded: json['model_loaded'] as bool,
      classes: json['classes'] is Map ? Map<String, dynamic>.from(json['classes']) : null,
      defaults: json['defaults'] != null ? Map<String, dynamic>.from(json['defaults']) : null,
    );
  }
}

class AnalyzeResponse {
  final bool ok;
  final int frames;
  final Map<String, String> artifacts;
  final Map<String, dynamic> summary;

  AnalyzeResponse({
    required this.ok,
    required this.frames,
    required this.artifacts,
    required this.summary,
  });

  factory AnalyzeResponse.fromJson(Map<String, dynamic> json) {
    return AnalyzeResponse(
      ok: json['ok'] as bool,
      frames: json['frames'] as int,
      artifacts: Map<String, String>.from(json['artifacts']),
      summary: Map<String, dynamic>.from(json['summary']),
    );
  }
}

class CleanResponse {
  final bool ok;
  final int removed;

  CleanResponse({required this.ok, required this.removed});

  factory CleanResponse.fromJson(Map<String, dynamic> json) {
    return CleanResponse(
      ok: json['ok'] as bool,
      removed: json['removed'] as int? ?? 0,
    );
  }
}
