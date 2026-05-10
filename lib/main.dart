import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quanta/features/tuner/data/audio_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AudioService.instance.init();
  runApp(const ProviderScope(child: QuantaApp()));
}
