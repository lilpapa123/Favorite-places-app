import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final colorScheme = ColorScheme.fromSeed(
  brightness: Brightness.dark,
  seedColor: const Color.fromARGB(255, 102, 6, 247),
  surface: const Color.fromARGB(255, 56, 49, 66),
);

final base = ThemeData.dark(useMaterial3: true);

final fontFamily = GoogleFonts.ubuntuCondensed().fontFamily;
final textTheme = base.textTheme.apply(fontFamily: fontFamily);

final theme = base.copyWith(
  colorScheme: colorScheme,
  scaffoldBackgroundColor: colorScheme.surface,
  textTheme: textTheme.copyWith(
    titleSmall: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
    titleMedium: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
  ),
);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Great Places',
      theme: theme,
      home: const Scaffold(body: Center(child: Text('Hello'))),
    );
  }
}
