import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

  // ================== CONTROLLER ==================
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final birthDateController = TextEditingController();
  final phoneController = TextEditingController();

  // ================== AUTH STATE ==================
  Rx<User?> firebaseUser = Rx<User?>(null);

  // Flag to skip auth state changes during initial app startup.
  // We skip the first TWO emissions because authStateChanges() can emit
  // null first (before session is restored) and then the actual user.
  // The initial routing is handled by main.dart, so we must not interfere.
  int _initialSkipCount = 2;

  @override
  void onInit() {
    firebaseUser.bindStream(_auth.authStateChanges());
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
    ever(firebaseUser, _handleAuthChanged);
  }

  void _handleAuthChanged(User? user) {
    // Skip initial emissions - the initial route is already set by main.dart
    if (_initialSkipCount > 0) {
      _initialSkipCount--;
      return;
    }

    if (user == null) {
      // Only navigate to login if we're not already on the login or register page
      final currentRoute = Get.currentRoute;
      if (currentRoute != Routes.LOGIN && currentRoute != Routes.REGISTER) {
        Get.offAllNamed(Routes.LOGIN);
      }
    } else {
      bool isSocialLogin = user.providerData.any((p) => p.providerId != 'password');        
      if (user.emailVerified || isSocialLogin) {
        // Only navigate to MAIN if we're not already there
        final currentRoute = Get.currentRoute;
        if (currentRoute != Routes.MAIN) {
          Get.offAllNamed(Routes.MAIN);
        }
      } else {
        Get.offAllNamed(Routes.EMAILVERIFICATIONPAGE, arguments: user.email);
      }
    }
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
      _showSuccess("Terkirim", "Link verifikasi baru telah dikirim ke email Anda.");
    } catch (e) {
      _showError("Gagal mengirim ulang link verifikasi.");
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
        _showError("Email Anda belum diverifikasi.");
      }
    } catch (e) {
      _showError("Gagal memperbarui status verifikasi.");
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
      _showError("Terjadi kesalahan sistem.");
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
        "email": googleUser.email, 
        "photoUrl": user.photoURL ?? "",
        "is_verified": true,
      }, SetOptions(merge: true));

      Get.offAllNamed(Routes.MAIN);
    } catch (e) {
      _showError("Login Google dibatalkan atau gagal.");
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

      String fbEmail = user.email ?? "";
      if (fbEmail.isEmpty && user.providerData.isNotEmpty) {
        fbEmail = user.providerData.first.email ?? "";
      }

      await _firestore.collection('users').doc(user.uid).set({
        "uid": user.uid,
        "firstName": firstName,
        "lastName": lastName,
        "email": fbEmail, 
        "photoUrl": user.photoURL ?? "",
        "is_verified": true,
      }, SetOptions(merge: true));

      Get.offAllNamed(Routes.MAIN);
    } catch (e) {
      _showError("Login Facebook dibatalkan atau gagal.");
    }
  }

  // ================== LUPA PASSWORD ==================
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showSuccess("Terkirim", "Link reset password telah dikirim ke $email");
    } on FirebaseAuthException catch (e) {
      String message = "Gagal mengirim email reset";

      if (e.code == 'user-not-found') message = "Email tidak terdaftar";
      if (e.code == 'invalid-email') message = "Format email tidak valid";

      _showError(message);
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

  // ================== CUSTOM BEAUTIFUL SNACKBARS ==================
  
  void _showSuccess(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: AppColors.mint,
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 28),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      borderRadius: 16,
      duration: const Duration(seconds: 4),
      boxShadows: [
        BoxShadow(
          color: AppColors.mint.withOpacity(0.4),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  void _showError(String message) {
    Get.snackbar(
      "Pemberitahuan",
      message,
      backgroundColor: const Color(0xFFFF5C5C), // Warna merah lembut tapi tegas
      colorText: Colors.white,
      icon: const Icon(Icons.error_outline, color: Colors.white, size: 28),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      borderRadius: 16,
      duration: const Duration(seconds: 4),
      boxShadows: [
        BoxShadow(
          color: const Color(0xFFFF5C5C).withOpacity(0.4),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}