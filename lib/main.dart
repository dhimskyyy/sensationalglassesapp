import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:sensationalglassesapp/app/theme/app_colors.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

import 'controllers/auth_controller.dart';
import 'app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final GoogleMapsFlutterPlatform mapsImplementation = GoogleMapsFlutterPlatform.instance;
  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    mapsImplementation.useAndroidViewSurface = true; 
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp();

  Get.put(AuthController(), permanent: true);

  // Use authStateChanges().first to reliably wait for Firebase to restore
  // the persisted session. The synchronous currentUser can sometimes be null
  // on cold start before the session is fully restored.
  User? currentUser = await FirebaseAuth.instance.authStateChanges().first;
  String firstRoute = AppPages.INITIAL; // Secara default ke Login

  if (currentUser != null) {
    bool isSocialLogin = currentUser.providerData.any((p) => p.providerId != 'password');
    if (currentUser.emailVerified || isSocialLogin) {
      firstRoute = Routes.MAIN; // Ubah rute awal langsung ke Home!
    } else {
      firstRoute = Routes.EMAILVERIFICATIONPAGE;
    }
  }

  // Masukkan rute yang sudah dicek ke dalam MyApp
  runApp(MyApp(initialRoute: firstRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute; // Tambahkan ini

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute, // <-- Gunakan variabel ini, BUKAN AppPages.INITIAL
      getPages: AppPages.pages,
      smartManagement: SmartManagement.full,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.white,
      ),
    );
  }
}