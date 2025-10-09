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
      status: json['status'] as String? ?? 'unknown',
      modelLoaded: json['model_loaded'] as bool? ?? false,
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
    final bool isOk = json['ok'] as bool? ?? false;
    if (!isOk) {
      // If not ok, return a default error response
      return AnalyzeResponse(
        ok: false,
        frames: 0,
        artifacts: {},
        summary: {'error': json['error'] ?? 'Unknown error'},
      );
    }
    return AnalyzeResponse(
      ok: true,
      frames: (json['frames'] as num?)?.toInt() ?? 0,
      artifacts: (json['artifacts'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v.toString())) ?? {},
      summary: json['summary'] != null ? Map<String, dynamic>.from(json['summary']) : {},
    );
  }
}

class CleanResponse {
  final bool ok;
  final int removed;

  CleanResponse({required this.ok, required this.removed});

  factory CleanResponse.fromJson(Map<String, dynamic> json) {
    return CleanResponse(
      ok: json['ok'] as bool? ?? false,
      removed: json['removed'] as int? ?? 0,
    );
  }
}