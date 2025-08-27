// lib/views/key_field_lines_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:VarXPro/views/pages/FiledLinesPages/controller/perspective_controller.dart';
import 'package:VarXPro/views/pages/FiledLinesPages/service/perspective_service.dart';
import 'package:VarXPro/views/pages/FiledLinesPages/widgets/image_picker_widget.dart';

class KeyFieldLinesPage extends StatelessWidget {
  const KeyFieldLinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PerspectiveBloc(context.read<PerspectiveService>())
        ..add(CheckHealthEvent()),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A1B33),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF071628),
                Color(0xFF0D2B59),
              ],
            ),
          ),
          child: BlocConsumer<PerspectiveBloc, PerspectiveState>(
            listener: (context, state) {
              if (state.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.error!),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
              if (state.cleanResponse != null && state.cleanResponse!.ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cleaned ${state.cleanResponse!.removed} artifacts'),
                    backgroundColor: const Color(0xFF11FFB2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
                context.read<PerspectiveBloc>().add(CheckHealthEvent());
              }
            },
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Color(0xFF11FFB2)),
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.all(constraints.maxWidth * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Health Status Card
                        Card(
                          color: const Color(0xFF0D2B59).withOpacity(0.8),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'API Status',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: state.health != null && state.health!.status == 'healthy'
                                            ? const Color(0xFF11FFB2)
                                            : Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      state.health != null && state.health!.status == 'healthy'
                                          ? "Connected"
                                          : "Disconnected",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: state.health != null && state.health!.status == 'healthy'
                                            ? const Color(0xFF11FFB2)
                                            : Colors.redAccent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (state.health != null) ...[
                                  _buildStatusItem('Status', state.health!.status ?? "Unknown"),
                                  _buildStatusItem('Calibrated', state.health!.calibrated.toString()),
                                  if (state.health!.dstSize != null)
                                    _buildStatusItem(
                                      'Output Size',
                                      '${state.health!.dstSize!['width']}x${state.health!.dstSize!['height']}',
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Load Calibration Section
                        _buildSectionHeader('Load Calibration'),
                        const SizedBox(height: 10),
                        const LoadCalibrationForm(),
                        if (state.loadCalibrationResponse != null) ...[
                          const SizedBox(height: 10),
                          Card(
                            color: const Color(0xFF0D2B59).withOpacity(0.8),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildResultItem(
                                    'Calibration Loaded',
                                    state.loadCalibrationResponse!.ok.toString(),
                                    state.loadCalibrationResponse!.ok,
                                  ),
                                  if (state.loadCalibrationResponse!.calibrationFile != null)
                                    _buildResultItem(
                                      'Calibration File',
                                      state.loadCalibrationResponse!.calibrationFile!,
                                      false,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),

                        // Detect Field Lines Section
                        _buildSectionHeader('Detect Field Lines'),
                        const SizedBox(height: 10),
                        ImagePickerWidget(
                          onImagePicked: (File image) {
                            context.read<PerspectiveBloc>().add(DetectLinesEvent(image));
                          },
                          buttonText: 'Select Image for Detection',
                        ),
                        if (state.detectLinesResponse != null) ...[
                          const SizedBox(height: 20),
                          Card(
                            color: const Color(0xFF0D2B59).withOpacity(0.8),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildResultItem(
                                    'Detected Lines',
                                    '${state.detectLinesResponse!.lines?.length ?? 0} lines found',
                                    state.detectLinesResponse!.lines != null && state.detectLinesResponse!.lines!.isNotEmpty,
                                  ),
                                  if (state.detectLinesResponse!.uploadUrl != null)
                                    _buildResultItem(
                                      'Uploaded Image',
                                      state.detectLinesResponse!.uploadUrl!,
                                      false,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (state.detectLinesResponse!.annotatedUrl != null) ...[
                            const SizedBox(height: 10),
                            const Text(
                              'Annotated Image:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              constraints: BoxConstraints(
                                maxHeight: constraints.maxWidth * 0.5,
                                maxWidth: constraints.maxWidth * 0.9,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF11FFB2).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: '${PerspectiveService.baseUrl}${state.detectLinesResponse!.annotatedUrl}',
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation(Color(0xFF11FFB2)),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey[800],
                                    child: const Center(
                                      child: Icon(
                                        Icons.error_outline,
                                        color: Colors.redAccent,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],

                        // Calibration Form
                        const SizedBox(height: 20),
                        _buildSectionHeader('Set Calibration'),
                        const SizedBox(height: 10),
                        const CalibrationForm(),
                        if (state.calibrationResponse != null) ...[
                          const SizedBox(height: 10),
                          Card(
                            color: const Color(0xFF0D2B59).withOpacity(0.8),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildResultItem(
                                    'Calibration Set',
                                    state.calibrationResponse!.ok.toString(),
                                    state.calibrationResponse!.ok,
                                  ),
                                  if (state.calibrationResponse!.saved == true)
                                    _buildResultItem(
                                      'Saved As',
                                      state.calibrationResponse!.calibrationUrl ?? 'Not saved',
                                      false,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        // Transform Image Section
                        const SizedBox(height: 20),
                        _buildSectionHeader('Transform Image'),
                        const SizedBox(height: 10),
                        ImagePickerWidget(
                          onImagePicked: (File image) {
                            context.read<PerspectiveBloc>().add(TransformFrameEvent(image));
                          },
                          buttonText: 'Select Image to Transform',
                        ),
                        if (state.transformFrameResponse != null &&
                            state.transformFrameResponse!.birdsEyeUrl != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10),
                              const Text(
                                'Transformed Image:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                constraints: BoxConstraints(
                                  maxHeight: constraints.maxWidth * 0.5,
                                  maxWidth: constraints.maxWidth * 0.9,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF11FFB2).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl:
                                        '${PerspectiveService.baseUrl}${state.transformFrameResponse!.birdsEyeUrl}',
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation(Color(0xFF11FFB2)),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.grey[800],
                                      child: const Center(
                                        child: Icon(
                                          Icons.error_outline,
                                          color: Colors.redAccent,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                        // Transform Video Section
                        const SizedBox(height: 20),
                        _buildSectionHeader('Transform Video'),
                        const SizedBox(height: 10),
                        const VideoTransformForm(),
                        if (state.transformVideoResponse != null) ...[
                          const SizedBox(height: 10),
                          Card(
                            color: const Color(0xFF0D2B59).withOpacity(0.8),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildResultItem(
                                    'Video Transformed',
                                    state.transformVideoResponse!.ok.toString(),
                                    state.transformVideoResponse!.ok,
                                  ),
                                  if (state.transformVideoResponse!.outputUrl != null)
                                    _buildResultItem(
                                      'Output Video',
                                      state.transformVideoResponse!.outputUrl!,
                                      false,
                                    ),
                                  if (state.transformVideoResponse!.frames != null)
                                    _buildResultItem(
                                      'Processed Frames',
                                      state.transformVideoResponse!.frames.toString(),
                                      false,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (state.transformVideoResponse!.outputUrl != null) ...[
                            const SizedBox(height: 10),
                            const Text(
                              'Transformed Video:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            VideoPlayerWidget(
                              videoUrl: '${PerspectiveService.baseUrl}${state.transformVideoResponse!.outputUrl}',
                            ),
                          ],
                        ],

                        // Transform Point Section
                        const SizedBox(height: 20),
                        _buildSectionHeader('Transform Points'),
                        const SizedBox(height: 10),
                        const TransformPointForm(),
                        if (state.transformPointResponse != null) ...[
                          const SizedBox(height: 10),
                          Card(
                            color: const Color(0xFF0D2B59).withOpacity(0.8),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (state.transformPointResponse!.input != null)
                                    _buildResultItem(
                                      'Input',
                                      state.transformPointResponse!.input.toString(),
                                      false,
                                    ),
                                  if (state.transformPointResponse!.output != null)
                                    _buildResultItem(
                                      'Output',
                                      state.transformPointResponse!.output.toString(),
                                      false,
                                    ),
                                  if (state.transformPointResponse!.error != null)
                                    _buildResultItem(
                                      'Error',
                                      state.transformPointResponse!.error!,
                                      true,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildResultItem(String label, String value, bool isSuccess) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: isSuccess ? const Color(0xFF11FFB2) : Colors.white,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget pour afficher la vidéo
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    
    await _videoPlayerController.initialize();
    
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: false,
      looping: false,
      allowFullScreen: true,
      allowMuting: true,
      showControls: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: const Color(0xFF11FFB2),
        handleColor: const Color(0xFF11FFB2),
        backgroundColor: Colors.grey[700]!,
        bufferedColor: Colors.grey[500]!,
      ),
    );

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFF11FFB2)),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF11FFB2).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 200,
          child: Chewie(controller: _chewieController),
        ),
      ),
    );
  }
}

class CalibrationForm extends StatefulWidget {
  const CalibrationForm({super.key});

  @override
  _CalibrationFormState createState() => _CalibrationFormState();
}

class _CalibrationFormState extends State<CalibrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _points = List.generate(
      4, (_) => [TextEditingController(), TextEditingController()]);
  final _dstWidthController = TextEditingController(text: '800');
  final _dstHeightController = TextEditingController(text: '600');
  final _saveAsController = TextEditingController(text: 'my_pitch');

  @override
  void dispose() {
    for (var point in _points) {
      point[0].dispose();
      point[1].dispose();
    }
    _dstWidthController.dispose();
    _dstHeightController.dispose();
    _saveAsController.dispose();
    super.dispose();
  }

  String? _validateCoordinate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter coordinate';
    }
    final numValue = double.tryParse(value);
    if (numValue == null || numValue < 0) {
      return 'Enter a valid non-negative number';
    }
    return null;
  }

  String? _validateDimension(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter dimension';
    }
    final numValue = int.tryParse(value);
    if (numValue == null || numValue <= 0) {
      return 'Enter a valid positive integer';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0D2B59).withOpacity(0.8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              for (int i = 0; i < 4; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _points[i][0],
                          decoration: InputDecoration(
                            labelText: 'Point ${i + 1} X',
                            labelStyle: const TextStyle(color: Color(0xFF11FFB2)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: const Color(0xFF11FFB2).withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: const Color(0xFF11FFB2).withOpacity(0.3),
                              ),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF0D2B59).withOpacity(0.6),
                          ),
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          validator: _validateCoordinate,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _points[i][1],
                          decoration: InputDecoration(
                            labelText: 'Point ${i + 1} Y',
                            labelStyle: const TextStyle(color: Color(0xFF11FFB2)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: const Color(0xFF11FFB2).withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: const Color(0xFF11FFB2).withOpacity(0.3),
                              ),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF0D2B59).withOpacity(0.6),
                          ),
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          validator: _validateCoordinate,
                        ),
                      ),
                    ],
                  ),
                ),
              TextFormField(
                controller: _dstWidthController,
                decoration: InputDecoration(
                  labelText: 'Destination Width',
                  labelStyle: const TextStyle(color: Color(0xFF11FFB2)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:  BorderSide(
                      color: Color(0xFF11FFB2).withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:  BorderSide(
                      color: Color(0xFF11FFB2).withOpacity(0.3),
                    ),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF0D2B59).withOpacity(0.6),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                validator: _validateDimension,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dstHeightController,
                decoration: InputDecoration(
                  labelText: 'Destination Height',
                  labelStyle: const TextStyle(color: Color(0xFF11FFB2)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:  BorderSide(
                      color: Color(0xFF11FFB2).withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:  BorderSide(
                      color: Color(0xFF11FFB2).withOpacity(0.3),
                    ),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF0D2B59).withOpacity(0.6),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                validator: _validateDimension,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _saveAsController,
                decoration: InputDecoration(
                  labelText: 'Save As (Optional)',
                  labelStyle: const TextStyle(color: Color(0xFF11FFB2)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:  BorderSide(
                      color: Color(0xFF11FFB2).withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:  BorderSide(
                      color: Color(0xFF11FFB2).withOpacity(0.3),
                    ),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF0D2B59).withOpacity(0.6),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final sourcePoints = _points
                        .map((p) => [
                              double.parse(p[0].text),
                              double.parse(p[1].text),
                            ])
                        .toList();
                    context.read<PerspectiveBloc>().add(
                          SetCalibrationEvent(
                            sourcePoints: sourcePoints,
                            dstWidth: int.parse(_dstWidthController.text),
                            dstHeight: int.parse(_dstHeightController.text),
                            saveAs: _saveAsController.text.isEmpty
                                ? null
                                : _saveAsController.text,
                          ),
                        );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF11FFB2),
                  foregroundColor: const Color(0xFF0A1B33),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Set Calibration',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoadCalibrationForm extends StatefulWidget {
  const LoadCalibrationForm({super.key});

  @override
  _LoadCalibrationFormState createState() => _LoadCalibrationFormState();
}

class _LoadCalibrationFormState extends State<LoadCalibrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'my_pitch');

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0D2B59).withOpacity(0.8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Calibration Name',
                  labelStyle: const TextStyle(color: Color(0xFF11FFB2)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:  BorderSide(
                      color: Color(0xFF11FFB2).withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:  BorderSide(
                      color: Color(0xFF11FFB2).withOpacity(0.3),
                    ),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF0D2B59).withOpacity(0.6),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (value) => value!.isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    context.read<PerspectiveBloc>().add(
                          LoadCalibrationByNameEvent(_nameController.text),
                        );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF11FFB2),
                  foregroundColor: const Color(0xFF0A1B33),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Load Calibration by Name',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),
              ImagePickerWidget(
                onImagePicked: (File file) {
                  context.read<PerspectiveBloc>().add(
                        LoadCalibrationByFileEvent(file),
                      );
                },
                buttonText: 'Load Calibration from File',
                isCalibration: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TransformPointForm extends StatefulWidget {
  const TransformPointForm({super.key});

  @override
  _TransformPointFormState createState() => _TransformPointFormState();
}

class _TransformPointFormState extends State<TransformPointForm> {
  final _formKey = GlobalKey<FormState>();
  final _xController = TextEditingController();
  final _yController = TextEditingController();

  @override
  void dispose() {
    _xController.dispose();
    _yController.dispose();
    super.dispose();
  }

  String? _validateCoordinate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter coordinate';
    }
    final numValue = double.tryParse(value);
    if (numValue == null) {
      return 'Enter a valid number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0D2B59).withOpacity(0.8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _xController,
                      decoration: InputDecoration(
                        labelText: 'X Coordinate',
                        labelStyle: const TextStyle(color: Color(0xFF11FFB2)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:  BorderSide(
                            color: Color(0xFF11FFB2).withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:  BorderSide(
                            color: Color(0xFF11FFB2).withOpacity(0.3),
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF0D2B59).withOpacity(0.6),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      validator: _validateCoordinate,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _yController,
                      decoration: InputDecoration(
                        labelText: 'Y Coordinate',
                        labelStyle: const TextStyle(color: Color(0xFF11FFB2)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:  BorderSide(
                            color: Color(0xFF11FFB2).withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:  BorderSide(
                            color: Color(0xFF11FFB2).withOpacity(0.3),
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF0D2B59).withOpacity(0.6),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      validator: _validateCoordinate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          context.read<PerspectiveBloc>().add(
                                TransformPointEvent(
                                  double.parse(_xController.text),
                                  double.parse(_yController.text),
                                ),
                              );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF11FFB2),
                        foregroundColor: const Color(0xFF0A1B33),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Transform Point',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          context.read<PerspectiveBloc>().add(
                                InverseTransformPointEvent(
                                  double.parse(_xController.text),
                                  double.parse(_yController.text),
                                ),
                              );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1263A0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Inverse Transform',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VideoTransformForm extends StatefulWidget {
  const VideoTransformForm({super.key});

  @override
  _VideoTransformFormState createState() => _VideoTransformFormState();
}

class _VideoTransformFormState extends State<VideoTransformForm> {
  final _formKey = GlobalKey<FormState>();
  bool _overlayLines = true;
  String _codec = 'mp4v';

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0D2B59).withOpacity(0.8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _overlayLines,
                    activeColor: const Color(0xFF11FFB2),
                    onChanged: (value) {
                      setState(() {
                        _overlayLines = value ?? true;
                      });
                    },
                  ),
                  const Text(
                    'Overlay Lines',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(width: 20),
                  DropdownButton<String>(
                    value: _codec,
                    dropdownColor: const Color(0xFF0D2B59),
                    style: const TextStyle(color: Colors.white),
                    items: ['mp4v', 'h264']
                        .map((codec) => DropdownMenuItem(
                              value: codec,
                              child: Text(codec),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _codec = value ?? 'mp4v';
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ImagePickerWidget(
                onImagePicked: (File video) {
                  context.read<PerspectiveBloc>().add(
                        TransformVideoEvent(
                          video,
                          overlayLines: _overlayLines,
                          codec: _codec,
                        ),
                      );
                },
                buttonText: 'Select Video to Transform',
                isVideo: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}