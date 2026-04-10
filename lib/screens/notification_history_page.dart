import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Untuk memformat waktu
import '../app/theme/app_colors.dart';
import 'maps.dart';

class NotificationHistoryPage extends StatelessWidget {
  const NotificationHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Riwayat Notifikasi',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: Text("Silakan login terlebih dahulu."))
          : StreamBuilder<QuerySnapshot>(
              // Mengambil data dari Firestore secara langsung
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('notifications')
                  .orderBy('timestamp', descending: true) // Urutkan dari yang terbaru
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.mint));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text("Belum ada riwayat notifikasi", style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  );
                }

                final notifications = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notifDoc = notifications[index];
                    final notif = notifDoc.data() as Map<String, dynamic>;
                    
                    // Format waktu dari Firestore ke format yang mudah dibaca
                    String formattedTime = "Baru saja";
                    if (notif['timestamp'] != null) {
                      DateTime date = (notif['timestamp'] as Timestamp).toDate();
                      formattedTime = DateFormat('dd MMM yyyy, HH:mm').format(date);
                    }

                    Color iconColor;
                    Color bgColor;
                    IconData iconData;

                    if (notif['level'] == 'danger') {
                      iconColor = Colors.redAccent;
                      bgColor = Colors.redAccent.withOpacity(0.1);
                    } else if (notif['level'] == 'warning') {
                      iconColor = Colors.orange;
                      bgColor = Colors.orange.withOpacity(0.1);
                    } else {
                      iconColor = AppColors.mint;
                      bgColor = AppColors.mint.withOpacity(0.1);
                    }

                    if (notif['type'] == 'battery') {
                      iconData = notif['level'] == 'danger' ? Icons.battery_0_bar : Icons.battery_alert;
                    } else {
                      iconData = Icons.share_location;
                    }

                    return GestureDetector(
                      onTap: () {
                        // Jika diklik, tandai sudah dibaca di database dan pergi ke Maps
                        notifDoc.reference.update({'isRead': true});
                        Get.to(() => const MapsScreen());
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: (notif['isRead'] == true) ? Colors.white : const Color(0xFFF0FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: (notif['isRead'] == true) ? Colors.grey.shade100 : AppColors.mint.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                              child: Icon(iconData, color: iconColor, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notif['title'] ?? 'Notifikasi', 
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: (notif['isRead'] == true) ? Colors.black87 : AppColors.mint)
                                        ),
                                      ),
                                      if (notif['isRead'] == false)
                                        Container(
                                          width: 8, height: 8,
                                          decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                        )
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(notif['message'] ?? '', style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.4)),
                                  const SizedBox(height: 12),
                                  Text(formattedTime, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}