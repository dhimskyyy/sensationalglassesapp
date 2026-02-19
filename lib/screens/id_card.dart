import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'input_data_tunanetra_page.dart';
import '../app/theme/app_colors.dart';

class IdCard extends StatelessWidget {
  const IdCard({super.key});

  @override
  Widget build(BuildContext context) {
    const Color neutralDark = Color(0xFF224942);

    String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
        title: const Text(
          "Digital ID Card",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
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
                style: TextStyle(color: Colors.black),
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
                            color: neutralDark.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: neutralDark),
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
    Get.defaultDialog(
      title: "Hapus Data",
      middleText: "Apakah Anda yakin ingin menghapus data tunanetra ini?",
      textConfirm: "Hapus",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      buttonColor: AppColors.error,
      onConfirm: () async {
        await FirebaseFirestore.instance
            .collection("tunanetra_data")
            .doc(uid)
            .delete();
        Get.back();
      },
    );
  }
}
