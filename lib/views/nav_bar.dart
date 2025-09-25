// Updated file: lib/views/nav_bar.dart
import 'package:VarXPro/views/setting/provider/history_provider.dart';
import 'package:VarXPro/views/setting/views/settings_page.dart';
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
      create: (context) => RefereeService(),
      child: const RefereeTrackingSystemPage(),
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
      create: (context) => TrackingService(),
      child: const EnhancedSoccerPlayerTrackingAndGoalAnalysisPage(),
    ),
    RepositoryProvider(
      create: (context) => LiveStreamController(),
      child: const LiveStreamDashboard(),
    ),
  ];

  final List<Map<String, dynamic>> _modes = [
    {"name": "Classic Mode", "emoji": "⚽", "color": Colors.green},
    {"name": "Light Mode", "emoji": "☀️", "color": Colors.yellow},
    {"name": "Pro Analysis Mode", "emoji": "📊", "color": Colors.blue},
    {"name": "VAR Vision Mode", "emoji": "📹", "color": Colors.purple},
    {"name": "Referee Mode", "emoji": "👨‍⚖️", "color": Colors.red},
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
    final historyProvider = Provider.of<HistoryProvider>(context); // Add this
    final currentLang = langProvider.currentLanguage;
    final seedColor =
        AppColors.seedColors[modeProvider.currentMode] ??
        AppColors.seedColors[1]!;

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final isLightMode = modeProvider.currentMode == 1; // Assuming index 1 is Light Mode

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(modeProvider.currentMode),
      appBar: AppBar(
        // Removed leading language button
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
          // Settings button with badge
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.settings, color: Colors.white, size: isSmallScreen ? 24 : 28),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SettingsPage(
                        langProvider: langProvider,
                        modeProvider: modeProvider,
                        currentLang: currentLang ?? 'en',
                      ),
                    ),
                  );
                },
              ),
              if (historyProvider.historyCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${historyProvider.historyCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
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
        isLightMode,
      ),
    );
  }

  Widget _buildResponsiveBottomNavBar(
    LanguageProvider langProvider,
    ModeProvider modeProvider,
    String currentLang,
    Color seedColor,
    bool isSmallScreen,
    bool isLightMode,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Dynamic navbar height based on screen size
    final navBarHeight = screenWidth < 360 ? 60.0 : screenWidth < 600 ? 70.0 : 80.0;
    // Dynamic icon size based on screen width
    final iconSize = screenWidth < 360 ? 20.0 : screenWidth < 600 ? 24.0 : 28.0;
    // Dynamic padding for navbar items
    final itemPadding = screenWidth < 360 ? 6.0 : screenWidth < 600 ? 8.0 : 10.0;

    return SafeArea(
      child: Container(
        height: navBarHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.95),
              AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.8),
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
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Use spaceEvenly to prevent overflow
          children: [
            _buildResponsiveNavItem(
              "⚽",
              Translations.getNavLabel(4, currentLang),
              1,
              seedColor,
              isSmallScreen,
              iconSize,
              itemPadding,
              isLightMode,
            ),
            _buildResponsiveNavItem(
              "⚠️",
              Translations.getNavLabel(1, currentLang),
              2,
              seedColor,
              isSmallScreen,
              iconSize,
              itemPadding,
              isLightMode,
            ),
            _buildResponsiveNavItem(
              "📏",
              Translations.getNavLabel(2, currentLang),
              3,
              seedColor,
              isSmallScreen,
              iconSize,
              itemPadding,
              isLightMode,
            ),
            _buildResponsiveHomeNavItem(seedColor, isSmallScreen, iconSize, itemPadding, isLightMode),
            _buildResponsiveNavItem(
              "🚩",
              Translations.getNavLabel(3, currentLang),
              4,
              seedColor,
              isSmallScreen,
              iconSize,
              itemPadding,
              isLightMode,
            ),
            _buildResponsiveNavItem(
              "📈",
              Translations.getNavLabel(0, currentLang),
              5,
              seedColor,
              isSmallScreen,
              iconSize,
              itemPadding,
              isLightMode,
            ),
            _buildResponsiveNavItem(
              "📺",
              Translations.getNavLabel(5, currentLang),
              6,
              seedColor,
              isSmallScreen,
              iconSize,
              itemPadding,
              isLightMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveHomeNavItem(
    Color seedColor,
    bool isSmallScreen,
    double iconSize,
    double itemPadding,
    bool isLightMode,
  ) {
    final isSelected = _selectedIndex == 0;
    final modeProvider = Provider.of<ModeProvider>(context);

    // Adjusted text/icon color for light mode visibility
    Color textColor = isLightMode
        ? (isSelected ? Colors.black : Colors.grey[800]!)
        : (isSelected
            ? Colors.white
            : AppColors.getPrimaryColor(seedColor, modeProvider.currentMode));

    return GestureDetector(
      onTap: () => _onItemTapped(0),
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, isSmallScreen ? -6 : -8), // Adjusted for better alignment
            child: Transform.scale(
              scale: _glowController.value,
              child: Container(
                padding: EdgeInsets.all(itemPadding),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      isSelected
                          ? AppColors.getPrimaryColor(seedColor, modeProvider.currentMode)
                          : AppColors.getTertiaryColor(seedColor, modeProvider.currentMode)
                              .withOpacity(0.8),
                      isSelected
                          ? AppColors.getTertiaryColor(seedColor, modeProvider.currentMode)
                          : AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.9),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? AppColors.getPrimaryColor(seedColor, modeProvider.currentMode)
                              .withOpacity(0.4)
                          : Colors.black.withOpacity(0.2),
                      blurRadius: isSmallScreen ? 6 : 8,
                      spreadRadius: isSmallScreen ? 1 : 2,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: isSelected
                        ? Colors.white
                        : AppColors.getPrimaryColor(seedColor, modeProvider.currentMode)
                            .withOpacity(0.5),
                    width: isSmallScreen ? 1.0 : 1.5,
                  ),
                ),
                child: Icon(
                  Icons.home,
                  size: iconSize,
                  color: textColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResponsiveNavItem(
    String emojiIcon, // Changed to String for emoji
    String label,
    int index,
    Color seedColor,
    bool isSmallScreen,
    double iconSize,
    double itemPadding,
    bool isLightMode,
  ) {
    final isSelected = _selectedIndex == index;
    final modeProvider = Provider.of<ModeProvider>(context);

    // Adjusted text/icon color for light mode visibility
    Color iconTextColor = isLightMode
        ? (isSelected ? Colors.black : Colors.grey[700]!)
        : (isSelected
            ? AppColors.getPrimaryColor(seedColor, modeProvider.currentMode)
            : AppColors.getTertiaryColor(seedColor, modeProvider.currentMode)
                .withOpacity(0.8));

    Color labelColor = isLightMode
        ? (isSelected ? Colors.black : Colors.grey[600]!)
        : (isSelected
            ? AppColors.getPrimaryColor(seedColor, modeProvider.currentMode)
            : AppColors.getTertiaryColor(seedColor, modeProvider.currentMode)
                .withOpacity(0.8));

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Tooltip(
        message: label, // Show label as tooltip on small screens
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(
            horizontal: itemPadding,
            vertical: itemPadding / 1.5, // Reduced vertical padding for better alignment
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.getPrimaryColor(seedColor, modeProvider.currentMode).withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode)
                          .withOpacity(0.2),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _bubbleController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: isSelected ? 1.1 : 1.0,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          emojiIcon,
                          style: TextStyle(
                            fontSize: iconSize,
                            fontWeight: FontWeight.bold,
                            color: iconTextColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (isSelected)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: ScaleTransition(
                              scale: _bubbleController,
                              child: Container(
                                width: isSmallScreen ? 5 : 6,
                                height: isSmallScreen ? 5 : 6,
                                decoration: BoxDecoration(
                                  color: AppColors.getPrimaryColor(
                                      seedColor, modeProvider.currentMode),
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
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 8 : 9,
                    color: labelColor,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
}