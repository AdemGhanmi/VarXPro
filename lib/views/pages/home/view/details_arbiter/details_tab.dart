// lib/views/pages/home/view/details_arbiter/details_tab.dart
import 'package:flutter/material.dart';
import 'package:VarXPro/views/pages/home/model/home_model.dart';
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';

class DetailsTab extends StatelessWidget {
  final Referee referee;
  final String currentLang;
  final Color textColor;
  final bool isLargeScreen;
  final AnimationController animationController;

  const DetailsTab({
    super.key,
    required this.referee,
    required this.currentLang,
    required this.textColor,
    required this.isLargeScreen,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${Translations.getRefereeDetailsText('details', currentLang)} ℹ️',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: isLargeScreen ? 20 : 18,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            emoji: '🏆',
            label: Translations.getRefereeDetailsText('confederation', currentLang),
            value: referee.confed ?? Translations.getRefereeDetailsText('na', currentLang),
            textColor: textColor,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            emoji: '📅',
            label: Translations.getRefereeDetailsText('since', currentLang),
            value: referee.since?.toString() ?? Translations.getRefereeDetailsText('na', currentLang),
            textColor: textColor,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            emoji: referee.gender == 'Male' ? '♂️' : '♀️',
            label: Translations.getRefereeDetailsText('gender', currentLang),
            value: referee.gender ?? Translations.getRefereeDetailsText('na', currentLang),
            textColor: textColor,
          ),
          const SizedBox(height: 12),
          Text(
            '${Translations.getRefereeDetailsText('roles', currentLang)} 🎭',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: isLargeScreen ? 18 : 16,
            ),
          ),
          const SizedBox(height: 8),
          if (referee.roles.isNotEmpty)
            AnimatedBuilder(
              animation: animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: animationController.value,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: referee.roles
                        .map(
                          (role) => Chip(
                            avatar: Text(_getRoleEmoji(role)),
                            label: Text(
                              role,
                              style: TextStyle(
                                color: _getRoleColor(role),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            backgroundColor: _getRoleColor(role).withOpacity(0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                );
              },
            )
          else
            Text(
              Translations.getRefereeDetailsText('noRolesSpecified', currentLang),
              style: TextStyle(
                color: textColor.withOpacity(0.6),
                fontSize: isLargeScreen ? 16 : 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String emoji,
    required String label,
    required String value,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 4),
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 4),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontSize: 16,
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

  String _getRoleEmoji(String role) {
    switch (role.toLowerCase()) {
      case 'var':
        return '📹';
      case 'referee':
        return '👨‍⚖️';
      case 'assistant':
        return '👥';
      case 'reviewer':
        return '🔍';
      default:
        return '⚽';
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'var':
        return Colors.purpleAccent;
      case 'referee':
        return Colors.blueAccent;
      case 'assistant':
        return Colors.greenAccent;
      case 'reviewer':
        return Colors.orangeAccent;
      default:
        return Colors.grey;
    }
  }
}
