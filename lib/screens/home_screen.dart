import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:sensationalglassesapp/screens/id_card.dart';
import '../controllers/auth_controller.dart';
import '../controllers/home_controller.dart';
import '../app/theme/app_colors.dart';
import 'input_data_tunanetra_page.dart';
import 'maps.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;

  final HomeController homeC = Get.put(HomeController());
  final AuthController authC = Get.find<AuthController>();

  GoogleMapController? _mapController;
  LatLng _currentDeviceLocation = const LatLng(-6.2088, 106.8456);

  Timer? _recenterTimer;
  bool _isUserInteracting = false;

  void _animateToDevice() {
    if (homeC.latitude.value != 0.0 && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(homeC.latitude.value, homeC.longitude.value),
        ),
      );
    }
  }

  void _onUserInteraction() {
    _isUserInteracting = true;
    _recenterTimer?.cancel();

    _recenterTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isUserInteracting = false;
        });
        _animateToDevice();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _initLocationService();

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    ever(homeC.latitude, (double lat) {
      if (lat != 0.0 && _mapController != null && !_isUserInteracting) {
        _animateToDevice();
      }
    });
  }

  @override
  void dispose() {
    _recenterTimer?.cancel();
    _radarController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initLocationService() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (mounted) {
      setState(() {
        _currentDeviceLocation = LatLng(position.latitude, position.longitude);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF66C7AA);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(
                          () => Text(
                            'Halo, \n${homeC.userName.value}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => authC.signOut(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.logout,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Obx(
                () => _buildDeviceCard(
                  primaryColor,
                  homeC.hasTunanetraData.value,
                  homeC.tunanetraData,
                ),
              ),

              const SizedBox(height: 20),

              _buildRadarOrMapCard(primaryColor),

              const SizedBox(height: 20),

              _buildAlarmButton(primaryColor),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadarOrMapCard(Color primaryColor) {
    return Obx(() {
      // 1. KONDISI: ALAT BELUM TERHUBUNG SAMA SEKALI
      if (!homeC.hasTunanetraData.value) {
        return _buildDisconnectedCard(primaryColor);
      }

      // 2. KONDISI: ALAT SUDAH TERHUBUNG, TAPI BELUM DAPAT SINYAL GPS (0.0)
      if (homeC.latitude.value == 0.0) {
        return _buildRadarCard(primaryColor);
      }

      // 3. KONDISI: ALAT TERHUBUNG DAN GPS DITEMUKAN (Tampilkan Peta Asli)
      LatLng targetLoc = LatLng(homeC.latitude.value, homeC.longitude.value);

      return Container(
        height: 320,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade200, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: targetLoc,
                  zoom: 16,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onCameraMoveStarted: () => _onUserInteraction(),
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
                onMapCreated: (controller) => _mapController = controller,

                polylines: Set<Polyline>.of(homeC.polylines),

                markers: {
                  Marker(
                    markerId: const MarkerId("iot_device"),
                    position: targetLoc,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      homeC.isDeviceOff.value
                          ? BitmapDescriptor.hueRed
                          : HSVColor.fromColor(const Color(0xFF70CAB0)).hue,
                    ),
                    infoWindow: const InfoWindow(title: "Lokasi Terakhir"),
                  ),
                  if (homeC.isShowingRoute.value)
                    Marker(
                      markerId: const MarkerId("user_location"),
                      position: _currentDeviceLocation,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueBlue,
                      ),
                      infoWindow: const InfoWindow(title: "Lokasi Anda"),
                    ),
                },
              ),

              if (homeC.isDeviceOff.value && !homeC.isShowingRoute.value) ...[
                IgnorePointer(
                  child: Container(
                    color: Colors.white.withOpacity(0.85),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 100,
                            width: 100,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                AnimatedBuilder(
                                  animation: _radarController,
                                  builder: (context, child) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: primaryColor.withOpacity(
                                            1 - _radarController.value,
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                      width: 100 * _radarController.value,
                                      height: 100 * _radarController.value,
                                    );
                                  },
                                ),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.explore,
                                    color: AppColors.mint,
                                    size: 30,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),
                          const Text(
                            'Mencari perangkat...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),

                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 160),
                      TextButton.icon(
                        onPressed: () => homeC.setupRealtimeIoT(),
                        icon: const Icon(
                          Icons.refresh,
                          size: 16,
                          color: AppColors.mint,
                        ),
                        label: const Text(
                          'Refresh Sinyal',
                          style: TextStyle(
                            color: AppColors.mint,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              Positioned(
                bottom: 15,
                right: 15,
                child: FloatingActionButton.small(
                  heroTag: "btn_fullscreen_map",
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.fullscreen, color: AppColors.mint),
                  onPressed: () => Get.to(
                    () => const MapsScreen(),
                    transition: Transition.fadeIn,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ==========================================
  // DESAIN WIDGET: JIKA ALAT BELUM TERHUBUNG
  // ==========================================
  Widget _buildDisconnectedCard(Color primaryColor) {
    return Container(
      height: 350,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200, width: 2),
        image: const DecorationImage(
          image: AssetImage('assets/maps.png'),
          fit: BoxFit.cover,
          opacity: 0.15, // Peta bayangan yang tipis
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.link_off, color: Colors.grey, size: 48),
          const SizedBox(height: 16),
          const Text(
            "Silakan hubungkan perangkat di menu\ninput data terlebih dahulu.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DESAIN WIDGET: JIKA ALAT TERHUBUNG TAPI MENCARI SINYAL (Radar)
  // ==========================================
  Widget _buildRadarCard(Color primaryColor) {
    return Container(
      height: 350,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200, width: 2),
        image: const DecorationImage(
          image: AssetImage('assets/maps.png'),
          fit: BoxFit.cover,
          opacity: 0.15,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 120,
            width: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _radarController,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withOpacity(
                            1 - _radarController.value,
                          ),
                          width: 2,
                        ),
                      ),
                      width: 120 * _radarController.value,
                      height: 120 * _radarController.value,
                    );
                  },
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.explore,
                    color: AppColors.mint,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Mencari perangkat...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we establish a secure\nconnection with the tracker.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          TextButton.icon(
            onPressed: () => homeC.setupRealtimeIoT(),
            icon: const Icon(Icons.refresh, size: 18, color: AppColors.mint),
            label: const Text(
              'Refresh Signal',
              style: TextStyle(color: AppColors.mint),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(
    Color primaryColor,
    bool hasData,
    Map<String, dynamic>? data,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          if (!hasData)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.to(() => const InputDataTunanetraPage()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text("Masukkan Data Tunanetra"),
              ),
            )
          else
            GestureDetector(
              onTap: () => Get.to(() => const IdCard()),
              child: Row(
                children: [
                  ClipOval(
                    child:
                        ((data?['foto_url'] != null && data?['foto_url'] != ""))
                        ? CachedNetworkImage(
                            imageUrl: data?['foto_url'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            fadeInDuration: Duration.zero,
                            fadeOutDuration: Duration.zero,
                            placeholder: (context, url) =>
                                Container(color: Colors.transparent),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.person, color: Colors.white),
                          )
                        : Image.asset(
                            'assets/default_profile.png',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data?['nama_tunanetra'] ?? "No Name",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Obx(() {
                          Color dotColor;

                          switch (homeC.iotStatus.value) {
                            case "Aktif":
                              dotColor = Colors.green;
                              break;
                            case "Lowbat":
                              dotColor = Colors.orange;
                              break;
                            case "Offline":
                              dotColor = Colors.red;
                              break;
                            default:
                              dotColor = Colors.grey;
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize:
                                  MainAxisSize.min, // Lebar menyesuaikan konten
                              children: [
                                Icon(Icons.circle, color: dotColor, size: 10),
                                const SizedBox(width: 6),
                                Text(
                                  homeC.iotStatus.value,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Colors.white24, height: 1),
          ),

          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  homeC.iotStatus.value == "Lowbat"
                      ? Icons.battery_alert_outlined
                      : Icons.battery_std_outlined,
                  'Battery',
                  "${homeC.battery.value}%",
                ),
                _buildStatItem(
                  Icons.signal_cellular_alt,
                  'Signal',
                  homeC.signal.value,
                ),
                _buildStatItem(
                  Icons
                      .near_me_outlined, // Menggunakan icon navigasi panah seperti di gambar
                  'Distance',
                  homeC.distance.value,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.black87, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildAlarmButton(Color primaryColor) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Obx(() {
        Color buttonColor = primaryColor;
        String buttonText = "Activate Alarm";
        Widget buttonIcon = const Icon(Icons.notifications_active);

        // Tetap pasang onPressed agar snackbar peringatannya bisa muncul saat diklik
        VoidCallback? onPressed = () => homeC.toggleAlarm();

        // 1. Desain Jika Alat Belum Terhubung SAMA SEKALI
        if (!homeC.hasTunanetraData.value) {
          buttonColor = Colors.grey.shade300;
          buttonText = "Alarm Tidak Tersedia";
          buttonIcon = Icon(
            Icons.notifications_off,
            color: Colors.grey.shade600,
          );
        }
        // 2. Desain Jika Lokasi GPS Belum Ditemukan
        else if (homeC.latitude.value == 0.0) {
          buttonColor = Colors.grey.shade400;
          buttonText = "Harap Tunggu...";
          buttonIcon = Icon(
            Icons.gps_off,
            color: Colors.grey.shade200,
          );
        }
        // 3. Desain Jika Alat Offline / Mati
        else if (homeC.isDeviceOff.value) {
          buttonColor = Colors.grey.shade400;
          buttonText = "Alat Offline";
          buttonIcon = const Icon(Icons.notifications_off);
        }
        // 4. Desain Normal
        else {
          switch (homeC.alarmState.value) {
            case AlarmState.idle:
              buttonColor = primaryColor;
              buttonText = "Activate Alarm";
              buttonIcon = const Icon(Icons.notifications_active);
              break;
            case AlarmState.loadingOn:
              buttonColor = Colors.grey;
              buttonText = "Menghubungkan ke IoT...";
              buttonIcon = const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              );
              onPressed = null;
              break;
            case AlarmState.countdown:
              buttonColor = Colors.orange;
              buttonText = "Tunggu ${homeC.countdownTimer.value} detik...";
              buttonIcon = const Icon(Icons.timer);
              onPressed = null;
              break;
            case AlarmState.active:
              buttonColor = Colors.redAccent;
              buttonText = "Stop Alarm";
              buttonIcon = const Icon(Icons.stop_circle);
              break;
            case AlarmState.loadingOff:
              buttonColor = Colors.grey;
              buttonText = "Mematikan Alarm...";
              buttonIcon = const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              );
              onPressed = null;
              break;
          }
        }

        return ElevatedButton.icon(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            // Jika belum ada alat atau GPS belum ditemukan, teksnya jadi abu-abu tua
            foregroundColor: (!homeC.hasTunanetraData.value || homeC.latitude.value == 0.0)
                ? Colors.grey.shade700
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation:
                (!homeC.hasTunanetraData.value || homeC.isDeviceOff.value || homeC.latitude.value == 0.0)
                ? 0
                : 5,
          ),
          icon: buttonIcon,
          label: Text(
            buttonText,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        );
      }),
    );
  }
}
