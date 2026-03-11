import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class HomeController extends GetxController {
  var signal = "0 dBm".obs;
  var battery = "0".obs;
  var distance = "0".obs;

  var latitude = 0.0.obs;
  var longitude = 0.0.obs;

  var iotStatus = "0 dBm".obs; // Untuk menampung "Active Now", "Off", atau "Lowbat"
  var isDeviceOff = false.obs; // Helper untuk status sinyal

  var userName = "User".obs;
  var userPhone = "".obs;
  var userBirthDate = "".obs;
  var userEmail = "".obs;
  
  var tunanetraData = <String, dynamic>{}.obs;
  var hasTunanetraData = false.obs;

  var userPhotoUrl = "".obs;

  var isAlarmProcessing = false.obs;

  Timer? _timer;
  StreamSubscription? _iotSubscription;
  StreamSubscription? _userSubscription;

  @override
  void onInit() {
    super.onInit();
    setupRealtimeProfile();
    setupRealtimeIoT();
  }

  void setupRealtimeProfile() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Monitor Data Admin/User
    _userSubscription = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        var data = doc.data();
        userName.value = "${data?['firstName'] ?? ''} ${data?['lastName'] ?? ''}".trim();
        userEmail.value = data?['email'] ?? user.email ?? "";
        userPhone.value = data?['phone'] ?? "";
        userBirthDate.value = data?['birthDate'] ?? "";
        userPhotoUrl.value = data?['photoUrl'] ?? "";
      }
    });

    // Monitor Data Tunanetra (Termasuk Foto)
    FirebaseFirestore.instance
        .collection("tunanetra_data")
        .doc(user.uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data() != null) {
        tunanetraData.value = doc.data()!;
        hasTunanetraData.value = true;
      } else {
        hasTunanetraData.value = false;
      }
    });
  }

  void setupRealtimeIoT() {    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String uid = user.uid;
    
    // Simpan subscription ke dalam variabel agar bisa di-cancel
    _iotSubscription = FirebaseFirestore.instance        
        .collection("tunanetra_data")
        .doc(uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        String channelID = doc.data()?['thingspeak_channel_id'] ?? "";
        String readKey = doc.data()?['thingspeak_read_key'] ?? "";

        if (channelID.isNotEmpty && readKey.isNotEmpty) {
          // Reset timer jika user mengganti alat/konfigurasi
          _timer?.cancel();
          
          // Ambil data pertama kali
          fetchThingSpeakData(channelID, readKey);
          
          // Jalankan interval 15 detik
          _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
            fetchThingSpeakData(channelID, readKey);
          });
        }
      }
    }, onError: (error) {
      // Tangani error secara halus agar tidak crash
      print("Firestore Stream Error: $error");
    });
  }

  // Tambahkan fungsi ini di dalam class HomeController
void resetIoTData() {
  // Hentikan timer dan subscription aktif
  _timer?.cancel();
  _iotSubscription?.cancel();
  
  // Reset nilai IoT ke default
  signal.value = "0 dBm";
  battery.value = "0";
  distance.value = "0";
  latitude.value = 0.0;
  longitude.value = 0.0;
  
  // Reset status data tunanetra
  hasTunanetraData.value = false;
  tunanetraData.clear();
  
  print("IoT Data has been reset successfully.");
}

  Future<void> fetchThingSpeakData(String id, String key) async {
  try {
    final url = "https://api.thingspeak.com/channels/$id/feeds.json?api_key=$key&results=1";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['feeds'] != null && data['feeds'].isNotEmpty) {
        final lastFeed = data['feeds'][0];
        
        // --- LOGIKA CEK ALAT MATI (TIMEOUT) ---
        DateTime lastUpdate = DateTime.parse(lastFeed['created_at']).toLocal();
        DateTime now = DateTime.now();
        // Jika selisih waktu sekarang dengan data terakhir > 45 detik (interval kirim 15s + toleransi)
        bool timedOut = now.difference(lastUpdate).inSeconds > 45;

        double devLat = double.tryParse(lastFeed['field1']?.toString() ?? "0.0") ?? 0.0;
        double devLng = double.tryParse(lastFeed['field2'] ?? "0.0") ?? 0.0;
        int batteryVal = int.tryParse(lastFeed['field4']?.toString() ?? "0") ?? 0;

        // 1. Update Lokasi & Jarak (Hanya jika alat nyala, kalau mati biarkan data terakhir)
        if (!timedOut) {
          latitude.value = devLat;
          longitude.value = devLng;
          calculateRealDistance(devLat, devLng);
          
          // 2. Update Sinyal & Baterai
          signal.value = "${lastFeed['field3'] ?? '0'} dBm";
          battery.value = batteryVal.toString();
          isDeviceOff.value = false;

          // 3. Update Status Text (Active vs Lowbat)
          if (batteryVal <= 30) {
            iotStatus.value = "Lowbat";
          } else {
            iotStatus.value = "Active Now";
          }
        } else {
          // KONDISI ALAT MATI / TIMEOUT
          isDeviceOff.value = true;
          iotStatus.value = "Off";
          signal.value = "0 dBm";
          // Distance & Battery tidak diupdate (menampilkan data terakhir)
        }
      }
    }
  } catch (e) {
    print("Error: $e");
  }
}

// Fungsi tambahan untuk menghitung jarak asli
Future<void> calculateRealDistance(double devLat, double devLng) async {
  try {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Cek apakah GPS di HP aktif
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Layanan lokasi tidak aktif.");
      return;
    }

    // 2. Cek status izin saat ini
    permission = await Geolocator.checkPermission();
    
    // 3. Jika izin ditolak, minta izin baru ke user
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Izin lokasi ditolak oleh pengguna.");
        return;
      }
    }

    // 4. Jika izin ditolak selamanya (lewat settings)
    if (permission == LocationPermission.deniedForever) {
      print("Izin lokasi ditolak secara permanen.");
      return;
    }

    // 5. Jika semua OK, baru ambil posisi
    Position userPos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    
    double distanceInMeters = Geolocator.distanceBetween(
      userPos.latitude, userPos.longitude, devLat, devLng
    );
    
    distance.value = distanceInMeters.toStringAsFixed(1);
    
  } catch (e) {
    print("Error pada kalkulasi jarak: $e");
  }
}

  // Di dalam home_controller.dart

Future<void> triggerAlarm() async {
  if (isAlarmProcessing.value) return;
  isAlarmProcessing.value = true;
  // Gunakan Write API Key Anda
  final String writeApiKey = "09IMFFDQ04DHUK5C"; 
  
  // URL untuk menyalakan (Field 5 = 1)
  final urlOn = Uri.parse("https://api.thingspeak.com/update?api_key=$writeApiKey&field5=1");
  // URL untuk mematikan (Field 5 = 0)
  final urlOff = Uri.parse("https://api.thingspeak.com/update?api_key=$writeApiKey&field5=0");

  try {
    // 1. KIRIM PERINTAH NYALA
    final responseOn = await http.get(urlOn);

    if (responseOn.statusCode == 200) {
      Get.snackbar(
        "Alarm Aktif",
        "Alarm akan berbunyi selama 5 detik",
        backgroundColor: const Color(0xFF66C7AA),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // 2. TUNGGU 5 DETIK
      await Future.delayed(const Duration(seconds: 5));

      // 3. KIRIM PERINTAH MATI SECARA OTOMATIS
      final responseOff = await http.get(urlOff);
      
      if (responseOff.statusCode == 200) {
        print("Alarm berhasil dimatikan otomatis");
      }
    } else {
      throw Exception("Gagal terhubung ke ThingSpeak");
    }
  } catch (e) {
    Get.snackbar(
      "Error",
      "Gagal mengontrol alarm: $e",
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
  isAlarmProcessing.value = false;
}

  void stopMonitoring() {
  _timer?.cancel();
  _iotSubscription?.cancel();
  _userSubscription?.cancel(); // Pindahkan ke sini agar sekalian berhenti
  print("Semua monitoring (IoT & Profil) berhasil dihentikan");
}

@override
void onClose() {
  stopMonitoring(); // Cukup panggil fungsi ini saja
  super.onClose();
}

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    return FirebaseFirestore.instance.collection("users").doc(user.uid).snapshots();
  }
}