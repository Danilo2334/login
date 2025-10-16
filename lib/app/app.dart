import 'package:flutter/material.dart';

import 'auth/auth_gate.dart';
import 'home/home_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6C63FF),
      brightness: Brightness.dark,
    );

    final outlineBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
    );

    return MaterialApp(
      title: 'Login',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: ThemeData(brightness: Brightness.dark).textTheme,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.08),
          border: outlineBorder,
          enabledBorder: outlineBorder,
          focusedBorder: outlineBorder.copyWith(
            borderSide: BorderSide(color: colorScheme.secondary, width: 1.6),
          ),
          labelStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
          ),
          prefixIconColor: Colors.white70,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: colorScheme.surface.withValues(alpha: 0.85),
          contentTextStyle: TextStyle(color: colorScheme.onSurface),
        ),
      ),
      home: const AuthGate(child: HomePage()),
    );
  }
}
