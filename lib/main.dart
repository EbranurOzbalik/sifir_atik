import 'package:flutter/material.dart';

import 'screens/login_page.dart';

void main() {
  runApp(const SifirAtikApp());
}

class SifirAtikApp extends StatelessWidget {
  const SifirAtikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sıfır Atık',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7FAF7),
      ),
      home: const LoginPage(),
    );
  }
}

typedef MyApp = SifirAtikApp;
