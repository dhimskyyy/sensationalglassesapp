import 'package:get/get.dart';
import '../../screens/splash_screen.dart';
import '../../screens/login_page.dart';
import '../../screens/register_page.dart';
import '../../screens/home_screen.dart';
import '../../screens/forgot_password_page.dart';
import '../../screens/code_verification.dart';
import '../../screens/email_verification.dart';
import '../../screens/home_screen.dart';
import '../../screens/maps.dart';
import '../../screens/main_navigation.dart';

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
    GetPage(
      name: Routes.EMAILVERIFICATIONPAGE,
      page: () => const EmailVerificationPage(),
    ),
    GetPage(
      name: Routes.MAIN,
      page: () => const MainNavigation(),
    ),
    GetPage(
      name: Routes.MAPS,
      page: () => const MapsScreen(),
    ),
  ];
}
