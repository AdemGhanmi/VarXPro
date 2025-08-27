// lib/models/referee_model.dart
class HealthResponse {
  final String status;
  final bool modelLoaded;
  final Map<String, int>? classes;

  HealthResponse({
    required this.status,
    required this.modelLoaded,
    this.classes,
  });

  factory HealthResponse.fromJson(Map<String, dynamic> json) {
    return HealthResponse(
      status: json['status'] as String,
      modelLoaded: json['model_loaded'] as bool,
      classes: json['classes'] != null
          ? Map<String, int>.from(json['classes'])
          : null,
    );
  }
}

class AnalyzeResponse {
  final bool ok;
  final double confThreshold;
  final Artifacts artifacts;
  final Summary summary;
  final String reportText;

  AnalyzeResponse({
    required this.ok,
    required this.confThreshold,
    required this.artifacts,
    required this.summary,
    required this.reportText,
  });

  factory AnalyzeResponse.fromJson(Map<String, dynamic> json) {
    return AnalyzeResponse(
      ok: json['ok'] as bool,
      confThreshold: (json['conf_threshold'] as num).toDouble(),
      artifacts: Artifacts.fromJson(json['artifacts'] as Map<String, dynamic>),
      summary: Summary.fromJson(json['summary'] as Map<String, dynamic>),
      reportText: json['report_text'] as String,
    );
  }
}

class Artifacts {
  final String reportUrl;
  final String metricsUrl;
  final String heatmapUrl;
  final String speedPlotUrl;
  final String proximityPlotUrl;
  final String outputVideoUrl;
  final List<String> sampleFramesUrls;

  Artifacts({
    required this.reportUrl,
    required this.metricsUrl,
    required this.heatmapUrl,
    required this.speedPlotUrl,
    required this.proximityPlotUrl,
    required this.outputVideoUrl,
    required this.sampleFramesUrls,
  });

  factory Artifacts.fromJson(Map<String, dynamic> json) {
    return Artifacts(
      reportUrl: json['report_url'] as String,
      metricsUrl: json['metrics_url'] as String,
      heatmapUrl: json['heatmap_url'] as String,
      speedPlotUrl: json['speed_plot_url'] as String,
      proximityPlotUrl: json['proximity_plot_url'] as String,
      outputVideoUrl: json['output_video_url'] as String,
      sampleFramesUrls: (json['sample_frames_urls'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }
}

class Summary {
  final double totalDistanceKm;
  final double avgSpeedKmH;
  final double maxSpeedKmH;
  final int sprints;
  final double distanceFirstHalfKm;
  final double distanceSecondHalfKm;

  Summary({
    required this.totalDistanceKm,
    required this.avgSpeedKmH,
    required this.maxSpeedKmH,
    required this.sprints,
    required this.distanceFirstHalfKm,
    required this.distanceSecondHalfKm,
  });

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      totalDistanceKm: (json['total_distance_km'] as num).toDouble(),
      avgSpeedKmH: (json['avg_speed_km_h'] as num).toDouble(),
      maxSpeedKmH: (json['max_speed_km_h'] as num).toDouble(),
      sprints: json['sprints'] as int,
      distanceFirstHalfKm: (json['distance_first_half_km'] as num).toDouble(),
      distanceSecondHalfKm: (json['distance_second_half_km'] as num).toDouble(),
    );
  }
}

class CleanResponse {
  final bool ok;
  final int removed;

  CleanResponse({
    required this.ok,
    required this.removed,
  });

  factory CleanResponse.fromJson(Map<String, dynamic> json) {
    return CleanResponse(
      ok: json['ok'] as bool,
      removed: json['removed'] as int,
    );
  }
}