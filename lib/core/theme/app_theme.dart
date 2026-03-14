import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color.fromRGBO(255, 36, 36, 1);
  static const Color btnColor = Color.fromRGBO(122, 161, 140, 1);
  static const Color title = Color.fromARGB(255, 0, 148, 94);
  static const Color bgContacto = Color.fromRGBO(0, 148, 94, 1);
  static const Color bg = Colors.white;

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      surface: bg,
    ),
    scaffoldBackgroundColor: bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
    ),
    primaryColor: primary,
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    ).copyWith(
      surface: Colors.black,
    ),
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      elevation: 0,
    ),
    primaryColor: primary,
  );
}
