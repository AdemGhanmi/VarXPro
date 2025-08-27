class PingResponse {
  final bool ok;
  final String model;
  final String opencv;

  PingResponse({required this.ok, required this.model, required this.opencv});

  factory PingResponse.fromJson(Map<String, dynamic> json) {
    return PingResponse(
      ok: json['ok'] as bool,
      model: json['model'] as String,
      opencv: json['opencv'] as String,
    );
  }
}

class OffsideFrameResponse {
  final bool ok;
  final bool offside;
  final Map<String, int> stats;
  final String? annotatedImageUrl;
  final Map<String, List<int>>? linePoints;
  final String? attackDirection;
  final String? error;

  OffsideFrameResponse({
    required this.ok,
    required this.offside,
    required this.stats,
    this.annotatedImageUrl,
    this.linePoints,
    this.attackDirection,
    this.error,
  });

  factory OffsideFrameResponse.fromJson(Map<String, dynamic> json) {
    return OffsideFrameResponse(
      ok: json['ok'] as bool,
      offside: json['offside'] as bool,
      stats: Map<String, int>.from(json['stats']),
      annotatedImageUrl: json['annotated_image_url'] as String?,
      linePoints: json['line_points'] != null
          ? {
              'start': List<int>.from(json['line_points']['start']),
              'end': List<int>.from(json['line_points']['end']),
            }
          : null,
      attackDirection: json['attack_direction'] as String?,
      error: json['error'] as String?,
    );
  }
}

class OffsideBatchResponse {
  final bool ok;
  final int count;
  final String? resultsJsonUrl;
  final String? zipUrl;
  final String? runDir;
  final String? error;

  OffsideBatchResponse({
    required this.ok,
    required this.count,
    this.resultsJsonUrl,
    this.zipUrl,
    this.runDir,
    this.error,
  });

  factory OffsideBatchResponse.fromJson(Map<String, dynamic> json) {
    return OffsideBatchResponse(
      ok: json['ok'] as bool,
      count: json['count'] as int,
      resultsJsonUrl: json['results_json_url'] as String?,
      zipUrl: json['zip_url'] as String?,
      runDir: json['run_dir'] as String?,
      error: json['error'] as String?,
    );
  }
}

class Run {
  final String run;
  final String? resultsJson;
  final dynamic resultsJsonContent;

  Run({required this.run, this.resultsJson, this.resultsJsonContent});

  factory Run.fromJson(Map<String, dynamic> json) {
    return Run(
      run: json['run'] as String,
      resultsJson: json['results_json'] as String?,
      resultsJsonContent: null,
    );
  }
}

class RunsResponse {
  final bool ok;
  final List<Run> runs;

  RunsResponse({required this.ok, required this.runs});

  factory RunsResponse.fromJson(Map<String, dynamic> json) {
    return RunsResponse(
      ok: json['ok'] as bool,
      runs: (json['runs'] as List).map((e) => Run.fromJson(e)).toList(),
    );
  }
}