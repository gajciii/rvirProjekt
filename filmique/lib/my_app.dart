// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'login_page.dart';
// import 'main_page.dart';
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Filmique',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
//         useMaterial3: true,
//       ),
//       home: FirebaseAuth.instance.currentUser == null
//           ? const LoginPage()
//           : const MainPage(),
//     );
//   }
// }
//
