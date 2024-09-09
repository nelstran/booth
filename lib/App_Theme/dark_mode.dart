import 'package:flutter/material.dart';

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    // surface: Colors.grey.shade900,
    background: Colors.grey.shade900,
    primary: Colors.grey.shade800,
    secondary: Colors.grey.shade700,
    inversePrimary: Colors.grey.shade500,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor:  Color.fromARGB(255, 0,51,102)
  ),
  elevatedButtonTheme: const ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(Color(0xFF0a335c)),
      foregroundColor: WidgetStatePropertyAll(Colors.white)
    )
  ),
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: Color.fromARGB(255, 0,51,102),
    indicatorColor: Color.fromARGB(255, 18, 88, 158),
  ),
  textTheme: ThemeData.light().textTheme.apply(
        bodyColor: Colors.grey[300],
        displayColor: Colors.white,

  ),

);
