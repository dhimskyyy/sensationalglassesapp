import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sensationalglassesapp/controllers/home_controller.dart';

import 'package:sensationalglassesapp/app/theme/app_colors.dart';
import '../app/routes/app_pages.dart';

class AuthController extends GetxController {
  // ================== INSTANCE ==================
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================== EMAIL JS ==================
  final String serviceId = 'service_v9e4i6c';
  final String templateId = 'template_nlmf1wn';
  final String publicKey = '4naTiGhbhMWZAnEYr';

  // ================== CONTROLLER ==================
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final birthDateController = TextEditingController();
  final phoneController = TextEditingController();

  // ================== AUTH STATE ==================
  Rx<User?> firebaseUser = Rx<User?>(null);

  @override
  void onInit() {
    firebaseUser.bindStream(_auth.authStateChanges());
    super.onInit();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    birthDateController.dispose();
    phoneController.dispose();
    super.onClose();
  }

  // ================== UTIL ==================
  void clearFields() {
    emailController.clear();
    passwordController.clear();
    firstNameController.clear();
    lastNameController.clear();
    birthDateController.clear();
    phoneController.clear();
  }

  // ================== EMAIL OTP ==================
  Future<bool> sendEmailOTP(
    String name,
    String emailTujuan,
    String otp,
  ) async {
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
            'to_name': name,
            'to_email': emailTujuan,
            'otp_code': otp,
          },
        }),
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ================== VERIFICATION ROUTING ==================
  Future<void> _checkVerificationAndRoute(User user) async {
    try {
      await user.reload();
      final updatedUser = _auth.currentUser;

      if (updatedUser != null && updatedUser.emailVerified) {
        await _firestore.collection('users').doc(updatedUser.uid).update({
          "is_verified": true,
        });

        Get.offAllNamed(Routes.MAIN);
      } else {
        Get.offAllNamed(
          Routes.EMAILVERIFICATIONPAGE,
          arguments: updatedUser?.email,
        );
      }
    } catch (e) {
      _showError("Gagal memuat status user: $e");
    }
  }

  // ================== RELOAD USER & CEK VERIFIKASI EMAIL ==================

  Future<void> resendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();

      Get.snackbar("Sukses", "Link verifikasi baru telah dikirim.");
    } catch (e) {
      Get.snackbar("Error", "Gagal mengirim ulang: $e");
    }
  }

  // ================== LOGIN EMAIL ==================
  Future<void> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user != null) {
        clearFields();
        await _checkVerificationAndRoute(cred.user!);
      }
    } on FirebaseAuthException catch (e) {
      String message =
          "Login gagal, harap masukkan email dan password dengan benar";

      if (e.code == 'user-not-found') {
        message = "Email belum terdaftar";
      } else if (e.code == 'wrong-password') {
        message = "Password salah";
      }

      _showError(message);
    } catch (_) {
      _showError("Terjadi kesalahan");
    }
  }

  // ================== GOOGLE LOGIN ==================
  Future<void> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) return;

      final names = user.displayName?.split(' ') ?? [];
      final firstName = names.isNotEmpty ? names.first : "User";
      final lastName = names.length > 1 ? names.sublist(1).join(' ') : "";

      await _firestore.collection('users').doc(user.uid).set({
        "uid": user.uid,
        "firstName": firstName,
        "lastName": lastName,
        // PERBAIKAN UTAMA: Ambil email murni dari Google, bukan Firebase
        "email": googleUser.email, 
        "photoUrl": user.photoURL ?? "",
        "is_verified": true,
      }, SetOptions(merge: true));

      Get.offAllNamed(Routes.MAIN);
    } catch (e) {
      _showError("Login Google gagal: $e");
    }
  }

  // ================== FACEBOOK LOGIN ==================
  Future<void> signInWithFacebook() async {
    try {
      final result = await FacebookAuth.instance.login();
      if (result.status != LoginStatus.success) return;

      final credential = FacebookAuthProvider.credential(
        result.accessToken!.token,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) return;

      final names = user.displayName?.split(' ') ?? [];
      final firstName = names.isNotEmpty ? names.first : "User";
      final lastName = names.length > 1 ? names.sublist(1).join(' ') : "";

      // PERBAIKAN UTAMA: Ambil email murni dari Provider Data
      String fbEmail = user.email ?? "";
      if (fbEmail.isEmpty && user.providerData.isNotEmpty) {
        fbEmail = user.providerData.first.email ?? "";
      }

      await _firestore.collection('users').doc(user.uid).set({
        "uid": user.uid,
        "firstName": firstName,
        "lastName": lastName,
        "email": fbEmail, // Pakai email yang sudah diekstrak
        "photoUrl": user.photoURL ?? "",
        "is_verified": true,
      }, SetOptions(merge: true));

      Get.offAllNamed(Routes.MAIN);
    } catch (e) {
      _showError("Login Facebook gagal: $e");
    }
  }

  // ================== OTP ==================
  // Di AuthController.dart

  String generateOTP() {
  final rng = Random();
  return (100000 + rng.nextInt(900000)).toString(); // Menghasilkan 6 digit
}
Future<bool> sendWhatsAppOTP(String phoneNumber, String otp) async {
  // Pastikan nomor diawali dengan kode negara (misal 62)
  String formattedPhone = phoneNumber;
  if (formattedPhone.startsWith('0')) {
    formattedPhone = '62${formattedPhone.substring(1)}';
  }

  final url = Uri.parse('https://api.fonnte.com/send');

  try {
    final response = await http.post(
      url,
      headers: {
        // Ganti dengan API Token dari Dashboard Fonnte Anda
        'Authorization': 'RjUzjWzqhEkFQaQwp6zJ',
      },
      body: {
        'target': formattedPhone,
        'message': 'KODE OTP ANDA: $otp. Jangan berikan kode ini kepada siapapun demi keamanan akun Anda.',
        'countryCode': '62',
      },
    );

    if (response.statusCode == 200) {
      print("OTP Berhasil Terkirim: ${response.body}");
      return true;
    } else {
      print("Gagal Kirim OTP: ${response.body}");
      return false;
    }
  } catch (e) {
    print("Error HTTP: $e");
    return false;
  }
}

  Future<void> verifyOtp(String inputOtp) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw "User tidak ditemukan";

      final doc =
          await _firestore.collection('users').doc(user.uid).get();
      final serverOtp = doc.get('otp_code') ?? "";

      if (inputOtp != serverOtp) {
        throw "Kode OTP yang Anda masukkan salah";
      }

      await _firestore.collection('users').doc(user.uid).update({
        "is_verified": true,
        "otp_code": FieldValue.delete(),
      });

      Get.offAllNamed(Routes.MAIN);
    } catch (e) {
      throw e.toString().replaceAll("Exception: ", "");
    }
  }

  // ================== RESET & VERIFIKASI ==================
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      Get.snackbar("Sukses", "Email reset password telah dikirim");
    } on FirebaseAuthException catch (e) {
      String message = "Gagal mengirim email reset";

      if (e.code == 'user-not-found') message = "Email tidak terdaftar";
      if (e.code == 'invalid-email') message = "Format email tidak valid";

      _showError(message);
    }
  }

  Future<void> reloadUserAndCheckVerification() async {
    try {
      await _auth.currentUser?.reload();
      final user = _auth.currentUser;

      if (user != null && user.emailVerified) {
        await _firestore.collection('users').doc(user.uid).update({
          "is_verified": true,
        });
        Get.offAllNamed(Routes.MAIN);
      } else {
        Get.snackbar(
          "Info",
          "Email belum diverifikasi",
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal memperbarui status: $e");
    }
  }

  // ================== LOGOUT ==================
  Future<void> signOut() async {
  try {
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().stopMonitoring();
      Get.delete<HomeController>(force: true);
    }

    await GoogleSignIn().signOut();
    await FacebookAuth.instance.logOut();
    await _auth.signOut();

    clearFields();
    Get.offAllNamed(Routes.LOGIN); 
    
  } catch (e) {
    _showError("Gagal logout: $e");
  }
}

  // ================== ERROR UI ==================
  void _showError(String message) {
    Get.snackbar(
      "Error",
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }
}