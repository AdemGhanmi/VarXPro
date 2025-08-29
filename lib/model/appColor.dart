import 'package:flutter/material.dart';

class AppColors {
  static const Map<int, Color> seedColors = {
    1: Color(0xFF1263A0), // Classic Mode (Blue)
    2: Color(0xFF4CAF50), // Light Mode (Green)
    3: Color(0xFF0288D1), // Pro Analysis Mode (Cyan)
    4: Color(0xFF8E24AA), // VAR Vision Mode (Purple)
    5: Color(0xFFFFA000), // Referee Mode (Yellow)
  };

  static const Color onPrimaryColor = Colors.white;
  static const Color onSecondaryColor = Colors.white;
  static const Color onBackgroundColor = Colors.white;
  static const Color onSurfaceColor = Colors.white;

  static Color getPrimaryColor(Color seedColor, int mode) {
    switch (mode) {
      case 2: return Colors.green[700]!;
      case 3: return Colors.cyan[800]!;
      case 4: return Colors.purple[700]!;
      case 5: return Colors.yellow[800]!;
      default: return seedColor;
    }
  }

  static Color getSecondaryColor(Color seedColor, int mode) {
    switch (mode) {
      case 2: return Colors.green[300]!;
      case 3: return Colors.cyan[400]!;
      case 4: return Colors.purple[300]!;
      case 5: return Colors.yellow[400]!;
      default: return Color.lerp(seedColor, Colors.blue, 0.5)!;
    }
  }

  static Color getTertiaryColor(Color seedColor, int mode) {
    switch (mode) {
      case 2: return Colors.green[100]!;
      case 3: return Colors.cyan[100]!;
      case 4: return Colors.purple[100]!;
      case 5: return Colors.yellow[100]!;
      default: return Color.lerp(seedColor, Colors.cyan, 0.7)!;
    }
  }

  static Color getShadowColor(Color seedColor, int mode) {
    switch (mode) {
      case 2: return Colors.green[200]!.withOpacity(0.3);
      case 3: return Colors.cyan[200]!.withOpacity(0.3);
      case 4: return Colors.purple[200]!.withOpacity(0.3);
      case 5: return Colors.yellow[200]!.withOpacity(0.3);
      default: return Color.lerp(seedColor, Colors.greenAccent, 0.5)!.withOpacity(0.3);
    }
  }

  static Color getDividerColor(Color seedColor, int mode) {
    switch (mode) {
      case 2: return Colors.green[100]!.withOpacity(0.2);
      case 3: return Colors.cyan[100]!.withOpacity(0.2);
      case 4: return Colors.purple[100]!.withOpacity(0.2);
      case 5: return Colors.yellow[100]!.withOpacity(0.2);
      default: return Color.lerp(seedColor, Colors.greenAccent, 0.5)!.withOpacity(0.2);
    }
  }

  static Color getLabelColor(Color seedColor, int mode) {
    switch (mode) {
      case 2: return Colors.green[300]!;
      case 3: return Colors.cyan[300]!;
      case 4: return Colors.purple[300]!;
      case 5: return Colors.yellow[300]!;
      default: return Color.lerp(seedColor, Colors.greenAccent, 0.5)!;
    }
  }

  static Color getBackgroundColor(int mode) {
    switch (mode) {
      case 2: return Colors.grey[100]!;
      case 3: return Colors.grey[800]!;
      case 4: return Colors.black87;
      case 5: return Colors.grey[900]!;
      default: return const Color(0xFF0A1B33);
    }
  }

  static Color getSurfaceColor(int mode) {
    switch (mode) {
      case 2: return Colors.white;
      case 3: return Colors.grey[700]!;
      case 4: return Colors.grey[800]!;
      case 5: return Colors.grey[800]!;
      default: return const Color(0xFF0D2B59);
    }
  }

  static Color getTextColor(int mode) {
    switch (mode) {
      case 2: return Colors.black87;
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
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green, Colors.greenAccent],
        );
      case 3:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.cyan, Colors.blueGrey],
        );
      case 4:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.purple, Colors.blue],
        );
      case 5:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.yellow, Colors.grey],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2B59), Color(0xFF1263A0)],
        );
    }
  }

  static LinearGradient getBodyGradient(int mode) {
    switch (mode) {
      case 2:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.grey],
        );
      case 3:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blueGrey, Colors.grey],
        );
      case 4:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.grey],
        );
      case 5:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey, Colors.black],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF071628), Color(0xFF0D2B59)],
        );
    }
  }
}
