import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:truelovesocio/model/socio_model.dart';
import 'package:truelovesocio/screen/home_screen.dart';
import 'package:truelovesocio/screen/screens.dart';
import 'package:truelovesocio/service/api_service.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:truelovesocio/service/firebase_api.dart';
import 'package:truelovesocio/theme/app_theme.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 1. ValueNotifier global para el ThemeMode
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // IMPORTANTE: registrar el background handler ANTES de initializeApp
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
  // try-catch es más robusto que Firebase.apps.isEmpty para evitar duplicate-app
  try {
    await Firebase.initializeApp(
      name: 'app dev',
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
    // Si ya existe, Firebase está listo — no es un error real
  }

  await FirebaseApi().initNotifications();


  // 2. Cargar preferencia del tema antes de runApp
  final prefs = await SharedPreferences.getInstance();
  String? themePref = prefs.getString('themeMode');
  if (themePref == 'light') {
    themeNotifier.value = ThemeMode.light;
  } else if (themePref == 'dark') {
    themeNotifier.value = ThemeMode.dark;
  } else {
    themeNotifier.value = ThemeMode.system;
  }

  Socio? user = await ApiService.getLoggedUser();
  bool loggedIn = user != null;
  runApp(MyApp(isLoggedIn: loggedIn));
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void dispose() {
    ScreenProtector.preventScreenshotOff();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 3. Usa ValueListenableBuilder para escuchar cambios de themeMode
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Delivery True Love',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/login':
                (context) => widget.isLoggedIn ? HomeScreen() : LoginScreen(),
          },
        );
      },
    );
  }
}

// 4. Función para cambiar y persistir el theme
Future<void> setThemeMode(ThemeMode mode) async {
  final prefs = await SharedPreferences.getInstance();
  themeNotifier.value = mode;
  if (mode == ThemeMode.light) {
    await prefs.setString('themeMode', 'light');
  } else if (mode == ThemeMode.dark) {
    await prefs.setString('themeMode', 'dark');
  } else {
    await prefs.setString('themeMode', 'system');
  }
}
