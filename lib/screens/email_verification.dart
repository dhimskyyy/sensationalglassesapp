import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../app/theme/app_colors.dart';
import '../app/theme/app_text_styles.dart';
import '../app/routes/app_pages.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _isLoading = false;
  // Mengambil argumen email yang dikirim dari halaman register
  final String emailUser = Get.arguments ?? "Email Anda";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Mint (Sama dengan desain lama)
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
                      // Logo & Brand Name
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
                      // Judul Verification
                      const Text(
                        'Verify Email',
                        style: TextStyle(
                          color: AppColors.dark,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          height: 1.02,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Subtitle yang disesuaikan
                      Text(
                        'Kami telah mengirimkan link verifikasi ke:\n$emailUser',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(30, 40, 30, 16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.mark_email_read_outlined,
                          size: 100,
                          color: AppColors.mint,
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'Belum menerima link?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                          
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Silakan periksa folder Spam atau klik tombol kirim ulang di bawah ini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        
                        // TOMBOL KIRIM ULANG (GestureDetector agar mirip style kamu)
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              // Panggil fungsi kirim ulang verifikasi di controller
                              Get.find<AuthController>().resendVerificationEmail();
                            },
                            child: const Text(
                              'Kirim Ulang Link',
                              style: TextStyle(
                                color: AppColors.mint,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                                                
                        const Spacer(),
                        
                        // TOMBOL UTAMA: CEK STATUS
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    setState(() => _isLoading = true);
                                    // Fungsi reloadUserAndCheckVerification sudah kita bahas di AuthController
                                    await Get.find<AuthController>().reloadUserAndCheckVerification();
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
                                    'Saya Sudah Verifikasi',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        
                        // KEMBALI KE LOGIN
                        Center(
                          child: GestureDetector(
                            onTap: () => Get.offAllNamed(Routes.LOGIN),
                            child: const Text(
                              'Batal',
                              style: TextStyle(
                                color: Colors.grey,
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
}