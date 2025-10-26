// lib/views/connexion/view/splash_screen.dart
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:VarXPro/views/connexion/view/login_page.dart';
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/provider/modeprovider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _meshCtrl;
  late final AnimationController _ballCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  final PageController _carousel = PageController(viewportFraction: 0.78);
  double _currentPage = 0.0;

  final List<Map<String, dynamic>> _modes = const [
    {"name": "Classic Mode", "emoji": "⚽", "color": Colors.blue},
    {"name": "Light Mode", "emoji": "☀️", "color": Colors.amber},
    {"name": "Pro Analysis Mode", "emoji": "📊", "color": Colors.green},
    {"name": "VAR Vision Mode", "emoji": "📹", "color": Colors.purple},
    {"name": "Referee Mode", "emoji": "👨‍⚖️", "color": Colors.red},
  ];

  @override
  void initState() {
    super.initState();
    _meshCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    _ballCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);

    _currentPage = _carousel.initialPage.toDouble();
    _carousel.addListener(
      () => setState(() => _currentPage = _carousel.page ?? 0.0),
    );
  }

  @override
  void dispose() {
    _meshCtrl.dispose();
    _ballCtrl.dispose();
    _fadeCtrl.dispose();
    _carousel.dispose();
    super.dispose();
  }

  TextDirection _dir(String? lang) =>
      (lang == 'ar') ? TextDirection.rtl : TextDirection.ltr;

  /* ===================== CONTENU ===================== */

  List<Map<String, dynamic>> _features(String? lang) {
    String t(String k, String fb) => Translations.getHomeText(k, lang!) ?? fb;
    return [
      {
        'id': 'referees',
        'emoji': '👨‍⚖️',
        'title': t('refereesTitle', 'Referees — World DB'),
        'desc': t(
          'refereesDesc',
          'Complete profiles, stats, decision histories.',
        ),
        'color': Colors.purple,
      },
      {
        'id': 'eval',
        'emoji': '🤖',
        'title': t('matchEvalTitle', 'Match Evaluation (AI / Manual)'),
        'desc': t(
          'matchEvalDesc',
          'AI automatic scoring or pro manual review.',
        ),
        'color': Colors.teal,
      },
      {
        'id': 'ball',
        'emoji': '🟢',
        'title': t('ballTrackingTitle', 'Ball Tracking — In/Out/Goal'),
        'desc': t(
          'ballTrackingDesc',
          'Real-time ball position and goal detection.',
        ),
        'color': Colors.green,
      },
      {
        'id': 'fouls',
        'emoji': '⚠️',
        'title': t('foulsTitle', 'Foul Detection'),
        'desc': t(
          'foulsDesc',
          'Computer vision: contacts, charges, dangerous tackles.',
        ),
        'color': Colors.orange,
      },
      {
        'id': 'offside',
        'emoji': '🚩',
        'title': t('offsideTitle', 'VAR — Offside Analysis'),
        'desc': t(
          'offsideDesc',
          'Multi-angle reconstruction, top-view/perspective.',
        ),
        'color': Colors.red,
      },
      {
        'id': 'iptv',
        'emoji': '📺',
        'title': t('iptvTitle', 'IPTV — Global Channels'),
        'desc': t('iptvDesc', 'Live sports selection from around the world.'),
        'color': Colors.blue,
      },
    ];
  }

  void _goToLoginWithHint(BuildContext ctx, String featureTitle, Color accent) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text('Log in to access "$featureTitle"'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: accent,
      ),
    );
    Navigator.of(ctx).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginPage(),
        transitionsBuilder: (_, a, __, c) =>
            FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 550),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().currentLanguage;
    final mode = context.watch<ModeProvider>().currentMode;

    final Color accent = AppColors.getPrimaryColor(
      AppColors.seedColors[mode] ?? AppColors.seedColors[1]!,
      mode,
    );
    final Color bg = AppColors.getSurfaceColor(mode);
    final Color text = AppColors.getTextColor(mode);
    final fts = _features(lang);

    String t(String k, String fb) => Translations.getHomeText(k, lang) ?? fb;

    return Directionality(
      textDirection: _dir(lang),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: Scaffold(
          backgroundColor: bg,
          body: Stack(
            children: [
              // BACKGROUND: mesh néon animé + léger blur
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _meshCtrl,
                  builder: (_, __) => _NeonMeshBackground(
                    progress: _meshCtrl.value,
                    accent: accent,
                  ),
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(color: Colors.black.withOpacity(0.06)),
                ),
              ),

              SafeArea(
                child: FadeTransition(
                  opacity: _fade,
                  child: Column(
                    children: [
                      /* ======= HEADER ======= */
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  _LogoOrb(accent: accent),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AnimatedBuilder(
                                          animation: _meshCtrl,
                                          builder: (_, __) =>
                                              _AnimatedGradientText(
                                                t('appName', 'VAR X PRO'),
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 0.8,
                                                ),
                                                accent: accent,
                                                progress: _meshCtrl.value,
                                              ),
                                        ),
                                        Text(
                                          t(
                                            'tagline',
                                            'AI Football Analysis Suite',
                                          ),
                                          style: TextStyle(
                                            color: text.withOpacity(0.72),
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                _RoundAction(
                                  emoji: '🌐',
                                  color: accent,
                                  onTap: () =>
                                      _showLanguageSheet(context, accent),
                                ),
                                const SizedBox(width: 10),
                                _RoundAction(
                                  emoji: '✨',
                                  color: accent,
                                  onTap: () => _showModeSheet(context, accent),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      /* ======= HOLOBALL + TAGLINE ======= */
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
                        child: _Glass(
                          radius: 26,
                          neon: true,
                          accent: accent,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 150,
                                  child: AnimatedBuilder(
                                    animation: _ballCtrl,
                                    builder: (_, __) => _HoloBall(
                                      t: _ballCtrl.value,
                                      accent: accent,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  t(
                                    'subtitle',
                                    'All your match analyses in one place: Referees, AI/Manual Evaluation, Ball In/Out/Goal, Fouls, VAR Offside, IPTV.',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: text.withOpacity(0.95),
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      /* ======= TRUST RIBBON ======= */
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                        child: _Glass(
                          radius: 20,
                          neon: true,
                          accent: accent,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                _TrustItem(
                                  icon: Icons.insights_rounded,
                                  label: t('aiPrecisionTitle', 'Precise AI'),
                                  value: '96.7%',
                                  accent: accent,
                                ),
                                _DividerV(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                                _TrustItem(
                                  icon: Icons.speed_rounded,
                                  label: t('lowLatency', 'Latency'),
                                  value: '≈120ms',
                                  accent: accent,
                                ),
                                _DividerV(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                                _TrustItem(
                                  icon: Icons.shield_outlined,
                                  label: t('privacyFirst', 'Privacy'),
                                  value: t('privacyValue', 'On-device / Cloud'),
                                  accent: accent,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      /* ======= CAROUSEL ======= */
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 206,
                        child: PageView.builder(
                          controller: _carousel,
                          itemCount: fts.length,
                          padEnds: false,
                          itemBuilder: (ctx, i) {
                            final f = fts[i];
                            final delta = (_currentPage - i).abs().clamp(
                              0.0,
                              1.0,
                            );
                            final scale = 1.0 - (delta * 0.08);
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Transform.scale(
                                scale: scale,
                                alignment: Alignment.center,
                                child: _Tilt(
                                  child: _ServiceCardNoDemo(
                                    emoji: f['emoji'],
                                    title: f['title'],
                                    desc: f['desc'],
                                    chipColor: f['color'],
                                    accent: accent,
                                    onAccess: () => _goToLoginWithHint(
                                      ctx,
                                      f['title'],
                                      accent,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      _DotsIndicator(
                        count: fts.length,
                        index: _currentPage,
                        activeColor: accent,
                      ),

                      const Spacer(),

                      /* ======= CTA ======= */
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: _GlowingButton(
                                label:
                                    Translations.getHomeText(
                                      'enterApp',
                                      lang,
                                    ) ??
                                    'ENTER APPLICATION',
                                icon: Icons.login_rounded,
                                color: accent,
                                onPressed: () =>
                                    Navigator.of(context).pushReplacement(
                                      PageRouteBuilder(
                                        pageBuilder: (_, __, ___) =>
                                            const LoginPage(),
                                        transitionsBuilder: (_, a, __, c) =>
                                            FadeTransition(
                                              opacity: a,
                                              child: c,
                                            ),
                                        transitionDuration: const Duration(
                                          milliseconds: 650,
                                        ),
                                      ),
                                    ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Opacity(
                              opacity: 0.75,
                              child: Text(
                                '© ${DateTime.now().year} VAR X PRO',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /* ======= SHEETS (lang & mode) ======= */
  void _showLanguageSheet(BuildContext context, Color accent) {
    final langP = context.read<LanguageProvider>();
    final langs =
        Translations.getLanguages(langP.currentLanguage) ??
        ['English', 'Français', 'العربية'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _Glass(
        radius: 24,
        neon: true,
        accent: accent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.language, color: accent),
              const SizedBox(height: 8),
              ...langs.asMap().entries.map((e) {
                final idx = e.key;
                final name = e.value;
                final code = idx == 0
                    ? 'en'
                    : idx == 1
                    ? 'fr'
                    : 'ar';
                final flag = idx == 0
                    ? '🇺🇸'
                    : idx == 1
                    ? '🇫🇷'
                    : '🇹🇳';
                final selected = langP.currentLanguage == code;
                return ListTile(
                  leading: Text(flag, style: const TextStyle(fontSize: 20)),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: selected
                      ? Icon(Icons.check_circle, color: accent)
                      : null,
                  onTap: () {
                    langP.changeLanguage(code);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Language: $name'),
                        backgroundColor: accent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showModeSheet(BuildContext context, Color accent) {
    final modeP = context.read<ModeProvider>();
    final modes =
        Translations.getModes(
          context.read<LanguageProvider>().currentLanguage,
        ) ??
        [
          'Classic Mode',
          'Light Mode',
          'Pro Analysis Mode',
          'VAR Vision Mode',
          'Referee Mode',
        ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _Glass(
        radius: 24,
        neon: true,
        accent: accent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, color: accent),
              const SizedBox(height: 8),
              ...modes.asMap().entries.map((e) {
                final idx = e.key;
                final name = e.value;
                final m = _modes[idx];
                final active = (modeP.currentMode == idx + 1);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: (m['color'] as Color).withOpacity(0.18),
                    child: Text(m['emoji']),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: active
                      ? Icon(Icons.check_circle, color: m['color'])
                      : null,
                  onTap: () {
                    modeP.changeMode(idx + 1);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$name activated'),
                        backgroundColor: accent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/* ===================== WIDGETS UI ===================== */

class _LogoOrb extends StatelessWidget {
  final Color accent;
  const _LogoOrb({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [accent.withOpacity(0.45), accent.withOpacity(0.1)],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.35),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(child: Image.asset('assets/logo.jpg', fit: BoxFit.cover)),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final String emoji;
  final Color color;
  final VoidCallback onTap;
  const _RoundAction({
    required this.emoji,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [color.withOpacity(0.16), color.withOpacity(0.06)],
          ),
          border: Border.all(color: color.withOpacity(0.3), width: 1.3),
        ),
        child: Text(emoji, style: TextStyle(fontSize: 20, color: color)),
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  final Widget child;
  final double radius;
  final bool neon;
  final Color? accent;
  const _Glass({
    required this.child,
    this.radius = 18,
    this.neon = false,
    this.accent,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    final panel = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: child,
        ),
      ),
    );

    if (!neon || accent == null) return panel;

    // Bordure néon dégradée (fine)
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius + 1),
        gradient: LinearGradient(
          colors: [accent!, Colors.white.withOpacity(0.6), accent!],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Padding(padding: const EdgeInsets.all(1.2), child: panel),
    );
  }
}

class _AnimatedGradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Color accent;
  final double progress; // 0..1
  const _AnimatedGradientText(
    this.text, {
    required this.style,
    required this.accent,
    required this.progress,
  });
  @override
  Widget build(BuildContext context) {
    final grad = LinearGradient(
      colors: [accent, Colors.white, accent],
      stops: const [0.0, 0.5, 1.0],
      transform: GradientRotation(progress * 2 * math.pi),
    );
    return ShaderMask(
      shaderCallback: (Rect bounds) => grad.createShader(bounds),
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}

class _NeonMeshBackground extends StatelessWidget {
  final double progress; // 0..1
  final Color accent;
  const _NeonMeshBackground({required this.progress, required this.accent});
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _MeshPainter(progress: progress, accent: accent),
  );
}

class _MeshPainter extends CustomPainter {
  final double progress;
  final Color accent;
  _MeshPainter({required this.progress, required this.accent});

  final int _count = 42;

  @override
  void paint(Canvas canvas, Size size) {
    final points = <Offset>[];
    final rnd = math.Random(7);

    for (int i = 0; i < _count; i++) {
      final base = Offset(
        rnd.nextDouble() * size.width,
        rnd.nextDouble() * size.height,
      );
      final speed = 0.6 + rnd.nextDouble() * 1.2;
      final phase = rnd.nextDouble() * math.pi * 2;
      final dx =
          base.dx + math.sin(progress * 2 * math.pi * speed + phase) * 18;
      final dy =
          base.dy + math.cos(progress * 2 * math.pi * speed + phase) * 14;
      points.add(Offset(dx, dy));
    }

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = accent.withOpacity(0.10);
    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = accent.withOpacity(0.12);

    const th = 120.0;
    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        final d = (points[i] - points[j]).distance;
        if (d < th) {
          final op = (1 - (d / th)) * 0.25;
          linePaint..color = accent.withOpacity(op);
          canvas.drawLine(points[i], points[j], linePaint);
        }
      }
    }
    for (final p in points) {
      canvas.drawCircle(p, 1.6, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MeshPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.accent != accent;
}

class _HoloBall extends StatelessWidget {
  final double t; // 0..1
  final Color accent;
  const _HoloBall({required this.t, required this.accent});
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _HoloBallPainter(t: t, accent: accent),
    child: const SizedBox.expand(),
  );
}

class _HoloBallPainter extends CustomPainter {
  final double t;
  final Color accent;
  _HoloBallPainter({required this.t, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) * 0.36;

    // Halo externe
    final halo = Paint()
      ..shader = RadialGradient(
        colors: [accent.withOpacity(0.34), Colors.transparent],
      ).createShader(Rect.fromCircle(center: c, radius: r * 1.45));
    canvas.drawCircle(c, r * 1.45, halo);

    // Cercle principal
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = Colors.white.withOpacity(0.70);
    canvas.drawCircle(c, r, ring);

    // Points latitude/longitude
    final dot = Paint()..color = accent.withOpacity(0.95);
    final rot = t * 2 * math.pi;

    for (int lat = -60; lat <= 60; lat += 20) {
      final phi = lat * math.pi / 180;
      final rr = r * math.cos(phi);
      for (int i = 0; i < 36; i++) {
        final theta = (i / 36) * 2 * math.pi + rot;
        final x = c.dx + rr * math.cos(theta);
        final y = c.dy + r * math.sin(phi) * 0.9;
        canvas.drawCircle(Offset(x, y), 1.5, dot);
      }
    }

    // Arc lumineux rotatif
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = accent;
    final start = rot;
    final sweep = math.pi / 3;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 1.02),
      start,
      sweep,
      false,
      arc,
    );

    // Scanline
    final scanY = (math.sin(rot) * 0.5 + 0.5) * r * 1.8;
    final scanPaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.transparent,
              Colors.white.withOpacity(0.25),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromLTWH(c.dx - r * 1.2, c.dy - r + scanY, r * 2.4, 3),
          );
    canvas.drawRect(
      Rect.fromLTWH(c.dx - r * 1.2, c.dy - r + scanY, r * 2.4, 3),
      scanPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HoloBallPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.accent != accent;
}

class _TrustItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  const _TrustItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
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

class _DividerV extends StatelessWidget {
  final Color color;
  const _DividerV({required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 24,
    margin: const EdgeInsets.symmetric(horizontal: 10),
    color: color,
  );
}

/* ===== Tilt effect (subtil) ===== */
class _Tilt extends StatefulWidget {
  final Widget child;
  const _Tilt({required this.child, super.key});
  @override
  State<_Tilt> createState() => _TiltState();
}

class _TiltState extends State<_Tilt> {
  double _dx = 0, _dy = 0;
  void _onPointerMove(PointerEvent e, Size size) {
    final local = e.localPosition;
    final nx = (local.dx / size.width) * 2 - 1;
    final ny = (local.dy / size.height) * 2 - 1;
    setState(() {
      _dx = nx * 6;
      _dy = ny * -6;
    });
  }

  void _reset() => setState(() {
    _dx = 0;
    _dy = 0;
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: (e) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) _onPointerMove(e, box.size);
      },
      onPointerCancel: (_) => _reset(),
      onPointerUp: (_) => _reset(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(_dy * math.pi / 180)
          ..rotateY(_dx * math.pi / 180),
        child: widget.child,
      ),
    );
  }
}

/* ===== Carte service (sans démo) ===== */
class _ServiceCardNoDemo extends StatelessWidget {
  final String emoji;
  final String title;
  final String desc;
  final Color chipColor;
  final Color accent;
  final VoidCallback onAccess;
  const _ServiceCardNoDemo({
    super.key,
    required this.emoji,
    required this.title,
    required this.desc,
    required this.chipColor,
    required this.accent,
    required this.onAccess,
  });

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 22,
      neon: true,
      accent: accent,
      child: InkWell(
        onTap: onAccess,
        onLongPress: () {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Access "$title"'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: accent,
            ),
          );
        },
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      chipColor.withOpacity(0.22),
                      chipColor.withOpacity(0.06),
                    ],
                  ),
                  border: Border.all(
                    color: chipColor.withOpacity(0.35),
                    width: 1.4,
                  ),
                ),
                child: Text(
                  emoji,
                  style: TextStyle(fontSize: 24, color: chipColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, color: accent, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

/* ===== CTA ===== */
class _GlowingButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  const _GlowingButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 12,
        shadowColor: color.withOpacity(0.6),
      ),
    );
  }
}

/* ===== Dots ===== */
class _DotsIndicator extends StatelessWidget {
  final int count;
  final double index;
  final Color activeColor;
  const _DotsIndicator({
    required this.count,
    required this.index,
    required this.activeColor,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final sel = (index.round() == i);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: sel ? 18 : 6,
          decoration: BoxDecoration(
            color: sel ? activeColor : Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
