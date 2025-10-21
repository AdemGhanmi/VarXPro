// lib/views/pages/BallGoalPage/controller/ballgoal_bloc.dart
import 'dart:io';
import 'package:VarXPro/views/pages/BallGoalPage/model/ballgoal_model.dart';
import 'package:VarXPro/views/pages/BallGoalPage/service/ballgoal_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


abstract class BallGoalEvent {}
class BallInOutEvent extends BallGoalEvent {
  final File image;
  BallInOutEvent(this.image);
}
class GoalCheckEvent extends BallGoalEvent {
  final File image;
  GoalCheckEvent(this.image);
}
class BallGoalState {
  final bool isLoading;
  final String? error;
  final BallInOutResponse? ballInOutResponse;
  final GoalCheckResponse? goalCheckResponse;
  BallGoalState({
    this.isLoading = false,
    this.error,
    this.ballInOutResponse,
    this.goalCheckResponse,
  });
  BallGoalState copyWith({
    bool? isLoading,
    String? error,
    BallInOutResponse? ballInOutResponse,
    GoalCheckResponse? goalCheckResponse,
  }) {
    return BallGoalState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      ballInOutResponse: ballInOutResponse ?? this.ballInOutResponse,
      goalCheckResponse: goalCheckResponse ?? this.goalCheckResponse,
    );
  }
}
class BallGoalBloc extends Bloc<BallGoalEvent, BallGoalState> {
  final BallGoalService service;
  BallGoalBloc(this.service) : super(BallGoalState()) {
    on<BallInOutEvent>(_onBallInOut);
    on<GoalCheckEvent>(_onGoalCheck);
  }
 
  Future<void> _onBallInOut(BallInOutEvent event, Emitter<BallGoalState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final response = await service.ballInOut(event.image);
      emit(state.copyWith(isLoading: false, ballInOutResponse: response));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
  Future<void> _onGoalCheck(GoalCheckEvent event, Emitter<BallGoalState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final response = await service.goalCheck(event.image);
      emit(state.copyWith(isLoading: false, goalCheckResponse: response));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}