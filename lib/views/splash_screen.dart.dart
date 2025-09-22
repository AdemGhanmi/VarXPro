import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/views/nav_bar.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _modes = [
    {"name": "Classic Mode", "icon": Icons.sports_soccer},
    {"name": "Light Mode", "icon": Icons.light_mode},
    {"name": "Pro Analysis Mode", "icon": Icons.analytics},
    {"name": "VAR Vision Mode", "icon": Icons.video_camera_front},
    {"name": "Referee Mode", "icon": Icons.sports},
  ];

  late AnimationController _glowController;
  late AnimationController _scanController;
  late AnimationController _particleController;
  late Animation<double> _glowAnimation;
  final List<Particle> _particles = [];

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
    

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    

    _initializeParticles();
  }

  void _initializeParticles() {
    for (int i = 0; i < 15; i++) {
      _particles.add(Particle());
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _scanController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _showLanguageDialog(
      BuildContext context, LanguageProvider langProvider, ModeProvider modeProvider, String currentLang) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.98),
                AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.92),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
            border: Border.all(
              color: AppColors.getPrimaryColor(
                AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!, 
                modeProvider.currentMode
              ).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Translations.getChooseLanguage(currentLang),
                style: TextStyle(
                  color: AppColors.getTextColor(modeProvider.currentMode),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 24),
              ...Translations.getLanguages(currentLang).asMap().entries.map((entry) {
                int idx = entry.key;
                String lang = entry.value;
                String code = idx == 0 ? 'en' : idx == 1 ? 'fr' : 'ar';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: AppColors.getTertiaryColor(
                            AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!, modeProvider.currentMode)
                        .withOpacity(0.2),
                    title: Text(
                      lang,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.getTextColor(modeProvider.currentMode),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      langProvider.changeLanguage(code);
                      Navigator.pop(ctx);
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  void _showModeDialog(BuildContext context, ModeProvider modeProvider, String currentLang) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.98),
                AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.92),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
            border: Border.all(
              color: AppColors.getPrimaryColor(
                AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!, 
                modeProvider.currentMode
              ).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Translations.getChooseMode(currentLang),
                style: TextStyle(
                  color: AppColors.getTextColor(modeProvider.currentMode),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 24),
              ...Translations.getModes(currentLang).asMap().entries.map((entry) {
                int index = entry.key;
                String modeName = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: AppColors.getTertiaryColor(
                            AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!, modeProvider.currentMode)
                        .withOpacity(0.2),
                    leading: Icon(
                      _modes[index]["icon"],
                      color: AppColors.getTextColor(modeProvider.currentMode),
                      size: 28,
                    ),
                    title: Text(
                      modeName,
                      style: TextStyle(
                        color: AppColors.getTextColor(modeProvider.currentMode),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      modeProvider.changeMode(index + 1);
                      Navigator.pop(ctx);
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final modeProvider = Provider.of<ModeProvider>(context);
    final currentLang = langProvider.currentLanguage;
    final seedColor = AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.5,
                  colors: [
                    AppColors.getPrimaryColor(seedColor, modeProvider.currentMode).withOpacity(0.15),
                    AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.05),
                    AppColors.getBodyGradient(modeProvider.currentMode).colors.last,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          

          Positioned.fill(
            child: CustomPaint(
              painter: _DataGridPainter(modeProvider.currentMode, seedColor),
            ),
          ),
          
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, _) {
              return CustomPaint(
                painter: _ParticlePainter(
                  particles: _particles,
                  time: _particleController.value,
                  seedColor: seedColor,
                  mode: modeProvider.currentMode,
                ),
              );
            },
          ),
          

          Positioned.fill(
            child: AnimatedBuilder(
              animation: _scanController,
              builder: (context, _) {
                final t = _scanController.value;
                return CustomPaint(
                  painter: _ScanLinePainter(
                    progress: t,
                    mode: modeProvider.currentMode,
                    seedColor: seedColor,
                  ),
                );
              },
            ),
          ),
          

          SafeArea(
            child: Column(
              children: [

                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [

                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) => Opacity(
                          opacity: value,
                          child: Transform.scale(
                            scale: value * 1.05,
                            child: child,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.getPrimaryColor(seedColor, modeProvider.currentMode).withOpacity(0.4),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.7],
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode).withOpacity(0.3),
                                    blurRadius: 12,
                                    spreadRadius: 3,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/logo.jpg',
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 1200),
                          curve: Curves.easeOut,
                          builder: (context, value, child) => Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, (1 - value) * 20),
                              child: child,
                            ),
                          ),
                          child: Text(
                            'VAR X PRO',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              fontFamily: 'Poppins',
                              foreground: Paint()
                                ..shader = LinearGradient(
                                  colors: [
                                    AppColors.getTextColor(modeProvider.currentMode),
                                    AppColors.getPrimaryColor(seedColor, modeProvider.currentMode),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                              shadows: [
                                Shadow(
                                  blurRadius: 6,
                                  color: Colors.black.withOpacity(0.15),
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _HaloIconButton(
                        icon: Icons.language,
                        color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode),
                        onPressed: () {
                          _showLanguageDialog(context, langProvider, modeProvider, currentLang);
                        },
                      ),
                      const SizedBox(width: 8),
                      _HaloIconButton(
                        icon: Icons.auto_awesome,
                        color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode),
                        onPressed: () {
                          _showModeDialog(context, modeProvider, currentLang);
                        },
                      ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1400),
                    curve: Curves.easeOut,
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - value) * 20),
                        child: child,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${Translations.getHomeText('subtitle', currentLang)}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.getTextColor(modeProvider.currentMode).withOpacity(0.8),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                        
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildAIDescriptionCard(
                            Translations.getHomeText('playerTrackingDesc', currentLang),
                            modeProvider,
                            seedColor,
                            Icons.track_changes,
                            delay: 200,
                          ),
                          const SizedBox(height: 16),
                          _buildAIDescriptionCard(
                            Translations.getHomeText('foulDetectionDesc', currentLang),
                            modeProvider,
                            seedColor,
                            Icons.warning_amber_rounded,
                            delay: 300,
                          ),
                          const SizedBox(height: 16),
                          _buildAIDescriptionCard(
                            Translations.getHomeText('keyFieldLinesDesc', currentLang),
                            modeProvider,
                            seedColor,
                            Icons.line_axis,
                            delay: 400,
                          ),
                          const SizedBox(height: 16),
                          _buildAIDescriptionCard(
                            Translations.getHomeText('offsideDesc', currentLang),
                            modeProvider,
                            seedColor,
                            Icons.flag_circle,
                            delay: 500,
                          ),
                          const SizedBox(height: 16),
                          _buildAIDescriptionCard(
                            Translations.getHomeText('refereeTrackingDesc', currentLang),
                            modeProvider,
                            seedColor,
                            Icons.sports,
                            delay: 600,
                          ),
                          const SizedBox(height: 16),
                          _buildAIDescriptionCard(
                            'AI Insights: Get the best AI-powered solutions for your football analysis problems, including tracking, verification, and more.',
                            modeProvider,
                            seedColor,
                            Icons.smart_toy,
                            delay: 700,
                          ),
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1600),
                    curve: Curves.easeOut,
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - value) * 30),
                        child: child,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ScaleTransition(
                          scale: _glowAnimation,
                          child: Container(
                            width: 250,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode).withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                          ),
                        ),
                        ScaleTransition(
                          scale: _glowAnimation,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                PageRouteBuilder(
                                  transitionDuration: const Duration(milliseconds: 800),
                                  pageBuilder: (_, __, ___) => const NavPage(),
                                  transitionsBuilder: (_, anim, __, child) {
                                    return SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 1),
                                        end: Offset.zero,
                                      ).animate(CurvedAnimation(
                                        parent: anim,
                                        curve: Curves.easeInOutCubic,
                                      )),
                                      child: FadeTransition(
                                        opacity: anim,
                                        child: child,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: 6,
                              shadowColor: AppColors.getShadowColor(seedColor, modeProvider.currentMode).withOpacity(0.4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  Translations.getHomeText('enterApp', currentLang),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_ios, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIDescriptionCard(String text, ModeProvider modeProvider, Color seedColor, IconData icon, {int delay = 0}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset((1 - value) * 50, 0),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.7),
              AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.4),
            ],
          ),
          border: Border.all(
            color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode).withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.3),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.getPrimaryColor(seedColor, modeProvider.currentMode).withOpacity(0.2),
                          Colors.transparent,
                        ],
                        stops: const [0.1, 1.0],
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.getLabelColor(seedColor, modeProvider.currentMode),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.getTextColor(modeProvider.currentMode),
                        fontWeight: FontWeight.w500,
                        height: 1.6,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HaloIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _HaloIconButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.2),
            Colors.transparent,
          ],
          stops: const [0.2, 1.0],
        ),
      ),
      child: IconButton(
        icon: Icon(icon, size: 28),
        color: color,
        onPressed: onPressed,
      ),
    );
  }
}

class Particle {
  double x = Random().nextDouble() * 100;
  double y = Random().nextDouble() * 100;
  double radius = Random().nextDouble() * 3 + 1;
  double speed = Random().nextDouble() * 0.5 + 0.1;
  double angle = Random().nextDouble() * 2 * 3.14159;
}

class _DataGridPainter extends CustomPainter {
  final int mode;
  final Color seedColor;
  
  _DataGridPainter(this.mode, this.seedColor);
  
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.getTextColor(mode).withOpacity(0.05)
      ..strokeWidth = 0.8;

    const step = 40.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final dotPaint = Paint()
      ..color = AppColors.getPrimaryColor(seedColor, mode).withOpacity(0.2)
      ..style = PaintingStyle.fill;

    for (double x = step; x < size.width; x += step) {
      for (double y = step; y < size.height; y += step) {
        if (Random().nextDouble() > 0.7) {
          canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
        }
      }
    }

    final linePaint = Paint()
      ..color = AppColors.getPrimaryColor(seedColor, mode).withOpacity(0.1)
      ..strokeWidth = 0.8;

    for (int i = 0; i < 15; i++) {
      final startX = Random().nextDouble() * size.width;
      final startY = Random().nextDouble() * size.height;
      final endX = startX + (Random().nextDouble() * 100 - 50);
      final endY = startY + (Random().nextDouble() * 100 - 50);
      
      if (endX > 0 && endX < size.width && endY > 0 && endY < size.height) {
        canvas.drawLine(Offset(startX, startY), Offset(endX, endY), linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double time;
  final Color seedColor;
  final int mode;
  
  _ParticlePainter({
    required this.particles,
    required this.time,
    required this.seedColor,
    required this.mode,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      particle.x += particle.speed * cos(particle.angle) * 0.3;
      particle.y += particle.speed * sin(particle.angle) * 0.3;
      
      if (particle.x < 0 || particle.x > size.width || particle.y < 0 || particle.y > size.height) {
        particle.x = Random().nextDouble() * size.width;
        particle.y = Random().nextDouble() * size.height;
        particle.angle = Random().nextDouble() * 2 * 3.14159;
      }
      
      final paint = Paint()
        ..color = AppColors.getPrimaryColor(seedColor, mode).withOpacity(0.15)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(particle.x, particle.y), particle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => 
      oldDelegate.time != time || oldDelegate.particles != particles;
}

class _ScanLinePainter extends CustomPainter {
  final double progress;
  final int mode;
  final Color seedColor;
  
  _ScanLinePainter({required this.progress, required this.mode, required this.seedColor});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    final line = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          AppColors.getPrimaryColor(seedColor, mode).withOpacity(0.15),
          AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 0.55, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, y - 60, size.width, 120));

    canvas.drawRect(Rect.fromLTWH(0, y - 60, size.width, 120), line);

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.getPrimaryColor(seedColor, mode).withOpacity(0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, y),
        radius: size.width * 0.2,
      ));

    canvas.drawCircle(Offset(size.width / 2, y), size.width * 0.2, glow);
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.mode != mode;
}