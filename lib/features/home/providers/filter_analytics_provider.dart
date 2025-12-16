import 'package:flutter/material.dart';
import 'package:flutter_grocery/data/datasource/remote/dio/dio_client.dart';
import 'package:flutter_grocery/utill/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FilterUsageEvent {
  final String filterType;
  final double? minPrice;
  final double? maxPrice;
  final double? rating;
  final DateTime timestamp;

  FilterUsageEvent({
    required this.filterType,
    this.minPrice,
    this.maxPrice,
    this.rating,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'filterType': filterType,
    'minPrice': minPrice,
    'maxPrice': maxPrice,
    'rating': rating,
    'timestamp': timestamp.toIso8601String(),
  };
}

class FilterAnalyticsProvider extends ChangeNotifier {
  static const String _filterEventsKey = 'filter_usage_events';
  static const String _analyticsEnabledKey = 'analytics_enabled';

  final SharedPreferences _sharedPreferences;
  final DioClient? _dioClient;

  List<FilterUsageEvent> _filterEvents = [];
  bool _analyticsEnabled = true;
  bool _isSyncing = false;

  List<FilterUsageEvent> get filterEvents => _filterEvents;
  bool get analyticsEnabled => _analyticsEnabled;
  bool get isSyncing => _isSyncing;

  FilterAnalyticsProvider({
    required SharedPreferences sharedPreferences,
    DioClient? dioClient,
  })  : _sharedPreferences = sharedPreferences,
        _dioClient = dioClient {
    _loadSettings();
    _loadLocalEvents();
  }

  void _loadSettings() {
    _analyticsEnabled = _sharedPreferences.getBool(_analyticsEnabledKey) ?? true;
  }

  void _loadLocalEvents() {
    try {
      final String? eventsJson = _sharedPreferences.getString(_filterEventsKey);
      if (eventsJson != null && eventsJson.isNotEmpty) {
        _filterEvents = [];
      }
    } catch (e) {
      debugPrint('Error loading filter events: $e');
    }
  }

  Future<void> trackFilterUsage({
    required String filterType,
    double? minPrice,
    double? maxPrice,
    double? rating,
  }) async {
    if (!_analyticsEnabled) return;

    try {
      final event = FilterUsageEvent(
        filterType: filterType,
        minPrice: minPrice,
        maxPrice: maxPrice,
        rating: rating,
      );

      _filterEvents.add(event);

      if (_dioClient != null) {
        try {
          await _dioClient!.post(
            AppConstants.trackFilterAnalyticsUri,
            data: event.toJson(),
          );
        } catch (e) {
          debugPrint('Failed to sync filter analytics: $e');
        }
      }

      notifyListeners();

      if (_filterEvents.length % 10 == 0) {
        await _syncOldEvents();
      }
    } catch (e) {
      debugPrint('Error tracking filter usage: $e');
    }
  }

  Future<void> _syncOldEvents() async {
    if (_dioClient == null || _filterEvents.length < 10) return;

    try {
      _isSyncing = true;
      notifyListeners();

      final List<Map<String, dynamic>> eventsData =
          _filterEvents.map((e) => e.toJson()).toList();

      await _dioClient!.post(
        AppConstants.trackFilterAnalyticsUri,
        data: {'events': eventsData},
      );

      _filterEvents.clear();
      await _sharedPreferences.setString(_filterEventsKey, '');

      _isSyncing = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to sync filter events: $e');
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> setAnalyticsEnabled(bool enabled) async {
    _analyticsEnabled = enabled;
    await _sharedPreferences.setBool(_analyticsEnabledKey, enabled);
    notifyListeners();
  }

  void clearLocalEvents() {
    _filterEvents.clear();
    _sharedPreferences.setString(_filterEventsKey, '');
    notifyListeners();
  }
}
