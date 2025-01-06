import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'badges.dart';
import 'home.dart';
import 'login.dart';
import 'app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Filmique',
      theme: AppTheme.theme,
      routes: {
        '/home': (context) => const MainPage(),
        '/login': (context) => const LoginPage(),
        '/badges': (context) => const BadgesPage(),
      },
      home: FirebaseAuth.instance.currentUser == null
          ? const LoginPage()
          : const MainPage(),
    );
  }
}
