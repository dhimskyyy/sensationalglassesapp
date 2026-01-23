import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Dibutuhkan untuk InputFormatter
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../app/theme/app_colors.dart';
import '../app/theme/app_text_styles.dart';
import '../app/routes/app_pages.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  // Membuat 6 controller untuk 6 kotak input
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // Menggabungkan 6 digit menjadi satu string
  String get _otpCode => _controllers.map((e) => e.text).join();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Mint
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
                        'Verification',
                        style: TextStyle(
                          color: AppColors.dark,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          height: 1.02,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Subtitle
                      const Text(
                        'Masukkan 6 digit kode yang telah dikirimkan ke email anda',
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
                          'Kode',
                          style: AppTextStyles.label,
                        ),
                        const SizedBox(height: 6),
                        
                        // 6 KOTAK OTP
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) {
                            return SizedBox(
                              width: 45,
                              height: 50,
                              child: TextFormField(
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
                                onChanged: (value) {
                                  // Logika pindah fokus otomatis
                                  if (value.isNotEmpty && index < 5) {
                                    _focusNodes[index + 1].requestFocus();
                                  } else if (value.isEmpty && index > 0) {
                                    _focusNodes[index - 1].requestFocus();
                                  }
                                },
                                style: const TextStyle(
                                  fontSize: 20, 
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.dark
                                ),
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(1),
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.zero,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppColors.mint),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // KIRIM ULANG OTP (Clickable)
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {
                              // Aksi ketika Kirim Ulang diklik
                              Get.snackbar(
                                "OTP Terkirim", 
                                "Kode OTP baru telah dikirim ke email Anda.",
                                backgroundColor: Colors.green,
                                colorText: Colors.white
                              );
                              // Anda bisa memanggil fungsi resend di controller di sini
                            },
                            child: RichText(
                              text: const TextSpan(
                                text: 'Tidak menerima OTP? ',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                                children: [
                                  TextSpan(
                                    text: 'Kirim Ulang OTP',
                                    style: TextStyle(
                                      color: AppColors.mint,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Spacer(),
                        
                        // TOMBOL VERIFICATION
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    // Validasi panjang kode
                                    if (_otpCode.length < 6) {
                                      Get.snackbar(
                                        "Error",
                                        "Harap masukkan 6 digit kode",
                                        backgroundColor: AppColors.error,
                                        colorText: Colors.white,
                                      );
                                      return;
                                    }

                                    setState(() => _isLoading = true);
                                    
                                    try {
                                      // Panggil fungsi verify di Controller
                                      // Controller yang akan handle navigasi ke HOME jika sukses
                                      await Get.find<AuthController>().verifyOtp(_otpCode);
                                      
                                      // Jika sukses, tidak perlu set isLoading false karena pindah halaman
                                    } catch (e) {
                                      // Jika gagal, tampilkan error dan matikan loading
                                      Get.snackbar(
                                        "Gagal", 
                                        e.toString().replaceAll("Exception: ", ""),
                                        backgroundColor: AppColors.error,
                                        colorText: Colors.white
                                      );
                                      setState(() => _isLoading = false);
                                    }
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
                                    'Verification',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),

                        // SizedBox(
                        //   height: 48,
                        //   child: ElevatedButton(
                        //     onPressed: _isLoading
                        //         ? null
                        //         : () async {
                        //             // Validasi panjang kode
                        //             if (_otpCode.length < 6) {
                        //               Get.snackbar(
                        //                 "Error",
                        //                 "Harap masukkan 6 digit kode",
                        //                 backgroundColor: AppColors.error,
                        //                 colorText: Colors.white,
                        //               );
                        //               return;
                        //             }

                        //             setState(() => _isLoading = true);
                                    
                        //             // Panggil fungsi verify di Controller
                        //             await Get.find<AuthController>().verifyOtp(_otpCode);
                                    
                        //             // Simulasi Loading sebentar agar UX lebih terasa
                        //             // await Future.delayed(const Duration(seconds: 1));

                        //             setState(() => _isLoading = false);

                        //             // ARAHKAN KE HOME (Sesuai Permintaan)
                        //             Get.offAllNamed(Routes.HOME);
                        //           },
                        //     style: ElevatedButton.styleFrom(
                        //       backgroundColor: AppColors.mint,
                        //       shape: RoundedRectangleBorder(
                        //         borderRadius: BorderRadius.circular(16),
                        //       ),
                        //       elevation: 0,
                        //     ),
                        //     child: _isLoading
                        //         ? const SizedBox(
                        //             height: 20,
                        //             width: 20,
                        //             child: CircularProgressIndicator(
                        //               color: Colors.white,
                        //               strokeWidth: 2,
                        //             ),
                        //           )
                        //         : const Text(
                        //             'Verification',
                        //             style: TextStyle(
                        //               fontSize: 16,
                        //               color: Colors.white,
                        //               fontWeight: FontWeight.w700,
                        //             ),
                        //           ),
                        //   ),
                        // ),
                        const SizedBox(height: 16),
                        
                        // KEMBALI KE LOGIN
                        Center(
                          child: GestureDetector(
                            onTap: () => Get.offAllNamed(Routes.LOGIN),
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
}