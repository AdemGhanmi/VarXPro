import 'dart:convert';
import 'dart:math';
import 'package:VarXPro/views/pages/home/view/details_arbiter/detail_arbiter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/views/pages/home/model/home_model.dart';
import 'package:VarXPro/lang/translation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late Future<List<Referee>> futureReferees;
  List<Referee> allReferees = [];
  List<Referee> displayedReferees = []; // Sliced for display
  bool _isLoadingMore = false;
  int _displayLimit = 50; // Initial display limit
  static const int _loadIncrement = 50; // Load more on scroll
  String? selectedConfed;
  String? selectedCountry;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  late List<AnimationController> _staggerControllers;

  @override
  void initState() {
    super.initState();
    // Temporary: Clear cache to force fresh load (remove after testing)
    _clearCacheForTesting();
    futureReferees = _loadReferees();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnimation = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _staggerControllers = [];
    _scrollController.addListener(_onScroll);
  }

  // Temporary method to clear cache for testing
  Future<void> _clearCacheForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_referees');
    await prefs.remove('cache_time');
    debugPrint('Cache cleared for testing');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _glowController.dispose();
    for (var controller in _staggerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Load referees with cache check
  Future<List<Referee>> _loadReferees() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('cached_referees');
    final cacheTime = prefs.getString('cache_time');
    if (cachedData != null && cacheTime != null) {
      try {
        final cacheDate = DateTime.parse(cacheTime);
        if (DateTime.now().difference(cacheDate).inHours < 24) {
          final List<dynamic> cachedJson = json.decode(cachedData);
          return cachedJson.map((json) => Referee.fromJson(json)).toList();
        }
      } catch (e) {
        debugPrint('Cache invalid: $e');
      }
    }
    return await fetchReferees(); // Load fresh if no valid cache
  }

  Map<String, dynamic> _parseNumericFields(Map<String, dynamic> json) {
    if (json.containsKey('details') && json['details'] != null) {
      final details = json['details'] as Map<String, dynamic>;
      if (details.containsKey('worldfootball') &&
          details['worldfootball'] != null) {
        final wf = details['worldfootball'] as Map<String, dynamic>;
        if (wf.containsKey('overall_totals') && wf['overall_totals'] != null) {
          final totals = wf['overall_totals'] as Map<String, dynamic>;
          totals.forEach((key, value) {
            if (value is String) {
              final numValue = num.tryParse(value);
              if (numValue != null) {
                totals[key] = numValue is double
                    ? numValue
                    : numValue.toDouble();
              }
            }
          });
        }
        if (wf.containsKey('scraped_at') && wf['scraped_at'] is String) {
          final numValue = num.tryParse(wf['scraped_at']);
          if (numValue != null) {
            wf['scraped_at'] = numValue.toInt();
          }
        }
        // Recurse for competitions if needed
        if (wf.containsKey('competitions') && wf['competitions'] != null) {
          final comps = wf['competitions'] as List<dynamic>;
          for (var comp in comps) {
            if (comp is Map<String, dynamic> && comp.containsKey('totals')) {
              final totals = comp['totals'] as Map<String, dynamic>;
              totals.forEach((key, value) {
                if (value is String) {
                  final numValue = num.tryParse(value);
                  if (numValue != null) {
                    totals[key] = numValue is double
                        ? numValue
                        : numValue.toDouble();
                  }
                }
              });
            }
            if (comp.containsKey('seasons') && comp['seasons'] != null) {
              final seasons = comp['seasons'] as List<dynamic>;
              for (var season in seasons) {
                if (season is Map<String, dynamic>) {
                  season.forEach((key, value) {
                    if (value is String) {
                      final numValue = num.tryParse(value);
                      if (numValue != null) {
                        season[key] = numValue is double
                            ? numValue
                            : numValue.toDouble();
                      }
                    }
                  });
                }
              }
            }
          }
        }
      }
    }
    // Also parse other numeric fields like last_enriched, since
    if (json.containsKey('last_enriched') && json['last_enriched'] is String) {
      final numValue = num.tryParse(json['last_enriched']);
      if (numValue != null) {
        json['last_enriched'] = numValue.toInt();
      }
    }
    if (json.containsKey('since') && json['since'] is String) {
      final numValue = num.tryParse(json['since']);
      if (numValue != null) {
        json['since'] = numValue.toInt();
      }
    }
    return json;
  }

  Future<List<Referee>> fetchReferees() async {
    List<Referee> referees = [];
    try {
      final listResponse = await http.get(
        Uri.parse('https://refereelist.varxpro.com/referees'),
      );
      if (listResponse.statusCode == 200) {
        final listData = json.decode(listResponse.body);
        final List<dynamic> listJson = listData['results'] ?? listData;

        final Map<String, String> nameToId = {};
        for (var ref in listJson) {
          final name = ref['name'] as String?;
          final id = ref['_id'] as String?;
          if (name != null && id != null && name.trim().isNotEmpty) {
            nameToId[name.toLowerCase().trim()] = id;
          }
        }

        try {
          final detailsResponse = await http.get(
            Uri.parse('https://refereelistdetail.varxpro.com/json'),
          );
          if (detailsResponse.statusCode == 200) {
            final detailsJson =
                json.decode(detailsResponse.body) as List<dynamic>;
            for (var det in detailsJson) {
              String id = '';
              final name = det['name'] as String?;
              if (name != null &&
                  nameToId.containsKey(name.toLowerCase().trim())) {
                id = nameToId[name.toLowerCase().trim()]!;
              }
              final refereeJson = Map<String, dynamic>.from(det);
              refereeJson['id'] = id;
              final referee = Referee.fromJson(refereeJson);
              referees.add(referee);
            }
            debugPrint('Loaded ${referees.length} referees with details');
          } else {
            debugPrint(
              'Details API error: ${detailsResponse.statusCode} - falling back to list',
            );
          }
        } catch (detailsError) {
          debugPrint(
            'Details fetch error: $detailsError - falling back to list data',
          );
        }

        // Fallback: if no details or partial, use list data for unmatched
        if (referees.length < listJson.length) {
          for (var ref in listJson) {
            final name = ref['name'] as String?;
            if (name != null &&
                name.trim().isNotEmpty &&
                !referees.any(
                  (r) =>
                      r.name.toLowerCase().trim() == name.toLowerCase().trim(),
                )) {
              final fallbackReferee = Referee.fromJson({
                'id': ref['_id'] ?? '',
                'confed': ref['confed'] ?? '',
                'country': ref['country'] ?? '',
                'details': null, // No details
                'gender': ref['gender'] ?? '',
                'last_enriched': 0,
                'name': name,
                'roles': ref['roles'] ?? [],
                'since': ref['since'] ?? 0,
                'year': ref['year'],
              });
              referees.add(fallbackReferee);
            }
          }
        }
      } else {
        debugPrint('List API error: ${listResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('General fetch error: $e - using empty list or cache');
      // No throw - graceful fallback to empty or cached
      referees = [];
    }

    // Fetch and merge from new API
    try {
      final newApiResponse = await http.get(
        Uri.parse('https://varxpro.com/storage/federations/all.json'),
      );
      if (newApiResponse.statusCode == 200) {
        final newApiJson = json.decode(newApiResponse.body);
        final List<dynamic> newData = newApiJson['data'] ?? [];
        debugPrint('Fetched ${newData.length} items from new API');
        for (var newItem in newData) {
          final newName = newItem['name'] as String?;
          if (newName != null && newName.trim().isNotEmpty) {
            // Handle country null by setting to empty string if needed
            if (newItem['country'] == null) {
              newItem['country'] = '';
            }
            final existingIndex = referees.indexWhere(
              (r) =>
                  r.name.toLowerCase().trim() == newName.toLowerCase().trim(),
            );
            final newRefereeJson = Map<String, dynamic>.from(newItem);
            newRefereeJson['id'] = newItem['refid'] ?? ''; // Map refid to id
            // Parse numeric fields for new API
            final parsedJson = _parseNumericFields(newRefereeJson);
            final newReferee = Referee.fromJson(parsedJson);
            if (existingIndex != -1) {
              // Update existing with new details if available
              if (newReferee.details != null) {
                final mergedJson = Map<String, dynamic>.from(
                  referees[existingIndex].toJson(),
                );
                mergedJson['details'] = newReferee.details!.toJson();
                referees[existingIndex] = Referee.fromJson(mergedJson);
                debugPrint('Merged details for existing: ${newReferee.name}');
              }
            } else {
              // Add new referee
              referees.add(newReferee);
              debugPrint(
                'Added new referee: ${newReferee.name} (confed: ${newReferee.confed}, country: ${newReferee.country ?? 'ALL'})',
              );
            }
          }
        }
        debugPrint('Merged ${newData.length} new referees from federation API');
      } else {
        debugPrint('New API error: ${newApiResponse.statusCode}');
      }
    } catch (newApiError) {
      debugPrint('New API fetch error: $newApiError');
    }

    // Sort the list by name for consistent display
    referees.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    // Cache full list (even if partial)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'cached_referees',
      json.encode(referees.map((r) => r.toJson()).toList()),
    );
    await prefs.setString('cache_time', DateTime.now().toIso8601String());

    debugPrint('Total referees loaded: ${referees.length}');
    return referees;
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore &&
          displayedReferees.length < getFilteredReferees().length) {
        _loadMore();
      }
    }
  }

  void _loadMore() {
    if (_isLoadingMore) return;
    setState(() {
      _isLoadingMore = true;
      _displayLimit += _loadIncrement;
      _updateDisplayedReferees();
    });
    // Simulate delay for smooth UX
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    });
  }

 void _updateDisplayedReferees() {
  final filtered = getFilteredReferees();
  final fullSliced = filtered.take(_displayLimit).toList();
  List<Referee> sliced = fullSliced;

  // Sort referees to ensure those with emoji "👨‍⚖️" appear at the end
  sliced.sort((a, b) {
    // If either referee has the emoji, sort them to the bottom
    if (a.name.contains('👨‍⚖️')) {
      return 1; // Move a to the bottom
    }
    if (b.name.contains('👨‍⚖️')) {
      return -1; // Move b to the bottom
    }
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });

  // Update the list with the sorted referees
  displayedReferees = sliced;
  _initializeStaggerAnimations(sliced.length);
}



  List<Referee> getFilteredReferees() {
  final filtered = allReferees.where((referee) {
    // Exclude referees with "👨‍⚖️" emoji in their name
    if (referee.name.contains('👨‍⚖️') || referee.name.isEmpty) {
      return false; // Exclude them
    }
    
    final nameMatch = referee.name.toLowerCase().contains(
      _searchController.text.toLowerCase(),
    );
    final confedMatch =
        selectedConfed == null || referee.confed == selectedConfed;
    final countryMatch =
        selectedCountry == null || (referee.country ?? '') == selectedCountry;
    return nameMatch && confedMatch && countryMatch;
  }).toList();
  
  // Ensure alphabetical sorting from A to Z (top to bottom) after filtering
  filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return filtered;
}


  Set<String> _getUniqueConfederations() {
    return allReferees
        .map((ref) => ref.confed)
        .where((c) => c != null && c.isNotEmpty)
        .toSet();
  }

  Set<String> _getUniqueCountries() {
    final refs = selectedConfed == null
        ? allReferees
        : allReferees.where((r) => r.confed == selectedConfed).toList();
    return refs
        .map((ref) => ref.country ?? '')
        .where((c) => c.isNotEmpty)
        .toSet();
  }

  void _showLanguageDialog(
    BuildContext context,
    LanguageProvider langProvider,
    ModeProvider modeProvider,
    String currentLang,
  ) {
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
                AppColors.getSurfaceColor(
                  modeProvider.currentMode,
                ).withOpacity(0.98),
                AppColors.getSurfaceColor(
                  modeProvider.currentMode,
                ).withOpacity(0.92),
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
              ...Translations.getLanguages(currentLang).asMap().entries.map((
                entry,
              ) {
                int idx = entry.key;
                String lang = entry.value;
                String code = idx == 0
                    ? 'en'
                    : idx == 1
                    ? 'fr'
                    : 'ar';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: AppColors.getTertiaryColor(
                      AppColors.seedColors[modeProvider.currentMode] ??
                          AppColors.seedColors[1]!,
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

  void _showModeDialog(
    BuildContext context,
    ModeProvider modeProvider,
    String currentLang,
  ) {
    final List<Map<String, dynamic>> _modes = [
      {
        "name": Translations.getModes(currentLang)[0],
        "icon": Icons.sports_soccer,
      },
      {"name": Translations.getModes(currentLang)[1], "icon": Icons.light_mode},
      {"name": Translations.getModes(currentLang)[2], "icon": Icons.analytics},
      {
        "name": Translations.getModes(currentLang)[3],
        "icon": Icons.video_camera_front,
      },
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
                AppColors.getSurfaceColor(
                  modeProvider.currentMode,
                ).withOpacity(0.98),
                AppColors.getSurfaceColor(
                  modeProvider.currentMode,
                ).withOpacity(0.92),
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: AppColors.getTertiaryColor(
                      AppColors.seedColors[modeProvider.currentMode] ??
                          AppColors.seedColors[1]!,
                      modeProvider.currentMode,
                    ).withOpacity(0.2),
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
    final currentLang = langProvider.currentLanguage ?? 'en';
    debugPrint('Current language: $currentLang');
    final textColor = AppColors.getTextColor(modeProvider.currentMode);
    final seedColor =
        AppColors.seedColors[modeProvider.currentMode] ??
        AppColors.seedColors[1]!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;
    final textDirection = currentLang == 'ar'
        ? TextDirection.rtl
        : TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _FootballGridPainter(modeProvider.currentMode),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.getBodyGradient(
                      modeProvider.currentMode,
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.all(isLargeScreen ? 24.0 : 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Hero(
                                tag: 'app_logo',
                                child: Container(
                                  width: isLargeScreen ? 70 : 50,
                                  height: isLargeScreen ? 70 : 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.getPrimaryColor(
                                          seedColor,
                                          modeProvider.currentMode,
                                        ).withOpacity(0.3),
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
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${Translations.getHomeText('mainTitle', currentLang)} ',
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
                                    Translations.getHomeText(
                                      'subtitle',
                                      currentLang,
                                    ),
                                    style: TextStyle(
                                      color: textColor.withOpacity(0.7),
                                      fontSize: isLargeScreen ? 16 : 12,
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
                    const SizedBox(height: 20),
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
                          color: AppColors.getSurfaceColor(
                            modeProvider.currentMode,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _updateDisplayedReferees();
                            });
                          },
                          textDirection: textDirection,
                          decoration: InputDecoration(
                            hintText: Translations.getRefereeDirectoryText(
                              'searchReferees',
                              currentLang,
                            ),
                            hintStyle: TextStyle(
                              color: textColor.withOpacity(0.5),
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: textColor.withOpacity(0.7),
                            ),
                            suffixIcon: Icon(
                              Icons.sports_soccer,
                              color: textColor.withOpacity(0.4),
                              size: 20,
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
                    const SizedBox(height: 24),
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
                            '${Translations.getRefereeDirectoryText('refereesDirectory', currentLang)} 👨‍⚖️',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: isLargeScreen ? 20 : 18,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '${getFilteredReferees().length} ${Translations.getRefereeDirectoryText('referees', currentLang)}',
                            style: TextStyle(
                              color: textColor.withOpacity(0.7),
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: FutureBuilder<List<Referee>>(
                        future: futureReferees,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            if (allReferees.isEmpty) {
                              allReferees = snapshot.data!;
                              _updateDisplayedReferees();
                              SchedulerBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {});
                                }
                              });
                            }

                            if (displayedReferees.isEmpty) {
                              return _buildEmptyState(textColor, currentLang);
                            }
                            return _buildGrid(
                              displayedReferees,
                              textColor,
                              modeProvider,
                              seedColor,
                              currentLang,
                            );
                          } else if (snapshot.hasError) {
                            return _buildErrorState(textColor, currentLang);
                          }
                          return _buildLoadingState(textColor, currentLang);
                        },
                      ),
                    ),
                    if (_isLoadingMore)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(
    List<Referee> referees,
    Color textColor,
    ModeProvider modeProvider,
    Color seedColor,
    String currentLang,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.getSurfaceColor(modeProvider.currentMode),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButton<String?>(
                  isExpanded: true,
                  value: selectedConfed,
                  hint: null,
                  items: <DropdownMenuItem<String?>>[
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        Translations.getRefereeDirectoryText(
                          'allConfederations',
                          currentLang,
                        ),
                      ),
                    ),
                    ..._getUniqueConfederations().map(
                      (conf) => DropdownMenuItem<String>(
                        value: conf,
                        child: Text(conf),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      selectedConfed = val;
                      selectedCountry = null;
                      _updateDisplayedReferees();
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButton<String?>(
                  isExpanded: true,
                  value: selectedCountry,
                  hint: null,
                  items: <DropdownMenuItem<String?>>[
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        Translations.getRefereeDirectoryText(
                          'allCountries',
                          currentLang,
                        ),
                      ),
                    ),
                    ..._getUniqueCountries().map(
                      (country) => DropdownMenuItem<String>(
                        value: country,
                        child: Text(country),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      selectedCountry = val;
                      _updateDisplayedReferees();
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            itemCount: referees.length + (_isLoadingMore ? 1 : 0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            itemBuilder: (context, index) {
              if (index >= referees.length) {
                return const Center(child: CircularProgressIndicator());
              }
              final referee = referees[index];
              final animController =
                  _staggerControllers.length > index
                        ? _staggerControllers[index]
                        : AnimationController(
                            vsync: this,
                            duration: const Duration(milliseconds: 500),
                          )
                    ..forward();
              return AnimatedBuilder(
                animation: animController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, (1 - animController.value) * 50),
                    child: Opacity(opacity: animController.value, child: child),
                  );
                },
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    animController.forward().then((_) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailArbiter(referee: referee),
                        ),
                      );
                    });
                  },
                  child: _buildRefereeCard(
                    referee,
                    textColor,
                    modeProvider,
                    seedColor,
                    currentLang,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _initializeStaggerAnimations(int count) {
    _staggerControllers.clear();
    final limitedCount = count > 20
        ? 20
        : count; // Limit animations to first 20 for perf
    for (int i = 0; i < limitedCount; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 500 + (i * 100)),
      );
      controller.forward();
      _staggerControllers.add(controller);
    }
  }

  Widget _buildFeatureChip({
    required String emoji,
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
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 4),
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
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
  final displayCountry = referee.country ?? 'ALL';
  final displayConfed = referee.confed ?? 'ALL';
  return Card(
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    shadowColor: AppColors.getShadowColor(
      seedColor,
      modeProvider.currentMode,
    ).withOpacity(0.5),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.getSurfaceColor(modeProvider.currentMode),
            AppColors.getSurfaceColor(
              modeProvider.currentMode,
            ).withOpacity(0.85),
          ],
        ),
        border: Border.all(
          color: AppColors.getPrimaryColor(
            seedColor,
            modeProvider.currentMode,
          ).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 16.0),  // Reduced bottom padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,  // Changed from spaceBetween
          children: [
            // Upper column
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '👨‍⚖️ ${referee.name}',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: referee.gender == 'Male'
                              ? Colors.blue.withOpacity(0.2)
                              : Colors.pink.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: referee.gender == 'Male'
                                ? Colors.blue.withOpacity(0.3)
                                : Colors.pink.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          referee.gender == 'Male'
                              ? Icons.male_rounded
                              : Icons.female_rounded,
                          size: 16,
                          color: referee.gender == 'Male'
                              ? Colors.blueAccent
                              : Colors.pinkAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Country and confed row
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    children: [
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '🏳️ $displayCountry',
                          style: TextStyle(
                            color: textColor.withOpacity(0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.account_balance_rounded,
                        size: 16,
                        color: textColor.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '🏆 $displayConfed',
                          style: TextStyle(
                            color: textColor.withOpacity(0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Lower column (including arrow to avoid spacing issues)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,  // Now spaceBetween here for arrow push
                children: [
                  // Content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      if (referee.roles.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: referee.roles
                              .map(
                                (role) => Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getRoleColor(role).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: _getRoleColor(role).withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _getRoleEmoji(role),
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          role,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _getRoleColor(role),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        )
                      else
                        Text(
                          Translations.getRefereeDirectoryText(
                            'noRolesSpecified',
                            currentLang,
                          ),
                          style: TextStyle(
                            color: textColor.withOpacity(0.6),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              size: 14,
                              color: Colors.transparent,
                            ),
                            const Text('📅', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                            Text(
                              '${Translations.getRefereeDirectoryText('since', currentLang)} ${referee.since}',
                              style: TextStyle(
                                color: textColor.withOpacity(0.6),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (referee.details?.worldfootball?.overallTotals !=
                          null) ...[
                        const SizedBox(height: 4),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            children: [
                              const Text('🟨', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 4),
                              Text(
                                'YPG: ${referee.details!.worldfootball!.overallTotals!.yellowPerGame.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.orange.withOpacity(0.8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Arrow (now inside Expanded for better spacing)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: textColor.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
      case 'fourth':
        return '⚽';
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
      case 'fourth':
        return Colors.indigoAccent;
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
            Icons.search_off_rounded,
            size: 60,
            color: textColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '${Translations.getRefereeDirectoryText('noRefereesFound', currentLang)} 😔',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            Translations.getRefereeDirectoryText(
              'adjustSearchOrFilters',
              currentLang,
            ),
            style: TextStyle(color: textColor.withOpacity(0.7)),
            textAlign: TextAlign.center,
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
            Icons.warning_amber_rounded,
            size: 60,
            color: Colors.orange.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            '${Translations.getRefereeDirectoryText('failedToLoadReferees', currentLang)} ⚠️',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            Translations.getRefereeDirectoryText(
              'checkConnection',
              currentLang,
            ),
            style: TextStyle(color: textColor.withOpacity(0.7)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ScaleTransition(
            scale: _glowAnimation,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  futureReferees = _loadReferees();
                });
              },
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text(
                Translations.getRefereeDirectoryText('retry', currentLang),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                backgroundColor: Colors.blueAccent,
                elevation: 4,
                shadowColor: Colors.blueAccent.withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(Color textColor, String currentLang) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FootballGridPainter extends CustomPainter {
  final int mode;

  _FootballGridPainter(this.mode);

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42); // Seeded for consistency
    final gridPaint = Paint()
      ..color = AppColors.getTextColor(mode).withOpacity(0.03)
      ..strokeWidth = 0.5;

    const step = 50.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Add subtle particles for improved dynamic feel
    final particlePaint = Paint()
      ..color = AppColors.getTextColor(mode).withOpacity(0.1);
    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 2 + 1;
      canvas.drawCircle(Offset(x, y), radius, particlePaint);
    }

    final fieldPaint = Paint()
      ..color = AppColors.getTextColor(mode).withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final inset = 40.0;
    final rect = Rect.fromLTWH(
      inset,
      inset * 2,
      size.width - inset * 2,
      size.height - inset * 4,
    );
    canvas.drawRect(rect, fieldPaint);

    final midX = rect.center.dy;
    canvas.drawLine(
      Offset(rect.left + rect.width / 2 - 100, midX),
      Offset(rect.left + rect.width / 2 + 100, midX),
      fieldPaint,
    );
    canvas.drawCircle(Offset(rect.left + rect.width / 2, midX), 30, fieldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
