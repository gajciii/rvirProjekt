import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vreme_app/sign-up.dart';
import 'home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> signIn() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
      );
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Nobenega uporabnika s tem emailom ni mogoče najti.';
          break;
        case 'invalid-email':
          message = 'Vnesen email je napačen.';
          break;
        case 'wrong-password':
          message = 'Napačno geslo za uporabnika.';
          break;
        default:
          message = 'Napačni vneseni podatki, poskusite ponovno.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message, style: Theme.of(context).textTheme.bodyMedium)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Napaka pri prijavi.', style: Theme.of(context).textTheme.bodyMedium)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: TopCurveClipper(),
              child: Container(
                height: 300,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('lib/images/grafika.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Prijava",
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    filled: true,
                    fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: "Geslo",
                    filled: true,
                    fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  obscureText: true,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: signIn,
                  child: const Text("Prijava"),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignUpPage()),
                    );
                  },
                  child: Text(
                    "Še nimate računa? Registrirajte se",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class TopCurveClipper extends CustomClipper<Path> { //slika in obroba
  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.moveTo(0, 50);
    path.quadraticBezierTo(
      size.width / 2, 0,
      size.width, 50,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
