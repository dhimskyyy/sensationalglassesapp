import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../controllers/home_controller.dart';
import '../app/theme/app_colors.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  final HomeController homeC = Get.find<HomeController>();
  GoogleMapController? _mapController;

  Set<Polyline> _polylines = {};
  List<LatLng> _polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();

  Timer? _recenterTimer;
  bool _isUserInteracting = false;

  final address = "Mencari alamat...".obs;

  // Lokasi default (Bisa Jakarta atau koordinat umum)
  LatLng _currentDeviceLocation = const LatLng(-6.2088, 106.8456);

  Future<void> _getPolylineRoute() async {
    // 1. Ambil koordinat asal (HP) dan tujuan (Alat)
    PointLatLng origin = PointLatLng(_currentDeviceLocation.latitude, _currentDeviceLocation.longitude);
    PointLatLng destination = PointLatLng(homeC.latitude.value, homeC.longitude.value);

    // 2. Request rute ke Google Directions API
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? "",
      origin,
      destination,
      travelMode: TravelMode.walking,
    );

    // 3. Jika berhasil, gambar garisnya
    if (result.points.isNotEmpty) {
      _polylineCoordinates.clear();
      for (var point in result.points) {
        _polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }

      setState(() {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId("route"),
            color: const Color(0xFF66C7AA),
            points: _polylineCoordinates,
            width: 5,
          ),
        );
      });
      
      // Fokuskan kamera agar mencakup seluruh rute
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          _getBounds(_polylineCoordinates), 50
        ),
      );
    }
  }

  // Fungsi pembantu untuk mengatur area zoom kamera
  LatLngBounds _getBounds(List<LatLng> list) {
    double? minLat, maxLat, minLng, maxLng;
    for (LatLng latLng in list) {
      if (minLat == null || latLng.latitude < minLat) minLat = latLng.latitude;
      if (maxLat == null || latLng.latitude > maxLat) maxLat = latLng.latitude;
      if (minLng == null || latLng.longitude < minLng) minLng = latLng.longitude;
      if (maxLng == null || latLng.longitude > maxLng) maxLng = latLng.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Format alamat yang lebih rapi
        address.value =
            "${place.subLocality}, ${place.locality}";
      }
    } catch (e) {
      address.value = "Alamat tidak ditemukan";
    }
  }

  // FUNGSI UNGGULAN: Gabungan dari dua fungsi sebelumnya agar tidak duplikat
  Future<void> _initLocationService() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Cek servis lokasi
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    // Cek izin
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    // Ambil posisi HP user
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (mounted) {
      setState(() {
        _currentDeviceLocation = LatLng(position.latitude, position.longitude);
      });

      // Geser kamera ke lokasi HP user sebagai tampilan awal
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_currentDeviceLocation),
      );
    }
  }

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
    _recenterTimer = Timer(const Duration(seconds: 10), () {
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
    _initLocationService(); // Hanya panggil satu fungsi utama ini
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    ever(homeC.latitude, (double lat) {
      if (lat != 0.0) {
        _getAddressFromLatLng(lat, homeC.longitude.value);
      }
    });
  }

  @override
  void dispose() {
    _recenterTimer?.cancel();
    _radarController.dispose();
    _mapController?.dispose(); // Penting untuk membersihkan memori map
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF66C7AA);
    String uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection("tunanetra_data")
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        bool isDeviceConnected =
            snapshot.hasData &&
            snapshot.data!.data() != null &&
            snapshot.data!.data()?['thingspeak_channel_id'] != null;

        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
          child: Obx(() => homeC.hasTunanetraData.value
              ? _buildRealGoogleMap()
              : _buildPlaceholderMap()),
        ),

            Obx(() => Positioned.fill(
              child: (homeC.latitude.value == 0.0)
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 300),
                      child: Center(
                        child: _buildRadarDisplay(primaryColor),
                      ),
                    )
                  : const SizedBox.shrink(),
            )),

              Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 20,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),                        
            ),
          ),
        ),

              Align(
          alignment: Alignment.bottomCenter,
          child: Obx(() => _buildBottomPanel(
                primaryColor,
                homeC.hasTunanetraData.value,
                homeC.tunanetraData, // Mengambil data dari HomeController
              )),
        ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRealGoogleMap() {
    return Obx(() {
      LatLng targetLoc = (homeC.latitude.value != 0.0)
          ? LatLng(homeC.latitude.value, homeC.longitude.value)
          : _currentDeviceLocation;

      if (!_isUserInteracting &&
          _mapController != null &&
          homeC.latitude.value != 0.0) {
        _animateToDevice();
      }

      return GoogleMap(
        initialCameraPosition: CameraPosition(target: targetLoc, zoom: 16),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        onMapCreated: (controller) => _mapController = controller,
        onCameraMoveStarted: () => _onUserInteraction(),
        polylines: _polylines,
        markers: {
          if (homeC.latitude.value != 0.0)
            Marker(
              markerId: const MarkerId("iot_device"),
              position: targetLoc,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
            ),
        },       
      );
    });
  }

  Widget _buildPlaceholderMap() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        image: const DecorationImage(
          image: AssetImage('assets/maps.png'),
          fit: BoxFit.cover,
          opacity: 0.1,
        ),
      ),
    );
  }

  Widget _buildRadarDisplay(Color primaryColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 220,
          width: 220,
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
                        width: 3,
                      ),
                    ),
                    width: 220 * _radarController.value,
                    height: 220 * _radarController.value,
                  );
                },
              ),
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.explore,
                  color: AppColors.mint,
                  size: 60,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Locating device...',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: () => homeC.setupRealtimeIoT(),
          icon: const Icon(Icons.refresh, color: AppColors.mint),
          label: const Text(
            'Refresh Signal',
            style: TextStyle(
              color: AppColors.mint,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomPanel(
    Color primaryColor,
    bool isConnected,
    Map<String, dynamic>? data,
  ) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
            child: Column(
              children: [
                if (!isConnected)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.link_off,
                          color: Colors.grey,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Silakan hubungkan alat IoT di menu\ninput data terlebih dahulu.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      Row(
                        children: [
                          // Di dalam Row pada _buildBottomPanel
ClipOval(
  child: (data?['foto_url'] != null && data?['foto_url'] != "")
      ? CachedNetworkImage(
          imageUrl: data!['foto_url'],
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          fadeInDuration: Duration.zero,  // Hilangkan jeda transisi
          fadeOutDuration: Duration.zero, // Hilangkan jeda transisi
          placeholder: (context, url) => Container(color: Colors.transparent),
          errorWidget: (context, url, error) => const Icon(Icons.person),
        )
      : Image.asset(
          'assets/default_profile.png',
          width: 56,
          height: 56,
          fit: BoxFit.cover,
        ),
),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data?['nama_tunanetra'] ?? "User",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const Text(
                                  "Tunanetra (Visually Impaired)",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFEE2E2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_active,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: AppColors.mint,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "LOKASI TERKINI",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Obx(
                                    () => Text(
                                      homeC.latitude.value != 0.0
                                          ? address.value
                                          : "Mencari GPS Alat...",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            _getPolylineRoute();
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
                                "Rute",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
