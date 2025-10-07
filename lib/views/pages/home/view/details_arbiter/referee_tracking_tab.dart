// lib/views/pages/home/view/details_arbiter/referee_tracking_tab.dart (Updated with translations)
import 'package:flutter/material.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:VarXPro/views/pages/RefereeTraking/service/referee_api_service.dart';
import 'package:VarXPro/views/pages/RefereeTraking/view/referee_tracking.dart';
import 'package:VarXPro/views/connexion/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:VarXPro/lang/translation.dart';

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
    final authProvider = Provider.of<AuthProvider>(context);
    final role = authProvider.user?.role ?? 'visitor';
    final isViewer = role == 'visitor' || role == 'user';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: SingleChildScrollView(
        key: ValueKey(animationController.hashCode),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('👨‍⚖️ ', style: TextStyle(fontSize: 24)),
                Text(
                  Translations.getEvaluationText('refereeTracking', currentLang),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: isLargeScreen ? 20 : 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.9),
                    AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: seedColor.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.track_changes,
                          size: 64,
                          color: seedColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          Translations.getEvaluationText('advancedRefereeTrackingSystem', currentLang),
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isSupervisor
                              ? Translations.getEvaluationText('fullAccessDescription', currentLang)
                              : Translations.getEvaluationText('viewerModeDescription', currentLang),
                          style: TextStyle(
                            color: textColor.withOpacity(0.8),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  // Features Section
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Translations.getEvaluationText('keyFeatures', currentLang),
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureItem(
                          icon: Icons.video_camera_back,
                          title: Translations.getEvaluationText('videoUpload', currentLang),
                          description: isSupervisor ? Translations.getEvaluationText('uploadMatchFootage', currentLang) : Translations.getEvaluationText('viewUploadedVideos', currentLang),
                          color: Colors.blue,
                          textColor: textColor,
                        ),
                        _buildFeatureItem(
                          icon: Icons.analytics,
                          title: Translations.getEvaluationText('aiInsights', currentLang),
                          description: isSupervisor ? Translations.getEvaluationText('generateReports', currentLang) : Translations.getEvaluationText('accessSummaries', currentLang),
                          color: Colors.green,
                          textColor: textColor,
                        ),
                        _buildFeatureItem(
                          icon: Icons.trending_up,
                          title: Translations.getEvaluationText('performanceMetrics', currentLang),
                          description: isSupervisor ? Translations.getEvaluationText('trackStats', currentLang) : Translations.getEvaluationText('viewMetrics', currentLang),
                          color: Colors.purple,
                          textColor: textColor,
                        ),
                        const SizedBox(height: 24),
                        // Action Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RepositoryProvider(
                                    create: (context) => RefereeService(),
                                    child: const RefereeTrackingSystemPage(),
                                  ),
                                ),
                              );
                            },
                            icon: Icon(isSupervisor ? Icons.play_arrow : Icons.visibility),
                            label: Text(
                              isSupervisor ? Translations.getEvaluationText('launchFullSystem', currentLang) : Translations.getEvaluationText('enterViewerMode', currentLang),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: seedColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              shadowColor: seedColor.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: textColor.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
