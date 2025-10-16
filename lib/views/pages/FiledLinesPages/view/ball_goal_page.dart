///import 'dart:async';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui; // pour BackdropFilter (blur)
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/views/pages/FiledLinesPages/controller/ballgoal_controller.dart';
import 'package:VarXPro/views/pages/FiledLinesPages/model/ballgoal_model.dart';
import 'package:VarXPro/views/pages/FiledLinesPages/service/ballgoal_service.dart';
import 'package:VarXPro/views/pages/FiledLinesPages/widgets/image_picker_widget.dart';
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
class _BallGoalPageState extends State<BallGoalPage> with TickerProviderStateMixin {
  bool _showSplash = true;
  late final AnimationController _glowController;
  late final Animation<double> _glowScale;
  late final AnimationController _netController;
  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    _glowScale = Tween(begin: 0.98, end: 1.03).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _netController = AnimationController(vsync: this, duration: const Duration(seconds: 18))
      ..repeat();
    // Splash 3s
    Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }
  @override
  void dispose() {
    _glowController.dispose();
    _netController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final modeProvider = Provider.of<ModeProvider>(context);
    final currentLang = langProvider.currentLanguage;
    final mode = modeProvider.currentMode;
    final seedColor = AppColors.seedColors[mode] ?? AppColors.seedColors[1]!;
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    // SPLASH
    if (_showSplash) {
      return Scaffold(
        backgroundColor: AppColors.getBackgroundColor(mode),
        body: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _netController,
                builder: (_, __) => CustomPaint(
                  painter: _NeonNetPainter(mode: mode, t: _netController.value),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.getBodyGradient(mode),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Lottie.asset(
                'assets/lotties/terrain.json',
                width: screenWidth * 0.75,
                height: size.height * 0.42,
                fit: BoxFit.contain,
              ),
            ),
          ],
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
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _netController,
                builder: (_, __) => CustomPaint(
                  painter: _NeonNetPainter(mode: mode, t: _netController.value),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.getBodyGradient(mode),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: BlocConsumer<BallGoalBloc, BallGoalState>(
                listener: (context, state) {
                  if (state.error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${Translations.getBallGoalText('error', currentLang)}: ${state.error}',
                          style: GoogleFonts.manrope(
                            color: AppColors.getTextColor(mode),
                            fontSize: 14,
                          ),
                        ),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                  if (state.ballInOutResponse?.ok == true || state.goalCheckResponse?.ok == true) {
                    final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
                    historyProvider.addHistoryItem('Ball & Goal', 'Ball/Goal analysis completed');
                  }
                },
                builder: (context, state) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.045, vertical: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ======= HERO =======
                        AnimatedScale(
                          scale: _glowScale.value,
                          duration: const Duration(milliseconds: 300),
                          child: _Glass(
                            mode: mode,
                            seedColor: seedColor,
                            borderGlow: true,
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                            child: Row(
                              children: [
                                _NeonDot(seedColor: seedColor, mode: mode),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ShaderMask(
                                        shaderCallback: (rect) => LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            AppColors.getPrimaryColor(seedColor, mode),
                                            AppColors.getTertiaryColor(seedColor, mode),
                                          ],
                                        ).createShader(rect),
                                        child: Text(
                                          '${Translations.getBallGoalText('ballInOut', currentLang)} • ${Translations.getBallGoalText('goalCheck', currentLang)}',
                                          style: GoogleFonts.oxanium(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        Translations.getBallGoalText('selectImageForBallInOut', currentLang),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.manrope(
                                          fontSize: 13.5,
                                          color: AppColors.getTextColor(mode).withOpacity(0.75),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        // ======= Ball In/Out =======
                        _SectionCard(
                          emoji: '⚽',
                          title: Translations.getBallGoalText('ballInOut', currentLang),
                          mode: mode,
                          seedColor: seedColor,
                          glowScale: _glowScale.value,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                        _SectionCard(
                          emoji: '🥅',
                          title: Translations.getBallGoalText('goalCheck', currentLang),
                          mode: mode,
                          seedColor: seedColor,
                          glowScale: _glowScale.value,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
}
/* ===============================
   WIDGETS
================================ */
class _SectionCard extends StatelessWidget {
  final String emoji;
  final String title;
  final int mode;
  final Color seedColor;
  final double glowScale;
  final Widget child;
  const _SectionCard({
    required this.emoji,
    required this.title,
    required this.mode,
    required this.seedColor,
    required this.child,
    this.glowScale = 1.0,
  });
  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: glowScale,
      duration: const Duration(milliseconds: 300),
      child: _Glass(
        mode: mode,
        seedColor: seedColor,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        borderGlow: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _EmojiBadge(emoji: emoji, seed: seedColor, mode: mode),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 18.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.getTextColor(mode),
                      letterSpacing: 0.35,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _NeonDivider(),
            const SizedBox(height: 14),
            child,
          ],
        ),
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
    return _Glass(
      mode: mode,
      seedColor: seedColor,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ResultChip(
            label: Translations.getBallGoalText('success', currentLang),
            value: response.ok ? 'true' : 'false',
            ok: response.ok,
            mode: mode,
            seedColor: seedColor,
          ),
          _ResultLine(
            label: Translations.getBallGoalText('result', currentLang),
            value: response.result,
            okColor: false,
            mode: mode,
            seedColor: seedColor,
          ),
          if (response.confidence != null)
            _ResultLine(
              label: Translations.getBallGoalText('confidence', currentLang),
              value: '${(response.confidence! * 100).toStringAsFixed(2)}%',
              okColor: false,
              mode: mode,
              seedColor: seedColor,
            ),
          if (response.boundaryGuess != null) ...[
            _ResultLine(
              label: Translations.getBallGoalText('boundarySide', currentLang),
              value: response.boundaryGuess!['side'] ?? 'N/A',
              okColor: false,
              mode: mode,
              seedColor: seedColor,
            ),
            _ResultLine(
              label: Translations.getBallGoalText('boundaryType', currentLang),
              value: response.boundaryGuess!['type'] ?? 'N/A',
              okColor: false,
              mode: mode,
              seedColor: seedColor,
            ),
          ],
        ],
      ),
    );
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
    return _Glass(
      mode: mode,
      seedColor: seedColor,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ResultChip(
            label: Translations.getBallGoalText('success', currentLang),
            value: response.ok ? 'true' : 'false',
            ok: response.ok,
            mode: mode,
            seedColor: seedColor,
          ),
          _ResultChip(
            label: Translations.getBallGoalText('isGoal', currentLang),
            value: response.goal ? 'true' : 'false',
            ok: response.goal,
            mode: mode,
            seedColor: seedColor,
          ),
          if (response.confidence != null)
            _ResultLine(
              label: Translations.getBallGoalText('confidence', currentLang),
              value: '${(response.confidence! * 100).toStringAsFixed(2)}%',
              okColor: false,
              mode: mode,
              seedColor: seedColor,
            ),
        ],
      ),
    );
  }
}
class _ResultLine extends StatelessWidget {
  final String label;
  final String value;
  final bool okColor;
  final int mode;
  final Color seedColor;
  const _ResultLine({
    required this.label,
    required this.value,
    required this.okColor,
    required this.mode,
    required this.seedColor,
  });
  @override
  Widget build(BuildContext context) {
    final color = okColor
        ? AppColors.getTertiaryColor(seedColor, mode)
        : AppColors.getTextColor(mode);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: GoogleFonts.manrope(
                color: AppColors.getTextColor(mode).withOpacity(0.8),
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.manrope(
                color: color,
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.15,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }
}
class _ResultChip extends StatelessWidget {
  final String label;
  final String value;
  final bool ok;
  final int mode;
  final Color seedColor;
  const _ResultChip({
    required this.label,
    required this.value,
    required this.ok,
    required this.mode,
    required this.seedColor,
  });
  @override
  Widget build(BuildContext context) {
    final Color bg = ok
        ? AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.12)
        : Colors.redAccent.withOpacity(0.12);
    final Color fg = ok
        ? AppColors.getTertiaryColor(seedColor, mode)
        : Colors.redAccent;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fg.withOpacity(0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ok ? Icons.check_circle_rounded : Icons.error_rounded, size: 18, color: fg),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.manrope(
              color: AppColors.getTextColor(mode).withOpacity(0.85),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.manrope(
              color: fg,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
class _EmojiBadge extends StatelessWidget {
  final String emoji;
  final Color seed;
  final int mode;
  const _EmojiBadge({required this.emoji, required this.seed, required this.mode});
  @override
  Widget build(BuildContext context) {
    final glow = AppColors.getTertiaryColor(seed, mode);
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: glow.withOpacity(0.18),
        boxShadow: [
          BoxShadow(color: glow.withOpacity(0.35), blurRadius: 10, spreadRadius: 1, offset: const Offset(0, 3)),
        ],
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 22)),
    );
  }
}
class _NeonDivider extends StatelessWidget {
  const _NeonDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1.2,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.white24, Colors.transparent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    );
  }
}
class _NeonDot extends StatelessWidget {
  final Color seedColor;
  final int mode;
  const _NeonDot({required this.seedColor, required this.mode});
  @override
  Widget build(BuildContext context) {
    final c = AppColors.getTertiaryColor(seedColor, mode);
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: c.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: c.withOpacity(0.6), blurRadius: 12, spreadRadius: 2),
          BoxShadow(color: c.withOpacity(0.4), blurRadius: 24, spreadRadius: 6),
        ],
      ),
    );
  }
}
/// Glassmorphism container SAFE inside scroll views (no SizedBox.expand).
class _Glass extends StatelessWidget {
  final Widget child;
  final int mode;
  final Color seedColor;
  final EdgeInsetsGeometry padding;
  final bool borderGlow;
  const _Glass({
    required this.child,
    required this.mode,
    required this.seedColor,
    this.padding = const EdgeInsets.all(16),
    this.borderGlow = false,
  });
  @override
  Widget build(BuildContext context) {
    final surface = AppColors.getSurfaceColor(mode);
    // Outer container for optional glow shadow
    return Container(
      decoration: borderGlow
          ? BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.20),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            // Important: finite size in scroll contexts
            width: double.infinity,
            decoration: BoxDecoration(
              color: surface.withOpacity(0.70),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.getPrimaryColor(seedColor, mode).withOpacity(0.22),
                width: 1,
              ),
            ),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
/* ===============================
   BACKGROUND PAINTER (animated net)
================================ */
class _NeonNetPainter extends CustomPainter {
  final int mode;
  final double t; // [0..1] animated
  _NeonNetPainter({required this.mode, required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final baseColor = AppColors.getTextColor(mode);
    const cols = 10;
    const rows = 12;
    final dx = size.width / (cols + 1);
    final dy = size.height / (rows + 1);
    final nodes = <Offset>[];
    for (int r = 1; r <= rows; r++) {
      for (int c = 1; c <= cols; c++) {
        final i = r * cols + c;
        final wobbleX = sin((t * 2 * pi) + i * 0.73) * 6.0;
        final wobbleY = cos((t * 2 * pi) + i * 1.11) * 6.0;
        nodes.add(Offset(c * dx + wobbleX, r * dy + wobbleY));
      }
    }
    final linePaint = Paint()
      ..color = baseColor.withOpacity(0.06)
      ..strokeWidth = 1.0;
    const linkRadius = 120.0;
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final d = (nodes[i] - nodes[j]).distance;
        if (d < linkRadius) {
          final o = 1.0 - (d / linkRadius);
          linePaint.color = baseColor.withOpacity(0.06 + o * 0.07);
          canvas.drawLine(nodes[i], nodes[j], linePaint);
        }
      }
    }
    final dotPaint = Paint()..color = baseColor.withOpacity(0.11);
    for (final p in nodes) {
      canvas.drawCircle(p, 1.6, dotPaint);
    }
  }
  @override
  bool shouldRepaint(covariant _NeonNetPainter oldDelegate) => oldDelegate.t != t || oldDelegate.mode != mode;
}