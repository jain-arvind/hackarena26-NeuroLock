import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'ui/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase init can fail until platform config is added.
  }

  runApp(const NeuroLockApp());
}

class NeuroLockApp extends StatelessWidget {
  const NeuroLockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeuroLock BLE',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
