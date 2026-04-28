import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:io';
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
  final TextEditingController emailC = TextEditingController();
  final TextEditingController phoneC = TextEditingController();
  final TextEditingController birthDateC = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;
  String? _existingPhotoUrl;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;

    var nameParts = homeC.userName.value.split(" ");
    firstNameC.text = nameParts.isNotEmpty ? nameParts[0] : "";
    lastNameC.text = nameParts.length > 1 ? nameParts.sublist(1).join(" ") : "";

    // MENGAMBIL EMAIL DENGAN CARA PALING AGRESIF
    String validEmail = user?.email ?? "";
    if (validEmail.isEmpty && user != null) {
      for (var provider in user.providerData) {
        if (provider.email != null && provider.email!.isNotEmpty) {
          validEmail = provider.email!;
          break;
        }
      }
    }
    if (validEmail.isEmpty) validEmail = homeC.userEmail.value;
    
    emailC.text = validEmail;

    // Pasang listener tambahan jaga-jaga jika databasenya telat
    ever(homeC.userEmail, (String emailDB) {
      if (emailC.text.isEmpty && emailDB.isNotEmpty) {
        emailC.text = emailDB;
      }
    });

    phoneC.text = homeC.userPhone.value;
    birthDateC.text = homeC.userBirthDate.value;

    _existingPhotoUrl = homeC.userPhotoUrl.value;
  }

  Future<void> _showImagePickerOptions() async {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
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
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    String uid = FirebaseAuth.instance.currentUser!.uid;
    String? imageUrl;

    try {
      if (_selectedImage != null) {
        Reference ref = FirebaseStorage.instance.ref().child("users_photo/$uid.jpg");
        await ref.putFile(_selectedImage!);
        imageUrl = await ref.getDownloadURL();
        await DefaultCacheManager().removeFile(imageUrl);
      }

      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "firstName": firstNameC.text.trim(),
        "lastName": lastNameC.text.trim(),
        "phone": phoneC.text.trim(),
        "birthDate": birthDateC.text.trim(),
        if (imageUrl != null) "photoUrl": imageUrl,
      }, SetOptions(merge: true));

      Get.back();
      Get.snackbar(
        "Berhasil",
        "Profil User diperbarui",
        backgroundColor: AppColors.mint,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar("Error", e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
    } finally {
      setState(() => _isLoading = false);
    }
  }

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
      String formattedDate = "${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}";
      setState(() {
        birthDateC.text = formattedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
    onTap: () => FocusScope.of(context).unfocus(),
    child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Edit Profil',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.mint.withOpacity(0.2), width: 4),
                    ),
                    child: Obx(() {
                      String userPhoto = homeC.userPhotoUrl.value;
                      return CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : (userPhoto.isNotEmpty)
                                ? CachedNetworkImageProvider(userPhoto)
                                : const AssetImage('assets/default_profile.png') as ImageProvider,
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
                        decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
                        child: const Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            _buildProfessionalField("Nama Depan", firstNameC, Icons.person_outline),
            _buildProfessionalField("Nama Belakang", lastNameC, Icons.person_outline),
            
            // Email dibuat readOnly agar abu-abu dan tidak bisa diedit
            _buildProfessionalField("Email", emailC, Icons.email_outlined, isReadOnly: true),

            _buildProfessionalField("Nomor Telepon", phoneC, Icons.phone_android, keyboardType: TextInputType.phone),
            
            // Tanggal Lahir di-set readOnly, TAPI dipaksa berwarna putih menggunakan parameter baru
            _buildProfessionalField(
              "Tanggal Lahir", 
              birthDateC, 
              Icons.calendar_today_outlined, 
              onTap: _pickDate, 
              isReadOnly: true,
              overrideFillColor: Colors.white,
            ),

            const SizedBox(height: 10),
          
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mint,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Simpan Perubahan", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  // WIDGET SUDAH DITAMBAHKAN PARAMETER overrideFillColor
  Widget _buildProfessionalField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isReadOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    Color? overrideFillColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: isReadOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: AppColors.mint),
            filled: true,
            // Logika Warna: Jika ada override, pakai itu. Jika tidak, cek apakah readOnly (abu-abu) atau normal (putih)
            fillColor: overrideFillColor ?? (isReadOnly ? Colors.grey[50] : Colors.white),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.mint, width: 2)),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}