import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app/theme/app_colors.dart';
import '../app/theme/app_text_styles.dart';
import '../app/routes/app_pages.dart';
import '../controllers/auth_controller.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthController authC = Get.find<AuthController>();

  final TextEditingController firstName = TextEditingController();
  final TextEditingController lastName = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController birthDate = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController password = TextEditingController();
  
  bool hidePass = true;
  bool isLoading = false;
  String? completePhoneNumber;

  // --- DATE PICKER ---
  Future<void> pickDate() async {
    DateTime? result = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialDate: DateTime(2000),
    );
    if (result != null) {
      birthDate.text = DateFormat('dd/MM/yyyy').format(result);
    }
  }

  // --- VALIDASI ---
  bool isValidEmail(String email) => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  bool isValidPassword(String pass) => RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*[\d\W]).+$').hasMatch(pass) && pass.length >= 8;

  // --- FUNGSI UTAMA ---
  Future<void> handleRegister() async {
    // 1. Validasi Input
    if (firstName.text.isEmpty || email.text.isEmpty || password.text.isEmpty || completePhoneNumber == null) {
      Get.snackbar("Error", "Harap isi semua data", backgroundColor: AppColors.error, colorText: Colors.white);
      return;
    }
    if (!isValidEmail(email.text)) {
      Get.snackbar("Error", "Email tidak valid", backgroundColor: AppColors.error, colorText: Colors.white);
      return;
    }

    setState(() => isLoading = true);

    try {      
      UserCredential userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      User? user = userCred.user;

      if (user != null) {
        await user.sendEmailVerification();

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          "uid": user.uid,
          "firstName": firstName.text.trim(),
          "lastName": lastName.text.trim(),
          "email": email.text.trim(),
          "birthDate": birthDate.text.trim(),
          "phone": completePhoneNumber,
          "createdAt": DateTime.now(),
          "is_verified": false,
        });
        
        Get.offAllNamed(Routes.EMAILVERIFICATIONPAGE, arguments: email.text.trim());                
      }

    } on FirebaseAuthException catch (e) {
      String message = "Terjadi kesalahan";
      if (e.code == 'email-already-in-use') message = "Email sudah terdaftar";
      if (e.code == 'weak-password') message = "Password terlalu lemah";
      
      Get.snackbar("Error", message, backgroundColor: AppColors.error, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(
        context,
      ).unfocus(),
    child:  Scaffold(
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
                        const SizedBox(height: 10),
                        const Text(
                          "Daftar",
                          style: TextStyle(
                            color: Color(0xFF2A274B),
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
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
                                onTap: () {
                                  FocusScope.of(context).unfocus();
                                  Get.offNamed(Routes.LOGIN);
                                },
                                child: const Text(
                                  "Masuk",
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w700,
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
                              handleRegister(); 
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
                        const SizedBox(height: 20),

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