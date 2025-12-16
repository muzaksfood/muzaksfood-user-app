import 'package:flutter/material.dart';
import 'package:flutter_grocery/features/order_track/services/order_status_notification_service.dart';

class OrderNotificationProvider extends ChangeNotifier {
  final OrderStatusNotificationService _notificationService;

  Set<int> _subscribedOrderIds = {};
  Map<int, String> _latestOrderStatus = {};

  Set<int> get subscribedOrderIds => _subscribedOrderIds;
  Map<int, String> get latestOrderStatus => _latestOrderStatus;

  OrderNotificationProvider({required OrderStatusNotificationService notificationService})
      : _notificationService = notificationService;

  Future<void> initializeOrderNotifications() async {
    try {
      await _notificationService.initializeOrderStatusNotifications();
      debugPrint('Order notifications initialized');
    } catch (e) {
      debugPrint('Error initializing order notifications: $e');
    }
  }

  Future<void> subscribeToOrder(int orderId) async {
    try {
      await _notificationService.subscribeToOrderNotifications(orderId);
      _subscribedOrderIds.add(orderId);
      notifyListeners();
      debugPrint('Subscribed to order $orderId');
    } catch (e) {
      debugPrint('Error subscribing to order: $e');
    }
  }

  Future<void> unsubscribeFromOrder(int orderId) async {
    try {
      await _notificationService.unsubscribeFromOrderNotifications(orderId);
      _subscribedOrderIds.remove(orderId);
      _latestOrderStatus.remove(orderId);
      notifyListeners();
      debugPrint('Unsubscribed from order $orderId');
    } catch (e) {
      debugPrint('Error unsubscribing from order: $e');
    }
  }

  void updateOrderStatus(int orderId, String status) {
    _latestOrderStatus[orderId] = status;
    notifyListeners();
  }

  bool isSubscribedToOrder(int orderId) {
    return _subscribedOrderIds.contains(orderId);
  }

  String? getLatestOrderStatus(int orderId) {
    return _latestOrderStatus[orderId];
  }

  void dispose() {
    _notificationService.unsubscribeFromAllOrderTopics();
    _subscribedOrderIds.clear();
    _latestOrderStatus.clear();
  }
}
