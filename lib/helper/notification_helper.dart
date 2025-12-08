import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grocery/common/enums/notification_type.dart';
import 'package:flutter_grocery/common/models/notification_body.dart';
import 'package:flutter_grocery/features/splash/providers/splash_provider.dart';
import 'package:flutter_grocery/helper/maintenance_helper.dart';
import 'package:flutter_grocery/helper/route_helper.dart';
import 'package:flutter_grocery/main.dart';
import 'package:flutter_grocery/utill/app_constants.dart';
import 'package:flutter_grocery/common/widgets/notification_dialog_web_widget.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class NotificationHelper {

  static Future<void> initialize(FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
    var androidInitialize = const AndroidInitializationSettings('notification_icon');
    var iOSInitialize = const DarwinInitializationSettings();
    var initializationsSettings = InitializationSettings(android: androidInitialize, iOS: iOSInitialize);

    flutterLocalNotificationsPlugin.initialize(initializationsSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {

      int? orderId;
      String? type = 'general';
      String? userType, profileImage, userName;
      if(notificationResponse.payload!.isNotEmpty) {
        orderId = int.tryParse(jsonDecode(notificationResponse.payload!)['order_id']);
        type = jsonDecode(notificationResponse.payload!)['type'];
        userType = jsonDecode(notificationResponse.payload!)['sender_type'];
        profileImage = jsonDecode(notificationResponse.payload!)['profile_image'];
        userName = jsonDecode(notificationResponse.payload!)['name'];
      }

        try{
          if( type == 'message') {
            RouteHelper.getChatRoute(
                orderId: orderId.toString(), userName: userName ?? "",
                profileImage: profileImage ?? "", senderType: userType ?? "admin",
            );
          }
          else if(orderId != null) {
            RouteHelper.getOrderDetailsRoute(orderId.toString());
          }else if(type == 'wallet') {
            RouteHelper.getWalletRoute(status: '', action: RouteAction.pushReplacement);
          }else if(type == 'general'){
            RouteHelper.getNotificationScreen();
        }

        }catch (e){return;}
        return;
      },);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (kDebugMode) {
        print("onMessage: ${message.notification?.title}/${message.notification?.body}/${message.notification?.titleLocKey}");
        print('id ${message.data}');
      }

      if(message.data['type'] == 'maintenance'){
        final SplashProvider splashProvider = Provider.of<SplashProvider>(Get.context!, listen: false);
        await splashProvider.initConfig(Get.context!, fromNotification: true);
      }

      if(message.data['type'] != 'maintenance') {
        showNotification(message, flutterLocalNotificationsPlugin, kIsWeb);
      }

    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      if (kDebugMode) {
        print("onOpenApp: ${message.notification?.title}/${message.notification?.body}/${message.notification?.titleLocKey}");
      }

      if(message.data['type'] == 'maintenance'){
        final SplashProvider splashProvider = Provider.of<SplashProvider>(Get.context!, listen: false);
        await splashProvider.initConfig(Get.context!, fromNotification: true);
        if(MaintenanceHelper.isMaintenanceModeEnable(splashProvider.configModel) && (MaintenanceHelper.checkCustomerMaintenanceMode(splashProvider.configModel) || MaintenanceHelper.checkWebMaintenanceMode(splashProvider.configModel))) {
          RouteHelper.getMaintenanceRoute(action: RouteAction.pushNamedAndRemoveUntil);
        }else if (!MaintenanceHelper.isMaintenanceModeEnable(splashProvider.configModel) && ModalRoute.of(Get.context!)?.settings.name == RouteHelper.maintenance){
          RouteHelper.getMainRoute(action: RouteAction.pushNamedAndRemoveUntil);
        }
      }


      final NotificationBody notificationBody = NotificationHelper.convertNotification(message.data);
      NotificationType? notificationType = getNotificationTypeEnum(notificationBody.type);

      switch (notificationType) {
        case NotificationType.order:
          RouteHelper.getOrderDetailsRoute(notificationBody.orderId.toString(), action: RouteAction.pushNamedAndRemoveUntil);
          break;
        case NotificationType.message:
          RouteHelper.getChatRoute(
              orderId: notificationBody.orderId.toString(),
              senderType:  notificationBody.senderType ?? "admin",
              profileImage:  notificationBody.userImage ?? "",
              userName: notificationBody.userName ?? "",
              isAppBar: true, action: RouteAction.pushNamedAndRemoveUntil
          );
          break;
        case NotificationType.general:
          RouteHelper.getNotificationScreen(action: RouteAction.pushNamedAndRemoveUntil);
          break;
        case NotificationType.wallet:
          RouteHelper.getWalletRoute(status: '', action: RouteAction.pushNamedAndRemoveUntil);
          break;
        case null:
          debugPrint('==============Notification type does not exist============${notificationBody.type}');
          RouteHelper.getMainRoute(action: RouteAction.pushNamedAndRemoveUntil);
      }

    });
  }

  static Future<void> showNotification(RemoteMessage message, FlutterLocalNotificationsPlugin? fln, bool data) async {
    String? title;
    String? body;
    String? orderID;
    String? image;
    String? type;
    String? userName;
    String? senderType;
    String? profileImage;

    title = message.data['title'];
    body = message.data['body'];
    orderID = message.data['order_id'];
    userName = message.data['name'];
    senderType = message.data['sender_type'];
    profileImage = message.data['profile_image'];
    image = (message.data['image'] != null && message.data['image'].isNotEmpty)
        ? message.data['image'].startsWith('http') ? message.data['image']
        : '${AppConstants.baseUrl}/storage/app/public/notification/${message.data['image']}' : null;
    type = message.data['type'];

    Map<String, String> payloadData = {
      'title' : '$title',
      'body' : '$body',
      'order_id' : '$orderID',
      'image' : '$image',
      'type' : '$type',
      'name' : '$userName',
      'sender_type' : '$senderType',
      'profile_image' : '$profileImage',
    };

    if(kIsWeb) {
      showDialog(
          context: Get.context!,
          builder: (context) => Center(
            child: NotificationDialogWebWidget(
              orderId: int.tryParse(orderID!),
              title: title,
              body: body,
              image: image,
              type: type,
              userName: userName,
              profileImage: profileImage,
              senderType: senderType,
            ),
          )
      );
    }

    else if(image != null && image.isNotEmpty) {
      try{
        await showBigPictureNotificationHiddenLargeIcon(payloadData, fln!);
      }catch(e) {
        await showBigTextNotification(payloadData, fln!);
      }
    }else {
      await showBigTextNotification(payloadData, fln!);
    }
  }


  static Future<void> showBigTextNotification(Map<String, String> data, FlutterLocalNotificationsPlugin fln) async {
    BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      data['body']!,
      htmlFormatBigText: true,
      contentTitle: data['title'],
      htmlFormatContentTitle: true,

    );
    AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      AppConstants.appName, AppConstants.appName, importance: Importance.max,
      styleInformation: bigTextStyleInformation, priority: Priority.max, playSound: true,
      sound: const RawResourceAndroidNotificationSound('notification'),
    );
    NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0, data['title'], data['body'], platformChannelSpecifics, payload: jsonEncode(data));
  }

  static Future<void> showBigPictureNotificationHiddenLargeIcon(
      Map<String, String> data,
      FlutterLocalNotificationsPlugin fln,
      ) async {
    final String largeIconPath = await _downloadAndSaveFile(data['image']!, 'largeIcon');
    final String bigPicturePath = await _downloadAndSaveFile(data['image']!, 'bigPicture');
    final BigPictureStyleInformation bigPictureStyleInformation = BigPictureStyleInformation(
      FilePathAndroidBitmap(bigPicturePath), hideExpandedLargeIcon: true,
      contentTitle: data['title'], htmlFormatContentTitle: true,
      summaryText: data['body'], htmlFormatSummaryText: true,
    );
    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      AppConstants.appName, AppConstants.appName,
      largeIcon: FilePathAndroidBitmap(largeIconPath), priority: Priority.max, playSound: true,
      styleInformation: bigPictureStyleInformation, importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('notification'),
    );
    final NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0, data['title'], data['body'], platformChannelSpecifics, payload: jsonEncode(data));
  }

  static Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final Response response = await Dio().get(url, options: Options(responseType: ResponseType.bytes));
    final File file = File(filePath);
    await file.writeAsBytes(response.data);
    return filePath;
  }

  static NotificationBody convertNotification(Map<String, dynamic> data){
    return NotificationBody.fromJson(data);
  }

}

@pragma('vm:entry-point')
Future<dynamic> myBackgroundMessageHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print("onBackground: ${message.notification!.title}/${message.notification!.body}/${message.notification!.titleLocKey}");
  }
}
