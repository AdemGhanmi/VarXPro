// Updated file: lib/views/pages/home/view/referee_tracking_tab.dart
import 'package:flutter/material.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:VarXPro/views/pages/RefereeTraking/service/referee_api_service.dart';
import 'package:VarXPro/views/pages/RefereeTraking/view/referee_tracking.dart';
import 'package:VarXPro/views/connexion/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class RefereeTrackingTab extends StatelessWidget {
  final String currentLang;
  final Color textColor;
  final bool isLargeScreen;
  final AnimationController animationController;
  final ModeProvider modeProvider;
  final Color seedColor;
  final bool isSupervisor;

  const RefereeTrackingTab({
    super.key,
    required this.currentLang,
    required this.textColor,
    required this.isLargeScreen,
    required this.animationController,
    required this.modeProvider,
    required this.seedColor,
    required this.isSupervisor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: SingleChildScrollView(
        key: ValueKey(animationController.hashCode),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              '👨‍⚖️ Referee Tracking',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: isLargeScreen ? 20 : 18,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: AppColors.getSurfaceColor(
                modeProvider.currentMode,
              ).withOpacity(0.8),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.track_changes,
                      size: 80,
                      color: seedColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Launch Referee Tracking System',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Analyze referee performance with video upload and AI insights.',
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isSupervisor
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RepositoryProvider(
                                      create: (context) => RefereeService(),
                                      child: const RefereeTrackingSystemPage(),
                                    ),
                                  ),
                                );
                              }
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Only supervisors can start tracking.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              },
                        icon: Icon(isSupervisor ? Icons.play_arrow : Icons.lock),
                        label: Text(isSupervisor ? 'Start Tracking' : 'Viewer Mode'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSupervisor ? seedColor : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
