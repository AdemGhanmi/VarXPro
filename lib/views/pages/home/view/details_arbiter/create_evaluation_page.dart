// lib/views/pages/home/view/create_evaluation_page.dart (fixed: full form with sections & items scoring, emojis, nice design, validation)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/provider/langageprovider.dart';
import 'package:VarXPro/views/pages/home/service/evaluations_service.dart';
import 'package:VarXPro/views/connexion/providers/auth_provider.dart';

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
    'matchDate': TextEditingController(text: '2025-10-06'), // Current date
    'finalScore': TextEditingController(),
    'notes': TextEditingController(),
  };

  // Full sections with items
  final Map<String, Map<String, dynamic>> _sections = {
    'technical_performance': {
      'weight': 40,
      'items': {
        'تطبيق قوانين اللعبة': {'score': 0, 'out_of': 10},
        'القرارات الحاسمة': {'score': 0, 'out_of': 10},
        'السيطرة على المباراة': {'score': 0, 'out_of': 10},
        'التعاون مع المساعدين/VAR': {'score': 0, 'out_of': 10},
      },
    },
    'fitness_positioning': {'weight': 15, 'items': {}},
    'management_control': {'weight': 25, 'items': {}},
    'time_management': {'weight': 10, 'items': {}},
    'overall_tech': {'weight': 10, 'items': {}},
  };

  bool _isLoading = false;

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
      for (var item in (section['items'] as Map? ?? {}).values) {
        subtotal += (item as Map)['score'] as int;
      }
      total += subtotal * (section['weight'] as int) ~/ 100; // Weighted
    }
    return total.clamp(0, 100);
  }

  String _getOverallRating(int totalScore) {
    if (totalScore >= 90) return 'excellent';
    if (totalScore >= 80) return 'very_good';
    if (totalScore >= 70) return 'good';
    if (totalScore >= 50) return 'acceptable';
    return 'weak';
  }

  Future<void> _createEvaluation() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final totalScore = _calculateTotalScore();
    if (totalScore == 0) {
      _showSnackBar('Please score at least one item ⭐', Colors.orange);
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
      for (var itemEntry in (sectionData['items'] as Map? ?? {}).entries) {
        final item = itemEntry.value as Map;
        final score = item['score'] as int;
        subtotal += score;
        items.add({
          'label': itemEntry.key,
          'score': score,
          'out_of': item['out_of'],
        });
      }
      sections[sectionName] = {
        'weight': sectionData['weight'],
        'subtotal': subtotal,
        'items': items.isNotEmpty ? items : null, // Only add items if present
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
      'signed_name': Provider.of<AuthProvider>(context, listen: false).user?.name ?? 'Supervisor',
      'signed_at': DateTime.now().toIso8601String().split('T')[0],
    };

    final result = await EvaluationsService.createEvaluation(data);
    setState(() => _isLoading = false);

    if (result['success']) {
      _showSnackBar('Evaluation created successfully! 🎉⭐', Colors.green);
      if (mounted) Navigator.pop(context, true);
    } else {
      _showSnackBar(result['error'] ?? 'Failed to create evaluation ❌', Colors.red);
    }
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

    final totalScore = _calculateTotalScore();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('📝 '),
            Text('Create Evaluation for ${widget.refereeName}'),
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
                      'New Evaluation',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _CustomTextField(
                  controller: _controllers['match']!,
                  label: 'Match 🏟️',
                  validator: (v) => (v?.isEmpty ?? true) ? 'Required ⚽' : null,
                  prefixEmoji: '🏟️',
                  seedColor: seedColor,
                  mode: modeProvider.currentMode,
                ),
                const SizedBox(height: 12),
                _CustomTextField(
                  controller: _controllers['stadium']!,
                  label: 'Stadium 🏟️',
                  prefixEmoji: '🏟️',
                  seedColor: seedColor,
                  mode: modeProvider.currentMode,
                ),
                const SizedBox(height: 12),
                _CustomTextField(
                  controller: _controllers['competition']!,
                  label: 'Competition 🏆',
                  prefixEmoji: '🏆',
                  seedColor: seedColor,
                  mode: modeProvider.currentMode,
                ),
                const SizedBox(height: 12),
                _CustomTextField(
                  controller: _controllers['matchDate']!,
                  label: 'Date (YYYY-MM-DD) 📅',
                  prefixEmoji: '📅',
                  seedColor: seedColor,
                  mode: modeProvider.currentMode,
                  keyboardType: TextInputType.datetime,
                  validator: (v) => RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v ?? '') ? null : 'Invalid date format 📅',
                ),
                const SizedBox(height: 12),
                _CustomTextField(
                  controller: _controllers['finalScore']!,
                  label: 'Final Score ⚽',
                  prefixEmoji: '⚽',
                  seedColor: seedColor,
                  mode: modeProvider.currentMode,
                ),
                const SizedBox(height: 20),
                // Sections Scoring
                const Text('📂 Score Sections:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ..._sections.entries.map((entry) => _buildSectionWidget(entry.key, entry.value, seedColor, textColor, modeProvider.currentMode)),
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
                      Text('Total Score: $totalScore / 100 ⭐', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                      Text('Rating: ${_getOverallRating(totalScore)}', style: TextStyle(fontSize: 16, color: _getRatingColor(_getOverallRating(totalScore)))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _CustomTextField(
                  controller: _controllers['notes']!,
                  label: 'Notes 📝',
                  maxLines: 3,
                  prefixEmoji: '📝',
                  seedColor: seedColor,
                  mode: modeProvider.currentMode,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _createEvaluation,
                    icon: _isLoading
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: const AlwaysStoppedAnimation<Color>(Colors.white)))
                        : const Icon(Icons.save),
                    label: Text(_isLoading ? 'Creating... ⏳' : 'Create Evaluation 💾'),
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
    );
  }

  Widget _buildSectionWidget(String sectionName, Map<String, dynamic> sectionData, Color seedColor, Color textColor, int mode) {
    final items = sectionData['items'] as Map? ?? {};
    final weight = sectionData['weight'] as int;
    int subtotal = 0;
    for (var item in items.values) {
      subtotal += (item as Map)['score'] as int;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Text('📊 ', style: TextStyle(fontSize: 20, color: seedColor)),
        title: Text('${sectionName.replaceAll('_', ' ').toUpperCase()} (Weight: $weight%)'),
        subtitle: Text('Subtotal: $subtotal'),
        children: items.isEmpty
            ? [const Padding(padding: EdgeInsets.all(16), child: Text('No items to score 📝'))]
            : items.entries.map((itemEntry) {
                final label = itemEntry.key;
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
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
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
    );
  }
}