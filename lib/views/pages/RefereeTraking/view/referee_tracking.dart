// lib/views/pages/RefereeTraking/referee_tracking.dart
import 'dart:io';
import 'package:VarXPro/views/pages/RefereeTraking/controller/referee_controller.dart';
import 'package:VarXPro/views/pages/RefereeTraking/service/referee_api_service.dart';
import 'package:VarXPro/views/pages/RefereeTraking/widgets/file_picker_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';


class RefereeTrackingSystemPage extends StatelessWidget {
  const RefereeTrackingSystemPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RefereeBloc(context.read<RefereeService>())
        ..add(CheckHealthEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Referee Tracking System'),
        ),
        body: BlocBuilder<RefereeBloc, RefereeState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.error != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${state.error}')),
                );
              });
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Health Status
                  Text(
                    'API Status: ${state.health?.status ?? "Unknown"}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text('Model Loaded: ${state.health?.modelLoaded ?? false}'),
                  if (state.health?.classes != null)
                    Text('Classes: ${state.health!.classes!.keys.join(", ")}'),
                  const SizedBox(height: 20),

                  // Video Picker
                  FilePickerWidget(
                    onFilePicked: (File file) {
                      context.read<RefereeBloc>().add(AnalyzeVideoEvent(video: file));
                    },
                    buttonText: 'Upload Video for Analysis',
                    allowedExtensions: ['mp4'],
                  ),

                  // Analysis Results
                  if (state.analyzeResponse != null) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Analysis Results',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    // Summary
                    Text('Total Distance: ${state.analyzeResponse!.summary.totalDistanceKm.toStringAsFixed(2)} km'),
                    Text('Average Speed: ${state.analyzeResponse!.summary.avgSpeedKmH.toStringAsFixed(2)} km/h'),
                    Text('Max Speed: ${state.analyzeResponse!.summary.maxSpeedKmH.toStringAsFixed(2)} km/h'),
                    Text('Sprints: ${state.analyzeResponse!.summary.sprints}'),
                    Text('First Half Distance: ${state.analyzeResponse!.summary.distanceFirstHalfKm.toStringAsFixed(2)} km'),
                    Text('Second Half Distance: ${state.analyzeResponse!.summary.distanceSecondHalfKm.toStringAsFixed(2)} km'),
                    const SizedBox(height: 20),

                    // Report Text
                    ExpansionTile(
                      title: const Text('Report'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(state.analyzeResponse!.reportText),
                        ),
                      ],
                    ),

                    // Visualizations
                    const SizedBox(height: 10),
                    const Text('Heatmap', style: TextStyle(fontWeight: FontWeight.bold)),
                    Image.network(
                      'http://192.168.1.18:8000${state.analyzeResponse!.artifacts.heatmapUrl}',
                      height: 200,
                      errorBuilder: (context, error, stackTrace) => const Text('Failed to load heatmap'),
                    ),
                    const SizedBox(height: 10),
                    const Text('Speed Plot', style: TextStyle(fontWeight: FontWeight.bold)),
                    Image.network(
                      'http://192.168.1.18:8000${state.analyzeResponse!.artifacts.speedPlotUrl}',
                      height: 200,
                      errorBuilder: (context, error, stackTrace) => const Text('Failed to load speed plot'),
                    ),
                    const SizedBox(height: 10),
                    const Text('Proximity Plot', style: TextStyle(fontWeight: FontWeight.bold)),
                    Image.network(
                      'http://192.168.1.18:8000${state.analyzeResponse!.artifacts.proximityPlotUrl}',
                      height: 200,
                      errorBuilder: (context, error, stackTrace) => const Text('Failed to load proximity plot'),
                    ),

                    // Output Video
                    const SizedBox(height: 10),
                    const Text('Output Video', style: TextStyle(fontWeight: FontWeight.bold)),
                    VideoPlayerWidget(
                      videoUrl: 'http://192.168.1.18:8000${state.analyzeResponse!.artifacts.outputVideoUrl}',
                    ),

                    // Sample Frames
                    if (state.analyzeResponse!.artifacts.sampleFramesUrls.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Text('Sample Frames', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: state.analyzeResponse!.artifacts.sampleFramesUrls.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Image.network(
                                'http://192.168.1.18:8000${state.analyzeResponse!.artifacts.sampleFramesUrls[index]}',
                                width: 150,
                                errorBuilder: (context, error, stackTrace) => const Text('Failed to load frame'),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],

                  // Clean Button
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      context.read<RefereeBloc>().add(CleanFilesEvent());
                    },
                    child: const Text('Clean Server Files'),
                  ),
                  if (state.cleanResponse != null)
                    Text('Files Removed: ${state.cleanResponse!.removed}'),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
      }).catchError((e) {
        print('Error initializing video player: $e');
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              if (_controller.value.isPlaying) {
                _controller.pause();
              } else {
                _controller.play();
              }
            });
          },
          child: Text(_controller.value.isPlaying ? 'Pause' : 'Play'),
        ),
      ],
    );
  }
}