import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:VarXPro/views/pages/FiledLinesPages/model/perspective_model.dart';
import 'package:VarXPro/views/pages/FiledLinesPages/service/perspective_service.dart';

abstract class PerspectiveEvent {}

class CheckHealthEvent extends PerspectiveEvent {}

class ResetCleanResponseEvent extends PerspectiveEvent {}

class DetectLinesEvent extends PerspectiveEvent {
  final File image;
  DetectLinesEvent(this.image);
}

class SetCalibrationEvent extends PerspectiveEvent {
  final List<List<double>> sourcePoints;
  final int dstWidth;
  final int dstHeight;
  final String? saveAs;
  SetCalibrationEvent({
    required this.sourcePoints,
    required this.dstWidth,
    required this.dstHeight,
    this.saveAs,
  });
}

class LoadCalibrationByNameEvent extends PerspectiveEvent {
  final String name;
  LoadCalibrationByNameEvent(this.name);
}

class LoadCalibrationByFileEvent extends PerspectiveEvent {
  final File calibrationFile;
  LoadCalibrationByFileEvent(this.calibrationFile);
}

class TransformFrameEvent extends PerspectiveEvent {
  final File image;
  TransformFrameEvent(this.image);
}

class TransformVideoEvent extends PerspectiveEvent {
  final File video;
  final bool overlayLines;
  final String codec;
  TransformVideoEvent(
    this.video, {
    this.overlayLines = true,
    this.codec = 'mp4v',
  });
}

class TransformPointEvent extends PerspectiveEvent {
  final double x;
  final double y;
  TransformPointEvent(this.x, this.y);
}

class InverseTransformPointEvent extends PerspectiveEvent {
  final double x;
  final double y;
  InverseTransformPointEvent(this.x, this.y);
}

class CleanEvent extends PerspectiveEvent {}

class PerspectiveState {
  final bool isLoading;
  final String? error;
  final HealthResponse? health;
  final DetectLinesResponse? detectLinesResponse;
  final CalibrationResponse? calibrationResponse;
  final LoadCalibrationResponse? loadCalibrationResponse;
  final TransformFrameResponse? transformFrameResponse;
  final TransformVideoResponse? transformVideoResponse;
  final TransformPointResponse? transformPointResponse;
  final TransformPointResponse? inversePointResponse;
  final CleanResponse? cleanResponse;
  final double? uploadProgress;

  PerspectiveState({
    this.isLoading = false,
    this.error,
    this.health,
    this.detectLinesResponse,
    this.calibrationResponse,
    this.loadCalibrationResponse,
    this.transformFrameResponse,
    this.transformVideoResponse,
    this.transformPointResponse,
    this.inversePointResponse,
    this.cleanResponse,
    this.uploadProgress,
  });

  PerspectiveState copyWith({
    bool? isLoading,
    String? error,
    HealthResponse? health,
    DetectLinesResponse? detectLinesResponse,
    CalibrationResponse? calibrationResponse,
    LoadCalibrationResponse? loadCalibrationResponse,
    TransformFrameResponse? transformFrameResponse,
    TransformVideoResponse? transformVideoResponse,
    TransformPointResponse? transformPointResponse,
    TransformPointResponse? inversePointResponse,
    CleanResponse? cleanResponse,
    double? uploadProgress,
  }) {
    return PerspectiveState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      health: health ?? this.health,
      detectLinesResponse: detectLinesResponse ?? this.detectLinesResponse,
      calibrationResponse: calibrationResponse ?? this.calibrationResponse,
      loadCalibrationResponse: loadCalibrationResponse ?? this.loadCalibrationResponse,
      transformFrameResponse: transformFrameResponse ?? this.transformFrameResponse,
      transformVideoResponse: transformVideoResponse ?? this.transformVideoResponse,
      transformPointResponse: transformPointResponse ?? this.transformPointResponse,
      inversePointResponse: inversePointResponse ?? this.inversePointResponse,
      cleanResponse: cleanResponse ?? this.cleanResponse,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }
}

class PerspectiveBloc extends Bloc<PerspectiveEvent, PerspectiveState> {
  final PerspectiveService service;

  PerspectiveBloc(this.service) : super(PerspectiveState()) {
    on<CheckHealthEvent>(_onCheckHealth);
    on<DetectLinesEvent>(_onDetectLines);
    on<SetCalibrationEvent>(_onSetCalibration);
    on<LoadCalibrationByNameEvent>(_onLoadCalibrationByName);
    on<LoadCalibrationByFileEvent>(_onLoadCalibrationByFile);
    on<TransformFrameEvent>(_onTransformFrame);
    on<TransformVideoEvent>(_onTransformVideo);
    on<TransformPointEvent>(_onTransformPoint);
    on<InverseTransformPointEvent>(_onInverseTransformPoint);
    on<CleanEvent>(_onClean);
on<ResetCleanResponseEvent>((event, emit) {
  emit(state.copyWith(cleanResponse: null));
});
  }

  Future<void> _onCheckHealth(CheckHealthEvent event, Emitter<PerspectiveState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final health = await service.checkHealth();
      emit(state.copyWith(isLoading: false, health: health));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onDetectLines(DetectLinesEvent event, Emitter<PerspectiveState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final response = await service.detectLines(event.image);
      emit(state.copyWith(isLoading: false, detectLinesResponse: response));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onSetCalibration(SetCalibrationEvent event, Emitter<PerspectiveState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final response = await service.setCalibration(
        sourcePoints: event.sourcePoints,
        dstWidth: event.dstWidth,
        dstHeight: event.dstHeight,
        saveAs: event.saveAs,
      );
      emit(state.copyWith(isLoading: false, calibrationResponse: response));
      add(CheckHealthEvent());
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onLoadCalibrationByName(LoadCalibrationByNameEvent event, Emitter<PerspectiveState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final response = await service.loadCalibrationByName(event.name);
      emit(state.copyWith(isLoading: false, loadCalibrationResponse: response));
      if (response.ok) add(CheckHealthEvent());
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onLoadCalibrationByFile(LoadCalibrationByFileEvent event, Emitter<PerspectiveState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final response = await service.loadCalibrationByFile(event.calibrationFile);
      emit(state.copyWith(isLoading: false, loadCalibrationResponse: response));
      if (response.ok) add(CheckHealthEvent());
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onTransformFrame(TransformFrameEvent event, Emitter<PerspectiveState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final response = await service.transformFrame(event.image);
      emit(state.copyWith(isLoading: false, transformFrameResponse: response));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onTransformVideo(TransformVideoEvent event, Emitter<PerspectiveState> emit) async {
    emit(state.copyWith(isLoading: true, error: null, uploadProgress: 0.0));
    try {
      final response = await service.transformVideo(
        event.video,
        overlayLines: event.overlayLines,
        codec: event.codec,
        onProgress: (sent, total) {
          emit(state.copyWith(uploadProgress: sent / total));
        },
      );
      emit(state.copyWith(isLoading: false, transformVideoResponse: response, uploadProgress: null));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString(), uploadProgress: null));
    }
  }

  Future<void> _onTransformPoint(TransformPointEvent event, Emitter<PerspectiveState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final response = await service.transformPoint(event.x, event.y);
      emit(state.copyWith(isLoading: false, transformPointResponse: response));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onInverseTransformPoint(InverseTransformPointEvent event, Emitter<PerspectiveState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final response = await service.inverseTransformPoint(event.x, event.y);
      emit(state.copyWith(isLoading: false, inversePointResponse: response));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onClean(CleanEvent event, Emitter<PerspectiveState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final response = await service.clean();
      emit(state.copyWith(
        isLoading: false,
        cleanResponse: response,
        detectLinesResponse: null,
        transformFrameResponse: null,
        transformVideoResponse: null,
      ));
      add(CheckHealthEvent());
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void _onResetCleanResponse(ResetCleanResponseEvent event, Emitter<PerspectiveState> emit) {
    emit(state.copyWith(cleanResponse: null, error: null));
  }
}