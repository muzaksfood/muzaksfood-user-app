import 'package:firebase_database/firebase_database.dart'; 
import 'package:flutter/foundation.dart';
import 'package:flutter_grocery/features/order/domain/models/delivery_man_model.dart';

class FirebaseRealtimeTrackerService {
  static const String _ordersPath = 'active_orders';
  static const String _deliveryMenPath = 'delivery_men';

  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Stream<DeliveryManModel?> getDeliveryManLocationStream({
    required int deliveryManId,
    required int orderId,
  }) {
    final ref = _database.ref('$_deliveryMenPath/$deliveryManId/orders/$orderId');
    
    return ref.onValue.map((event) {
      if (event.snapshot.exists) {
        try {
          final data = event.snapshot.value as Map<dynamic, dynamic>?;
          if (data != null) {
            return DeliveryManModel.fromJson(Map<String, dynamic>.from(data));
          }
        } catch (e) {
          debugPrint('Error parsing delivery man data: $e');
        }
      }
      return null;
    }).handleError((error) {
      debugPrint('Firebase error: $error');
    });
  }

  Stream<Map<String, dynamic>?> getOrderStatusStream({required int orderId}) {
    final ref = _database.ref('$_ordersPath/$orderId/status');
    
    return ref.onValue.map((event) {
      if (event.snapshot.exists) {
        try {
          final data = event.snapshot.value;
          if (data is Map) {
            return Map<String, dynamic>.from(data);
          } else if (data is String) {
            return {'status': data, 'updatedAt': DateTime.now().toIso8601String()};
          }
        } catch (e) {
          debugPrint('Error parsing order status: $e');
        }
      }
      return null;
    }).handleError((error) {
      debugPrint('Firebase error: $error');
    });
  }

  Stream<Map<String, dynamic>?> getDeliveryEstimateStream({required int orderId}) {
    final ref = _database.ref('$_ordersPath/$orderId/estimate');
    
    return ref.onValue.map((event) {
      if (event.snapshot.exists) {
        try {
          final data = event.snapshot.value as Map<dynamic, dynamic>?;
          if (data != null) {
            return Map<String, dynamic>.from(data);
          }
        } catch (e) {
          debugPrint('Error parsing delivery estimate: $e');
        }
      }
      return null;
    }).handleError((error) {
      debugPrint('Firebase error: $error');
    });
  }

  void startOrderTracking({
    required int orderId,
    required int deliveryManId,
  }) {
    final ref = _database.ref('$_ordersPath/$orderId/tracking');
    ref.set({
      'orderId': orderId,
      'deliveryManId': deliveryManId,
      'startedAt': ServerValue.timestamp,
      'status': 'active',
    }).catchError((error) {
      debugPrint('Error starting order tracking: $error');
    });
  }

  void stopOrderTracking({required int orderId}) {
    final ref = _database.ref('$_ordersPath/$orderId/tracking');
    ref.update({
      'status': 'inactive',
      'endedAt': ServerValue.timestamp,
    }).catchError((error) {
      debugPrint('Error stopping order tracking: $error');
    });
  }

  void updateDeliveryEstimate({
    required int orderId,
    required int estimatedMinutes,
    required double distanceKm,
  }) {
    final ref = _database.ref('$_ordersPath/$orderId/estimate');
    ref.set({
      'minutes': estimatedMinutes,
      'distanceKm': distanceKm,
      'updatedAt': ServerValue.timestamp,
    }).catchError((error) {
      debugPrint('Error updating delivery estimate: $error');
    });
  }

  Future<void> updateDeliveryManLocation({
    required int deliveryManId,
    required int orderId,
    required double latitude,
    required double longitude,
  }) {
    final ref = _database.ref('$_deliveryMenPath/$deliveryManId/orders/$orderId');
    return ref.update({
      'latitude': latitude,
      'longitude': longitude,
      'lastUpdated': ServerValue.timestamp,
    }).catchError((error) {
      debugPrint('Error updating delivery man location: $error');
    });
  }

  void dispose() {
    _database.goOffline();
  }
}
