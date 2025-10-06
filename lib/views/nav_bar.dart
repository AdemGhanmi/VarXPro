// lib/views/nav/nav_page.dart (fixed: add back arrow leading for visitor only; ensure settings always visible; center single nav item; remove dots under emojis; only show emojis)
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:VarXPro/views/setting/provider/history_provider.dart';
import 'package:VarXPro/views/setting/views/settings_page.dart';

import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/views/connexion/providers/auth_provider.dart'; // Add auth provider

// PAGES
import 'package:VarXPro/views/pages/home/view/home_page.dart';

import 'package:VarXPro/views/pages/FauteDetectiong/service/FoulDetectionService.dart';
import 'package:VarXPro/views/pages/FauteDetectiong/faute_detection_page.dart';

import 'package:VarXPro/views/pages/FiledLinesPages/service/perspective_service.dart';
import 'package:VarXPro/views/pages/FiledLinesPages/view/key_field_lines_page.dart';

import 'package:VarXPro/views/pages/offsidePage/service/offside_service.dart';
import 'package:VarXPro/views/pages/offsidePage/view/offside_page.dart';

import 'package:VarXPro/views/pages/TrackingAndGoalAnalysis/service/tracking_service.dart';
import 'package:VarXPro/views/pages/TrackingAndGoalAnalysis/view/tracking_page.dart';

import 'package:VarXPro/views/pages/LiveStream/controller/live_stream_controller.dart';
import 'package:VarXPro/views/pages/LiveStream/views/live_stream_dashboard.dart';

class NavPage extends StatefulWidget {
  const NavPage({super.key});

  @override
  State<NavPage> createState() => _NavPageState();
}

class _NavPageState extends State<NavPage> with TickerProviderStateMixin {
  int _selectedIndex = 0;

  late List<_NavItem> _navItems;
  late final List<Widget> _pages;

  // Anim “pill” sélectionné
  late final AnimationController _pillController;
  late Animation<double> _pillScale;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomePage(),
      RepositoryProvider(create: (_) => FoulDetectionService(), child: const FoulDetectionPage()),
      RepositoryProvider(create: (_) => PerspectiveService(), child: const KeyFieldLinesPage()),
      RepositoryProvider(create: (_) => OffsideService(), child: const OffsidePage()),
      RepositoryProvider(create: (_) => TrackingService(), child: const EnhancedSoccerPlayerTrackingAndGoalAnalysisPage()),
      RepositoryProvider(create: (_) => LiveStreamController(), child: const LiveStreamDashboard()),
    ];

    _pillController = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    _pillScale = Tween<double>(begin: .92, end: 1.0)
        .animate(CurvedAnimation(parent: _pillController, curve: Curves.easeOutBack));
    _pillController.forward();
  }

  @override
  void dispose() {
    _pillController.dispose();
    super.dispose();
  }

  void _onTapNav(int i) {
    final target = _navItems[i].pageIndex;
    if (target == _selectedIndex) return;
    HapticFeedback.lightImpact();
    setState(() => _selectedIndex = target);
    _pillController..reset()..forward();
  }

  Future<bool> _showExitDialog() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App?'),
        content: const Text('Are you sure you want to exit VAR X PRO?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Exit')),
        ],
      ),
    );
    if (shouldExit == true) {
      SystemNavigator.pop(); // Exit app
    }
    return shouldExit ?? false;
  }

  String _titleForIndex(int pageIndex, String lang) {
    if (pageIndex == 0) return 'Home';
    // mapping selon Translations.getTitle(index)
    final mapToOld = {1: 0, 2: 1, 3: 2, 4: 3, 5: 4, 6: 5};
    return Translations.getTitle(mapToOld[pageIndex] ?? 0, lang);
  }

  String _emojiForIndex(int pageIndex) {
    switch (pageIndex) {
      case 0: return '🏠';
      case 1: return '🧑‍⚖️';
      case 2: return '🛑';
      case 3: return '🗺️';
      case 4: return '🚩';
      case 5: return '📊';
      case 6: return '📡';
      default: return '⚽';
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final modeProvider = Provider.of<ModeProvider>(context);
    final historyProvider = Provider.of<HistoryProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context); // Add auth check

    final currentLang = (langProvider.currentLanguage);
    final seed = AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!;
    final w = MediaQuery.sizeOf(context).width;
    final isCompact = w < 360;

    final title = _titleForIndex(_selectedIndex, currentLang);
    final emoji = _emojiForIndex(_selectedIndex);

    // Check if visitor - show only Home
    final isVisitor = !authProvider.isAuthenticated || authProvider.user?.role == 'visitor';
    _navItems = isVisitor 
        ? const [_NavItem(emoji: '🏠', pageIndex: 0)] // Only Home for visitor
        : const [
            _NavItem(emoji: '🏠', pageIndex: 0),
            _NavItem(emoji: '🧑‍⚖️', pageIndex: 1),
            _NavItem(emoji: '🗺️', pageIndex: 2),
            _NavItem(emoji: '🚩', pageIndex: 3),
            _NavItem(emoji: '📊', pageIndex: 4),
            _NavItem(emoji: '📡', pageIndex: 5),
          ];

    return WillPopScope( // Fix back behavior: For visitor, confirm before exit; for auth, stay
      onWillPop: () async {
        return await _showExitDialog();
      },
      child: Scaffold(
        extendBody: true, // pour voir le blur sous la nav bar
        backgroundColor: AppColors.getBackgroundColor(modeProvider.currentMode),

        // APP BAR modernisée
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Gradient + blur subtil
                Container(decoration: BoxDecoration(gradient: AppColors.getAppBarGradient(modeProvider.currentMode))),
                BackdropFilter(filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4), child: Container(color: Colors.transparent)),
                AppBar(
                  elevation: 0,
                  centerTitle: true,
                  backgroundColor: Colors.transparent,
                  automaticallyImplyLeading: false, // Hide implied back arrow
                  leading: isVisitor // Show back arrow only for visitor
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () async {
                            await _showExitDialog();
                          },
                        )
                      : null,
                  title: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Row(
                      key: ValueKey<String>(title),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(emoji, style: TextStyle(fontSize: isCompact ? 18 : 22)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: isCompact ? 18 : 22,
                              color: Colors.white,
                              letterSpacing: .5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    // bouton settings + badge historique (always visible, even for visitor)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            tooltip: 'Settings',
                            icon: Text('⚙️', style: TextStyle(fontSize: isCompact ? 18 : 22, color: Colors.white)), // Ensure white color for visibility
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SettingsPage(
                                    langProvider: langProvider,
                                    modeProvider: modeProvider,
                                    currentLang: currentLang,
                                  ),
                                ),
                              );
                            },
                          ),
                          if (historyProvider.historyCount > 0)
                            Positioned(
                              right: 6,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(.45), blurRadius: 8, offset: const Offset(0, 2))],
                                ),
                                child: Text(
                                  '${historyProvider.historyCount}',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // BODY - Show selected page
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) {
            final slide = Tween<Offset>(begin: const Offset(.04, 0), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
            return FadeTransition(opacity: anim, child: SlideTransition(position: slide, child: child));
          },
          child: Container(
            key: ValueKey<int>(_selectedIndex),
            decoration: BoxDecoration(gradient: AppColors.getBodyGradient(modeProvider.currentMode)),
            child: _pages[_selectedIndex],
          ),
        ),

        // NAV BAR — emojis only (filtered for visitor)
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: _EmojiOnlyNavBar(
              items: _navItems,
              seedColor: seed,
              isCompact: isCompact,
              currentPageIndex: _selectedIndex,
              onTapItem: _onTapNav,
              pillScale: _pillScale,
              mode: modeProvider.currentMode,
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------------------------------------------------------------------------
 *  MODELES & WIDGETS PRIVÉS
 * ------------------------------------------------------------------------- */

class _NavItem {
  final String emoji;
  final int pageIndex;
  const _NavItem({required this.emoji, required this.pageIndex});
}

class _EmojiOnlyNavBar extends StatelessWidget {
  final List<_NavItem> items;
  final Color seedColor;
  final bool isCompact;
  final int currentPageIndex;
  final void Function(int itemPos) onTapItem;
  final Animation<double> pillScale;
  final int mode;

  const _EmojiOnlyNavBar({
    super.key,
    required this.items,
    required this.seedColor,
    required this.isCompact,
    required this.currentPageIndex,
    required this.onTapItem,
    required this.pillScale,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final pill = seedColor.withOpacity(.16);
    final glow = seedColor.withOpacity(.35);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 6 : 10, vertical: isCompact ? 8 : 12),
          decoration: BoxDecoration(
            color: AppColors.getSurfaceColor(mode).withOpacity(.74),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(.08), width: 1),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(.12), blurRadius: 22, offset: const Offset(0, 10))],
          ),
          child: items.length == 1
              ? _SingleNavItem( // Custom for single item to center
                  item: items[0],
                  seedColor: seedColor,
                  isCompact: isCompact,
                  pillScale: pillScale,
                  mode: mode,
                )
              : Row(
                  children: List.generate(items.length, (i) {
                    final it = items[i];
                    final selected = it.pageIndex == currentPageIndex;

                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: isCompact ? 2 : 4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => onTapItem(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: EdgeInsets.symmetric(horizontal: isCompact ? 6 : 10, vertical: isCompact ? 8 : 12),
                            decoration: BoxDecoration(
                              color: selected ? pill : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: selected
                                  ? [BoxShadow(color: glow, blurRadius: 14, spreadRadius: 1, offset: const Offset(0, 3))]
                                  : [],
                            ),
                            child: ScaleTransition(
                              scale: selected ? pillScale : const AlwaysStoppedAnimation(1.0),
                              child: Text(
                                it.emoji,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: isCompact ? 18 : 20),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
        ),
      ),
    );
  }
}

class _SingleNavItem extends StatelessWidget {
  final _NavItem item;
  final Color seedColor;
  final bool isCompact;
  final Animation<double> pillScale;
  final int mode;

  const _SingleNavItem({
    required this.item,
    required this.seedColor,
    required this.isCompact,
    required this.pillScale,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final pill = seedColor.withOpacity(.16);
    final glow = seedColor.withOpacity(.35);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {}, // No other items, so no action
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: isCompact ? 6 : 10, vertical: isCompact ? 8 : 12),
        decoration: BoxDecoration(
          color: pill, // Always "selected" style
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: glow, blurRadius: 14, spreadRadius: 1, offset: const Offset(0, 3))],
        ),
        child: ScaleTransition(
          scale: pillScale,
          child: Text(
            item.emoji,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: isCompact ? 18 : 20),
          ),
        ),
      ),
    );
  }
}
