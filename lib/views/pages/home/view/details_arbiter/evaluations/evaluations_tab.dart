import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/views/connexion/providers/auth_provider.dart';
import 'package:VarXPro/views/pages/home/service/evaluations_service.dart';
import 'package:VarXPro/lang/translation.dart';

class EvaluationsTab extends StatefulWidget {
  final String refereeId;
  final bool isSupervisor;
  final bool isUser;
  final VoidCallback onCreate;
  final Future<void> Function(int, Map<String, dynamic>, String) onUpdate;
  final String currentLang;
  final Color textColor;
  final bool isLargeScreen;
  final AnimationController animationController;
  final ModeProvider modeProvider;
  final Color seedColor;
  final String currentUserId;

  const EvaluationsTab({
    super.key,
    required this.refereeId,
    required this.isSupervisor,
    required this.isUser,
    required this.onCreate,
    required this.onUpdate,
    required this.currentLang,
    required this.textColor,
    required this.isLargeScreen,
    required this.animationController,
    required this.modeProvider,
    required this.seedColor,
    required this.currentUserId,
  });

  @override
  _EvaluationsTabState createState() => _EvaluationsTabState();
}

class _EvaluationsTabState extends State<EvaluationsTab>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _evaluations = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadEvaluations();
  }

  Future<void> _loadEvaluations() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isGuest = !authProvider.isAuthenticated;
    if (isGuest || widget.refereeId.isEmpty) {
      setState(() {
        _evaluations = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await EvaluationsService.listRefereeEvaluations(
        widget.refereeId,
        widget.currentLang,
      );
      if (result['success'] == true) {
        setState(() {
          _evaluations = List<Map<String, dynamic>>.from(result['data'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          _showErrorSnackBar(
            result['error'] ??
                Translations.getEvaluationText(
                  'failedToLoadEvaluations',
                  widget.currentLang,
                ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorSnackBar(
          Translations.getEvaluationText(
                'errorLoadingEvaluations',
                widget.currentLang,
              ) +
              ': $e 🔄',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isGuest = !authProvider.isAuthenticated;
    final textDirection = widget.currentLang == 'ar'
        ? TextDirection.rtl
        : TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: RefreshIndicator(
        onRefresh: _loadEvaluations,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bouton de création placé au-dessus et aligné à côté du titre "evaluations"
              if (widget.isSupervisor && !isGuest)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Align(
                    alignment: textDirection == TextDirection.rtl
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      onPressed: widget.onCreate,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(
                        Translations.getEvaluationText(
                          'createNewEvaluation',
                          widget.currentLang,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.seedColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ),
              _GlassHeader(
                title: Translations.getEvaluationText(
                  'evaluations',
                  widget.currentLang,
                ),
                seedColor: widget.seedColor,
                textColor: widget.textColor,
              ),
              const SizedBox(height: 16),

              if (isGuest)
                _InfoCard(
                  icon: Icons.lock_outline,
                  color: Colors.orange,
                  title: Translations.getEvaluationText(
                    'loginToView',
                    widget.currentLang,
                  ),
                  subtitle: Translations.getEvaluationText(
                    'signInAsUserOrSupervisor',
                    widget.currentLang,
                  ),
                  seedColor: widget.seedColor,
                )
              else if (_isLoading)
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 6),
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(
                        Translations.getEvaluationText(
                          'loadingEvaluations',
                          widget.currentLang,
                        ),
                        style: TextStyle(color: widget.textColor),
                      ),
                    ],
                  ),
                )
              else if (_evaluations.isEmpty)
                _GlassBlock(
                  seedColor: widget.seedColor,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 80,
                        color: widget.textColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        Translations.getEvaluationText(
                          'noEvaluations',
                          widget.currentLang,
                        ),
                        style: TextStyle(
                          color: widget.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Translations.getEvaluationText(
                          'createOneToGetStarted',
                          widget.currentLang,
                        ),
                        style: TextStyle(
                          color: widget.textColor.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadEvaluations,
                        icon: const Icon(Icons.refresh),
                        label: Text(
                          Translations.getEvaluationText(
                            'reload',
                            widget.currentLang,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.seedColor,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _evaluations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final eval = _evaluations[index];
                    final isAuthor =
                        widget.currentUserId ==
                        (eval['evaluator_id']?.toString());
                    final ratingColor = _getRatingColor(
                      eval['overall_rating']?.toString() ?? '',
                    );

                    return _EvaluationCard(
                      eval: eval,
                      seedColor: widget.seedColor,
                      textColor: widget.textColor,
                      ratingColor: ratingColor,
                      isSupervisor: widget.isSupervisor,
                      isAuthor: isAuthor,
                      lang: widget.currentLang,
                      onTap: () => _navigateToDetails(context, eval),
                      onEdit: () =>
                          _showEditDialog(context, eval['id'] as int, eval),
                      onDelete: () =>
                          _showDeleteConfirm(context, eval['id'] as int),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDetails(BuildContext context, Map<String, dynamic> eval) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EvaluationDetailsPage(
          evaluation: eval,
          currentLang: widget.currentLang,
          textColor: widget.textColor,
          isLargeScreen: widget.isLargeScreen,
          modeProvider: widget.modeProvider,
          seedColor: widget.seedColor,
          currentUserId: widget.currentUserId,
          isSupervisor: widget.isSupervisor,
        ),
      ),
    );
  }

  Color _getRatingColor(String rating) {
    switch (rating.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'very_good':
        return Colors.blue;
      case 'good':
        return Colors.orange;
      case 'acceptable':
        return Colors.amber;
      default:
        return Colors.red;
    }
  }

  void _showEditDialog(
    BuildContext context,
    int id,
    Map<String, dynamic> eval,
  ) {
    final isAuthor = widget.currentUserId == eval['evaluator_id']?.toString();
    if (!isAuthor) {
      _showErrorSnackBar(
        Translations.getEvaluationText('youCanOnlyEditOwn', widget.currentLang),
      );
      return;
    }

    final notesController = TextEditingController(text: eval['notes'] ?? '');
    final scoreController = TextEditingController(
      text: (eval['total_score'] ?? '').toString(),
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.edit, color: widget.seedColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      Translations.getEvaluationText(
                        'editEvaluation',
                        widget.currentLang,
                      ),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: widget.textColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: Translations.getEvaluationText(
                    'notes',
                    widget.currentLang,
                  ),
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.05),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: scoreController,
                decoration: InputDecoration(
                  labelText: Translations.getEvaluationText(
                    'scoreMustBe0100',
                    widget.currentLang,
                  ),
                  prefixIcon: const Icon(Icons.star),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.05),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      Translations.getEvaluationText(
                        'cancel',
                        widget.currentLang,
                      ),
                      style: TextStyle(
                        color: widget.textColor.withOpacity(0.7),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final newScore =
                          int.tryParse(scoreController.text) ??
                          (eval['total_score'] ?? 0);
                      if (newScore < 0 || newScore > 100) {
                        _showErrorSnackBar(
                          Translations.getEvaluationText(
                            'scoreMustBe0100',
                            widget.currentLang,
                          ),
                        );
                        return;
                      }
                      final updates = {
                        'notes': notesController.text,
                        'total_score': newScore,
                      };
                      Navigator.pop(context);
                      await widget.onUpdate(id, updates, widget.currentLang);
                      _loadEvaluations();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.seedColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      Translations.getEvaluationText(
                        'save',
                        widget.currentLang,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, int id) {
    final eval = _evaluations.firstWhere(
      (e) => e['id'] == id,
      orElse: () => <String, dynamic>{},
    );
    final isAuthor = widget.currentUserId == eval['evaluator_id']?.toString();
    if (!isAuthor) {
      _showErrorSnackBar(
        Translations.getEvaluationText(
          'youCanOnlyDeleteOwn',
          widget.currentLang,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text(
              Translations.getEvaluationText(
                'confirmDelete',
                widget.currentLang,
              ),
            ),
            const Text(' 🗑️'),
          ],
        ),
        content: Text(
          Translations.getEvaluationText(
            'areYouSureDelete',
            widget.currentLang,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              Translations.getEvaluationText('cancel', widget.currentLang),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await EvaluationsService.deleteEvaluation(id);
              if (result['success'] == true) {
                _loadEvaluations();
                _showSuccessSnackBar(
                  Translations.getEvaluationText(
                    'deletedSuccessfully',
                    widget.currentLang,
                  ),
                );
              } else {
                _showErrorSnackBar(
                  result['error'] ??
                      Translations.getEvaluationText(
                        'deleteFailed',
                        widget.currentLang,
                      ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              Translations.getEvaluationText('delete', widget.currentLang),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

/* ---------- Cards & Details ---------- */

class _GlassHeader extends StatelessWidget {
  final String title;
  final Color seedColor;
  final Color textColor;
  const _GlassHeader({
    required this.title,
    required this.seedColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: seedColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: seedColor.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              const Text('📊 ', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Color seedColor;
  const _InfoCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.seedColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Icon(icon, color: color, size: 56),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(subtitle, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EvaluationCard extends StatelessWidget {
  final Map<String, dynamic> eval;
  final Color seedColor;
  final Color textColor;
  final Color ratingColor;
  final bool isSupervisor;
  final bool isAuthor;
  final String lang;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EvaluationCard({
    required this.eval,
    required this.seedColor,
    required this.textColor,
    required this.ratingColor,
    required this.isSupervisor,
    required this.isAuthor,
    required this.lang,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final date = (eval['match_date']?.toString() ?? '').split('T').first;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: seedColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),

            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // icon bubble
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: seedColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '⭐',
                      style: TextStyle(fontSize: 24, color: seedColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${Translations.getEvaluationText('score', lang)}: ${eval['total_score'] ?? 'N/A'}',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: ratingColor.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${eval['overall_rating'] ?? 'N/A'}',
                                style: TextStyle(
                                  color: ratingColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '⚽ ${Translations.getEvaluationText('matchField', lang)}: ${eval['match'] ?? 'N/A'}',
                          style: TextStyle(
                            color: textColor.withOpacity(0.85),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '📅 $date',
                          style: TextStyle(
                            color: textColor.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        if (isSupervisor)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isAuthor)
                                  IconButton(
                                    tooltip: 'Edit',
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: onEdit,
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Chip(
                                      label: Text(
                                        Translations.getEvaluationText(
                                          'viewOnly',
                                          lang,
                                        ),
                                      ),
                                      backgroundColor: Colors.grey.withOpacity(
                                        0.12,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                if (isAuthor)
                                  IconButton(
                                    tooltip: 'Delete',
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: onDelete,
                                  ),
                              ],
                            ),
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
  }
}

/* ---------------- Details Page ---------------- */

class EvaluationDetailsPage extends StatefulWidget {
  final Map<String, dynamic> evaluation;
  final String currentLang;
  final Color textColor;
  final bool isLargeScreen;
  final ModeProvider modeProvider;
  final Color seedColor;
  final String currentUserId;
  final bool isSupervisor;

  const EvaluationDetailsPage({
    super.key,
    required this.evaluation,
    required this.currentLang,
    required this.textColor,
    required this.isLargeScreen,
    required this.modeProvider,
    required this.seedColor,
    required this.currentUserId,
    required this.isSupervisor,
  });

  @override
  State<EvaluationDetailsPage> createState() => _EvaluationDetailsPageState();
}

class _EvaluationDetailsPageState extends State<EvaluationDetailsPage>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _details;
  String _errorMsg = '';
  bool _isLoading = true;

  // simple background animation
  late final AnimationController _bgAnim;

  @override
  void initState() {
    super.initState();
    _bgAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);
    _loadDetails();
  }

  @override
  void dispose() {
    _bgAnim.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    try {
      final result = await EvaluationsService.getEvaluation(
        widget.evaluation['id'].toString(),
        widget.currentLang,
      );
      if (result['success'] == true) {
        setState(() {
          _details = Map<String, dynamic>.from(result['data'] ?? {});
          _errorMsg = '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _details = widget.evaluation;
          _errorMsg =
              result['error'] ??
              Translations.getEvaluationText(
                'failedToLoadFullDetails',
                widget.currentLang,
              );
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _details = widget.evaluation;
        _errorMsg =
            Translations.getEvaluationText(
              'couldntLoadFullDetails',
              widget.currentLang,
            ) +
            ' (Error: $e)';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.modeProvider.currentMode;
    final lang = widget.currentLang;
    final textDirection = lang == 'ar' ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            Translations.getEvaluationText('evaluationDetails', lang),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Stack(
          children: [
            // gradient + animated emojis
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.getBodyGradient(mode),
              ),
            ),
            _FloatingEmojiField(controller: _bgAnim),
            // content
            SafeArea(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 12),
                          Text(
                            Translations.getEvaluationText(
                              'loadingDetails',
                              lang,
                            ),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GlassHeader(
                            title: Translations.getEvaluationText(
                              'evaluationDetails',
                              lang,
                            ),
                            subtitle: Translations.getEvaluationText(
                              'viewDetails',
                              lang,
                            ),
                            seedColor: widget.seedColor,
                          ),
                          const SizedBox(height: 16),
                          if (_errorMsg.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 10,
                                  sigmaY: 10,
                                ),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.orange.withOpacity(0.25),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.orange,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMsg,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          _GlassBlock(
                            seedColor: widget.seedColor,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _detail(
                                  '⚽',
                                  Translations.getEvaluationText('match', lang),
                                  _details?['match'] ?? 'N/A',
                                ),
                                _detail(
                                  '🏟️',
                                  Translations.getEvaluationText(
                                    'stadium',
                                    lang,
                                  ),
                                  _details?['stadium'] ?? 'N/A',
                                ),
                                _detail(
                                  '🏆',
                                  Translations.getEvaluationText(
                                    'competition',
                                    lang,
                                  ),
                                  _details?['competition'] ?? 'N/A',
                                ),
                                _detail(
                                  '📅',
                                  Translations.getEvaluationText(
                                    'dateField',
                                    lang,
                                  ),
                                  (_details?['match_date']
                                          ?.toString()
                                          .split('T')
                                          .first) ??
                                      'N/A',
                                ),
                                _detail(
                                  '⚽',
                                  Translations.getEvaluationText(
                                    'finalScore',
                                    lang,
                                  ),
                                  _details?['final_score'] ?? 'N/A',
                                ),
                                _detail(
                                  '⭐',
                                  Translations.getEvaluationText(
                                    'totalScore',
                                    lang,
                                  ),
                                  '${_details?['total_score'] ?? 'N/A'}',
                                ),
                                _detail(
                                  '📈',
                                  Translations.getEvaluationText(
                                    'overallRating',
                                    lang,
                                  ),
                                  _details?['overall_rating']?.toString() ??
                                      'N/A',
                                ),
                                _detail(
                                  '📝',
                                  Translations.getEvaluationText('notes', lang),
                                  _details?['notes'] ?? 'N/A',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          if (_details?['sections'] == null ||
                              (_details?['sections'] is Map &&
                                  (_details?['sections'] as Map).isEmpty)) ...[
                            _GlassBlock(
                              seedColor: widget.seedColor,
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.visibility_off,
                                    color: Colors.grey,
                                    size: 40,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    Translations.getEvaluationText(
                                      'detailedSectionsNotAvailable',
                                      lang,
                                    ),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: widget.textColor.withOpacity(0.8),
                                    ),
                                  ),
                                  Text(
                                    Translations.getEvaluationText(
                                      'summaryShownAbove',
                                      lang,
                                    ),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: widget.textColor.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            GlassHeader(
                              title: Translations.getEvaluationText(
                                'evaluationSections',
                                lang,
                              ),
                              subtitle: '',
                              seedColor: widget.seedColor,
                            ),
                            const SizedBox(height: 12),
                            ...(_details?['sections'] as Map).entries.map((e) {
                              final sectionData = Map<String, dynamic>.from(
                                e.value,
                              );
                              return _SectionDetailsCard(
                                sectionKey: e.key,
                                sectionData: sectionData,
                                seedColor: widget.seedColor,
                                textColor: widget.textColor,
                                lang: lang,
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 14, color: widget.textColor),
                children: [
                  TextSpan(
                    text: label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ': $value'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionDetailsCard extends StatelessWidget {
  final String sectionKey;
  final Map<String, dynamic> sectionData;
  final Color seedColor;
  final Color textColor;
  final String lang;
  const _SectionDetailsCard({
    required this.sectionKey,
    required this.sectionData,
    required this.seedColor,
    required this.textColor,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final itemsList = (sectionData['items'] as List?) ?? [];
    final weight = sectionData['weight'] as int? ?? 0;
    final subtotal = sectionData['subtotal'] as int? ?? 0;

    double sectionMax = 0;
    for (var item in itemsList) {
      sectionMax += (item['out_of'] as int).toDouble();
    }
    final progress = (sectionMax > 0 ? subtotal / sectionMax : 0.0).clamp(
      0.0,
      1.0,
    );

    final title =
        sectionData['title']?[lang] ??
        sectionKey.replaceAll('_', ' ').toUpperCase();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: seedColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: seedColor.withOpacity(0.25)),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            leading: Text(
              '📊',
              style: TextStyle(fontSize: 22, color: seedColor),
            ),
            title: Text(
              '$title  •  ${Translations.getEvaluationText('weight', lang)} $weight%',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: seedColor.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(seedColor),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${Translations.getEvaluationText('subtotal', lang)}: $subtotal',
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            children: itemsList.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        Translations.getEvaluationText('noItemsToScore', lang),
                      ),
                    ),
                  ]
                : itemsList.map((item) {
                    final label = item['label']?.toString() ?? '';
                    final score = item['score']?.toString() ?? '0';
                    final outOf = item['out_of']?.toString() ?? '10';
                    final itemProgress =
                        ((int.tryParse(outOf) ?? 10) > 0
                                ? (int.tryParse(score) ?? 0) /
                                      (int.tryParse(outOf) ?? 10)
                                : 0.0)
                            .clamp(0.0, 1.0);
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  label,
                                  style: TextStyle(color: textColor),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: seedColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$score/$outOf',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: itemProgress,
                            backgroundColor: seedColor.withOpacity(0.12),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              seedColor,
                            ),
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
          ),
        ),
      ),
    );
  }
}

/* ---- Pretty glass container for details ---- */
class _GlassBlock extends StatelessWidget {
  final Widget child;
  final Color seedColor;
  const _GlassBlock({required this.child, required this.seedColor});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: seedColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: seedColor.withOpacity(0.25)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlassHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color seedColor;
  const GlassHeader({
    required this.title,
    required this.subtitle,
    required this.seedColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: seedColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: seedColor.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('📋', style: TextStyle(fontSize: 28, color: seedColor)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white.withOpacity(0.75)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingEmojiField extends StatelessWidget {
  final AnimationController controller;
  const _FloatingEmojiField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final emojis = ['⚽', '🏟️', '🟨', '🟥', '🎯', '🧑‍⚖️', '🟢', '🔵'];
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final t = controller.value;
          return Opacity(
            opacity: 0.15,
            child: Stack(
              children: List.generate(emojis.length, (i) {
                final dx = (i * 0.12 + t * 0.4) % 1.0;
                final dy = ((i * 0.21 + (1 - t) * 0.5) % 1.0);
                return Align(
                  alignment: Alignment(-1 + 2 * dx, -1 + 2 * dy),
                  child: Transform.scale(
                    scale: 0.8 + (i % 3) * 0.1,
                    child: Text(
                      emojis[i],
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}
