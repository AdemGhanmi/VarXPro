// Updated file: lib/views/settings_page.dart (Add history count display)
import 'package:VarXPro/views/connexion/view/login_page.dart';
import 'package:VarXPro/views/setting/provider/history_provider.dart';
import 'package:VarXPro/views/setting/views/history_page.dart';  
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

class _SettingsPageState extends State<SettingsPage> with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _modes = [
    {"name": "Classic Mode", "emoji": "⚽", "color": Colors.green},
    {"name": "Light Mode", "emoji": "☀️", "color": Colors.amber},
    {"name": "Pro Analysis Mode", "emoji": "📊", "color": Colors.blue},
    {"name": "VAR Vision Mode", "emoji": "📹", "color": Colors.purple},
    {"name": "Referee Mode", "emoji": "👨‍⚖️", "color": Colors.red},
  ];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  void _showSuccessSnackbar(BuildContext context, String message, int mode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.getPrimaryColor(
          AppColors.seedColors[mode] ?? AppColors.seedColors[1]!, 
          mode
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.getSurfaceColor(Provider.of<ModeProvider>(context, listen: false).currentMode),
        title: Text(
          Translations.getSettingsText('logoutConfirmTitle', Provider.of<LanguageProvider>(context, listen: false).currentLanguage ?? 'en') ?? 'Confirm Logout',
          style: TextStyle(
            color: AppColors.getTextColor(Provider.of<ModeProvider>(context, listen: false).currentMode),
          ),
        ),
        content: Text(
          Translations.getSettingsText('logoutConfirmMessage', Provider.of<LanguageProvider>(context, listen: false).currentLanguage ?? 'en') ?? 'Are you sure you want to logout?',
          style: TextStyle(
            color: AppColors.getTextColor(Provider.of<ModeProvider>(context, listen: false).currentMode),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              Translations.getSettingsText('cancel', Provider.of<LanguageProvider>(context, listen: false).currentLanguage ?? 'en') ?? 'Cancel',
              style: TextStyle(
                color: AppColors.getTertiaryColor(
                  AppColors.seedColors[Provider.of<ModeProvider>(context, listen: false).currentMode] ?? AppColors.seedColors[1]!, 
                  Provider.of<ModeProvider>(context, listen: false).currentMode
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              Translations.getSettingsText('logout', Provider.of<LanguageProvider>(context, listen: false).currentLanguage ?? 'en') ?? 'Logout',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: true);
    final modeProvider = Provider.of<ModeProvider>(context, listen: true);
    final historyProvider = Provider.of<HistoryProvider>(context, listen: true); 
    final currentLang = langProvider.currentLanguage ?? 'en';
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
                    AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.9),
                    AppColors.getSurfaceColor(modeProvider.currentMode),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                       IconButton(
                          icon: Icon(Icons.arrow_back, color: AppColors.getTextColor(modeProvider.currentMode)),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Hero(
                          tag: 'logo',
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.getPrimaryColor(seedColor, modeProvider.currentMode),
                                    AppColors.getPrimaryColor(seedColor, modeProvider.currentMode).withOpacity(0.7),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode).withOpacity(0.4),
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
                        const SizedBox(width: 60), // Spacer for alignment
                      ],
                    ),
                  ),
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      Translations.getSettingsText('settingsTitle', currentLang) ?? 'Settings',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextColor(modeProvider.currentMode),
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode).withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Main Content
                  Expanded(
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          children: [
                            // Language Section - Now using ExpansionTile
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode).withOpacity(0.2),
                                ),
                              ),
                              child: ExpansionTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode).withOpacity(0.2),
                                  ),
                                  child: Text(
                                    '🌐',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  Translations.getSettingsText('languageSection', currentLang) ?? 'Language',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.getTextColor(modeProvider.currentMode),
                                  ),
                                ),
                                backgroundColor: AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.3),
                                collapsedBackgroundColor: Colors.transparent,
                                children: Translations.getLanguages(currentLang).asMap().entries.map((entry) {
                                  int idx = entry.key;
                                  String lang = entry.value;
                                  String code = idx == 0 ? 'en' : idx == 1 ? 'fr' : 'ar';
                                  String flag = code == 'en' ? '🇺🇸' : code == 'fr' ? '🇫🇷' : '🇹🇳';
                                  return ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode).withOpacity(0.2),
                                      ),
                                      child: Text(
                                        flag,
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      lang,
                                      style: TextStyle(
                                        color: AppColors.getTextColor(modeProvider.currentMode),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    trailing: langProvider.currentLanguage == code 
                                        ? Text(
                                            '✅',
                                            style: TextStyle(
                                              fontSize: 20,
                                              color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode),
                                            ),
                                          )
                                        : null,
                                    onTap: () {
                                      langProvider.changeLanguage(code);
                                      _showSuccessSnackbar(context, 'Language changed to $lang', modeProvider.currentMode);
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Mode Section - Now using ExpansionTile
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode).withOpacity(0.2),
                                ),
                              ),
                              child: ExpansionTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode).withOpacity(0.2),
                                  ),
                                  child: Text(
                                    '✨',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  Translations.getSettingsText('modeSection', currentLang) ?? 'Mode',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.getTextColor(modeProvider.currentMode),
                                  ),
                                ),
                                backgroundColor: AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.3),
                                collapsedBackgroundColor: Colors.transparent,
                                children: _modes.asMap().entries.map((entry) {
                                  int index = entry.key;
                                  var mode = entry.value;
                                  return ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: mode['color'].withOpacity(0.2),
                                      ),
                                      child: Text(
                                        mode['emoji'],
                                        style: TextStyle(
                                          color: mode['color'],
                                          fontSize: 24,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      mode['name'],
                                      style: TextStyle(
                                        color: AppColors.getTextColor(modeProvider.currentMode),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    trailing: modeProvider.currentMode == index + 1
                                        ? Text(
                                            '✅',
                                            style: TextStyle(
                                              fontSize: 20,
                                              color: mode['color'],
                                            ),
                                          )
                                        : null,
                                    onTap: () {
                                      modeProvider.changeMode(index + 1);
                                      _showSuccessSnackbar(context, '${mode['name']} activated', modeProvider.currentMode);
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // History Section (with count)
                            _SettingsSection(
                              title: '${Translations.getSettingsText('historySection', currentLang) ?? 'History'} (${historyProvider.historyCount})', // Add count here
                              emoji: '📜',
                              children: [
                                ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode).withOpacity(0.1),
                                    ),
                                    child: Text(
                                      '📜',
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    'View History',
                                    style: TextStyle(
                                      color: AppColors.getTextColor(modeProvider.currentMode),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  trailing: Text(
                                    '➡️',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.getTextColor(modeProvider.currentMode),
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const HistoryPage()),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Logout Button
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 40),
                              child: ElevatedButton.icon(
                                onPressed: () => _logout(context),
                                icon: Text(
                                  '👋',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                  ),
                                ),
                                label: Text(
                                  Translations.getSettingsText('logoutButton', currentLang) ?? 'Logout',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ],
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
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final String emoji;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.emoji,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final modeProvider = Provider.of<ModeProvider>(context);
    final seedColor = AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode).withOpacity(0.2),
                ),
                child: Text(
                  emoji,
                  style: TextStyle(
                    fontSize: 20,
                    color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextColor(modeProvider.currentMode),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}