import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:VarXPro/views/pages/LiveStream/controller/live_stream_controller.dart';
import 'package:VarXPro/views/pages/LiveStream/views/live_stream_dashboard.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/views/pages/FauteDetectiong/faute_detection_page.dart';
import 'package:VarXPro/views/pages/FauteDetectiong/service/FoulDetectionService.dart';
import 'package:VarXPro/views/pages/FiledLinesPages/service/perspective_service.dart';
import 'package:VarXPro/views/pages/FiledLinesPages/view/key_field_lines_page.dart';
import 'package:VarXPro/views/pages/RefereeTraking/service/referee_api_service.dart';
import 'package:VarXPro/views/pages/RefereeTraking/view/referee_tracking.dart';
import 'package:VarXPro/views/pages/TrackingAndGoalAnalysis/service/tracking_service.dart';
import 'package:VarXPro/views/pages/TrackingAndGoalAnalysis/view/tracking_page.dart';
import 'package:VarXPro/views/pages/offsidePage/service/offside_service.dart';
import 'package:VarXPro/views/pages/offsidePage/view/offside_page.dart';
import 'package:VarXPro/views/pages/home/view/home_page.dart';

class NavPage extends StatefulWidget {
  const NavPage({super.key});

  @override
  State<NavPage> createState() => _NavPageState();
}

class _NavPageState extends State<NavPage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _glowController;
  late AnimationController _bubbleController;

  final List<Widget> _pages = [
    const HomePage(),
    RepositoryProvider(
      create: (context) => TrackingService(),
      child: const EnhancedSoccerPlayerTrackingAndGoalAnalysisPage(),
    ),
    RepositoryProvider(
      create: (context) => FoulDetectionService(),
      child: const FoulDetectionPage(),
    ),
    RepositoryProvider(
      create: (context) => PerspectiveService(),
      child: const KeyFieldLinesPage(),
    ),
    RepositoryProvider(
      create: (context) => OffsideService(),
      child: const OffsidePage(),
    ),
    RepositoryProvider(
      create: (context) => RefereeService(),
      child: const RefereeTrackingSystemPage(),
    ),
    RepositoryProvider(
      create: (context) => LiveStreamController(),
      child: const LiveStreamDashboard(),
    ),
  ];

  final List<Map<String, dynamic>> _modes = [
    {"name": "Classic Mode", "icon": Icons.sports_soccer},
    {"name": "Light Mode", "icon": Icons.light_mode},
    {"name": "Pro Analysis Mode", "icon": Icons.analytics},
    {"name": "VAR Vision Mode", "icon": Icons.video_camera_front},
    {"name": "Referee Mode", "icon": Icons.sports},
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
      lowerBound: 0.8,
      upperBound: 1.0,
    )..repeat(reverse: true);

    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    _bubbleController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final modeProvider = Provider.of<ModeProvider>(context);
    final currentLang = langProvider.currentLanguage;
    final seedColor =
        AppColors.seedColors[modeProvider.currentMode] ??
        AppColors.seedColors[1]!;

    // الحصول على حجم الشاشة لتحديد إذا كانت صغيرة
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(modeProvider.currentMode),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.language, color: Colors.white, size: isSmallScreen ? 24 : 28),
          onPressed: () {
            _showLanguageDialog(
              context,
              langProvider,
              modeProvider,
              currentLang,
            );
          },
        ),
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Text(
            _selectedIndex == 0
                ? 'Home'
                : Translations.getTitle(_selectedIndex - 1, currentLang),
            key: ValueKey<String>(
              _selectedIndex == 0
                  ? 'Home'
                  : Translations.getTitle(_selectedIndex - 1, currentLang),
            ),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: isSmallScreen ? 20 : 24,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.auto_awesome, color: Colors.white, size: isSmallScreen ? 24 : 28),
            onPressed: () {
              _showModeDialog(context, modeProvider, currentLang);
            },
          ),
        ],
        backgroundColor: AppColors.getPrimaryColor(
          seedColor,
          modeProvider.currentMode,
        ),
        elevation: 4,
        shadowColor: AppColors.getShadowColor(
          seedColor,
          modeProvider.currentMode,
        ).withOpacity(0.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppColors.getAppBarGradient(modeProvider.currentMode),
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        transitionBuilder: (Widget child, Animation<double> animation) {
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(animation);
          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: Container(
          key: ValueKey<int>(_selectedIndex),
          decoration: BoxDecoration(
            gradient: AppColors.getBodyGradient(modeProvider.currentMode),
          ),
          child: _pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: _buildResponsiveBottomNavBar(
        langProvider,
        modeProvider,
        currentLang,
        seedColor,
        isSmallScreen,
      ),
    );
  }

  Widget _buildResponsiveBottomNavBar(
    LanguageProvider langProvider,
    ModeProvider modeProvider,
    String currentLang,
    Color seedColor,
    bool isSmallScreen,
  ) {
    return Container(
      height: isSmallScreen ? 70 : 90, // ارتفاع أقل للشاشات الصغيرة
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.getSurfaceColor(
              modeProvider.currentMode,
            ).withOpacity(0.95),
            AppColors.getSurfaceColor(
              modeProvider.currentMode,
            ).withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 5,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildResponsiveNavItem(
            Icons.track_changes,
            Translations.getNavLabel(0, currentLang),
            1,
            seedColor,
            isSmallScreen,
          ),
          _buildResponsiveNavItem(
            Icons.warning_amber_rounded,
            Translations.getNavLabel(1, currentLang),
            2,
            seedColor,
            isSmallScreen,
          ),
          _buildResponsiveNavItem(
            Icons.line_axis,
            Translations.getNavLabel(2, currentLang),
            3,
            seedColor,
            isSmallScreen,
          ),
          _buildResponsiveHomeNavItem(seedColor, isSmallScreen), // Home icon in the center
          _buildResponsiveNavItem(
            Icons.flag_circle,
            Translations.getNavLabel(3, currentLang),
            4,
            seedColor,
            isSmallScreen,
          ),
          _buildResponsiveNavItem(
            Icons.sports,
            Translations.getNavLabel(4, currentLang),
            5,
            seedColor,
            isSmallScreen,
          ),
          _buildResponsiveNavItem(
            Icons.live_tv,
            Translations.getNavLabel(5, currentLang),
            6,
            seedColor,
            isSmallScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveHomeNavItem(Color seedColor, bool isSmallScreen) {
    final isSelected = _selectedIndex == 0; // Home is at index 0
    final modeProvider = Provider.of<ModeProvider>(context);

    return GestureDetector(
      onTap: () => _onItemTapped(0),
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, isSmallScreen ? -8 : -10), // ارتفاع أقل للشاشات الصغيرة
            child: Transform.scale(
              scale: _glowController.value,
              child: Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 12), // padding أصغر
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      isSelected
                          ? AppColors.getPrimaryColor(
                              seedColor,
                              modeProvider.currentMode,
                            )
                          : AppColors.getTertiaryColor(
                              seedColor,
                              modeProvider.currentMode,
                            ).withOpacity(0.8),
                      isSelected
                          ? AppColors.getTertiaryColor(
                              seedColor,
                              modeProvider.currentMode,
                            )
                          : AppColors.getSurfaceColor(
                              modeProvider.currentMode,
                            ).withOpacity(0.9),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? AppColors.getPrimaryColor(
                              seedColor,
                              modeProvider.currentMode,
                            ).withOpacity(0.4)
                          : Colors.black.withOpacity(0.2),
                      blurRadius: isSmallScreen ? 8 : 12, // ظل أصغر
                      spreadRadius: isSmallScreen ? 2 : 3, // انتشار أقل
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: isSelected
                        ? Colors.white
                        : AppColors.getPrimaryColor(
                            seedColor,
                            modeProvider.currentMode,
                          ).withOpacity(0.5),
                    width: isSmallScreen ? 1.5 : 2, // حدود أرق
                  ),
                ),
                child: Icon(
                  Icons.home,
                  size: isSmallScreen ? 28 : 36, // أيقونة أصغر للشاشات الصغيرة
                  color: isSelected
                      ? Colors.white
                      : AppColors.getPrimaryColor(
                          seedColor,
                          modeProvider.currentMode,
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResponsiveNavItem(
    IconData icon,
    String label,
    int index,
    Color seedColor,
    bool isSmallScreen,
  ) {
    final isSelected = _selectedIndex == index;
    final modeProvider = Provider.of<ModeProvider>(context);

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 8 : 12, 
          vertical: isSmallScreen ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.getPrimaryColor(
                  seedColor,
                  modeProvider.currentMode,
                ).withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.getPrimaryColor(
                      seedColor,
                      modeProvider.currentMode,
                    ).withOpacity(0.2),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _bubbleController,
              builder: (context, child) {
                return Transform.scale(
                  scale: isSelected ? 1.1 : 1.0,
                  child: Stack(
                    children: [
                      Icon(
                        icon,
                        size: isSmallScreen ? 22 : 28, // أيقونات أصغر
                        color: isSelected
                            ? AppColors.getPrimaryColor(
                                seedColor,
                                modeProvider.currentMode,
                              )
                            : AppColors.getTertiaryColor(
                                seedColor,
                                modeProvider.currentMode,
                              ).withOpacity(0.8),
                      ),
                      if (isSelected)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: ScaleTransition(
                            scale: _bubbleController,
                            child: Container(
                              width: isSmallScreen ? 6 : 8, // نقطة أصغر
                              height: isSmallScreen ? 6 : 8,
                              decoration: BoxDecoration(
                                color: AppColors.getPrimaryColor(
                                  seedColor,
                                  modeProvider.currentMode,
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            if (!isSmallScreen) // إخفاء النص على الشاشات الصغيرة
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 9 : 10, // خط أصغر
                  color: isSelected
                      ? AppColors.getPrimaryColor(
                          seedColor,
                          modeProvider.currentMode,
                        )
                      : AppColors.getTertiaryColor(
                          seedColor,
                          modeProvider.currentMode,
                        ).withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(
    BuildContext context,
    LanguageProvider langProvider,
    ModeProvider modeProvider,
    String currentLang,
  ) {
    final seedColor =
        AppColors.seedColors[modeProvider.currentMode] ??
        AppColors.seedColors[1]!;

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
                AppColors.getSurfaceColor(
                  modeProvider.currentMode,
                ).withOpacity(0.98),
                AppColors.getSurfaceColor(
                  modeProvider.currentMode,
                ).withOpacity(0.92),
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
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: AppColors.getTertiaryColor(
                      seedColor,
                      modeProvider.currentMode,
                    ).withOpacity(0.2),
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

  void _showModeDialog(
    BuildContext context,
    ModeProvider modeProvider,
    String currentLang,
  ) {
    final seedColor =
        AppColors.seedColors[modeProvider.currentMode] ??
        AppColors.seedColors[1]!;

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
                AppColors.getSurfaceColor(
                  modeProvider.currentMode,
                ).withOpacity(0.98),
                AppColors.getSurfaceColor(
                  modeProvider.currentMode,
                ).withOpacity(0.92),
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
              ...Translations.getModes(currentLang).asMap().entries.map((
                entry,
              ) {
                int index = entry.key;
                String modeName = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: AppColors.getTertiaryColor(
                      seedColor,
                      modeProvider.currentMode,
                    ).withOpacity(0.2),
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
}
