import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:medora/firebase_options.dart';

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
      home: const AuthGate(),
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
          return const Scaffold(
            backgroundColor: AppColors.deepGreen,
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }
        return snapshot.data == null ? const LoginScreen() : const HomeShell();
      },
    );
  }
}
