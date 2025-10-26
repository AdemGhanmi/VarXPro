// views/pages/RefereeTraking/model/referee_analysis.dart
class AnalyzeResponse {
  final bool ok;
  final Map<String, dynamic> metrics;
  final RefereeEvaluation? refereeEvaluation;
  final Map<String, String> downloads;
  final String reportUrl;
  final String videoUrl;

  AnalyzeResponse({
    required this.ok,
    required this.metrics,
    this.refereeEvaluation,
    required this.downloads,
    required this.reportUrl,
    required this.videoUrl,
  });

  factory AnalyzeResponse.fromJson(Map<String, dynamic> json) {
    return AnalyzeResponse(
      ok: json['ok'] ?? false,
      metrics: json['metrics'] ?? {},
      refereeEvaluation: json['referee_evaluation'] != null
          ? RefereeEvaluation.fromJson(json['referee_evaluation'])
          : null,
      downloads: Map<String, String>.from(json['downloads'] ?? {}),
      reportUrl: json['report_url'] ?? '',
      videoUrl: json['video_url'] ?? '',
    );
  }
}

class RefereeEvaluation {
  final Map<String, dynamic> context;
  final List<Criterion> criteria;
  final String grade;
  final Map<String, String> notes;
  final double overallScore;

  RefereeEvaluation({
    required this.context,
    required this.criteria,
    required this.grade,
    required this.notes,
    required this.overallScore,
  });

  factory RefereeEvaluation.fromJson(Map<String, dynamic> json) {
    return RefereeEvaluation(
      context: json['context'] ?? {},
      criteria: (json['criteria'] as List<dynamic>?)
              ?.map((e) => Criterion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      grade: json['grade'] ?? '',
      notes: Map<String, String>.from(json['notes'] ?? {}),
      overallScore: (json['overall_score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Criterion {
  final String key;
  final String label;
  final dynamic rawValue;
  final double? score;
  final double weight;

  Criterion({
    required this.key,
    required this.label,
    required this.rawValue,
    this.score,
    required this.weight,
  });

  factory Criterion.fromJson(Map<String, dynamic> json) {
    return Criterion(
      key: json['key'] ?? '',
      label: json['label'] ?? '',
      rawValue: json['raw_value'],
      score: (json['score'] as num?)?.toDouble(),
      weight: (json['weight'] as num).toDouble(),
    );
  }
}