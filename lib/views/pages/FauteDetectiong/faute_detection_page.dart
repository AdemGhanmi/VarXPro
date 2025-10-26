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
        AppColors.seedColors[mode] ?? AppColors.seedColors[1]!;
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
          SafeArea(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Column(
                  children: [
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
          // DROPDOWN - DÉCISION ARBITRE (INPUT)
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
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: textPrimary.withOpacity(0.35)),
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
          // RÉSUMÉ D'ANALYSE - TOUT COMME DEMANDÉ + ARBITRE + ÉVALUATION
          if (_controller.result != null && _controller.result!.ok && inference != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  icon: Icons.analytics_outlined,
                  title: Translations.getFoulDetectionText('analysisSummary', currentLang),
                  mode: mode,
                ),
                const SizedBox(height: 10),
                GlassCard(
                  mode: mode,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    children: [
                      // 1. FAUTE DÉTECTÉE
                      _SimpleSummaryItem(
                        label: eventsCount == 1 
                            ? Translations.getFoulDetectionText('foulsDetectedSingular', currentLang) 
                            : Translations.getFoulDetectionText('foulsDetectedPlural', currentLang),
                        value: eventsCount.toString(),
                        mode: mode,
                        seedColor: seedColor,
                      ),
                      const SizedBox(height: 12),
                      // 2. DÉCISION FINALE
                      _SimpleSummaryItem(
                        label: Translations.getFoulDetectionText('finalDecision', currentLang),
                        value: inference.finalDecision,
                        mode: mode,
                        seedColor: seedColor,
                        isDecision: true,
                      ),
                      const SizedBox(height: 12),
                      // 3. ACTION PRINCIPALE (SANS %)
                      _SimpleSummaryItem(
                        label: Translations.getFoulDetectionText('mainAction', currentLang),
                        value: inference.actionTopLabel,
                        mode: mode,
                        seedColor: seedColor,
                      ),
                      const SizedBox(height: 12),
                      // 4. ACTION SECONDAIRE (SANS %)
                      _SimpleSummaryItem(
                        label: Translations.getFoulDetectionText('secondaryAction', currentLang),
                        value: inference.actionTop2Label,
                        mode: mode,
                        seedColor: seedColor,
                      ),
                      const SizedBox(height: 12),
                      // 5. DÉCISION ARBITRE (OUTPUT)
                      if (evaluation != null && evaluation['referee'] != null)
                        _SimpleSummaryItem(
                          label: Translations.getFoulDetectionText('refereeDecision', currentLang),
                          value: evaluation['referee'],
                          mode: mode,
                          seedColor: seedColor,
                          isDecision: true,
                        ),
                      const SizedBox(height: 12),
                      // 6. ÉVALUATION
                      if (evaluation != null && evaluation['outcome'] != null)
                        _SimpleSummaryItem(
                          label: Translations.getFoulDetectionText('evaluation', currentLang),
                          value: evaluation['outcome'].toString().toUpperCase(),
                          mode: mode,
                          seedColor: seedColor,
                          isEvaluation: true,
                        ),
                    ],
                  ),
                ),
              ],
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
                    text: Translations.getFoulDetectionText('noVideoAvailable', currentLang),
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
}

// ======== WIDGET SIMPLE MODIFIÉ POUR ARBITRE + ÉVALUATION ========
class _SimpleSummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final int mode;
  final Color seedColor;
  final bool isDecision;
  final bool isEvaluation;
  const _SimpleSummaryItem({
    required this.label,
    required this.value,
    required this.mode,
    required this.seedColor,
    this.isDecision = false,
    this.isEvaluation = false,
  });

  @override
  Widget build(BuildContext context) {
    final txt = AppColors.getTextColor(mode);
    Color valueColor = txt;
   
    // Couleur pour Décision finale / Arbitre
    if (isDecision) {
      final d = value.toLowerCase();
      if (d.contains('no')) valueColor = Colors.green;
      else if (d.contains('yellow')) valueColor = Colors.amber;
      else if (d.contains('red')) valueColor = Colors.red;
    }
   
    // Couleur pour Évaluation
    if (isEvaluation) {
      final e = value.toLowerCase();
      valueColor = e == 'correct' ? Colors.green : Colors.red;
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.getPrimaryColor(seedColor, mode).withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getPrimaryColor(seedColor, mode).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Label à gauche
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: GoogleFonts.roboto(
                color: txt.withOpacity(0.7),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Value à droite
          Expanded(
            flex: 1,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.roboto(
                color: valueColor,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ======== TOUS LES AUTRES WIDGETS (INCHANGÉS) ========
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
        border: Border.all(color: AppColors.getTextColor(mode).withOpacity(0.08)),
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
          color: AppColors.getSecondaryColor(AppColors.seedColors[1]!, 1).withOpacity(0.85),
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
    final rect = Rect.fromLTWH(
        inset, inset * 2, size.width - inset * 2, size.height - inset * 4);
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

///////////
