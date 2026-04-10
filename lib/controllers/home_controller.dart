import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../screens/maps.dart';

enum AlarmState { idle, loadingOn, countdown, active, loadingOff }

class HomeController extends GetxController {
  var signal = "0 dBm".obs;
  var battery = "0".obs;
  var distance = "0".obs;

  var latitude = 0.0.obs;
  var longitude = 0.0.obs;

  var iotStatus = "0 dBm".obs; 
  var isDeviceOff = false.obs; 

  var userName = "User".obs;
  var userPhone = "".obs;
  var userBirthDate = "".obs;
  var userEmail = "".obs;
  
  var tunanetraData = <String, dynamic>{}.obs;
  var hasTunanetraData = false.obs;

  var userPhotoUrl = "".obs;

  var alarmState = AlarmState.idle.obs;
  var countdownTimer = 15.obs;

  var polylines = <Polyline>{}.obs;
  var isShowingRoute = false.obs;
  var isLoadingRoute = false.obs;
  var selectedTravelMode = TravelMode.driving.obs;

  Timer? _timer;
  StreamSubscription? _iotSubscription;
  StreamSubscription? _userSubscription;
  StreamSubscription? _stopSubscription;

  // ============================================
  // VARIABEL NOTIFIKASI (Mencegah Spam)
  // ============================================
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  bool _notifiedDist5 = false;
  bool _notifiedDist8 = false;
  bool _notifiedDist10 = false;
  
  bool _notifiedBat50 = false;
  bool _notifiedBat30 = false;
  bool _notifiedBat20 = false;
  bool _notifiedDeviceOff = false;

  @override
  void onInit() {
    super.onInit();
    _initNotifications(); // Aktifkan sistem notifikasi
    setupRealtimeProfile();
    setupRealtimeIoT();
  }

  // ============================================
  // INISIALISASI NOTIFIKASI
  // ============================================
  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notif_sensational_logo');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
        
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // JIKA NOTIFIKASI DIKLIK -> LANGSUNG KE MAPS
        Get.to(() => const MapsScreen());
      },
    );

    // Meminta izin notifikasi (Wajib untuk Android 13+)
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  // ============================================
  // FUNGSI MEMUNCULKAN POP-UP & SIMPAN KE FIRESTORE
  // ============================================
  Future<void> _triggerNotification(String type, String title, String message, String level) async {
    // 1. Munculkan Pop-up di HP
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'tracker_alerts', 'Peringatan Sensational Glasses',
      channelDescription: 'Notifikasi jarak dan baterai dari perangkat kacamata.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: 'ic_notif_sensational_logo',
      color: const Color(0xFF70CAB0),
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      message,
      platformChannelSpecifics,
    );

    // 2. Simpan Permanen ke Database Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("notifications")
          .add({
        "type": type,
        "title": title,
        "message": message,
        "level": level,
        "timestamp": FieldValue.serverTimestamp(),
        "isRead": false,
      });
    }
  }

  // ============================================
  // LOGIKA PENDETEKSI SPAM
  // ============================================
  void _checkAlerts(double distInKm, int batVal, bool isOff) {
    // A. CEK BATERAI / STATUS MATI
    if (isOff) {
      if (!_notifiedDeviceOff) {
        _triggerNotification('battery', 'Perangkat Mati / Offline', 'Kacamata Sensational Glasses kehabisan daya atau kehilangan sinyal.', 'danger');
        _notifiedDeviceOff = true;
      }
    } else {
      _notifiedDeviceOff = false; // Reset jika online lagi

      if (batVal <= 20 && !_notifiedBat20) {
        _triggerNotification('battery', 'Baterai Kritis 20%', 'Perangkat segera mati. Segera hubungi pengguna!', 'danger');
        _notifiedBat20 = true;
      } else if (batVal > 20) { _notifiedBat20 = false; }

      if (batVal <= 30 && !_notifiedBat30 && batVal > 20) {
        _triggerNotification('battery', 'Baterai Lemah 30%', 'Kapasitas baterai perangkat memasuki mode lowbat.', 'warning');
        _notifiedBat30 = true;
      } else if (batVal > 30) { _notifiedBat30 = false; }

      if (batVal <= 50 && !_notifiedBat50 && batVal > 30) {
        _triggerNotification('battery', 'Baterai Tersisa 50%', 'Kapasitas baterai perangkat tinggal setengah.', 'info');
        _notifiedBat50 = true;
      } else if (batVal > 50) { _notifiedBat50 = false; }
    }

    // B. CEK JARAK
    if (distInKm >= 10.0 && !_notifiedDist10) {
      _triggerNotification('distance', 'Peringatan Jarak (> 10 km)', 'Pengguna telah berada sangat jauh melebihi 10 km.', 'danger');
      _notifiedDist10 = true;
    } else if (distInKm < 10.0) { _notifiedDist10 = false; }

    if (distInKm >= 8.0 && distInKm < 10.0 && !_notifiedDist8) {
      _triggerNotification('distance', 'Peringatan Jarak (> 8 km)', 'Pengguna sudah menjauh sejauh 8 km dari lokasi Anda.', 'warning');
      _notifiedDist8 = true;
    } else if (distInKm < 8.0) { _notifiedDist8 = false; }

    if (distInKm >= 5.0 && distInKm < 8.0 && !_notifiedDist5) {
      _triggerNotification('distance', 'Informasi Jarak (> 5 km)', 'Pengguna berada di luar radius 5 km.', 'info');
      _notifiedDist5 = true;
    } else if (distInKm < 5.0) { _notifiedDist5 = false; }
  }


  // ============================================
  // FUNGSI LAINNYA (TETAP SAMA SEPERTI SEBELUMNYA)
  // ============================================
  void setupRealtimeProfile() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _userSubscription = FirebaseFirestore.instance.collection("users").doc(user.uid).snapshots().listen((doc) {
      if (doc.exists) {
        var data = doc.data();
        userName.value = "${data?['firstName'] ?? ''} ${data?['lastName'] ?? ''}".trim();
        userEmail.value = data?['email'] ?? user.email ?? "";
        userPhone.value = data?['phone'] ?? "";
        userBirthDate.value = data?['birthDate'] ?? "";
        userPhotoUrl.value = data?['photoUrl'] ?? "";
      }
    }, onError: (error) => print("User Stream ditutup karena logout"));

    _stopSubscription = FirebaseFirestore.instance.collection("tunanetra_data").doc(user.uid).snapshots().listen((doc) {
      if (doc.exists && doc.data() != null) {
        tunanetraData.value = doc.data()!;
        hasTunanetraData.value = true;
      } else {
        hasTunanetraData.value = false;
      }
    }, onError: (error) => print("Tunanetra Stream ditutup karena logout")); 
  }

  void setupRealtimeIoT() {    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    String uid = user.uid;
    
    _iotSubscription = FirebaseFirestore.instance.collection("tunanetra_data").doc(uid).snapshots().listen((doc) {
      if (doc.exists) {
        String channelID = doc.data()?['thingspeak_channel_id'] ?? "";
        String readKey = doc.data()?['thingspeak_read_key'] ?? "";

        if (channelID.isNotEmpty && readKey.isNotEmpty) {
          _timer?.cancel();
          fetchThingSpeakData(channelID, readKey);
          _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
            fetchThingSpeakData(channelID, readKey);
          });
        }
      }
    }, onError: (error) { print("Firestore Stream Error: $error"); });
  }

  void resetIoTData() {
    _timer?.cancel();
    _iotSubscription?.cancel();
    signal.value = "0 dBm";
    battery.value = "0";
    distance.value = "0";
    latitude.value = 0.0;
    longitude.value = 0.0;
    hasTunanetraData.value = false;
    tunanetraData.clear();
    clearRoute();
  }

  Future<void> fetchThingSpeakData(String id, String key) async {
    try {
      final url = "https://api.thingspeak.com/channels/$id/feeds.json?api_key=$key&results=1";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['feeds'] != null && data['feeds'].isNotEmpty) {
          final lastFeed = data['feeds'][0];
          
          DateTime lastUpdate = DateTime.parse(lastFeed['created_at']).toLocal();
          DateTime now = DateTime.now();
          bool timedOut = now.difference(lastUpdate).inSeconds > 45;

          double devLat = double.tryParse(lastFeed['field1']?.toString() ?? "0.0") ?? 0.0;
          double devLng = double.tryParse(lastFeed['field2'] ?? "0.0") ?? 0.0;
          int batteryVal = int.tryParse(lastFeed['field4']?.toString() ?? "0") ?? 0;

          if (devLat != 0.0 && devLng != 0.0) {
            latitude.value = devLat;
            longitude.value = devLng;
          }

          if (!timedOut) {
            double currentDistKm = await calculateRealDistance(devLat, devLng); 
            signal.value = "${lastFeed['field3'] ?? '0'} dBm";
            battery.value = batteryVal.toString();
            isDeviceOff.value = false;
            iotStatus.value = (batteryVal <= 30) ? "Lowbat" : "Active Now";
            
            // Panggil pengecek notifikasi
            _checkAlerts(currentDistKm, batteryVal, false);

          } else {
            isDeviceOff.value = true;
            iotStatus.value = "Off";
            signal.value = "0 dBm";
            double currentDistKm = await calculateRealDistance(devLat, devLng); 
            
            // Panggil pengecek notifikasi untuk status OFF
            _checkAlerts(currentDistKm, batteryVal, true);
          }
        }
      }
    } catch (e) { print("Error: $e"); }
  }

  // Mengubah kalkulasi jarak agar mengembalikan nilai (return)
  Future<double> calculateRealDistance(double devLat, double devLng) async {
    double distKm = 0.0;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return 0.0;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return 0.0;
      }
      if (permission == LocationPermission.deniedForever) return 0.0;

      Position userPos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      double distanceInMeters = Geolocator.distanceBetween(userPos.latitude, userPos.longitude, devLat, devLng);
      
      distKm = distanceInMeters / 1000;

      if (distanceInMeters > 1000) {
        distance.value = "${distKm.toStringAsFixed(2)} km";
      } else {
        distance.value = "${distanceInMeters.toStringAsFixed(1)} m";
      }
    } catch (e) {
      print("Error pada kalkulasi jarak: $e");
    }
    return distKm;
  }

  Future<LatLngBounds?> fetchPolylineRoute(LatLng originLoc) async {
    if (latitude.value == 0.0) { Get.snackbar("Menunggu", "Lokasi alat IoT belum ditemukan."); return null; }
    isLoadingRoute.value = true;
    String apiKey = "AIzaSyAw_-eH3JXoXl7cTNlV4BJQ_6ugibXGEsg";
    PolylinePoints polylinePoints = PolylinePoints();
    PointLatLng origin = PointLatLng(originLoc.latitude, originLoc.longitude);
    PointLatLng destination = PointLatLng(latitude.value, longitude.value);

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      apiKey, origin, destination, travelMode: selectedTravelMode.value,
    );

    if (result.points.isNotEmpty) {
      List<LatLng> polylineCoordinates = [];
      double? minLat, maxLat, minLng, maxLng;

      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        if (minLat == null || point.latitude < minLat) minLat = point.latitude;
        if (maxLat == null || point.latitude > maxLat) maxLat = point.latitude;
        if (minLng == null || point.longitude < minLng) minLng = point.longitude;
        if (maxLng == null || point.longitude > maxLng) maxLng = point.longitude;
      }

      polylines.clear();
      polylines.add(Polyline(polylineId: const PolylineId("route"), color: const Color(0xFF66C7AA), points: polylineCoordinates, width: 6));
      
      isShowingRoute.value = true;
      isLoadingRoute.value = false;

      return LatLngBounds(southwest: LatLng(minLat!, minLng!), northeast: LatLng(maxLat!, maxLng!));
    } else {
      isLoadingRoute.value = false;
      Get.snackbar("Rute Gagal", "Google Maps tidak menemukan rute.", backgroundColor: Colors.redAccent, colorText: Colors.white);
      return null;
    }
  }

  void clearRoute() {
    polylines.clear();
    isShowingRoute.value = false;
  }

  Future<void> toggleAlarm() async {
    final String writeApiKey = "FGXPQPS5QMSCU7UC"; 
    if (isDeviceOff.value) {
      if (alarmState.value == AlarmState.idle) {
        alarmState.value = AlarmState.loadingOn; 
        await Future.delayed(const Duration(seconds: 5)); 
        alarmState.value = AlarmState.idle;
        Get.snackbar("Perangkat Tidak Terhubung", "Alat IoT sedang mati atau di luar jangkauan.", backgroundColor: Colors.redAccent, colorText: Colors.white, duration: const Duration(seconds: 4));
      }
      return; 
    }

    if (alarmState.value == AlarmState.idle) {
      alarmState.value = AlarmState.loadingOn; 
      try {
        final urlOn = Uri.parse("https://api.thingspeak.com/update?api_key=$writeApiKey&field1=1");
        final response = await http.get(urlOn);
        if (response.statusCode == 200 && response.body != "0") {
          await Future.delayed(const Duration(seconds: 5));
          startCountdown(); 
        } else {
          alarmState.value = AlarmState.idle;
          Get.snackbar("Gagal", "Sistem sibuk, tunggu beberapa saat lagi.", backgroundColor: Colors.orange, colorText: Colors.white);
        }
      } catch (e) { alarmState.value = AlarmState.idle; Get.snackbar("Error", "Gagal menyalakan alarm", backgroundColor: Colors.red, colorText: Colors.white); }
    } else if (alarmState.value == AlarmState.active) {
      alarmState.value = AlarmState.loadingOff; 
      try {
        final urlOff = Uri.parse("https://api.thingspeak.com/update?api_key=$writeApiKey&field1=0");
        final response = await http.get(urlOff);
        if (response.statusCode == 200 && response.body != "0") {
          await Future.delayed(const Duration(seconds: 5));
          alarmState.value = AlarmState.idle; 
        } else {
          alarmState.value = AlarmState.active; 
          Get.snackbar("Gagal", "Sistem sibuk, tunggu beberapa saat lagi.", backgroundColor: Colors.orange, colorText: Colors.white);
        }
      } catch (e) { alarmState.value = AlarmState.active; Get.snackbar("Error", "Gagal mematikan alarm", backgroundColor: Colors.red, colorText: Colors.white); }
    }
  }

  void startCountdown() {
    alarmState.value = AlarmState.countdown;
    countdownTimer.value = 15;
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdownTimer.value > 0) { countdownTimer.value--; } else { timer.cancel(); alarmState.value = AlarmState.active; }
    });
  }

  void stopMonitoring() {
    _timer?.cancel();
    _iotSubscription?.cancel();
    _userSubscription?.cancel();
    _stopSubscription?.cancel();
  }

  @override
  void onClose() {
    stopMonitoring(); 
    super.onClose();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    return FirebaseFirestore.instance.collection("users").doc(user.uid).snapshots();
  }
}