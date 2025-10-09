// lib/views/pages/home/view/details_arbiter/detail_arbiter.dart
import 'package:VarXPro/views/pages/home/service/evaluations_service.dart';
import 'package:VarXPro/views/pages/home/view/details_arbiter/competitions_tab.dart';
import 'package:VarXPro/views/pages/home/view/details_arbiter/details_tab.dart';
import 'package:VarXPro/views/pages/home/view/details_arbiter/evaluations/evaluations_tab.dart';
import 'package:VarXPro/views/pages/home/view/details_arbiter/football_grid_painter.dart';
import 'package:VarXPro/views/pages/home/view/details_arbiter/referee_tracking_tab.dart';
import 'package:VarXPro/views/pages/home/view/details_arbiter/statistics_tab.dart';
import 'package:flutter/material.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/views/pages/home/model/home_model.dart';
import 'package:VarXPro/lang/translation.dart';
import 'package:provider/provider.dart';
import 'package:VarXPro/views/connexion/providers/auth_provider.dart';
import 'evaluations/create_evaluation_page.dart'; // New import for full page

class DetailArbiter extends StatefulWidget {
  final Referee referee;

  const DetailArbiter({super.key, required this.referee});

  @override
  State<DetailArbiter> createState() => _DetailArbiterState();
}

class _DetailArbiterState extends State<DetailArbiter>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  TabController? _tabController;
  bool _isSupervisor = false;
  bool _isUser = false;
  bool _isVisitor = false;
  late int _tabLength;
  late List<Tab> _tabs;
  late List<Widget> _tabViews;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
          ),
        );
    // Initialize with defaults
    _tabLength = 0;
    _tabs = [];
    _tabViews = [];
    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tabController == null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final role = authProvider.user?.role ?? 'visitor';
      _isSupervisor = role == 'supervisor';
      _isUser = role == 'user';
      _isVisitor = role == 'visitor';
      final currentUserId =
          authProvider.user?.id?.toString() ?? ''; // Get user id
      _setupTabs(currentUserId); // Pass to setup
      _tabController = TabController(length: _tabLength, vsync: this);

      _tabController!.addListener(() {
        if (_tabController!.indexIsChanging) {
          _animationController.reset();
          _animationController.forward();
        }
      });
    }
  }

void _setupTabs(String currentUserId) {
  final langProvider = Provider.of<LanguageProvider>(context, listen: false);
  final currentLang = langProvider.currentLanguage ?? 'en';
  final modeProvider = Provider.of<ModeProvider>(context, listen: false);
  final textColor = AppColors.getTextColor(modeProvider.currentMode);
  final seedColor =
      AppColors.seedColors[modeProvider.currentMode] ??
      AppColors.seedColors[1]!;
  final screenWidth = MediaQuery.of(context).size.width;
  final isLargeScreen = screenWidth > 600;

  // ترجمة النصوص للتبويبات حسب اللغة
  final detailsTabText = Translations.getRefereeDetailsText('detailsTab', currentLang);
  final statisticsTabText = Translations.getRefereeDetailsText('statisticsTab', currentLang);
  final competitionsTabText = Translations.getRefereeDetailsText('competitionsTab', currentLang);
  final evaluationsTabText = Translations.getRefereeDetailsText('evaluationsTab', currentLang);
  final refereeTrackingTabText = Translations.getRefereeDetailsText('refereeTrackingTab', currentLang);

  if (_isVisitor) {
    // For visitor: only Details, Statistics, Competitions with emojis
    _tabs = [
      Tab(text: 'ℹ️ $detailsTabText'),
      Tab(text: '📊 $statisticsTabText'),
      Tab(text: '🏆 $competitionsTabText'),
    ];
    _tabViews = [
      DetailsTab(
        referee: widget.referee,
        currentLang: currentLang,  // مرر اللغة للـ sub-widget عشان يترجم جواه
        textColor: textColor,
        isLargeScreen: isLargeScreen,
        animationController: _animationController,
      ),
      StatisticsTab(
        referee: widget.referee,
        currentLang: currentLang,  // مرر اللغة
        textColor: textColor,
        isLargeScreen: isLargeScreen,
        animationController: _animationController,
        modeProvider: modeProvider,
        seedColor: seedColor,
      ),
      CompetitionsTab(
        referee: widget.referee,
        currentLang: currentLang,  // مرر اللغة
        textColor: textColor,
        isLargeScreen: isLargeScreen,
        animationController: _animationController,
        modeProvider: modeProvider,
        seedColor: seedColor,
      ),
    ];
    _tabLength = 3;
  } else if (_isUser) {
    // For user: Details, Statistics, Competitions, Evaluations (view + create)
    _tabs = [
      Tab(text: 'ℹ️ $detailsTabText'),
      Tab(text: '📊 $statisticsTabText'),
      Tab(text: '🏆 $competitionsTabText'),
      Tab(text: '📋 $evaluationsTabText'),
      Tab(text: '👨‍⚖️ $refereeTrackingTabText'),
    ];
    _tabViews = [
      DetailsTab(
        referee: widget.referee,
        currentLang: currentLang,
        textColor: textColor,
        isLargeScreen: isLargeScreen,
        animationController: _animationController,
      ),
      StatisticsTab(
        referee: widget.referee,
        currentLang: currentLang,
        textColor: textColor,
        isLargeScreen: isLargeScreen,
        animationController: _animationController,
        modeProvider: modeProvider,
        seedColor: seedColor,
      ),
      CompetitionsTab(
        referee: widget.referee,
        currentLang: currentLang,
        textColor: textColor,
        isLargeScreen: isLargeScreen,
        animationController: _animationController,
        modeProvider: modeProvider,
        seedColor: seedColor,
      ),
      EvaluationsTab(
        refereeId: widget.referee.id,
        isSupervisor: _isSupervisor,
        isUser: _isUser,
        onCreate: _navigateToCreateEvaluation,
        onUpdate: _updateEvaluation,
        currentLang: currentLang,  // مرر اللغة
        textColor: textColor,
        isLargeScreen: isLargeScreen,
        animationController: _animationController,
        modeProvider: modeProvider,
        seedColor: seedColor,
        currentUserId: currentUserId,
      ),
      RefereeTrackingTab(
        currentLang: currentLang,
        textColor: textColor,
        isLargeScreen: isLargeScreen,
        animationController: _animationController,
        modeProvider: modeProvider,
        seedColor: seedColor,
        isSupervisor: _isSupervisor,
      ),
    ];
    _tabLength = 5;
  } else {
    // For supervisor: all 5 tabs with full access
    _tabs = [
      Tab(text: 'ℹ️ $detailsTabText'),
      Tab(text: '📊 $statisticsTabText'),
      Tab(text: '🏆 $competitionsTabText'),
      Tab(text: '📋 $evaluationsTabText'),
      Tab(text: '👨‍⚖️ $refereeTrackingTabText'),
    ];
    _tabViews = [
      // نفس الـ views زي فوق، بس isSupervisor: true
      DetailsTab(
        referee: widget.referee,
        currentLang: currentLang,
        textColor: textColor,
        isLargeScreen: isLargeScreen,
        animationController: _animationController,
      ),
      StatisticsTab(
        referee: widget.referee,
        currentLang: currentLang,
        textColor: textColor,
        isLargeScreen: isLargeScreen,
        animationController: _animationController,
        modeProvider: modeProvider,
        seedColor: seedColor,
      ),
      CompetitionsTab(
        referee: widget.referee,
        currentLang: currentLang,
        textColor: textColor,
        isLargeScreen: isLargeScreen,
        animationController: _animationController,
        modeProvider: modeProvider,
        seedColor: seedColor,
      ),
      EvaluationsTab(
        refereeId: widget.referee.id,
        isSupervisor: true,
        isUser: false,
        onCreate: _navigateToCreateEvaluation,
        onUpdate: _updateEvaluation,
        currentLang: currentLang,
        textColor: textColor,
        isLargeScreen: isLargeScreen,
        animationController: _animationController,
        modeProvider: modeProvider,
        seedColor: seedColor,
        currentUserId: currentUserId,
      ),
      RefereeTrackingTab(
        currentLang: currentLang,
        textColor: textColor,
        isLargeScreen: isLargeScreen,
        animationController: _animationController,
        modeProvider: modeProvider,
        seedColor: seedColor,
        isSupervisor: _isSupervisor,
      ),
    ];
    _tabLength = 5;
  }
}
  Future<void> _updateEvaluation(
    int evalId,
    Map<String, dynamic> updates,
    String lang,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final role = authProvider.user?.role ?? 'visitor';
    if (role == 'visitor') {
      _showSnackBar('Only authenticated users can update ✏️', Colors.orange);
      return;
    }

    // Additional check: fetch eval to verify author, but since UI already checks, optional
    // For safety, proceed as is, since service will return 403 if not author

    try {
      final result = await EvaluationsService.updateEvaluation(evalId, updates, lang);
      if (result['success']) {
        if (mounted) {
          _showSnackBar('Evaluation updated successfully! ✅', Colors.green);
        }
      } else {
        if (mounted) {
          _showSnackBar(result['error'] ?? 'Failed to update ❌', Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error updating: $e 🌐', Colors.red);
      }
    }
  }

  void _navigateToCreateEvaluation() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final role = authProvider.user?.role ?? 'visitor';
    if (role == 'visitor') {
      // Restrict to authenticated users only (API requires it)
      _showSnackBar(
        'Only authenticated users can create evaluations 📝',
        Colors.orange,
      );
      return;
    }

    final refereeId = widget.referee.id ?? '';
    if (refereeId.isEmpty) {
      _showSnackBar('Invalid referee ID 👨‍⚖️', Colors.red);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEvaluationPage(
          externalRefId: refereeId,
          refereeName: widget.referee.name,
        ),
      ),
    ).then((success) {
      if (success == true) {
        _showSnackBar('Evaluation created! Reload to see 📋', Colors.green);
      }
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final modeProvider = Provider.of<ModeProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final currentLang = langProvider.currentLanguage ?? 'en';
    final textColor = AppColors.getTextColor(modeProvider.currentMode);
    final seedColor =
        AppColors.seedColors[modeProvider.currentMode] ??
        AppColors.seedColors[1]!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;
    final textDirection = currentLang == 'ar' ? TextDirection.rtl : TextDirection.ltr;

    final double rating = 4.2;

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Text('👨‍⚖️ '),
              Expanded(
                child: Text(
                  '${Translations.getRefereeDetailsText('title', currentLang)}',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: isLargeScreen ? 24 : 20,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.getSurfaceColor(modeProvider.currentMode),
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            labelColor: textColor,
            unselectedLabelColor: textColor.withOpacity(0.6),
            indicatorColor: seedColor,
            tabs: _tabs,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.star, color: Colors.amber),
              onPressed: () {},
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: FootballGridPainter(modeProvider.currentMode),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        seedColor.withOpacity(0.1),
                        seedColor.withOpacity(0.05),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.all(isLargeScreen ? 24.0 : 16.0),
                child: Column(
                  children: [
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.getSurfaceColor(
                                  modeProvider.currentMode,
                                ),
                                AppColors.getSurfaceColor(
                                  modeProvider.currentMode,
                                ).withOpacity(0.8),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.getShadowColor(
                                  seedColor,
                                  modeProvider.currentMode,
                                ).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              _buildProfileAvatar(widget.referee, isLargeScreen),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${widget.referee.details?.worldfootball?.profile?.completeName ?? widget.referee.name}',
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: isLargeScreen ? 24 : 20,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '🏳️ ${widget.referee.country}, ${widget.referee.details?.worldfootball?.profile?.placeOfBirth ?? ''}',
                                      style: TextStyle(
                                        color: textColor.withOpacity(0.7),
                                        fontSize: isLargeScreen ? 16 : 14,
                                      ),
                                    ),
                                    if (widget
                                                .referee
                                                .details
                                                ?.worldfootball
                                                ?.profile
                                                ?.born !=
                                            null &&
                                        widget
                                            .referee
                                            .details!
                                            .worldfootball!
                                            .profile!
                                            .born!
                                            .isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        '📅 Born: ${widget.referee.details!.worldfootball!.profile!.born}',
                                        style: TextStyle(
                                          color: textColor.withOpacity(0.7),
                                          fontSize: isLargeScreen ? 14 : 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        ...List.generate(5, (index) {
                                          if (index < rating.floor()) {
                                            return const Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                              size: 16,
                                            );
                                          } else if (index < rating) {
                                            return const Icon(
                                              Icons.star_half,
                                              color: Colors.amber,
                                              size: 16,
                                            );
                                          } else {
                                            return const Icon(
                                              Icons.star_border,
                                              color: Colors.amber,
                                              size: 16,
                                            );
                                          }
                                        }),
                                        const SizedBox(width: 4),
                                        Text(
                                          '⭐ ${rating.toStringAsFixed(1)} / 5',
                                          style: TextStyle(
                                            color: textColor.withOpacity(0.7),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: TabBarView(
                          controller: _tabController,
                          children: _tabViews,
                        ),
                      ),
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

  Widget _buildProfileAvatar(Referee referee, bool isLargeScreen) {
    return CircleAvatar(
      radius: isLargeScreen ? 50 : 40,
      backgroundColor: referee.gender == 'Male'
          ? Colors.blueAccent.withOpacity(0.2)
          : Colors.pinkAccent.withOpacity(0.2),
      child: Icon(
        referee.gender == 'Male' ? Icons.male_rounded : Icons.female_rounded,
        size: isLargeScreen ? 40 : 32,
        color: referee.gender == 'Male' ? Colors.blueAccent : Colors.pinkAccent,
      ),
    );
  }
}