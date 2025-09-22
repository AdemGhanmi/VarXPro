import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/views/pages/home/model/home_model.dart';
import 'package:VarXPro/lang/translation.dart';
import 'package:provider/provider.dart';

class DetailArbiter extends StatefulWidget {
  final Referee referee;

  const DetailArbiter({
    super.key,
    required this.referee,
  });

  @override
  State<DetailArbiter> createState() => _DetailArbiterState();
}

class _DetailArbiterState extends State<DetailArbiter>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late TabController _tabController;

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
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
    ));
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _animationController.reset();
        _animationController.forward();
      }
    });
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modeProvider = Provider.of<ModeProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final currentLang = langProvider.currentLanguage ?? 'en';
    final textColor = AppColors.getTextColor(modeProvider.currentMode);
    final seedColor =
        AppColors.seedColors[modeProvider.currentMode] ??
        AppColors.seedColors[1]!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

    // Fake rating for demonstration (can be replaced with real data)
    final double rating = 4.2;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          Translations.getRefereeDetailsText('title', currentLang),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: isLargeScreen ? 24 : 20,
          ),
        ),
        backgroundColor: AppColors.getSurfaceColor(modeProvider.currentMode),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: textColor,
          unselectedLabelColor: textColor.withOpacity(0.6),
          indicatorColor: seedColor,
          tabs: [
            Tab(icon: Icon(Icons.info_outline_rounded), text: 'Details'),
            Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Statistics'),
            Tab(icon: Icon(Icons.sports_soccer_rounded), text: 'Competitions'),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.star, color: Colors.amber),
            onPressed: () {
              // Toggle favorite or something
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background with subtle football field grid
          Positioned.fill(
            child: CustomPaint(
              painter: _FootballGridPainter(modeProvider.currentMode),
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
                  // Profile Header with Rating
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
                              AppColors.getSurfaceColor(modeProvider.currentMode),
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
                                    widget.referee.details?.worldfootball?.profile?.completeName ?? widget.referee.name,
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
                                    '${widget.referee.country}, ${widget.referee.details?.worldfootball?.profile?.placeOfBirth ?? ''}',
                                    style: TextStyle(
                                      color: textColor.withOpacity(0.7),
                                      fontSize: isLargeScreen ? 16 : 14,
                                    ),
                                  ),
                                  if (widget.referee.details?.worldfootball?.profile?.born != null &&
                                      widget.referee.details!.worldfootball!.profile!.born!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Born: ${widget.referee.details!.worldfootball!.profile!.born}',
                                      style: TextStyle(
                                        color: textColor.withOpacity(0.7),
                                        fontSize: isLargeScreen ? 14 : 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  // Rating with stars
                                  Row(
                                    children: [
                                      ...List.generate(5, (index) {
                                        if (index < rating.floor()) {
                                          return Icon(Icons.star, color: Colors.amber, size: 16);
                                        } else if (index < rating) {
                                          return Icon(Icons.star_half, color: Colors.amber, size: 16);
                                        } else {
                                          return Icon(Icons.star_border, color: Colors.amber, size: 16);
                                        }
                                      }),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${rating.toStringAsFixed(1)} / 5',
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
                        children: [
                          // Details Tab
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Translations.getRefereeDetailsText(
                                    'details',
                                    currentLang,
                                  ),
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isLargeScreen ? 20 : 18,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildDetailRow(
                                  icon: Icons.account_balance_rounded,
                                  label: Translations.getRefereeDetailsText(
                                    'confederation',
                                    currentLang,
                                  ),
                                  value: widget.referee.confed,
                                  textColor: textColor,
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  icon: Icons.calendar_month_rounded,
                                  label: Translations.getRefereeDetailsText(
                                    'since',
                                    currentLang,
                                  ),
                                  value: widget.referee.since.toString(),
                                  textColor: textColor,
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  icon: widget.referee.gender == 'Male'
                                      ? Icons.male_rounded
                                      : Icons.female_rounded,
                                  label: Translations.getRefereeDetailsText(
                                    'gender',
                                    currentLang,
                                  ),
                                  value: widget.referee.gender,
                                  textColor: textColor,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  Translations.getRefereeDetailsText('roles', currentLang),
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: isLargeScreen ? 18 : 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (widget.referee.roles.isNotEmpty)
                                  AnimatedBuilder(
                                    animation: _animationController,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _animationController.value,
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: widget.referee.roles
                                              .map(
                                                (role) => Chip(
                                                  label: Text(
                                                    role,
                                                    style: TextStyle(
                                                      color: _getRoleColor(role),
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  backgroundColor: _getRoleColor(
                                                    role,
                                                  ).withOpacity(0.2),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      );
                                    },
                                  )
                                else
                                  Text(
                                    Translations.getRefereeDetailsText(
                                      'noRolesSpecified',
                                      currentLang,
                                    ),
                                    style: TextStyle(
                                      color: textColor.withOpacity(0.6),
                                      fontSize: isLargeScreen ? 16 : 14,
                                    ),
                                  ),
                                // Badges based on roles or stats
                                if (widget.referee.roles.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    'Badges',
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isLargeScreen ? 18 : 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  AnimatedBuilder(
                                    animation: _animationController,
                                    builder: (context, child) {
                                      return Opacity(
                                        opacity: _animationController.value,
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            if (widget.referee.roles.any((r) => r.toLowerCase() == 'var'))
                                              Chip(
                                                avatar: Icon(Icons.videocam, color: Colors.purple),
                                                label: Text('VAR Expert', style: TextStyle(color: Colors.purple)),
                                                backgroundColor: Colors.purple.withOpacity(0.1),
                                              ),
                                            Chip(
                                              avatar: Icon(Icons.sports_soccer, color: Colors.green),
                                              label: Text('Active Referee', style: TextStyle(color: Colors.green)),
                                              backgroundColor: Colors.green.withOpacity(0.1),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Statistics Tab
                          if (widget.referee.details?.worldfootball?.overallTotals != null)
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: SingleChildScrollView(
                                key: ValueKey(_tabController.index),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 16),
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 600),
                                      curve: Curves.easeInOut,
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
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        children: [
                                          AnimatedSwitcher(
                                            duration: const Duration(milliseconds: 400),
                                            child: Row(
                                              key: ValueKey('stats_row_${_tabController.index}'),
                                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                              children: [
                                                _buildStatCard(
                                                  label: 'Matches',
                                                  value1: widget.referee.details!.worldfootball!.overallTotals!.matches.toString(),
                                                  icon: Icons.sports_soccer,
                                                  iconColor: Colors.green,
                                                  textColor: textColor,
                                                ),
                                                _buildStatCard(
                                                  label: 'Yellow Cards',
                                                  value1: widget.referee.details!.worldfootball!.overallTotals!.yellow.toString(),
                                                  icon: Icons.warning_amber_rounded,
                                                  iconColor: Colors.orange,
                                                  textColor: textColor,
                                                ),
                                                _buildStatCard(
                                                  label: 'Red Cards',
                                                  value1: widget.referee.details!.worldfootball!.overallTotals!.red.toString(),
                                                  icon: Icons.block,
                                                  iconColor: Colors.red,
                                                  textColor: textColor,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          _buildStatCard(
                                            label: 'Yellow per Game',
                                            value1: '${widget.referee.details!.worldfootball!.overallTotals!.yellowPerGame.toStringAsFixed(2)}',
                                            icon: Icons.trending_up,
                                            iconColor: Colors.blue,
                                            textColor: textColor,
                                            isFullWidth: true,
                                          ),
                                          const SizedBox(height: 16),
                                          // Pie Chart for Yellow/Red Distribution
                                          SizedBox(
                                            height: 200,
                                            child: AnimatedBuilder(
                                              animation: _animationController,
                                              builder: (context, child) {
                                                return Transform.scale(
                                                  scale: 0.9 + 0.1 * _animationController.value,
                                                  child: AnimatedOpacity(
                                                    opacity: _animationController.value,
                                                    duration: const Duration(milliseconds: 500),
                                                    child: PieChart(
                                                      PieChartData(
                                                        pieTouchData: PieTouchData(touchCallback: (FlTouchEvent event, pieTouchResponse) {}),
                                                        borderData: FlBorderData(show: false),
                                                        sectionsSpace: 2,
                                                        centerSpaceRadius: 40,
                                                        sections: _getPieChartSections(
                                                          widget.referee.details!.worldfootball!.overallTotals!,
                                                          textColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          // Radar Chart for Stats
                                          SizedBox(
                                            height: 250,
                                            child: AnimatedBuilder(
                                              animation: _animationController,
                                              builder: (context, child) {
                                                return Transform.rotate(
                                                  angle: _animationController.value * 0.1,
                                                  child: AnimatedOpacity(
                                                    opacity: _animationController.value,
                                                    duration: const Duration(milliseconds: 700),
                                                    child: RadarChart(
                                                      RadarChartData(
                                                        radarShape: RadarShape.circle,
                                                        dataSets: _getRadarDataSets(
                                                          widget.referee.details!.worldfootball!.overallTotals!,
                                                          textColor,
                                                        ),
                                                        radarBorderData: BorderSide(color: textColor.withOpacity(0.3)),
                                                        tickCount: 5,
                                                        ticksTextStyle: TextStyle(color: textColor.withOpacity(0.5), fontSize: 10),
                                                        tickBorderData: BorderSide(color: textColor.withOpacity(0.3)),
                                                        gridBorderData: BorderSide(color: textColor.withOpacity(0.2)),
                                                        getTitle: (index, angle) {
                                                          final titles = ['Matches', 'Yellows', 'Reds', 'YPG*10'];
                                                          return RadarChartTitle(
                                                            text: titles[index % titles.length],
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            const Center(child: Text('No statistics available')),
                          // Competitions Tab - Enhanced with GridView for nicer display
                          if (widget.referee.details?.worldfootball?.competitions != null)
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: SingleChildScrollView(
                                key: ValueKey(_tabController.index),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 16),
                                    Text(
                                      'Recent Competitions',
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: isLargeScreen ? 20 : 18,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      height: 450, // Reduced height slightly
                                      child: AnimatedBuilder(
                                        animation: _animationController,
                                        builder: (context, child) {
                                          return Opacity(
                                            opacity: _animationController.value,
                                            child: GridView.builder(
                                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: isLargeScreen ? 2 : 1,
                                                childAspectRatio: 1.4, // Increased to make cards slightly shorter and wider for smaller feel
                                                crossAxisSpacing: 8, // Reduced spacing on sides
                                                mainAxisSpacing: 8, // Reduced spacing
                                              ),
                                              itemCount: widget.referee.details!.worldfootball!.competitions.take(6).length, // Limited to 6 for grid
                                              itemBuilder: (context, index) {
                                                final comp = widget.referee.details!.worldfootball!.competitions[index];
                                                return AnimatedBuilder(
                                                  animation: _animationController,
                                                  builder: (context, child) {
                                                    return GestureDetector(
                                                      onTapDown: (_) {
                                                        // Trigger animation on touch
                                                        _animationController.reset();
                                                        _animationController.forward();
                                                      },
                                                      child: TweenAnimationBuilder<double>(
                                                        duration: const Duration(milliseconds: 200),
                                                        tween: Tween(begin: 1.0, end: 0.95),
                                                        builder: (context, scale, child) => Transform.scale(
                                                          scale: scale,
                                                          child: child,
                                                        ),
                                                        child: AnimatedContainer(
                                                          duration: Duration(milliseconds: 300 + index * 150),
                                                          curve: Curves.easeInOut,
                                                          decoration: BoxDecoration(
                                                            color: AppColors.getSurfaceColor(modeProvider.currentMode),
                                                            borderRadius: BorderRadius.circular(16),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors.black.withOpacity(0.1),
                                                                blurRadius: 10,
                                                                offset: const Offset(0, 4),
                                                              ),
                                                            ],
                                                          ),
                                                          child: InkWell(
                                                            borderRadius: BorderRadius.circular(16),
                                                            onTap: () {
                                                              // Navigate to competition details if needed
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                SnackBar(content: Text('Tapped on ${comp.name}')),
                                                              );
                                                            },
                                                            child: Padding(
                                                              padding: const EdgeInsets.all(12), // Reduced padding for smaller cards
                                                              child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                children: [
                                                                  // Competition Name
                                                                  Expanded(
                                                                    flex: 2,
                                                                    child: Column(
                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                      children: [
                                                                        Text(
                                                                          comp.name,
                                                                          style: TextStyle(
                                                                            color: textColor,
                                                                            fontWeight: FontWeight.w700,
                                                                            fontSize: isLargeScreen ? 15 : 13, // Slightly smaller font
                                                                          ),
                                                                          maxLines: 2,
                                                                          overflow: TextOverflow.ellipsis,
                                                                        ),
                                                                        const SizedBox(height: 8),
                                                                        Container(
                                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                          decoration: BoxDecoration(
                                                                            color: seedColor.withOpacity(0.1),
                                                                            borderRadius: BorderRadius.circular(12),
                                                                          ),
                                                                          child: Text(
                                                                            'Total Cards: ${comp.totals.yellow + comp.totals.red + comp.totals.secondYellow}',
                                                                            style: TextStyle(
                                                                              color: textColor.withOpacity(0.8),
                                                                              fontSize: isLargeScreen ? 11 : 10, // Smaller font
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  const SizedBox(height: 8), // Reduced from 12 to 8
                                                                  // Stats Row 1: Matches, Yellow, Red
                                                                  Expanded(
                                                                    flex: 1,
                                                                    child: Row(
                                                                      children: [
                                                                        Expanded(
                                                                          child: _buildMiniStat(
                                                                            'Matches',
                                                                            comp.totals.matches.toString(),
                                                                            Icons.sports_soccer,
                                                                            Colors.green,
                                                                            textColor,
                                                                          ),
                                                                        ),
                                                                        Expanded(
                                                                          child: _buildMiniStat(
                                                                            'Yellow',
                                                                            comp.totals.yellow.toString(),
                                                                            Icons.warning_amber_rounded,
                                                                            Colors.orange,
                                                                            textColor,
                                                                          ),
                                                                        ),
                                                                        Expanded(
                                                                          child: _buildMiniStat(
                                                                            'Red',
                                                                            (comp.totals.red + comp.totals.secondYellow).toString(),
                                                                            Icons.block,
                                                                            Colors.red,
                                                                            textColor,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  // Stats Row 2: Yellow per Game and Mini Progress
                                                                  Padding(
                                                                    padding: const EdgeInsets.only(top: 4), // Reduced from 8 to 4
                                                                    child: Column(
                                                                      children: [
                                                                        Row(
                                                                          children: [
                                                                            Expanded(
                                                                              child: _buildMiniStat(
                                                                                'YPG',
                                                                                comp.totals.yellowPerGame.toStringAsFixed(2),
                                                                                Icons.trending_up,
                                                                                Colors.blue,
                                                                                textColor,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        const SizedBox(height: 4), // Reduced from 6 to 4
                                                                        // Mini Progress Bar for YPG
                                                                        LinearProgressIndicator(
                                                                          value: (comp.totals.yellowPerGame / 5).clamp(0.0, 1.0), // Assuming max 5 YPG
                                                                          backgroundColor: textColor.withOpacity(0.2),
                                                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.withOpacity(0.7)),
                                                                          minHeight: 3, // Reduced from 4 to 3
                                                                          borderRadius: BorderRadius.circular(2),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            const Center(child: Text('No competitions available')),
                        ],
                      ),
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

  Widget _buildProfileAvatar(Referee referee, bool isLargeScreen) {
    return CircleAvatar(
      radius: isLargeScreen ? 50 : 40,
      backgroundColor: referee.gender == 'Male'
          ? Colors.blueAccent.withOpacity(0.2)
          : Colors.pinkAccent.withOpacity(0.2),
      child: Icon(
        referee.gender == 'Male'
            ? Icons.male_rounded
            : Icons.female_rounded,
        size: isLargeScreen ? 40 : 32,
        color: referee.gender == 'Male'
            ? Colors.blueAccent
            : Colors.pinkAccent,
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, Color iconColor, Color textColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor), // Reduced from 18 to 16
        const SizedBox(height: 2), // Reduced from 4 to 2
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 11, // Reduced from 12 to 11
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(
            color: textColor.withOpacity(0.7),
            fontSize: 9, // Reduced from 10 to 9
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  List<PieChartSectionData> _getPieChartSections(OverallTotals totals, Color textColor) {
    final totalCards = totals.yellow + totals.red;
    if (totalCards == 0) {
      return [PieChartSectionData(color: Colors.grey, value: 1, radius: 60)];
    }
    return [
      PieChartSectionData(
        color: Colors.orange,
        value: totals.yellow.toDouble(),
        title: '${totals.yellow}',
        radius: 60,
        titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
      ),
      PieChartSectionData(
        color: Colors.red,
        value: totals.red.toDouble(),
        title: '${totals.red}',
        radius: 60,
        titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
      ),
    ];
  }

  List<RadarDataSet> _getRadarDataSets(OverallTotals totals, Color textColor) {
    final values = [totals.matches.toDouble(), totals.yellow.toDouble(), totals.red.toDouble(), totals.yellowPerGame * 10];
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return [
      RadarDataSet(
        fillColor: Colors.blue.withOpacity(0.2),
        borderColor: Colors.blue,
        dataEntries: values.map((v) => RadarEntry(value: v / maxValue * 100)).toList(),
        borderWidth: 2,
        entryRadius: 4,
      ),
    ];
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: textColor.withOpacity(0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value1,
    required IconData icon,
    required Color iconColor,
    required Color textColor,
    bool isFullWidth = false,
  }) {
    final container = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 4),
          Text(
            value1,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: textColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textColor.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
    if (isFullWidth) {
      return container;
    } else {
      return Expanded(child: container);
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
      default:
        return Colors.grey;
    }
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