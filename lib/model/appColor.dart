import 'package:flutter/material.dart';

class AppColors {
  static const Map<int, Color> seedColors = {
    1: Color(0xFF0D47A1), 
    2: Color(0xFF26A69A), 
    3: Color(0xFF00695C), 
    4: Color(0xFF512DA8),
    5: Color(0xFFFF5722),
  };

  static const Color onPrimaryColor = Colors.white;
  static const Color onSecondaryColor = Colors.white;
  static const Color onBackgroundColor = Colors.white;
  static const Color onSurfaceColor = Colors.white;

  static Color getPrimaryColor(Color seedColor, int mode) {
    switch (mode) {
      case 2: return Colors.teal[700]!;
      case 3: return Colors.cyan[800]!;
      case 4: return Colors.purple[700]!;
      case 5: return Colors.orange[800]!;
      default: return seedColor;
    }
  }

  static Color getSecondaryColor(Color seedColor, int mode) {
    switch (mode) {
      case 2: return Colors.teal[300]!;
      case 3: return Colors.cyan[400]!;
      case 4: return Colors.purple[300]!;
      case 5: return Colors.orange[400]!;
      default: return Color.lerp(seedColor, Colors.blue, 0.3)!;
    }
  }

  static Color getTertiaryColor(Color seedColor, int mode) {
    switch (mode) {
      case 2: return Colors.teal[100]!;
      case 3: return Colors.cyan[100]!;
      case 4: return Colors.purple[100]!;
      case 5: return Colors.orange[100]!;
      default: return Color.lerp(seedColor, Colors.cyan, 0.5)!;
    }
  }

  static Color getShadowColor(Color seedColor, int mode) {
    switch (mode) {
      case 2: return Colors.teal[200]!.withOpacity(0.2);
      case 3: return Colors.cyan[200]!.withOpacity(0.2);
      case 4: return Colors.purple[200]!.withOpacity(0.2);
      case 5: return Colors.orange[200]!.withOpacity(0.2);
      default: return Color.lerp(seedColor, Colors.blue, 0.3)!.withOpacity(0.2);
    }
  }

  static Color getDividerColor(Color seedColor, int mode) {
    switch (mode) {
      case 2: return Colors.teal[100]!.withOpacity(0.1);
      case 3: return Colors.cyan[100]!.withOpacity(0.1);
      case 4: return Colors.purple[100]!.withOpacity(0.1);
      case 5: return Colors.orange[100]!.withOpacity(0.1);
      default: return Color.lerp(seedColor, Colors.blue, 0.3)!.withOpacity(0.1);
    }
  }

  static Color getLabelColor(Color seedColor, int mode) {
    switch (mode) {
      case 2: return Colors.teal[400]!;
      case 3: return Colors.cyan[400]!;
      case 4: return Colors.purple[400]!;
      case 5: return Colors.orange[400]!;
      default: return Color.lerp(seedColor, Colors.blue, 0.3)!;
    }
  }

  static Color getBackgroundColor(int mode) {
    switch (mode) {
      case 2: return Colors.grey[50]!;
      case 3: return Colors.grey[850]!;
      case 4: return Colors.black87;
      case 5: return Colors.grey[900]!;
      default: return const Color(0xFF0A1B33);
    }
  }

  static Color getSurfaceColor(int mode) {
    switch (mode) {
      case 2: return Colors.white;
      case 3: return Colors.grey[800]!;
      case 4: return Colors.grey[850]!;
      case 5: return Colors.grey[850]!;
      default: return const Color(0xFF0D2B59);
    }
  }

  static Color getTextColor(int mode) {
    switch (mode) {
      case 2: return Colors.black;
      default: return Colors.white;
    }
  }

  static Brightness getBrightness(int mode) {
    switch (mode) {
      case 2: return Brightness.light;
      default: return Brightness.dark;
    }
  }

  static LinearGradient getAppBarGradient(int mode) {
    switch (mode) {
      case 2:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.teal[700]!, Colors.teal[500]!],
        );
      case 3:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.cyan[800]!, Colors.cyan[600]!],
        );
      case 4:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.purple[700]!, Colors.purple[500]!],
        );
      case 5:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.orange[800]!, Colors.orange[600]!],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2B59), Color(0xFF0D47A1)],
        );
    }
  }

  static LinearGradient getBodyGradient(int mode) {
    final baseColor = seedColors[mode] ?? seedColors[1]!;
    final bgColor = getBackgroundColor(mode);
    final subtleTop = Color.lerp(bgColor, baseColor, 0.02)!;
    final subtleMid = Color.lerp(bgColor, baseColor, 0.08)!;
    final subtleBottom = Color.lerp(bgColor, baseColor, 0.04)!;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [subtleTop, subtleMid, subtleBottom],
      stops: const [0.0, 0.6, 1.0],
    );
  }
}