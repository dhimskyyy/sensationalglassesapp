import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart'; // Tambahan package untuk membuka link
import '../app/theme/app_colors.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  // Fungsi khusus untuk membuka aplikasi luar (WhatsApp / Email)
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      Get.snackbar(
        "Gagal", 
        "Tidak dapat membuka aplikasi terkait.", 
        backgroundColor: Colors.redAccent, 
        colorText: Colors.white
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Bantuan & Dukungan',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.mint.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.support_agent, size: 60, color: AppColors.mint),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ada yang bisa kami bantu?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Temukan jawaban dari pertanyaan umum seputar alat Sensational Glasses di bawah ini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              'PERTANYAAN UMUM (FAQ)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
            ),
            const SizedBox(height: 16),

            // Kumpulan FAQ
            _buildFaqItem(
              'Mengapa status perangkat menjadi "Offline"?',
              'Status "Offline" terjadi jika perangkat kacamata tidak mengirimkan data selama lebih dari 45 detik. Hal ini bisa disebabkan karena perangkat kehabisan baterai, dimatikan, atau berada di area blank spot (tidak ada sinyal internet).',
            ),
            _buildFaqItem(
              'Bagaimana cara kerja fitur Alarm?',
              'Fitur alarm digunakan untuk membunyikan buzzer pada kacamata dari jarak jauh guna membantu menemukan pengguna. Tekan tombol "Activate Alarm", tunggu 15 detik proses sinkronisasi dengan server IoT, lalu alarm akan otomatis berbunyi.',
            ),
            _buildFaqItem(
              'Mengapa garis rute navigasi tidak muncul?',
              'Pastikan Anda sudah mengaktifkan GPS/Lokasi pada HP Anda. Fitur pembuatan rute membutuhkan koneksi internet yang stabil untuk mengunduh jalur terbaik dari server peta Google.',
            ),

            const SizedBox(height: 32),
            
            const Text(
              'HUBUNGI DEVELOPER',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
            ),
            const SizedBox(height: 16),

            // ==========================================
            // KARTU KONTAK DEVELOPER YANG BARU
            // ==========================================
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
                    'Apabila Anda mengalami kendala teknis, menemukan bug, atau membutuhkan panduan dalam menggunakan aplikasi ini, jangan ragu untuk menghubungi kami. Setiap saran dan masukan Anda sangat berharga untuk menjadikan aplikasi ini lebih baik ke depannya.',
                    style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.6),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(color: Color(0xFFF1F5F9), thickness: 2),
                  ),
                  
                  // Tombol Email
                  _buildActionContact(
                    icon: Icons.email_rounded,
                    color: const Color(0xFFEA4335),
                    title: 'Kirim Email',
                    subtitle: 'mdhimas25@gmail.com',
                    onTap: () {
                      _launchURL('mailto:mdhimas25@gmail.com?subject=Bantuan Aplikasi Sensational Glasses');
                    }
                  ),
                  const SizedBox(height: 16),
                  
                  // Tombol WhatsApp
                  _buildActionContact(
                    icon: Icons.chat_bubble_rounded,
                    color: const Color(0xFF25D366),
                    title: 'Chat WhatsApp',
                    subtitle: '+62 852-5669-4929',
                    onTap: () {
                      _launchURL('https://wa.me/6285256694929?text=Halo%20Dhimas,%20saya%20butuh%20bantuan%20terkait%20aplikasi%20Sensational%20Glasses.');
                    }
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(color: Color(0xFFF1F5F9), thickness: 2),
                  ),
                  
                  // Bagian Alamat
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.mint.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on, color: AppColors.mint, size: 20),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alamat', 
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Perum Tiara Permai 1, Jl. Sultan Agung, Karang Malang, Teluk, Kec. Purwokerto Sel., Kabupaten Banyumas, Jawa Tengah 53181',
                              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5)
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.mint,
          collapsedIconColor: Colors.grey,
          title: Text(
            question,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          children: [
            Text(
              answer,
              style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // Desain tombol aksi untuk Email dan WA
  Widget _buildActionContact({required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.5), size: 16),
          ],
        ),
      ),
    );
  }
}