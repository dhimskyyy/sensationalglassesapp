import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeController extends GetxController {
  var signal = "Wait...".obs;
  var battery = "0".obs;
  var distance = "0".obs;

  var latitude = 0.0.obs;
  var longitude = 0.0.obs;
  
  var userName = "User".obs;
  var tunanetraData = <String, dynamic>{}.obs;
  var hasTunanetraData = false.obs;

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

  Future<void> fetchThingSpeakData(String id, String key) async {
    try {
      final url = "https://api.thingspeak.com/channels/$id/feeds.json?api_key=$key&results=1";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['feeds'] != null && data['feeds'].isNotEmpty) {
          final lastFeed = data['feeds'][0];
          signal.value = lastFeed['field1'] ?? "N/A";
          battery.value = lastFeed['field2'] ?? "0";
          distance.value = lastFeed['field3'] ?? "0";
          latitude.value = double.tryParse(lastFeed['field4']?.toString() ?? "0.0") ?? 0.0;
          longitude.value = double.tryParse(lastFeed['field5']?.toString() ?? "0.0") ?? 0.0;

          print("Update Lokasi: ${latitude.value}, ${longitude.value}");
        }
      }
    } catch (e) {
      print("Error fetching IoT data: $e");
    }
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