import 'dart:developer';
import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truelovesocio/core/storage/secure_storage.dart';
import 'package:truelovesocio/data/services/auth_service.dart';
import 'package:truelovesocio/data/services/misc_service.dart';
import 'package:truelovesocio/data/models/socio_model.dart';

String _getValidTitle(RemoteMessage message, String defaultTitle) {
  if (message.notification?.title != null && message.notification!.title!.isNotEmpty) {
    return message.notification!.title!;
  }
  final dataTitle = message.data['title']?.toString();
  if (dataTitle != null && dataTitle.isNotEmpty) {
    return dataTitle;
  }
  return defaultTitle;
}

String _getValidBody(RemoteMessage message, String defaultBody) {
  if (message.notification?.body != null && message.notification!.body!.isNotEmpty) {
    return message.notification!.body!;
  }
  final dataBody = message.data['body']?.toString();
  if (dataBody != null && dataBody.isNotEmpty) {
    return dataBody;
  }
  return defaultBody;
}

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  final notificationId = message.data['notification_id'];
  if (notificationId != null && notificationId.isNotEmpty) {
    await MiscService().acknowledgeNotification(notificationId, 'received');
  }

  if (Platform.isIOS && message.notification != null) {
    return;
  }

  final plugin = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  await plugin.initialize(const InitializationSettings(android: androidSettings, iOS: iosSettings));

  final androidPlugin = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.createNotificationChannel(
    const AndroidNotificationChannel(
      'pedidos_v3',
      'Nuevos Pedidos',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('nuevo_pedido'),
      enableVibration: true,
      playSound: true,
    ),
  );
  
  await androidPlugin?.createNotificationChannel(
    const AndroidNotificationChannel(
      'general_channel',
      'Notificaciones Generales',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
    ),
  );

  final title = _getValidTitle(message, 'Nuevo Pedido');
  final body = _getValidBody(message, 'Tienes un nuevo pedido');
  String? soundFile = message.data['sound'];
  final channelId = message.data['channel_id'] ?? 'pedidos_v3';
  
  // Si sound es 'default' o vacío, null hará que use el sonido por defecto del sistema
  AndroidNotificationSound? androidSound = (soundFile == null || soundFile == 'default' || soundFile.isEmpty) 
      ? null 
      : RawResourceAndroidNotificationSound(soundFile);

  await plugin.show(
    DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        'Notificaciones',
        importance: Importance.max,
        priority: Priority.max,
        sound: androidSound,
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        presentBanner: true,
        presentList: true,
        sound: (soundFile == null || soundFile == 'default' || soundFile.isEmpty) 
            ? 'default' 
            : (soundFile.endsWith('.wav') ? soundFile : '$soundFile.wav'),
      ),
    ),
  );
}

class FirebaseApi {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    try {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: true,
      );

      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        log("✅ Token FCM obtenido: $token");
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token_fcm', token);
        
        final userJson = await SecureStorage.getUser();
        if (userJson != null) {
          final socio = Socio.fromJson(jsonDecode(userJson));
          await AuthService().updateFcmToken(socio.id, token);
        }
      }

      if (Platform.isIOS) {
        await _firebaseMessaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        requestCriticalPermission: true,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(android: androidSettings, iOS: iosSettings),
      );

      await _createNotificationChannels();

      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        final notificationId = initialMessage.data['notification_id'];
        if (notificationId != null) {
          await MiscService().acknowledgeNotification(notificationId, 'received');
          await MiscService().acknowledgeNotification(notificationId, 'opened');
        }
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        final notificationId = message.data['notification_id'];
        if (notificationId != null) {
          await MiscService().acknowledgeNotification(notificationId, 'received');
        }
        
        if (Platform.isAndroid || message.notification == null) {
          _showNotification(message);
        }
      });

      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token_fcm', newToken);
        final userJson = await SecureStorage.getUser();
        if (userJson != null) {
          final socio = Socio.fromJson(jsonDecode(userJson));
          await AuthService().updateFcmToken(socio.id, newToken);
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
        final notificationId = message.data['notification_id'];
        if (notificationId != null) {
          await MiscService().acknowledgeNotification(notificationId, 'opened');
        }
      });
    } catch (e) {
      log('❌ Error inicializando notificaciones: $e');
    }
  }

  Future<void> _createNotificationChannels() async {
    final AndroidNotificationChannel pedidosChannelWithSound = const AndroidNotificationChannel(
      'pedidos_v3',
      'Nuevos Pedidos',
      description: 'Notificaciones de nuevos pedidos con sonido personalizado',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('nuevo_pedido'),
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFF00FF00),
      playSound: true,
    );

    final AndroidNotificationChannel generalChannel = const AndroidNotificationChannel(
      'general_channel',
      'Notificaciones Generales',
      description: 'Notificaciones sobre el seguimiento de los pedidos',
      importance: Importance.max,
      enableVibration: true,
      enableLights: true,
      playSound: true,
    );

    final androidPlugin = _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(pedidosChannelWithSound);
    await androidPlugin?.createNotificationChannel(generalChannel);
  }

  Future<void> _showNotification(RemoteMessage message) async {
    String? soundFile = message.data['sound'];
    if (soundFile == 'nuevo_pedido') {
      await _showPedidoNotification(message);
    } else {
      await _showGeneralNotification(message);
    }
  }

  Future<void> _showPedidoNotification(RemoteMessage message) async {
    final vibrationPattern = Int64List.fromList([0, 200, 100, 200, 100, 200, 100, 400, 200, 400, 200, 400]);
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pedidos_v3',
      'Nuevos Pedidos',
      importance: Importance.max,
      priority: Priority.max,
      sound: const RawResourceAndroidNotificationSound('nuevo_pedido'),
      playSound: true,
      enableVibration: true,
      vibrationPattern: vibrationPattern,
      enableLights: true,
      ledColor: Colors.green,
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      _getValidTitle(message, '🛒 Nuevo Pedido'),
      _getValidBody(message, 'Tienes un nuevo pedido'),
      NotificationDetails(android: androidDetails),
    );
  }

  Future<void> _showGeneralNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'general_channel',
      'Notificaciones Generales',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      _getValidTitle(message, 'Nueva notificación'),
      _getValidBody(message, 'Tienes una nueva notificación'),
      const NotificationDetails(android: androidDetails),
    );
  }
}
