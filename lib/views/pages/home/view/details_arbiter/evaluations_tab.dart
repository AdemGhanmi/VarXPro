// lib/views/pages/home/view/details_arbiter/evaluations_tab.dart (fixed: handle 403 on getEvaluation by showing basic details from list data, improved UI with emojis and better error messages)
import 'package:flutter/material.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/provider/modeprovider.dart';
import 'package:VarXPro/views/connexion/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:VarXPro/views/pages/home/service/evaluations_service.dart';

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
  });

  @override
  _EvaluationsTabState createState() => _EvaluationsTabState();
}

class _EvaluationsTabState extends State<EvaluationsTab>
    with AutomaticKeepAliveClientMixin {
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
      final result = await EvaluationsService.listRefereeEvaluations(
        widget.refereeId,
      );
      if (result['success']) {
        setState(() {
          _evaluations = List<Map<String, dynamic>>.from(result['data'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          _showErrorSnackBar(
            result['error'] ?? 'Failed to load evaluations 📭',
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorSnackBar('Error loading evaluations: $e 🔄');
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
                  'Evaluations',
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
                      const Icon(
                        Icons.lock_outline,
                        color: Colors.orange,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '🔒 Login to view and manage evaluations',
                        style: TextStyle(
                          color: widget.textColor.withOpacity(0.8),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in as user or supervisor to access 📋',
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
                      'Loading evaluations... ⏳',
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
                      'No evaluations available 😔',
                      style: TextStyle(
                        color: widget.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create one to get started 📝',
                      style: TextStyle(
                        color: widget.textColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadEvaluations,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reload 🔄'),
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
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final eval = _evaluations[index];
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showDetailsDialog(context, eval),
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
                                          'Score: ${eval['total_score'] ?? 'N/A'}',
                                          style: TextStyle(
                                            color: widget.textColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getRatingColor(
                                            eval['overall_rating'] ?? '',
                                          ).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          '${eval['overall_rating'] ?? 'N/A'}',
                                          style: TextStyle(
                                            color: _getRatingColor(
                                              eval['overall_rating'] ?? '',
                                            ),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '⚽ Match: ${eval['match'] ?? 'N/A'}',
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
                                  if (widget.isSupervisor)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                            ),
                                            onPressed: () {
                                              _showEditDialog(
                                                context,
                                                eval['id'],
                                                eval,
                                                widget.onUpdate,
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () {
                                              _showDeleteConfirm(
                                                context,
                                                eval['id'],
                                              );
                                            },
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
                  );
                },
              ),
            if ((widget.isSupervisor || widget.isUser) && !isGuest)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.onCreate,
                    icon: const Icon(Icons.add),
                    label: Text(
                      widget.isSupervisor
                          ? 'Create New Evaluation (Full Access) 📝'
                          : 'Create New Evaluation 📝',
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

  Color _getRatingColor(String rating) {
    switch (rating.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'very_good':
        return Colors.blue;
      case 'good':
        return Colors.orange;
      case 'acceptable':
        return Colors.yellow;
      default:
        return Colors.red;
    }
  }

  Future<void> _showDetailsDialog(BuildContext context, dynamic eval) async {
    // First, try to get full details
    Map<String, dynamic>? details;
    String errorMsg = '';
    try {
      final result = await EvaluationsService.getEvaluation(
        eval['id'].toString(),
      );
      if (result['success']) {
        details = result['data'];
      } else {
        errorMsg = result['error'] ?? 'Failed to load full details';
        // Fallback to basic eval data
        details = eval;
      }
    } catch (e) {
      errorMsg = 'Error loading details: $e';
      details = eval; // Use basic data
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('📋 '),
            const Expanded(child: Text('Evaluation Details')),
            if (errorMsg.isNotEmpty)
              const Icon(Icons.warning_amber, color: Colors.orange),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (errorMsg.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMsg,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              _buildDetailRow('⚽', 'Match', details?['match'] ?? 'N/A'),
              _buildDetailRow('🏟️', 'Stadium', details?['stadium'] ?? 'N/A'),
              _buildDetailRow(
                '🏆',
                'Competition',
                details?['competition'] ?? 'N/A',
              ),
              _buildDetailRow(
                '📅',
                'Date',
                details?['match_date']?.split('T')[0] ?? 'N/A',
              ),
              _buildDetailRow(
                '⚽',
                'Final Score',
                details?['final_score'] ?? 'N/A',
              ),
              _buildDetailRow(
                '⭐',
                'Total Score',
                '${details?['total_score'] ?? 'N/A'}',
              ),
              _buildDetailRow(
                '📈',
                'Rating',
                details?['overall_rating'] ?? 'N/A',
              ),
              _buildDetailRow('📝', 'Notes', details?['notes'] ?? 'N/A'),
              if (details?['sections'] != null) ...[
                const SizedBox(height: 16),
                const Text(
                  '📂 Sections:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...(details?['sections'] as Map? ?? {}).entries.map(
                  (e) => _buildDetailRow(
                    '📊',
                    '${e.key.replaceAll('_', ' ').toUpperCase()}',
                    'Subtotal: ${e.value['subtotal']} (Weight: ${e.value['weight']})',
                  ),
                ),
                if ((details?['sections']
                        as Map?)?['technical_performance']?['items'] !=
                    null) ...[
                  const SizedBox(height: 8),
                  const Text(
                    '🔧 Technical Items:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...((details?['sections']
                                  as Map?)?['technical_performance']?['items']
                              as List? ??
                          [])
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _buildDetailRow(
                            '',
                            item['label'],
                            '${item['score']}/${item['out_of']}',
                          ),
                        ),
                      ),
                ],
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close ❌'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String emoji, String label, String value) {
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
                style: const TextStyle(fontSize: 14),
                children: [
                  const TextSpan(
                    text: '',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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

  void _showEditDialog(
    BuildContext context,
    int id,
    Map<String, dynamic> eval,
    Future<void> Function(int, Map<String, dynamic>) onUpdate,
  ) {
    final TextEditingController notesController = TextEditingController(
      text: eval['notes'] ?? '',
    );
    final TextEditingController scoreController = TextEditingController(
      text: eval['total_score'].toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [Text('✏️ '), Text('Edit Evaluation')]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes 📝',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: scoreController,
              decoration: const InputDecoration(
                labelText: 'Total Score (0-100) ⭐',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel ❌'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newScore =
                  int.tryParse(scoreController.text) ?? eval['total_score'];
              if (newScore < 0 || newScore > 100) {
                _showErrorSnackBar('Score must be 0-100 ⭐');
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
            child: const Text('Save 💾'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [Text('🗑️ '), Text('Confirm Delete')]),
        content: const Text(
          'Are you sure you want to delete this evaluation? This action cannot be undone. ⚠️',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel ❌'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await EvaluationsService.deleteEvaluation(id);
              if (result['success']) {
                _loadEvaluations(); // Reload after delete
                _showSuccessSnackBar('Deleted successfully 🗑️');
              } else {
                _showErrorSnackBar(result['error'] ?? 'Delete failed ❌');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
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
