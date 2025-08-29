import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/views/splash_screen.dart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'model/appcolor.dart';
import 'provider/modeprovider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ModeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer2<ModeProvider, LanguageProvider>(
        builder: (context, modeProvider, languageProvider, child) {
          final seedColor = AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!;
          return MaterialApp(
            title: 'VAR X Pro',
            theme: ThemeData(
              primaryColor: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode),
              colorScheme: ColorScheme.fromSeed(
                seedColor: seedColor,
                primary: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode),
                secondary: AppColors.getSecondaryColor(seedColor, modeProvider.currentMode),
                tertiary: AppColors.getTertiaryColor(seedColor, modeProvider.currentMode),
                background: AppColors.getBackgroundColor(modeProvider.currentMode),
                surface: AppColors.getSurfaceColor(modeProvider.currentMode),
                onPrimary: AppColors.onPrimaryColor,
                onSecondary: AppColors.onSecondaryColor,
                onBackground: AppColors.onBackgroundColor,
                onSurface: AppColors.onSurfaceColor,
                brightness: AppColors.getBrightness(modeProvider.currentMode),
              ),
              useMaterial3: true,
              fontFamily: 'Poppins',
              textTheme: TextTheme(
                displayLarge: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.getTextColor(modeProvider.currentMode),
                  letterSpacing: 1.2,
                ),
                displayMedium: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.getTextColor(modeProvider.currentMode),
                  letterSpacing: 1.0,
                ),
                displaySmall: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.getTextColor(modeProvider.currentMode),
                  letterSpacing: 0.8,
                ),
                bodyLarge: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.getTextColor(modeProvider.currentMode).withOpacity(0.9),
                ),
                bodyMedium: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.getTextColor(modeProvider.currentMode).withOpacity(0.7),
                ),
                labelLarge: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextColor(modeProvider.currentMode),
                  letterSpacing: 0.5,
                ),
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: AppColors.getSurfaceColor(modeProvider.currentMode),
                elevation: 0,
                centerTitle: true,
                titleTextStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.getTextColor(modeProvider.currentMode),
                  fontFamily: 'Poppins',
                  letterSpacing: 1.0,
                ),
                iconTheme: IconThemeData(color: AppColors.getTextColor(modeProvider.currentMode)),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode),
                  foregroundColor: AppColors.onPrimaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                  shadowColor: AppColors.getShadowColor(seedColor, modeProvider.currentMode),
                  elevation: 6,
                ),
              ),
cardTheme: CardThemeData(
                color: AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.8),
                elevation: 4,
                margin: const EdgeInsets.all(8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                surfaceTintColor: Colors.transparent,
                shadowColor: AppColors.getShadowColor(seedColor, modeProvider.currentMode),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.getTertiaryColor(seedColor, modeProvider.currentMode).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.getTertiaryColor(seedColor, modeProvider.currentMode),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                hintStyle: TextStyle(color: AppColors.getTextColor(modeProvider.currentMode).withOpacity(0.5)),
                labelStyle: TextStyle(color: AppColors.getLabelColor(seedColor, modeProvider.currentMode)),
              ),
dialogTheme: DialogThemeData(
                backgroundColor: AppColors.getSurfaceColor(modeProvider.currentMode),
                surfaceTintColor: Colors.transparent,
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                titleTextStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.getTextColor(modeProvider.currentMode),
                ),
                contentTextStyle: TextStyle(color: AppColors.getTextColor(modeProvider.currentMode).withOpacity(0.7)),
              ),
              dividerTheme: DividerThemeData(
                color: AppColors.getDividerColor(seedColor, modeProvider.currentMode),
                thickness: 1,
                space: 1,
              ),
            ),
            debugShowCheckedModeBanner: false,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}