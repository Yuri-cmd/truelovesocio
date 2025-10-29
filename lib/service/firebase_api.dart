import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truelovesocio/service/api_service.dart';

class FirebaseApi {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    // Solicitar permisos
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("Permisos de notificación concedidos");
    }

    // Obtener el token de FCM
    String? token = await _firebaseMessaging.getToken();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token_fcm', token!);
    final idUser = await ApiService.getUsuarioId();
    if (idUser != null) {
      ApiService.updateFcmToken(idUser, token);
    }
  
    // Configurar flutter_local_notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _flutterLocalNotificationsPlugin.initialize(initSettings);

    // Crear canales de notificación
    await _createNotificationChannels();

    // Manejar notificaciones en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    // Manejar notificaciones cuando la app está en segundo plano pero abierta
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notificación abierta: ${message.notification?.title}');
    });
  }

  Future<void> _createNotificationChannels() async {
    try {
      // Canal para pedidos con sonido personalizado
      const AndroidNotificationChannel pedidosChannelWithSound = AndroidNotificationChannel(
        'pedidos_channel',
        'Nuevos Pedidos',
        description: 'Notificaciones de nuevos pedidos con sonido personalizado',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('nuevo_pedido'),
      );

      // Canal para notificaciones generales sin sonido personalizado
      const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
        'general_channel',
        'Notificaciones Generales',
        description: 'Notificaciones generales del sistema',
        importance: Importance.high,
      );

      // Canal básico de respaldo
      const AndroidNotificationChannel basicChannel = AndroidNotificationChannel(
        'basic_channel',
        'Notificaciones Básicas',
        description: 'Canal básico de notificaciones',
        importance: Importance.high,
      );

      // Intentar crear el canal con sonido personalizado
      try {
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(pedidosChannelWithSound);
        print('Canal de pedidos con sonido personalizado creado exitosamente');
      } catch (e) {
        print('Error creando canal con sonido personalizado: $e');
      }

      // Crear canales de respaldo
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(generalChannel);

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(basicChannel);
      
      print('Todos los canales de notificación creados');
    } catch (e) {
      print('Error general creando canales: $e');
    }
  }

  Future<void> _showNotification(RemoteMessage message) async {
    try {
      // Obtener el sonido del data payload
      String? soundFile = message.data['sound'];
      print('Archivo de sonido recibido: $soundFile');
      
      // Determinar qué tipo de notificación mostrar
      if (soundFile != null && soundFile == 'nuevo_pedido') {
        await _showPedidoNotification(message);
      } else {
        await _showGeneralNotification(message);
      }
    } catch (e) {
      print('Error general mostrando notificación: $e');
      await _showFallbackNotification(message);
    }
  }

  // Notificación para nuevos pedidos con sonido personalizado
  Future<void> _showPedidoNotification(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'pedidos_channel',
        'Nuevos Pedidos',
        channelDescription: 'Notificaciones de nuevos pedidos con sonido personalizado',
        importance: Importance.high,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('nuevo_pedido'),
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Colors.red,
        ledOnMs: 1000,
        ledOffMs: 500,
      );

      const NotificationDetails details = NotificationDetails(android: androidDetails);

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        message.notification?.title ?? "🛒 Nuevo Pedido",
        message.notification?.body ?? "Tienes un nuevo pedido",
        details,
      );
      
      print('Notificación de pedido con sonido personalizado mostrada');
    } catch (e) {
      print('Error con notificación de pedido personalizada: $e');
      // Fallback a notificación de pedido sin sonido personalizado
      await _showPedidoNotificationFallback(message);
    }
  }

  // Notificación de pedido sin sonido personalizado (fallback)
  Future<void> _showPedidoNotificationFallback(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'general_channel',
        'Notificaciones Generales',
        channelDescription: 'Notificaciones de pedidos sin sonido personalizado',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Colors.orange,
        ledOnMs: 1000,
        ledOffMs: 500,
      );

      const NotificationDetails details = NotificationDetails(android: androidDetails);

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        message.notification?.title ?? "🛒 Nuevo Pedido",
        message.notification?.body ?? "Tienes un nuevo pedido",
        details,
      );
      
      print('Notificación de pedido con sonido del sistema mostrada');
    } catch (e) {
      print('Error con notificación de pedido fallback: $e');
    }
  }

  // Notificación general sin sonido personalizado
  Future<void> _showGeneralNotification(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'general_channel',
        'Notificaciones Generales',
        channelDescription: 'Notificaciones generales del sistema',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      );

      const NotificationDetails details = NotificationDetails(android: androidDetails);

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        message.notification?.title ?? "Nueva notificación",
        message.notification?.body ?? "Tienes una nueva notificación",
        details,
      );
      
      print('Notificación general mostrada');
    } catch (e) {
      print('Error mostrando notificación general: $e');
    }
  }

  // Notificación de respaldo básica
  Future<void> _showFallbackNotification(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'basic_channel',
        'Notificaciones Básicas',
        channelDescription: 'Canal básico de notificaciones',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      );

      const NotificationDetails details = NotificationDetails(android: androidDetails);

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        message.notification?.title ?? "Nueva notificación",
        message.notification?.body ?? "Tienes una nueva notificación",
        details,
      );
      
      print('Notificación básica de respaldo mostrada');
    } catch (e) {
      print('Error mostrando notificación de respaldo: $e');
    }
  }
}