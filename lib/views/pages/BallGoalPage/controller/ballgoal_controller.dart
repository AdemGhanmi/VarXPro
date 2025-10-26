// ballgoal_bloc.dart (updated with PingEvent support)
import 'dart:io';
import 'package:VarXPro/views/pages/BallGoalPage/model/ballgoal_model.dart';
import 'package:VarXPro/views/pages/BallGoalPage/service/ballgoal_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class BallGoalEvent {}

class PingEvent extends BallGoalEvent {}

class BallInOutEvent extends BallGoalEvent {
  final File file;
  final bool isVideo;
  final String? testType;

  BallInOutEvent(this.file, {this.isVideo = false, this.testType});
}

class BallGoalState {
  final bool isLoading;
  final String? error;
  final BallInOutResponse? ballInOutResponse;
  final BallInOutVideoResponse? ballInOutVideoResponse;
  final String? currentTestType;

  BallGoalState({
    this.isLoading = false,
    this.error,
    this.ballInOutResponse,
    this.ballInOutVideoResponse,
    this.currentTestType,
  });

  BallGoalState copyWith({
    bool? isLoading,
    String? error,
    BallInOutResponse? ballInOutResponse,
    BallInOutVideoResponse? ballInOutVideoResponse,
    String? currentTestType,
  }) {
    return BallGoalState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      ballInOutResponse: ballInOutResponse ?? this.ballInOutResponse,
      ballInOutVideoResponse: ballInOutVideoResponse ?? this.ballInOutVideoResponse,
      currentTestType: currentTestType ?? this.currentTestType,
    );
  }
}

class BallGoalBloc extends Bloc<BallGoalEvent, BallGoalState> {
  final BallGoalService service;

  BallGoalBloc(this.service) : super(BallGoalState()) {
    on<PingEvent>(_onPing);
    on<BallInOutEvent>(_onBallInOut);
  }

  Future<void> _onPing(PingEvent event, Emitter<BallGoalState> emit) async {
    // Optional: Perform any initialization or ping logic here
    // For now, just emit the initial state
    emit(state);
  }

  Future<void> _onBallInOut(BallInOutEvent event, Emitter<BallGoalState> emit) async {
    emit(state.copyWith(
      isLoading: true,
      error: null,
      ballInOutResponse: null,
      ballInOutVideoResponse: null,
      currentTestType: null,
    ));
    try {
      if (event.isVideo) {
        final response = await service.ballInOutVideo(event.file);
        emit(state.copyWith(
          isLoading: false,
          ballInOutVideoResponse: response,
          currentTestType: event.testType,
        ));
      } else {
        final response = await service.ballInOut(event.file);
        emit(state.copyWith(
          isLoading: false,
          ballInOutResponse: response,
          currentTestType: null,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
        currentTestType: null,
      ));
    }
  }
}
