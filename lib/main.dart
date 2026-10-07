import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:medora/firebase_options.dart';
import 'package:medora/presentation/dashboard_screen.dart';
import 'package:medora/presentation/onboaeding.dart';
import 'package:medora/presentation/splash_screen.dart';

import 'app_theme.dart';

import 'presentation/home_shell.dart';
import 'presentation/login_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.init();
  runApp(const PharmacyInventoryApp());
}

class PharmacyInventoryApp extends StatelessWidget {
  const PharmacyInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pharmacy Inventory',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const OnboardingPage(),
    );
  }
}

/// Sends signed-in users straight to the inventory and everyone else to
/// sign-in, so inventory data is never rendered without an account.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.instance.authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        return snapshot.data == null ? const LoginScreen(): const HomeShell();
      },
    );
  }
}


// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();           // must finish before runApp
//   final prefs = await SharedPreferences.getInstance();
//   final seen = prefs.getBool('seenOnboarding') ?? false;
//   runApp(MyApp(seenOnboarding: seen));
// }
//
// class MyApp extends StatelessWidget {
//   final bool seenOnboarding;
//   const MyApp({super.key, required this.seenOnboarding});
//
//   @override
//   Widget build(BuildContext context) => MaterialApp(
//     home: StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(),
//       builder: (context, snap) {
//         if (snap.connectionState == ConnectionState.waiting) {
//           return const Scaffold(body: Center(child: CircularProgressIndicator()));
//         }
//         if (snap.hasData) return const DashboardPage();
//         return seenOnboarding ? const LoginPage() : const OnboardingPage();
//       },
//     ),
//   );
// }
//
// final prefs = await SharedPreferences.getInstance();
// await prefs.setBool('seenOnboarding', true);
// if (!mounted) return;
// Navigator.of(context).pushReplacement(
// MaterialPageRoute(builder: (_) => const LoginPage()),
// );