import 'dart:convert';

class AnalysisResult {
  final bool ok;
  final Summary? summary;
  final String? annotatedVideoUrl;
  final String? eventsCsvUrl;
  final String? reportPdfUrl;
  final String? snapshotsDir;
  final String? runDir;
  final String? error;

  AnalysisResult({
    required this.ok,
    this.summary,
    this.annotatedVideoUrl,
    this.eventsCsvUrl,
    this.reportPdfUrl,
    this.snapshotsDir,
    this.runDir,
    this.error,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      ok: json['ok'] ?? false,
      summary: json['summary'] != null ? Summary.fromJson(json['summary']) : null,
      annotatedVideoUrl: json['annotated_video_url'],
      eventsCsvUrl: json['events_csv_url'],
      reportPdfUrl: json['report_pdf_url'],
      snapshotsDir: json['snapshots_dir'],
      runDir: json['run_dir'],
      error: json['error'],
    );
  }
}

class Summary {
  final double fps;
  final int width;
  final int height;
  final int totalFrames;
  final int eventsCount;

  Summary({
    required this.fps,
    required this.width,
    required this.height,
    required this.totalFrames,
    required this.eventsCount,
  });

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      fps: (json['fps'] as num).toDouble(),
      width: json['width'] as int,
      height: json['height'] as int,
      totalFrames: json['total_frames'] as int,
      eventsCount: json['events_count'] as int,
    );
  }
}

class Run {
  final String run;
  final int? eventsCount;
  final bool? annotatedVideo;
  final bool? reportPdf;

  Run({
    required this.run,
    this.eventsCount,
    this.annotatedVideo,
    this.reportPdf,
  });

  factory Run.fromJson(Map<String, dynamic> json) {
    return Run(
      run: json['run'],
      eventsCount: json['events_count'],
      annotatedVideo: json['annotated_video'],
      reportPdf: json['report_pdf'],
    );
  }
}

/// Parsed content of /api/files/<run>/summary.json
class RunSummaryJson {
  final String? video;
  final double? fps;
  final int? width;
  final int? height;
  final int? totalFrames;
  final int? eventsCount;
  final String? eventsCsv;
  final String? reportPdf;
  final String? snapshotsDir; // absolute on server
  final String? runDirAbs;    // absolute on server
  final String runFolderRel;  // e.g. "video_analysis_2025.../"

  RunSummaryJson({
    required this.runFolderRel,
    this.video,
    this.fps,
    this.width,
    this.height,
    this.totalFrames,
    this.eventsCount,
    this.eventsCsv,
    this.reportPdf,
    this.snapshotsDir,
    this.runDirAbs,
  });

  factory RunSummaryJson.fromJson(String runFolderRel, Map<String, dynamic> json) {
    return RunSummaryJson(
      runFolderRel: runFolderRel,
      video: json['annotated_video'],
      fps: (json['fps'] as num?)?.toDouble(),
      width: json['width'] as int?,
      height: json['height'] as int?,
      totalFrames: json['total_frames'] as int?,
      eventsCount: json['events_count'] as int?,
      eventsCsv: json['events_csv'] as String?,
      reportPdf: json['report_pdf'] as String?,
      snapshotsDir: json['snapshots_dir'] as String?,
      runDirAbs: json['run_dir'] as String?,
    );
  }

  Summary? toSummary() {
    if (fps == null || width == null || height == null || totalFrames == null || eventsCount == null) return null;
    return Summary(
      fps: fps!,
      width: width!,
      height: height!,
      totalFrames: totalFrames!,
      eventsCount: eventsCount!,
    );
    // Note: not all runs may have full values; it's okay.
  }

  String get snapshotsDirRel {
    // server summary has absolute; we only need relative: runs/<...>/snapshots
    // but we already know the run folder: use it
    return "$runFolderRel/snapshots";
  }
}

class RunFilesUrls {
  final String? videoUrl;
  final String? csvUrl;
  final String? pdfUrl;
  RunFilesUrls({this.videoUrl, this.csvUrl, this.pdfUrl});
}
