import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grocery/data/datasource/remote/dio/dio_client.dart';
import 'package:flutter_grocery/utill/app_constants.dart';

class OrderStatusNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final DioClient? _dioClient;

  OrderStatusNotificationService({DioClient? dioClient}) : _dioClient = dioClient;

  Future<void> initializeOrderStatusNotifications() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission for order status notifications');
        await _subscribeToOrderStatusTopic();
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('User granted provisional permission');
        await _subscribeToOrderStatusTopic();
      } else {
        debugPrint('User declined or has not yet granted permission');
      }
    } catch (e) {
      debugPrint('Error initializing order status notifications: $e');
    }
  }

  Future<void> _subscribeToOrderStatusTopic() async {
    try {
      await _firebaseMessaging.subscribeToTopic('order-status-updates');
      debugPrint('Subscribed to order-status-updates topic');
    } catch (e) {
      debugPrint('Error subscribing to order-status-updates topic: $e');
    }
  }

  Future<void> subscribeToOrderNotifications(int orderId) async {
    try {
      final String topic = 'order_$orderId';
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Subscribed to order notifications for order $orderId');

      if (_dioClient != null) {
        try {
          await _dioClient!.post(
            '${AppConstants.baseUrl}/api/v1/customer/order/subscribe-notifications',
            data: {'order_id': orderId, 'fcm_topic': topic},
          );
        } catch (e) {
          debugPrint('Failed to sync order subscription to backend: $e');
        }
      }
    } catch (e) {
      debugPrint('Error subscribing to order notifications: $e');
    }
  }

  Future<void> unsubscribeFromOrderNotifications(int orderId) async {
    try {
      final String topic = 'order_$orderId';
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from order notifications for order $orderId');

      if (_dioClient != null) {
        try {
          await _dioClient!.post(
            '${AppConstants.baseUrl}/api/v1/customer/order/unsubscribe-notifications',
            data: {'order_id': orderId},
          );
        } catch (e) {
          debugPrint('Failed to sync order unsubscription to backend: $e');
        }
      }
    } catch (e) {
      debugPrint('Error unsubscribing from order notifications: $e');
    }
  }

  String parseOrderStatusFromMessage(RemoteMessage message) {
    try {
      final data = message.data;
      if (data.containsKey('order_status')) {
        return data['order_status'] ?? 'unknown';
      }
      if (message.notification?.body != null) {
        return message.notification!.body!;
      }
      return 'Order Status Updated';
    } catch (e) {
      debugPrint('Error parsing order status from message: $e');
      return 'Order Status Updated';
    }
  }

  int? parseOrderIdFromMessage(RemoteMessage message) {
    try {
      final data = message.data;
      if (data.containsKey('order_id')) {
        return int.tryParse(data['order_id'].toString());
      }
      return null;
    } catch (e) {
      debugPrint('Error parsing order ID from message: $e');
      return null;
    }
  }

  String? parseDeliveryManLocationFromMessage(RemoteMessage message) {
    try {
      final data = message.data;
      if (data.containsKey('delivery_man_location')) {
        return data['delivery_man_location'];
      }
      return null;
    } catch (e) {
      debugPrint('Error parsing delivery man location: $e');
      return null;
    }
  }

  String? parseEstimatedTimeFromMessage(RemoteMessage message) {
    try {
      final data = message.data;
      if (data.containsKey('estimated_time')) {
        return data['estimated_time'];
      }
      return null;
    } catch (e) {
      debugPrint('Error parsing estimated time: $e');
      return null;
    }
  }

  void unsubscribeFromAllOrderTopics() {
    try {
      _firebaseMessaging.unsubscribeFromTopic('order-status-updates');
      debugPrint('Unsubscribed from general order-status-updates topic');
    } catch (e) {
      debugPrint('Error unsubscribing from order topics: $e');
    }
  }
}
