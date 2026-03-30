import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:convert';
import 'package:mobile_scanner/mobile_scanner.dart';

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
  final TextEditingController birthPlaceDateController = TextEditingController();

  // Controller IOT Tetap
  final TextEditingController thingSpeakChannelController = TextEditingController();
  final TextEditingController thingSpeakReadKeyController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _isObscureChannel = true;
  bool _isObscureKey = true;
  
  File? _selectedImage;
  String? _existingFotoUrl;

  String _generateIdNumber(String name, String birthDate) {
  // 1. Ambil Inisial Nama (Contoh: Budi Setiawan -> BS)
  List<String> nameParts = name.trim().split(' ');
  String initials = "";
  if (nameParts.length >= 2) {
    initials = (nameParts[0][0] + nameParts[1][0]).toUpperCase();
  } else if (nameParts.isNotEmpty) {
    initials = nameParts[0][0].toUpperCase();
  }

  // 2. Ambil Angka dari Tanggal Lahir (Contoh: 14 Agustus 1995 -> 14081995)
  // Kita asumsikan format input user mengandung angka tanggal-bulan-tahun
  String dateNumbers = birthDate.replaceAll(RegExp(r'[^0-9]'), '');
  
  // Jika pembersihan angka gagal/kosong, gunakan default
  if (dateNumbers.isEmpty) dateNumbers = "00000000";

  // 3. Tambahkan nomor urut/acak (Contoh: 001)
  String randomSuffix = "001"; 

  return "$dateNumbers-$initials-$randomSuffix";
}

  Future<void> _pickImage(ImageSource source) async {
  final pickedFile = await ImagePicker().pickImage(source: source, imageQuality: 50);
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
              title: const Text('Hapus Foto', style: TextStyle(color: Colors.red)),
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

  void _prosesDataDariQR(String rawCode) {
  try {
    Map<String, dynamic> data = jsonDecode(rawCode);

    // Validasi apakah key 'id' dan 'key' ada di dalam JSON
    if (data.containsKey('id') && data.containsKey('key')) {
      setState(() {
        thingSpeakChannelController.text = data['id'].toString();
        thingSpeakReadKeyController.text = data['key'].toString();
      });

      Get.snackbar(
        "Alat Terdeteksi",
        "Konfigurasi alat berhasil dimuat.",
        backgroundColor: const Color(0xFF66C7AA),
        colorText: Colors.white,
      );
    } else {
      throw Exception("Data tidak lengkap");
    }
  } catch (e) {
    Get.snackbar(
      "Format Salah",
      "Gunakan QR Code khusus alat IoT (Key 'id' & 'key' tidak ditemukan).",
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}

void _bukaScannerKamera() {
  // Inisialisasi controller secara spesifik
  final MobileScannerController scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    formats: [BarcodeFormat.qrCode], // FOKUS: Hanya scan QR Code
    detectionTimeoutMs: 1000, // Beri jeda 1 detik antar deteksi agar tidak lag
  );

  Get.to(() => Scaffold(
    appBar: AppBar(
      title: const Text("Posisikan QR di Dalam Kotak"),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          scannerController.dispose(); // Pastikan dispose saat keluar
          Get.back();
        },
      ),
    ),
    body: Stack(
      children: [
        MobileScanner(
          controller: scannerController,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              final String? code = barcodes.first.displayValue ?? barcodes.first.rawValue;
              
              if (code != null) {
                // Matikan scanner segera setelah terdeteksi agar tidak looping
                scannerController.stop(); 
                _prosesDataDariQR(code);
                
                // Beri sedikit delay sebelum pindah halaman agar snackbar muncul
                Future.delayed(const Duration(milliseconds: 500), () {
                  scannerController.dispose();
                  Get.back();
                });
              }
            }
          },
        ),
        // OVERLAY KOTAK
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF66C7AA), width: 4),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    ),
  ));
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
      birthPlaceDateController.text = data['tempat_tanggal_lahir'] ?? "";
      
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
        ? Image.file(_selectedImage!, fit: BoxFit.cover, width: 120, height: 120)
        : (_existingFotoUrl != null && _existingFotoUrl!.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: _existingFotoUrl!,
                fit: BoxFit.cover,
                width: 120,
                height: 120,
                // Placeholder transparan agar tidak ada "kedipan" putih/default
                placeholder: (context, url) => Container(color: Colors.transparent),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              )
            : Image.asset(
                'assets/default_profile.png', 
                fit: BoxFit.cover, 
                width: 120, 
                height: 120
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
                  hint: "Contoh: Budi Setiawan",
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
                        hint: "28",
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildModernTextField(
                        controller: bloodTypeController,
                        label: "Golongan Darah",
                        icon: Icons.water_drop_outlined,
                        hint: "O",
                        autoUpperCase: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Kolom Tempat, Tanggal Lahir (Full Width)
                _buildModernTextField(
                  controller: birthPlaceDateController,
                  label: "Tempat, Tanggal Lahir",
                  icon: Icons.location_on_outlined,
                  hint: "Bandung, 14 Agustus 1995",
                ),
                const SizedBox(height: 32),

                // Bagian Konfigurasi IOT
                Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Text(
      "Konfigurasi Alat",
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
    ),
    TextButton.icon(
      onPressed: () => _bukaScannerKamera(),
      icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF66C7AA)),
      label: const Text("Scan QR", style: TextStyle(color: Color(0xFF66C7AA))),
    ),
  ],
),
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: thingSpeakChannelController,
                  label: "ThingSpeak Channel ID",
                  icon: Icons.router_outlined,
                  hint: "Contoh: 3239717",
                  keyboardType: TextInputType.number,
                  obscureText: _isObscureChannel, // Gunakan variabel state
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscureChannel ? Icons.visibility_off : Icons.visibility,
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
                  hint: "Masukkan API Key",
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
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _saveData();
                      } else {
                        // Jika ada yang kosong, munculkan pesan/pop-up
                        Get.snackbar(
                          "Data Belum Lengkap",
                          "Silakan isi semua kolom yang tersedia sebelum melanjutkan.",
                          backgroundColor: Colors.orangeAccent,
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
                    child: const Row(
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
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool autoUpperCase = false,
    bool obscureText = false, // <-- TAMBAHKAN PARAMETER INI
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
          obscureText: obscureText, // <-- TERAPKAN DI SINI
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
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
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
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;      
      String? finalFotoUrl = _existingFotoUrl;

      if (_selectedImage != null) {
      Reference ref = FirebaseStorage.instance.ref().child("profile_tunanetra/$uid.jpg");
      UploadTask uploadTask = ref.putFile(_selectedImage!);
      TaskSnapshot snapshot = await uploadTask;
      finalFotoUrl = await snapshot.ref.getDownloadURL();
    }

      // Cek apakah ini data baru atau edit
    var existingData = Get.arguments;
    String idNumber;

    if (existingData != null && existingData['id_number'] != null) {
      // Jika edit, gunakan ID yang sudah ada
      idNumber = existingData['id_number'];
    } else {
      // Jika data baru, buat ID otomatis
      idNumber = _generateIdNumber(nameController.text, birthPlaceDateController.text);
    }

      await FirebaseFirestore.instance
          .collection("tunanetra_data")
          .doc(uid)
          .set({
            "id_number": idNumber,
            "nama_tunanetra": nameController.text,
            "usia": ageController.text,
            "golongan_darah": bloodTypeController.text, // Field baru
            "tempat_tanggal_lahir": birthPlaceDateController.text, // Field baru
            "foto_url": finalFotoUrl,
            "thingspeak_channel_id": thingSpeakChannelController.text,
            "thingspeak_read_key": thingSpeakReadKeyController.text,
            "updated_at": FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

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
    Navigator.pop(context); // Kembali ke Home Screen tanpa menghapus state
  } else {
    Get.offAllNamed('/main'); // Fallback jika stack hilang
  }
});
    } catch (e) {
      Get.snackbar(
        "Error",
        "Gagal menyimpan: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
