class PingResponse {
  final bool ok;
  final String model;
  final String opencv;

  PingResponse({
    required this.ok,
    required this.model,
    required this.opencv,
  });

  factory PingResponse.fromJson(Map<String, dynamic> json) {
    final bool statusOk =
        (json['ok'] == true) || (json['status']?.toString().toLowerCase() == 'ok');
    return PingResponse(
      ok: statusOk,
      model: (json['model'] as String?) ?? '',
      opencv: (json['opencv'] as String?) ?? '',
    );
  }
}

class OffsideFrameResponse {
  final bool? offside; // nullable
  final int offsidesCount;
  final String? annotatedImageUrl;
  final Map<String, List<int>>? linePoints;
  final String? attackDirection;
  final String? attackingTeam;
  final double? secondLastDefenderProjection;
  final List<dynamic>? players;
  final String? reason;
  final String? error;
  final String? top;     // "offside"/"onside" (اختياري من الباك)
  final String? verdict; // "offside"/"onside" (اختياري من الباك)

  OffsideFrameResponse({
    required bool ok,
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
    this.top,
    this.verdict,
  });

  /// حسم النتيجة من جميع المفاتيح المحتملة
  bool get offsideResolved {
    bool raw;
    if (offside != null) {
      raw = offside!;
    } else {
      final s = (top ?? verdict)?.toLowerCase();
      if (s == 'offside') {
        raw = true;
      } else if (s == 'onside') {
        raw = false;
      } else {
        // Fallback to count
        raw = offsidesCount > 0;
      }
    }
    return !raw; // Invert to fix reversed logic
  }

  factory OffsideFrameResponse.fromJson(Map<String, dynamic> json, {String? annotatedImageUrl}) {
    Map<String, List<int>>? linePointsMap;
    final rawLp = json['line_points'];
    if (rawLp is Map<String, dynamic>) {
      linePointsMap = {
        'start': rawLp['start'] != null ? List<int>.from(rawLp['start']) : <int>[],
        'end': rawLp['end'] != null ? List<int>.from(rawLp['end']) : <int>[],
      };
    }

    bool? offsideBool;
    final offRaw = json['offside'];
    if (offRaw is bool) {
      offsideBool = offRaw;
    } else if (offRaw is String) {
      final v = offRaw.toLowerCase();
      if (v == 'true' || v == 'offside') offsideBool = true;
      if (v == 'false' || v == 'onside') offsideBool = false;
    }

    return OffsideFrameResponse(
      ok: true,
      offside: offsideBool,
      offsidesCount: json['offsides_count'] as int? ?? 0,
      annotatedImageUrl: annotatedImageUrl,
      linePoints: linePointsMap,
      attackDirection: json['attack_direction'] as String?,
      attackingTeam: json['attacking_team'] as String?,
      secondLastDefenderProjection: (json['second_last_defender_projection'] as num?)?.toDouble(),
      players: json['players'] as List<dynamic>?,
      reason: json['reason'] as String?,
      error: json['error'] as String?,
      top: json['top'] as String?,
      verdict: json['verdict'] as String?,
    );
  }
}


class OffsideVideoResponse {
 
 
 
  final bool? offside; // nullable
  final int offsidesCount;
  final String? annotatedVideoUrl;
  final Map<String, List<int>>? linePoints;
  final String? attackDirection;
  final String? attackingTeam;
  final double? secondLastDefenderProjection;
  final List<dynamic>? players;
  final String? reason;
  final String? error;
  final String? top;
  final String? verdict;

  OffsideVideoResponse({
    required bool ok,
    required this.offside,
    required this.offsidesCount,
    this.annotatedVideoUrl,
    this.linePoints,
    this.attackDirection,
    this.attackingTeam,
    this.secondLastDefenderProjection,
    this.players,
    this.reason,
    this.error,
    this.top,
    this.verdict,
  });

  bool get offsideResolved {
    bool raw;
    if (offside != null) {
      raw = offside!;
    } else {
      final s = (top ?? verdict)?.toLowerCase();
      if (s == 'offside') {
        raw = true;
      } else if (s == 'onside') {
        raw = false;
      } else {
        // Fallback to count
        raw = offsidesCount > 0;
      }
    }
    return !raw; // Invert to fix reversed logic
  }

  factory OffsideVideoResponse.fromJson(Map<String, dynamic> json, {String? annotatedVideoUrl}) {
    Map<String, List<int>>? linePointsMap;
    final rawLp = json['line_points'];
    if (rawLp is Map<String, dynamic>) {
      linePointsMap = {
        'start': rawLp['start'] != null ? List<int>.from(rawLp['start']) : <int>[],
        'end': rawLp['end'] != null ? List<int>.from(rawLp['end']) : <int>[],
      };
    }

    bool? offsideBool;
    final offRaw = json['offside'];
    if (offRaw is bool) {
      offsideBool = offRaw;
    } else if (offRaw is String) {
      final v = offRaw.toLowerCase();
      if (v == 'true' || v == 'offside') offsideBool = true;
      if (v == 'false' || v == 'onside') offsideBool = false;
    }

    return OffsideVideoResponse(
      ok: true,
      offside: offsideBool,
      offsidesCount: json['offsides_count'] as int? ?? 0,
      annotatedVideoUrl: annotatedVideoUrl,
      linePoints: linePointsMap,
      attackDirection: json['attack_direction'] as String?,
      attackingTeam: json['attacking_team'] as String?,
      secondLastDefenderProjection: (json['second_last_defender_projection'] as num?)?.toDouble(),
      players: json['players'] as List<dynamic>?,
      reason: json['reason'] as String?,
      error: json['error'] as String?,
      top: json['top'] as String?,
      verdict: json['verdict'] as String?,
    );
  }
}