import 'dart:convert';
import 'dart:io';
import 'package:VarXPro/views/pages/TrackingAndGoalAnalysis/model/analysis_result.dart';
import 'package:VarXPro/views/pages/TrackingAndGoalAnalysis/widgets/file_picker_widget.dart';
import 'package:VarXPro/views/pages/TrackingAndGoalAnalysis/controller/tracking_controller.dart';
import 'package:VarXPro/views/pages/TrackingAndGoalAnalysis/service/tracking_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;

class EnhancedSoccerPlayerTrackingAndGoalAnalysisPage extends StatefulWidget {
  const EnhancedSoccerPlayerTrackingAndGoalAnalysisPage({super.key});

  @override
  _EnhancedSoccerPlayerTrackingAndGoalAnalysisPageState createState() =>
      _EnhancedSoccerPlayerTrackingAndGoalAnalysisPageState();
}

class _EnhancedSoccerPlayerTrackingAndGoalAnalysisPageState
    extends State<EnhancedSoccerPlayerTrackingAndGoalAnalysisPage> {
  final _formKey = GlobalKey<FormState>();
  final _detectionConfidenceController = TextEditingController(text: '0.4');
  final _trailLengthController = TextEditingController(text: '30');
  final _goalLeftXController = TextEditingController(text: '100');
  final _goalLeftYController = TextEditingController(text: '100');
  final _goalRightXController = TextEditingController(text: '500');
  final _goalRightYController = TextEditingController(text: '100');
  bool _showTrails = true;
  bool _showSkeleton = true;
  bool _showBoxes = true;
  bool _showIds = true;
  int _visibleRows = 10; // Initially show 10 rows
  bool _showAllRows = false;

  @override
  void dispose() {
    _detectionConfidenceController.dispose();
    _trailLengthController.dispose();
    _goalLeftXController.dispose();
    _goalLeftYController.dispose();
    _goalRightXController.dispose();
    _goalRightYController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          TrackingBloc(context.read<TrackingService>())..add(CheckHealthEvent()),
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
          child: BlocConsumer<TrackingBloc, TrackingState>(
            listener: (context, state) {
              if (state.cleanResponse != null && state.cleanResponse!.ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Artifacts cleaned successfully"),
                    backgroundColor: const Color(0xFF11FFB2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
                context.read<TrackingBloc>().emit(TrackingState(
                      health: state.health,
                    ));
              }
              if (state.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${state.error}'),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
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
                        // API Status Card
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
                                        color: state.health != null &&
                                                state.health!.status == "OK"
                                            ? const Color(0xFF11FFB2)
                                            : Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      state.health != null &&
                                              state.health!.status == "OK"
                                          ? "Connected"
                                          : "Disconnected",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: state.health != null &&
                                                state.health!.status == "OK"
                                            ? const Color(0xFF11FFB2)
                                            : Colors.redAccent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _buildStatusItem(
                                    'Model Loaded',
                                    state.health?.modelLoaded ?? false
                                        ? "Yes"
                                        : "No"),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: constraints.maxWidth * 0.05),
                        // Config Form
                        _buildSectionHeader('Analysis Configuration'),
                        SizedBox(height: constraints.maxWidth * 0.03),
                        _buildConfigForm(constraints, context),
                        // Results
                        if (state.analyzeResponse != null) ...[
                          SizedBox(height: constraints.maxWidth * 0.05),
                          _buildResults(state.analyzeResponse!, constraints),
                          SizedBox(height: constraints.maxWidth * 0.05),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () => context
                                  .read<TrackingBloc>()
                                  .add(CleanArtifactsEvent()),
                              icon: const Icon(Icons.delete, size: 18),
                              label: const Text('Clean Artifacts'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.redAccent.withOpacity(0.2),
                                foregroundColor: Colors.redAccent,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                minimumSize:
                                    Size(constraints.maxWidth * 0.3, 36),
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildConfigForm(BoxConstraints constraints, BuildContext context) {
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
              FilePickerWidget(
                onFilePicked: (File file) {
                  if (_formKey.currentState?.validate() ?? false) {
                    context.read<TrackingBloc>().add(AnalyzeVideoEvent(
                          video: file,
                          detectionConfidence:
                              double.parse(_detectionConfidenceController.text),
                          showTrails: _showTrails,
                          showSkeleton: _showSkeleton,
                          showBoxes: _showBoxes,
                          showIds: _showIds,
                          trailLength: int.parse(_trailLengthController.text),
                          goalLeft: [
                            int.parse(_goalLeftXController.text),
                            int.parse(_goalLeftYController.text),
                          ],
                          goalRight: [
                            int.parse(_goalRightXController.text),
                            int.parse(_goalRightYController.text),
                          ],
                        ));
                  }
                },
                buttonText: 'Pick and Analyze Video',
                fileType: FileType.video,
              ),
              SizedBox(height: constraints.maxWidth * 0.04),
              TextFormField(
                controller: _detectionConfidenceController,
                decoration: InputDecoration(
                  labelText: 'Detection Confidence (0-1)',
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
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  final num = double.tryParse(value);
                  if (num == null || num < 0 || num > 1) {
                    return 'Must be between 0 and 1';
                  }
                  return null;
                },
              ),
              SizedBox(height: constraints.maxWidth * 0.04),
              SwitchListTile(
                title: const Text(
                  'Show Trails',
                  style: TextStyle(color: Colors.white),
                ),
                value: _showTrails,
                activeColor: const Color(0xFF11FFB2),
                onChanged: (val) => setState(() => _showTrails = val),
              ),
              SwitchListTile(
                title: const Text(
                  'Show Skeleton',
                  style: TextStyle(color: Colors.white),
                ),
                value: _showSkeleton,
                activeColor: const Color(0xFF11FFB2),
                onChanged: (val) => setState(() => _showSkeleton = val),
              ),
              SwitchListTile(
                title: const Text(
                  'Show Bounding Boxes',
                  style: TextStyle(color: Colors.white),
                ),
                value: _showBoxes,
                activeColor: const Color(0xFF11FFB2),
                onChanged: (val) => setState(() => _showBoxes = val),
              ),
              SwitchListTile(
                title: const Text(
                  'Show Player IDs',
                  style: TextStyle(color: Colors.white),
                ),
                value: _showIds,
                activeColor: const Color(0xFF11FFB2),
                onChanged: (val) => setState(() => _showIds = val),
              ),
              SizedBox(height: constraints.maxWidth * 0.04),
              TextFormField(
                controller: _trailLengthController,
                decoration: InputDecoration(
                  labelText: 'Trail Length',
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
                validator: (value) =>
                    value!.isEmpty ? 'Enter trail length' : null,
              ),
              SizedBox(height: constraints.maxWidth * 0.04),
              const Text(
                'Goal Posts Coordinates',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: constraints.maxWidth * 0.03),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _goalLeftXController,
                      decoration: InputDecoration(
                        labelText: 'Left X',
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
                      validator: (value) =>
                          value!.isEmpty ? 'Enter X coordinate' : null,
                    ),
                  ),
                  SizedBox(width: constraints.maxWidth * 0.02),
                  Expanded(
                    child: TextFormField(
                      controller: _goalLeftYController,
                      decoration: InputDecoration(
                        labelText: 'Left Y',
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
                      validator: (value) =>
                          value!.isEmpty ? 'Enter Y coordinate' : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: constraints.maxWidth * 0.03),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _goalRightXController,
                      decoration: InputDecoration(
                        labelText: 'Right X',
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
                      validator: (value) =>
                          value!.isEmpty ? 'Enter X coordinate' : null,
                    ),
                  ),
                  SizedBox(width: constraints.maxWidth * 0.02),
                  Expanded(
                    child: TextFormField(
                      controller: _goalRightYController,
                      decoration: InputDecoration(
                        labelText: 'Right Y',
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
                      validator: (value) =>
                          value!.isEmpty ? 'Enter Y coordinate' : null,
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

  Widget _buildResults(AnalyzeResponse response, BoxConstraints constraints) {
    final baseUrl = "http://192.168.1.18:8002";

    return Card(
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
            _buildResultItem(
                'Frames Processed', response.frames.toString(), false),
            _buildResultItem(
                'Player Count', response.summary['player_count']?.toString() ?? '0', false),
            // Analysis Image
            if (response.artifacts['analysis_url'] != null) ...[
              const SizedBox(height: 12),
              const Text(
                'Analysis Plot:',
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
                  child: Image.network(
                    "$baseUrl${response.artifacts['analysis_url']}",
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[800],
                      child: const Center(
                        child: Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 40,
                        ),
                      ),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          valueColor:
                              const AlwaysStoppedAnimation(Color(0xFF11FFB2)),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
            // Metrics Chart
            if (response.artifacts['metrics_url'] != null) ...[
              const SizedBox(height: 12),
              const Text(
                'Metrics Chart:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<http.Response>(
                future: http.get(Uri.parse("$baseUrl${response.artifacts['metrics_url']}")),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Color(0xFF11FFB2)),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Text(
                      "Error loading metrics: ${snapshot.error}",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14,
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data?.body == null) {
                    return const Text(
                      "No metrics data available",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    );
                  }
                  try {
                    final jsonMap = jsonDecode(snapshot.data!.body) as Map<String, dynamic>;
                    final List<String> keys = [];
                    final List<double> values = [];
                    jsonMap.forEach((key, value) {
                      if (value is num) {
                        keys.add(key);
                        values.add(value.toDouble());
                      }
                    });
                    if (values.isEmpty) {
                      return const Text(
                        "No numerical metrics to chart",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      );
                    }
                    
                    // Find max value for scaling
                    final maxValue = values.reduce((a, b) => a > b ? a : b);
                    
                    return Container(
                      height: 300,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF071628).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: BarChart(
                        BarChartData(
                          barGroups: List.generate(
                            values.length,
                            (i) => BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: values[i],
                                  color: const Color(0xFF11FFB2),
                                  width: 16,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 || index >= keys.length) {
                                    return const Text('');
                                  }
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    child: RotatedBox(
                                      quarterTurns: -1,
                                      child: Text(
                                        keys[index],
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                                interval: maxValue > 5 ? (maxValue / 5) : 1,
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(
                              color: const Color(0xFF11FFB2).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          gridData: const FlGridData(show: true),
                        ),
                      ),
                    );
                  } catch (e) {
                    return Text(
                      "Failed to parse or chart metrics: $e",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14,
                      ),
                    );
                  }
                },
              ),
            ],
            // Results Table
            if (response.artifacts['results_url'] != null) ...[
              const SizedBox(height: 12),
              const Text(
                'Results Table:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<http.Response>(
                future: http.get(Uri.parse("$baseUrl${response.artifacts['results_url']}")),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Color(0xFF11FFB2)),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Text(
                      "Error loading results: ${snapshot.error}",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14,
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data?.body == null) {
                    return const Text(
                      "No results data available",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    );
                  }
                  final csvContent = snapshot.data!.body;
                  final List<String> lines = csvContent
                      .split('\n')
                      .where((line) => line.isNotEmpty)
                      .toList();
                  if (lines.isEmpty) {
                    return const Text(
                      "Empty CSV",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    );
                  }
                  final List<List<String>> data = lines.map((line) {
                    return line.split(',').map((e) => e.trim()).toList();
                  }).toList();
                  final List<String> headers = data[0];
                  final int colCount = headers.length;
                  final List<DataRow> rows = data.sublist(1).map((row) {
                    List<String> adjusted = List.from(row);
                    while (adjusted.length < colCount) {
                      adjusted.add('');
                    }
                    if (adjusted.length > colCount) {
                      adjusted = adjusted.sublist(0, colCount);
                    }
                    return DataRow(
                      cells: adjusted
                          .map((cell) => DataCell(
                                Text(
                                  cell,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                    );
                  }).toList();

                  // Calculate which rows to show
                  final rowsToShow = _showAllRows 
                      ? rows 
                      : rows.take(_visibleRows).toList();

                  return Column(
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth * 0.9,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF11FFB2).withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: constraints.maxWidth > 600 ? 20 : 10,
                            dataRowMinHeight: 40,
                            dataRowMaxHeight: 48,
                            headingRowHeight: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            columns: headers
                                .map(
                                  (header) => DataColumn(
                                    label: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      child: Text(
                                        header,
                                        style: TextStyle(
                                          fontSize:
                                              constraints.maxWidth > 600 ? 14 : 12,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF11FFB2),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            rows: rowsToShow
                                .asMap()
                                .entries
                                .map((entry) {
                              final index = entry.key;
                              final row = entry.value;
                              return DataRow(
                                color: WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.hovered)) {
                                    return const Color(0xFF11FFB2).withOpacity(0.1);
                                  }
                                  return index % 2 == 0
                                      ? const Color(0xFF0D2B59).withOpacity(0.4)
                                      : const Color(0xFF071628).withOpacity(0.4);
                                }),
                                cells: row.cells,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      if (rows.length > _visibleRows) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!_showAllRows) ...[
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _visibleRows += 10;
                                    if (_visibleRows >= rows.length) {
                                      _showAllRows = true;
                                    }
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF11FFB2).withOpacity(0.2),
                                  foregroundColor: const Color(0xFF11FFB2),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Show More (10)',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _showAllRows = !_showAllRows;
                                  if (!_showAllRows) {
                                    _visibleRows = 10;
                                  }
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF11FFB2).withOpacity(0.2),
                                foregroundColor: const Color(0xFF11FFB2),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                _showAllRows ? 'Show Less' : 'Show All',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(String label, String value, bool isOffside) {
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
                color: isOffside
                    ? const Color(0xFFFF6B6B)
                    : const Color(0xFF11FFB2),
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

class VideoPlayerWidget extends StatefulWidget {
  final String url;
  const VideoPlayerWidget({super.key, required this.url});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() => _isInitialized = true);
        _controller.play();
      }).catchError((error) {
        setState(() {
          _isInitialized = false;
          _error = error.toString();
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Column(
        children: [
          const Icon(
            Icons.error,
            color: Colors.redAccent,
            size: 40,
          ),
          Text(
            'Video Error: $_error',
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 14,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _error = null;
                _isInitialized = false;
                _controller =
                    VideoPlayerController.networkUrl(Uri.parse(widget.url))
                      ..initialize().then((_) {
                        setState(() => _isInitialized = true);
                        _controller.play();
                      }).catchError((error) {
                        setState(() {
                          _isInitialized = false;
                          _error = error.toString();
                        });
                      });
              });
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF11FFB2).withOpacity(0.2),
              foregroundColor: const Color(0xFF11FFB2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      );
    }
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Color(0xFF11FFB2)),
        ),
      );
    }
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          VideoPlayer(_controller),
          VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: Color(0xFF11FFB2),
              bufferedColor: Color(0xFF0D2B59),
              backgroundColor: Colors.white24,
            ),
          ),
        ],
      ),
    );
  }
}