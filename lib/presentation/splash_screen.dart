import 'package:flutter/material.dart';
import 'package:medora/app_theme.dart';
import 'package:medora/main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  // @override
  // void initState() {
  //   // TODO: implement initState
  //   Future.delayed(const Duration(milliseconds: 500), ()=> AuthGate());
  //   super.initState();
  // }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Color(0xFF032109),
        child: Column(
          children: [
            Text('Medi Vault'),
            CircularProgressIndicator(color: AppColors.primaryLight,)
          ],
        ),
      ),
    );
  }
}
