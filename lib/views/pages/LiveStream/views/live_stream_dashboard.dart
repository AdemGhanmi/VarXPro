import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/views/pages/LiveStream/controller/live_stream_controller.dart';
import 'package:VarXPro/views/pages/LiveStream/service/api_service.dart';
import 'package:VarXPro/views/pages/LiveStream/views/video_fullscreen_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class LiveStreamDashboard extends StatefulWidget {
  const LiveStreamDashboard({super.key});

  @override
  State<LiveStreamDashboard> createState() => _LiveStreamDashboardState();
}

class _LiveStreamDashboardState extends State<LiveStreamDashboard> {
  final LiveStreamController _controller = LiveStreamController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.fetchData();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ModeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentLang = languageProvider.currentLanguage ?? 'en';
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final screenWidth = MediaQuery.of(context).size.width;
    final seedColor = AppColors.seedColors[themeProvider.currentMode] ?? AppColors.seedColors[1]!;

    final crossAxisCount = screenWidth < 400 ? 2 : screenWidth < 600 ? 3 : screenWidth < 900 ? 4 : 6;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.getBodyGradient(themeProvider.currentMode),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return NestedScrollView(
                controller: _scrollController,
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                  
                  ];
                },
                body: _controller.isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(seedColor),
                              strokeWidth: 4,
                            ),
                            SizedBox(height: isPortrait ? 16 : 12),
                            Text(
                              Translations.translate('loading_channels', currentLang),
                              style: GoogleFonts.roboto(
                                color: AppColors.getTextColor(themeProvider.currentMode),
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
                                    color: seedColor.withOpacity(0.1),
                                  ),
                                  child: Icon(
                                    Icons.error_outline,
                                    color: seedColor,
                                    size: isPortrait ? 48 : 40,
                                  ),
                                ),
                                SizedBox(height: isPortrait ? 16 : 12),
                                Text(
                                  _controller.errorMessage ?? Translations.translate('unknown_error', currentLang),
                                  style: GoogleFonts.roboto(
                                    color: AppColors.getTextColor(themeProvider.currentMode),
                                    fontSize: isPortrait ? 16 : 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: isPortrait ? 24 : 20),
                                ElevatedButton(
                                  onPressed: _controller.fetchData,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: seedColor,
                                    foregroundColor: AppColors.onPrimaryColor,
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
                                    Translations.translate('retry', currentLang),
                                    style: GoogleFonts.roboto(
                                      fontSize: isPortrait ? 14 : 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.onPrimaryColor,
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
                                            Translations.translate('all', currentLang),
                                            style: GoogleFonts.roboto(
                                              color: AppColors.getTextColor(themeProvider.currentMode),
                                              fontSize: isPortrait ? 14 : 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          selected: _controller.selectedCategoryId.isEmpty,
                                          onSelected: (selected) {
                                            _controller.updateSelectedCategory('');
                                          },
                                          selectedColor: seedColor,
                                          backgroundColor: AppColors.getSurfaceColor(themeProvider.currentMode),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            side: BorderSide(
                                              color: seedColor.withOpacity(0.3),
                                            ),
                                          ),
                                          labelPadding: const EdgeInsets.symmetric(horizontal: 12),
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
                                            color: AppColors.getTextColor(themeProvider.currentMode),
                                            fontSize: isPortrait ? 14 : 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        selected: _controller.selectedCategoryId == category.id,
                                        onSelected: (selected) {
                                          _controller.updateSelectedCategory(category.id);
                                        },
                                        selectedColor: seedColor,
                                        backgroundColor: AppColors.getSurfaceColor(themeProvider.currentMode),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          side: BorderSide(
                                            color: seedColor.withOpacity(0.3),
                                          ),
                                        ),
                                        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
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
                                    color: AppColors.getTextColor(themeProvider.currentMode),
                                    fontSize: isPortrait ? 16 : 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: Translations.translate('search_channels', currentLang),
                                    hintStyle: GoogleFonts.roboto(
                                      color: AppColors.getTextColor(themeProvider.currentMode).withOpacity(0.7),
                                      fontSize: isPortrait ? 16 : 14,
                                    ),
                                    filled: true,
                                    fillColor: AppColors.getSurfaceColor(themeProvider.currentMode),
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
                                      color: seedColor,
                                    ),
                                    suffixIcon: _controller.searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: Icon(
                                              Icons.clear,
                                              color: seedColor,
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
                                                color: seedColor.withOpacity(0.1),
                                              ),
                                              child: Icon(
                                                Icons.tv,
                                                color: seedColor,
                                                size: isPortrait ? 64 : 56,
                                              ),
                                            ),
                                            SizedBox(height: isPortrait ? 16 : 12),
                                            Text(
                                              Translations.translate('no_channels_found', currentLang),
                                              style: GoogleFonts.roboto(
                                                color: AppColors.getTextColor(themeProvider.currentMode),
                                                fontSize: isPortrait ? 16 : 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            SizedBox(height: isPortrait ? 16 : 12),
                                            ElevatedButton(
                                              onPressed: _controller.resetFilters,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: seedColor,
                                                foregroundColor: AppColors.onPrimaryColor,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: Text(
                                                Translations.translate('reset_filters', currentLang),
                                                style: GoogleFonts.roboto(
                                                  fontSize: isPortrait ? 14 : 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.onPrimaryColor,
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
                                            child: Card(
                                              elevation: 4,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              color: AppColors.getSurfaceColor(themeProvider.currentMode),
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
                                                      border: Border.all(
                                                        color: seedColor.withOpacity(0.3),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: channel.streamIcon.isEmpty
                                                        ? Icon(
                                                            Icons.tv,
                                                            size: screenWidth * 0.1,
                                                            color: seedColor,
                                                          )
                                                        : null,
                                                  ),
                                                  SizedBox(height: screenWidth * 0.02),
                                                  Text(
                                                    channel.name,
                                                    textAlign: TextAlign.center,
                                                    style: GoogleFonts.roboto(
                                                      color: AppColors.getTextColor(themeProvider.currentMode),
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
        ),
      ),
    );
  }
}