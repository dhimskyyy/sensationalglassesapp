import 'package:get/get.dart';
import '../../screens/splash_screen.dart';
import '../../screens/login_page.dart';
import '../../screens/register_page.dart';
import '../../screens/home_screen.dart';
import '../../screens/forgot_password_page.dart';
import '../../screens/code_verification.dart';

part 'app_routes.dart';

class AppPages {
  static const INITIAL = Routes.SPLASH;

  static final pages = [
    GetPage(
      name: Routes.SPLASH,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginPage(),
    ),
    GetPage(
      name: Routes.REGISTER,
      page: () => const RegisterPage(),
    ),
    GetPage(
      name: Routes.HOME,
      page: () => const HomeScreen(),
    ),
    GetPage(
  name: Routes.FORGOT_PASSWORD,
  page: () => const ForgotPasswordPage(),
),
    GetPage(
  name: Routes.VERIFICATIONPAGE,
  page: () => const VerificationPage(),
),
  ];
}
