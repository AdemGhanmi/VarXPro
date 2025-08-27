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

  final List<String> _pageTitles = [
    'Player Tracking',
    'Fault Detection',
    'Field Lines',
    'Offside',
    'Referee Tracking',
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
    return Scaffold(
      backgroundColor: const Color(0xFF0A1B33),
      appBar: AppBar(
        title: AnimatedBuilder(
          animation: _glowController,
          builder: (context, _) {
            return ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFF11FFB2),
                  Color(0xFF4DC9FF),
                  Color(0xFF11FFB2),
                ],
                stops: [0.0, 0.5, 1.0],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ).createShader(bounds),
              child: Text(
                _pageTitles[_selectedIndex],
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  fontSize: 22,
                ),
              ),
            );
          },
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0D2B59),
                Color(0xFF1263A0),
              ],
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF071628),
              Color(0xFF0D2B59),
            ],
          ),
        ),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _glowController,
        builder: (context, _) {
          return CurvedNavigationBar(
            backgroundColor: Colors.transparent,
            color: const Color(0xFF0D2B59),
            buttonBackgroundColor: const Color(0xFF1AA3FF),
            animationCurve: Curves.easeInOut,
            height: 65,
            animationDuration: const Duration(milliseconds: 400),
            items: [
              _buildNavItem(Icons.track_changes, "Tracking", 0),
              _buildNavItem(Icons.warning_amber_rounded, "Faults", 1),
              _buildNavItem(Icons.line_axis, "Lines", 2),
              _buildNavItem(Icons.flag_circle, "Offside", 3),
              _buildNavItem(Icons.sports, "Referee", 4),
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

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 26,
          color: isSelected
              ? const Color(0xFF11FFB2)
              : Colors.white.withOpacity(0.8),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFF11FFB2)
                : Colors.white.withOpacity(0.8),
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}