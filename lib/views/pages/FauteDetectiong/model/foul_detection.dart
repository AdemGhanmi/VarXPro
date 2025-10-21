class AnalysisResult {
  final bool ok;
  final Inference? inference;
  final Map<String, dynamic>? evaluation;
  final String? error;

  AnalysisResult({
    required this.ok,
    this.inference,
    this.evaluation,
    this.error,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      ok: json['ok'] ?? false,
      inference: json['inference'] != null ? Inference.fromJson(json['inference']) : null,
      evaluation: json['evaluation'],
      error: json['error'],
    );
  }
}

class Inference {
  final String actionTopLabel;
  final double actionTopProb;
  final String actionTop2Label;
  final double actionTop2Prob;
  final Map<String, double> severityMap;
  final String finalDecision;
  final List<String> notes;
  final String? snapshotPath;

  Inference({
    required this.actionTopLabel,
    required this.actionTopProb,
    required this.actionTop2Label,
    required this.actionTop2Prob,
    required this.severityMap,
    required this.finalDecision,
    required this.notes,
    this.snapshotPath,
  });

  factory Inference.fromJson(Map<String, dynamic> json) {
    final actionTop = List<dynamic>.from(json['action_top'] ?? []);
    final actionTop2 = List<dynamic>.from(json['action_top2'] ?? []);
    return Inference(
      actionTopLabel: actionTop.isNotEmpty ? actionTop[0].toString() : '',
      actionTopProb: actionTop.length > 1 ? (actionTop[1] as num).toDouble() : 0.0,
      actionTop2Label: actionTop2.isNotEmpty ? actionTop2[0].toString() : '',
      actionTop2Prob: actionTop2.length > 1 ? (actionTop2[1] as num).toDouble() : 0.0,
      severityMap: (json['severity_map'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, (value as num).toDouble())),
      finalDecision: json['final_decision'] ?? '',
      notes: List<String>.from(json['notes'] ?? []),
      snapshotPath: json['snapshot_path'],
    );
  }
}