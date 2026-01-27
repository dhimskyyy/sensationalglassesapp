import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../app/routes/app_pages.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String serviceId = 'service_v9e4i6c'; 
  final String templateId = 'template_nlmf1wn'; 
  final String publicKey = '4naTiGhbhMWZAnEYr';

  Rx<User?> firebaseUser = Rx<User?>(null);

  @override
  void onInit() {
    firebaseUser.bindStream(_auth.authStateChanges());
    super.onInit();
  }

  String generateOTP() {
    var rng = Random();
    return (100000 + rng.nextInt(900000)).toString();
  }

  // --- FUNGSI KIRIM EMAIL OTP (EmailJS) --- 

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
            'to_name': name,
            'to_email': emailTujuan,
            'otp_code': otp,
          }
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ================== FUNGSI BANTUAN CEK STATUS VERIFIKASI ==================
  Future<void> _checkVerificationAndRoute(User user) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

        bool isVerified = data?['is_verified'] ?? false;

        if (isVerified) {
          Get.offAllNamed(Routes.HOME);
        } else {
          Get.offAllNamed(Routes.VERIFICATIONPAGE, arguments: user.email);
          Get.snackbar("Info", "Silakan verifikasi akun Anda terlebih dahulu.");
        }
      } else {
        Get.offAllNamed(Routes.VERIFICATIONPAGE, arguments: user.email);
      }
    } catch (e) {
      _showError("Gagal memuat status user: $e");
    }
  }

  // ================== LOGIN EMAIL ==================
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user != null) {
        await _checkVerificationAndRoute(cred.user!);
      }
    } on FirebaseAuthException catch (e) {
      String message = "Login gagal, harap masukkan email dan password dengan benar";
      if (e.code == 'user-not-found')
        message = "Email belum terdaftar";
      else if (e.code == 'wrong-password')
        message = "Password salah";
      _showError(message);
    } catch (_) {
      _showError("Terjadi kesalahan");
    }
  }

  // ================== GOOGLE LOGIN ==================
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      final User? user = userCredential.user;

      if (user != null) {
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          // 1. Generate OTP Baru
          String otpCode = generateOTP();
          String firstName = user.displayName?.split(' ').first ?? "User";

          // 2. Kirim Email OTP via EmailJS
          await sendEmailOTP(firstName, user.email!, otpCode);

          // 3. Simpan ke Firestore dengan OTP asli (bukan 123456)
          await _firestore.collection('users').doc(user.uid).set({
            "uid": user.uid,
            "firstName": firstName,
            "lastName": user.displayName?.split(' ').last ?? "",
            "email": user.email,
            "phone": user.phoneNumber ?? "",
            "createdAt": DateTime.now(),
            "is_verified": false,
            "otp_code": otpCode, // OTP dinamis
          });

          Get.offAllNamed(Routes.VERIFICATIONPAGE, arguments: user.email);
        } else {
          await _checkVerificationAndRoute(user);
        }
      }
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

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      final User? user = userCredential.user;

      if (user != null) {
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          String otpCode = generateOTP();
          String firstName = user.displayName?.split(' ').first ?? "User";

          await sendEmailOTP(firstName, user.email ?? "", otpCode);

          await _firestore.collection('users').doc(user.uid).set({
            "uid": user.uid,
            "firstName": firstName,
            "lastName": "",
            "email": user.email ?? "",
            "createdAt": DateTime.now(),
            "is_verified": false,
            "otp_code": otpCode,
          });
          Get.offAllNamed(Routes.VERIFICATIONPAGE, arguments: user.email);
        } else {
          await _checkVerificationAndRoute(user);
        }
      }
    } catch (e) {
      _showError("Login Facebook gagal: $e");
    }
  }

  // ================== RESEND OTP ==================
  Future<void> resendOtp(String email) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw "Sesi berakhir, silakan login kembali";

      // 1. Generate OTP baru
      String newOtp = generateOTP();

      // 2. Update di Firestore
      await _firestore.collection('users').doc(user.uid).update({
        "otp_code": newOtp,
      });

      // 3. Ambil nama user untuk template email
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      String name = doc.get('firstName') ?? "User";

      // 4. Kirim Email via EmailJS
      bool isSent = await sendEmailOTP(name, email, newOtp);

      if (isSent) {
        Get.snackbar(
          "Sukses",
          "Kode OTP baru telah dikirim ke email Anda",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        throw "Gagal mengirim email, coba lagi nanti";
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  // ================== VERIFIKASI KODE OTP ==================
  // ================== VERIFIKASI KODE OTP ==================
  Future<void> verifyOtp(String inputOtp) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw "User tidak ditemukan, silakan login kembali";

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
          
      if (!doc.exists) throw "Data user tidak ditemukan di database";

      String serverOtp = doc.get('otp_code') ?? "";

      // Verifikasi HANYA dengan kode yang dikirim ke email
      if (inputOtp == serverOtp) {
        await _firestore.collection('users').doc(user.uid).update({
          "is_verified": true,
          "otp_code": FieldValue.delete(), // Menghapus kode setelah berhasil digunakan
        });

        Get.snackbar(
          "Berhasil",
          "Akun Anda telah terverifikasi",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        Get.offAllNamed(Routes.HOME);
      } else {
        throw "Kode OTP yang Anda masukkan salah";
      }
    } catch (e) {
      // Melempar error agar bisa ditangkap oleh UI di verification_page
      throw e.toString().replaceAll("Exception: ", "");
    }
  }

  // ================== KIRIM EMAIL RESET ==================
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      Get.snackbar(
        "Sukses",
        "Email reset password telah dikirim",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } on FirebaseAuthException catch (e) {
      String message = "Gagal mengirim email reset";
      if (e.code == 'user-not-found') {
        message = "Email tidak terdaftar";
      } else if (e.code == 'invalid-email') {
        message = "Format email tidak valid";
      }
      _showError(message);
    }
  }

  // ================== LOGOUT ==================
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await FacebookAuth.instance.logOut();
    await _auth.signOut();

    Get.offAllNamed(Routes.LOGIN);
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
