import 'dart:io';
import 'package:VarXPro/views/pages/offsidePage/model/offside_model.dart';
import 'package:VarXPro/views/pages/offsidePage/service/offside_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class OffsideEvent {}

class PingEvent extends OffsideEvent {}

class DetectOffsideSingleEvent extends OffsideEvent {
  final File image;
  final String attackDirection;
  final List<int>? lineStart;
  final List<int>? lineEnd;

  DetectOffsideSingleEvent({
    required this.image,
    this.attackDirection = 'right',
    this.lineStart,
    this.lineEnd,
  });
}

class DetectOffsideBatchEvent extends OffsideEvent {
  final List<File>? images;
  final File? zipFile;
  final String attackDirection;
  final String lineMode;
  final List<int>? lineStart;
  final List<int>? lineEnd;

  DetectOffsideBatchEvent({
    this.images,
    this.zipFile,
    this.attackDirection = 'right',
    this.lineMode = 'auto',
    this.lineStart,
    this.lineEnd,
  });
}

class ListRunsEvent extends OffsideEvent {}

class ClearRunsEvent extends OffsideEvent {}

class UpdatePickedImageEvent extends OffsideEvent {
  final File image;

  UpdatePickedImageEvent(this.image);
}

class OffsideState {
  final bool isLoading;
  final String? error;
  final PingResponse? pingResponse;
  final OffsideFrameResponse? offsideFrameResponse;
  final OffsideBatchResponse? offsideBatchResponse;
  final RunsResponse? runsResponse;
  final File? pickedImage;

  OffsideState({
    this.isLoading = false,
    this.error,
    this.pingResponse,
    this.offsideFrameResponse,
    this.offsideBatchResponse,
    this.runsResponse,
    this.pickedImage,
  });

  OffsideState copyWith({
    bool? isLoading,
    String? error,
    PingResponse? pingResponse,
    OffsideFrameResponse? offsideFrameResponse,
    OffsideBatchResponse? offsideBatchResponse,
    RunsResponse? runsResponse,
    File? pickedImage,
  }) {
    return OffsideState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      pingResponse: pingResponse ?? this.pingResponse,
      offsideFrameResponse: offsideFrameResponse ?? this.offsideFrameResponse,
      offsideBatchResponse: offsideBatchResponse ?? this.offsideBatchResponse,
      runsResponse: runsResponse ?? this.runsResponse,
      pickedImage: pickedImage ?? this.pickedImage,
    );
  }
}

class OffsideBloc extends Bloc<OffsideEvent, OffsideState> {
  final OffsideService service;

  OffsideBloc(this.service) : super(OffsideState()) {
    on<PingEvent>(_onPing);
    on<DetectOffsideSingleEvent>(_onDetectOffsideSingle);
    on<DetectOffsideBatchEvent>(_onDetectOffsideBatch);
    on<ListRunsEvent>(_onListRuns);
    on<ClearRunsEvent>(_onClearRuns);
    on<UpdatePickedImageEvent>(_onUpdatePickedImage);
  }

  Future<void> _onPing(PingEvent event, Emitter<OffsideState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final response = await service.ping();
      emit(state.copyWith(isLoading: false, pingResponse: response));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onDetectOffsideSingle(
      DetectOffsideSingleEvent event, Emitter<OffsideState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final response = await service.detectOffsideSingle(
        image: event.image,
        attackDirection: event.attackDirection,
        lineStart: event.lineStart,
        lineEnd: event.lineEnd,
      );
      emit(state.copyWith(isLoading: false, offsideFrameResponse: response));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onDetectOffsideBatch(
      DetectOffsideBatchEvent event, Emitter<OffsideState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final response = await service.detectOffsideBatch(
        images: event.images,
        zipFile: event.zipFile,
        attackDirection: event.attackDirection,
        lineMode: event.lineMode,
        lineStart: event.lineStart,
        lineEnd: event.lineEnd,
      );
      emit(state.copyWith(isLoading: false, offsideBatchResponse: response));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onListRuns(ListRunsEvent event, Emitter<OffsideState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final response = await service.listRuns();
      emit(state.copyWith(isLoading: false, runsResponse: response));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onClearRuns(ClearRunsEvent event, Emitter<OffsideState> emit) async {
    emit(state.copyWith(
      isLoading: false,
      offsideFrameResponse: null,
      offsideBatchResponse: null,
      runsResponse: null,
      pickedImage: null,
    ));
  }

  Future<void> _onUpdatePickedImage(
      UpdatePickedImageEvent event, Emitter<OffsideState> emit) async {
    emit(state.copyWith(pickedImage: event.image));
  }
}