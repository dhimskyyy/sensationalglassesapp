import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';
import 'dart:math' as math;

class MapsScreen extends StatelessWidget {
  const MapsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Mengubah background menjadi warna netral agar peta lebih terlihat
      backgroundColor: const Color(0xFFF3F4F6), 
      body: Stack(
        children: [
          // 1. Background Peta
          Positioned.fill(
            child: Container(
              color: const Color(0xFFE5E5F7),
              child: CustomPaint(
                painter: MapPathPainter(),
              ),
            ),
          ),

          // 2. Marker Tempat (Tetap Sama)
          const Positioned(
            top: 150,
            left: 100,
            child: MapMarker(
              icon: Icons.location_on,
              color: Colors.orange,
              label: "Masjid PUSDAI",
            ),
          ),
          const Positioned(
            bottom: 400,
            right: 80,
            child: MapMarker(
              icon: Icons.restaurant,
              color: Colors.blue,
              label: "Shabu Hachi",
            ),
          ),

          // 3. Marker Utama
          Positioned(
            top: 200,
            left: 180,
            child: MainUserMarker(primaryColor: AppColors.mint),
          ),

          // 4. Panel Bawah (Informasi User)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 20), // Memberi ruang di bawah
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle Bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Header Profile
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.grey,
                              backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=cameron'),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Cameron Williamson",
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    "Tunanetra (Visually Impaired)",
                                    style: TextStyle(color: Colors.grey, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFEE2E2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.notifications_active, color: Colors.red, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Lokasi Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: AppColors.mint),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text("LOKASI TERKINI", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                    Text("Jl. Pahlawan No. 1, Jakarta", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Tombol Rute
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.mint,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text("Rute", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        // BAGIAN BOTTOM NAV LAMA SUDAH DIHAPUS DARI SINI
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget pendukung (Marker & Painter) tetap sama seperti kode Anda sebelumnya...

// Widget untuk Marker Toko/Tempat
class MapMarker extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const MapMarker({super.key, required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// Widget untuk User Utama (Dengan Animasi Lingkaran)
class MainUserMarker extends StatefulWidget {
  final Color primaryColor;
  const MainUserMarker({super.key, required this.primaryColor});

  @override
  State<MainUserMarker> createState() => _MainUserMarkerState();
}

class _MainUserMarkerState extends State<MainUserMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            ScaleTransition(
              scale: Tween(begin: 1.0, end: 2.0).animate(_controller),
              child: FadeTransition(
                opacity: Tween(begin: 0.5, end: 0.0).animate(_controller),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(color: widget.primaryColor.withOpacity(0.5), shape: BoxShape.circle),
                ),
              ),
            ),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: widget.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
          ),
          child: const Text("Cameron W.", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// Painter untuk menggambar jalanan di background (seperti SVG)
class MapPathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final path1 = Path()
      ..moveTo(-10, 100)
      ..lineTo(150, 150)
      ..lineTo(300, 50)
      ..lineTo(450, 80);

    final path2 = Path()
      ..moveTo(50, -10)
      ..lineTo(80, 200)
      ..lineTo(60, 400)
      ..lineTo(100, 700);

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
    
    paint.strokeWidth = 6;
    paint.color = Colors.white.withOpacity(0.3);
    canvas.drawLine(const Offset(150, 150), const Offset(250, 400), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}