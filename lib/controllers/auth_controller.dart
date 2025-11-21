import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/material.dart';
import '../routes/app_pages.dart'; // ✅ Import routes

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Rx<User?> firebaseUser = Rx<User?>(null);
  
  @override
  void onInit() {
    firebaseUser.bindStream(_auth.authStateChanges());
    ever(firebaseUser, (User? user) {
      // Hanya update state — tanpa navigasi
      firebaseUser.value = user;
    });
    super.onInit();
  }
  
  // ================== LOGIN EMAIL ==================
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (cred.user != null) {
        Get.offAllNamed(Routes.HOME); // ✅ Gunakan Routes.HOME
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
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
      
      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        Get.offAllNamed(Routes.HOME);
      }
    } catch (e) {
      Get.snackbar("Google Login Error", e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
  
  // ================== FACEBOOK LOGIN ==================
  Future<void> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final fbToken = result.accessToken!;
        final credential = FacebookAuthProvider.credential(fbToken.token);
        
        final userCredential = await _auth.signInWithCredential(credential);
        
        if (userCredential.user != null) {
          Get.offAllNamed(Routes.HOME);
        }
      }
    } catch (e) {
      Get.snackbar("Facebook Login Error", e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // ================== FORGOT PASSWORD ==================
  Future<void> sendPasswordResetEmail(String email) async {
  try {
    await _auth.sendPasswordResetEmail(email: email);
    Get.snackbar(
      "Sukses",
      "Email reset password telah dikirim ke $email",
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  } catch (e) {
    Get.snackbar(
      "Error",
      e.toString(),
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
} 

  // ================== LOGOUT ==================
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
      await FacebookAuth.instance.logOut();
      await _auth.signOut();
      
      // ✅ TAMBAHKAN NAVIGASI KE LOGIN SETELAH LOGOUT
      Get.offAllNamed(Routes.LOGIN);
    } catch (e) {
      Get.snackbar("Logout Error", e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}