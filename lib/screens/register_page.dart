import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app/theme/app_colors.dart';
import '../app/theme/app_text_styles.dart';
import '../app/routes/app_pages.dart'; 

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Controller untuk input teks
  final TextEditingController firstName = TextEditingController();
  final TextEditingController lastName = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController birthDate = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController password = TextEditingController();
  
  bool hidePass = true;
  bool isLoading = false;
  String? completePhoneNumber;

  // ========================================================
  // 1. KONFIGURASI EMAILJS (ISI DENGAN DATA ANDA)
  // ========================================================
  // TODO: Ganti placeholder ini dengan kunci asli dari EmailJS Anda
  final String serviceId = 'service_v9e4i6c'; 
  final String templateId = 'template_nlmf1wn'; 
  final String publicKey = '4naTiGhbhMWZAnEYr'; 

  // --- FUNGSI: MEMBUAT KODE OTP 6 DIGIT ACAK ---
  String generateOTP() {
    var rng = Random();
    return (100000 + rng.nextInt(900000)).toString();
  }

  // --- FUNGSI: KIRIM EMAIL MENGGUNAKAN EMAILJS ---
  Future<bool> sendEmailOTP(String name, String emailTujuan, String otp) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    try {
      final response = await http.post(
        url,
        headers: {
          'origin': 'http://localhost',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'template_params': {
            'to_name': name,       // Sesuai variabel {{to_name}} di template EmailJS
            'to_email': emailTujuan, // Wajib: agar EmailJS tahu mau kirim kemana
            'otp_code': otp,       // Sesuai variabel {{otp_code}} di template EmailJS
          }
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Email OTP berhasil dikirim ke $emailTujuan");
        return true;
      } else {
        print("❌ Gagal kirim email: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Error koneksi: $e");
      return false;
    }
  }

  // --- DATE PICKER (PILIH TANGGAL) ---
  Future<void> pickDate() async {
    DateTime? result = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialDate: DateTime.now(),
    );
    if (result != null) {
      birthDate.text = DateFormat('dd/MM/yyyy').format(result);
    }
  }

  // --- VALIDASI EMAIL ---
  bool isValidEmail(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  // --- VALIDASI PASSWORD ---
  bool isValidPassword(String pass) {
    // Minimal 8 karakter, harus ada huruf besar, huruf kecil, dan angka/simbol
    final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*[\d\W]).+$');
    return regex.hasMatch(pass) && pass.length >= 8;
  }

  // --- FUNGSI UTAMA: MENDAFTAR USER ---
  Future<void> registerUser() async {
    setState(() => isLoading = true); // Mulai Loading (tombol disable)

    try {
      // 1. Buat kode OTP acak
      String otpCode = generateOTP();

      // 2. Kirim Email OTP (Tunggu sampai sukses sebelum lanjut buat akun)
      //    Catatan: Kita kirim email dulu untuk memastikan email valid/aktif
      bool emailSent = await sendEmailOTP(firstName.text, email.text.trim(), otpCode);

      if (!emailSent) {
        Get.snackbar(
          "Gagal", 
          "Gagal mengirim kode ke email. Periksa koneksi internet atau pastikan email benar.",
          backgroundColor: AppColors.error, 
          colorText: Colors.white
        );
        setState(() => isLoading = false);
        return; // Berhenti jika email gagal terkirim
      }

      // 3. Buat User di Firebase Authentication
      UserCredential userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.text.trim(),
            password: password.text.trim(),
          );

      String uid = userCred.user!.uid;

      // 4. Simpan Data User + OTP ke Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        "uid": uid,
        "firstName": firstName.text.trim(),
        "lastName": lastName.text.trim(),
        "email": email.text.trim(),
        "birthDate": birthDate.text.trim(),
        "phone": completePhoneNumber,
        "createdAt": DateTime.now(),
        "is_verified": false,
        "otp_code": otpCode,
      });

      // 5. Pindah ke Halaman Verifikasi
      // Kirim email sebagai argumen agar bisa ditampilkan di halaman berikutnya
      Get.toNamed(Routes.VERIFICATIONPAGE, arguments: email.text.trim());

      Get.snackbar(
        "Berhasil",
        "Kode OTP telah dikirim ke email Anda",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        "Error",
        e.message ?? "Terjadi kesalahan pada server",
        backgroundColor: Colors.red.withOpacity(0.85),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error", 
        e.toString(),
        backgroundColor: Colors.red.withOpacity(0.85),
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => isLoading = false); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // BACKGROUND MINT
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
                            const Image(
                              image: AssetImage('assets/logo.png'),
                              width: 20,
                              height: 20,
                              color: Color(0xFF1C2340),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "Sensational Glasses",
                              style: TextStyle(
                                color: Color(0xFF2A274B),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          "Daftar",
                          style: TextStyle(
                            color: Color(0xFF2A274B),
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text(
                              'Sudah Punya Akun?',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => Get.back(),
                              child: const Text(
                                "Masuk",
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.dark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // CONTAINER FORM PUTIH
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(30, 38, 30, 20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // BARIS NAMA
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Nama Depan",
                                    style: AppTextStyles.label,
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: firstName,
                                    decoration: _inputDecoration(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Nama Belakang",
                                    style: AppTextStyles.label,
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: lastName,
                                    decoration: _inputDecoration(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // EMAIL
                        const Text(
                          "Email",
                          style: AppTextStyles.label,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration(),
                        ),

                        const SizedBox(height: 18),

                        // TANGGAL LAHIR
                        const Text(
                          "Tanggal Lahir",
                          style: AppTextStyles.label,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: birthDate,
                          readOnly: true,
                          onTap: pickDate,
                          decoration: _inputDecoration().copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                Icons.calendar_month,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: pickDate,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // NOMOR TELEPON
                        const Text(
                          "Nomor Telepon",
                          style: AppTextStyles.label,
                        ),
                        const SizedBox(height: 8),

                        IntlPhoneField(
                          controller: phone,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1.4,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade400,
                                width: 1.6,
                              ),
                            ),
                          ),
                          initialCountryCode: 'ID',
                          onChanged: (p) =>
                              completePhoneNumber = p.completeNumber,
                          onCountryChanged: (c) => completePhoneNumber = null,
                        ),

                        const SizedBox(height: 18),

                        // PASSWORD
                        const Text(
                          "Password",
                          style: AppTextStyles.label,
                        ),
                        const SizedBox(height: 8),

                        TextFormField(
                          controller: password,
                          obscureText: hidePass,
                          decoration: _inputDecoration().copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                hidePass
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.dark,
                              ),
                              onPressed: () => setState(() {
                                hidePass = !hidePass;
                              }),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // TOMBOL DAFTAR
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF74C9B6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            // Disable tombol saat loading
                            onPressed: isLoading ? null : () {
                              // VALIDASI DATA
                              if (firstName.text.isEmpty ||
                                  lastName.text.isEmpty ||
                                  email.text.isEmpty ||
                                  birthDate.text.isEmpty ||
                                  password.text.isEmpty ||
                                  (completePhoneNumber?.isEmpty ?? true)) {
                                Get.snackbar(
                                  "Form Tidak Lengkap",
                                  "Harap isi semua data.",
                                  backgroundColor: AppColors.error,
                                  colorText: Colors.white,
                                );
                                return;
                              }

                              if (!isValidEmail(email.text)) {
                                Get.snackbar(
                                  "Email Tidak Valid",
                                  "Masukkan email yang benar.",
                                  backgroundColor: AppColors.error,
                                  colorText: Colors.white,
                                );
                                return;
                              }

                              if (!isValidPassword(password.text)) {
                                Get.snackbar(
                                  "Password Lemah",
                                  "Minimal 8 Karakter, kombinasi huruf besar, kecil, angka/simbol.",
                                  backgroundColor: AppColors.error,
                                  colorText: Colors.white,
                                );
                                return;
                              }

                              // JALANKAN PROSES REGISTER
                              registerUser(); 
                            },
                            child: isLoading 
                              ? const SizedBox(
                                  height: 20, width: 20, 
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                )
                              : const Text(
                                  "Daftar",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                  ),
                                ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        Center(
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              text: 'Dengan mendaftar, Anda menyetujui ',
                              style: TextStyle(color: AppColors.dark, fontSize: 13),
                              children: [
                                TextSpan(
                                  text: 'Persyaratan\n',
                                  style: TextStyle(
                                    color: AppColors.mint,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Layanan dan ',
                                  style: TextStyle(color: AppColors.dark),
                                ),
                                TextSpan(
                                  text: 'Perjanjian Pemrosesan Data',
                                  style: TextStyle(
                                    color: AppColors.mint,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // DEKORASI INPUT
  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
    );
  }
}