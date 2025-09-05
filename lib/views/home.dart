import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/views/nav_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _modes = [
    {"name": "Classic Mode", "icon": Icons.sports_soccer},
    {"name": "Light Mode", "icon": Icons.light_mode},
    {"name": "Pro Analysis Mode", "icon": Icons.analytics},
    {"name": "VAR Vision Mode", "icon": Icons.video_camera_front},
    {"name": "Referee Mode", "icon": Icons.sports},
  ];

  late AnimationController _glowController;
  late AnimationController _scanController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animation de pulsation pour le bouton principal
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _glowAnimation = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    // Animation de la ligne de scan
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _scanController.dispose();
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
          // Arrière-plan avec effet de terrain de football subtil
          Positioned.fill(
            child: CustomPaint(
              painter: _FootballGridPainter(modeProvider.currentMode),
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.getBodyGradient(modeProvider.currentMode),
                ),
              ),
            ),
          ),
          
          // Ligne de scan animée subtile
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
          
          // Contenu principal
          SafeArea(
            child: Column(
              children: [
                // Top bar with refined animation
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) => Opacity(
                          opacity: value,
                          child: Transform.scale(
                            scale: value * 1.05,  // Slight overshoot for polish
                            child: child,
                          ),
                        ),
                        child: Container(
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
                              color: AppColors.getTextColor(modeProvider.currentMode),
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
                      IconButton(
                        icon: Icon(
                          Icons.language,
                          color: AppColors.getTextColor(modeProvider.currentMode),
                          size: 28,
                        ),
                        onPressed: () {
                          _showLanguageDialog(context, langProvider, modeProvider, currentLang);
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.auto_awesome,
                          color: AppColors.getTextColor(modeProvider.currentMode),
                          size: 28,
                        ),
                        onPressed: () {
                          _showModeDialog(context, modeProvider, currentLang);
                        },
                      ),
                    ],
                  ),
                ),
                
                // Subtitle with AI hint, refined typography
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
                    child: Text(
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
                  ),
                ),
                const SizedBox(height: 32),
                
                // Descriptions with staggered animations and icons
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildDescriptionCard(
                            Translations.getHomeText('playerTrackingDesc', currentLang),
                            modeProvider,
                            seedColor,
                            Icons.track_changes,
                            delay: 200,
                          ),
                          const SizedBox(height: 16),
                          _buildDescriptionCard(
                            Translations.getHomeText('foulDetectionDesc', currentLang),
                            modeProvider,
                            seedColor,
                            Icons.warning_amber_rounded,
                            delay: 300,
                          ),
                          const SizedBox(height: 16),
                          _buildDescriptionCard(
                            Translations.getHomeText('keyFieldLinesDesc', currentLang),
                            modeProvider,
                            seedColor,
                            Icons.line_axis,
                            delay: 400,
                          ),
                          const SizedBox(height: 16),
                          _buildDescriptionCard(
                            Translations.getHomeText('offsideDesc', currentLang),
                            modeProvider,
                            seedColor,
                            Icons.flag_circle,
                            delay: 500,
                          ),
                          const SizedBox(height: 16),
                          _buildDescriptionCard(
                            Translations.getHomeText('refereeTrackingDesc', currentLang),
                            modeProvider,
                            seedColor,
                            Icons.sports,
                            delay: 600,
                          ),
                          const SizedBox(height: 16),
                          _buildDescriptionCard(
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
                
                // Button with refined glow and scale animation
                Padding(
                  padding: const EdgeInsets.all(16.0),
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
                    child: ScaleTransition(
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(String text, ModeProvider modeProvider, Color seedColor, IconData icon, {int delay = 0}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset((1 - value) * 50, 0),  // Slide from left for professional feel
          child: child,
        ),
      ),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: AppColors.getShadowColor(seedColor, modeProvider.currentMode).withOpacity(0.3),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.getSurfaceColor(modeProvider.currentMode),
                AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.getDividerColor(seedColor, modeProvider.currentMode).withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode).withOpacity(0.1),
                  shape: BoxShape.circle,
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
    );
  }
}

// Peintre pour l'arrière-plan avec motif de terrain de football plus subtil
class _FootballGridPainter extends CustomPainter {
  final int mode;
  
  _FootballGridPainter(this.mode);
  
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.getTextColor(mode).withOpacity(0.04)
      ..strokeWidth = 0.5;

    const step = 50.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Dessiner un terrain de football stylisé plus subtil
    final fieldPaint = Paint()
      ..color = AppColors.getTextColor(mode).withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final inset = 40.0;
    final rect = Rect.fromLTWH(
        inset, inset * 2, size.width - inset * 2, size.height - inset * 4);
    canvas.drawRect(rect, fieldPaint);

    final midX = rect.center.dy;
    canvas.drawLine(Offset(rect.left + rect.width / 2 - 100, midX), Offset(rect.left + rect.width / 2 + 100, midX), fieldPaint);
    canvas.drawCircle(Offset(rect.left + rect.width / 2, midX), 30, fieldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Peintre pour la ligne de scan animée plus subtile
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
          AppColors.getPrimaryColor(seedColor, mode).withOpacity(0.2),
          AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 0.55, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, y - 80, size.width, 160));

    canvas.drawRect(Rect.fromLTWH(0, y - 80, size.width, 160), line);

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.getPrimaryColor(seedColor, mode).withOpacity(0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, y),
        radius: size.width * 0.25,
      ));

    canvas.drawCircle(Offset(size.width / 2, y), size.width * 0.25, glow);
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.mode != mode;
}