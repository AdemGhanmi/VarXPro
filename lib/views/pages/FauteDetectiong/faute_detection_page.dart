import 'dart:async';
import 'dart:io';

import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/views/pages/FauteDetectiong/controller/foul_detection_controller.dart';
import 'package:VarXPro/views/pages/FauteDetectiong/view/video_viewer.dart';
import 'package:VarXPro/views/setting/provider/history_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class FoulDetectionPage extends StatefulWidget {
  const FoulDetectionPage({super.key});

  @override
  State<FoulDetectionPage> createState() => _FoulDetectionPageState();
}

class _FoulDetectionPageState extends State<FoulDetectionPage>
    with TickerProviderStateMixin {
  final FoulDetectionController _controller = FoulDetectionController();
  final ScrollController _scrollController = ScrollController();

  bool _showSplash = true;
  String? _selectedRefereeDecision;
  List<File>? _videoFiles;
  bool _isMultiView = false;

  late final AnimationController _heroPulseCtrl;
  late final Animation<double> _heroPulse;

  @override
  void initState() {
    super.initState();

    _heroPulseCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _heroPulse = Tween<double>(begin: 0.25, end: 0.75).animate(
      CurvedAnimation(parent: _heroPulseCtrl, curve: Curves.easeInOut),
    );

    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showSplash = false);
      _controller.pingServer();
      _controller.fetchVersion();
    });
  }

  @override
  void dispose() {
    _heroPulseCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo(bool multi) async {
    final allowMultiple = multi;
    final result = await FilePicker.platform
        .pickFiles(type: FileType.video, allowMultiple: allowMultiple);
    if (result != null && result.files.isNotEmpty) {
      List<File> videos = [];
      for (var file in result.files) {
        if (file.path != null) {
          videos.add(File(file.path!));
        }
      }
      if (videos.isNotEmpty) {
        setState(() {
          _videoFiles = videos;
          _isMultiView = multi;
        });
        await _controller.analyzeVideo(
          videoFile: videos.first,
          refereeDecision: _selectedRefereeDecision,
        );

        // Log history si OK
        if (_controller.result != null && _controller.result!.ok) {
          final historyProvider =
              Provider.of<HistoryProvider>(context, listen: false);
          final angleText = multi ? '${videos.length} angles' : 'single angle';
          historyProvider.addHistoryItem(
            'Foul Detection',
            'VAR analysis completed for $angleText',
          );
        }
        if (mounted) setState(() {});
      }
    }
  }

  Color _getDecisionColor(String decision, int mode) {
    final textPrimary = AppColors.getTextColor(mode);
    final d = decision.toLowerCase();
    if (d.contains('no')) return Colors.green.withOpacity(0.85);
    if (d.contains('yellow')) return Colors.amber.withOpacity(0.9);
    if (d.contains('red')) return Colors.red.withOpacity(0.9);
    return textPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final modeProvider = Provider.of<ModeProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final currentLang = langProvider.currentLanguage;

    final mode = modeProvider.currentMode;
    final seedColor =
        AppColors.seedColors[mode] ?? AppColors.seedColors[1]!; // fallback

    if (_showSplash) {
      return Scaffold(
        backgroundColor: AppColors.getBackgroundColor(mode),
        body: Center(
          child: Lottie.asset(
            'assets/lotties/FoulDetection.json',
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.5,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(mode),
      body: Stack(
        children: [
          // Fond animé + grille terrain
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.getBodyGradient(mode),
              ),
              child: CustomPaint(
                painter: _FootballGridPainter(mode),
              ),
            ),
          ),

          // Contenu
          SafeArea(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Column(
                  children: [
                    // Loader global ou contenu
                    Expanded(
                      child: _controller.isLoading
                          ? _GlobalLoader(
                              mode: mode,
                              seedColor: seedColor,
                              text: Translations.getFoulDetectionText(
                                  'loading', currentLang),
                            )
                          : _buildSummaryView(
                              context: context,
                              mode: mode,
                              seedColor: seedColor,
                              currentLang: currentLang,
                            ),
                    ),

                    // Barre d’action avec deux boutons
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ModeButton(
                              label: Translations.getFoulDetectionText(
                                  'singleView', currentLang),
                              isSelected: !_isMultiView,
                              onTap: () async {
                                setState(() {
                                  _isMultiView = false;
                                });
                                await _pickVideo(false);
                              },
                              mode: mode,
                              seedColor: seedColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ModeButton(
                              label: Translations.getFoulDetectionText(
                                  'multiView', currentLang),
                              isSelected: _isMultiView,
                              onTap: () async {
                                setState(() {
                                  _isMultiView = true;
                                });
                                await _pickVideo(true);
                              },
                              mode: mode,
                              seedColor: seedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryView({
    required BuildContext context,
    required int mode,
    required Color seedColor,
    required String currentLang,
  }) {
    final textPrimary = AppColors.getTextColor(mode);
    final textSecondary = textPrimary.withOpacity(0.7);
    final cardColor = AppColors.getSurfaceColor(mode);
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    final inference = _controller.result?.inference;
    final evaluation = _controller.result?.evaluation;

    final hasFoul = (inference != null) &&
        !inference.finalDecision.toLowerCase().contains('no');

    final eventsCount = hasFoul ? 1 : 0;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(16, isPortrait ? 12 : 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Erreur
          if (_controller.error != null)
            GlassCard(
              mode: mode,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${Translations.getFoulDetectionText('error', currentLang)}: ${_controller.error!}',
                      style: GoogleFonts.roboto(
                        color: Colors.redAccent,
                        fontSize: isPortrait ? 15 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Retry',
                    onPressed: () {
                      _controller.pingServer();
                      _controller.fetchVersion();
                    },
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: AppColors.getTertiaryColor(seedColor, mode),
                    ),
                  )
                ],
              ),
            ),

          // Paramètres “Referee decision” (nullable fix)
          _SectionHeader(
            icon: Icons.sports,
            title: Translations.getFoulDetectionText('refereeDecisionOptional', currentLang),
            mode: mode,
          ),
          const SizedBox(height: 10),
          GlassCard(
            mode: mode,
            padding: const EdgeInsets.all(14),
            child: DropdownButtonFormField<String?>(
              value: _selectedRefereeDecision,
              icon: const Icon(Icons.expand_more_rounded),
              dropdownColor: cardColor,
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: _outline(textSecondary),
                enabledBorder: _outline(textSecondary),
                focusedBorder: _outline(
                  AppColors.getPrimaryColor(seedColor, mode),
                ),
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null, 
                  child: Text(Translations.getFoulDetectionText('none', currentLang))
                ),
                DropdownMenuItem<String?>(
                  value: 'No offence', 
                  child: Text(Translations.getFoulDetectionText('noOffence', currentLang))
                ),
                DropdownMenuItem<String?>(
                  value: 'Yellow card', 
                  child: Text(Translations.getFoulDetectionText('yellowCard', currentLang))
                ),
                DropdownMenuItem<String?>(
                  value: 'Red card', 
                  child: Text(Translations.getFoulDetectionText('redCard', currentLang))
                ),
              ],
              onChanged: (val) => setState(() => _selectedRefereeDecision = val),
            ),
          ),
          const SizedBox(height: 18),

          // Résumé d’analyse
          if (_controller.result != null && _controller.result!.ok && inference != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  icon: Icons.analytics_outlined,
                  title:
                      Translations.getFoulDetectionText('analysisSummary', currentLang),
                  mode: mode,
                ),
                const SizedBox(height: 10),
                GlassCard(
                  mode: mode,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    children: [
                      _SummaryItem(
                        icon: Icons.flag,
                        label: Translations.getFoulDetectionText(
                            'eventsDetected', currentLang),
                        value: eventsCount.toString(),
                        mode: mode,
                        seedColor: seedColor,
                      ),
                      const SizedBox(height: 8),
                      _DecisionBanner(
                        mode: mode,
                        decision: inference.finalDecision,
                        color: _getDecisionColor(inference.finalDecision, mode),
                        currentLang: currentLang,
                      ),
                      const SizedBox(height: 8),
                      _SummaryItem(
                        icon: Icons.sports_soccer,
                        label: Translations.getFoulDetectionText('topAction', currentLang),
                        value:
                            '${inference.actionTopLabel} (${(inference.actionTopProb * 100).toStringAsFixed(1)}%)',
                        mode: mode,
                        seedColor: seedColor,
                      ),
                      const SizedBox(height: 8),
                      _SummaryItem(
                        icon: Icons.sports_soccer_outlined,
                        label: Translations.getFoulDetectionText('secondAction', currentLang),
                        value:
                            '${inference.actionTop2Label} (${(inference.actionTop2Prob * 100).toStringAsFixed(1)}%)',
                        mode: mode,
                        seedColor: seedColor,
                      ),
                      const SizedBox(height: 8),

                      // Chips des probabilités
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _probChip(
                              mode,
                              currentLang,
                              Translations.getFoulDetectionText('noOffence', currentLang),
                              '${(inference.severityMap['no']! * 100).toStringAsFixed(1)}%',
                              Colors.green,
                            ),
                            _probChip(
                              mode,
                              currentLang,
                              Translations.getFoulDetectionText('yellow', currentLang),
                              '${(inference.severityMap['yellow']! * 100).toStringAsFixed(1)}%',
                              Colors.amber,
                            ),
                            _probChip(
                              mode,
                              currentLang,
                              Translations.getFoulDetectionText('red', currentLang),
                              '${(inference.severityMap['red']! * 100).toStringAsFixed(1)}%',
                              Colors.redAccent,
                            ),
                          ],
                        ),
                      ),

                      // Version
                      if (_controller.version != null) ...[
                        const SizedBox(height: 8),
                        _SummaryItem(
                          icon: Icons.info_outline,
                          label: Translations.getFoulDetectionText('version', currentLang),
                          value: _controller.version!,
                          mode: mode,
                          seedColor: seedColor,
                        ),
                      ],

                      // Evaluation vs referee
                      if (evaluation != null) ...[
                        const SizedBox(height: 10),
                        _SummaryItem(
                          icon: Icons.person,
                          label: Translations.getFoulDetectionText('refereeDecision', currentLang),
                          value: evaluation['referee'] ?? 'N/A',
                          mode: mode,
                          seedColor: seedColor,
                        ),
                        const SizedBox(height: 8),
                        _EvaluationBadge(
                          outcome: '${evaluation['outcome']}',
                          currentLang: currentLang,
                        ),
                      ],

                      // Notes
                      if (inference.notes.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _NotesBlock(
                          mode: mode,
                          notes: inference.notes.cast<String>(),
                          currentLang: currentLang,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            )
          else if (_controller.result != null && !_controller.result!.ok)
            GlassCard(
              mode: mode,
              padding: const EdgeInsets.all(16),
              child: Text(
                _controller.result!.error ??
                    Translations.getFoulDetectionText(
                        'summaryNotAvailable', currentLang),
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  color: textSecondary,
                  fontSize: isPortrait ? 16 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Video viewer
          _SectionHeader(
            icon: Icons.play_circle_outline,
            title: Translations.getFoulDetectionText('video', currentLang),
            mode: mode,
          ),
          const SizedBox(height: 10),
          GlassCard(
            mode: mode,
            child: _videoFiles != null && _videoFiles!.isNotEmpty
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      final videos = _videoFiles!;
                      final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
                      if (isPortrait) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: videos.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final videoFile = entry.value;
                              return Padding(
                                padding: EdgeInsets.only(bottom: idx < videos.length - 1 ? 8.0 : 0.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    height: 180,
                                    child: VideoViewer(
                                      videoFile: videoFile,
                                      mode: mode,
                                      seedColor: seedColor,
                                      currentLang: currentLang,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: videos.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final videoFile = entry.value;
                              return Padding(
                                padding: EdgeInsets.only(right: idx < videos.length - 1 ? 8.0 : 0.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: constraints.maxWidth / videos.length,
                                    height: 160,
                                    child: VideoViewer(
                                      videoFile: videoFile,
                                      mode: mode,
                                      seedColor: seedColor,
                                      currentLang: currentLang,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      }
                    },
                  )
                : _EmptyState(
                    icon: Icons.video_file_outlined,
                    text:
                        Translations.getFoulDetectionText('noVideoAvailable', currentLang),
                    mode: mode,
                  ),
          ),

          const SizedBox(height: 20),

          // Snapshot annoté
          _SectionHeader(
            icon: Icons.image_outlined,
            title: Translations.getFoulDetectionText('annotatedSnapshot', currentLang),
            mode: mode,
          ),
          const SizedBox(height: 10),
          GlassCard(
            mode: mode,
            height: isPortrait ? 420 : 360,
            child: _controller.imageUrl != null
                ? GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => FullScreenImageViewer(
                            imageUrl: _controller.imageUrl!,
                            mode: mode,
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _NetworkImageWithSkeleton(
                        url: _controller.imageUrl!,
                        mode: mode,
                        currentLang: currentLang,
                      ),
                    ),
                  )
                : _EmptyState(
                    icon: Icons.image_outlined,
                    text: Translations.getFoulDetectionText('noSnapshotAvailable', currentLang),
                    mode: mode,
                  ),
          ),
        ],
      ),
    );
  }

  static OutlineInputBorder _outline(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color.withOpacity(0.35), width: 1.2),
      );

  static Widget _probChip(
      int mode, String currentLang, String label, String value, Color accent) {
    final txt = AppColors.getTextColor(mode);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: accent.withOpacity(0.08),
        border: Border.all(color: accent.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.18),
            blurRadius: 12,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bubble_chart, size: 16, color: accent),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: GoogleFonts.roboto(
              color: txt.withOpacity(0.7),
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.roboto(
              color: accent,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ======== Full Screen Image Viewer ========

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final int mode;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(20.0),
          minScale: 0.5,
          maxScale: 4.0,
          panEnabled: true,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(Icons.image_not_supported_outlined, color: Colors.white70, size: 64),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ======== Sub-Widgets design ========

class GlassCard extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final int mode;

  const GlassCard({
    super.key,
    required this.mode,
    this.child,
    this.padding,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.getSurfaceColor(mode).withOpacity(0.5);
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [bg, bg.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border:
            Border.all(color: AppColors.getTextColor(mode).withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.02),
            blurRadius: 2,
            spreadRadius: -1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int mode;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final txt = AppColors.getTextColor(mode);
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors
              .getSecondaryColor(AppColors.seedColors[1]!, 1)
              .withOpacity(0.85),
          size: 26,
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: txt,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final int mode;
  final Color seedColor;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.mode,
    required this.seedColor,
  });

  @override
  Widget build(BuildContext context) {
    final txt = AppColors.getTextColor(mode);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getPrimaryColor(seedColor, mode).withOpacity(0.055),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: AppColors
                  .getPrimaryColor(seedColor, mode)
                  .withOpacity(0.75)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.roboto(
                    color: txt.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.roboto(
                    color: txt,
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _DecisionBanner extends StatelessWidget {
  final int mode;
  final String decision;
  final Color color;
  final String currentLang;

  const _DecisionBanner({
    required this.mode,
    required this.decision,
    required this.color,
    required this.currentLang,
  });

  @override
  Widget build(BuildContext context) {
    final txt = AppColors.getTextColor(mode);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.18),
            blurRadius: 16,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Translations.getFoulDetectionText('finalDecision', currentLang),
                  style: GoogleFonts.roboto(
                    color: txt.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 12.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  decision,
                  style: GoogleFonts.roboto(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EvaluationBadge extends StatelessWidget {
  final String outcome; // 'correct' / 'incorrect' etc.
  final String currentLang;

  const _EvaluationBadge({
    required this.outcome,
    required this.currentLang,
  });

  @override
  Widget build(BuildContext context) {
    final isCorrect = outcome.toLowerCase() == 'correct';
    final color = isCorrect ? Colors.green : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: color),
          const SizedBox(width: 8),
          Text(
            '${Translations.getFoulDetectionText('evaluation', currentLang)}: ${outcome.toUpperCase()}',
            style: GoogleFonts.roboto(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesBlock extends StatelessWidget {
  final int mode;
  final List<String> notes;
  final String currentLang;

  const _NotesBlock({
    required this.mode, 
    required this.notes,
    required this.currentLang,
  });

  @override
  Widget build(BuildContext context) {
    final txt = AppColors.getTextColor(mode);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: txt.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${Translations.getFoulDetectionText('notes', currentLang)}:',
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w900,
              color: txt,
              fontSize: 15.5,
            ),
          ),
          const SizedBox(height: 6),
          ...notes.map(
            (n) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ',
                      style: GoogleFonts.roboto(
                        color: txt.withOpacity(0.75),
                        fontSize: 14,
                      )),
                  Expanded(
                    child: Text(
                      n,
                      style: GoogleFonts.roboto(
                        color: txt.withOpacity(0.75),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  final int mode;

  const _EmptyState({
    required this.icon,
    required this.text,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final txt = AppColors.getTextColor(mode);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 46, color: txt.withOpacity(0.45)),
          const SizedBox(height: 8),
          Text(
            text,
            style: GoogleFonts.roboto(
              color: txt.withOpacity(0.65),
              fontWeight: FontWeight.w600,
              fontSize: 14.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlobalLoader extends StatelessWidget {
  final int mode;
  final Color seedColor;
  final String text;

  const _GlobalLoader({
    required this.mode,
    required this.seedColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final txt = AppColors.getTextColor(mode);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(
              AppColors.getLabelColor(seedColor, mode),
            ),
            strokeWidth: 4,
          ),
          const SizedBox(height: 18),
          Text(
            text,
            style: GoogleFonts.roboto(
              color: txt.withOpacity(0.75),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int mode;
  final Color seedColor;

  const _ModeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.mode,
    required this.seedColor,
  });

  @override
  Widget build(BuildContext context) {
    final txt = AppColors.getTextColor(mode);
    final primaryColor = AppColors.getPrimaryColor(seedColor, mode);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? primaryColor : Colors.transparent,
          border: Border.all(
            color: primaryColor.withOpacity(isSelected ? 0 : 0.3),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.roboto(
              color: isSelected ? txt : txt.withOpacity(0.7),
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _NetworkImageWithSkeleton extends StatefulWidget {
  final String url;
  final int mode;
  final String currentLang;

  const _NetworkImageWithSkeleton({
    required this.url,
    required this.mode,
    required this.currentLang,
  });

  @override
  State<_NetworkImageWithSkeleton> createState() =>
      _NetworkImageWithSkeletonState();
}

class _NetworkImageWithSkeletonState extends State<_NetworkImageWithSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.getTextColor(widget.mode).withOpacity(0.06);
    return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(20.0),
      minScale: 0.5,
      maxScale: 4.0,
      panEnabled: true,
      child: Image.network(
        widget.url,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) {
            return child;
          }
          return AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              return Container(
                color: bg,
                child: Center(
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                            (progress.expectedTotalBytes ?? 1)
                        : (_ctrl.value),
                  ),
                ),
              );
            },
          );
        },
        errorBuilder: (context, error, stack) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.image_not_supported_outlined,
                    color: Colors.redAccent, size: 44),
                const SizedBox(height: 8),
                Text(
                  'Failed to load snapshot',
                  style: GoogleFonts.roboto(
                    color: AppColors.getTextColor(widget.mode).withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ======== Background painter ========

class _FootballGridPainter extends CustomPainter {
  final int mode;

  _FootballGridPainter(this.mode);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.getTextColor(mode).withOpacity(0.045)
      ..strokeWidth = 0.5;

    const step = 48.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final fieldPaint = Paint()
      ..color = AppColors.getTextColor(mode).withOpacity(0.085)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const inset = 40.0;
    final rect =
        Rect.fromLTWH(inset, inset * 2, size.width - inset * 2, size.height - inset * 4);

    // Terrain central + cercle
    canvas.drawRect(rect, fieldPaint);
    final midY = rect.center.dy;
    canvas.drawLine(
      Offset(rect.left + rect.width / 2 - 100, midY),
      Offset(rect.left + rect.width / 2 + 100, midY),
      fieldPaint,
    );
    canvas.drawCircle(Offset(rect.left + rect.width / 2, midY), 30, fieldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}