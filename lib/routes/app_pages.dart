import 'package:get/get.dart';
import '../screens/splash_screen.dart';
import '../screens/login_page.dart';
import '../screens/register_page.dart';
import '../screens/home_screen.dart';

part 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(name: Routes.SPLASH, page: () => const SplashScreen()),
    GetPage(name: Routes.LOGIN, page: () => const LoginPage()),
    GetPage(name: Routes.REGISTER, page: () => const RegisterPage()),
    GetPage(name: Routes.HOME, page: () => const HomeScreen()),
  ];
}
