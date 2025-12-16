import 'package:flutter/material.dart';
import 'package:flutter_grocery/data/datasource/remote/dio/dio_client.dart';
import 'package:flutter_grocery/utill/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryProvider extends ChangeNotifier {
  static const String _searchHistoryKey = 'search_history';
  static const int _maxHistoryItems = 20;

  final SharedPreferences _sharedPreferences;
  final DioClient? _dioClient;

  List<String> _searchHistory = [];
  List<String> _trendingSearches = [];
  bool _isLoadingTrending = false;

  List<String> get searchHistory => _searchHistory;
  List<String> get trendingSearches => _trendingSearches;
  bool get isLoadingTrending => _isLoadingTrending;

  SearchHistoryProvider({
    required SharedPreferences sharedPreferences,
    DioClient? dioClient,
  })  : _sharedPreferences = sharedPreferences,
        _dioClient = dioClient {
    _loadSearchHistory();
  }

  void _loadSearchHistory() {
    try {
      final String? historyJson = _sharedPreferences.getString(_searchHistoryKey);
      if (historyJson != null && historyJson.isNotEmpty) {
        final List<dynamic> decoded = (historyJson).split(',');
        _searchHistory = decoded.map((e) => e.toString()).toList();
      }
    } catch (e) {
      debugPrint('Error loading search history: $e');
      _searchHistory = [];
    }
  }

  Future<void> addSearchToHistory(String query) async {
    if (query.isEmpty) return;

    try {
      _searchHistory.removeWhere((item) => item.toLowerCase() == query.toLowerCase());

      _searchHistory.insert(0, query);

      if (_searchHistory.length > _maxHistoryItems) {
        _searchHistory = _searchHistory.sublist(0, _maxHistoryItems);
      }

      await _sharedPreferences.setString(
        _searchHistoryKey,
        _searchHistory.join(','),
      );

      if (_dioClient != null) {
        try {
          await _dioClient!.post(
            AppConstants.saveSearchHistoryUri,
            data: {'search_query': query},
          );
        } catch (e) {
          debugPrint('Failed to sync search history: $e');
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding search to history: $e');
    }
  }

  Future<void> removeFromHistory(String query) async {
    try {
      _searchHistory.remove(query);
      await _sharedPreferences.setString(
        _searchHistoryKey,
        _searchHistory.join(','),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing search from history: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      _searchHistory.clear();
      await _sharedPreferences.remove(_searchHistoryKey);

      if (_dioClient != null) {
        try {
          await _dioClient!.post(AppConstants.clearSearchHistoryUri);
        } catch (e) {
          debugPrint('Failed to clear search history on backend: $e');
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing search history: $e');
    }
  }

  Future<void> loadTrendingSearches() async {
    if (_dioClient == null) return;

    try {
      _isLoadingTrending = true;
      notifyListeners();

      final response = await _dioClient!.get(AppConstants.getTrendingSearchesUri);
      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> trendingList = data is Map ? data['trending_searches'] ?? [] : [];

        _trendingSearches = trendingList
            .map((item) => item is Map ? (item['search_query'] ?? item.toString()) : item.toString())
            .cast<String>()
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading trending searches: $e');
      _trendingSearches = [];
    }

    _isLoadingTrending = false;
    notifyListeners();
  }
}
