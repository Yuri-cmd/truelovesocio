import 'dart:io';
import 'package:flutter/material.dart';
import 'package:truelovesocio/model/socio_model.dart';
import 'package:truelovesocio/screen/home_screen.dart';
import 'package:truelovesocio/screen/screens.dart';
import 'package:truelovesocio/service/api_service.dart';
import 'package:screen_protector/screen_protector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔐 Previene capturas de pantalla al iniciar
  await ScreenProtector.preventScreenshotOn();

  if (Platform.isIOS) {
    await ScreenProtector.protectDataLeakageWithBlur();
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
    // Opcional: desactiva la protección si quieres limpiar al salir
    ScreenProtector.preventScreenshotOff();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Delivery True Love',
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => widget.isLoggedIn ? HomeScreen() : LoginScreen(),
      },
    );
  }
}
