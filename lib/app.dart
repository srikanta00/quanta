import 'package:flutter/material.dart';
import 'package:quanta/core/theme/app_theme.dart';
import 'package:quanta/features/tuner/presentation/screens/tuner_screen.dart';

class QuantaApp extends StatelessWidget {
  const QuantaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quanta',
      theme: AppTheme.dark(),
      debugShowCheckedModeBanner: false,
      home: const TunerScreen(),
    );
  }
}
