import 'dart:async';
import 'dart:io';

import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/views/pages/BallGoalPage/controller/ballgoal_controller.dart';
import 'package:VarXPro/views/pages/BallGoalPage/model/ballgoal_model.dart';
import 'package:VarXPro/views/pages/BallGoalPage/service/ballgoal_service.dart';
import 'package:VarXPro/views/pages/BallGoalPage/widgets/image_picker_widget.dart';
import 'package:VarXPro/views/setting/provider/history_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/provider/modeprovider.dart';

class BallGoalPage extends StatefulWidget {
  const BallGoalPage({super.key});
  @override
  _BallGoalPageState createState() => _BallGoalPageState();
}

class _BallGoalPageState extends State<BallGoalPage> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Splash 3s
    Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final modeProvider = Provider.of<ModeProvider>(context);
    final currentLang = langProvider.currentLanguage;
    final mode = modeProvider.currentMode;
    final seedColor = AppColors.seedColors[mode] ?? AppColors.seedColors[1]!;
    final size = MediaQuery.of(context).size;
    final textPrimary = AppColors.getTextColor(mode);
    final textSecondary = textPrimary.withOpacity(0.7);
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    // SPLASH
    if (_showSplash) {
      return Scaffold(
        backgroundColor: AppColors.getBackgroundColor(mode),
        body: Center(
          child: Lottie.asset(
            'assets/lotties/FoulDetection.json',
            width: size.width * 0.8,
            height: size.height * 0.5,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    // PAGE
    return BlocProvider(
      create: (_) => BallGoalBloc(BallGoalService()),
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
            SafeArea(
              child: BlocConsumer<BallGoalBloc, BallGoalState>(
                listener: (context, state) {
                  if (state.ballInOutResponse?.ok == true || state.goalCheckResponse?.ok == true) {
                    final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
                    historyProvider.addHistoryItem('Ball & Goal', 'Ball/Goal analysis completed');
                  }
                },
                builder: (context, state) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16, isPortrait ? 12 : 8, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Erreur
                        if (state.error != null)
                          GlassCard(
                            mode: mode,
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.error_outline, color: Colors.redAccent),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${Translations.getBallGoalText('error', currentLang)}: ${state.error}',
                                    style: GoogleFonts.roboto(
                                      color: Colors.redAccent,
                                      fontSize: isPortrait ? 15 : 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Hero
                        GlassCard(
                          mode: mode,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionHeader(
                                icon: Icons.sports_soccer,
                                title: '${Translations.getBallGoalText('ballInOut', currentLang)} • ${Translations.getBallGoalText('goalCheck', currentLang)}',
                                mode: mode,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                Translations.getBallGoalText('selectImageForBallInOut', currentLang),
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // ======= Ball In/Out =======
                        GlassCard(
                          mode: mode,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionHeader(
                                icon: Icons.sports_soccer,
                                title: Translations.getBallGoalText('ballInOut', currentLang),
                                mode: mode,
                              ),
                              const SizedBox(height: 10),
                              ImagePickerWidget(
                                onImagePicked: (File image) => context.read<BallGoalBloc>().add(BallInOutEvent(image)),
                                buttonText: Translations.getBallGoalText('selectImageForBallInOut', currentLang),
                                mode: mode,
                                seedColor: seedColor,
                              ),
                              const SizedBox(height: 12),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: (state.ballInOutResponse == null)
                                    ? const SizedBox.shrink()
                                    : _BallInOutResult(
                                        response: state.ballInOutResponse!,
                                        mode: mode,
                                        seedColor: seedColor,
                                        currentLang: currentLang,
                                      ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // ======= Goal Check =======
                        GlassCard(
                          mode: mode,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionHeader(
                                icon: Icons.sports_score,
                                title: Translations.getBallGoalText('goalCheck', currentLang),
                                mode: mode,
                              ),
                              const SizedBox(height: 10),
                              ImagePickerWidget(
                                onImagePicked: (File image) => context.read<BallGoalBloc>().add(GoalCheckEvent(image)),
                                buttonText: Translations.getBallGoalText('selectImageForGoalCheck', currentLang),
                                mode: mode,
                                seedColor: seedColor,
                              ),
                              const SizedBox(height: 12),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: (state.goalCheckResponse == null)
                                    ? const SizedBox.shrink()
                                    : _GoalCheckResult(
                                        response: state.goalCheckResponse!,
                                        mode: mode,
                                        seedColor: seedColor,
                                        currentLang: currentLang,
                                      ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getResultColor(String result, int mode) {
    final textPrimary = AppColors.getTextColor(mode);
    final r = result.toLowerCase();
    if (r.contains('in') || r.contains('goal')) return Colors.green.withOpacity(0.85);
    if (r.contains('out')) return Colors.red.withOpacity(0.9);
    return textPrimary;
  }
}

// ======== Sub-Widgets ========

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
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: txt,
              letterSpacing: 0.3,
            ),
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
          Icon(
            icon,
            color: AppColors.getPrimaryColor(seedColor, mode).withOpacity(0.75),
          ),
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
          ),
        ],
      ),
    );
  }
}

class _DecisionBanner extends StatelessWidget {
  final int mode;
  final String decision;
  final Color color;
  final String subLabel;

  const _DecisionBanner({
    required this.mode,
    required this.decision,
    required this.color,
    required this.subLabel,
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
                  subLabel,
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
  final String outcome;
  final String currentLang;

  const _EvaluationBadge({
    required this.outcome,
    required this.currentLang,
  });

  @override
  Widget build(BuildContext context) {
    final isSuccess = outcome.toLowerCase() == 'success';
    final color = isSuccess ? Colors.green : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(isSuccess ? Icons.check_circle : Icons.cancel, color: color),
          const SizedBox(width: 8),
          Text(
            '${Translations.getBallGoalText('analysisSuccess', currentLang)}: ${outcome.toUpperCase()}',
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

class _BallInOutResult extends StatelessWidget {
  final BallInOutResponse response;
  final int mode;
  final Color seedColor;
  final String currentLang;

  const _BallInOutResult({
    required this.response,
    required this.mode,
    required this.seedColor,
    required this.currentLang,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EvaluationBadge(
          outcome: response.ok ? 'success' : 'failed',
          currentLang: currentLang,
        ),
        const SizedBox(height: 8),
        _DecisionBanner(
          mode: mode,
          decision: response.result,
          color: _getResultColor(response.result, mode),  // Use the function from state
          subLabel: Translations.getBallGoalText('result', currentLang),
        ),
        const SizedBox(height: 8),
        if (response.confidence != null)
          _SummaryItem(
            icon: Icons.bar_chart,
            label: Translations.getBallGoalText('confidence', currentLang),
            value: '${(response.confidence! * 100).toStringAsFixed(1)}%',
            mode: mode,
            seedColor: seedColor,
          ),
        if (response.boundaryGuess != null) ...[
          const SizedBox(height: 8),
          _SummaryItem(
            icon: Icons.aspect_ratio,
            label: Translations.getBallGoalText('boundarySide', currentLang),
            value: response.boundaryGuess!['side'] ?? 'N/A',
            mode: mode,
            seedColor: seedColor,
          ),
          _SummaryItem(
            icon: Icons.line_style,
            label: Translations.getBallGoalText('boundaryType', currentLang),
            value: response.boundaryGuess!['type'] ?? 'N/A',
            mode: mode,
            seedColor: seedColor,
          ),
        ],
      ],
    );
  }

  Color _getResultColor(String result, int mode) {
    final textPrimary = AppColors.getTextColor(mode);
    final r = result.toLowerCase();
    if (r.contains('in')) return Colors.green.withOpacity(0.85);
    if (r.contains('out')) return Colors.red.withOpacity(0.9);
    return textPrimary;
  }
}

class _GoalCheckResult extends StatelessWidget {
  final GoalCheckResponse response;
  final int mode;
  final Color seedColor;
  final String currentLang;

  const _GoalCheckResult({
    required this.response,
    required this.mode,
    required this.seedColor,
    required this.currentLang,
  });

  @override
  Widget build(BuildContext context) {
    final resultText = response.goal ? Translations.getBallGoalText('yes', currentLang) : Translations.getBallGoalText('no', currentLang);
    final resultColor = response.goal ? Colors.green.withOpacity(0.85) : Colors.red.withOpacity(0.9);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EvaluationBadge(
          outcome: response.ok ? 'success' : 'failed',
          currentLang: currentLang,
        ),
        const SizedBox(height: 8),
        _DecisionBanner(
          mode: mode,
          decision: resultText,
          color: resultColor,
          subLabel: Translations.getBallGoalText('isGoal', currentLang),
        ),
        const SizedBox(height: 8),
        if (response.confidence != null)
          _SummaryItem(
            icon: Icons.bar_chart,
            label: Translations.getBallGoalText('confidence', currentLang),
            value: '${(response.confidence! * 100).toStringAsFixed(1)}%',
            mode: mode,
            seedColor: seedColor,
          ),
      ],
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
    final rect = Rect.fromLTWH(inset, inset * 2, size.width - inset * 2, size.height - inset * 4);

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