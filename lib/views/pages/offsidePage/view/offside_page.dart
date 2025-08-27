import 'dart:io';
import 'package:VarXPro/views/pages/offsidePage/controller/offside_controller.dart';
import 'package:VarXPro/views/pages/offsidePage/service/offside_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:VarXPro/views/pages/offsidePage/widgets/image_picker_widget.dart';
import 'package:VarXPro/views/pages/offsidePage/model/offside_model.dart';

class OffsidePage extends StatelessWidget {
  const OffsidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OffsideBloc(context.read<OffsideService>())..add(PingEvent()),
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
          child: BlocBuilder<OffsideBloc, OffsideState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Color(0xFF11FFB2)),
                  ),
                );
              }
              if (state.error != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
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
                });
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.all(constraints.maxWidth * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                        color: state.pingResponse != null && state.pingResponse!.ok
                                            ? const Color(0xFF11FFB2)
                                            : Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      state.pingResponse != null && state.pingResponse!.ok
                                          ? "Connected"
                                          : "Disconnected",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: state.pingResponse != null && state.pingResponse!.ok
                                            ? const Color(0xFF11FFB2)
                                            : Colors.redAccent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (state.pingResponse != null) ...[
                                  _buildStatusItem('Model', state.pingResponse!.model ?? "Unknown"),
                                  _buildStatusItem('OpenCV', state.pingResponse!.opencv ?? "Unknown"),
                                ],
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: constraints.maxWidth * 0.05),
                        _buildSectionHeader('Single Frame Offside Detection'),
                        SizedBox(height: constraints.maxWidth * 0.03),
                        OffsideForm(constraints: constraints),
                        if (state.offsideFrameResponse != null) ...[
                          SizedBox(height: constraints.maxWidth * 0.05),
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
                                  _buildResultItem(
                                    'Offside Detection',
                                    state.offsideFrameResponse!.offside ? 'YES' : 'NO',
                                    state.offsideFrameResponse!.offside,
                                  ),
                                  if (state.offsideFrameResponse!.stats.isNotEmpty)
                                    _buildResultItem(
                                      'Stats',
                                      state.offsideFrameResponse!.stats.entries
                                          .map((e) => '${e.key}: ${e.value}')
                                          .join(', '),
                                      false,
                                    ),
                                  if (state.offsideFrameResponse!.attackDirection != null)
                                    _buildResultItem(
                                      'Attack Direction',
                                      state.offsideFrameResponse!.attackDirection!,
                                      false,
                                    ),
                                  if (state.offsideFrameResponse!.linePoints != null)
                                    _buildResultItem(
                                      'Line Points',
                                      'Start: ${state.offsideFrameResponse!.linePoints!['start']}, End: ${state.offsideFrameResponse!.linePoints!['end']}',
                                      false,
                                    ),
                                  if (state.pickedImage != null) ...[
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Picked Image:',
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
                                        child: Image.file(
                                          state.pickedImage!,
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
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (state.offsideFrameResponse!.annotatedImageUrl != null) ...[
                                    const SizedBox(height: 12),
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
                                        child: Image.network(
                                          state.offsideFrameResponse!.annotatedImageUrl!,
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
                                                valueColor: const AlwaysStoppedAnimation(Color(0xFF11FFB2)),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                        SizedBox(height: constraints.maxWidth * 0.05),
                        _buildSectionHeader('Batch Offside Detection'),
                        SizedBox(height: constraints.maxWidth * 0.03),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final result = await FilePicker.platform.pickFiles(
                                    allowMultiple: true,
                                    type: FileType.image,
                                  );
                                  if (result != null) {
                                    final files = result.files.map((file) => File(file.path!)).toList();
                                    context.read<OffsideBloc>().add(DetectOffsideBatchEvent(images: files));
                                  }
                                },
                                icon: const Icon(Icons.photo_library, size: 20),
                                label: const Text('Pick Images'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1263A0),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: constraints.maxWidth * 0.02),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final result = await FilePicker.platform.pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: ['zip'],
                                  );
                                  if (result != null && result.files.single.path != null) {
                                    context.read<OffsideBloc>().add(
                                          DetectOffsideBatchEvent(zipFile: File(result.files.single.path!)),
                                        );
                                  }
                                },
                                icon: const Icon(Icons.archive, size: 20),
                                label: const Text('Pick ZIP'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1263A0),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (state.offsideBatchResponse != null) ...[
                          SizedBox(height: constraints.maxWidth * 0.05),
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
                                  _buildResultItem(
                                    'Processed Frames',
                                    state.offsideBatchResponse!.count.toString(),
                                    false,
                                  ),
                                  if (state.offsideBatchResponse!.resultsJsonUrl != null)
                                    _buildResultItem('Results JSON', 'Available', false),
                                  if (state.offsideBatchResponse!.zipUrl != null)
                                    _buildResultItem('Annotated ZIP', 'Available', false),
                                ],
                              ),
                            ),
                          ),
                        ],
                        SizedBox(height: constraints.maxWidth * 0.05),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: _buildSectionHeader('Previous Analysis Runs'),
                            ),
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      context.read<OffsideBloc>().add(ListRunsEvent());
                                    },
                                    icon: const Icon(Icons.refresh, size: 18),
                                    label: const Text('Refresh'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF11FFB2).withOpacity(0.2),
                                      foregroundColor: const Color(0xFF11FFB2),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      minimumSize: Size(constraints.maxWidth * 0.2, 36),
                                    ),
                                  ),
                                  SizedBox(width: constraints.maxWidth * 0.02),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      context.read<OffsideBloc>().add(ClearRunsEvent());
                                    },
                                    icon: const Icon(Icons.delete, size: 18),
                                    label: const Text('Clean'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent.withOpacity(0.2),
                                      foregroundColor: Colors.redAccent,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      minimumSize: Size(constraints.maxWidth * 0.2, 36),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: constraints.maxWidth * 0.03),
                        if (state.runsResponse != null && state.runsResponse!.runs.isNotEmpty)
                          _buildRunsList(state.runsResponse!.runs, constraints)
                        else if (state.runsResponse != null)
                          _buildEmptyState('No previous runs found')
                        else
                          _buildEmptyState('Press refresh to load previous runs'),
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
                color: isOffside ? const Color(0xFFFF6B6B) : const Color(0xFF11FFB2),
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunsList(List<Run> runs, BoxConstraints constraints) {
    final validRuns = runs.where((run) {
      final jsonContent = run.resultsJsonContent as Map<String, dynamic>?;
      return jsonContent != null &&
          jsonContent.containsKey('results') &&
          jsonContent['results'] is Map &&
          (jsonContent['results'] as Map).isNotEmpty;
    }).toList();

    if (validRuns.isEmpty) {
      return _buildEmptyState('No valid runs found');
    }

    return Column(
      children: validRuns.map((run) {
        final date = _parseRunDate(run.run);
        final jsonContent = run?.resultsJsonContent as Map<String, dynamic>;
        final baseUrl = run.resultsJson != null
            ? run.resultsJson!.substring(0, run.resultsJson!.lastIndexOf('/') + 1)
            : '';
        return Card(
          color: const Color(0xFF0D2B59).withOpacity(0.8),
          margin: EdgeInsets.symmetric(vertical: constraints.maxWidth * 0.02),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ExpansionTile(
            leading: const Icon(Icons.analytics, color: Color(0xFF11FFB2)),
            title: Text(
              date ?? run.run,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            subtitle: date != null
                ? Text(
                    run.run,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  )
                : null,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Parameters:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildResultItem(
                      'Attack Direction',
                      jsonContent['attack_direction']?.toString() ?? 'Unknown',
                      false,
                    ),
                    _buildResultItem(
                      'Line Mode',
                      jsonContent['line_mode']?.toString() ?? 'Unknown',
                      false,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Results:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...((jsonContent['results'] as Map).entries.map((entry) {
                      final frame = entry.key;
                      final data = entry.value as Map<String, dynamic>;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '- $frame:',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildResultItem(
                            'Offside',
                            data['offside'] == true ? 'YES' : 'NO',
                            data['offside'] == true,
                          ),
                          if (data['stats'] != null)
                            _buildResultItem(
                              'Stats',
                              (data['stats'] as Map).entries.map((e) => '${e.key}: ${e.value}').join(', '),
                              false,
                            ),
                          if (data['line_points'] != null)
                            _buildResultItem(
                              'Line Points',
                              'Start: ${data['line_points']['start']}, End: ${data['line_points']['end']}',
                              false,
                            ),
                          if (data['annotated_image'] != null) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Annotated Image:',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
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
                                  '$baseUrl${data['annotated_image']}',
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
                                        valueColor: const AlwaysStoppedAnimation(Color(0xFF11FFB2)),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    }).toList()),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2B59).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF11FFB2).withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.history,
            size: 48,
            color: Color(0xFF11FFB2),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String? _parseRunDate(String runId) {
    try {
      final matches = RegExp(r'(\d{8}_\d{6})').firstMatch(runId);
      if (matches != null) {
        final dateStr = matches.group(1);
        final date = DateFormat('yyyyMMdd_HHmmss').parse(dateStr!);
        return DateFormat('MMM dd, yyyy - HH:mm').format(date);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

class OffsideForm extends StatefulWidget {
  final BoxConstraints constraints;

  const OffsideForm({super.key, required this.constraints});

  @override
  _OffsideFormState createState() => _OffsideFormState();
}

class _OffsideFormState extends State<OffsideForm> {
  final _formKey = GlobalKey<FormState>();
  final _lineStartXController = TextEditingController(text: '640');
  final _lineStartYController = TextEditingController(text: '0');
  final _lineEndXController = TextEditingController(text: '690');
  final _lineEndYController = TextEditingController(text: '720');
  String _attackDirection = 'right';
  bool _useFixedLine = false;

  @override
  void dispose() {
    _lineStartXController.dispose();
    _lineStartYController.dispose();
    _lineEndXController.dispose();
    _lineEndYController.dispose();
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
              ImagePickerWidget(
                onImagePicked: (File image) {
                  if (_formKey.currentState!.validate()) {
                    context.read<OffsideBloc>().add(
                          DetectOffsideSingleEvent(
                            image: image,
                            attackDirection: _attackDirection,
                            lineStart: _useFixedLine
                                ? [
                                    int.parse(_lineStartXController.text),
                                    int.parse(_lineStartYController.text)
                                  ]
                                : null,
                            lineEnd: _useFixedLine
                                ? [
                                    int.parse(_lineEndXController.text),
                                    int.parse(_lineEndYController.text)
                                  ]
                                : null,
                          ),
                        );
                    context.read<OffsideBloc>().add(UpdatePickedImageEvent(image));
                  }
                },
                buttonText: 'Pick and Analyze Image',
              ),
              SizedBox(height: widget.constraints.maxWidth * 0.04),
              DropdownButtonFormField<String>(
                value: _attackDirection,
                decoration: InputDecoration(
                  labelText: 'Attack Direction',
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
                dropdownColor: const Color(0xFF0D2B59),
                items: ['right', 'left', 'up', 'down']
                    .map((dir) => DropdownMenuItem(
                          value: dir,
                          child: Text(
                            dir.toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _attackDirection = value!;
                  });
                },
              ),
              SizedBox(height: widget.constraints.maxWidth * 0.04),
              SwitchListTile(
                title: const Text(
                  'Use Fixed Line',
                  style: TextStyle(color: Colors.white),
                ),
                value: _useFixedLine,
                activeColor: const Color(0xFF11FFB2),
                onChanged: (value) {
                  setState(() {
                    _useFixedLine = value;
                  });
                },
              ),
              if (_useFixedLine) ...[
                SizedBox(height: widget.constraints.maxWidth * 0.04),
                const Text(
                  'Line Coordinates',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: widget.constraints.maxWidth * 0.03),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _lineStartXController,
                        decoration: const InputDecoration(
                          labelText: 'Start X',
                          labelStyle: TextStyle(color: Color(0xFF11FFB2)),
                        ),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'Enter X coordinate' : null,
                      ),
                    ),
                    SizedBox(width: widget.constraints.maxWidth * 0.02),
                    Expanded(
                      child: TextFormField(
                        controller: _lineStartYController,
                        decoration: const InputDecoration(
                          labelText: 'Start Y',
                          labelStyle: TextStyle(color: Color(0xFF11FFB2)),
                        ),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'Enter Y coordinate' : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: widget.constraints.maxWidth * 0.03),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _lineEndXController,
                        decoration: const InputDecoration(
                          labelText: 'End X',
                          labelStyle: TextStyle(color: Color(0xFF11FFB2)),
                        ),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'Enter X coordinate' : null,
                      ),
                    ),
                    SizedBox(width: widget.constraints.maxWidth * 0.02),
                    Expanded(
                      child: TextFormField(
                        controller: _lineEndYController,
                        decoration: const InputDecoration(
                          labelText: 'End Y',
                          labelStyle: TextStyle(color: Color(0xFF11FFB2)),
                        ),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'Enter Y coordinate' : null,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}