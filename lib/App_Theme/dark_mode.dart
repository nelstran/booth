import 'package:flutter/material.dart';

ThemeData darkMode = ThemeData(
  // OLD THEME
  // brightness: Brightness.dark,
  // colorScheme: ColorScheme.dark(
  //   background: Colors.grey.shade900,
  //   surface: Colors.grey.shade900,
  //   primary: Colors.grey.shade800,
  //   secondary: Colors.grey.shade800,
  //   inversePrimary: Colors.grey.shade500,
  // ),
  // textTheme: ThemeData.light().textTheme.apply(
  //       bodyColor: Colors.grey[300],
  //       displayColor: Colors.white,
  // ),
  // NEW THEME
  colorScheme: ColorScheme.fromSeed(
    // seedColor: const Color.fromARGB(255, 24, 135, 209),
    seedColor: const Color.fromARGB(255, 0, 162, 255),
    brightness: Brightness.dark,
    dynamicSchemeVariant: DynamicSchemeVariant.monochrome // Most closely how app was before in Material2
    // dynamicSchemeVariant: DynamicSchemeVariant.content,
    // surfaceContainerLow: // LIST TILES
    // surface: // BACKGROUND
  )
);


// FOR REFERENCE -- Nelson
// colorScheme: ColorScheme.fromSeed(
//   seedColor: const Color(0xffbb86fc),
//   brightness: Brightness.dark,
// ).copyWith(
//   primaryContainer: const Color(0xffbb86fc),
//   onPrimaryContainer: Colors.black,
//   secondaryContainer: const Color(0xff03dac6),
//   onSecondaryContainer: Colors.black,
//   error: const Color(0xffcf6679),
//   onError: Colors.black,
// ),