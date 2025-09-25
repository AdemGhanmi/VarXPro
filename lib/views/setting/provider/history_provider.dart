// Updated file: lib/provider/history_provider.dart (New file)
import 'package:flutter/material.dart';

class HistoryItem {
  final String pageName;
  final String action;
  final DateTime timestamp;

  HistoryItem({
    required this.pageName,
    required this.action,
    required this.timestamp,
  });

  String get formattedDate => '${action} on ${timestamp.toString().substring(0, 10)}';

  @override
  String toString() => formattedDate;
}

class HistoryProvider extends ChangeNotifier {
  List<HistoryItem> _historyItems = [];

  List<HistoryItem> get historyItems => List.unmodifiable(_historyItems);

  int get historyCount => _historyItems.length;

  void addHistoryItem(String pageName, String action) {
    _historyItems.add(HistoryItem(
      pageName: pageName,
      action: action,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  void clearHistory() {
    _historyItems.clear();
    notifyListeners();
  }
}