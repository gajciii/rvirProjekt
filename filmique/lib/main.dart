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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load();

  // Preveri internetno povezavo
  final hasInternet = await checkInternetConnection();

  runApp(MyApp(hasInternet: hasInternet));
}

// Funkcija za preverjanje internetne povezave
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
        '/no-internet': (context) => const NoInternetPage(), // Nova pot
      },
      home: hasInternet
          ? (FirebaseAuth.instance.currentUser == null
          ? const LoginPage()
          : const MainPage())
          : const NoInternetPage(),
    );
  }
}

// Stran za stanje brez internetne povezave
class NoInternetPage extends StatelessWidget {
  const NoInternetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Napaka'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            const Text(
              'Ni internetne povezave.',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Za delovanje aplikacije potrebujete internet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                final hasInternet = await checkInternetConnection();
                if (hasInternet) {
                  Navigator.pushReplacementNamed(context, '/home');
                }
              },
              child: const Text('Poskusi znova'),
            ),
          ],
        ),
      ),
    );
  }
}
