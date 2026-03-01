import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sensationalglassesapp/screens/id_card.dart';
import '../controllers/auth_controller.dart';
import '../controllers/home_controller.dart';
import '../app/theme/app_colors.dart';
import 'input_data_tunanetra_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  
  // Inisialisasi Controller GetX
  final HomeController homeC = Get.put(HomeController());
  final AuthController authC = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  const Color primaryColor = Color(0xFF66C7AA);
  String uid = FirebaseAuth.instance.currentUser!.uid;

  // Stream 1: Mengambil Data Profil User (Admin) yang sedang login
  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance.collection("users").doc(uid).snapshots(),
    builder: (context, userSnapshot) {
      // Ambil nama User
      var userData = userSnapshot.data?.data();
      String userName = userData != null
          ? "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}".trim()
          : "User";

      // Stream 2: Mengambil Data Tunanetra (untuk isi Card)
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection("tunanetra_data").doc(uid).snapshots(),
        builder: (context, tunaSnapshot) {
          bool hasData = tunaSnapshot.hasData && tunaSnapshot.data!.data() != null;
          var tunanetraData = tunaSnapshot.data?.data();

          // Tampilan Loading jika stream utama belum siap
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: primaryColor)),
            );
          }

          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() => Text(
                        'Halo, ${homeC.userName.value}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      )),
                      Text(
                        'Monitoring device status',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => authC.signOut(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                    child: const Icon(Icons.logout, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
                    const SizedBox(height: 24),

                    _buildDeviceCard(primaryColor, hasData, tunanetraData),

                    const SizedBox(height: 24),

                    // Radar Card
                    _buildRadarCard(primaryColor),

                    const SizedBox(height: 24),

                    // Activate Alarm Button
                    _buildAlarmButton(primaryColor),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildDeviceCard(Color primaryColor, bool hasData, Map<String, dynamic>? data) {
  String formattedDate = "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";

  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: primaryColor,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
    ),
    child: Column(
      children: [
        if (!hasData)
          // TAMPILAN JIKA DATA KOSONG (Tombol Masukkan Data)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Get.to(() => const InputDataTunanetraPage()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Masukkan Data Tunanetra"),
            ),
          )
        else
          // TAMPILAN JIKA DATA ADA (Sesuai Gambar Referensi)
GestureDetector(
  onTap: () => Get.to(() => const IdCard()),
  child: Row(
    children: [
      ClipOval(
                  child: ((data?['foto_url'] != null && data?['foto_url'] != ""))
                      ? CachedNetworkImage(
                          imageUrl: data?['foto_url'],
                          width: 60, height: 60,
                          fit: BoxFit.cover,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                          placeholder: (context, url) => Container(color: Colors.transparent),
                          errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.white),
                        )
                      : Image.asset('assets/default_profile.png', width: 60, height: 60, fit: BoxFit.cover),
                ),
      const SizedBox(width: 15),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data?['nama_tunanetra'] ?? "No Name",
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const Row(
              children: [
                Icon(Icons.circle, color: Colors.greenAccent, size: 10),
                SizedBox(width: 5),
                Text("Active Now", style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
      const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
    ],
  ),
),

        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Divider(color: Colors.white24, height: 1),
        ),

        // BAGIAN OBX UNTUK DATA REAL-TIME
        Obx(() => GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          children: [
            _buildStatItem(Icons.calendar_today, 'Date', formattedDate),

            // Menampilkan data sinyal dari HomeController
            _buildStatItem(Icons.signal_cellular_alt, 'Signal', homeC.signal.value),

            // Menampilkan data baterai dari HomeController
            _buildStatItem(Icons.battery_full, 'Battery', "${homeC.battery.value}%"),

            // Menampilkan data jarak dari HomeController
            _buildStatItem(Icons.straighten, 'Distance', "${homeC.distance.value} m"),
          ],
        )),
      ],
    ),
  );
}

  Widget _buildRadarCard(Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        image: const DecorationImage(
          image: AssetImage('assets/maps.png'),
          fit: BoxFit.cover,
          opacity: 0.1,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 120, width: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _radarController,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryColor.withOpacity(1 - _radarController.value), width: 2),
                      ),
                      width: 120 * _radarController.value,
                      height: 120 * _radarController.value,
                    );
                  },
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryColor.withOpacity(0.2), width: 1),
                  ),
                  child: const Icon(Icons.explore, color: AppColors.mint, size: 40),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Locating device...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Please wait while we establish a secure\nconnection with the tracker.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.refresh, size: 18, color: AppColors.mint),
            label: const Text('Refresh Signal', style: TextStyle(color: AppColors.mint)),
          ),
        ],
      ),
    );
  }

Widget _buildAlarmButton(Color primaryColor) {
  return SizedBox(
    width: double.infinity,
    height: 56,
    child: Obx(() => ElevatedButton.icon(
      // Jika isAlarmProcessing true, onPressed jadi null (tombol tidak bisa diklik/disabled)
      onPressed: homeC.isAlarmProcessing.value ? null : () => homeC.triggerAlarm(),
      style: ElevatedButton.styleFrom(
        backgroundColor: homeC.isAlarmProcessing.value ? Colors.grey : primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 5,
      ),
      icon: homeC.isAlarmProcessing.value 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Icon(Icons.notifications_active),
      label: Text(
        homeC.isAlarmProcessing.value ? 'Alarm is Ringing...' : 'Activate Alarm',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    )),
  );
}

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ],
    );
  }
}