import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/views/home.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'model/appcolor.dart';
import 'provider/modeprovider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ModeProvider()),
      ],
      child: Consumer<ModeProvider>(
        builder: (context, modeProvider, child) {
          return MaterialApp(
            title: 'VAR X Pro',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!,
                brightness: AppColors.getBrightness(modeProvider.currentMode),
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

void main() {
  runApp(const MyApp());
}