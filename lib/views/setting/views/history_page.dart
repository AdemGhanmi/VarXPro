// Updated file: lib/views/history_page.dart
import 'package:VarXPro/views/setting/provider/history_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/provider/modeprovider.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  void _clearHistory(BuildContext context) {
    final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
    historyProvider.clearHistory();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          Translations.getHistoryText('historyCleared', Provider.of<LanguageProvider>(context, listen: false).currentLanguage ?? 'en'),
          style: GoogleFonts.roboto(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final modeProvider = Provider.of<ModeProvider>(context);
    final historyProvider = Provider.of<HistoryProvider>(context);
    final currentLang = langProvider.currentLanguage ?? 'en';
    final seedColor = AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(modeProvider.currentMode),
      appBar: AppBar(
        title: Text(
          Translations.getHistoryText('title', currentLang),
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: historyProvider.historyItems.isEmpty
                  ? Center(
                      child: Text(
                        Translations.getHistoryText('noHistory', currentLang),
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          color: AppColors.getTextColor(modeProvider.currentMode).withOpacity(0.6),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: historyProvider.historyItems.length,
                      itemBuilder: (context, index) {
                        final item = historyProvider.historyItems[index];
                        return Card(
                          color: AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode).withOpacity(0.1),
                              ),
                              child: Text(
                                '📜',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode),
                                ),
                              ),
                            ),
                            title: Text(
                              item.toString(),
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: AppColors.getTextColor(modeProvider.currentMode),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: historyProvider.historyItems.isNotEmpty ? () => _clearHistory(context) : null,
                icon: Text(
                  '🧹',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                label: Text(
                  Translations.getHistoryText('cleanHistory', currentLang),
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}