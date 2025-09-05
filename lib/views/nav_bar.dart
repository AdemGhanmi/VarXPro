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
    final seedColor = AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(modeProvider.currentMode),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.language, 
                     color: Colors.white, 
                     size: 28),
          onPressed: () {
            _showLanguageDialog(context, langProvider, modeProvider, currentLang);
          },
        ),
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Text(
            Translations.getTitle(_selectedIndex, currentLang),
            key: ValueKey<String>(Translations.getTitle(_selectedIndex, currentLang)),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 24,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.auto_awesome, 
                       color: Colors.white, 
                       size: 28),
            onPressed: () {
              _showModeDialog(context, modeProvider, currentLang);},
            ),
        ],
        backgroundColor: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode),
        elevation: 4,
        shadowColor: AppColors.getShadowColor(seedColor, modeProvider.currentMode).withOpacity(0.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
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
      bottomNavigationBar: _buildModernBottomNavBar(langProvider, modeProvider, currentLang, seedColor),
    );
  }

  Widget _buildModernBottomNavBar(LanguageProvider langProvider, ModeProvider modeProvider, 
                           String currentLang, Color seedColor) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(modeProvider.currentMode),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildModernNavItem(Icons.track_changes, Translations.getNavLabel(0, currentLang), 0),
          _buildModernNavItem(Icons.warning_amber_rounded, Translations.getNavLabel(1, currentLang), 1),
          _buildModernNavItem(Icons.line_axis, Translations.getNavLabel(2, currentLang), 2),
          _buildModernNavItem(Icons.flag_circle, Translations.getNavLabel(3, currentLang), 3),
          _buildModernNavItem(Icons.sports, Translations.getNavLabel(4, currentLang), 4),
          _buildModernNavItem(Icons.live_tv, Translations.getNavLabel(5, currentLang), 5),
        ],
      ),
    );
  }

  Widget _buildModernNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    final modeProvider = Provider.of<ModeProvider>(context);
    final seedColor = AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode).withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode).withOpacity(0.3),
                  width: 1,
                ),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: isSelected
                      ? AppColors.getPrimaryColor(seedColor, modeProvider.currentMode)
                      : AppColors.getTextColor(modeProvider.currentMode).withOpacity(0.6),
                ),
                if (isSelected)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: ScaleTransition(
                      scale: _bubbleController,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.getPrimaryColor(seedColor, modeProvider.currentMode)
                    : AppColors.getTextColor(modeProvider.currentMode).withOpacity(0.6),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, LanguageProvider langProvider, 
                          ModeProvider modeProvider, String currentLang) {
    final seedColor = AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!;

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
                    tileColor: AppColors.getTertiaryColor(seedColor, modeProvider.currentMode).withOpacity(0.2),
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
    final seedColor = AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!;

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
                    tileColor: AppColors.getTertiaryColor(seedColor, modeProvider.currentMode).withOpacity(0.2),
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