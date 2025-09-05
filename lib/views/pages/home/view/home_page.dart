import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/views/pages/home/model/home_model.dart';
import 'package:VarXPro/lang/translation.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late Future<List<Referee>> futureReferees;
  List<Referee> allReferees = [];
  String? selectedConfed;
  String? selectedCountry;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _glowController;
  late AnimationController _scanController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    futureReferees = fetchReferees();

    // Animation for the glowing button effect
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnimation = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Animation for the scan line
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _glowController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  Future<List<Referee>> fetchReferees() async {
    final response = await http.get(
      Uri.parse('https://refereelist.varxpro.com/referees'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;
      return results.map((json) => Referee.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load referees');
    }
  }

  List<Referee> getFilteredReferees() {
    return allReferees.where((referee) {
      final nameMatch = referee.name.toLowerCase().contains(
        _searchController.text.toLowerCase(),
      );
      final confedMatch =
          selectedConfed == null || referee.confed == selectedConfed;
      final countryMatch =
          selectedCountry == null || referee.country == selectedCountry;

      return nameMatch && confedMatch && countryMatch;
    }).toList();
  }

  void _showLanguageDialog(
      BuildContext context, LanguageProvider langProvider, ModeProvider modeProvider, String currentLang) {
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
                Translations.getChooseLanguage(currentLang),
                style: TextStyle(
                  color: AppColors.getTextColor(modeProvider.currentMode),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 24),
              ...Translations.getLanguages(currentLang).asMap().entries.map((entry) {
                int idx = entry.key;
                String lang = entry.value;
                String code = idx == 0 ? 'en' : idx == 1 ? 'fr' : 'ar';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: AppColors.getTertiaryColor(
                            AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!, modeProvider.currentMode)
                        .withOpacity(0.2),
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

  void _showModeDialog(BuildContext context, ModeProvider modeProvider, String currentLang) {
    final List<Map<String, dynamic>> _modes = [
      {"name": Translations.getModes(currentLang)[0], "icon": Icons.sports_soccer},
      {"name": Translations.getModes(currentLang)[1], "icon": Icons.light_mode},
      {"name": Translations.getModes(currentLang)[2], "icon": Icons.analytics},
      {"name": Translations.getModes(currentLang)[3], "icon": Icons.video_camera_front},
      {"name": Translations.getModes(currentLang)[4], "icon": Icons.sports},
    ];

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
                Translations.getChooseMode(currentLang),
                style: TextStyle(
                  color: AppColors.getTextColor(modeProvider.currentMode),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 24),
              ..._modes.asMap().entries.map((entry) {
                int index = entry.key;
                String modeName = entry.value["name"];
                IconData icon = entry.value["icon"];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: AppColors.getTertiaryColor(
                            AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!, modeProvider.currentMode)
                        .withOpacity(0.2),
                    leading: Icon(
                      icon,
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
    final langProvider = Provider.of<LanguageProvider>(context);
    final currentLang = langProvider.currentLanguage;
    final textColor = AppColors.getTextColor(modeProvider.currentMode);
    final seedColor = AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

    return Scaffold(
      body: Stack(
        children: [
          // Background with subtle football field grid
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
          // Animated scan line
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
          // Main content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(isLargeScreen ? 24.0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with logo, title, and language/mode selectors
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Transform.scale(
                        scale: value * 1.05,
                        child: child,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: isLargeScreen ? 70 : 50,
                          height: isLargeScreen ? 70 : 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.getPrimaryColor(seedColor, modeProvider.currentMode).withOpacity(0.3),
                                blurRadius: 12,
                                spreadRadius: 3,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/logo.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                Translations.getHomeText('mainTitle', currentLang),
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isLargeScreen ? 28 : 22,
                                  fontFamily: 'Poppins',
                                  shadows: [
                                    Shadow(
                                      blurRadius: 6,
                                      color: Colors.black.withOpacity(0.15),
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                Translations.getHomeText('subtitle', currentLang),
                                style: TextStyle(
                                  color: textColor.withOpacity(0.7),
                                  fontSize: isLargeScreen ? 16 : 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                     
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Search bar
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOut,
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - value) * 20),
                        child: child,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.getSurfaceColor(modeProvider.currentMode),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: Translations.getRefereeDirectoryText('searchReferees', currentLang),
                          hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                          prefixIcon: Icon(
                            Icons.search,
                            color: textColor.withOpacity(0.7),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Feature chips
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1400),
                    curve: Curves.easeOut,
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset((1 - value) * 50, 0),
                        child: child,
                      ),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFeatureChip(
                            icon: Icons.memory,
                            label: Translations.getRefereeDirectoryText('aiAnalysis', currentLang),
                            color: Colors.blue,
                            textColor: textColor,
                            modeProvider: modeProvider,
                          ),
                          const SizedBox(width: 10),
                          _buildFeatureChip(
                            icon: Icons.videocam,
                            label: Translations.getRefereeDirectoryText('varTechnology', currentLang),
                            color: Colors.purple,
                            textColor: textColor,
                            modeProvider: modeProvider,
                          ),
                          const SizedBox(width: 10),
                          _buildFeatureChip(
                            icon: Icons.bar_chart,
                            label: Translations.getRefereeDirectoryText('liveDashboard', currentLang),
                            color: Colors.green,
                            textColor: textColor,
                            modeProvider: modeProvider,
                          ),
                          const SizedBox(width: 10),
                          _buildFeatureChip(
                            icon: Icons.location_on,
                            label: Translations.getRefereeDirectoryText('offsideDetection', currentLang),
                            color: Colors.orange,
                            textColor: textColor,
                            modeProvider: modeProvider,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Referee directory title and count
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1600),
                    curve: Curves.easeOut,
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - value) * 20),
                        child: child,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Translations.getRefereeDirectoryText('refereesDirectory', currentLang),
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: isLargeScreen ? 20 : 18,
                          ),
                        ),
                        Text(
                          '${getFilteredReferees().length} ${Translations.getRefereeDirectoryText('referees', currentLang)}',
                          style: TextStyle(
                            color: textColor.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filters
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1800),
                    curve: Curves.easeOut,
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset((1 - value) * 50, 0),
                        child: child,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.getSurfaceColor(modeProvider.currentMode),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.2),
                              ),
                            ),
                            child: DropdownButton<String>(
                              isExpanded: true,
                              underline: const SizedBox(),
                              icon: Icon(
                                Icons.arrow_drop_down,
                                size: 18,
                                color: textColor.withOpacity(0.7),
                              ),
                              hint: Text(
                                Translations.getRefereeDirectoryText('allConfederations', currentLang),
                                style: TextStyle(color: textColor.withOpacity(0.7)),
                              ),
                              value: selectedConfed,
                              items: allReferees
                                  .map((ref) => ref.confed)
                                  .toSet()
                                  .map(
                                    (conf) => DropdownMenuItem(
                                      value: conf,
                                      child: Text(
                                        conf,
                                        style: TextStyle(color: textColor),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  selectedConfed = val;
                                  selectedCountry = null;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.getSurfaceColor(modeProvider.currentMode),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.2),
                              ),
                            ),
                            child: DropdownButton<String>(
                              isExpanded: true,
                              underline: const SizedBox(),
                              icon: Icon(
                                Icons.arrow_drop_down,
                                size: 18,
                                color: textColor.withOpacity(0.7),
                              ),
                              hint: Text(
                                Translations.getRefereeDirectoryText('allCountries', currentLang),
                                style: TextStyle(color: textColor.withOpacity(0.7)),
                              ),
                              value: selectedCountry,
                              items: (selectedConfed == null
                                      ? allReferees
                                      : allReferees.where((r) => r.confed == selectedConfed))
                                  .map((ref) => ref.country)
                                  .toSet()
                                  .map(
                                    (country) => DropdownMenuItem(
                                      value: country,
                                      child: Text(
                                        country,
                                        style: TextStyle(color: textColor),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  selectedCountry = val;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Referee list
                  Expanded(
                    child: FutureBuilder<List<Referee>>(
                      future: futureReferees,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          allReferees = snapshot.data!;
                          final filteredReferees = getFilteredReferees();

                          return filteredReferees.isEmpty
                              ? _buildEmptyState(textColor, currentLang)
                              : GridView.builder(
                                  controller: _scrollController,
                                  physics: const BouncingScrollPhysics(),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: isLargeScreen ? (screenWidth > 900 ? 3 : 2) : 1,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 16,
                                    childAspectRatio: isLargeScreen ? 1.6 : 1.5,
                                  ),
                                  itemCount: filteredReferees.length,
                                  itemBuilder: (context, index) {
                                    final referee = filteredReferees[index];
                                    return TweenAnimationBuilder(
                                      tween: Tween<double>(begin: 0, end: 1),
                                      duration: Duration(milliseconds: 600 + (index * 100)),
                                      curve: Curves.easeOutCubic,
                                      builder: (context, value, child) => Opacity(
                                        opacity: value,
                                        child: Transform.translate(
                                          offset: Offset((1 - value) * 50, 0),
                                          child: child,
                                        ),
                                      ),
                                      child: _buildRefereeCard(
                                        referee,
                                        textColor,
                                        modeProvider,
                                        seedColor,
                                        currentLang,
                                      ),
                                    );
                                  },
                                );
                        } else if (snapshot.hasError) {
                          return _buildErrorState(textColor, currentLang);
                        }
                        return _buildLoadingState(textColor, currentLang);
                      },
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

  Widget _buildFeatureChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required ModeProvider modeProvider,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(modeProvider.currentMode),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefereeCard(
    Referee referee,
    Color textColor,
    ModeProvider modeProvider,
    Color seedColor,
    String currentLang,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: AppColors.getShadowColor(seedColor, modeProvider.currentMode).withOpacity(0.3),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.getSurfaceColor(modeProvider.currentMode),
              AppColors.getSurfaceColor(modeProvider.currentMode).withOpacity(0.7),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          referee.name,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: referee.gender == 'Male'
                              ? Colors.blue.withOpacity(0.2)
                              : Colors.pink.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          referee.gender == 'Male' ? Icons.male : Icons.female,
                          size: 16,
                          color: referee.gender == 'Male' ? Colors.blue : Colors.pink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.flag,
                        size: 16,
                        color: textColor.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        referee.country,
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.account_balance,
                        size: 16,
                        color: textColor.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        referee.confed,
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (referee.roles.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: referee.roles
                          .map(
                            (role) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getRoleColor(role).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                role,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getRoleColor(role),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    )
                  else
                    Text(
                      Translations.getRefereeDirectoryText('noRolesSpecified', currentLang),
                      style: TextStyle(
                        color: textColor.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: textColor.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${Translations.getRefereeDirectoryText('since', currentLang)} ${referee.since ?? Translations.getRefereeDirectoryText('na', currentLang)}',
                        style: TextStyle(
                          color: textColor.withOpacity(0.6),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'var':
        return Colors.purple;
      case 'referee':
        return Colors.blue;
      case 'assistant':
        return Colors.green;
      case 'reviewer':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmptyState(Color textColor, String currentLang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 60,
            color: textColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            Translations.getRefereeDirectoryText('noRefereesFound', currentLang),
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Translations.getRefereeDirectoryText('adjustSearchOrFilters', currentLang),
            style: TextStyle(color: textColor.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Color textColor, String currentLang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.warning,
            size: 60,
            color: Colors.orange.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            Translations.getRefereeDirectoryText('failedToLoadReferees', currentLang),
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Translations.getRefereeDirectoryText('checkConnection', currentLang),
            style: TextStyle(color: textColor.withOpacity(0.7)),
          ),
          const SizedBox(height: 16),
          ScaleTransition(
            scale: _glowAnimation,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  futureReferees = fetchReferees();
                });
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(Translations.getRefereeDirectoryText('retry', currentLang)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(Color textColor, String currentLang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            Translations.getRefereeDirectoryText('loadingReferees', currentLang),
            style: TextStyle(color: textColor.withOpacity(0.6)),
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

    final fieldPaint = Paint()
      ..color = AppColors.getTextColor(mode).withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final inset = 40.0;
    final rect = Rect.fromLTWH(
        inset, inset * 2, size.width - inset * 2, size.height - inset * 4);
    canvas.drawRect(rect, fieldPaint);

    final midX = rect.center.dy;
    canvas.drawLine(
        Offset(rect.left + rect.width / 2 - 100, midX),
        Offset(rect.left + rect.width / 2 + 100, midX),
        fieldPaint);
    canvas.drawCircle(Offset(rect.left + rect.width / 2, midX), 30, fieldPaint);
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