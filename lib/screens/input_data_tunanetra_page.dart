import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import 'package:sensationalglassesapp/app/theme/app_colors.dart';
import 'package:sensationalglassesapp/controllers/home_controller.dart';

class InputDataTunanetraPage extends StatefulWidget {
  const InputDataTunanetraPage({super.key});

  @override
  State<InputDataTunanetraPage> createState() => _InputDataTunanetraPageState();
}

class _InputDataTunanetraPageState extends State<InputDataTunanetraPage> {
  // Controller Ditambah untuk menyesuaikan field gambar
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController bloodTypeController = TextEditingController();
  final TextEditingController birthPlaceController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();

  // Controller IOT Tetap
  final TextEditingController thingSpeakChannelController =
      TextEditingController();
  final TextEditingController thingSpeakReadKeyController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _isObscureChannel = true;
  bool _isObscureKey = true;
  bool _isSaving = false;

  File? _selectedImage;
  String? _existingFotoUrl;

  String _generateIdNumber(String name, String birthDate) {
    List<String> nameParts = name.trim().split(' ');
    String initials = "";
    if (nameParts.length >= 2) {
      initials = (nameParts[0][0] + nameParts[1][0]).toUpperCase();
    } else if (nameParts.isNotEmpty) {
      initials = nameParts[0][0].toUpperCase();
    }

    // 2. Ambil Angka dari Tanggal Lahir
    String dateNumbers = birthDate.replaceAll(RegExp(r'[^0-9]'), '');

    // Jika pembersihan angka gagal/kosong, gunakan default
    if (dateNumbers.isEmpty) dateNumbers = "00000000";

    // 3. Tambahkan nomor urut/acak (Contoh: 001)
    String randomSuffix = "001";

    return "$dateNumbers-$initials-$randomSuffix";
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF66C7AA),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        birthDateController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(
      source: source,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
    Get.back();
  }

  void _showPicker(context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Kamera'),
                onTap: () => _pickImage(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Hapus Foto',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  setState(() {
                    _selectedImage = null;
                    _existingFotoUrl = null;
                  });
                  Get.back();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    // Menjalankan fungsi pengisian data setelah frame pertama dirender
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fillDataIfAvailable();
    });
  }

  void _fillDataIfAvailable() {
    // Mengambil arguments yang dikirim dari halaman ID Card
    var data = Get.arguments;

    if (data != null && data is Map<String, dynamic>) {
      setState(() {
        nameController.text = data['nama_tunanetra'] ?? "";
        ageController.text = data['usia'] ?? "";
        bloodTypeController.text = data['golongan_darah'] ?? "";

        // Handle split fields: try individual fields first, then fallback to combined
        if (data['tempat_lahir'] != null && data['tempat_lahir'] != "") {
          birthPlaceController.text = data['tempat_lahir'];
        } else if (data['tempat_tanggal_lahir'] != null) {
          // Fallback: parse from combined field (e.g. "Jakarta, 14 Agustus 1995")
          String combined = data['tempat_tanggal_lahir'] ?? "";
          if (combined.contains(',')) {
            birthPlaceController.text = combined.split(',')[0].trim();
            birthDateController.text = combined.split(',').sublist(1).join(',').trim();
          } else {
            birthPlaceController.text = combined;
          }
        }

        if (data['tanggal_lahir'] != null && data['tanggal_lahir'] != "") {
          birthDateController.text = data['tanggal_lahir'];
        }

        // Mengisi data IoT jika tersedia
        thingSpeakChannelController.text = data['thingspeak_channel_id'] ?? "";
        thingSpeakReadKeyController.text = data['thingspeak_read_key'] ?? "";

        _existingFotoUrl = data['foto_url'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF66C7AA);
    return GestureDetector(
      onTap: () => FocusScope.of(
        context,
      ).unfocus(), // Ini untuk menghilangkan fokus saat klik di mana saja
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
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
            "Data Tunanetra & Alat",
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // 1. Header Profil
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryColor, width: 2),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: // Ganti widget CircleAvatar di dalam stack Header Profil
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        child: ClipOval(
                          child: _selectedImage != null
                              ? Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                  width: 120,
                                  height: 120,
                                )
                              : (_existingFotoUrl != null &&
                                    _existingFotoUrl!.isNotEmpty)
                              ? CachedNetworkImage(
                                  imageUrl: _existingFotoUrl!,
                                  fit: BoxFit.cover,
                                  width: 120,
                                  height: 120,
                                  // Placeholder transparan agar tidak ada "kedipan" putih/default
                                  placeholder: (context, url) =>
                                      Container(color: Colors.transparent),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                )
                              : Image.asset(
                                  'assets/default_profile.png',
                                  fit: BoxFit.cover,
                                  width: 120,
                                  height: 120,
                                ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showPicker(context),
                      child: Container(
                        height: 35,
                        width: 35,
                        decoration: const BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  "Data Personal Tunanetra",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const Text(
                  "Informasi identitas pengguna perangkat",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // 2. INPUT FIELDS (Disesuaikan dengan Gambar Referensi)

                // Kolom Nama Lengkap (Full Width)
                _buildModernTextField(
                  controller: nameController,
                  label: "Nama Lengkap",
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 20),

                // Row untuk Usia dan Golongan Darah (Sejajar)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildModernTextField(
                        controller: ageController,
                        label: "Usia",
                        icon: Icons.cake_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildModernTextField(
                        controller: bloodTypeController,
                        label: "Golongan Darah",
                        icon: Icons.water_drop_outlined,
                        autoUpperCase: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Row untuk Tempat Lahir dan Tanggal Lahir (Sejajar)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildModernTextField(
                        controller: birthPlaceController,
                        label: "Tempat Lahir",
                        icon: Icons.location_on_outlined,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildModernTextField(
                        controller: birthDateController,
                        label: "Tanggal Lahir",
                        icon: Icons.calendar_today_outlined,
                        readOnly: true,
                        onTap: _pickDate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

const Align(
  alignment: Alignment.centerLeft,
  child: Text(
    "Konfigurasi Alat",
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.blueGrey,
    ),
  ),
),
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: thingSpeakChannelController,
                  label: "ThingSpeak Channel ID",
                  icon: Icons.router_outlined,
                  keyboardType: TextInputType.number,
                  obscureText: _isObscureChannel, // Gunakan variabel state
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscureChannel
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscureChannel = !_isObscureChannel;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),
                _buildModernTextField(
                  controller: thingSpeakReadKeyController,
                  label: "Read API Key",
                  icon: Icons.vpn_key_outlined,
                  obscureText: _isObscureKey, // Gunakan variabel state
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscureKey ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscureKey = !_isObscureKey;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 48),

                // 3. Tombol Simpan
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : () {
                      if (_formKey.currentState!.validate()) {
                        _saveData();
                      } else {
                        // Jika ada yang kosong, munculkan pesan/pop-up
                        Get.snackbar(
                          "Data Belum Lengkap",
                          "Silakan isi semua kolom yang tersedia sebelum melanjutkan.",
                          backgroundColor: AppColors.error,
                          colorText: Colors.white,
                          icon: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.white,
                          ),
                          snackPosition: SnackPosition.TOP,
                          duration: const Duration(seconds: 3),
                          margin: const EdgeInsets.all(15),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Simpan & Hubungkan",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool autoUpperCase = false,
    bool obscureText = false,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(fontSize: 15),
          onChanged: (value) {
            if (autoUpperCase) {
              controller.value = controller.value.copyWith(
                text: value.toUpperCase(),
                selection: TextSelection.collapsed(offset: value.length),
              );
            }
          },
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF66C7AA), size: 22),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 20,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF66C7AA),
                width: 1.5,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Bidang ini tidak boleh kosong";
            }
            return null;
          },
        ),
      ],
    );
  }

  // LOGIKA SIMPAN (Disesuaikan dengan Field Baru)
  Future<void> _saveData() async {
    setState(() => _isSaving = true);
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      // Validate ThingSpeak credentials before saving
      String channelId = thingSpeakChannelController.text.trim();
      String readKey = thingSpeakReadKeyController.text.trim();

      bool isValid = await validateThingSpeakCredentials(channelId, readKey);
      if (!isValid) {
        setState(() => _isSaving = false);
        Get.snackbar(
          "Data ThingSpeak Salah",
          "Silakan masukkan data ThingSpeak dengan benar.",
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          icon: const Icon(Icons.error_outline, color: Colors.white),
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
          margin: const EdgeInsets.all(15),
        );
        return;
      }

      String? finalFotoUrl = _existingFotoUrl;

      if (_selectedImage != null) {
        Reference ref = FirebaseStorage.instance.ref().child(
          "profile_tunanetra/$uid.jpg",
        );
        UploadTask uploadTask = ref.putFile(_selectedImage!);
        TaskSnapshot snapshot = await uploadTask;
        finalFotoUrl = await snapshot.ref.getDownloadURL();
      }

      // Cek apakah ini data baru atau edit
      var existingData = Get.arguments;
      String idNumber;

      // Combine birth place and date for backward compatibility
      String combinedBirthPlaceDate = "${birthPlaceController.text}, ${birthDateController.text}";

      if (existingData != null && existingData['id_number'] != null) {
        // Jika edit, gunakan ID yang sudah ada
        idNumber = existingData['id_number'];
      } else {
        // Jika data baru, buat ID otomatis
        idNumber = _generateIdNumber(
          nameController.text,
          birthDateController.text,
        );
      }

      await FirebaseFirestore.instance
          .collection("tunanetra_data")
          .doc(uid)
          .set({
            "id_number": idNumber,
            "nama_tunanetra": nameController.text,
            "usia": ageController.text,
            "golongan_darah": bloodTypeController.text,
            "tempat_lahir": birthPlaceController.text,
            "tanggal_lahir": birthDateController.text,
            "tempat_tanggal_lahir": combinedBirthPlaceDate,
            "foto_url": finalFotoUrl,
            "thingspeak_channel_id": channelId,
            "thingspeak_read_key": readKey,
            "updated_at": FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      setState(() => _isSaving = false);

      Get.snackbar(
        "Berhasil",
        "Data berhasil diperbarui",
        backgroundColor: const Color(0xFF66C7AA),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(20),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (Navigator.canPop(context)) {
          Navigator.pop(
            context,
          ); // Kembali ke Home Screen tanpa menghapus state
        } else {
          Get.offAllNamed('/main'); // Fallback jika stack hilang
        }
      });
    } catch (e) {
      setState(() => _isSaving = false);
      Get.snackbar(
        "Error",
        "Gagal menyimpan: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
