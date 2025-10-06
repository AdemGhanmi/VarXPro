// lib/views/pages/home/view/statistics_tab.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:VarXPro/views/pages/home/model/home_model.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/modeprovider.dart';

class StatisticsTab extends StatelessWidget {
  final Referee referee;
  final String currentLang;
  final Color textColor;
  final bool isLargeScreen;
  final AnimationController animationController;
  final ModeProvider modeProvider;
  final Color seedColor;

  const StatisticsTab({
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
    if (referee
            .details
            ?.worldfootball
            ?.overallTotals !=
        null) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: SingleChildScrollView(
          key: ValueKey(animationController.hashCode),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              AnimatedContainer(
                duration: const Duration(
                  milliseconds: 600,
                ),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: AppColors.getSurfaceColor(
                    modeProvider.currentMode,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                        0.1,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(
                        milliseconds: 400,
                      ),
                      child: Row(
                        key: ValueKey(
                          'stats_row_${animationController.hashCode}',
                        ),
                        mainAxisAlignment:
                            MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildAnimatedStatCard(
                            label: '⚽ Matches',
                            targetValue: referee
                                .details!
                                .worldfootball!
                                .overallTotals!
                                .matches
                                .toDouble(),
                            isInt: true,
                            icon: Icons.sports_soccer,
                            iconColor: Colors.green,
                            textColor: textColor,
                            animation:
                                animationController,
                          ),
                          _buildAnimatedStatCard(
                            label: '🟨 Yellow Cards',
                            targetValue: referee
                                .details!
                                .worldfootball!
                                .overallTotals!
                                .yellow
                                .toDouble(),
                            isInt: true,
                            icon: Icons
                                .warning_amber_rounded,
                            iconColor: Colors.orange,
                            textColor: textColor,
                            animation:
                                animationController,
                          ),
                          _buildAnimatedStatCard(
                            label: '🔴 Red Cards',
                            targetValue: referee
                                .details!
                                .worldfootball!
                                .overallTotals!
                                .red
                                .toDouble(),
                            isInt: true,
                            icon: Icons.block,
                            iconColor: Colors.red,
                            textColor: textColor,
                            animation:
                                animationController,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildAnimatedStatCard(
                      label: '📈 Yellow per Game',
                      targetValue: referee
                          .details!
                          .worldfootball!
                          .overallTotals!
                          .yellowPerGame,
                      isInt: false,
                      icon: Icons.trending_up,
                      iconColor: Colors.blue,
                      textColor: textColor,
                      animation: animationController,
                      isFullWidth: true,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: AnimatedBuilder(
                        animation: animationController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale:
                                0.9 +
                                0.1 *
                                    animationController
                                        .value,
                            child: AnimatedOpacity(
                              opacity:
                                  animationController
                                      .value,
                              duration: const Duration(
                                milliseconds: 500,
                              ),
                              child: PieChart(
                                PieChartData(
                                  pieTouchData: PieTouchData(
                                    touchCallback:
                                        (
                                          FlTouchEvent
                                          event,
                                          pieTouchResponse,
                                        ) {},
                                  ),
                                  borderData:
                                      FlBorderData(
                                        show: false,
                                      ),
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 40,
                                  sections:
                                      _getPieChartSections(
                                        referee
                                            .details!
                                            .worldfootball!
                                            .overallTotals!,
                                        textColor,
                                      ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 250,
                      child: AnimatedBuilder(
                        animation: animationController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle:
                                animationController
                                    .value *
                                0.1,
                            child: AnimatedOpacity(
                              opacity:
                                  animationController
                                      .value,
                              duration: const Duration(
                                milliseconds: 700,
                              ),
                              child: RadarChart(
                                RadarChartData(
                                  radarShape:
                                      RadarShape.circle,
                                  dataSets:
                                      _getRadarDataSets(
                                        referee
                                            .details!
                                            .worldfootball!
                                            .overallTotals!,
                                        textColor,
                                      ),
                                  radarBorderData:
                                      BorderSide(
                                        color: textColor
                                            .withOpacity(
                                              0.3,
                                            ),
                                      ),
                                  tickCount: 5,
                                  ticksTextStyle:
                                      TextStyle(
                                        color: textColor
                                            .withOpacity(
                                              0.5,
                                            ),
                                        fontSize: 10,
                                      ),
                                  tickBorderData:
                                      BorderSide(
                                        color: textColor
                                            .withOpacity(
                                              0.3,
                                            ),
                                      ),
                                  gridBorderData:
                                      BorderSide(
                                        color: textColor
                                            .withOpacity(
                                              0.2,
                                            ),
                                      ),
                                  getTitle: (index, angle) {
                                    final titles = [
                                      'Matches',
                                      'Yellows',
                                      'Reds',
                                      'YPG*10',
                                    ];
                                    return RadarChartTitle(
                                      text:
                                          titles[index %
                                              titles
                                                  .length],
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return const Center(
        child: Text('No statistics available 😔'),
      );
    }
  }

  Widget _buildAnimatedStatCard({
    required String label,
    required double targetValue,
    required bool isInt,
    required IconData icon,
    required Color iconColor,
    required Color textColor,
    required Animation<double> animation,
    bool isFullWidth = false,
  }) {
    final container = AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final currentValue = targetValue * animation.value;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(height: 4),
              Text(
                _formatNumber(currentValue, isInt),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: textColor,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
    if (isFullWidth) {
      return container;
    } else {
      return Expanded(child: container);
    }
  }

  List<PieChartSectionData> _getPieChartSections(
    OverallTotals totals,
    Color textColor,
  ) {
    final totalCards = totals.yellow + totals.red;
    if (totalCards == 0) {
      return [PieChartSectionData(color: Colors.grey, value: 1, radius: 60)];
    }
    return [
      PieChartSectionData(
        color: Colors.orange,
        value: totals.yellow.toDouble(),
        title: '${totals.yellow}',
        radius: 60,
        titleStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
      PieChartSectionData(
        color: Colors.red,
        value: totals.red.toDouble(),
        title: '${totals.red}',
        radius: 60,
        titleStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    ];
  }

  List<RadarDataSet> _getRadarDataSets(OverallTotals totals, Color textColor) {
    final values = [
      totals.matches.toDouble(),
      totals.yellow.toDouble(),
      totals.red.toDouble(),
      totals.yellowPerGame * 10,
    ];
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return [
      RadarDataSet(
        fillColor: Colors.blue.withOpacity(0.2),
        borderColor: Colors.blue,
        dataEntries: values
            .map((v) => RadarEntry(value: v / maxValue * 100))
            .toList(),
        borderWidth: 2,
        entryRadius: 4,
      ),
    ];
  }
}
