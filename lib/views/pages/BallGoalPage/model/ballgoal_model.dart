// ballgoal_model.dart (updated with fileUrl)
class BallInOutResponse {
  final bool ok;
  final Map<String, dynamic>? offside;
  final String? ballState;
  final double? confidence; // Optional if present

  BallInOutResponse({
    this.ok = true,
    this.offside,
    this.ballState,
    this.confidence,
  });

  factory BallInOutResponse.fromJson(Map<String, dynamic> json) {
    return BallInOutResponse(
      ok: json['ok'] as bool? ?? true,
      offside: json['offside'] as Map<String, dynamic>?,
      ballState: (json['ball_event'] as Map<String, dynamic>?)?['state'] as String?,
      confidence: json['confidence'] as double?,
    );
  }

  String get result => ballState?.toUpperCase() ?? 'UNKNOWN';
  bool get isOffside => offside?['is_offside'] as bool? ?? false;
  double? get margin => offside?['max_offside_margin'] as double?;
}

class BallInOutVideoResponse {
  final bool ok;
  final List<Map<String, dynamic>> offsideEvents;
  final List<Map<String, dynamic>> ballEvents;
  final Map<String, dynamic>? bestPicks;
  final Map<String, dynamic>? counts;
  final String? fileUrl;

  BallInOutVideoResponse({
    this.ok = true,
    this.offsideEvents = const [],
    this.ballEvents = const [],
    this.bestPicks,
    this.counts,
    this.fileUrl,
  });

  factory BallInOutVideoResponse.fromJson(Map<String, dynamic> json) {
    return BallInOutVideoResponse(
      ok: json['ok'] as bool? ?? true,
      offsideEvents: (json['offside_events'] as List?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
      ballEvents: (json['ball_events'] as List?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
      bestPicks: json['best_picks'] as Map<String, dynamic>?,
      counts: json['counts'] as Map<String, dynamic>?,
      fileUrl: json['fileUrl'] as String?,
    );
  }

  Map<String, dynamic>? get bestBallEvent => bestPicks?['best_ball_event'];
  Map<String, dynamic>? get bestOffside => bestPicks?['best_offside'];
}