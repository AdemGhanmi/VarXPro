import 'package:VarXPro/views/connexion/models/auth_model.dart';
import 'package:VarXPro/views/connexion/providers/auth_provider.dart';
import 'package:VarXPro/views/connexion/view/login_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/provider/modeprovider.dart';

class SettingsPage extends StatefulWidget {
  final LanguageProvider langProvider;
  final ModeProvider modeProvider;
  final String currentLang;

  const SettingsPage({
    super.key,
    required this.langProvider,
    required this.modeProvider,
    required this.currentLang,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _modes = const [
    {
      "name": "Classic Mode",
      "emoji": "⚽",
      "color": Colors.green,
      "desc": "Traditional football analysis",
    },
    {
      "name": "Light Mode",
      "emoji": "☀️",
      "color": Colors.amber,
      "desc": "Bright and clear interface",
    },
    {
      "name": "Pro Analysis Mode",
      "emoji": "📊",
      "color": Colors.blue,
      "desc": "Advanced statistical insights",
    },
    {
      "name": "VAR Vision Mode",
      "emoji": "📹",
      "color": Colors.purple,
      "desc": "Video assistant referee tools",
    },
    {
      "name": "Referee Mode",
      "emoji": "👨‍⚖️",
      "color": Colors.red,
      "desc": "Official referee perspective",
    },
  ];

  // Role-based emojis
  final Map<String, String> _roleEmojis = {
    'user': '👤',
    'supervisor': '👨‍💼',
    'visitor': '👀',
  };

  // Animations
  late final AnimationController _fadeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();
  late final Animation<double> _fadeAnimation = CurvedAnimation(
    parent: _fadeController,
    curve: Curves.easeInOutQuart,
  );

  late final AnimationController _slideController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();
  late final Animation<Offset> _slideAnimation =
      Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
      );

  late final AnimationController _scaleController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);
  late final Animation<double> _scaleAnimation =
      Tween<double>(begin: 0.98, end: 1.02).animate(
        CurvedAnimation(parent: _scaleController, curve: Curves.easeInOutSine),
      );

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _showSuccessSnackbar(BuildContext context, String message, int mode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.getPrimaryColor(
          AppColors.seedColors[mode] ?? AppColors.seedColors[1]!,
          mode,
        ),
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );

    // إعادة إظهار النص (علشان نعدّل الـ content حسب الرسالة)
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.getPrimaryColor(
          AppColors.seedColors[mode] ?? AppColors.seedColors[1]!,
          mode,
        ),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message, int mode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade700,
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLang = langProvider.currentLanguage;
    final modeProvider = Provider.of<ModeProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.getSurfaceColor(modeProvider.currentMode),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout, color: Colors.red, size: 30),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                Translations.getSettingsText(
                      'logoutConfirmTitle',
                      currentLang,
                    ) ??
                    'Confirm Logout',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.getTextColor(modeProvider.currentMode),
                ),
              ),
              const SizedBox(height: 8),

              // Message
              Text(
                Translations.getSettingsText(
                      'logoutConfirmMessage',
                      currentLang,
                    ) ??
                    'Are you sure you want to logout?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.getTextColor(
                    modeProvider.currentMode,
                  ).withOpacity(.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.getTextColor(
                            modeProvider.currentMode,
                          ).withOpacity(.3),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        Translations.getSettingsText('cancel', currentLang) ??
                            'Cancel',
                        style: TextStyle(
                          color: AppColors.getTextColor(
                            modeProvider.currentMode,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        try {
                          await authProvider.logout(); // يمر عبر AuthService.logout و ينظف الكاش
                          if (!mounted) return;
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                            (route) => false,
                          );
                          _showSuccessSnackbar(
                            context,
                            Translations.getSettingsText(
                                  'logoutSuccess',
                                  currentLang,
                                ) ??
                                'Logged out successfully',
                            modeProvider.currentMode,
                          );
                        } catch (e) {
                          _showErrorSnackbar(
                            context,
                            'Logout failed: ${e.toString()}',
                            modeProvider.currentMode,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: true);
    final modeProvider = Provider.of<ModeProvider>(context, listen: true);
    final authProvider = Provider.of<AuthProvider>(context, listen: true);

    final currentLang = langProvider.currentLanguage;
    final seedColor =
        AppColors.seedColors[modeProvider.currentMode] ??
            AppColors.seedColors[1]!;
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 360;
    final isTablet = size.width > 600;

    final textDirection =
        currentLang == 'ar' ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        body: Stack(
          children: [
            // Background Gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.getPrimaryColor(
                        seedColor,
                        modeProvider.currentMode,
                      ).withOpacity(0.08),
                      AppColors.getSurfaceColor(
                        modeProvider.currentMode,
                      ).withOpacity(0.4),
                      AppColors.getSurfaceColor(modeProvider.currentMode),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // Animated Background Elements
            _AnimatedBackgroundElements(modeProvider: modeProvider),

            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Header
                    _SettingsHeader(
                      modeProvider: modeProvider,
                      isCompact: isCompact,
                      onBack: () => Navigator.pop(context),
                    ),

                    // Title with Logo
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 32 : 20,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              Translations.getSettingsText(
                                    'settingsTitle',
                                    currentLang,
                                  ) ??
                                  'Paramètres',
                              style: TextStyle(
                                fontSize: isCompact ? 26 : 32,
                                fontWeight: FontWeight.w900,
                                color: AppColors.getTextColor(
                                  modeProvider.currentMode,
                                ),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Logo after title
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              width: isCompact ? 40 : 50,
                              height: isCompact ? 40 : 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF6200EE),
                                    const Color(0xFF3700B3).withOpacity(0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6200EE)
                                        .withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/logo.jpg',
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          const Icon(Icons.sports_soccer,
                                              color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Content
                    Expanded(
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _SettingsContent(
                          modeProvider: modeProvider,
                          langProvider: langProvider,
                          currentLang: currentLang,
                          modes: _modes,
                          isTablet: isTablet,
                          authProvider: authProvider,
                          roleEmojis: _roleEmojis,
                          onLogout: () => _logout(context),
                          onSuccessSnackbar: (message) => _showSuccessSnackbar(
                            context,
                            message,
                            modeProvider.currentMode,
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

/* =========================================================================
 *  Widget Components
 * ========================================================================= */

class _AnimatedBackgroundElements extends StatelessWidget {
  final ModeProvider modeProvider;

  const _AnimatedBackgroundElements({required this.modeProvider});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _BackgroundPainter(modeProvider: modeProvider),
        ),
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final ModeProvider modeProvider;

  _BackgroundPainter({required this.modeProvider});

  @override
  void paint(Canvas canvas, Size size) {
    final seedColor =
        AppColors.seedColors[modeProvider.currentMode] ??
            AppColors.seedColors[1]!;
    final primaryColor = AppColors.getPrimaryColor(
      seedColor,
      modeProvider.currentMode,
    );

    final paint = Paint()
      ..color = primaryColor.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Draw some decorative circles
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.1), 60, paint);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.7), 40, paint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.8), 80, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SettingsHeader extends StatelessWidget {
  final ModeProvider modeProvider;
  final bool isCompact;
  final VoidCallback onBack;

  const _SettingsHeader({
    required this.modeProvider,
    required this.isCompact,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          // Back Button
          Container(
            decoration: BoxDecoration(
              color: AppColors.getSurfaceColor(
                modeProvider.currentMode,
              ).withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: AppColors.getTextColor(modeProvider.currentMode),
                size: isCompact ? 20 : 24,
              ),
              onPressed: onBack,
              splashRadius: 20,
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  final ModeProvider modeProvider;
  final LanguageProvider langProvider;
  final String currentLang;
  final List<Map<String, dynamic>> modes;
  final bool isTablet;
  final AuthProvider authProvider;
  final Map<String, String> roleEmojis;
  final VoidCallback onLogout;
  final Function(String) onSuccessSnackbar;

  const _SettingsContent({
    required this.modeProvider,
    required this.langProvider,
    required this.currentLang,
    required this.modes,
    required this.isTablet,
    required this.authProvider,
    required this.roleEmojis,
    required this.onLogout,
    required this.onSuccessSnackbar,
  });

  @override
  Widget build(BuildContext context) {
    final user = authProvider.user;
    final isAuthenticated = authProvider.isAuthenticated;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 32 : 20,
        vertical: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Profile Section (shows after login or for visitor)
          if (user != null) ...[
            _UserProfileSection(
              user: user,
              roleEmoji: roleEmojis[user.role] ?? '👤',
              modeProvider: modeProvider,
              isAuthenticated: isAuthenticated,
            ),
            const SizedBox(height: 20),
          ],

          // Language Section
          _SettingsSection(
            title:
                Translations.getSettingsText('languageSection', currentLang) ??
                    'Language',
            icon: '🌐',
            modeProvider: modeProvider,
          ),
          const SizedBox(height: 8),

          _LanguageGrid(
            currentLang: currentLang,
            modeProvider: modeProvider,
            onLanguageChanged: (langCode, message) {
              langProvider.changeLanguage(langCode);
              onSuccessSnackbar(message);
            },
          ),

          const SizedBox(height: 20),

          // Mode Section
          _SettingsSection(
            title:
                Translations.getSettingsText('modeSection', currentLang) ??
                    'Interface Mode',
            icon: '🎨',
            modeProvider: modeProvider,
          ),
          const SizedBox(height: 8),

          _ModeGrid(
            modes: modes,
            modeProvider: modeProvider,
            currentLang: currentLang,
            onModeChanged: (modeIndex, modeName) {
              modeProvider.changeMode(modeIndex);
              onSuccessSnackbar('$modeName activated');
            },
          ),

          const SizedBox(height: 20),

          // Logout Button (only if authenticated, else hidden)
          if (isAuthenticated)
            _LogoutButton(
              onLogout: onLogout,
              currentLang: currentLang,
              isTablet: isTablet,
            ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _UserProfileSection extends StatelessWidget {
  final User user;
  final String roleEmoji;
  final ModeProvider modeProvider;
  final bool isAuthenticated;

  const _UserProfileSection({
    required this.user,
    required this.roleEmoji,
    required this.modeProvider,
    required this.isAuthenticated,
  });

  @override
  Widget build(BuildContext context) {
    final seedColor = AppColors.seedColors[modeProvider.currentMode] ??
        AppColors.seedColors[1]!;
    final displayName =
        user.name.trim().isEmpty ? '...' : user.name; // Fallback أنظف

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors
                .getPrimaryColor(seedColor, modeProvider.currentMode)
                .withOpacity(0.1),
            AppColors
                .getSurfaceColor(modeProvider.currentMode)
                .withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors
              .getPrimaryColor(seedColor, modeProvider.currentMode)
              .withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Emoji Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  isAuthenticated
                      ? Colors.blue.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  isAuthenticated
                      ? Colors.purple.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: isAuthenticated ? seedColor : Colors.grey,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                roleEmoji,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isAuthenticated ? seedColor : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.getTextColor(modeProvider.currentMode),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors
                        .getTextColor(modeProvider.currentMode)
                        .withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      roleEmoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isAuthenticated
                          ? '${user.role.toUpperCase()} USER'
                          : 'VISITOR MODE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isAuthenticated ? seedColor : Colors.grey,
                      ),
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

class _SettingsSection extends StatelessWidget {
  final String title;
  final String icon;
  final ModeProvider modeProvider;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.modeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(
          modeProvider.currentMode,
        ).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getTextColor(
            modeProvider.currentMode,
          ).withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.getTextColor(modeProvider.currentMode),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageGrid extends StatelessWidget {
  final String currentLang;
  final ModeProvider modeProvider;
  final Function(String, String) onLanguageChanged;

  const _LanguageGrid({
    required this.currentLang,
    required this.modeProvider,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final languages = [
      {
        'code': 'en',
        'label': 'English',
        'flag': '🇺🇸',
        'message': 'Language changed to English',
      },
      {
        'code': 'fr',
        'label': 'Français',
        'flag': '🇫🇷',
        'message': 'Langue changée en Français',
      },
      {
        'code': 'ar',
        'label': 'العربية',
        'flag': '🇹🇳',
        'message': 'تم تغيير اللغة إلى العربية',
      },
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: languages.map((lang) {
        final isSelected = currentLang == lang['code'];
        return _LanguageCard(
          flag: lang['flag']!,
          label: lang['label']!,
          isSelected: isSelected,
          modeProvider: modeProvider,
          onTap: () => onLanguageChanged(lang['code']!, lang['message']!),
        );
      }).toList(),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String flag;
  final String label;
  final bool isSelected;
  final ModeProvider modeProvider;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.flag,
    required this.label,
    required this.isSelected,
    required this.modeProvider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final seedColor =
        AppColors.seedColors[modeProvider.currentMode] ??
            AppColors.seedColors[1]!;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.getPrimaryColor(seedColor, modeProvider.currentMode)
              : AppColors.getSurfaceColor(
            modeProvider.currentMode,
          ).withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.getPrimaryColor(seedColor, modeProvider.currentMode)
                : AppColors.getTextColor(
              modeProvider.currentMode,
            ).withOpacity(0.1),
            width: 2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.getPrimaryColor(
                  seedColor,
                  modeProvider.currentMode,
                ).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : AppColors.getTextColor(modeProvider.currentMode),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeGrid extends StatelessWidget {
  final List<Map<String, dynamic>> modes;
  final ModeProvider modeProvider;
  final String currentLang;
  final Function(int, String) onModeChanged;

  const _ModeGrid({
    required this.modes,
    required this.modeProvider,
    required this.currentLang,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: modes.length,
      itemBuilder: (context, index) {
        final mode = modes[index];
        final modeIndex = index + 1;
        final isSelected = modeProvider.currentMode == modeIndex;

        return _ModeCard(
          emoji: mode['emoji'] as String,
          name: mode['name'] as String,
          description: mode['desc'] as String,
          color: mode['color'] as Color,
          isSelected: isSelected,
          onTap: () => onModeChanged(modeIndex, mode['name'] as String),
        );
      },
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String emoji;
  final String name;
  final String description;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.emoji,
    required this.name,
    required this.description,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          gradient: isSelected
              ? LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : LinearGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Stack(
          children: [
            const Positioned(
              top: 12,
              left: 12,
              child: Text(''),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child:
                    const Icon(Icons.check_circle, color: Colors.white, size: 16),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected
                            ? Colors.white.withOpacity(0.8)
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
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

class _LogoutButton extends StatelessWidget {
  final VoidCallback onLogout;
  final String currentLang;
  final bool isTablet;

  const _LogoutButton({
    required this.onLogout,
    required this.currentLang,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade600, Colors.red.shade800],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onLogout,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  Translations.getSettingsText('logoutButton', currentLang) ??
                      'Logout',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
