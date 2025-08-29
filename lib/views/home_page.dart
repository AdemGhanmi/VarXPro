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
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';



class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _glowController;

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
      lowerBound: 0.6,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
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
          icon: Icon(Icons.language, color: AppColors.getTertiaryColor(seedColor, modeProvider.currentMode)),
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.getSurfaceColor(modeProvider.currentMode),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Text(
                  Translations.getChooseLanguage(currentLang),
                  style: TextStyle(color: AppColors.getTextColor(modeProvider.currentMode)),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: Translations.getLanguages(currentLang).asMap().entries.map((entry) {
                    int idx = entry.key;
                    String lang = entry.value;
                    String code = idx == 0 ? 'en' : idx == 1 ? 'fr' : 'ar';
                    return ListTile(
                      title: Text(lang, style: TextStyle(color: AppColors.getTextColor(modeProvider.currentMode))),
                      onTap: () {
                        langProvider.changeLanguage(code);
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
        title: AnimatedBuilder(
          animation: _glowController,
          builder: (context, _) {
            return ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  AppColors.getTertiaryColor(seedColor, modeProvider.currentMode),
                  AppColors.getSecondaryColor(seedColor, modeProvider.currentMode),
                  AppColors.getTertiaryColor(seedColor, modeProvider.currentMode),
                ],
                stops: const [0.0, 0.5, 1.0],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ).createShader(bounds),
              child: Text(
                Translations.getTitle(_selectedIndex, currentLang),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.auto_awesome, color: AppColors.getTertiaryColor(seedColor, modeProvider.currentMode)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.getSurfaceColor(modeProvider.currentMode),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Text(
                    Translations.getChooseMode(currentLang),
                    style: TextStyle(color: AppColors.getTextColor(modeProvider.currentMode)),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: Translations.getModes(currentLang).asMap().entries.map((entry) {
                      int index = entry.key;
                      String modeName = entry.value;
                      return ListTile(
                        leading: Icon(_modes[index]["icon"], color: AppColors.getTextColor(modeProvider.currentMode)),
                        title: Text(
                          modeName,
                          style: TextStyle(color: AppColors.getTextColor(modeProvider.currentMode)),
                        ),
                        onTap: () {
                          Provider.of<ModeProvider>(context, listen: false).changeMode(index + 1);
                          Navigator.pop(ctx);
                        },
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppColors.getAppBarGradient(modeProvider.currentMode),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.getBodyGradient(modeProvider.currentMode)),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _glowController,
        builder: (context, _) {
          return CurvedNavigationBar(
            backgroundColor: Colors.transparent,
            color: AppColors.getSurfaceColor(modeProvider.currentMode),
            buttonBackgroundColor: AppColors.getSecondaryColor(seedColor, modeProvider.currentMode),
            animationCurve: Curves.easeInOut,
            height: 65,
            animationDuration: const Duration(milliseconds: 400),
            items: [
              _buildNavItem(Icons.track_changes, Translations.getNavLabel(0, currentLang), 0),
              _buildNavItem(Icons.warning_amber_rounded, Translations.getNavLabel(1, currentLang), 1),
              _buildNavItem(Icons.line_axis, Translations.getNavLabel(2, currentLang), 2),
              _buildNavItem(Icons.flag_circle, Translations.getNavLabel(3, currentLang), 3),
              _buildNavItem(Icons.sports, Translations.getNavLabel(4, currentLang), 4),
            ],
            onTap: _onItemTapped,
            index: _selectedIndex,
          );
        },
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    final modeProvider = Provider.of<ModeProvider>(context);
    final seedColor = AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 26,
          color: isSelected
              ? AppColors.getTertiaryColor(seedColor, modeProvider.currentMode)
              : AppColors.getTextColor(modeProvider.currentMode).withOpacity(0.8),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppColors.getTertiaryColor(seedColor, modeProvider.currentMode)
                : AppColors.getTextColor(modeProvider.currentMode).withOpacity(0.8),
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}