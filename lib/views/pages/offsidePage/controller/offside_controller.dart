import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';

import '../model/offside_model.dart';
import '../service/offside_service.dart';

abstract class OffsideEvent {}

class PingEvent extends OffsideEvent {}

class DetectOffsideSingleEvent extends OffsideEvent {
  final File image;
  final String attackDirection;
  final List<int>? lineStart;
  final List<int>? lineEnd;
  final bool returnFile;
  DetectOffsideSingleEvent({
    required this.image,
    this.attackDirection = 'right',
    this.lineStart,
    this.lineEnd,
    this.returnFile = false,
  });
}

class DetectOffsideVideoEvent extends OffsideEvent {
  final File video;
  final String attackDirection;
  final List<int>? lineStart;
  final List<int>? lineEnd;
  final bool returnFile;
  DetectOffsideVideoEvent({
    required this.video,
    this.attackDirection = 'right',
    this.lineStart,
    this.lineEnd,
    this.returnFile = false,
  });
}

class UpdatePickedImageEvent extends OffsideEvent {
  final File image;
  UpdatePickedImageEvent(this.image);
}

class CancelCurrentRequestEvent extends OffsideEvent {}

class _ProgressEvent extends OffsideEvent {
  final double? upload;   // 0..1
  final double? download; // 0..1
  _ProgressEvent({this.upload, this.download});
}

class OffsideState {
  final bool isLoading;
  final String? error;
  final PingResponse? pingResponse;
  final OffsideFrameResponse? offsideFrameResponse;
  final OffsideVideoResponse? videoResponse;
  final File? pickedImage;

  final double uploadProgress;
  final double downloadProgress;
  final bool cancellable;

  OffsideState({
    this.isLoading = false,
    this.error,
    this.pingResponse,
    this.offsideFrameResponse,
    this.videoResponse,
    this.pickedImage,
    this.uploadProgress = 0.0,
    this.downloadProgress = 0.0,
    this.cancellable = false,
  });

  OffsideState copyWith({
    bool? isLoading,
    String? error,
    PingResponse? pingResponse,
    OffsideFrameResponse? offsideFrameResponse,
    OffsideVideoResponse? videoResponse,
    File? pickedImage,
    double? uploadProgress,
    double? downloadProgress,
    bool? cancellable,
  }) {
    return OffsideState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      pingResponse: pingResponse ?? this.pingResponse,
      offsideFrameResponse: offsideFrameResponse ?? this.offsideFrameResponse,
      videoResponse: videoResponse ?? this.videoResponse,
      pickedImage: pickedImage ?? this.pickedImage,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      cancellable: cancellable ?? this.cancellable,
    );
  }
}

class OffsideBloc extends Bloc<OffsideEvent, OffsideState> {
  final OffsideService service;
  CancelToken? _cancelToken;

  OffsideBloc(this.service) : super(OffsideState()) {
    on<PingEvent>(_onPing);
    on<DetectOffsideSingleEvent>(_onDetectOffsideSingle);
    on<DetectOffsideVideoEvent>(_onDetectOffsideVideo);
    on<UpdatePickedImageEvent>(_onUpdatePickedImage);
    on<CancelCurrentRequestEvent>(_onCancel);
    on<_ProgressEvent>(_onProgress);
  }

  Future<void> _onPing(PingEvent event, Emitter<OffsideState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final response = await service.ping();
      emit(state.copyWith(isLoading: false, pingResponse: response));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onDetectOffsideSingle(
      DetectOffsideSingleEvent event, Emitter<OffsideState> emit) async {
    _cancelToken = CancelToken();
    emit(state.copyWith(
      isLoading: true,
      error: null,
      uploadProgress: 0,
      downloadProgress: 0,
      cancellable: true,
    ));
    try {
      final resp = await service.detectOffsideSingle(
        image: event.image,
        attackDirection: event.attackDirection,
        lineStart: event.lineStart,
        lineEnd: event.lineEnd,
        returnFile: event.returnFile,
        cancelToken: _cancelToken,
        onSendProgress: (s, t) => add(_ProgressEvent(upload: t == 0 ? 0 : s / t)),
        onReceiveProgress: (r, t) => add(_ProgressEvent(download: t == 0 ? 0 : r / t)),
      );
      emit(state.copyWith(
        isLoading: false,
        offsideFrameResponse: resp,
        uploadProgress: 1,
        downloadProgress: 1,
        cancellable: false,
      ));
    } on DioException catch (e) {
      final msg = e.type == DioExceptionType.receiveTimeout
          ? 'Processing exceeded the timeout. Timeout increased—retry.'
          : e.message ?? e.toString();
      emit(state.copyWith(isLoading: false, error: msg, cancellable: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString(), cancellable: false));
    }
  }

  Future<void> _onDetectOffsideVideo(
      DetectOffsideVideoEvent event, Emitter<OffsideState> emit) async {
    _cancelToken = CancelToken();
    emit(state.copyWith(
      isLoading: true,
      error: null,
      uploadProgress: 0,
      downloadProgress: 0,
      cancellable: true,
    ));
    try {
      final resp = await service.detectOffsideVideo(
        video: event.video,
        attackDirection: event.attackDirection,
        lineStart: event.lineStart,
        lineEnd: event.lineEnd,
        returnFile: event.returnFile,
        cancelToken: _cancelToken,
        onSendProgress: (s, t) => add(_ProgressEvent(upload: t == 0 ? 0 : s / t)),
        onReceiveProgress: (r, t) => add(_ProgressEvent(download: t == 0 ? 0 : r / t)),
      );
      emit(state.copyWith(
        isLoading: false,
        videoResponse: resp,
        uploadProgress: 1,
        downloadProgress: 1,
        cancellable: false,
      ));
    } on DioException catch (e) {
      final msg = e.type == DioExceptionType.receiveTimeout
          ? 'Video processing exceeded the timeout. Timeout increased—retry.'
          : e.message ?? e.toString();
      emit(state.copyWith(isLoading: false, error: msg, cancellable: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString(), cancellable: false));
    }
  }

  Future<void> _onUpdatePickedImage(
      UpdatePickedImageEvent event, Emitter<OffsideState> emit) async {
    emit(state.copyWith(pickedImage: event.image));
  }

  Future<void> _onCancel(CancelCurrentRequestEvent event, Emitter<OffsideState> emit) async {
    try {
      _cancelToken?.cancel('Cancelled by user');
    } catch (_) {}
    emit(state.copyWith(isLoading: false, cancellable: false));
  }

  void _onProgress(_ProgressEvent event, Emitter<OffsideState> emit) {
    emit(state.copyWith(
      uploadProgress: event.upload ?? state.uploadProgress,
      downloadProgress: event.download ?? state.downloadProgress,
    ));
  }
}