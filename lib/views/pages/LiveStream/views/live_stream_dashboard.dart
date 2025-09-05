
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appColor.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/views/pages/LiveStream/controller/live_stream_controller.dart';
import 'package:VarXPro/views/pages/LiveStream/service/api_service.dart';
import 'package:VarXPro/views/pages/LiveStream/views/video_fullscreen_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:math';

class LiveStreamDashboard extends StatefulWidget {
  const LiveStreamDashboard({super.key});

  @override
  State<LiveStreamDashboard> createState() => _LiveStreamDashboardState();
}

class _LiveStreamDashboardState extends State<LiveStreamDashboard> with TickerProviderStateMixin {
  final LiveStreamController _controller = LiveStreamController();
  final ScrollController _scrollController = ScrollController();

  late AnimationController _glowController;
  late AnimationController _scanController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller.fetchData();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowAnimation = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _glowController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  void _showLanguageDialog(BuildContext context, LanguageProvider langProvider, ModeProvider modeProvider) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.98),
                AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.92),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Translations.getChooseLanguage(langProvider.currentLanguage),
                style: TextStyle(
                  color: AppColors.getTextColor(modeProvider.currentMode),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 24),
              ...Translations.getLanguages(langProvider.currentLanguage).asMap().entries.map((entry) {
                int idx = entry.key;
                String lang = entry.value;
                String code = idx == 0 ? 'en' : idx == 1 ? 'fr' : 'ar';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: AppColors.getTertiaryColor(
                      AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!,
                      modeProvider.currentMode,
                    ).withOpacity(0.2),
                    title: Text(
                      lang,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.getTextColor(modeProvider.currentMode),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      langProvider.changeLanguage(code);
                      Navigator.pop(ctx);
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  void _showModeDialog(BuildContext context, ModeProvider modeProvider) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.98),
                AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.92),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Translations.getChooseMode(modeProvider.currentMode.toString()),
                style: TextStyle(
                  color: AppColors.getTextColor(modeProvider.currentMode),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 24),
              ...Translations.getModes(modeProvider.currentMode.toString()).asMap().entries.map((entry) {
                int index = entry.key;
                String modeName = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: AppColors.getTertiaryColor(
                      AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!,
                      modeProvider.currentMode,
                    ).withOpacity(0.2),
                    leading: Icon(
                      Icons.auto_awesome,
                      color: AppColors.getTextColor(modeProvider.currentMode),
                      size: 28,
                    ),
                    title: Text(
                      modeName,
                      style: TextStyle(
                        color: AppColors.getTextColor(modeProvider.currentMode),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      modeProvider.changeMode(index + 1);
                      Navigator.pop(ctx);
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modeProvider = Provider.of<ModeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final screenWidth = MediaQuery.of(context).size.width;
    final seedColor = AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!;
    final primaryColor = AppColors.getPrimaryColor(seedColor, modeProvider.currentMode);
    final secondaryColor = AppColors.getSecondaryColor(seedColor, modeProvider.currentMode);
    final textPrimary = AppColors.getTextColor(modeProvider.currentMode);
    final textSecondary = AppColors.getTextColor(modeProvider.currentMode).withOpacity(0.7);
    final cardColor = AppColors.getSurfaceColor(modeProvider.currentMode);

    final crossAxisCount = screenWidth < 400 ? 2 : screenWidth < 600 ? 3 : screenWidth < 900 ? 4 : 6;

    return Scaffold(
     
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _FootballGridPainter(modeProvider.currentMode),
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.getBodyGradient(modeProvider.currentMode),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _scanController,
              builder: (context, _) {
                final t = _scanController.value;
                return CustomPaint(
                  painter: _ScanLinePainter(
                    progress: t,
                    mode: modeProvider.currentMode,
                    seedColor: seedColor,
                  ),
                );
              },
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return NestedScrollView(
                controller: _scrollController,
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [];
                },
                body: _controller.isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.getLabelColor(seedColor, modeProvider.currentMode),
                              ),
                              strokeWidth: 4,
                            ),
                            SizedBox(height: isPortrait ? 16 : 12),
                            Text(
                              Translations.translate('loading_channels', languageProvider.currentLanguage),
                              style: GoogleFonts.roboto(
                                color: textSecondary,
                                fontSize: isPortrait ? 16 : 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _controller.errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.getTertiaryColor(seedColor, modeProvider.currentMode).withOpacity(0.1),
                                  ),
                                  child: Icon(
                                    Icons.error_outline,
                                    color: AppColors.getLabelColor(seedColor, modeProvider.currentMode),
                                    size: isPortrait ? 48 : 40,
                                  ),
                                ),
                                SizedBox(height: isPortrait ? 16 : 12),
                                Text(
                                  Translations.translate('unknown_error', languageProvider.currentLanguage),
                                  style: GoogleFonts.roboto(
                                    color: textSecondary,
                                    fontSize: isPortrait ? 16 : 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: isPortrait ? 24 : 20),
                                ElevatedButton(
                                  onPressed: _controller.fetchData,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.getLabelColor(seedColor, modeProvider.currentMode),
                                    foregroundColor: primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isPortrait ? 24 : 20,
                                      vertical: isPortrait ? 12 : 10,
                                    ),
                                    elevation: 2,
                                  ),
                                  child: Text(
                                    Translations.translate('retry', languageProvider.currentLanguage),
                                    style: GoogleFonts.roboto(
                                      fontSize: isPortrait ? 14 : 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              Container(
                                height: screenWidth * 0.12,
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.04,
                                  vertical: 8,
                                ),
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _controller.categories.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index == 0) {
                                      return Padding(
                                        padding: EdgeInsets.only(right: screenWidth * 0.02),
                                        child: ChoiceChip(
                                          label: Text(
                                            Translations.translate('all', languageProvider.currentLanguage),
                                            style: GoogleFonts.roboto(
                                              color: modeProvider.currentMode == 2 ? Colors.black : Colors.white,
                                              fontSize: isPortrait ? 14 : 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          selected: _controller.selectedCategoryId.isEmpty,
                                          onSelected: (selected) {
                                            _controller.updateSelectedCategory('');
                                          },
                                          selectedColor: AppColors.getLabelColor(seedColor, modeProvider.currentMode),
                                          backgroundColor: cardColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            side: BorderSide(
                                              color: AppColors.getLabelColor(seedColor, modeProvider.currentMode).withOpacity(0.3),
                                            ),
                                          ),
                                          labelPadding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                        ),
                                      );
                                    }
                                    final category = _controller.categories[index - 1];
                                    return Padding(
                                      padding: EdgeInsets.only(right: screenWidth * 0.02),
                                      child: ChoiceChip(
                                        label: Text(
                                          category.name,
                                          style: GoogleFonts.roboto(
                                            color: modeProvider.currentMode == 2 ? Colors.black : Colors.white,
                                            fontSize: isPortrait ? 14 : 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        selected: _controller.selectedCategoryId == category.id,
                                        onSelected: (selected) {
                                          _controller.updateSelectedCategory(category.id);
                                        },
                                        selectedColor: AppColors.getLabelColor(seedColor, modeProvider.currentMode),
                                        backgroundColor: cardColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          side: BorderSide(
                                            color: AppColors.getLabelColor(seedColor, modeProvider.currentMode).withOpacity(0.3),
                                          ),
                                        ),
                                        labelPadding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.04,
                                  vertical: 8,
                                ),
                                child: TextField(
                                  style: GoogleFonts.roboto(
                                    color: textPrimary,
                                    fontSize: isPortrait ? 16 : 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: Translations.translate('search_channels', languageProvider.currentLanguage),
                                    hintStyle: GoogleFonts.roboto(
                                      color: textSecondary,
                                      fontSize: isPortrait ? 16 : 14,
                                    ),
                                    filled: true,
                                    fillColor: cardColor,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.04,
                                      vertical: isPortrait ? 12 : 10,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: AppColors.getLabelColor(seedColor, modeProvider.currentMode),
                                    ),
                                    suffixIcon: _controller.searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: Icon(
                                              Icons.clear,
                                              color: AppColors.getLabelColor(seedColor, modeProvider.currentMode),
                                            ),
                                            onPressed: () {
                                              _controller.updateSearchQuery('');
                                            },
                                          )
                                        : null,
                                  ),
                                  onChanged: _controller.updateSearchQuery,
                                ),
                              ),
                              Expanded(
                                child: _controller.filteredChannels.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(20),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: textSecondary.withOpacity(0.05),
                                              ),
                                              child: Icon(
                                                Icons.tv,
                                                color: textSecondary.withOpacity(0.3),
                                                size: isPortrait ? 64 : 56,
                                              ),
                                            ),
                                            SizedBox(height: isPortrait ? 16 : 12),
                                            Text(
                                              Translations.translate('no_channels_found', languageProvider.currentLanguage),
                                              style: GoogleFonts.roboto(
                                                color: textSecondary,
                                                fontSize: isPortrait ? 16 : 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            SizedBox(height: isPortrait ? 16 : 12),
                                            ElevatedButton(
                                              onPressed: _controller.resetFilters,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.getLabelColor(seedColor, modeProvider.currentMode),
                                                foregroundColor: primaryColor,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: Text(
                                                Translations.translate('reset_filters', languageProvider.currentLanguage),
                                                style: GoogleFonts.roboto(
                                                  fontSize: isPortrait ? 14 : 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : GridView.builder(
                                        padding: EdgeInsets.all(screenWidth * 0.04),
                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: crossAxisCount,
                                          crossAxisSpacing: screenWidth * 0.04,
                                          mainAxisSpacing: screenWidth * 0.04,
                                          childAspectRatio: 0.75,
                                        ),
                                        itemCount: _controller.filteredChannels.length,
                                        itemBuilder: (context, index) {
                                          final channel = _controller.filteredChannels[index];
                                          return GestureDetector(
                                            onTap: () {
                                              final streamUrl = ApiService().getStreamUrl(channel.id);
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => VideoFullScreenPage(
                                                    streamUrl: streamUrl,
                                                    channelName: channel.name,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(12),
                                                color: cardColor,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.1),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    width: screenWidth * 0.15,
                                                    height: screenWidth * 0.15,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      image: channel.streamIcon.isNotEmpty
                                                          ? DecorationImage(
                                                              image: NetworkImage(channel.streamIcon),
                                                              fit: BoxFit.cover,
                                                              onError: (exception, stackTrace) {},
                                                            )
                                                          : null,
                                                    ),
                                                    child: channel.streamIcon.isEmpty
                                                        ? Icon(
                                                            Icons.tv,
                                                            size: screenWidth * 0.1,
                                                            color: AppColors.getLabelColor(seedColor, modeProvider.currentMode),
                                                          )
                                                        : null,
                                                  ),
                                                  SizedBox(height: screenWidth * 0.02),
                                                  Text(
                                                    channel.name,
                                                    textAlign: TextAlign.center,
                                                    style: GoogleFonts.roboto(
                                                      color: textPrimary,
                                                      fontSize: isPortrait ? 14 : 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FootballGridPainter extends CustomPainter {
  final int mode;

  _FootballGridPainter(this.mode);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.getTextColor(mode).withOpacity(0.04)
      ..strokeWidth = 0.5;

    const step = 50.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Stylized football field
    final fieldPaint = Paint()
      ..color = AppColors.getTextColor(mode).withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final inset = 40.0;
    final rect = Rect.fromLTWH(inset, inset * 2, size.width - inset * 2, size.height - inset * 4);
    canvas.drawRect(rect, fieldPaint);

    final midY = rect.center.dy;
    canvas.drawLine(Offset(rect.left + rect.width / 2 - 100, midY), Offset(rect.left + rect.width / 2 + 100, midY), fieldPaint);
    canvas.drawCircle(Offset(rect.left + rect.width / 2, midY), 30, fieldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScanLinePainter extends CustomPainter {
  final double progress;
  final int mode;
  final Color seedColor;

  _ScanLinePainter({required this.progress, required this.mode, required this.seedColor});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    final line = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          AppColors.getPrimaryColor(seedColor, mode).withOpacity(0.2),
          AppColors.getTertiaryColor(seedColor, mode).withOpacity(0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 0.55, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, y - 80, size.width, 160));

    canvas.drawRect(Rect.fromLTWH(0, y - 80, size.width, 160), line);

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.getPrimaryColor(seedColor, mode).withOpacity(0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, y),
        radius: size.width * 0.25,
      ));

    canvas.drawCircle(Offset(size.width / 2, y), size.width * 0.25, glow);
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.mode != mode;
}