// lib/views/pages/home/view/details_arbiter/evaluations_tab.dart (Updated with translations)
import 'package:flutter/material.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/views/connexion/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:VarXPro/views/pages/home/service/evaluations_service.dart';
import 'package:VarXPro/lang/translation.dart';

class EvaluationsTab extends StatefulWidget {
  final String refereeId;
  final bool isSupervisor;
  final bool isUser;
  final VoidCallback onCreate;
  final Future<void> Function(int, Map<String, dynamic>) onUpdate;
  final String currentLang;
  final Color textColor;
  final bool isLargeScreen;
  final AnimationController animationController;
  final ModeProvider modeProvider;
  final Color seedColor;
  final String currentUserId; // New prop

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
    required this.currentUserId, // Added
  });

  @override
  _EvaluationsTabState createState() => _EvaluationsTabState();
}

class _EvaluationsTabState extends State<EvaluationsTab> with AutomaticKeepAliveClientMixin {
  List<dynamic> _evaluations = [];
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
      final result = await EvaluationsService.listRefereeEvaluations(widget.refereeId);
      if (result['success']) {
        setState(() {
          _evaluations = List<Map<String, dynamic>>.from(result['data'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          _showErrorSnackBar(result['error'] ?? Translations.getEvaluationText('failedToLoadEvaluations', widget.currentLang));
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorSnackBar(Translations.getEvaluationText('errorLoadingEvaluations', widget.currentLang) + ': $e 🔄');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final authProvider = Provider.of<AuthProvider>(context);
    final isGuest = !authProvider.isAuthenticated;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: SingleChildScrollView(
        key: ValueKey('$_isLoading-${_evaluations.length}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('📊 ', style: TextStyle(fontSize: 24)),
                Text(
                  Translations.getEvaluationText('evaluations', widget.currentLang),
                  style: TextStyle(
                    color: widget.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: widget.isLargeScreen ? 20 : 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isGuest)
              Card(
                color: Colors.orange.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Icon(Icons.lock_outline, color: Colors.orange, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        Translations.getEvaluationText('loginToView', widget.currentLang),
                        style: TextStyle(
                          color: widget.textColor.withOpacity(0.8),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Translations.getEvaluationText('signInAsUserOrSupervisor', widget.currentLang),
                        style: TextStyle(
                          color: widget.textColor.withOpacity(0.6),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else if (_isLoading)
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      Translations.getEvaluationText('loadingEvaluations', widget.currentLang),
                      style: TextStyle(color: widget.textColor),
                    ),
                  ],
                ),
              )
            else if (_evaluations.isEmpty)
              Center(
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
                      Translations.getEvaluationText('noEvaluations', widget.currentLang),
                      style: TextStyle(
                        color: widget.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Translations.getEvaluationText('createOneToGetStarted', widget.currentLang),
                      style: TextStyle(
                        color: widget.textColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadEvaluations,
                      icon: const Icon(Icons.refresh),
                      label: Text(Translations.getEvaluationText('reload', widget.currentLang)),
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
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final eval = _evaluations[index];
                  final isAuthor = widget.currentUserId == eval['evaluator_id']?.toString();
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _navigateToDetails(context, eval),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: widget.seedColor.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '⭐',
                                style: TextStyle(
                                  fontSize: 24,
                                  color: widget.seedColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${Translations.getEvaluationText('score', widget.currentLang)}: ${eval['total_score'] ?? 'N/A'}',
                                          style: TextStyle(
                                            color: widget.textColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getRatingColor(eval['overall_rating'] ?? '').withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${eval['overall_rating'] ?? 'N/A'}',
                                          style: TextStyle(
                                            color: _getRatingColor(eval['overall_rating'] ?? ''),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '⚽ ${Translations.getEvaluationText('matchField', widget.currentLang)}: ${eval['match'] ?? 'N/A'}',
                                    style: TextStyle(
                                      color: widget.textColor.withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '📅 ${eval['match_date']?.split('T')[0] ?? 'N/A'}',
                                    style: TextStyle(
                                      color: widget.textColor.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (widget.isSupervisor && isAuthor)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blue),
                                            onPressed: () {
                                              _showEditDialog(context, eval['id'], eval, widget.onUpdate);
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () {
                                              _showDeleteConfirm(context, eval['id']);
                                            },
                                          ),
                                        ],
                                      ),
                                    )
                                  else if (widget.isSupervisor && !isAuthor)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        Translations.getEvaluationText('viewOnly', widget.currentLang),
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
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
                },
              ),
            if (widget.isSupervisor && !isGuest)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.onCreate,
                    icon: const Icon(Icons.add),
                    label: Text(
                      Translations.getEvaluationText('createNewEvaluation', widget.currentLang),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.seedColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetails(BuildContext context, dynamic eval) {
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
      case 'excellent': return Colors.green;
      case 'very_good': return Colors.blue;
      case 'good': return Colors.orange;
      case 'acceptable': return Colors.yellow;
      default: return Colors.red;
    }
  }

  void _showEditDialog(
    BuildContext context,
    int id,
    Map<String, dynamic> eval,
    Future<void> Function(int, Map<String, dynamic>) onUpdate,
  ) {
    print('Debug: Current user ID: ${widget.currentUserId}, Eval author ID: ${eval['evaluator_id']}'); // Added for auth check
    final isAuthor = widget.currentUserId == eval['evaluator_id']?.toString();
    if (!isAuthor) {
      _showErrorSnackBar(Translations.getEvaluationText('youCanOnlyEditOwn', widget.currentLang));
      return;
    }

    final TextEditingController notesController = TextEditingController(text: eval['notes'] ?? '');
    final TextEditingController scoreController = TextEditingController(text: eval['total_score'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [Text(Translations.getEvaluationText('editEvaluation', widget.currentLang)), Text('✏️ ')]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: Translations.getEvaluationText('notes', widget.currentLang),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: scoreController,
              decoration: InputDecoration(
                labelText: Translations.getEvaluationText('scoreMustBe0100', widget.currentLang),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Translations.getEvaluationText('cancel', widget.currentLang)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newScore = int.tryParse(scoreController.text) ?? eval['total_score'];
              if (newScore < 0 || newScore > 100) {
                _showErrorSnackBar(Translations.getEvaluationText('scoreMustBe0100', widget.currentLang));
                return;
              }
              final updates = {
                'notes': notesController.text,
                'total_score': newScore,
              };
              Navigator.pop(context);
              await onUpdate(id, updates);
              _loadEvaluations(); // Reload after update
            },
            child: Text(Translations.getEvaluationText('save', widget.currentLang)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, int id) {
    print('Debug: Deleting eval ID $id'); // Added debug
    final eval = _evaluations.firstWhere((e) => e['id'] == id, orElse: () => <String, dynamic>{}); // FIXED: Explicit type
    final isAuthor = widget.currentUserId == eval['evaluator_id']?.toString();
    print('Debug: Current user ID: ${widget.currentUserId}, Eval author ID: ${eval['evaluator_id']}'); // Added for auth check
    if (!isAuthor) {
      _showErrorSnackBar(Translations.getEvaluationText('youCanOnlyDeleteOwn', widget.currentLang));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [Text(Translations.getEvaluationText('confirmDelete', widget.currentLang)), Text('🗑️ ')]),
        content: Text(Translations.getEvaluationText('areYouSureDelete', widget.currentLang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Translations.getEvaluationText('cancel', widget.currentLang)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await EvaluationsService.deleteEvaluation(id);
              if (result['success']) {
                _loadEvaluations(); // Reload after delete
                _showSuccessSnackBar(Translations.getEvaluationText('deletedSuccessfully', widget.currentLang));
              } else {
                _showErrorSnackBar(result['error'] ?? Translations.getEvaluationText('deleteFailed', widget.currentLang));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(Translations.getEvaluationText('delete', widget.currentLang)),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}



class EvaluationDetailsPage extends StatefulWidget {
  final dynamic evaluation;
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

class _EvaluationDetailsPageState extends State<EvaluationDetailsPage> {
  Map<String, dynamic>? _details;
  String _errorMsg = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    try {
      final result = await EvaluationsService.getEvaluation(widget.evaluation['id'].toString());
      print('Debug: Full result from getEvaluation: $result'); // Added for debugging
      if (result['success']) {
        setState(() {
          _details = result['data'];
          _errorMsg = ''; // Clear error on success
          _isLoading = false;
        });
      } else {
        final err = result['error'] ?? Translations.getEvaluationText('failedToLoadFullDetails', widget.currentLang);
        setState(() {
          _isLoading = false;
          _details = widget.evaluation;
          _errorMsg = err; // Show exact error from API
        });
        print('Debug: Error details: $err'); // Log exact error
      }
    } catch (e) {
      // Silently fallback on any error
      setState(() {
        _isLoading = false;
        _details = widget.evaluation;
        _errorMsg = Translations.getEvaluationText('couldntLoadFullDetails', widget.currentLang) + ' (Error: $e)';
      });
      print('Debug: Catch error: $e'); // Log catch error
    }
  }

  Widget _buildDetailRow(String emoji, String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: TextStyle(fontSize: 16, color: textColor)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 14, color: textColor),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textDirection = widget.currentLang == 'ar' ? TextDirection.rtl : TextDirection.ltr;
    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        appBar: AppBar(
          title: Text(Translations.getEvaluationText('evaluationDetails', widget.currentLang)),
          backgroundColor: widget.seedColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(Translations.getEvaluationText('loadingDetails', widget.currentLang)),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_errorMsg.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMsg,
                                        style: const TextStyle(fontSize: 14, color: Colors.orange),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            _buildDetailRow('⚽', Translations.getEvaluationText('match', widget.currentLang), _details?['match'] ?? 'N/A', textColor: widget.textColor),
                            _buildDetailRow('🏟️', Translations.getEvaluationText('stadium', widget.currentLang), _details?['stadium'] ?? 'N/A', textColor: widget.textColor),
                            _buildDetailRow('🏆', Translations.getEvaluationText('competition', widget.currentLang), _details?['competition'] ?? 'N/A', textColor: widget.textColor),
                            _buildDetailRow('📅', Translations.getEvaluationText('dateField', widget.currentLang), _details?['match_date']?.split('T')[0] ?? 'N/A', textColor: widget.textColor),
                            _buildDetailRow('⚽', Translations.getEvaluationText('finalScore', widget.currentLang), _details?['final_score'] ?? 'N/A', textColor: widget.textColor),
                            _buildDetailRow('⭐', Translations.getEvaluationText('totalScore', widget.currentLang), '${_details?['total_score'] ?? 'N/A'}', textColor: widget.textColor),
                            _buildDetailRow('📈', Translations.getEvaluationText('overallRating', widget.currentLang), _details?['overall_rating'] ?? 'N/A', textColor: widget.textColor),
                            _buildDetailRow('📝', Translations.getEvaluationText('notes', widget.currentLang), _details?['notes'] ?? 'N/A', textColor: widget.textColor),
                            // Handle null sections gracefully with placeholder
                            if (_details?['sections'] == null || (_details?['sections'] as Map?)?.isEmpty == true) ...[
                              const SizedBox(height: 24),
                              Card(
                                color: Colors.grey.withOpacity(0.1),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Icon(Icons.visibility_off, color: Colors.grey, size: 48),
                                      const SizedBox(height: 8),
                                      Text(
                                        Translations.getEvaluationText('detailedSectionsNotAvailable', widget.currentLang),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: widget.textColor.withOpacity(0.7),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        Translations.getEvaluationText('summaryShownAbove', widget.currentLang),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: widget.textColor.withOpacity(0.5),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ] else if (_details?['sections'] != null) ...[
                              const SizedBox(height: 24),
                              Text(
                                Translations.getEvaluationText('evaluationSections', widget.currentLang),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: widget.textColor,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...(_details?['sections'] as Map? ?? {}).entries.map(
                                (e) => Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: _buildDetailRow(
                                      '📊',
                                      '${e.key.replaceAll('_', ' ').toUpperCase()}',
                                      'Subtotal: ${e.value['subtotal']} (Weight: ${e.value['weight']})',
                                      textColor: widget.textColor,
                                    ),
                                  ),
                                ),
                              ),
                              if ((_details?['sections'] as Map?)?['technical_performance']?['items'] != null) ...[
                                const SizedBox(height: 16),
                                Text(
                                  Translations.getEvaluationText('technicalPerformanceItems', widget.currentLang),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: widget.textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...((_details?['sections'] as Map?)?['technical_performance']?['items'] as List? ?? []).map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                                    child: _buildDetailRow(
                                      '•',
                                      item['label'] ?? 'N/A',
                                      '${item['score'] ?? 'N/A'}/${item['out_of'] ?? 'N/A'}',
                                      textColor: widget.textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ],
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