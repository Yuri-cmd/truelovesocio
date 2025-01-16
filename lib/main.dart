import 'package:flutter/material.dart';
import 'package:truelovesocio/screen/home_screen.dart';
import 'package:truelovesocio/screen/screens.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Delivery True Love',
      // theme: ThemeData(
      //   primarySwatch: Colors.red,
      // ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        // '/login': (context) =>
        //     const LoginScreen(),
      },
    );
  }
}
