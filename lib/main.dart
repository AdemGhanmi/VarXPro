import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/views/setting/provider/history_provider.dart';
import 'package:VarXPro/views/connexion/providers/auth_provider.dart';
import 'package:VarXPro/views/home.dart'; // هذا هو HomePage splash
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
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ModeProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer3<ModeProvider, AuthProvider, LanguageProvider>(
        builder: (context, modeProvider, authProvider, langProvider, child) {
          final currentLang = langProvider.currentLanguage ?? 'en';
          return MaterialApp(
            title: 'VAR X Pro',
            locale: Locale(currentLang),
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.seedColors[modeProvider.currentMode] ??
                    AppColors.seedColors[1]!,
                brightness:
                    AppColors.getBrightness(modeProvider.currentMode),
              ),
              fontFamily: 'Poppins',
            ),
            home: const HomePage(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
