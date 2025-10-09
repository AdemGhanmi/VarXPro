// offside_model.dart
class PingResponse {
  final bool ok;
  final String model;
  final String opencv;

  PingResponse({required this.ok, required this.model, required this.opencv});

  factory PingResponse.fromJson(Map<String, dynamic> json) {
    return PingResponse(
      ok: json['ok'] as bool? ?? false, // Fallback if null
      model: json['model'] as String? ?? '',
      opencv: json['opencv'] as String? ?? '',
    );
  }
}

class OffsideFrameResponse {
  final bool ok;
  final bool offside;
  final int offsidesCount;
  final String? annotatedImageUrl;
  final Map<String, List<int>>? linePoints;
  final String? attackDirection;
  final String? attackingTeam;
  final double? secondLastDefenderProjection;
  final List<dynamic>? players;
  final String? reason;
  final String? error;

  OffsideFrameResponse({
    required this.ok,
    required this.offside,
    required this.offsidesCount,
    this.annotatedImageUrl,
    this.linePoints,
    this.attackDirection,
    this.attackingTeam,
    this.secondLastDefenderProjection,
    this.players,
    this.reason,
    this.error,
  });

  factory OffsideFrameResponse.fromJson(Map<String, dynamic> json) {
    Map<String, List<int>>? linePointsMap;
    if (json['line_points'] != null) {
      final lp = json['line_points'] as Map<String, dynamic>? ?? <String, dynamic>{};
      linePointsMap = {
        'start': lp['start'] != null ? List<int>.from(lp['start']) : <int>[],
        'end': lp['end'] != null ? List<int>.from(lp['end']) : <int>[],
      };
    }

    return OffsideFrameResponse(
      ok: json['ok'] as bool? ?? false,
      offside: json['offside'] as bool? ?? false,
      offsidesCount: json['offsides_count'] as int? ?? 0,
      annotatedImageUrl: json['annotated_image_url'] as String?,
      linePoints: linePointsMap,
      attackDirection: json['attack_direction'] as String?,
      attackingTeam: json['attacking_team'] as String?,
      secondLastDefenderProjection: (json['second_last_defender_projection'] as num?)?.toDouble(),
      players: json['players'] as List<dynamic>?,
      reason: json['reason'] as String?,
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
      ok: json['ok'] as bool? ?? false,
      count: json['count'] as int? ?? 0,
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
      run: json['run'] as String? ?? '',
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
    final runsList = json['runs'] as List<dynamic>? ?? <dynamic>[];
    return RunsResponse(
      ok: json['ok'] as bool? ?? false,
      runs: runsList.map((e) => Run.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}