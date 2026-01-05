import 'package:flutter/material.dart';
import 'screens/setup_screen.dart';

/// アプリケーションのルートウィジェット
class MyImageSSApp extends StatelessWidget {
  const MyImageSSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Screenshot Tool',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SetupScreen(),
    );
  }
}
