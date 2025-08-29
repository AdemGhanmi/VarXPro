import 'dart:io';

import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/views/pages/RefereeTraking/controller/referee_controller.dart';
import 'package:VarXPro/views/pages/RefereeTraking/service/referee_api_service.dart';
import 'package:VarXPro/views/pages/RefereeTraking/widgets/file_picker_widget.dart';
import 'package:VarXPro/views/pages/RefereeTraking/widgets/video_player_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class RefereeTrackingSystemPage extends StatefulWidget {
  const RefereeTrackingSystemPage({super.key});

  @override
  _RefereeTrackingSystemPageState createState() =>
      _RefereeTrackingSystemPageState();
}

class _RefereeTrackingSystemPageState extends State<RefereeTrackingSystemPage> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final modeProvider = Provider.of<ModeProvider>(context);
    final seedColor = AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!;

    if (_showSplash) {
      return Scaffold(
        backgroundColor: AppColors.getBackgroundColor(modeProvider.currentMode),
        body: Center(
          child: Lottie.asset(
            'assets/lotties/refere.json',
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.5,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    return BlocProvider(
      create: (context) => RefereeBloc(context.read<RefereeService>())
        ..add(CheckHealthEvent()),
      child: Scaffold(
        backgroundColor: AppColors.getBackgroundColor(modeProvider.currentMode),
      
        body: BlocConsumer<RefereeBloc, RefereeState>(
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.error!,
                    style: TextStyle(
                      color: AppColors.getTextColor(modeProvider.currentMode),
                    ),
                  ),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  action: SnackBarAction(
                    label: 'Retry',
                    textColor: Colors.white,
                    onPressed: () {
                      context.read<RefereeBloc>().add(CheckHealthEvent());
                    },
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state.isLoading) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(
                    AppColors.getTertiaryColor(seedColor, modeProvider.currentMode),
                  ),
                ),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Health Status
                  Text(
                    'API Status: ${state.health?.status ?? "Unknown"}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextColor(modeProvider.currentMode),
                    ),
                  ),
                  Text(
                    'Model Loaded: ${state.health?.modelLoaded ?? false}',
                    style: TextStyle(
                      color: AppColors.getTextColor(modeProvider.currentMode),
                    ),
                  ),
                  if (state.health?.classes != null)
                    Text(
                      'Classes: ${state.health!.classes!.keys.join(", ")}',
                      style: TextStyle(
                        color: AppColors.getTextColor(modeProvider.currentMode),
                      ),
                    ),
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
                  if (state.analyzeResponse != null && state.analyzeResponse!.ok) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Analysis Results',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextColor(modeProvider.currentMode),
                      ),
                    ),
                    // Summary
                    Card(
                      color: AppColors.getSurfaceColor(modeProvider.currentMode),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Distance: ${state.analyzeResponse!.summary.totalDistanceKm.toStringAsFixed(2)} km',
                              style: TextStyle(
                                color: AppColors.getTextColor(modeProvider.currentMode),
                              ),
                            ),
                            Text(
                              'Average Speed: ${state.analyzeResponse!.summary.avgSpeedKmH.toStringAsFixed(2)} km/h',
                              style: TextStyle(
                                color: AppColors.getTextColor(modeProvider.currentMode),
                              ),
                            ),
                            Text(
                              'Max Speed: ${state.analyzeResponse!.summary.maxSpeedKmH.toStringAsFixed(2)} km/h',
                              style: TextStyle(
                                color: AppColors.getTextColor(modeProvider.currentMode),
                              ),
                            ),
                            Text(
                              'Sprints: ${state.analyzeResponse!.summary.sprints}',
                              style: TextStyle(
                                color: AppColors.getTextColor(modeProvider.currentMode),
                              ),
                            ),
                            Text(
                              'First Half Distance: ${state.analyzeResponse!.summary.distanceFirstHalfKm.toStringAsFixed(2)} km',
                              style: TextStyle(
                                color: AppColors.getTextColor(modeProvider.currentMode),
                              ),
                            ),
                            Text(
                              'Second Half Distance: ${state.analyzeResponse!.summary.distanceSecondHalfKm.toStringAsFixed(2)} km',
                              style: TextStyle(
                                color: AppColors.getTextColor(modeProvider.currentMode),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Report Text
                    ExpansionTile(
                      title: Text(
                        'Full Report',
                        style: TextStyle(
                          color: AppColors.getTextColor(modeProvider.currentMode),
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SelectableText(
                            state.analyzeResponse!.reportText,
                            style: TextStyle(
                              color: AppColors.getTextColor(modeProvider.currentMode),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Visualizations
                    const SizedBox(height: 10),
                    Text(
                      'Heatmap',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextColor(modeProvider.currentMode),
                      ),
                    ),
                    Image.network(
                      'http://192.168.1.18:8000${state.analyzeResponse!.artifacts.heatmapUrl}',
                      height: 200,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Text(
                        'Failed to load heatmap',
                        style: TextStyle(
                          color: AppColors.getTextColor(modeProvider.currentMode),
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    (loadingProgress.expectedTotalBytes ?? 1)
                                : null,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Speed Plot',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextColor(modeProvider.currentMode),
                      ),
                    ),
                    Image.network(
                      'http://192.168.1.18:8000${state.analyzeResponse!.artifacts.speedPlotUrl}',
                      height: 200,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Text(
                        'Failed to load speed plot',
                        style: TextStyle(
                          color: AppColors.getTextColor(modeProvider.currentMode),
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    (loadingProgress.expectedTotalBytes ?? 1)
                                : null,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Proximity Plot',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextColor(modeProvider.currentMode),
                      ),
                    ),
                    Image.network(
                      'http://192.168.1.18:8000${state.analyzeResponse!.artifacts.proximityPlotUrl}',
                      height: 200,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Text(
                        'Failed to load proximity plot',
                        style: TextStyle(
                          color: AppColors.getTextColor(modeProvider.currentMode),
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    (loadingProgress.expectedTotalBytes ?? 1)
                                : null,
                          ),
                        );
                      },
                    ),

                    // Output Video
                    const SizedBox(height: 10),
                    Text(
                      'Output Video',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextColor(modeProvider.currentMode),
                      ),
                    ),
                    VideoPlayerWidget(
                      videoUrl:
                          'http://192.168.1.18:8000${state.analyzeResponse!.artifacts.outputVideoUrl}',
                    ),

                    // Sample Frames
                    if (state.analyzeResponse!.artifacts.sampleFramesUrls.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Sample Frames',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextColor(modeProvider.currentMode),
                        ),
                      ),
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
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Text(
                                  'Failed to load frame',
                                  style: TextStyle(
                                    color: AppColors.getTextColor(modeProvider.currentMode),
                                  ),
                                ),
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              (loadingProgress.expectedTotalBytes ?? 1)
                                          : null,
                                    ),
                                  );
                                },
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          AppColors.getSecondaryColor(seedColor, modeProvider.currentMode),
                      foregroundColor: AppColors.getTextColor(modeProvider.currentMode),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Clean Server Files'),
                  ),
                  if (state.cleanResponse != null)
                    Text(
                      'Files Removed: ${state.cleanResponse!.removed}',
                      style: TextStyle(
                        color: AppColors.getTextColor(modeProvider.currentMode),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}