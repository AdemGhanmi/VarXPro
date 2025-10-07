// lib/views/pages/home/view/details_arbiter/competitions_tab.dart (Updated with translations)
import 'package:flutter/material.dart';
import 'package:VarXPro/views/pages/home/model/home_model.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/lang/translation.dart';

class CompetitionsTab extends StatelessWidget {
  final Referee referee;
  final String currentLang;
  final Color textColor;
  final bool isLargeScreen;
  final AnimationController animationController;
  final ModeProvider modeProvider;
  final Color seedColor;

  const CompetitionsTab({
    super.key,
    required this.referee,
    required this.currentLang,
    required this.textColor,
    required this.isLargeScreen,
    required this.animationController,
    required this.modeProvider,
    required this.seedColor,
  });

  String _formatNumber(double value, bool isInt) {
    if (isInt) {
      return value.round().toString();
    } else {
      return value.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (referee.details?.worldfootball?.competitions != null) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: SingleChildScrollView(
          key: ValueKey(animationController.hashCode),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                Translations.getEvaluationText('recentCompetitions', currentLang),
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: isLargeScreen ? 20 : 18,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 450, 
                child: AnimatedBuilder(
                  animation: animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: animationController.value,
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isLargeScreen ? 2 : 1,
                          childAspectRatio: 1.4, 
                          crossAxisSpacing: 8, 
                          mainAxisSpacing: 8, 
                        ),
                        itemCount: referee.details!.worldfootball!.competitions.take(6).length, 
                        itemBuilder: (context, index) {
                          final comp = referee.details!.worldfootball!.competitions[index];
                          return AnimatedBuilder(
                            animation: animationController,
                            builder: (context, child) {
                              return GestureDetector(
                                onTapDown: (_) {
                                  animationController.reset();
                                  animationController.forward();
                                },
                                child: TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 200),
                                  tween: Tween(begin: 1.0, end: 0.95),
                                  builder: (context, scale, child) => Transform.scale(
                                    scale: scale,
                                    child: child,
                                  ),
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 300 + index * 150),
                                    curve: Curves.easeInOut,
                                    decoration: BoxDecoration(
                                      color: AppColors.getSurfaceColor(modeProvider.currentMode),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('${Translations.getEvaluationText('tappedOn', currentLang)} ${comp.name} 🎯')),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(12), 
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '🏅 ${comp.name}',
                                                    style: TextStyle(
                                                      color: textColor,
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: isLargeScreen ? 15 : 13, 
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: seedColor.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      '${Translations.getEvaluationText('totalCards', currentLang)}: ${comp.totals.yellow + comp.totals.red + comp.totals.secondYellow}',
                                                      style: TextStyle(
                                                        color: textColor.withOpacity(0.8),
                                                        fontSize: isLargeScreen ? 11 : 10, 
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 8), 
                                            Expanded(
                                              flex: 1,
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: _buildAnimatedMiniStat(
                                                      label: Translations.getEvaluationText('matches', currentLang),
                                                      targetValue: comp.totals.matches.toDouble(),
                                                      isInt: true,
                                                      icon: Icons.sports_soccer,
                                                      iconColor: Colors.green,
                                                      textColor: textColor,
                                                      animation: animationController,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: _buildAnimatedMiniStat(
                                                      label: Translations.getEvaluationText('yellow', currentLang),
                                                      targetValue: comp.totals.yellow.toDouble(),
                                                      isInt: true,
                                                      icon: Icons.warning_amber_rounded,
                                                      iconColor: Colors.orange,
                                                      textColor: textColor,
                                                      animation: animationController,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: _buildAnimatedMiniStat(
                                                      label: Translations.getEvaluationText('red', currentLang),
                                                      targetValue: (comp.totals.red + comp.totals.secondYellow).toDouble(),
                                                      isInt: true,
                                                      icon: Icons.block,
                                                      iconColor: Colors.red,
                                                      textColor: textColor,
                                                      animation: animationController,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4), 
                                              child: Column(
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: _buildAnimatedMiniStat(
                                                          label: '📈 YPG',
                                                          targetValue: comp.totals.yellowPerGame,
                                                          isInt: false,
                                                          icon: Icons.trending_up,
                                                          iconColor: Colors.blue,
                                                          textColor: textColor,
                                                          animation: animationController,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4), 
                                                  LinearProgressIndicator(
                                                    value: (comp.totals.yellowPerGame / 5).clamp(0.0, 1.0), 
                                                    backgroundColor: textColor.withOpacity(0.2),
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.withOpacity(0.7)),
                                                    minHeight: 3, 
                                                    borderRadius: BorderRadius.circular(2),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                },
              ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Center(child: Text(Translations.getEvaluationText('noCompetitionsAvailable', currentLang)));
    }
  }

  Widget _buildAnimatedMiniStat({
    required String label,
    required double targetValue,
    required bool isInt,
    required IconData icon,
    required Color iconColor,
    required Color textColor,
    required Animation<double> animation,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final currentValue = targetValue * animation.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor), 
            const SizedBox(height: 2), 
            Text(
              _formatNumber(currentValue, isInt),
              style: TextStyle(
                color: textColor,
                fontSize: 11, 
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style: TextStyle(
                color: textColor.withOpacity(0.7),
                fontSize: 9, 
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }
}
