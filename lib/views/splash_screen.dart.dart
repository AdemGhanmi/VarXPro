// lib/views/connexion/view/splash_screen.dart
import 'package:VarXPro/views/connexion/view/login_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

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
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _showSuccessSnackbar(BuildContext context, String message, int mode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.getPrimaryColor(
          AppColors.seedColors[mode] ?? AppColors.seedColors[1]!,
          mode,
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showLanguageDialog(
    BuildContext context,
    LanguageProvider langProvider,
    ModeProvider modeProvider,
    String currentLang,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: _getTextDirection(currentLang),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: AppColors.getSurfaceColor(modeProvider.currentMode),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "🌐",
                  style: TextStyle(
                    fontSize: 40,
                    color: AppColors.getPrimaryColor(
                      AppColors.seedColors[modeProvider.currentMode] ??
                          AppColors.seedColors[1]!,
                      modeProvider.currentMode,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  Translations.getChooseLanguage(currentLang),
                  style: TextStyle(
                    color: AppColors.getTextColor(modeProvider.currentMode),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                ...Translations.getLanguages(currentLang).asMap().entries.map((
                  entry,
                ) {
                  int idx = entry.key;
                  String lang = entry.value;
                  String code = idx == 0
                      ? 'en'
                      : idx == 1
                      ? 'fr'
                      : 'ar';
                  String flag = code == 'en'
                      ? '🇺🇸'
                      : code == 'fr'
                      ? '🇫🇷'
                      : '🇹🇳';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      tileColor: AppColors.getTertiaryColor(
                        AppColors.seedColors[modeProvider.currentMode] ??
                            AppColors.seedColors[1]!,
                        modeProvider.currentMode,
                      ).withOpacity(0.1),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.getPrimaryColor(
                            AppColors.seedColors[modeProvider.currentMode] ??
                                AppColors.seedColors[1]!,
                            modeProvider.currentMode,
                          ).withOpacity(0.2),
                        ),
                        child: Text(
                          flag,
                          style: TextStyle(
                            fontSize: 20,
                            color: AppColors.getPrimaryColor(
                              AppColors.seedColors[modeProvider.currentMode] ??
                                  AppColors.seedColors[1]!,
                              modeProvider.currentMode,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        lang,
                        style: TextStyle(
                          color: AppColors.getTextColor(
                            modeProvider.currentMode,
                          ),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: langProvider.currentLanguage == code
                          ? Icon(
                              Icons.check_circle,
                              color: AppColors.getPrimaryColor(
                                AppColors.seedColors[modeProvider
                                        .currentMode] ??
                                    AppColors.seedColors[1]!,
                                modeProvider.currentMode,
                              ),
                            )
                          : null,
                      onTap: () {
                        langProvider.changeLanguage(code);
                        Navigator.pop(ctx);
                        _showSuccessSnackbar(
                          context,
                          'Language changed to $lang',
                          modeProvider.currentMode,
                        );
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showModeDialog(
    BuildContext context,
    ModeProvider modeProvider,
    String currentLang,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: _getTextDirection(currentLang),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: AppColors.getSurfaceColor(modeProvider.currentMode),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "✨",
                  style: TextStyle(
                    fontSize: 40,
                    color: AppColors.getPrimaryColor(
                      AppColors.seedColors[modeProvider.currentMode] ??
                          AppColors.seedColors[1]!,
                      modeProvider.currentMode,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  Translations.getChooseMode(currentLang),
                  style: TextStyle(
                    color: AppColors.getTextColor(modeProvider.currentMode),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                ..._modes.asMap().entries.map((entry) {
                  int index = entry.key;
                  var mode = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      tileColor: AppColors.getTertiaryColor(
                        AppColors.seedColors[modeProvider.currentMode] ??
                            AppColors.seedColors[1]!,
                        modeProvider.currentMode,
                      ).withOpacity(0.1),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: mode['color'].withOpacity(0.2),
                        ),
                        child: Text(
                          mode['emoji'],
                          style: TextStyle(color: mode['color'], fontSize: 24),
                        ),
                      ),
                      title: Text(
                        mode['name'],
                        style: TextStyle(
                          color: AppColors.getTextColor(
                            modeProvider.currentMode,
                          ),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: modeProvider.currentMode == index + 1
                          ? Icon(Icons.check_circle, color: mode['color'])
                          : null,
                      onTap: () {
                        modeProvider.changeMode(index + 1);
                        Navigator.pop(ctx);
                        _showSuccessSnackbar(
                          context,
                          '${mode['name']} activated',
                          modeProvider.currentMode,
                        );
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextDirection _getTextDirection(String? lang) =>
      lang == 'ar' ? TextDirection.rtl : TextDirection.ltr;

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final modeProvider = Provider.of<ModeProvider>(context);
    final currentLang = langProvider.currentLanguage;
    final seedColor =
        AppColors.seedColors[modeProvider.currentMode] ??
        AppColors.seedColors[1]!;

    final features = [
      {
        'emoji': "📍",
        'title': 'Player Tracking',
        'desc':
            Translations.getHomeText('playerTrackingDesc', currentLang) ??
            'Advanced player movement tracking with AI precision.',
        'color': Colors.blue,
      },
      {
        'emoji': "⚠️",
        'title': 'Foul Detection',
        'desc':
            Translations.getHomeText('foulDetectionDesc', currentLang) ??
            'Real-time foul identification using computer vision.',
        'color': Colors.orange,
      },
      {
        'emoji': "📏",
        'title': 'Key Field Lines',
        'desc':
            Translations.getHomeText('keyFieldLinesDesc', currentLang) ??
            'Accurate detection of field lines for better analysis.',
        'color': Colors.green,
      },
      {
        'emoji': "🚩",
        'title': 'Offside Analysis',
        'desc':
            Translations.getHomeText('offsideDesc', currentLang) ??
            'Precise offside rule enforcement with multi-angle views.',
        'color': Colors.red,
      },
      {
        'emoji': "👨‍⚖️",
        'title': 'Referee Tracking',
        'desc':
            Translations.getHomeText('refereeTrackingDesc', currentLang) ??
            'Monitor referee decisions and positioning in real-time.',
        'color': Colors.purple,
      },
      {
        'emoji': "🤖",
        'title': 'AI Insights',
        'desc': 'AI-powered solutions for football analysis.',
        'color': Colors.teal,
      },
    ];

    return Directionality(
      textDirection: _getTextDirection(currentLang),
      child: Scaffold(
        backgroundColor: AppColors.getSurfaceColor(modeProvider.currentMode),
        body: Stack(
          children: [

            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Hero(
                                  tag: 'logo',
                                  child: ScaleTransition(
                                    scale: _scaleAnimation,
                                    child: Container(
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.getPrimaryColor(
                                              seedColor,
                                              modeProvider.currentMode,
                                            ),
                                            AppColors.getPrimaryColor(
                                              seedColor,
                                              modeProvider.currentMode,
                                            ).withOpacity(0.7),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.getPrimaryColor(
                                              seedColor,
                                              modeProvider.currentMode,
                                            ).withOpacity(0.4),
                                            blurRadius: 15,
                                            spreadRadius: 3,
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: Image.asset(
                                          'assets/logo.jpg',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'VAR X PRO ',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.getTextColor(
                                            modeProvider.currentMode,
                                          ),
                                          letterSpacing: 1.2,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 10,
                                              color: AppColors.getPrimaryColor(
                                                seedColor,
                                                modeProvider.currentMode,
                                              ).withOpacity(0.3),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        'AI Football Analysis',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.getTextColor(
                                            modeProvider.currentMode,
                                          ).withOpacity(0.7),
                                          fontWeight: FontWeight.w500,
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
                              _AnimatedEmojiButton(
                                emoji: "🌐",
                                color: AppColors.getPrimaryColor(
                                  seedColor,
                                  modeProvider.currentMode,
                                ),
                                onPressed: () => _showLanguageDialog(
                                  context,
                                  langProvider,
                                  modeProvider,
                                  currentLang ?? 'en',
                                ),
                              ),
                              const SizedBox(width: 12),
                              _AnimatedEmojiButton(
                                emoji: "✨",
                                color: AppColors.getPrimaryColor(
                                  seedColor,
                                  modeProvider.currentMode,
                                ),
                                onPressed: () => _showModeDialog(
                                  context,
                                  modeProvider,
                                  currentLang ?? 'en',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.getPrimaryColor(
                                    seedColor,
                                    modeProvider.currentMode,
                                  ).withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.getPrimaryColor(
                                      seedColor,
                                      modeProvider.currentMode,
                                    ).withOpacity(0.2),
                                  ),
                                ),
                                child: Text(
                                  Translations.getHomeText(
                                        'subtitle',
                                        currentLang,
                                      ) ??
                                      'Revolutionizing Football Analysis with AI',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.getTextColor(
                                      modeProvider.currentMode,
                                    ).withOpacity(0.9),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.8,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                    ),
                                itemCount: features.length,
                                itemBuilder: (context, index) {
                                  final feature = features[index];
                                  return _FeatureCard(
                                    emoji: feature['emoji'] as String,
                                    title: feature['title'] as String,
                                    desc: feature['desc'] as String,
                                    iconColor: feature['color'] as Color,
                                    seedColor: seedColor,
                                    mode: modeProvider.currentMode,
                                  );
                                },
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.getSurfaceColor(
                              modeProvider.currentMode,
                            ).withOpacity(0.7),
                            AppColors.getSurfaceColor(modeProvider.currentMode),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              PageRouteBuilder(
                                transitionDuration: const Duration(
                                  milliseconds: 800,
                                ),
                                pageBuilder: (_, __, ___) => const LoginPage(),
                                transitionsBuilder: (_, anim, __, child) {
                                  return FadeTransition(
                                    opacity: anim,
                                    child: SlideTransition(
                                      position:
                                          Tween<Offset>(
                                            begin: const Offset(0, 0.5),
                                            end: Offset.zero,
                                          ).animate(
                                            CurvedAnimation(
                                              parent: anim,
                                              curve: Curves.easeInOutBack,
                                            ),
                                          ),
                                      child: child,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 22,
                          ),
                          label: Text(
                            Translations.getHomeText('enterApp', currentLang) ??
                                'ENTER APPLICATION',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.getPrimaryColor(
                              seedColor,
                              modeProvider.currentMode,
                            ),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                            shadowColor: AppColors.getPrimaryColor(
                              seedColor,
                              modeProvider.currentMode,
                            ).withOpacity(0.5),
                          ),
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
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String desc;
  final Color iconColor;
  final Color seedColor;
  final int mode;

  const _FeatureCard({
    required this.emoji,
    required this.title,
    required this.desc,
    required this.iconColor,
    required this.seedColor,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.getSurfaceColor(mode).withOpacity(0.8),
            AppColors.getSurfaceColor(mode).withOpacity(0.6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: AppColors.getPrimaryColor(seedColor, mode).withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  iconColor.withOpacity(0.2),
                  iconColor.withOpacity(0.1),
                ],
              ),
              border: Border.all(color: iconColor.withOpacity(0.3), width: 2),
            ),
            child: Text(
              emoji,
              style: TextStyle(color: iconColor, fontSize: 28),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextColor(mode),
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              desc,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.getTextColor(mode).withOpacity(0.8),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedEmojiButton extends StatefulWidget {
  final String emoji;
  final Color color;
  final VoidCallback onPressed;
  const _AnimatedEmojiButton({
    required this.emoji,
    required this.color,
    required this.onPressed,
  });
  @override
  State<_AnimatedEmojiButton> createState() => __AnimatedEmojiButtonState();
}

class __AnimatedEmojiButtonState extends State<_AnimatedEmojiButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  late final Animation<double> _scaleAnimation = Tween<double>(
    begin: 1.0,
    end: 0.9,
  ).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.forward();
  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    widget.onPressed();
  }

  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                widget.color.withOpacity(0.15),
                widget.color.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: widget.color.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.emoji,
              style: TextStyle(color: widget.color, fontSize: 22),
            ),
          ),
        ),
      ),
    );
  }
}