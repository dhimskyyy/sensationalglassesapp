import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../routes/app_pages.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
void initState() {
  super.initState();

  Future.delayed(const Duration(seconds: 2), () {
    if (mounted) {
      Get.offAllNamed(Routes.LOGIN);
    }
  });
}
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF70CAB0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              width: 180,
            ),
            const SizedBox(height: 26),
            const Text(
              "SENSATIONAL",
              style: TextStyle(
                fontSize: 20,
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Text(
              "GLASSES",
              style: TextStyle(
                fontSize: 14,
                letterSpacing: 4,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
