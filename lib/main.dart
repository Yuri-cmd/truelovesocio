import 'package:flutter/material.dart';
import 'package:truelovesocio/model/socio_model.dart';
import 'package:truelovesocio/screen/home_screen.dart';
import 'package:truelovesocio/screen/screens.dart';
import 'package:truelovesocio/service/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Socio? user = await ApiService.getLoggedUser();
  bool loggedIn = user != null;
  runApp(MyApp(isLoggedIn: loggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Delivery True Love',
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => isLoggedIn ? HomeScreen() : LoginScreen(),
      },
    );
  }
}
