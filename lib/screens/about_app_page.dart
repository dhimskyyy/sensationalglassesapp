import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/theme/app_colors.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Tentang Aplikasi',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            
            // Ikon Aplikasi Besar
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.mint.withOpacity(0.1), 
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/logo.png', 
                width: 80, 
                height: 80, 
                fit: BoxFit.contain, 
              ),
            ),
            const SizedBox(height: 24),
            
            // Nama Aplikasi
            const Text(
              'Sensational Glasses',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            const Text(
              'Alat Bantu Penyandang Tunanetra Menggunakan\nMachine Learning Terintegrasi Internet of Things', // Saya tambahkan enter (\n) dan perbaiki typo
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 32),

            // Card Informasi
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DESKRIPSI',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Sensational Glasses, sebuah inovasi dalam teknologi yang dirancang untuk membantu penyandang tunanetra meningkatkan aksesibilitas dan kualitas hidup mereka. Disabilitas, termasuk tunanetra, di Indonesia masih menghadapi banyak hambatan dalam berpartisipasi secara sosial dan ekonomi. Aplikasi ini hadir dengan tujuan untuk monitoring dan pelacakan perangkat Sensational Glasses. Dirancang khusus untuk membantu pengawasan aktivitas penyandang tunanetra.',
                    style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(color: Color(0xFFF1F5F9), thickness: 2),
                  ),
                  
                  const Text(
                    'DIKEMBANGKAN OLEH',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // ==========================================
                      // PERBAIKAN FOTO PROFIL DEVELOPER
                      // ==========================================
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14), // Tingkat kelengkungan sudut
                        child: Image.asset(
                          'assets/me.png', 
                          width: 52, // Dibesarkan sedikit agar lebih proporsional
                          height: 52, 
                          fit: BoxFit.cover, // Kunci agar foto tidak penyok
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mohammad Dhimas Afrizal', 
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)
                            ),
                            SizedBox(height: 4),
                            Text(
                              'S1 Rekayasa Perangkat Lunak', 
                              style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}