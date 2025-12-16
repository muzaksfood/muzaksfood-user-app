import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_grocery/data/datasource/remote/dio/dio_client.dart';
import 'package:flutter_grocery/features/checkout/domain/models/saved_payment_method_model.dart';
import 'package:flutter_grocery/utill/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentMethodRepo {
  static const String _savedPaymentMethodsKey = 'saved_payment_methods';

  final SharedPreferences _sharedPreferences;
  final DioClient? _dioClient;

  PaymentMethodRepo({
    required SharedPreferences sharedPreferences,
    DioClient? dioClient,
  })  : _sharedPreferences = sharedPreferences,
        _dioClient = dioClient;

  Future<void> savePaymentMethod(SavedPaymentMethod method) async {
    try {
      final savedMethods = await getSavedPaymentMethods();
      savedMethods.add(method);
      
      await _sharedPreferences.setString(
        _savedPaymentMethodsKey,
        jsonEncode(savedMethods.map((m) => m.toJson()).toList()),
      );

      if (_dioClient != null) {
        try {
          await _dioClient!.post(
            AppConstants.addPaymentMethodUri,
            data: method.toJson(),
          );
        } catch (e) {
          debugPrint('Failed to sync payment method to backend: $e');
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<SavedPaymentMethod>> getSavedPaymentMethods({bool syncWithBackend = true}) async {
    try {
      if (_dioClient != null && syncWithBackend) {
        try {
          final response = await _dioClient!.get(AppConstants.getSavedPaymentMethodsUri);
          if (response.statusCode == 200) {
            final data = response.data;
            final List<dynamic> methodsList = data is Map ? data['payment_methods'] ?? [] : [];
            
            final methods = methodsList
                .map((item) => SavedPaymentMethod.fromJson(item as Map<String, dynamic>))
                .toList();
            
            await _sharedPreferences.setString(
              _savedPaymentMethodsKey,
              jsonEncode(methods.map((m) => m.toJson()).toList()),
            );
            
            return methods;
          }
        } catch (e) {
          debugPrint('Failed to fetch payment methods from backend, using local cache: $e');
        }
      }

      final jsonString = _sharedPreferences.getString(_savedPaymentMethodsKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded
          .map((item) => SavedPaymentMethod.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> updatePaymentMethod(SavedPaymentMethod method) async {
    try {
      final savedMethods = await getSavedPaymentMethods(syncWithBackend: false);
      final index = savedMethods.indexWhere((m) => m.id == method.id);
      if (index != -1) {
        savedMethods[index] = method;
        await _sharedPreferences.setString(
          _savedPaymentMethodsKey,
          jsonEncode(savedMethods.map((m) => m.toJson()).toList()),
        );

        if (_dioClient != null) {
          try {
            await _dioClient!.put(
              '${AppConstants.updatePaymentMethodUri}/${method.id}',
              data: method.toJson(),
            );
          } catch (e) {
            debugPrint('Failed to sync payment method update to backend: $e');
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deletePaymentMethod(String id) async {
    try {
      final savedMethods = await getSavedPaymentMethods(syncWithBackend: false);
      savedMethods.removeWhere((m) => m.id == id);
      await _sharedPreferences.setString(
        _savedPaymentMethodsKey,
        jsonEncode(savedMethods.map((m) => m.toJson()).toList()),
      );

      if (_dioClient != null) {
        try {
          await _dioClient!.delete('${AppConstants.deletePaymentMethodUri}$id');
        } catch (e) {
          debugPrint('Failed to sync payment method deletion to backend: $e');
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setDefaultPaymentMethod(String id) async {
    try {
      final savedMethods = await getSavedPaymentMethods(syncWithBackend: false);
      for (int i = 0; i < savedMethods.length; i++) {
        savedMethods[i] = savedMethods[i].copyWith(isDefault: savedMethods[i].id == id);
      }
      await _sharedPreferences.setString(
        _savedPaymentMethodsKey,
        jsonEncode(savedMethods.map((m) => m.toJson()).toList()),
      );

      if (_dioClient != null) {
        try {
          await _dioClient!.post(
            AppConstants.setDefaultPaymentMethodUri,
            data: {'payment_method_id': id},
          );
        } catch (e) {
          debugPrint('Failed to set default payment method on backend: $e');
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<SavedPaymentMethod?> getDefaultPaymentMethod() async {
    try {
      final methods = await getSavedPaymentMethods();
      return methods.firstWhere(
        (m) => m.isDefault,
        orElse: () => methods.isNotEmpty ? methods.first : null as SavedPaymentMethod,
      );
    } catch (e) {
      return null;
    }
  }
}
