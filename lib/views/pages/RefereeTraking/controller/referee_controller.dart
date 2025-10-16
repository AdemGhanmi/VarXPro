// views/pages/RefereeTraking/controller/referee_bloc.dart
import 'dart:io';
import 'package:VarXPro/views/pages/RefereeTraking/model/referee_analysis.dart';
import 'package:VarXPro/views/pages/RefereeTraking/service/referee_api_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class RefereeEvent {}

class CheckHealthEvent extends RefereeEvent {}

class AnalyzeVideoEvent extends RefereeEvent {
  final File video;
  final String attack;
  final String attacking_team;
  final File? refLog;
  final String? decisionsJson;

  AnalyzeVideoEvent({
    required this.video,
    this.attack = 'left',
    this.attacking_team = 'team1',
    this.refLog,
    this.decisionsJson,
  });
}

class RefereeState {
  final bool isLoading;
  final String? error;
  final HealthResponse? health;
  final AnalyzeResponse? analyzeResponse;

  RefereeState({
    this.isLoading = false,
    this.error,
    this.health,
    this.analyzeResponse,
  });

  RefereeState copyWith({
    bool? isLoading,
    String? error,
    HealthResponse? health,
    AnalyzeResponse? analyzeResponse,
  }) {
    return RefereeState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      health: health ?? this.health,
      analyzeResponse: analyzeResponse ?? this.analyzeResponse,
    );
  }
}

class RefereeBloc extends Bloc<RefereeEvent, RefereeState> {
  final RefereeService service;

  RefereeBloc(this.service) : super(RefereeState()) {
    on<CheckHealthEvent>(_onCheckHealth);
    on<AnalyzeVideoEvent>(_onAnalyzeVideo);
  }

  Future<void> _onCheckHealth(
      CheckHealthEvent event, Emitter<RefereeState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final health = await service.checkHealth();
      emit(state.copyWith(isLoading: false, health: health));
    } catch (e) {
      print('Health check error: ${e.toString()}');
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
        attack: event.attack,
        attacking_team: event.attacking_team,
        refLog: event.refLog,
        decisionsJson: event.decisionsJson,
      );
      emit(state.copyWith(isLoading: false, analyzeResponse: response));
    } catch (e) {
      print('Analyze video error: ${e.toString()}');
      emit(state.copyWith(
        isLoading: false,
        error: e.toString().contains('FileNotFoundError')
            ? 'Backend model file missing. Contact administrator.'
            : 'Failed to analyze video: $e',
      ));
    }
  }
}