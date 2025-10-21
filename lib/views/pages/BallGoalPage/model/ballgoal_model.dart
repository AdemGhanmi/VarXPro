// lib/views/pages/BallGoalPage/model/ballgoal_model.dart
class BallInOutResponse {
  final bool ok;
  final Map<String, dynamic>? ball;
  final Map<String, dynamic>? boundaryGuess;
  final bool inPlay;

  BallInOutResponse({
    required this.ok,
    this.ball,
    this.boundaryGuess,
    required this.inPlay,
  });

  factory BallInOutResponse.fromJson(Map<String, dynamic> json) {
    return BallInOutResponse(
      ok: json['ok'] as bool,
      ball: json['ball'] as Map<String, dynamic>?,
      boundaryGuess: json['boundary_guess'] as Map<String, dynamic>?,
      inPlay: json['in_play'] as bool,
    );
  }

  String get result => inPlay ? 'IN' : 'OUT';
  double? get confidence => ball?['conf']?.toDouble();
}

class GoalCheckResponse {
  final bool ok;
  final Map<String, dynamic>? ball;
  final bool goal;

  GoalCheckResponse({
    required this.ok,
    this.ball,
    required this.goal,
  });

  factory GoalCheckResponse.fromJson(Map<String, dynamic> json) {
    return GoalCheckResponse(
      ok: json['ok'] as bool,
      ball: json['ball'] as Map<String, dynamic>?,
      goal: json['goal'] as bool,
    );
  }

  double? get confidence => ball?['conf']?.toDouble();
}