import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vreme_app/profile.dart';
import 'badges.dart';
import 'home.dart';
import 'login.dart';
import 'app_theme.dart';
import 'no-internet.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load();

  // Check internet connection
  final hasInternet = await checkInternetConnection();

  runApp(MyApp(hasInternet: hasInternet));
}

// Function to check internet connection
Future<bool> checkInternetConnection() async {
  try {
    final result = await InternetAddress.lookup('google.com');
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (e) {
    return false;
  }
}

class MyApp extends StatelessWidget {
  final bool hasInternet;

  const MyApp({super.key, required this.hasInternet});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Filmique',
      theme: AppTheme.theme,
      routes: {
        '/home': (context) => const MainPage(),
        '/login': (context) => const LoginPage(),
        '/badges': (context) => const BadgesPage(),
        '/profile': (context) => const ProfilePage(),
        '/no-internet': (context) => const NoInternetPage(),
      },
      home: hasInternet
          ? FirebaseAuth.instance.currentUser == null
          ? const LoginPage()
          : const MainPage()
          : const NoInternetPage(),
    );
  }
}
