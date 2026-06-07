import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../app/routes/app_pages.dart';
import '../app/theme/app_colors.dart';
import '../app/theme/app_text_styles.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isPasswordHidden = true;

  final AuthController authC = Get.find<AuthController>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Container(height: 500, color: AppColors.mint),
            SafeArea(
  child: SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                  // HEADER
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'assets/logo.png',
                              width: 22,
                              height: 22,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Sensational Glasses',
                              style: TextStyle(
                                color: AppColors.dark,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Masuk ke Akun\nAnda',
                          style: TextStyle(
                            color: AppColors.dark,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            height: 1.02,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text(
                              'Belum Punya Akun?',
                              style: AppTextStyles.subtitle,
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              authC.clearFields();
                              Get.offNamed(Routes.REGISTER);
                            },
                            child: const Text(
                              'Daftar',
                              style: TextStyle(
                                color: AppColors.dark,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // WHITE FORM
                  Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(30, 24, 30, 16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // EMAIL
                          const Text('Email', style: AppTextStyles.label),

                          const SizedBox(height: 6),
                          TextFormField(
                            controller: authC.emailController,
                            decoration: _inputDecoration(),
                          ),
                          const SizedBox(height: 12),

                          // PASSWORD
                          const Text('Password', style: AppTextStyles.label),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: authC.passwordController,
                            obscureText: _isPasswordHidden,
                            decoration: _inputDecoration().copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordHidden
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.textPrimary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordHidden = !_isPasswordHidden;
                                  });
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                Get.toNamed(Routes.FORGOT_PASSWORD);
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Lupa Password ?',
                                style: AppTextStyles.label,
                              ),
                            ),
                          ),
                          const SizedBox(height: 80),
                          // LOGIN BUTTON
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                final email = authC.emailController.text.trim();
                                final password = authC.passwordController.text.trim();

                                if (email.isEmpty && password.isEmpty) {
                                  Get.snackbar(
                                    "Error",
                                    "Email dan password wajib diisi",
                                    backgroundColor: AppColors.error,
                                    colorText: AppColors.white,
                                  );
                                  return;
                                }

                                if (email.isEmpty) {
                                  Get.snackbar(
                                    "Error",
                                    "Harap masukkan email",
                                    backgroundColor: AppColors.error,
                                    colorText: AppColors.white,
                                  );
                                  return;
                                }

                                if (password.isEmpty) {
                                  Get.snackbar(
                                    "Error",
                                    "Harap masukkan password",
                                    backgroundColor: AppColors.error,
                                    colorText: AppColors.white,
                                  );
                                  return;
                                }

                                Get.find<AuthController>()
                                    .signInWithEmailAndPassword(
                                      email,
                                      password,
                                    );
                              },

                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.mint,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Masuk',
                                style: AppTextStyles.button,
                              ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          // DIVIDER
                          Row(
                            children: const [
                              Expanded(
                                child: Divider(
                                  thickness: 1,
                                  color: AppColors.divider,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Atau masuk dengan',
                                style: AppTextStyles.label,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Divider(
                                  thickness: 1,
                                  color: AppColors.divider,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 22),

                          // SOCIAL LOGIN
                          OutlinedButton(
                            onPressed: () => Get.find<AuthController>()
                                .signInWithGoogle(),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  "assets/google.png",
                                  width: 20,
                                  height: 20,
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Google',
                                  style: AppTextStyles.label,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                ],
              ),
  ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }
}
