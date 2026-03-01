import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:io';
import 'dart:math';
import '../controllers/home_controller.dart';
import '../controllers/auth_controller.dart';
import '../app/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final HomeController homeC = Get.find<HomeController>();
  final AuthController authC = Get.find<AuthController>();

  final TextEditingController firstNameC = TextEditingController();
  final TextEditingController lastNameC = TextEditingController();
  final TextEditingController emailC = TextEditingController(); // Field Baru
  final TextEditingController phoneC = TextEditingController();
  final TextEditingController birthDateC = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;

  String? _existingPhotoUrl;

  @override
  void initState() {
    super.initState();
    // Pisahkan nama dari userName user (bukan tunanetra)
    var nameParts = homeC.userName.value.split(" ");
    firstNameC.text = nameParts.isNotEmpty ? nameParts[0] : "";
    lastNameC.text = nameParts.length > 1 ? nameParts.sublist(1).join(" ") : "";

    emailC.text = homeC.userEmail.value;
    phoneC.text = homeC.userPhone.value;
    birthDateC.text = homeC.userBirthDate.value;

    // AMBIL URL FOTO DARI KOLEKSI 'users', BUKAN 'tunanetra_data'
    // Pastikan HomeController sudah memantau field 'photoUrl' di koleksi users
    _existingPhotoUrl = homeC.userPhotoUrl.value;
  }

  // Fitur Pilih Foto (Galeri & Kamera)
  // Fitur Pilih Foto (Galeri & Kamera)
  Future<void> _showImagePickerOptions() async {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        // Hapus baris 'color: Colors.white,' dari sini
        decoration: const BoxDecoration(
          color: Colors.white, // PINDAHKAN WARNA KE SINI
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.mint),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                _pickImage(ImageSource.gallery);
                Get.back();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.mint),
              title: const Text('Ambil Foto Kamera'),
              onTap: () {
                _pickImage(ImageSource.camera);
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(
      source: source,
      imageQuality: 50,
    );
    if (pickedFile != null)
      setState(() => _selectedImage = File(pickedFile.path));
  }

  // Simulasi Pengiriman OTP Nomor Telepon
  void _verifyPhoneNumber() {
    if (phoneC.text.isEmpty) {
      Get.snackbar(
        "Nomor Kosong",
        "Harap masukkan nomor telepon terlebih dahulu",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
        borderRadius: 10,
      );
      return;
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ikon Ilustrasi OTP
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.mint.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  color: AppColors.mint,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Verifikasi Nomor",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C2340),
                ),
              ),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(
                      text: "Kami akan mengirimkan kode OTP ke nomor ",
                    ),
                    TextSpan(
                      text: phoneC.text,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const TextSpan(text: " melalui WhatsApp atau SMS."),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Tombol Aksi
              Row(
                children: [
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
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        String otp = authC.generateOTP();
                        Get.back();
                        Get.snackbar(
                          "Memproses",
                          "Mengirim kode OTP...",
                          showProgressIndicator: true, 
                        );
                        bool isSent = await authC.sendWhatsAppOTP(
                          phoneC.text.trim(),
                          otp,
                        );
                        if (isSent) {
                          // Simpan OTP sementara di Firestore untuk divalidasi nanti
                          String uid = FirebaseAuth.instance.currentUser!.uid;
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .update({'temp_phone_otp': otp});
                          Get.snackbar(
                            "OTP Terkirim",
                            "Silakan cek pesan masuk Anda",
                            backgroundColor: AppColors.mint,
                            colorText: Colors.white,
                          );
                        } else {
                          Get.snackbar(
                            "Gagal",
                            "Gagal mengirim OTP. Pastikan nomor benar.",
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mint,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Kirim OTP",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false, // User harus memilih salah satu tombol
    );
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    String uid = FirebaseAuth.instance.currentUser!.uid;
    String? imageUrl;

    try {
      if (_selectedImage != null) {
        // 1. Simpan ke folder users_photo (Sesuai folder di Screenshot 15.01.52)
        Reference ref = FirebaseStorage.instance.ref().child(
          "users_photo/$uid.jpg",
        );
        await ref.putFile(_selectedImage!);
        imageUrl = await ref.getDownloadURL();

        // Bersihkan cache agar foto terbaru langsung muncul
        await DefaultCacheManager().removeFile(imageUrl);
      }

      // 2. Update koleksi 'users', JANGAN campur dengan 'tunanetra_data'
      await FirebaseFirestore.instance.collection("users").doc(uid).update({
        "firstName": firstNameC.text.trim(),
        "lastName": lastNameC.text.trim(),
        "phone": phoneC.text.trim(),
        "birthDate": birthDateC.text.trim(),
        // Gunakan field 'photoUrl' secara konsisten untuk user
        if (imageUrl != null) "photoUrl": imageUrl,
      });

      Get.back();
      Get.snackbar(
        "Berhasil",
        "Profil User diperbarui",
        backgroundColor: AppColors.mint,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Edit My Profile",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar Section
            Center(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.mint.withOpacity(0.2),
                        width: 4,
                      ),
                    ),
                    child: Obx(() {
                      // Ambil URL langsung dari memori controller
                      String userPhoto = homeC.userPhotoUrl.value;

                      return CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : (userPhoto.isNotEmpty)
                            ? CachedNetworkImageProvider(
                                "$userPhoto?t=${DateTime.now().millisecondsSinceEpoch}",
                              )
                            : const AssetImage('assets/default_profile.png')
                                  as ImageProvider, // 3. Default
                      );
                    }),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showImagePickerOptions,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.mint,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Form Fields
            _buildProfessionalField(
              "Nama Depan",
              firstNameC,
              Icons.person_outline,
            ),
            _buildProfessionalField(
              "Nama Belakang",
              lastNameC,
              Icons.person_outline,
            ),
            _buildProfessionalField(
              "Email",
              emailC,
              Icons.email_outlined,
              isReadOnly: true,
            ),

            // Nomor Telepon dengan Tombol Verifikasi
            _buildPhoneField(),

            // Di dalam Column pada widget build
            _buildProfessionalField(
              "Tanggal Lahir",
              birthDateC,
              Icons.calendar_today_outlined,
              onTap: _pickDate, // Panggil fungsi kalender saat diklik
              isReadOnly: true, // Mencegah keyboard muncul
            ),

            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mint,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Simpan Perubahan",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Tambahkan di dalam class _UserProfilePageState
  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.mint,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      // Format tanggal sesuai keinginan (dd/MM/yyyy)
      String formattedDate =
          "${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}";
      setState(() {
        birthDateC.text = formattedDate;
      });
    }
  }

  Widget _buildProfessionalField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isReadOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: isReadOnly,
          onTap: onTap, // Menjalankan fungsi saat field di-klik
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: AppColors.mint),
            filled: true,
            fillColor: isReadOnly
                ? Colors.grey[50]
                : Colors.white, // Warna sedikit beda jika readOnly
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.mint, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Nomor Telepon",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: phoneC,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.phone_android,
              size: 20,
              color: AppColors.mint,
            ),
            suffixIcon: TextButton(
              onPressed: _verifyPhoneNumber,
              child: const Text(
                "Verifikasi",
                style: TextStyle(
                  color: AppColors.mint,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.mint, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
