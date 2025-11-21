import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController firstName = TextEditingController();
  final TextEditingController lastName = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController birthDate = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController password = TextEditingController();
  bool hidePass = true;

  String? completePhoneNumber;

  // DATE PICKER
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

  // EMAIL VALIDATION
  bool isValidEmail(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  // PASSWORD VALIDATION
  bool isValidPassword(String pass) {
    final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*[\d\W]).+$');
    return regex.hasMatch(pass);
  }

  // FIREBASE REGISTER + SAVE TO FIRESTORE
  Future<void> registerUser() async {
    try {
      // ===================== AUTH =====================
      UserCredential userCred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      String uid = userCred.user!.uid;

      // =================== FIRESTORE ===================
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        "uid": uid,
        "firstName": firstName.text.trim(),
        "lastName": lastName.text.trim(),
        "email": email.text.trim(),
        "birthDate": birthDate.text.trim(),
        "phone": completePhoneNumber,
        "createdAt": DateTime.now(),
      });

      Get.offAllNamed('/login');

      Get.snackbar(
        "Berhasil",
        "Akun berhasil dibuat",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        "Error",
        e.message ?? "Terjadi kesalahan",
        backgroundColor: Colors.red.withOpacity(0.85),
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // BACKGROUND MINT
          Container(height: 500, color: const Color(0xFF74C9B6)),

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
                              style: TextStyle(color: Colors.white, fontSize: 14),
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
                                  color: Color(0xFF1C2340),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // WHITE FORM CONTAINER
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
                        // NAME ROW
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Nama Depan",
                                      style: TextStyle(color: Color(0xFF2A274B))),
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
                                  const Text("Nama Belakang",
                                      style: TextStyle(color: Color(0xFF2A274B))),
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
                        const Text("Email",
                            style: TextStyle(color: Color(0xFF2A274B))),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: email,
                          decoration: _inputDecoration(),
                        ),

                        const SizedBox(height: 18),

                        // BIRTHDATE
                        const Text("Birth of date",
                            style: TextStyle(color: Color(0xFF2A274B))),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: birthDate,
                          readOnly: true,
                          onTap: pickDate,
                          decoration: _inputDecoration().copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(Icons.calendar_month,
                                  color: Colors.grey.shade600),
                              onPressed: pickDate,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // PHONE
                        const Text("Phone Number",
                            style: TextStyle(color: Color(0xFF2A274B))),
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
                          onChanged: (p) => completePhoneNumber = p.completeNumber,
                          onCountryChanged: (c) => completePhoneNumber = null,
                        ),

                        const SizedBox(height: 18),

                        // PASSWORD
                        const Text("Set Password",
                            style: TextStyle(color: Color(0xFF2A274B))),
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
                                color: const Color(0xFF2A274B),
                              ),
                              onPressed: () => setState(() {
                                hidePass = !hidePass;
                              }),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // BUTTON
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF74C9B6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              // VALIDATION
                              if (firstName.text.isEmpty ||
                                  lastName.text.isEmpty ||
                                  email.text.isEmpty ||
                                  birthDate.text.isEmpty ||
                                  password.text.isEmpty ||
                                  (completePhoneNumber?.isEmpty ?? true)) {
                                Get.snackbar(
                                  "Form Tidak Lengkap",
                                  "Harap isi semua data.",
                                  backgroundColor: Colors.red.withOpacity(0.85),
                                  colorText: Colors.white,
                                );
                                return;
                              }

                              if (!isValidEmail(email.text)) {
                                Get.snackbar(
                                  "Email Tidak Valid",
                                  "Masukkan email yang benar.",
                                  backgroundColor: Colors.red.withOpacity(0.85),
                                  colorText: Colors.white,
                                );
                                return;
                              }

                              if (!isValidPassword(password.text)) {
                                Get.snackbar(
                                  "Password Lemah",
                                  "Harus ada huruf besar, kecil, angka/simbol.",
                                  backgroundColor: Colors.red.withOpacity(0.85),
                                  colorText: Colors.white,
                                );
                                return;
                              }

                              registerUser(); // 🔥 REGISTER + SAVE FIRESTORE
                            },
                            child: const Text(
                              "Daftar",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
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

  // INPUT DECORATION
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
