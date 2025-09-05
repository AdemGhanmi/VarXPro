import 'dart:io';
import 'package:VarXPro/views/pages/RefereeTraking/model/referee_analysis.dart';
import 'package:VarXPro/views/pages/RefereeTraking/service/referee_api_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class RefereeEvent {}

class CheckHealthEvent extends RefereeEvent {}

class AnalyzeVideoEvent extends RefereeEvent {
  final File video;
  final double confThreshold;
  AnalyzeVideoEvent({required this.video, this.confThreshold = 0.3});
}

class CleanFilesEvent extends RefereeEvent {}

class RefereeState {
  final bool isLoading;
  final String? error;
  final HealthResponse? health;
  final AnalyzeResponse? analyzeResponse;
  final CleanResponse? cleanResponse;
  final String? reportText;

  RefereeState({
    this.isLoading = false,
    this.error,
    this.health,
    this.analyzeResponse,
    this.cleanResponse,
    this.reportText,
  });

  RefereeState copyWith({
    bool? isLoading,
    String? error,
    HealthResponse? health,
    AnalyzeResponse? analyzeResponse,
    CleanResponse? cleanResponse,
    String? reportText,
  }) {
    return RefereeState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      health: health ?? this.health,
      analyzeResponse: analyzeResponse ?? this.analyzeResponse,
      cleanResponse: cleanResponse ?? this.cleanResponse,
      reportText: reportText ?? this.reportText,
    );
  }
}

class RefereeBloc extends Bloc<RefereeEvent, RefereeState> {
  final RefereeService service;

  RefereeBloc(this.service) : super(RefereeState()) {
    on<CheckHealthEvent>(_onCheckHealth);
    on<AnalyzeVideoEvent>(_onAnalyzeVideo);
    on<CleanFilesEvent>(_onCleanFiles);
  }

  Future<void> _onCheckHealth(
      CheckHealthEvent event, Emitter<RefereeState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final health = await service.checkHealth();
      emit(state.copyWith(isLoading: false, health: health));
    } catch (e) {
      print('Health check error: ${e.toString()}'); // Added logging
      emit(state.copyWith(
        isLoading: false,
        error: e.toString().contains('FileNotFoundError')
            ? 'Backend model file missing. Contact administrator.'
            : 'Failed to check API health: $e',
      ));
    }
  }

  Future<void> _onAnalyzeVideo(
      AnalyzeVideoEvent event, Emitter<RefereeState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final response = await service.analyzeVideo(
        video: event.video,
        confThreshold: event.confThreshold,
      );
      String reportText = response.reportText ?? '';
      if (reportText.isEmpty && response.artifacts.reportUrl.isNotEmpty) {
        reportText = await service.getArtifactText(response.artifacts.reportUrl);
      }
      if (!response.ok) {
        emit(state.copyWith(
          isLoading: false,
          error: reportText.isNotEmpty
              ? reportText
              : 'Analysis failed on server.',
        ));
        return;
      }
      emit(state.copyWith(isLoading: false, analyzeResponse: response, reportText: reportText));
    } catch (e) {
      print('Analyze video error: ${e.toString()}'); // Added logging for exact error
      emit(state.copyWith(
        isLoading: false,
        error: e.toString().contains('FileNotFoundError')
            ? 'Backend model file missing. Contact administrator.'
            : 'Failed to analyze video: $e',
      ));
    }
  }

  Future<void> _onCleanFiles(
      CleanFilesEvent event, Emitter<RefereeState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final response = await service.clean();
      emit(state.copyWith(isLoading: false, cleanResponse: response));
    } catch (e) {
      print('Clean files error: ${e.toString()}'); // Added logging
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to clean server files: $e',
      ));
    }
  }
}
