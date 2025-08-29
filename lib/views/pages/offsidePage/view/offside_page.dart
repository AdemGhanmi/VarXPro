import 'dart:io';
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/views/pages/offsidePage/controller/offside_controller.dart';
import 'package:VarXPro/views/pages/offsidePage/service/offside_service.dart';
import 'package:VarXPro/views/pages/offsidePage/model/offside_model.dart';
import 'package:VarXPro/views/pages/offsidePage/widgets/OffsideForm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart'; // Added Lottie package
import 'dart:async'; // Added for Timer

class OffsidePage extends StatefulWidget {
  const OffsidePage({super.key});

  @override
  _OffsidePageState createState() => _OffsidePageState();
}

class _OffsidePageState extends State<OffsidePage> {
  bool _showSplash = true; // State to control splash screen visibility

  @override
  void initState() {
    super.initState();
    // Start a timer to hide the splash screen after 3 seconds
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
    final langProvider = Provider.of<LanguageProvider>(context);
    final modeProvider = Provider.of<ModeProvider>(context);
    final currentLang = langProvider.currentLanguage;
    final seedColor = AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!;

    // Show Lottie animation if splash screen is active
    if (_showSplash) {
      return Scaffold(
        backgroundColor: AppColors.getBackgroundColor(modeProvider.currentMode),
        body: Center(
          child: Lottie.asset(
            'assets/lotties/offside.json',
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.5,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    // Main content after splash screen
    return BlocProvider(
      create: (context) => OffsideBloc(context.read<OffsideService>())..add(PingEvent()),
      child: Scaffold(
        backgroundColor: AppColors.getBackgroundColor(modeProvider.currentMode),
        body: Container(
          decoration: BoxDecoration(
            gradient: AppColors.getBodyGradient(modeProvider.currentMode),
          ),
          child: BlocBuilder<OffsideBloc, OffsideState>(
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
              if (state.error != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${Translations.getOffsideText('error', currentLang)}: ${state.error}',
                        style: TextStyle(
                          color: AppColors.getTextColor(modeProvider.currentMode),
                        ),
                      ),
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
                          color: AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.8),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Translations.getOffsideText('apiStatus', currentLang),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.getTextColor(modeProvider.currentMode),
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
                                            ? AppColors.getTertiaryColor(seedColor, modeProvider.currentMode)
                                            : Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      state.pingResponse != null && state.pingResponse!.ok
                                          ? Translations.getOffsideText('connected', currentLang)
                                          : Translations.getOffsideText('disconnected', currentLang),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: state.pingResponse != null && state.pingResponse!.ok
                                            ? AppColors.getTertiaryColor(seedColor, modeProvider.currentMode)
                                            : Colors.redAccent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (state.pingResponse != null) ...[
                                  _buildStatusItem(
                                    Translations.getOffsideText('model', currentLang),
                                    state.pingResponse!.model ?? "Unknown",
                                    modeProvider.currentMode,
                                    seedColor,
                                  ),
                                  _buildStatusItem(
                                    Translations.getOffsideText('opencv', currentLang),
                                    state.pingResponse!.opencv ?? "Unknown",
                                    modeProvider.currentMode,
                                    seedColor,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: constraints.maxWidth * 0.05),
                        _buildSectionHeader(
                          Translations.getOffsideText('singleFrameDetection', currentLang),
                          modeProvider.currentMode,
                          seedColor,
                        ),
                        SizedBox(height: constraints.maxWidth * 0.03),
                        OffsideForm(
                          constraints: constraints,
                          currentLang: currentLang,
                          mode: modeProvider.currentMode,
                          seedColor: seedColor,
                        ),
                        if (state.offsideFrameResponse != null) ...[
                          SizedBox(height: constraints.maxWidth * 0.05),
                          Card(
                            color: AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.8),
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
                                    Translations.getOffsideText('offside', currentLang),
                                    state.offsideFrameResponse!.offside
                                        ? Translations.getOffsideText('offside', currentLang).toUpperCase()
                                        : 'NO',
                                    state.offsideFrameResponse!.offside,
                                    modeProvider.currentMode,
                                    seedColor,
                                  ),
                                  if (state.offsideFrameResponse!.stats.isNotEmpty)
                                    _buildResultItem(
                                      Translations.getOffsideText('stats', currentLang),
                                      state.offsideFrameResponse!.stats.entries
                                          .map((e) => '${e.key}: ${e.value}')
                                          .join(', '),
                                      false,
                                      modeProvider.currentMode,
                                      seedColor,
                                    ),
                                  if (state.offsideFrameResponse!.attackDirection != null)
                                    _buildResultItem(
                                      Translations.getOffsideText('attackDirection', currentLang),
                                      state.offsideFrameResponse!.attackDirection!,
                                      false,
                                      modeProvider.currentMode,
                                      seedColor,
                                    ),
                                  if (state.offsideFrameResponse!.linePoints != null)
                                    _buildResultItem(
                                      Translations.getOffsideText('linePoints', currentLang),
                                      'Start: ${state.offsideFrameResponse!.linePoints!['start']}, End: ${state.offsideFrameResponse!.linePoints!['end']}',
                                      false,
                                      modeProvider.currentMode,
                                      seedColor,
                                    ),
                                  if (state.pickedImage != null) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      Translations.getOffsideText('pickedImage', currentLang),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.getTextColor(modeProvider.currentMode),
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
                                          color: AppColors.getTertiaryColor(seedColor, modeProvider.currentMode).withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          state.pickedImage!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: AppColors.getSurfaceColor(modeProvider.currentMode),
                                            child: Center(
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
                                    Text(
                                      Translations.getOffsideText('annotatedImage', currentLang),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.getTextColor(modeProvider.currentMode),
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
                                          color: AppColors.getTertiaryColor(seedColor, modeProvider.currentMode).withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          state.offsideFrameResponse!.annotatedImageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: AppColors.getSurfaceColor(modeProvider.currentMode),
                                            child: Center(
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
                                                valueColor: AlwaysStoppedAnimation(
                                                  AppColors.getTertiaryColor(seedColor, modeProvider.currentMode),
                                                ),
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
                        _buildSectionHeader(
                          Translations.getOffsideText('batchDetection', currentLang),
                          modeProvider.currentMode,
                          seedColor,
                        ),
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
                                icon: Icon(Icons.photo_library, size: 20, color: AppColors.getTextColor(modeProvider.currentMode)),
                                label: Text(
                                  Translations.getOffsideText('pickImages', currentLang),
                                  style: TextStyle(color: AppColors.getTextColor(modeProvider.currentMode)),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.getSecondaryColor(seedColor, modeProvider.currentMode),
                                  foregroundColor: AppColors.getTextColor(modeProvider.currentMode),
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
                                icon: Icon(Icons.archive, size: 20, color: AppColors.getTextColor(modeProvider.currentMode)),
                                label: Text(
                                  Translations.getOffsideText('pickZip', currentLang),
                                  style: TextStyle(color: AppColors.getTextColor(modeProvider.currentMode)),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.getSecondaryColor(seedColor, modeProvider.currentMode),
                                  foregroundColor: AppColors.getTextColor(modeProvider.currentMode),
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
                            color: AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.8),
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
                                    Translations.getOffsideText('processedFrames', currentLang),
                                    state.offsideBatchResponse!.count.toString(),
                                    false,
                                    modeProvider.currentMode,
                                    seedColor,
                                  ),
                                  if (state.offsideBatchResponse!.resultsJsonUrl != null)
                                    _buildResultItem(
                                      Translations.getOffsideText('resultsJson', currentLang),
                                      'Available',
                                      false,
                                      modeProvider.currentMode,
                                      seedColor,
                                    ),
                                  if (state.offsideBatchResponse!.zipUrl != null)
                                    _buildResultItem(
                                      Translations.getOffsideText('annotatedZip', currentLang),
                                      'Available',
                                      false,
                                      modeProvider.currentMode,
                                      seedColor,
                                    ),
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
                              child: _buildSectionHeader(
                                Translations.getOffsideText('previousRuns', currentLang),
                                modeProvider.currentMode,
                                seedColor,
                              ),
                            ),
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      context.read<OffsideBloc>().add(ListRunsEvent());
                                    },
                                    icon: Icon(Icons.refresh, size: 18, color: AppColors.getTextColor(modeProvider.currentMode)),
                                    label: Text(
                                      Translations.getOffsideText('refresh', currentLang),
                                      style: TextStyle(color: AppColors.getTextColor(modeProvider.currentMode)),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.getTertiaryColor(seedColor, modeProvider.currentMode).withOpacity(0.2),
                                      foregroundColor: AppColors.getTertiaryColor(seedColor, modeProvider.currentMode),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      minimumSize: Size(constraints.maxWidth * 0.2, 36),
                                    ),
                                  ),
                                  SizedBox(width: constraints.maxWidth * 0.02),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: constraints.maxWidth * 0.03),
                        if (state.runsResponse != null && state.runsResponse!.runs.isNotEmpty)
                          _buildRunsList(state.runsResponse!.runs, constraints, currentLang, modeProvider.currentMode, seedColor)
                        else if (state.runsResponse != null)
                          _buildEmptyState(Translations.getOffsideText('noRuns', currentLang), modeProvider.currentMode, seedColor)
                        else
                          _buildEmptyState(Translations.getOffsideText('pressRefresh', currentLang), modeProvider.currentMode, seedColor),
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

  Widget _buildStatusItem(String label, String value, int mode, Color seedColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: AppColors.getTextColor(mode).withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.getTextColor(mode),
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

  Widget _buildSectionHeader(String title, int mode, Color seedColor) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.getTextColor(mode),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildResultItem(String label, String value, bool isOffside, int mode, Color seedColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: AppColors.getTextColor(mode).withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: isOffside
                    ? Colors.redAccent
                    : AppColors.getTertiaryColor(seedColor, mode),
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunsList(List<Run> runs, BoxConstraints constraints, String currentLang, int mode, Color seedColor) {
    final validRuns = runs.where((run) {
      final jsonContent = run.resultsJsonContent as Map<String, dynamic>?;
      return jsonContent != null &&
          jsonContent.containsKey('results') &&
          jsonContent['results'] is Map &&
          (jsonContent['results'] as Map).isNotEmpty;
    }).toList();

    if (validRuns.isEmpty) {
      return _buildEmptyState(Translations.getOffsideText('noValidRuns', currentLang), mode, seedColor);
    }

    return Column(
      children: validRuns.map((run) {
        final date = _parseRunDate(run.run);
        final jsonContent = run.resultsJsonContent as Map<String, dynamic>;
        final baseUrl = run.resultsJson != null
            ? run.resultsJson!.substring(0, run.resultsJson!.lastIndexOf('/') + 1)
            : '';
        return Card(
          color: AppColors.getSurfaceColor(mode).withOpacity(0.8),
          margin: EdgeInsets.symmetric(vertical: constraints.maxWidth * 0.02),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ExpansionTile(
            leading: Icon(Icons.analytics, color: AppColors.getTertiaryColor(seedColor, mode)),
            title: Text(
              date ?? run.run,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.getTextColor(mode),
              ),
            ),
            subtitle: date != null
                ? Text(
                    run.run,
                    style: TextStyle(
                      color: AppColors.getTextColor(mode).withOpacity(0.6),
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
                    Text(
                      Translations.getOffsideText('parameters', currentLang),
                      style: TextStyle(
                        color: AppColors.getTextColor(mode),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildResultItem(
                      Translations.getOffsideText('attackDirection', currentLang),
                      jsonContent['attack_direction']?.toString() ?? 'Unknown',
                      false,
                      mode,
                      seedColor,
                    ),
                    _buildResultItem(
                      Translations.getOffsideText('lineMode', currentLang),
                      jsonContent['line_mode']?.toString() ?? 'Unknown',
                      false,
                      mode,
                      seedColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Translations.getOffsideText('resultsJson', currentLang),
                      style: TextStyle(
                        color: AppColors.getTextColor(mode),
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
                              color: AppColors.getTextColor(mode).withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildResultItem(
                            Translations.getOffsideText('offside', currentLang),
                            data['offside'] == true
                                ? Translations.getOffsideText('offside', currentLang).toUpperCase()
                                : 'NO',
                            data['offside'] == true,
                            mode,
                            seedColor,
                          ),
                          if (data['stats'] != null)
                            _buildResultItem(
                              Translations.getOffsideText('stats', currentLang),
                              (data['stats'] as Map).entries.map((e) => '${e.key}: ${e.value}').join(', '),
                              false,
                              mode,
                              seedColor,
                            ),
                          if (data['line_points'] != null)
                            _buildResultItem(
                              Translations.getOffsideText('linePoints', currentLang),
                              'Start: ${data['line_points']['start']}, End: ${data['line_points']['end']}',
                              false,
                              mode,
                              seedColor,
                            ),
                          if (data['annotated_image'] != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              Translations.getOffsideText('annotatedImage', currentLang),
                              style: TextStyle(
                                color: AppColors.getTextColor(mode),
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
                                  color: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  '$baseUrl/annotated/${data['annotated_image']}',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: AppColors.getSurfaceColor(mode),
                                    child: Center(
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
                                        valueColor: AlwaysStoppedAnimation(
                                          AppColors.getTertiaryColor(seedColor, mode),
                                        ),
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

  Widget _buildEmptyState(String message, int mode, Color seedColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(mode).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: 48,
            color: AppColors.getTertiaryColor(seedColor, mode),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: AppColors.getTextColor(mode).withOpacity(0.7),
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