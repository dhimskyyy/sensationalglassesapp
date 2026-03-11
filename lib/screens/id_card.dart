import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sensationalglassesapp/app/theme/app_text_styles.dart';
import '../controllers/home_controller.dart';
import 'input_data_tunanetra_page.dart';
import '../app/theme/app_colors.dart';

class IdCard extends StatelessWidget {
  const IdCard({super.key});

  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "ID Card",
          style: AppTextStyles.appBarTitle
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection("tunanetra_data")
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.mint),
            );
          }

          var data = snapshot.data!.data();
          if (data == null)
            return const Center(
              child: Text(
                "Data tidak ditemukan",
                style: AppTextStyles.normal
              ),
            );

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Column(
              children: [
                // IDENTITY CARD CONTAINER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.idCard,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.mint.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Profile Image Section
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          ClipOval(
                            child:
                                (data['foto_url'] != null &&
                                    data['foto_url'] != "")
                                ? CachedNetworkImage(
                                    imageUrl: data['foto_url'],
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 100,
                                    fadeInDuration: Duration.zero,
                                    fadeOutDuration: Duration.zero,
                                    placeholder: (context, url) =>
                                        Container(color: Colors.transparent),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.person),
                                  )
                                : Image.asset(
                                    'assets/default_profile.png',
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 100,
                                  ),
                          ),
                          const CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.mint,
                            child: Icon(
                              Icons.verified,
                              size: 14,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        data['nama_tunanetra'] ?? "-",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.mint.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "TUNANETRA",
                          style: TextStyle(
                            color: AppColors.mint,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ID Details Grid
                      _buildInfoTile(
                        "ID NUMBER",
                        data['id_number'] ?? "-",
                        AppColors.mint,
                        AppColors.neutralDark,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoTile(
                              "USIA",
                              "${data['usia']} Tahun",
                              AppColors.mint,
                              AppColors.neutralDark,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInfoTile(
                              "GOL. DARAH",
                              data['golongan_darah'] ?? "-",
                              AppColors.mint,
                              AppColors.neutralDark,
                              isPrimary: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoTile(
                        "TEMPAT, TANGGAL LAHIR",
                        data['tempat_tanggal_lahir'] ?? "-",
                        AppColors.mint,
                        AppColors.neutralDark,
                      ),

                      // Status Chip
                      const SizedBox(height: 30),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.neutralDark.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.neutralDark),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.mint,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "STATUS: ACTIVE",
                                style: TextStyle(
                                  color: AppColors.mint,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ACTION BUTTONS
                const SizedBox(height: 40),
                _buildActionButton(
                  label: "Edit Data",
                  icon: Icons.edit,
                  color: AppColors.neutralDark,
                  textColor: Colors.white,
                  onTap: () => Get.to(
                    () => const InputDataTunanetraPage(),
                    arguments: data,
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  label: "Hapus Data",
                  icon: Icons.delete,
                  color: Colors.transparent,
                  textColor: Colors.redAccent,
                  isOutline: true,
                  onTap: () => _confirmDelete(uid),
                ),
                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(
    String label,
    String value,
    Color labelColor,
    Color borderColor, {
    bool isPrimary = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isPrimary ? const Color(0xFF0df2cc) : Colors.white,
              fontSize: 16,
              fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    bool isOutline = false,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: textColor),
        label: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutline ? Colors.transparent : color,
          elevation: 0,
          side: isOutline
              ? const BorderSide(color: Colors.redAccent, width: 0.5)
              : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(String uid) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Peringatan
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.redAccent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              
              // Judul
              const Text(
                "Hapus Data?",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              
              // Deskripsi
              const Text(
                "Tindakan ini tidak dapat dibatalkan. Semua data tunanetra yang tersimpan akan dihapus secara permanen.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              
              // Tombol Aksi
              Row(
                children: [
                  // Tombol Batal
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Batal",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Tombol Hapus
                  Expanded(
  child: ElevatedButton(
    onPressed: () async {
      // 1. Hapus data dari Firestore
      await FirebaseFirestore.instance
          .collection("tunanetra_data")
          .doc(uid)
          .delete();

      // 2. Reset data di HomeController agar tampilan Home langsung berubah
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().resetIoTData();
      }

      // 3. Kembali ke halaman sebelumnya
      Get.back();

      // 4. Beri notifikasi
      Get.snackbar(
        "Berhasil",
        "Data telah dihapus",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        margin: const EdgeInsets.all(20),
      );
    },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Hapus",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false, // User wajib memilih salah satu tombol
    );
  }
}
