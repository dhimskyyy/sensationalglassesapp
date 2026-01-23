import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../app/theme/app_colors.dart';
import '../app/theme/app_text_styles.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(height: 500, color: AppColors.mint),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset('assets/logo.png', width: 22, height: 22),
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
                      const SizedBox(height: 28),
                      const Text(
                        'Lupa Password?',
                        style: TextStyle(
                          color: AppColors.dark,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          height: 1.02,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Masukkan email Anda untuk menerima link reset password',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
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
                        const Text(
                          'Email',
                          style: AppTextStyles.label,
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration(),
                        ),
                        const SizedBox(height: 24),
                        const Spacer(),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    if (emailController.text.isEmpty) {
                                      Get.snackbar(
                                        "Error",
                                        "Masukkan email Anda",
                                        backgroundColor: AppColors.error,
                                        colorText: Colors.white,
                                      );
                                      return;
                                    }
                                    setState(() => _isLoading = true);
                                    await Get.find<AuthController>()
                                        .sendPasswordResetEmail(
                                      emailController.text.trim(),
                                    );
                                    setState(() => _isLoading = false);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.mint,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Kirim Link Reset',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: GestureDetector(
                            onTap: () => Get.back(),
                            child: const Text(
                              'Kembali ke Login',
                              style: TextStyle(
                                color: AppColors.mint,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}