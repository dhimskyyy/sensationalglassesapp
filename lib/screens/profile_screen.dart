import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/home_controller.dart';
import '../controllers/auth_controller.dart';
import '../app/routes/app_pages.dart';
import '../app/theme/app_colors.dart';
import 'edit_user_profile_page.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {

    // Inisialisasi controller
    final HomeController homeC = Get.find<HomeController>();
    final AuthController authC = Get.find<AuthController>();
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 14),
              // --- Profile Header Section ---
              Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.mint.withOpacity(0.2),
                                width: 4,
                              ),
                            ),
                            child: ClipOval(
                              child: Obx(() {
                                String userPhoto = homeC.userPhotoUrl.value;
                                return (userPhoto.isNotEmpty)
                                    ? CachedNetworkImage(
                                        // PERBAIKAN: Hapus "?t=..." agar Cache bekerja instan
                                        imageUrl: userPhoto, 
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                        fadeInDuration: const Duration(milliseconds: 100),
                                        // Gunakan Shimmer atau Widget yang lebih ringan sebagai placeholder
                                        placeholder: (context, url) =>
                                            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                        errorWidget: (context, url, error) =>
                                            const Icon(Icons.person, size: 60),
                                      )
                                    : Image.asset(
                                        'assets/default_profile.png',
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      );
                              }),
                            ),
                          ),
                          // Badge Verified
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.mint,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.verified,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Obx(() => Text(
                        homeC.userName.value,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      )),
                      
                      // PERBAIKAN: Email dibungkus Obx dan digabungkan logikanya
                      Obx(() {
                        // 1. Tembak dari inti Firebase Auth dulu
                        String validEmail = user?.email ?? "";
                        
                        // 2. Jika dari Auth kosong (kasus FB), tarik dari Database
                        if (validEmail.isEmpty) {
                          validEmail = homeC.userEmail.value;
                        }
                        
                        // 3. Fallback jika memang masih loading
                        if (validEmail.isEmpty) {
                          validEmail = "Memuat email...";
                        }

                        return Text(
                          validEmail,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        );
                      }),
                      
                    ],
                  ),
                ),     
              const SizedBox(height: 32),

              // --- Account Settings Group ---
              _buildSectionHeader('Data Monitor'),
              _buildSettingsContainer(AppColors.mint, [
                _buildSettingTile(
                  primaryColor: AppColors.mint,
                  icon: Icons.person_outline,
                  title: 'Edit Profile',
                  onTap: () => Get.to(() => const UserProfilePage()),
                ),
                _buildSettingTile(
                  primaryColor: AppColors.mint,
                  icon: Icons.badge_outlined,
                  title: 'Data Tunanetra',
                  onTap: () => Get.toNamed(Routes.IDCARD),
                ),
                _buildSettingTile(
                  primaryColor: AppColors.mint,
                  icon: Icons.history,
                  title: 'Riwayat Notifikasi',
                  isLast: true,
                ),
              ]),

              const SizedBox(height: 24),

              // --- App Settings Group ---
              _buildSectionHeader('App Settings'),
              _buildSettingsContainer(AppColors.mint, [
                _buildSettingTile(
                  primaryColor: AppColors.mint,
                  icon: Icons.language,
                  title: 'Language',
                  subtitle: 'Indonesia (ID)',
                ),
                _buildSettingTile(
                  primaryColor: AppColors.mint,
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  isLast: true,
                ),
              ]),
              
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => authC.signOut(),
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          backgroundColor: Colors.red.withOpacity(0.05),
                          side: BorderSide(color: Colors.red.withOpacity(0.1)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
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
      );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsContainer(Color primaryColor, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.05)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingTile({
    required Color primaryColor,
    required IconData icon,
    required String title,
    String? subtitle,
    bool isLast = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(color: primaryColor.withOpacity(0.05)),
                ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: primaryColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}