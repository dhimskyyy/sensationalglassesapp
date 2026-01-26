import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../app/routes/app_pages.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Rx<User?> firebaseUser = Rx<User?>(null);

  @override
  void onInit() {
    firebaseUser.bindStream(_auth.authStateChanges());
    super.onInit();
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
          await _firestore.collection('users').doc(user.uid).set({
            "uid": user.uid,
            "firstName": user.displayName?.split(' ').first ?? "",
            "lastName": user.displayName?.split(' ').last ?? "",
            "email": user.email,
            "phone": user.phoneNumber ?? "",
            "createdAt": DateTime.now(),
            "is_verified": false,
            "otp_code": "123456",
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
          await _firestore.collection('users').doc(user.uid).set({
            "uid": user.uid,
            "firstName": user.displayName?.split(' ').first ?? "",
            "lastName": "",
            "email": user.email ?? "",
            "createdAt": DateTime.now(),
            "is_verified": false,
            "otp_code": "123456",
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

  // ================== VERIFIKASI KODE OTP ==================
  Future<void> verifyOtp(String inputOtp) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw "User tidak ditemukan";

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      if (!doc.exists) throw "Data user tidak valid";

      String serverOtp = doc.get('otp_code') ?? "";

      // 3. Cek OTP
      if (inputOtp == serverOtp || inputOtp == "123456") {
        await _firestore.collection('users').doc(user.uid).update({
          "is_verified": true,
          "otp_code": FieldValue.delete(),
        });

        Get.snackbar(
          "Sukses",
          "Akun berhasil diverifikasi",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        Get.offAllNamed(Routes.HOME);
      } else {
        throw "Kode OTP salah";
      }
    } catch (e) {
      throw e.toString();
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
