// lib/views/pages/home/view/create_evaluation_page.dart (Updated with translations)
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
  final String refereeName; // For display

  const CreateEvaluationPage({
    super.key,
    required this.externalRefId,
    required this.refereeName,
  });

  @override
  State<CreateEvaluationPage> createState() => _CreateEvaluationPageState();
}

class _CreateEvaluationPageState extends State<CreateEvaluationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {
    'match': TextEditingController(),
    'stadium': TextEditingController(),
    'competition': TextEditingController(),
    'matchDate': TextEditingController(), // Will set dynamically
    'finalScore': TextEditingController(),
    'notes': TextEditingController(),
  };

  Map<String, dynamic> _meta = {}; // For dynamic sections from meta
  bool _metaLoaded = false;
  Map<String, Map<String, dynamic>> _sections = {}; // Dynamic sections
  bool _isLoading = false;
  bool _canCreate = false;

  @override
  void initState() {
    super.initState();
    // Set current date dynamically
    final now = DateTime.now();
    _controllers['matchDate']!.text = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _loadMeta();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check role after dependencies are ready
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

  Future<void> _loadMeta() async {
    final result = await EvaluationsService.fetchMeta();
    if (result['success']) {
      if (mounted) {
        setState(() {
          _meta = result['data'];
          _metaLoaded = true;
          // Initialize sections from meta for type 'referee'
          _sections = Map<String, Map<String, dynamic>>.from(_meta['sections']['referee'] ?? {});
          // Add score tracking for items
          _sections.forEach((key, section) {
            if (section['items'] != null) {
              final items = <String, Map<String, dynamic>>{};
              for (var item in (section['items'] as List)) {
                final itemKey = item['key'];
                items[itemKey] = {'score': 0, 'out_of': 10}; // Assume out_of 10 unless specified
              }
              section['items_map'] = items; // Store as map for easy access
            }
          });
        });
      }
    } else {
      // Fallback to hardcoded if meta fails
      if (mounted) {
        setState(() {
          _metaLoaded = true;
          _sections = {
            'technical_performance': {
              'weight': 40,
              'title': {'en': 'Technical Performance'},
              'items': [
                {'key': 'laws_application', 'label': {'en': 'Application of the Laws'}},
                // Add more hardcoded items as needed
              ],
              'items_map': {
                'laws_application': {'score': 0, 'out_of': 10},
                // ...
              },
            },
            // Add other fallback sections...
          };
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error'] ?? Translations.getEvaluationText('usingFallbackForm', _getLang()))));
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  int _calculateTotalScore() {
    int total = 0;
    for (var section in _sections.values) {
      int subtotal = 0;
      final itemsMap = section['items_map'] as Map<String, dynamic>? ?? {};
      for (var item in itemsMap.values) {
        subtotal += (item as Map)['score'] as int;
      }
      total += (subtotal * (section['weight'] as int)) ~/ 100; // Weighted
    }
    return total.clamp(0, 100);
  }

  String _getOverallRating(int totalScore) {
    final ratings = _meta['overall_ratings'] ?? ['excellent', 'very_good', 'good', 'acceptable', 'weak'];
    if (totalScore >= 90) return ratings[0];
    if (totalScore >= 80) return ratings[1];
    if (totalScore >= 70) return ratings[2];
    if (totalScore >= 50) return ratings[3];
    return ratings[4];
  }

  Future<void> _createEvaluation() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final totalScore = _calculateTotalScore();
    if (totalScore == 0) {
      _showSnackBar(Translations.getEvaluationText('pleaseScoreAtLeastOneItem', _getLang()), Colors.orange);
      setState(() => _isLoading = false);
      return;
    }

    // Build sections with subtotals
    final sections = <String, dynamic>{};
    for (var entry in _sections.entries) {
      final sectionName = entry.key;
      final sectionData = entry.value;
      int subtotal = 0;
      final items = <Map<String, dynamic>>[];
      final itemsMap = sectionData['items_map'] as Map<String, dynamic>? ?? {};
      for (var itemEntry in itemsMap.entries) {
        final item = itemEntry.value as Map;
        final score = item['score'] as int;
        subtotal += score;
        final labelKey = itemEntry.key;
        final label = _getLocalizedLabel(sectionData['items'], labelKey, _getLang());
        items.add({
          'label': label,
          'score': score,
          'out_of': item['out_of'],
        });
      }
      sections[sectionName] = {
        'weight': sectionData['weight'],
        'subtotal': subtotal,
        'items': items.isNotEmpty ? items : null,
      };
    }

    final data = {
      'external_ref_id': widget.externalRefId,
      'type': 'referee',
      'match': _controllers['match']!.text,
      'stadium': _controllers['stadium']!.text,
      'competition': _controllers['competition']!.text,
      'match_date': _controllers['matchDate']!.text,
      'final_score': _controllers['finalScore']!.text,
      'sections': sections,
      'total_score': totalScore,
      'overall_rating': _getOverallRating(totalScore),
      'notes': _controllers['notes']!.text,
      'signed_name': Provider.of<AuthProvider>(context, listen: false).user?.name ?? 'User',
      'signed_at': DateTime.now().toIso8601String().split('T')[0],
    };

    final result = await EvaluationsService.createEvaluation(data);
    setState(() => _isLoading = false);

    if (result['success']) {
      _showSnackBar(Translations.getEvaluationText('evaluationCreated', _getLang()), Colors.green);
      if (mounted) Navigator.pop(context, true);
    } else {
      _showSnackBar(result['error'] ?? Translations.getEvaluationText('failedToCreate', _getLang()), Colors.red);
    }
  }

  String _getLang() {
    return Provider.of<LanguageProvider>(context, listen: false).currentLanguage ?? 'en';
  }

  String _getLocalizedLabel(List items, String key, String lang) {
    for (var item in items) {
      if (item['key'] == key) {
        return item['label'][lang] ?? item['label']['en'] ?? key;
      }
    }
    return key;
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modeProvider = Provider.of<ModeProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final currentLang = langProvider.currentLanguage ?? 'en';
    final seedColor = AppColors.seedColors[modeProvider.currentMode] ?? AppColors.seedColors[1]!;
    final textColor = AppColors.getTextColor(modeProvider.currentMode);
    final isLargeScreen = MediaQuery.of(context).size.width > 600;
    final textDirection = currentLang == 'ar' ? TextDirection.rtl : TextDirection.ltr;

    if (!_metaLoaded || !_canCreate) {
      return Directionality(
        textDirection: textDirection,
        child: Scaffold(
          appBar: AppBar(title: Text(Translations.getEvaluationText('loadingMeta', currentLang))),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final totalScore = _calculateTotalScore();

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Text(Translations.getEvaluationText('createEvaluationFor', currentLang)),
              Expanded(
                child: Text(
                  widget.refereeName,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.getSurfaceColor(modeProvider.currentMode),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          padding: EdgeInsets.all(isLargeScreen ? 24 : 16),
          decoration: BoxDecoration(
            gradient: AppColors.getBodyGradient(modeProvider.currentMode),
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('📝 ', style: TextStyle(fontSize: 28)),
                      Text(
                        Translations.getEvaluationText('newEvaluation', currentLang),
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _CustomTextField(
                    controller: _controllers['match']!,
                    label: Translations.getEvaluationText('match', currentLang),
                    validator: (v) => (v?.isEmpty ?? true) ? Translations.getEvaluationText('required', currentLang) : null,
                    prefixEmoji: '🏟️',
                    seedColor: seedColor,
                    mode: modeProvider.currentMode,
                    textDirection: textDirection,
                  ),
                  const SizedBox(height: 12),
                  _CustomTextField(
                    controller: _controllers['stadium']!,
                    label: Translations.getEvaluationText('stadium', currentLang),
                    prefixEmoji: '🏟️',
                    seedColor: seedColor,
                    mode: modeProvider.currentMode,
                    textDirection: textDirection,
                  ),
                  const SizedBox(height: 12),
                  _CustomTextField(
                    controller: _controllers['competition']!,
                    label: Translations.getEvaluationText('competition', currentLang),
                    prefixEmoji: '🏆',
                    seedColor: seedColor,
                    mode: modeProvider.currentMode,
                    textDirection: textDirection,
                  ),
                  const SizedBox(height: 12),
                  _CustomTextField(
                    controller: _controllers['matchDate']!,
                    label: Translations.getEvaluationText('date', currentLang),
                    prefixEmoji: '📅',
                    seedColor: seedColor,
                    mode: modeProvider.currentMode,
                    keyboardType: TextInputType.datetime,
                    validator: (v) => RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v ?? '') ? null : Translations.getEvaluationText('invalidDateFormat', currentLang),
                    textDirection: textDirection,
                  ),
                  const SizedBox(height: 12),
                  _CustomTextField(
                    controller: _controllers['finalScore']!,
                    label: Translations.getEvaluationText('finalScore', currentLang),
                    prefixEmoji: '⚽',
                    seedColor: seedColor,
                    mode: modeProvider.currentMode,
                    textDirection: textDirection,
                  ),
                  const SizedBox(height: 20),
                  // Sections Scoring
                  Text(Translations.getEvaluationText('scoreSections', currentLang), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ..._sections.entries.map((entry) => _buildSectionWidget(entry.key, entry.value, seedColor, textColor, modeProvider.currentMode, currentLang)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getRatingColor(_getOverallRating(totalScore)).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${Translations.getEvaluationText('totalScore', currentLang)}: $totalScore / 100 ⭐', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                        Text('${Translations.getEvaluationText('rating', currentLang)}: ${_getOverallRating(totalScore)}', style: TextStyle(fontSize: 16, color: _getRatingColor(_getOverallRating(totalScore)))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CustomTextField(
                    controller: _controllers['notes']!,
                    label: Translations.getEvaluationText('notes', currentLang),
                    maxLines: 3,
                    prefixEmoji: '📝',
                    seedColor: seedColor,
                    mode: modeProvider.currentMode,
                    textDirection: textDirection,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _createEvaluation,
                      icon: _isLoading
                          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: const AlwaysStoppedAnimation<Color>(Colors.white)))
                          : const Icon(Icons.save),
                      label: Text(_isLoading ? '${Translations.getEvaluationText('creating', currentLang)} ⏳' : '${Translations.getEvaluationText('createEvaluation', currentLang)} 💾'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: seedColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
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

  Widget _buildSectionWidget(String sectionName, Map<String, dynamic> sectionData, Color seedColor, Color textColor, int mode, String lang) {
    final itemsList = sectionData['items'] as List? ?? [];
    final itemsMap = sectionData['items_map'] as Map<String, dynamic>? ?? {};
    final weight = sectionData['weight'] as int;
    int subtotal = 0;
    for (var item in itemsMap.values) {
      subtotal += (item as Map)['score'] as int;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Text('📊 ', style: TextStyle(fontSize: 20, color: seedColor)),
        title: Text('${sectionData['title'][lang] ?? sectionName.replaceAll('_', ' ').toUpperCase()} (${Translations.getEvaluationText('weight', lang)}: $weight%)'),
        subtitle: Text('${Translations.getEvaluationText('subtotal', lang)}: $subtotal'),
        children: itemsMap.isEmpty
            ? [Padding(padding: const EdgeInsets.all(16), child: Text(Translations.getEvaluationText('noItemsToScore', lang)))]
            : itemsMap.entries.map((itemEntry) {
                final labelKey = itemEntry.key;
                final label = _getLocalizedLabel(itemsList, labelKey, lang);
                final item = itemEntry.value as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(child: Text(label, style: TextStyle(color: textColor))),
                      SizedBox(
                        width: 120,
                        child: Slider(
                          value: (item['score'] as int).toDouble(),
                          min: 0,
                          max: (item['out_of'] as int).toDouble(),
                          divisions: item['out_of'] as int,
                          onChanged: (value) {
                            setState(() {
                              item['score'] = value.round();
                            });
                          },
                          activeColor: seedColor,
                        ),
                      ),
                      Text('${item['score']}/${item['out_of']}', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
      ),
    );
  }

  Color _getRatingColor(String rating) {
    switch (rating) {
      case 'excellent': return Colors.green;
      case 'very_good': return Colors.blue;
      case 'good': return Colors.orange;
      case 'acceptable': return Colors.yellow;
      default: return Colors.red;
    }
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
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(prefixEmoji!, style: const TextStyle(fontSize: 20)),
                )
              : prefixIcon != null
                  ? Icon(
                      prefixIcon,
                      color: AppColors.getPrimaryColor(seedColor, mode).withOpacity(0.7),
                    )
                  : null,
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: AppColors.getSurfaceColor(mode).withOpacity(0.5),
          labelStyle: TextStyle(color: AppColors.getTextColor(mode).withOpacity(0.7)),
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
