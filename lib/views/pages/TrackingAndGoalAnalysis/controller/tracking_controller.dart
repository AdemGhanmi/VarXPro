// lib/views/pages/TrackingAndGoalAnalysis/controller/tracking_controller.dart
import 'dart:io';
import 'package:VarXPro/views/pages/TrackingAndGoalAnalysis/model/analysis_result.dart';
import 'package:VarXPro/views/pages/TrackingAndGoalAnalysis/service/tracking_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class TrackingEvent {}

class CheckHealthEvent extends TrackingEvent {}

class AnalyzeVideoEvent extends TrackingEvent {
  final File video;
  final double? detectionConfidence;
  final bool? showTrails;
  final bool? showSkeleton;
  final bool? showBoxes;
  final bool? showIds;
  final int? trailLength;
  final List<int>? goalLeft;
  final List<int>? goalRight;
  final bool? offsideEnabled;
  final String? attackDirection;
  final String? attackingTeam;
  final List<int>? lineStart;
  final List<int>? lineEnd;

  AnalyzeVideoEvent({
    required this.video,
    this.detectionConfidence,
    this.showTrails,
    this.showSkeleton,
    this.showBoxes,
    this.showIds,
    this.trailLength,
    this.goalLeft,
    this.goalRight,
    this.offsideEnabled,
    this.attackDirection,
    this.attackingTeam,
    this.lineStart,
    this.lineEnd,
  });
}

class CleanArtifactsEvent extends TrackingEvent {}

class TrackingState {
  final bool isLoading;
  final String? error;
  final HealthResponse? health;
  final AnalyzeResponse? analyzeResponse;
  final CleanResponse? cleanResponse;

  TrackingState({
    this.isLoading = false,
    this.error,
    this.health,
    this.analyzeResponse,
    this.cleanResponse,
  });

  TrackingState copyWith({
    bool? isLoading,
    String? error,
    HealthResponse? health,
    AnalyzeResponse? analyzeResponse,
    CleanResponse? cleanResponse,
  }) {
    return TrackingState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      health: health ?? this.health,
      analyzeResponse: analyzeResponse ?? this.analyzeResponse,
      cleanResponse: cleanResponse ?? this.cleanResponse,
    );
  }
}

class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  final TrackingService service;

  TrackingBloc(this.service) : super(TrackingState()) {
    on<CheckHealthEvent>(_onCheckHealth);
    on<AnalyzeVideoEvent>(_onAnalyzeVideo);
    on<CleanArtifactsEvent>(_onCleanArtifacts);
  }

  Future<void> _onCheckHealth(CheckHealthEvent event, Emitter<TrackingState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final health = await service.checkHealth();
      emit(state.copyWith(isLoading: false, health: health));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onAnalyzeVideo(AnalyzeVideoEvent event, Emitter<TrackingState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final response = await service.analyzeVideo(
        video: event.video,
        detectionConfidence: event.detectionConfidence,
        showTrails: event.showTrails,
        showSkeleton: event.showSkeleton,
        showBoxes: event.showBoxes,
        showIds: event.showIds,
        trailLength: event.trailLength,
        goalLeft: event.goalLeft,
        goalRight: event.goalRight,
        offsideEnabled: event.offsideEnabled,
        attackDirection: event.attackDirection,
        attackingTeam: event.attackingTeam,
        lineStart: event.lineStart,
        lineEnd: event.lineEnd,
      );
      emit(state.copyWith(isLoading: false, analyzeResponse: response));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onCleanArtifacts(CleanArtifactsEvent event, Emitter<TrackingState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final response = await service.cleanArtifacts();
      emit(state.copyWith(isLoading: false, cleanResponse: response));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}