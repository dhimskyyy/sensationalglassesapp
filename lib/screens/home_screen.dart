import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/home_controller.dart'; // Pastikan import ini sesuai lokasi file nomor 1
import '../app/theme/app_colors.dart'; // Pastikan import tema Anda benar

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Panggil controller yang baru kita buat
    final HomeController homeC = Get.put(HomeController());
    final AuthController authC = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Home Page",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF74C9B6),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => authC.signOut(),
          ),
        ],
      ),
      // StreamBuilder akan otomatis update tampilan jika data user berubah/dimuat
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: homeC.streamUser(),
        builder: (context, snapshot) {
          // 1. Tampilan saat Loading data
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF74C9B6)));
          }

          // 2. Ambil data dari Firestore
          var userData = snapshot.data?.data();

          // 3. Siapkan teks default jika data masih kosong
          String fullName = "Pengguna";
          String email = "Email tidak tersedia";

          // Jika data ditemukan, ganti teks default dengan data asli
          if (userData != null) {
            fullName = "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}";
            email = userData['email'] ?? "";
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified_user_rounded, size: 80, color: Color(0xFF74C9B6)),
                const SizedBox(height: 20),

                const Text(
                  "Login Berhasil!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 10),

                // Tampilkan Nama Lengkap dari Firestore
                Text(
                  "Halo, $fullName", 
                  style: const TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF74C9B6)
                  ),
                ),

                const SizedBox(height: 5),

                // Tampilkan Email
                Text(
                  email,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),

                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: () => authC.signOut(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF74C9B6),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    "Logout",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}