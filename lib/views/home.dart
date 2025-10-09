import 'dart:math';
import 'package:VarXPro/views/connexion/providers/auth_provider.dart';
import 'package:VarXPro/views/nav_bar.dart';
import 'package:VarXPro/views/splash_screen.dart.dart';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final AnimationController _scanCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _particleCtrl;
  late final AnimationController _titleShimmerCtrl;

  // Parallax (desktop/web) — doux
  Offset _pointer = Offset.zero;

  @override
  void initState() {
    super.initState();

    _scanCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
      lowerBound: 0.6,
      upperBound: 1.0,
    )..repeat(reverse: true);
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();

    _titleShimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    // Transition auto vers Home / Splash
    Future.delayed(const Duration(seconds: 5), () async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.checkAuthStatus();

      final target = authProvider.isAuthenticated ? const NavPage() : const SplashScreen();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 900),
          pageBuilder: (_, __, ___) => target,
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOutQuart),
            child: child,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _glowCtrl.dispose();
    _particleCtrl.dispose();
    _titleShimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgTop = Color(0xFF071628);
    const bgBottom = Color(0xFF0D2B59);

    return Scaffold(
      backgroundColor: bgTop,
      body: Listener(
        onPointerHover: (e) => setState(() => _pointer = e.localPosition),
        onPointerMove: (e) => setState(() => _pointer = e.localPosition),
        child: Stack(
          children: [
            // Grille / pitch + dégradé
            Positioned.fill(
              child: CustomPaint(
                painter: _FootballGridPainter(),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [bgTop, bgBottom],
                      stops: [0.3, 0.9],
                    ),
                  ),
                ),
              ),
            ),

            // Particules flottantes
            AnimatedBuilder(
              animation: _particleCtrl,
              builder: (context, _) => CustomPaint(
                painter: _FloatingParticlesPainter(time: _particleCtrl.value * 2 * pi),
              ),
            ),

            // Ligne de scan AI
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _scanCtrl,
                builder: (context, _) => CustomPaint(painter: _ScanLinePainter(progress: _scanCtrl.value)),
              ),
            ),

            // Halo radial large (ajoute de la profondeur)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.15),
                      radius: 1.2,
                      colors: [
                        const Color(0xFF11FFB2).withOpacity(0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Contenu
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Carte logo néon avec parallax doux
                      _Parallax(
                        pointer: _pointer,
                        strength: 12,
                        child: ScaleTransition(
                          scale: _glowCtrl,
                          child: _NeonCard(
                            child: Stack(
                              children: [
                                // Anneaux radar
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _RadarRingsPainter(time: _particleCtrl.value * 2 * pi),
                                  ),
                                ),
                                // Logo
                                Center(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.28),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
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
                      ),
                      const SizedBox(height: 28),

                      // Titre avec shimmer animé (neon sweep)
                      _AnimatedGradientTitle(controller: _titleShimmerCtrl, text: 'VAR X PRO'),
                      const SizedBox(height: 10),

                      // Sous-titre
                      Opacity(
                        opacity: 0.95,
                        child: Text(
                          'AI-Powered Football Video Analytics',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.92),
                            fontSize: 16,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w400,
                            height: 1.25,
                            shadows: [
                              BoxShadow(
                                color: const Color(0xFF11FFB2).withOpacity(0.25),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Feature line (typer)
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.9,
                        child: AnimatedTextKit(
                          animatedTexts: [
                            TyperAnimatedText(
                              'Player Tracking • Goal Analysis • Foul Detection • Offside • Referee Tracking • Key Field Lines',
                              textStyle: TextStyle(
                                fontSize: 15.5,
                                color: Colors.white.withOpacity(0.9),
                                height: 1.55,
                                fontWeight: FontWeight.w400,
                              ),
                              speed: const Duration(milliseconds: 22),
                            ),
                          ],
                          totalRepeatCount: 1,
                          pause: const Duration(milliseconds: 700),
                          displayFullTextOnTap: true,
                          stopPauseOnTap: true,
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Chips features (esthétique + info)
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: const [
                          _FeatureChip(icon: Icons.sports_soccer, label: 'Computer Vision'),
                          _FeatureChip(icon: Icons.timeline, label: 'Object Tracking'),
                          _FeatureChip(icon: Icons.grid_4x4, label: 'Field Geometry'),
                          _FeatureChip(icon: Icons.shield, label: 'Referee Assist'),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Progress + texte animé
                      AnimatedBuilder(
                        animation: _glowCtrl,
                        builder: (context, _) {
                          return Column(
                            children: [
                              // Cercle progress glow
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF11FFB2).withOpacity(0.35 * _glowCtrl.value),
                                      blurRadius: 18,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                child: CircularProgressIndicator(
                                  strokeWidth: 3.5,
                                  valueColor: const AlwaysStoppedAnimation(Color(0xFF11FFB2)),
                                  backgroundColor: Colors.white.withOpacity(0.12),
                                  value: _scanCtrl.value,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.auto_awesome, size: 16, color: Colors.white.withOpacity(0.8)),
                                  const SizedBox(width: 8),
                                  AnimatedTextKit(
                                    animatedTexts: [
                                      FadeAnimatedText(
                                        'Loading AI models...',
                                        textStyle: _loadingStyle,
                                        duration: const Duration(milliseconds: 1200),
                                      ),
                                      FadeAnimatedText(
                                        'Processing algorithms...',
                                        textStyle: _loadingStyle,
                                        duration: const Duration(milliseconds: 1200),
                                      ),
                                      FadeAnimatedText(
                                        'Initializing video analysis...',
                                        textStyle: _loadingStyle,
                                        duration: const Duration(milliseconds: 1200),
                                      ),
                                    ],
                                    totalRepeatCount: 2,
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// === Styles / Widgets ===

const TextStyle _loadingStyle = TextStyle(
  color: Colors.white70,
  fontSize: 13.5,
  letterSpacing: 0.4,
  fontWeight: FontWeight.w300,
);

class _NeonCard extends StatelessWidget {
  final Widget child;
  const _NeonCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const RadialGradient(
          center: Alignment(-0.2, -0.2),
          radius: 0.95,
          colors: [Color(0xFF0D2B59), Color(0xFF0C3D6E), Color(0xFF12A87E)],
          stops: [0.08, 0.55, 1.0],
        ),
        border: Border.all(color: Colors.white10, width: 2),
        boxShadow: [
          BoxShadow(color: const Color(0xFF11FFB2).withOpacity(0.45), blurRadius: 36, spreadRadius: 8),
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(32), child: child),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withOpacity(0.06), Colors.white.withOpacity(0.02)],
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF11FFB2).withOpacity(0.18), blurRadius: 14, spreadRadius: 1),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFBFFFEF)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFDAFFFA),
              fontSize: 12.5,
              letterSpacing: 0.3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedGradientTitle extends StatelessWidget {
  final AnimationController controller;
  final String text;
  const _AnimatedGradientTitle({required this.controller, required this.text});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 + t * 2.0, 0),
              end: Alignment(1.0 + t * 2.0, 0),
              colors: const [Color(0xFF11FFB2), Color(0xFF4DC9FF), Color(0xFF11FFB2)],
              stops: const [0.25, 0.5, 0.75],
            ).createShader(bounds);
          },
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w900,
              letterSpacing: 3.2,
              fontFamily: 'Poppins',
              height: 1.06,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

class _Parallax extends StatelessWidget {
  final Widget child;
  final Offset pointer;
  final double strength;
  const _Parallax({required this.child, required this.pointer, this.strength = 10});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Normalise le pointer (si 0, on reste centré)
    final dx = (pointer.dx == 0 && pointer.dy == 0) ? 0.0 : ((pointer.dx / size.width) - 0.5);
    final dy = (pointer.dx == 0 && pointer.dy == 0) ? 0.0 : ((pointer.dy / size.height) - 0.5);

    return Transform.translate(
      offset: Offset(dx * strength, dy * strength),
      child: child,
    );
  }
}

// === Painters d'arrière-plan (inchangés, avec petits raffinements) ===

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

    const inset = 28.0;
    final rect = Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2);
    canvas.drawRect(rect, pitch);
    canvas.drawRect(rect, glow);

    final midY = rect.centerLeft.dy;
    canvas.drawLine(Offset(rect.left, midY), Offset(rect.right, midY), pitch);
    canvas.drawCircle(rect.center, min(rect.width, rect.height) * 0.12, pitch);

    void penaltyBoxes() {
      final boxW = rect.width * 0.18;
      final boxH = rect.height * 0.24;
      final leftBox = Rect.fromLTWH(rect.left, rect.top + (rect.height - boxH) / 2, boxW, boxH);
      final rightBox = Rect.fromLTWH(rect.right - boxW, rect.top + (rect.height - boxH) / 2, boxW, boxH);
      canvas.drawRect(leftBox, pitch);
      canvas.drawRect(rightBox, pitch);
      final leftPenaltySpot = Offset(rect.left + boxW * 0.7, rect.center.dy);
      final rightPenaltySpot = Offset(rect.right - boxW * 0.7, rect.center.dy);
      canvas.drawCircle(leftPenaltySpot, 3, pitch);
      canvas.drawCircle(rightPenaltySpot, 3, pitch);
    }

    penaltyBoxes();

    final gridPaint = Paint()..color = Colors.white.withOpacity(0.06)..strokeWidth = 0.8;
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
        colors: [const Color(0xFF11FFB2).withOpacity(0.15), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(size.width / 2, y), radius: size.width * 0.3));

    canvas.drawCircle(Offset(size.width / 2, y), size.width * 0.3, glow);
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter oldDelegate) => oldDelegate.progress != progress;
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
        colors: [Colors.transparent, const Color(0xFF11FFB2).withOpacity(0.4), Colors.transparent],
        stops: const [0.0, 0.1, 1.0],
        startAngle: 0,
        endAngle: pi * 2,
        transform: GradientRotation(time),
      ).createShader(Rect.fromCircle(center: center, radius: maxR));

    canvas.drawCircle(center, maxR, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarRingsPainter oldDelegate) => oldDelegate.time != time;
}

class _FloatingParticlesPainter extends CustomPainter {
  final double time;
  _FloatingParticlesPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    const particleCount = 28;

    for (int i = 0; i < particleCount; i++) {
      final x = size.width * rng.nextDouble();
      final y = size.height * rng.nextDouble();
      final sizeFactor = 0.55 + rng.nextDouble() * 1.6;
      final opacity = 0.2 + rng.nextDouble() * 0.3;
      final drift = sin(time + i * 0.5) * 5;

      final particle = Paint()
        ..color = const Color(0xFF11FFB2).withOpacity(opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(Offset(x + drift, y + drift), 1.5 * sizeFactor, particle);
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingParticlesPainter oldDelegate) => oldDelegate.time != time;
}
