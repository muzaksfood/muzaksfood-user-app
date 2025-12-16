import 'package:flutter/material.dart';
import 'package:flutter_grocery/features/checkout/domain/models/saved_payment_method_model.dart';
import 'package:flutter_grocery/features/checkout/domain/repositories/payment_method_repo.dart';

class PaymentMethodProvider extends ChangeNotifier {
  final PaymentMethodRepo paymentMethodRepo;

  PaymentMethodProvider({required this.paymentMethodRepo});

  List<SavedPaymentMethod> _savedPaymentMethods = [];
  SavedPaymentMethod? _defaultPaymentMethod;
  bool _isLoading = false;

  List<SavedPaymentMethod> get savedPaymentMethods => _savedPaymentMethods;
  SavedPaymentMethod? get defaultPaymentMethod => _defaultPaymentMethod;
  bool get isLoading => _isLoading;

  Future<void> loadSavedPaymentMethods() async {
    _isLoading = true;
    notifyListeners();

    try {
      _savedPaymentMethods = await paymentMethodRepo.getSavedPaymentMethods();
      _defaultPaymentMethod = await paymentMethodRepo.getDefaultPaymentMethod();
    } catch (e) {
      debugPrint('Error loading saved payment methods: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addPaymentMethod(SavedPaymentMethod method) async {
    try {
      await paymentMethodRepo.savePaymentMethod(method);
      _savedPaymentMethods.add(method);
      if (method.isDefault) {
        _defaultPaymentMethod = method;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding payment method: $e');
      rethrow;
    }
  }

  Future<void> updatePaymentMethod(SavedPaymentMethod method) async {
    try {
      await paymentMethodRepo.updatePaymentMethod(method);
      final index = _savedPaymentMethods.indexWhere((m) => m.id == method.id);
      if (index != -1) {
        _savedPaymentMethods[index] = method;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating payment method: $e');
      rethrow;
    }
  }

  Future<void> deletePaymentMethod(String id) async {
    try {
      await paymentMethodRepo.deletePaymentMethod(id);
      _savedPaymentMethods.removeWhere((m) => m.id == id);
      if (_defaultPaymentMethod?.id == id) {
        _defaultPaymentMethod = _savedPaymentMethods.isNotEmpty ? _savedPaymentMethods.first : null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting payment method: $e');
      rethrow;
    }
  }

  Future<void> setDefaultPaymentMethod(String id) async {
    try {
      await paymentMethodRepo.setDefaultPaymentMethod(id);
      for (var i = 0; i < _savedPaymentMethods.length; i++) {
        _savedPaymentMethods[i] = _savedPaymentMethods[i].copyWith(isDefault: _savedPaymentMethods[i].id == id);
      }
      _defaultPaymentMethod = _savedPaymentMethods.firstWhere((m) => m.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting default payment method: $e');
      rethrow;
    }
  }
}
