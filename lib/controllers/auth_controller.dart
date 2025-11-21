import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/material.dart';
import '../routes/app_pages.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Rx<User?> firebaseUser = Rx<User?>(null);
  bool isFirstOpen = true;

  @override
  void onInit() {
    firebaseUser.bindStream(_auth.authStateChanges());
    ever(firebaseUser, _authStateChanged);
    super.onInit();
  }

  // ================== HANDLE STATE ==================
  void _authStateChanged(User? user) {
    if (isFirstOpen) {
      isFirstOpen = false;
      return;
    }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (user == null) {
      Get.offAllNamed(Routes.LOGIN);
    } else {
      Get.offAllNamed(Routes.HOME);
    }
  });
}

void signInWithEmailAndPassword(String email, String password) async {
  try {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    Get.offAllNamed(Routes.HOME);
  } catch (e) {
    Get.snackbar("Login gagal", e.toString());
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

      await _auth.signInWithCredential(credential);

    } catch (e) {
      Get.snackbar("Google Login Error", e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // ================== FACEBOOK LOGIN ==================
  Future<void> signInWithFacebook() async {
  try {
    final LoginResult result = await FacebookAuth.instance.login();

    // Jika user cancel login, jangan tampilkan error apa pun
    if (result.status == LoginStatus.cancelled) {
      print("User cancelled Facebook login");
      return;
    }

    // Jika error beneran (failed)
    if (result.status == LoginStatus.failed) {
      Get.snackbar(
        "Facebook Login Failed",
        result.message ?? "Unknown error",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Jika sukses
    if (result.status == LoginStatus.success) {
      final fbToken = result.accessToken!;
      final credential = FacebookAuthProvider.credential(fbToken.token);
      await _auth.signInWithCredential(credential);
    }

  } catch (e) {
    Get.snackbar("Facebook Login Error", e.toString(),
        backgroundColor: Colors.red, colorText: Colors.white);
  }
}


  // ================== LOGOUT ==================
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await FacebookAuth.instance.logOut();
    await _auth.signOut();
  }
}
