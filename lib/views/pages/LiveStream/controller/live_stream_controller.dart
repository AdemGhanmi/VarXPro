import 'package:VarXPro/views/pages/LiveStream/model/category.dart';
import 'package:VarXPro/views/pages/LiveStream/model/channel.dart';
import 'package:VarXPro/views/pages/LiveStream/service/api_service.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class LiveStreamController extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final Logger _logger = Logger();

  List<Category> categories = [];
  List<Channel> channels = [];
  List<Channel> filteredChannels = [];
  String selectedCategoryId = '';
  String searchQuery = '';
  bool isLoading = true;
  String? errorMessage;

  Future<void> fetchData() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        fetchCategories(),
        fetchChannels(),
      ]);
      filterChannels();
    } catch (e, stackTrace) {
      _logger.e("Error loading data", error: e, stackTrace: stackTrace);
      errorMessage = 'Error loading data';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCategories() async {
    try {
      categories = await _apiService.fetchCategories();
    } catch (e, stackTrace) {
      _logger.e("Error fetching categories", error: e, stackTrace: stackTrace);
      rethrow; 
    }
    notifyListeners();
  }

  Future<void> fetchChannels() async {
    try {
      channels = await _apiService.fetchChannels();
      filteredChannels = channels;
    } catch (e, stackTrace) {
      _logger.e("Error fetching channels", error: e, stackTrace: stackTrace);
      rethrow;
    }
    notifyListeners();
  }

  void filterChannels() {
    filteredChannels = channels.where((channel) {
      final categoryMatch =
          selectedCategoryId.isEmpty || channel.categoryId == selectedCategoryId;

      final searchMatch = (channel.name ?? '')
          .toLowerCase()
          .contains(searchQuery.toLowerCase());

      return categoryMatch && searchMatch;
    }).toList();

    notifyListeners();
  }

  void resetFilters() {
    selectedCategoryId = '';
    searchQuery = '';
    filteredChannels = channels;
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    searchQuery = query;
    filterChannels();
  }

  void updateSelectedCategory(String categoryId) {
    selectedCategoryId = categoryId;
    filterChannels();
  }
}
