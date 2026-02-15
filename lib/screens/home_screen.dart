import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/auth_controller.dart';
import '../controllers/home_controller.dart';
import '../app/theme/app_colors.dart';

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

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: homeC.streamUser(),
      builder: (context, snapshot) {
        // Tampilan Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: primaryColor)),
          );
        }

        // Ambil data User dari Firestore
        var userData = snapshot.data?.data();
        String fullName = userData != null 
            ? "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}" 
            : "Admin";

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Header Dinamis
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Halo, $fullName',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Monitoring device status',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ),
                      // Tombol Logout di Logo
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

                  // Green Device Card
                  _buildDeviceCard(primaryColor, fullName),

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
          // Bottom Nav dihapus dari sini karena akan dikelola oleh MainNavigation
        );
      },
    );
  }

  Widget _buildDeviceCard(Color primaryColor, String name) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white24,
                backgroundImage: AssetImage("assets/profile.png"),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Row(
                      children: [
                        Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                        SizedBox(width: 4),
                        Text('Active Now', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white70),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Colors.white24, height: 1),
          ),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            children: [
              _buildStatItem(Icons.calendar_today, 'Date', '20/01/2026'),
              _buildStatItem(Icons.signal_cellular_alt, 'Signal', 'Bagus'),
              _buildStatItem(Icons.battery_full, 'Battery', '100%'),
              _buildStatItem(Icons.straighten, 'Distance', '500 m'),
            ],
          ),
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
      child: ElevatedButton.icon(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 5,
          shadowColor: primaryColor.withOpacity(0.4),
        ),
        icon: const Icon(Icons.notifications_active),
        label: const Text('Activate Alarm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
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