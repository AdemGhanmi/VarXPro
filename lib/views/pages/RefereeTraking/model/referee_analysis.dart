// views/pages/RefereeTraking/model/referee_analysis.dart

class HealthResponse {
  final String status;
  final bool modelLoaded;
  final Map<String, String>? classes;

  HealthResponse({
    required this.status,
    required this.modelLoaded,
    this.classes,
  });

  factory HealthResponse.fromJson(Map<String, dynamic> json) {
    return HealthResponse(
      status: (json['ok'] as bool?) ?? false ? 'ok' : 'error',
      modelLoaded: (json['model_loaded'] as bool?) ?? true,
      classes: json['classes'] != null
          ? Map<String, String>.from(json['classes'])
          : null,
    );
  }
}

class AnalyzeResponse {
  final List<AiEvent> aiEvents;
  final Evaluation? evaluation;

  AnalyzeResponse({
    required this.aiEvents,
    this.evaluation,
  });

  factory AnalyzeResponse.fromJson(Map<String, dynamic> json) {
    return AnalyzeResponse(
      aiEvents: (json['ai_events'] as List<dynamic>?)
              ?.map((e) => AiEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      evaluation: json['evaluation'] != null 
          ? Evaluation.fromJson(json['evaluation'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AiEvent {
  final double t;
  final String type;
  final Map<String, dynamic> details;

  AiEvent({
    required this.t,
    required this.type,
    required this.details,
  });

  factory AiEvent.fromJson(Map<String, dynamic> json) {
    return AiEvent(
      t: (json['t'] as num).toDouble(),
      type: json['type'] as String,
      details: json['details'] as Map<String, dynamic>,
    );
  }
}

class Evaluation {
  final double accuracy;
  final int correct;
  final int total;
  final List<PerDecision> perDecision;

  Evaluation({
    required this.accuracy,
    required this.correct,
    required this.total,
    required this.perDecision,
  });

  factory Evaluation.fromJson(Map<String, dynamic> json) {
    return Evaluation(
      accuracy: (json['accuracy'] as num).toDouble(),
      correct: json['correct'] as int,
      total: json['total'] as int,
      perDecision: (json['per_decision'] as List<dynamic>?)
              ?.map((e) => PerDecision.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PerDecision {
  final double t;
  final String type;
  final String decision;
  final bool match;

  PerDecision({
    required this.t,
    required this.type,
    required this.decision,
    required this.match,
  });

  factory PerDecision.fromJson(Map<String, dynamic> json) {
    return PerDecision(
      t: (json['t'] as num).toDouble(),
      type: json['type'] as String,
      decision: json['decision'] as String,
      match: json['match'] as bool,
    );
  }
}