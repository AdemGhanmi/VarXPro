// lib/views/pages/home/create_evaluation_page.dart
import 'dart:ui';
import 'package:VarXPro/views/pages/home/model/home_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/views/pages/home/service/evaluations_service.dart';
import 'package:VarXPro/views/connexion/providers/auth_provider.dart';
import 'package:VarXPro/lang/translation.dart';

class CreateEvaluationPage extends StatefulWidget {
  final String externalRefId;
  final String refereeName;

  const CreateEvaluationPage({
    super.key,
    required this.externalRefId,
    required this.refereeName,
  });

  @override
  State<CreateEvaluationPage> createState() => _CreateEvaluationPageState();
}

class _CreateEvaluationPageState extends State<CreateEvaluationPage> with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {
    'match': TextEditingController(),
    'stadium': TextEditingController(),
    'competition': TextEditingController(),
    'matchDate': TextEditingController(),
    'finalScore': TextEditingController(),
    'notes': TextEditingController(),
  };

  Map<String, dynamic> _meta = {};
  bool _metaLoaded = false;
  Map<String, Map<String, dynamic>> _sections = {};
  bool _isLoading = false;
  bool _canCreate = false;
  String? selectedType;
  bool _refereeLoaded = false;

  // simple background animation
  late final AnimationController _bgAnim;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _controllers['matchDate']!.text =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    _bgAnim = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat(reverse: true);

    _loadRefereeAndSetType();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final role = authProvider.user?.role ?? 'visitor';
    if (role == 'visitor') {
      _canCreate = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(Translations.getEvaluationText('onlyAuthenticatedUsers', _getLang()))),
          );
        }
      });
    } else {
      _canCreate = true;
    }
  }

  Future<void> _loadRefereeAndSetType() async {
    final result = await EvaluationsService.fetchRefereeById(widget.externalRefId);
    if (result['success'] && mounted) {
      final refereeJson = result['data'];
      final referee = Referee.fromJson(refereeJson);
      String autoType = 'referee';  // Default
      if (referee.roles.contains('assistant')) {
        autoType = 'assistant';
      }
      // Add more logic for other roles if needed (e.g., 'var' -> 'video_assistant')
      setState(() {
        selectedType = autoType;
        _refereeLoaded = true;
      });
      await _loadMeta();  // Now load meta after setting type
    } else {
      if (mounted) {
        setState(() {
          selectedType = 'referee';  // Fallback
          _refereeLoaded = true;
        });
        await _loadMeta();
      }
    }
  }

  Future<void> _loadMeta() async {
    final currentLang = _getLang();
    final result = await EvaluationsService.fetchMeta(currentLang);
    if (result['success'] == true) {
      if (!mounted) return;
      setState(() {
        _meta = result['data'];
        _metaLoaded = true;
        _updateSections(selectedType!);
      });
    } else {
      if (!mounted) return;
      setState(() {
        _meta = {
          'types': ['referee'],
          'overall_ratings': ['excellent', 'very_good', 'good', 'acceptable', 'weak'],
          'sections': {
            'referee': {
              'performance': {
                'weight': 60,
                'title': {'en': 'Technical Performance', 'fr': 'Performance technique', 'ar': 'الأداء الفني'},
                'items': [
                  {'key': 'laws_application', 'label': {'en': 'Application of the Laws','fr':'Application des lois','ar':'تطبيق القوانين'}, 'out_of': 10},
                  {'key': 'positioning', 'label': {'en': 'Positioning','fr':'Placement','ar':'التمركز'}, 'out_of': 10},
                  {'key': 'fitness', 'label': {'en': 'Fitness','fr':'Condition physique','ar':'اللياقة'}, 'out_of': 10},
                ],
              },
              'management': {
                'weight': 40,
                'title': {'en': 'Game Management', 'fr': 'Gestion du match', 'ar': 'إدارة المباراة'},
                'items': [
                  {'key': 'communication', 'label': {'en':'Communication','fr':'Communication','ar':'التواصل'}, 'out_of': 10},
                  {'key': 'player_control', 'label': {'en':'Player Control','fr':'Contrôle des joueurs','ar':'السيطرة على اللاعبين'}, 'out_of': 10},
                ],
              },
            },
          },
        };
        _metaLoaded = true;
        _updateSections(selectedType!);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? Translations.getEvaluationText('usingFallbackForm', _getLang()))),
      );
    }
  }

  void _updateSections(String type) {
    _sections.clear();
    final sectionsRoot = _meta['sections']?[type];
    if (sectionsRoot is Map) {
      for (final entry in sectionsRoot.entries) {
        final key = entry.key.toString();
        final section = Map<String, dynamic>.from(entry.value as Map);
        final itemsMap = <String, Map<String, dynamic>>{};
        final itemsList = (section['items'] as List?) ?? [];
        for (final item in itemsList) {
          final itemKey = item['key'].toString();
          itemsMap[itemKey] = {'score': 0, 'out_of': item['out_of'] ?? 10, 'label': item['label']};
        }
        section['items_map'] = itemsMap;
        _sections[key] = section;
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    _bgAnim.dispose();
    super.dispose();
  }

  int _calculateTotalScore() {
    int total = 0;
    for (var section in _sections.values) {
      int subtotal = 0;
      double sectionMax = 0;
      final itemsMap = (section['items_map'] as Map<String, dynamic>?) ?? {};
      for (var item in itemsMap.values) {
        subtotal += (item['score'] as int);
        sectionMax += (item['out_of'] as int).toDouble();
      }
      final weight = section['weight'] as int? ?? 0;
      if (sectionMax > 0) {
        final sectionScore = ((subtotal / sectionMax) * weight).round();
        total += sectionScore;
      }
    }
    return total.clamp(0, 100);
  }

  String _getOverallRating(int totalScore) {
    final ratings = (_meta['overall_ratings'] as List?) ?? ['excellent', 'very_good', 'good', 'acceptable', 'weak'];
    if (totalScore >= 90) return ratings[0];
    if (totalScore >= 80) return ratings.length > 1 ? ratings[1] : ratings[0];
    if (totalScore >= 70) return ratings.length > 2 ? ratings[2] : ratings[1];
    if (totalScore >= 50) return ratings.length > 3 ? ratings[3] : ratings.last;
    return ratings.length > 4 ? ratings[4] : ratings.last;
  }

  Future<void> _createEvaluation() async {
    if (!_formKey.currentState!.validate() || selectedType == null) return;

    // Check if selectedType is allowed (from meta types)
    final allowedTypes = (_meta['types'] as List?)?.map((e) => e.toString()).toList() ?? ['referee'];
    if (!allowedTypes.contains(selectedType)) {
      _showSnackBar('Invalid type for this referee. Allowed: ${allowedTypes.join(', ')}', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    final totalScore = _calculateTotalScore();
    if (totalScore == 0) {
      _showSnackBar(Translations.getEvaluationText('pleaseScoreAtLeastOneItem', _getLang()), Colors.orange);
      setState(() => _isLoading = false);
      return;
    }

    // Build sections payload
    final payloadSections = <String, dynamic>{};
    _sections.forEach((sectionName, sectionData) {
      int subtotal = 0;
      final items = <Map<String, dynamic>>[];
      final itemsMap = (sectionData['items_map'] as Map<String, dynamic>?) ?? {};
      for (final e in itemsMap.entries) {
        final item = e.value;
        final score = item['score'] as int;
        subtotal += score;
        items.add({
          'label': (item['label'] as Map?)?[_getLang()] ?? (item['label'] as Map?)?['en'] ?? e.key,
          'score': score,
          'out_of': item['out_of'],
        });
      }
      payloadSections[sectionName] = {
        'weight': sectionData['weight'],
        'subtotal': subtotal,
        'items': items.isEmpty ? null : items,
      };
    });

    final data = {
      'external_ref_id': widget.externalRefId,
      'type': selectedType,
      'match': _controllers['match']!.text.trim(),
      'stadium': _controllers['stadium']!.text.trim(),
      'competition': _controllers['competition']!.text.trim(),
      'match_date': _controllers['matchDate']!.text.trim(),
      'final_score': _controllers['finalScore']!.text.trim(),
      'sections': payloadSections,
      'total_score': totalScore,
      'overall_rating': _getOverallRating(totalScore),
      'notes': _controllers['notes']!.text.trim(),
      'signed_name': Provider.of<AuthProvider>(context, listen: false).user?.name ?? 'User',
      'signed_at': DateTime.now().toIso8601String().split('T')[0],
    };

    final result = await EvaluationsService.createEvaluation(data);
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _showSnackBar(Translations.getEvaluationText('evaluationCreated', _getLang()), Colors.green);
      if (mounted) Navigator.pop(context, true);
    } else {
      _showSnackBar(result['error'] ?? Translations.getEvaluationText('failedToCreate', _getLang()), Colors.red);
    }
  }

  String _getLang() => Provider.of<LanguageProvider>(context, listen: false).currentLanguage ?? 'en';

  String _getLocalizedLabel(List items, String key, String lang) {
    for (var item in items) {
      if (item['key'] == key) {
        final m = (item['label'] as Map?) ?? {};
        return m[lang] ?? m['en'] ?? key;
      }
    }
    return key;
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final mode = Provider.of<ModeProvider>(context).currentMode;
    final lang = Provider.of<LanguageProvider>(context).currentLanguage ?? 'en';
    final textColor = AppColors.getTextColor(mode);
    final seedColor = AppColors.seedColors[mode] ?? Colors.blue;
    final isLarge = MediaQuery.of(context).size.width > 720;
    final textDirection = lang == 'ar' ? TextDirection.rtl : TextDirection.ltr;

    if (!_refereeLoaded || !_metaLoaded || !_canCreate) {
      return Directionality(
        textDirection: textDirection,
        child: Scaffold(
          appBar: AppBar(title: Text(Translations.getEvaluationText('loadingMeta', lang))),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final totalScore = _calculateTotalScore();
    final rating = _getOverallRating(totalScore);

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
          title: Row(
            children: [
              Text(Translations.getEvaluationText('createEvaluationFor', lang)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(widget.refereeName, overflow: TextOverflow.ellipsis, maxLines: 1),
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            // gradient + animated emojis
            Container(decoration: BoxDecoration(gradient: AppColors.getBodyGradient(mode))),
            _FloatingEmojiField(controller: _bgAnim),
            // content
            SafeArea(
              child: Form(
                key: _formKey,
                child: LayoutBuilder(
                  builder: (context, c) {
                    return SingleChildScrollView(
                      padding: EdgeInsets.all(isLarge ? 24 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _GlassHeader(
                            title: Translations.getEvaluationText('newEvaluation', lang),
                            subtitle: Translations.getEvaluationText('fillTheForm', lang),
                            seedColor: seedColor,
                          ),
                          const SizedBox(height: 16),
                          _CustomTextField(
                            controller: _controllers['match']!,
                            label: Translations.getEvaluationText('match', lang),
                            validator: (v) => (v?.trim().isEmpty ?? true)
                                ? Translations.getEvaluationText('required', lang)
                                : null,
                            prefixEmoji: '⚽',
                            seedColor: seedColor,
                            mode: mode,
                            textDirection: textDirection,
                          ),
                          const SizedBox(height: 12),
                          _CustomTextField(
                            controller: _controllers['stadium']!,
                            label: Translations.getEvaluationText('stadium', lang),
                            prefixEmoji: '🏟️',
                            seedColor: seedColor,
                            mode: mode,
                            textDirection: textDirection,
                          ),
                          const SizedBox(height: 12),
                          _CustomTextField(
                            controller: _controllers['competition']!,
                            label: Translations.getEvaluationText('competition', lang),
                            prefixEmoji: '🏆',
                            seedColor: seedColor,
                            mode: mode,
                            textDirection: textDirection,
                          ),
                          const SizedBox(height: 12),

                          // Chip selector for types
                          _TypeSelector(
                            types: (_meta['types'] as List? ?? []).map((e) => e.toString()).toList(),
                            current: selectedType,
                            onChanged: (v) {
                              setState(() {
                                selectedType = v;
                                _updateSections(v);
                              });
                            },
                            label: Translations.getEvaluationText('evaluationType', lang),
                            seedColor: seedColor,
                            mode: mode,
                          ),
                          const SizedBox(height: 12),

                          // Date (with picker)
                          _CustomTextField(
                            controller: _controllers['matchDate']!,
                            label: Translations.getEvaluationText('date', lang),
                            prefixEmoji: '📅',
                            seedColor: seedColor,
                            mode: mode,
                            keyboardType: TextInputType.datetime,
                            validator: (v) => RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v ?? '')
                                ? null
                                : Translations.getEvaluationText('invalidDateFormat', lang),
                            textDirection: textDirection,
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_month),
                              onPressed: () async {
                                final now = DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: now,
                                  firstDate: DateTime(now.year - 2),
                                  lastDate: DateTime(now.year + 2),
                                );
                                if (picked != null) {
                                  _controllers['matchDate']!.text =
                                      '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                  setState(() {});
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 12),

                          _CustomTextField(
                            controller: _controllers['finalScore']!,
                            label: Translations.getEvaluationText('finalScore', lang),
                            prefixEmoji: '⚽',
                            seedColor: seedColor,
                            mode: mode,
                            textDirection: textDirection,
                          ),

                          const SizedBox(height: 20),
                          Text(
                            Translations.getEvaluationText('scoreSections', lang),
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                          ),
                          const SizedBox(height: 8),

                          ..._sections.entries.map(
                            (entry) => _SectionCard(
                              sectionKey: entry.key,
                              sectionData: entry.value,
                              seedColor: seedColor,
                              textColor: textColor,
                              lang: lang,
                              onChanged: () => setState(() {}),
                            ),
                          ),

                          const SizedBox(height: 12),
                          _TotalSummary(
                            totalScore: totalScore,
                            rating: rating,
                            color: _ratingColor(rating),
                            textColor: textColor,
                            lang: lang,
                          ),

                          const SizedBox(height: 12),
                          _CustomTextField(
                            controller: _controllers['notes']!,
                            label: Translations.getEvaluationText('notes', lang),
                            maxLines: 3,
                            prefixEmoji: '📝',
                            seedColor: seedColor,
                            mode: mode,
                            textDirection: textDirection,
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _createEvaluation,
                              icon: _isLoading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.save),
                              label: Text(
                                _isLoading
                                    ? '${Translations.getEvaluationText('creating', lang)} ⏳'
                                    : '${Translations.getEvaluationText('createEvaluation', lang)} 💾',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: seedColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _ratingColor(String rating) {
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
}

/* ==================== Helpers ==================== */

class _GlassHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color seedColor;
  const _GlassHeader({required this.title, required this.subtitle, required this.seedColor});

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
              Text('📝', style: TextStyle(fontSize: 28, color: seedColor)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.75))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final List<String> types;
  final String? current;
  final ValueChanged<String> onChanged;
  final String label;
  final Color seedColor;
  final int mode;
  const _TypeSelector({
    required this.types,
    required this.current,
    required this.onChanged,
    required this.label,
    required this.seedColor,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final surface = AppColors.getSurfaceColor(mode).withOpacity(0.5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: types.map((t) {
              final isSel = t == current;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: isSel,
                  label: Text(t),
                  onSelected: (_) => onChanged(t),
                  selectedColor: seedColor.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSel ? seedColor : AppColors.getTextColor(mode),
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(color: isSel ? seedColor : seedColor.withOpacity(0.25)),
                  backgroundColor: surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String sectionKey;
  final Map<String, dynamic> sectionData;
  final Color seedColor;
  final Color textColor;
  final String lang;
  final VoidCallback onChanged;
  const _SectionCard({
    required this.sectionKey,
    required this.sectionData,
    required this.seedColor,
    required this.textColor,
    required this.lang,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final itemsList = (sectionData['items'] as List?) ?? [];
    final itemsMap = (sectionData['items_map'] as Map<String, dynamic>?) ?? {};
    final weight = sectionData['weight'] as int? ?? 0;

    int subtotal = 0;
    double sectionMax = 0;
    for (var item in itemsMap.values) {
      subtotal += (item['score'] as int);
      sectionMax += (item['out_of'] as int).toDouble();
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: seedColor.withOpacity(0.25))),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Text('📊', style: TextStyle(fontSize: 22, color: seedColor)),
        title: Text(
          '${(sectionData['title']?[lang] ?? sectionKey.replaceAll('_', ' ').toUpperCase())}  •  ${Translations.getEvaluationText('weight', lang)} $weight%',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: LinearProgressIndicator(
            value: (sectionMax > 0 ? subtotal / sectionMax : 0.0).clamp(0.0, 1.0),
            backgroundColor: seedColor.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(seedColor),
            minHeight: 6,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        children: itemsMap.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(Translations.getEvaluationText('noItemsToScore', lang)),
                )
              ]
            : itemsMap.entries.map((e) {
                final key = e.key;
                final item = e.value as Map<String, dynamic>;
                final labelMap = (item['label'] as Map?) ?? {};
                final label = labelMap[lang] ?? labelMap['en'] ?? key;
                final outOf = item['out_of'] as int;
                final score = item['score'] as int;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      Expanded(child: Text(label, style: TextStyle(color: textColor))),
                      SizedBox(
                        width: 140,
                        child: Slider(
                          value: score.toDouble(),
                          min: 0,
                          max: outOf.toDouble(),
                          divisions: outOf,
                          onChanged: (v) {
                            item['score'] = v.round();
                            onChanged();
                          },
                          activeColor: seedColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: seedColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$score/$outOf', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              }).toList(),
      ),
    );
  }
}

class _TotalSummary extends StatelessWidget {
  final int totalScore;
  final String rating;
  final Color color;
  final Color textColor;
  final String lang;
  const _TotalSummary({
    required this.totalScore,
    required this.rating,
    required this.color,
    required this.textColor,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration:
          BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
        children: [
          Text('⭐', style: TextStyle(fontSize: 22, color: color)),
          const SizedBox(width: 12),
          Expanded(
            child: Text('${Translations.getEvaluationText('totalScore', lang)}: $totalScore / 100',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Text('${Translations.getEvaluationText('rating', lang)}: $rating',
                style: TextStyle(fontWeight: FontWeight.w700, color: color)),
          ),
        ],
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
                    child: Text(emojis[i], style: const TextStyle(fontSize: 28)),
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

class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final String? prefixEmoji;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final int maxLines;
  final TextInputType? keyboardType;
  final Color seedColor;
  final int mode;
  final TextDirection? textDirection;

  const _CustomTextField({
    required this.controller,
    required this.label,
    this.validator,
    this.prefixEmoji,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.maxLines = 1,
    this.keyboardType,
    required this.seedColor,
    required this.mode,
    this.textDirection,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: textDirection ?? TextDirection.ltr,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        textDirection: textDirection,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefixEmoji != null
              ? Padding(padding: const EdgeInsets.all(12), child: Text(prefixEmoji!, style: const TextStyle(fontSize: 20)))
              : (prefixIcon != null
                  ? Icon(prefixIcon, color: AppColors.getPrimaryColor(seedColor, mode).withOpacity(0.7))
                  : null),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: AppColors.getSurfaceColor(mode).withOpacity(0.55),
          labelStyle: TextStyle(color: AppColors.getTextColor(mode).withOpacity(0.75)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.getPrimaryColor(seedColor, mode), width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.getPrimaryColor(seedColor, mode).withOpacity(0.2)),
          ),
        ),
      ),
    );
  }
}