// offside_page.dart
import 'dart:io';
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/views/pages/offsidePage/controller/offside_controller.dart';
import 'package:VarXPro/views/pages/offsidePage/service/offside_service.dart';
import 'package:VarXPro/views/pages/offsidePage/model/offside_model.dart';
import 'package:VarXPro/views/pages/offsidePage/widgets/OffsideForm.dart';
import 'package:VarXPro/views/setting/provider/history_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class OffsidePage extends StatefulWidget {
  const OffsidePage({super.key});

  @override
  _OffsidePageState createState() => _OffsidePageState();
}

class _OffsidePageState extends State<OffsidePage>
    with TickerProviderStateMixin {
  bool _showSplash = true;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowAnimation = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _fetchBatchResults(String? url) async {
    if (url == null) return null;
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      // Handle error silently
    }
    return null;
  }

  String _getBaseUrl(String jsonUrl) {
    if (jsonUrl.isEmpty) return '';
    final lastSlash = jsonUrl.lastIndexOf('/');
    return jsonUrl.substring(0, lastSlash + 1);
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final modeProvider = Provider.of<ModeProvider>(context);
    final currentLang = langProvider.currentLanguage;
    final seedColor =
        AppColors.seedColors[modeProvider.currentMode] ??
        AppColors.seedColors[1]!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    if (_showSplash) {
      return Scaffold(
        backgroundColor: AppColors.getBackgroundColor(modeProvider.currentMode),
        body: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _FootballGridPainter(modeProvider.currentMode),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.getBodyGradient(
                      modeProvider.currentMode,
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: ScaleTransition(
                scale: _glowAnimation,
                child: Lottie.asset(
                  'assets/lotties/offside.json',
                  width: screenWidth * 0.8,
                  height: MediaQuery.of(context).size.height * 0.5,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return BlocProvider(
      create: (context) =>
          OffsideBloc(context.read<OffsideService>())..add(PingEvent()),
      child: Builder(
        builder: (BuildContext blocContext) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _FootballGridPainter(modeProvider.currentMode),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.getBodyGradient(
                          modeProvider.currentMode,
                        ),
                      ),
                    ),
                  ),
                ),
                BlocBuilder<OffsideBloc, OffsideState>(
                  builder: (context, state) {
                    if (state.isLoading) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(
                            AppColors.getTertiaryColor(
                              seedColor,
                              modeProvider.currentMode,
                            ),
                          ),
                        ),
                      );
                    }
                    if (state.error != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ScaffoldMessenger.of(blocContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${Translations.getOffsideText('error', currentLang)}: ${state.error}',
                              style: GoogleFonts.roboto(
                                color: AppColors.getTextColor(
                                  modeProvider.currentMode,
                                ),
                                fontSize: 14,
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
                          padding: EdgeInsets.fromLTRB(
                            constraints.maxWidth * 0.04,
                            constraints.maxWidth * 0.04,
                            constraints.maxWidth * 0.04,
                            kBottomNavigationBarHeight + constraints.maxWidth * 0.06,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildApiStatusCard(state, currentLang, modeProvider.currentMode, seedColor),
                              SizedBox(height: constraints.maxWidth * 0.05),
                              _buildSectionHeader(
                                Translations.getOffsideText(
                                  'singleFrameDetection',
                                  currentLang,
                                ),
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
                                _buildSingleFrameResultCard(state, constraints, currentLang, modeProvider.currentMode, seedColor),
                              ],
                              if (state.offsideFrameResponse != null &&
                                  state.offsideFrameResponse!.offside != null)
                                Builder(
                                  builder: (context) {
                                    final historyProvider =
                                        Provider.of<HistoryProvider>(
                                          blocContext,
                                          listen: false,
                                        );
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      historyProvider.addHistoryItem(
                                        'Offside Detection',
                                        'Offside analysis completed',
                                      );
                                    });
                                    return const SizedBox.shrink();
                                  },
                                ),
                              SizedBox(height: constraints.maxWidth * 0.05),
                              _buildSectionHeader(
                                Translations.getOffsideText(
                                  'batchDetection',
                                  currentLang,
                                ),
                                modeProvider.currentMode,
                                seedColor,
                              ),
                              SizedBox(height: constraints.maxWidth * 0.03),
                              _buildBatchDetectionButtons(blocContext, constraints, currentLang, modeProvider.currentMode, seedColor),
                              if (state.offsideBatchResponse != null) ...[
                                SizedBox(height: constraints.maxWidth * 0.05),
                                _buildBatchResultCard(state, constraints, currentLang, modeProvider.currentMode, seedColor, _fetchBatchResults),
                              ],
                              SizedBox(height: constraints.maxWidth * 0.05),
                              if (state.runsResponse != null &&
                                  state.runsResponse!.runs.isNotEmpty)
                                _buildRunsList(
                                  state.runsResponse!.runs,
                                  constraints,
                                  currentLang,
                                  modeProvider.currentMode,
                                  seedColor,
                                )
                              else if (state.runsResponse != null)
                                _buildEmptyState(
                                  Translations.getOffsideText(
                                    'noRuns',
                                    currentLang,
                                  ),
                                  modeProvider.currentMode,
                                  seedColor,
                                )
                              else
                               
                              SizedBox(height: kBottomNavigationBarHeight + 16),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildApiStatusCard(OffsideState state, String currentLang, int mode, Color seedColor) {
    return Card(
      color: AppColors.getSurfaceColor(mode).withOpacity(0.9),
      elevation: 8,
      shadowColor: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      
    );
  }

  Widget _buildSingleFrameResultCard(OffsideState state, BoxConstraints constraints, String currentLang, int mode, Color seedColor) {
    return Card(
      color: AppColors.getSurfaceColor(mode).withOpacity(0.9),
      elevation: 8,
      shadowColor: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              AppColors.getSurfaceColor(mode).withOpacity(0.9),
              AppColors.getSurfaceColor(mode).withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: state.offsideFrameResponse!.offside ? Colors.redAccent : AppColors.getTertiaryColor(seedColor, mode),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  Translations.getOffsideText('detectionResult', currentLang),
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.getTextColor(mode),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildResultItem(
              Translations.getOffsideText('offside', currentLang),
              state.offsideFrameResponse!.offside
                  ? Translations.getOffsideText('offside', currentLang).toUpperCase()
                  : 'NO',
              state.offsideFrameResponse!.offside,
              mode,
              seedColor,
            ),
            _buildResultItem(
              'Offsides Count',
              state.offsideFrameResponse!.offsidesCount.toString(),
              false,
              mode,
              seedColor,
            ),
            if (state.offsideFrameResponse!.attackingTeam != null)
              _buildResultItem(
                'Attacking Team',
                state.offsideFrameResponse!.attackingTeam!,
                false,
                mode,
                seedColor,
              ),
            if (state.offsideFrameResponse!.secondLastDefenderProjection != null)
              _buildResultItem(
                'Second Last Proj',
                state.offsideFrameResponse!.secondLastDefenderProjection!.toStringAsFixed(2),
                false,
                mode,
                seedColor,
              ),
            if (state.offsideFrameResponse!.players != null)
              _buildResultItem(
                'Players',
                state.offsideFrameResponse!.players!.length.toString(),
                false,
                mode,
                seedColor,
              ),
            if (state.offsideFrameResponse!.reason != null && state.offsideFrameResponse!.reason != 'OK')
              _buildResultItem(
                'Reason',
                state.offsideFrameResponse!.reason!,
                false,
                mode,
                seedColor,
              ),
            if (state.offsideFrameResponse!.attackDirection != null)
              _buildResultItem(
                Translations.getOffsideText('attackDirection', currentLang),
                state.offsideFrameResponse!.attackDirection!,
                false,
                mode,
                seedColor,
              ),
            if (state.offsideFrameResponse!.linePoints != null)
              _buildResultItem(
                Translations.getOffsideText('linePoints', currentLang),
                'Start: [${state.offsideFrameResponse!.linePoints!['start']?[0]}, ${state.offsideFrameResponse!.linePoints!['start']?[1]}], End: [${state.offsideFrameResponse!.linePoints!['end']?[0]}, ${state.offsideFrameResponse!.linePoints!['end']?[1]}]',
                false,
                mode,
                seedColor,
              ),
            if (state.pickedImage != null) ...[
              const SizedBox(height: 16),
              _buildImageSection(Translations.getOffsideText('pickedImage', currentLang), state.pickedImage!, constraints, mode),
            ],
            if (state.offsideFrameResponse!.annotatedImageUrl != null) ...[
              const SizedBox(height: 16),
              _buildImageSection(Translations.getOffsideText('annotatedImage', currentLang), null, constraints, mode, imageUrl: state.offsideFrameResponse!.annotatedImageUrl!, seedColor: seedColor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBatchDetectionButtons(BuildContext blocContext, BoxConstraints constraints, String currentLang, int mode, Color seedColor) {
    return Row(
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
                blocContext.read<OffsideBloc>().add(DetectOffsideBatchEvent(images: files));
              }
            },
            icon: Icon(Icons.photo_library, size: 20, color: AppColors.getTextColor(mode)),
            label: Text(
              Translations.getOffsideText('pickImages', currentLang),
              style: GoogleFonts.roboto(
                color: AppColors.getTextColor(mode),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.getSecondaryColor(seedColor, mode),
              foregroundColor: AppColors.getTextColor(mode),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              shadowColor: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.3),
            ),
          ),
        ),
        SizedBox(width: constraints.maxWidth * 0.04),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['zip'],
              );
              if (result != null && result.files.single.path != null) {
                blocContext.read<OffsideBloc>().add(
                  DetectOffsideBatchEvent(
                    zipFile: File(result.files.single.path!),
                  ),
                );
              }
            },
            icon: Icon(Icons.archive, size: 20, color: AppColors.getTextColor(mode)),
            label: Text(
              Translations.getOffsideText('pickZip', currentLang),
              style: GoogleFonts.roboto(
                color: AppColors.getTextColor(mode),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.getSecondaryColor(seedColor, mode),
              foregroundColor: AppColors.getTextColor(mode),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              shadowColor: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBatchResultCard(OffsideState state, BoxConstraints constraints, String currentLang, int mode, Color seedColor, Future<Map<String, dynamic>?> Function(String?) fetcher) {
    return Card(
      color: AppColors.getSurfaceColor(mode).withOpacity(0.9),
      elevation: 8,
      shadowColor: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              AppColors.getSurfaceColor(mode).withOpacity(0.9),
              AppColors.getSurfaceColor(mode).withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: AppColors.getTertiaryColor(seedColor, mode),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  Translations.getOffsideText('batchResults', currentLang),
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.getTextColor(mode),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildResultItem(
              Translations.getOffsideText('processedFrames', currentLang),
              state.offsideBatchResponse!.count.toString(),
              false,
              mode,
              seedColor,
            ),
            if (state.offsideBatchResponse!.resultsJsonUrl != null) ...[
              FutureBuilder<Map<String, dynamic>?>(
                future: fetcher(state.offsideBatchResponse!.resultsJsonUrl),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                    return _buildResultItem(
                      Translations.getOffsideText('resultsJson', currentLang),
                      'Error loading details',
                      false,
                      mode,
                      seedColor,
                    );
                  }
                  final jsonContent = snapshot.data!;
                  final baseUrl = _getBaseUrl(state.offsideBatchResponse!.resultsJsonUrl!);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        Translations.getOffsideText('detailedResults', currentLang),
                        style: GoogleFonts.roboto(
                          color: AppColors.getTextColor(mode),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...((jsonContent['results'] as Map).entries.map((entry) {
                        final frame = entry.key;
                        final data = entry.value as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: AppColors.getSurfaceColor(mode).withOpacity(0.5),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '- $frame:',
                                  style: GoogleFonts.roboto(
                                    color: AppColors.getTextColor(mode).withOpacity(0.8),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildResultItem(
                                  Translations.getOffsideText('offside', currentLang),
                                  data['offside'] == true
                                      ? Translations.getOffsideText('offside', currentLang).toUpperCase()
                                      : 'NO',
                                  data['offside'] == true,
                                  mode,
                                  seedColor,
                                ),
                                _buildResultItem(
                                  'Offsides Count',
                                  data['offsides_count']?.toString() ?? '0',
                                  false,
                                  mode,
                                  seedColor,
                                ),
                                if (data['attacking_team'] != null)
                                  _buildResultItem(
                                    'Attacking Team',
                                    data['attacking_team'],
                                    false,
                                    mode,
                                    seedColor,
                                  ),
                                if (data['second_last_defender_projection'] != null)
                                  _buildResultItem(
                                    'Second Last Proj',
                                    data['second_last_defender_projection'].toString(),
                                    false,
                                    mode,
                                    seedColor,
                                  ),
                                if (data['players'] != null)
                                  _buildResultItem(
                                    'Players',
                                    (data['players'] as List).length.toString(),
                                    false,
                                    mode,
                                    seedColor,
                                  ),
                                if (data['reason'] != null && data['reason'] != 'OK')
                                  _buildResultItem(
                                    'Reason',
                                    data['reason'],
                                    false,
                                    mode,
                                    seedColor,
                                  ),
                                if (data['line_points'] != null)
                                  _buildResultItem(
                                    Translations.getOffsideText('linePoints', currentLang),
                                    'Start: [${data['line_points']['start'][0]}, ${data['line_points']['start'][1]}], End: [${data['line_points']['end'][0]}, ${data['line_points']['end'][1]}]',
                                    false,
                                    mode,
                                    seedColor,
                                  ),
                                if (data['annotated_image'] != null) ...[
                                  const SizedBox(height: 12),
                                  _buildImageSection(
                                    Translations.getOffsideText('annotatedImage', currentLang),
                                    null,
                                    constraints,
                                    mode,
                                    imageUrl: '$baseUrl/annotated/${data['annotated_image']}',
                                    seedColor: seedColor,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList()),
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

 

  Widget _buildImageSection(String title, File? file, BoxConstraints constraints, int mode, {String? imageUrl, Color? seedColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
            color: AppColors.getTextColor(mode),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          constraints: BoxConstraints(
            maxHeight: constraints.maxWidth * 0.6,
            maxWidth: constraints.maxWidth * 0.95,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: seedColor != null ? AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.4) : Colors.grey.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (seedColor != null ? AppColors.getTertiaryColor(seedColor, mode) : Colors.grey).withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: file != null
                ? Image.file(
                    file,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.getSurfaceColor(mode),
                      child: Center(
                        child: Icon(Icons.error_outline, color: Colors.redAccent, size: 50),
                      ),
                    ),
                  )
                : imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColors.getSurfaceColor(mode),
                          child: Center(
                            child: Icon(Icons.error_outline, color: Colors.redAccent, size: 50),
                          ),
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                              valueColor: AlwaysStoppedAnimation(seedColor != null ? AppColors.getTertiaryColor(seedColor, mode) : Colors.grey),
                            ),
                          );
                        },
                      )
                    : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusItem(String label, String value, int mode, Color seedColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.roboto(
                    color: AppColors.getTextColor(mode).withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.roboto(
                    color: AppColors.getTextColor(mode),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int mode, Color seedColor) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.getTertiaryColor(seedColor, mode),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.getTextColor(mode),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildResultItem(String label, String value, bool isOffside, int mode, Color seedColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.getTextColor(mode).withOpacity(0.5)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.roboto(
                    color: AppColors.getTextColor(mode).withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.roboto(
                    color: isOffside ? Colors.redAccent : AppColors.getTertiaryColor(seedColor, mode),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunsList(
    List<Run> runs,
    BoxConstraints constraints,
    String currentLang,
    int mode,
    Color seedColor,
  ) {
    final validRuns = runs.where((run) => run.resultsJson != null).toList();

    if (validRuns.isEmpty) {
      return _buildEmptyState(
        Translations.getOffsideText('noValidRuns', currentLang),
        mode,
        seedColor,
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: validRuns.length,
      separatorBuilder: (context, index) => SizedBox(height: constraints.maxWidth * 0.02),
      itemBuilder: (context, index) {
        final run = validRuns[index];
        return FutureBuilder<Map<String, dynamic>?>(
          future: () async {
            if (run.resultsJsonContent != null) {
              return run.resultsJsonContent as Map<String, dynamic>?;
            }
            return await _fetchBatchResults(run.resultsJson);
          }(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Card(
                color: AppColors.getSurfaceColor(mode).withOpacity(0.9),
                elevation: 4,
                shadowColor: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }
            final jsonContent = snapshot.data;
            if (jsonContent == null) {
              return Card(
                color: AppColors.getSurfaceColor(mode).withOpacity(0.9),
                elevation: 4,
                shadowColor: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Failed to load details',
                    style: GoogleFonts.roboto(
                      color: AppColors.getTextColor(mode),
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }
            final date = _parseRunDate(run.run);
            final baseUrl = run.resultsJson != null
                ? _getBaseUrl(run.resultsJson!)
                : '';
            return Card(
              color: AppColors.getSurfaceColor(mode).withOpacity(0.9),
              elevation: 4,
              shadowColor: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ExpansionTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.analytics, color: AppColors.getTertiaryColor(seedColor, mode)),
                ),
                title: Text(
                  date ?? run.run,
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextColor(mode),
                    fontSize: 16,
                  ),
                ),
                subtitle: date != null
                    ? Text(
                        run.run,
                        style: GoogleFonts.roboto(
                          color: AppColors.getTextColor(mode).withOpacity(0.6),
                          fontSize: 12,
                        ),
                      )
                    : null,
                childrenPadding: const EdgeInsets.all(16.0),
                children: [
                  _buildRunParameters(jsonContent, currentLang, mode, seedColor),
                  const SizedBox(height: 16),
                  _buildRunResults(jsonContent, baseUrl, constraints, currentLang, mode, seedColor),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRunParameters(Map<String, dynamic> jsonContent, String currentLang, int mode, Color seedColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Translations.getOffsideText('parameters', currentLang),
          style: GoogleFonts.roboto(
            color: AppColors.getTextColor(mode),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
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
      ],
    );
  }

  Widget _buildRunResults(Map<String, dynamic> jsonContent, String baseUrl, BoxConstraints constraints, String currentLang, int mode, Color seedColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Translations.getOffsideText('resultsJson', currentLang),
          style: GoogleFonts.roboto(
            color: AppColors.getTextColor(mode),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        ...((jsonContent['results'] as Map).entries.map((entry) {
          final frame = entry.key;
          final data = entry.value as Map<String, dynamic>;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: AppColors.getSurfaceColor(mode).withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '- $frame:',
                    style: GoogleFonts.roboto(
                      color: AppColors.getTextColor(mode).withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildResultItem(
                    Translations.getOffsideText('offside', currentLang),
                    data['offside'] == true
                        ? Translations.getOffsideText('offside', currentLang).toUpperCase()
                        : 'NO',
                    data['offside'] == true,
                    mode,
                    seedColor,
                  ),
                  _buildResultItem(
                    'Offsides Count',
                    data['offsides_count']?.toString() ?? '0',
                    false,
                    mode,
                    seedColor,
                  ),
                  if (data['attacking_team'] != null)
                    _buildResultItem(
                      'Attacking Team',
                      data['attacking_team'],
                      false,
                      mode,
                      seedColor,
                    ),
                  if (data['second_last_defender_projection'] != null)
                    _buildResultItem(
                      'Second Last Proj',
                      data['second_last_defender_projection'].toString(),
                      false,
                      mode,
                      seedColor,
                    ),
                  if (data['players'] != null)
                    _buildResultItem(
                      'Players',
                      (data['players'] as List).length.toString(),
                      false,
                      mode,
                      seedColor,
                    ),
                  if (data['reason'] != null && data['reason'] != 'OK')
                    _buildResultItem(
                      'Reason',
                      data['reason'],
                      false,
                      mode,
                      seedColor,
                    ),
                  if (data['line_points'] != null)
                    _buildResultItem(
                      Translations.getOffsideText('linePoints', currentLang),
                      'Start: [${data['line_points']['start'][0]}, ${data['line_points']['start'][1]}], End: [${data['line_points']['end'][0]}, ${data['line_points']['end'][1]}]',
                      false,
                      mode,
                      seedColor,
                    ),
                  if (data['annotated_image'] != null) ...[
                    const SizedBox(height: 12),
                    _buildImageSection(
                      Translations.getOffsideText('annotatedImage', currentLang),
                      null,
                      constraints,
                      mode,
                      imageUrl: '$baseUrl/annotated/${data['annotated_image']}',
                      seedColor: seedColor,
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList()),
      ],
    );
  }

  Widget _buildEmptyState(String message, int mode, Color seedColor) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(mode).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.roboto(
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

class _FootballGridPainter extends CustomPainter {
  final int mode;

  _FootballGridPainter(this.mode);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.getTextColor(mode).withOpacity(0.05)
      ..strokeWidth = 0.5;

    const step = 50.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final fieldPaint = Paint()
      ..color = AppColors.getTextColor(mode).withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final inset = 40.0;
    final rect = Rect.fromLTWH(
      inset,
      inset * 2,
      size.width - inset * 2,
      size.height - inset * 4,
    );
    canvas.drawRect(rect, fieldPaint);

    final midX = rect.center.dy;
    canvas.drawLine(
      Offset(rect.left + rect.width / 2 - 100, midX),
      Offset(rect.left + rect.width / 2 + 100, midX),
      fieldPaint,
    );
    canvas.drawCircle(Offset(rect.left + rect.width / 2, midX), 30, fieldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}