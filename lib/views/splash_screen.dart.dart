// splash_screen.dart - Do not change as per instructions
import 'dart:math';
import 'package:VarXPro/views/home.dart';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _scanCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _particleCtrl;

  @override
  void initState() {
    super.initState();

    // Animation du scan AI
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: false);

    // Animation de pulsation du logo
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
      lowerBound: 0.6,
      upperBound: 1.0,
    )..repeat(reverse: true);

    // Animation des particules flottantes
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Transition automatique vers Home
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 1000),
          pageBuilder: (_, __, ___) => const HomePage(),
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: anim,
                curve: Curves.easeInOutQuart,
              ),
              child: child,
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _glowCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgTop = const Color(0xFF071628);
    final bgBottom = const Color(0xFF0D2B59);

    return Scaffold(
      backgroundColor: bgTop,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _FootballGridPainter(),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [bgTop, bgBottom],
                    stops: const [0.3, 0.9],
                  ),
                ),
              ),
            ),
          ),

          // Particules flottantes animées
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (context, _) {
              return CustomPaint(
                painter: _FloatingParticlesPainter(
                  time: _particleCtrl.value * 2 * pi,
                ),
              );
            },
          ),

          // Ligne de scan AI animée
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _scanCtrl,
              builder: (context, _) {
                final t = _scanCtrl.value;
                return CustomPaint(
                  painter: _ScanLinePainter(progress: t),
                );
              },
            ),
          ),

          // Contenu principal centré
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo avec effet de glow et anneaux radar
                ScaleTransition(
                  scale: _glowCtrl,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      gradient: const RadialGradient(
                        center: Alignment(-0.2, -0.2),
                        radius: 0.9,
                        colors: [
                          Color(0xFF0D2B59),
                          Color(0xFF0C3D6E),
                          Color(0xFF12A87E),
                        ],
                        stops: [0.1, 0.5, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF11FFB2).withOpacity(0.4),
                          blurRadius: 32,
                          spreadRadius: 6,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 2.5,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Anneaux radar animés
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _RadarRingsPainter(
                              time: _particleCtrl.value * 2 * pi,
                            ),
                          ),
                        ),
                        // Logo central
                        Center(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Image.asset(
                                'assets/logo.jpg',
                                height: 130,
                                width: 130,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFF11FFB2),
                      Color(0xFF4DC9FF),
                      Color(0xFF11FFB2),
                    ],
                    stops: [0.0, 0.5, 1.0],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ).createShader(bounds),
                  child: const Text(
                    'VAR X PRO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3.0,
                      fontFamily: 'Poppins',
                      height: 1.1,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Opacity(
                  opacity: 0.9,
                  child: Text(
                    'AI-Powered Football Video Analytics',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 15,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w300,
                      shadows: [
                        BoxShadow(
                          color: const Color(0xFF11FFB2).withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Texte animé des fonctionnalités
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.85,
                  child: AnimatedTextKit(
                    animatedTexts: [
                      TyperAnimatedText(
                        'Player Tracking • Goal Analysis • Foul Detection • Offside • Referee Tracking • Key Field Lines',
                        textStyle: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                        speed: const Duration(milliseconds: 30),
                      ),
                    ],
                    totalRepeatCount: 1,
                    pause: const Duration(milliseconds: 800),
                    displayFullTextOnTap: true,
                    stopPauseOnTap: true,
                  ),
                ),
                const SizedBox(height: 32),

                // Indicateur de progression avec effet de pulsation
                AnimatedBuilder(
                  animation: _glowCtrl,
                  builder: (context, _) {
                    return Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF11FFB2)
                                .withOpacity(_glowCtrl.value * 0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircularProgressIndicator(
                        strokeWidth: 3.5,
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF11FFB2),
                        ),
                        backgroundColor: Colors.white.withOpacity(0.1),
                        value: _scanCtrl.value,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.sports_soccer,
                      size: 18,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    const SizedBox(width: 8),
                    AnimatedTextKit(
                      animatedTexts: [
                        FadeAnimatedText(
                          'Loading AI models...',
                          textStyle: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13.5,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w300,
                          ),
                          duration: const Duration(milliseconds: 1500),
                        ),
                        FadeAnimatedText(
                          'Processing algorithms...',
                          textStyle: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13.5,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w300,
                          ),
                          duration: const Duration(milliseconds: 1500),
                        ),
                        FadeAnimatedText(
                          'Initializing video analysis...',
                          textStyle: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13.5,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w300,
                          ),
                          duration: const Duration(milliseconds: 1500),
                        ),
                      ],
                      totalRepeatCount: 2,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FootballGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pitch = Paint()
      ..color = const Color(0xFF0EF3A6).withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final glow = Paint()
      ..color = const Color(0xFF11FFB2).withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final inset = 28.0;
    final rect = Rect.fromLTWH(
        inset, inset, size.width - inset * 2, size.height - inset * 2);
    canvas.drawRect(rect, pitch);
    canvas.drawRect(rect, glow);

    final midY = rect.centerLeft.dy;
    canvas.drawLine(Offset(rect.left, midY), Offset(rect.right, midY), pitch);
    canvas.drawCircle(rect.center, min(rect.width, rect.height) * 0.12, pitch);

    void penaltyBoxes() {
      final boxW = rect.width * 0.18;
      final boxH = rect.height * 0.24;
      final leftBox = Rect.fromLTWH(
          rect.left, rect.top + (rect.height - boxH) / 2, boxW, boxH);
      final rightBox = Rect.fromLTWH(
          rect.right - boxW, rect.top + (rect.height - boxH) / 2, boxW, boxH);
      canvas.drawRect(leftBox, pitch);
      canvas.drawRect(rightBox, pitch);

      final leftPenaltySpot = Offset(rect.left + boxW * 0.7, rect.center.dy);
      final rightPenaltySpot = Offset(rect.right - boxW * 0.7, rect.center.dy);
      canvas.drawCircle(leftPenaltySpot, 3, pitch);
      canvas.drawCircle(rightPenaltySpot, 3, pitch);
    }

    penaltyBoxes();

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 0.8;

    const step = 40.0;
    for (double x = rect.left; x <= rect.right; x += step) {
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), gridPaint);
    }
    for (double y = rect.top; y <= rect.bottom; y += step) {
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), gridPaint);
    }

    final arcPaint = Paint()
      ..color = const Color(0xFF11FFB2).withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawArc(
      Rect.fromCircle(center: rect.center, radius: min(rect.width, rect.height) * 0.3),
      -pi / 4,
      pi / 2,
      false,
      arcPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: rect.center, radius: min(rect.width, rect.height) * 0.3),
      pi - pi / 4,
      pi / 2,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScanLinePainter extends CustomPainter {
  final double progress;
  _ScanLinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    final line = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF11FFB2).withOpacity(0.35),
          const Color(0xFF4DC9FF).withOpacity(0.25),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 0.6, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, y - 100, size.width, 200));

    canvas.drawRect(Rect.fromLTWH(0, y - 100, size.width, 200), line);

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF11FFB2).withOpacity(0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, y),
        radius: size.width * 0.3,
      ));

    canvas.drawCircle(Offset(size.width / 2, y), size.width * 0.3, glow);
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _RadarRingsPainter extends CustomPainter {
  final double time;
  _RadarRingsPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = min(size.width, size.height) * 0.5;

    for (int i = 1; i <= 3; i++) {
      final r = maxR * (i / 3);
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Color.lerp(
          const Color(0xFF11FFB2).withOpacity(0.25),
          const Color(0xFF4DC9FF).withOpacity(0.1),
          i / 3,
        )!;

      canvas.drawCircle(center, r, ring);
    }

    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF11FFB2).withOpacity(0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.1, 1.0],
        startAngle: 0,
        endAngle: pi * 2,
        transform: GradientRotation(time),
      ).createShader(Rect.fromCircle(center: center, radius: maxR));

    canvas.drawCircle(center, maxR, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarRingsPainter oldDelegate) =>
      oldDelegate.time != time;
}

/// Peintre pour les particules flottantes
class _FloatingParticlesPainter extends CustomPainter {
  final double time;
  _FloatingParticlesPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42); // Seed fixe pour un motif cohérent
    final particleCount = 25;

    for (int i = 0; i < particleCount; i++) {
      final x = size.width * rng.nextDouble();
      final y = size.height * rng.nextDouble();
      final sizeFactor = 0.5 + rng.nextDouble() * 1.5;
      final opacity = 0.2 + rng.nextDouble() * 0.3;
      final drift = sin(time + i * 0.5) * 5;

      final particle = Paint()
        ..color = const Color(0xFF11FFB2).withOpacity(opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(
        Offset(x + drift, y + drift),
        1.5 * sizeFactor,
        particle,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingParticlesPainter oldDelegate) =>
      oldDelegate.time != time;
}