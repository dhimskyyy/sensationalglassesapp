import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../controllers/home_controller.dart';
import '../app/theme/app_colors.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  final HomeController homeC = Get.find<HomeController>();
  GoogleMapController? _mapController;

  Timer? _recenterTimer;
  bool _isUserInteracting = false;

  // State untuk Panel Tarik (Bisa di-swipe atas/bawah)
  bool _isPanelExpanded = true;

  final address = "Mencari alamat...".obs;

  LatLng _currentDeviceLocation = const LatLng(-6.2088, 106.8456);

  Future<void> _getPolylineRoute() async {
    LatLngBounds? bounds = await homeC.fetchPolylineRoute(
      _currentDeviceLocation,
    );

    if (bounds != null && mounted) {
      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }
  }

  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        address.value = "${place.subLocality}, ${place.locality}";
      }
    } catch (e) {
      address.value = "Alamat tidak ditemukan";
    }
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
        if (!homeC.isShowingRoute.value) {
          _animateToDevice();
        }
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
    if (homeC.latitude.value != 0.0) {
      _getAddressFromLatLng(homeC.latitude.value, homeC.longitude.value);
    }
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
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF66C7AA);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Obx(
              () => homeC.hasTunanetraData.value
                  ? _buildRealGoogleMap()
                  : _buildPlaceholderMap(),
            ),
          ),

          Obx(
            () => Positioned.fill(
              // KUNCI UTAMA ADA DI SINI: Tambahkan homeC.hasTunanetraData.value &&
              child:
                  (homeC.hasTunanetraData.value &&
                      (homeC.latitude.value == 0.0 ||
                          homeC.isDeviceOff.value) &&
                      !homeC.isShowingRoute.value)
                  ? Stack(
                      children: [
                        IgnorePointer(
                          child: Container(
                            color: Colors.white.withOpacity(0.7),
                            padding: const EdgeInsets.only(bottom: 250),
                            child: Center(
                              child: Column(
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
                                                  color: primaryColor
                                                      .withOpacity(
                                                        1 -
                                                            _radarController
                                                                .value,
                                                      ),
                                                  width: 3,
                                                ),
                                              ),
                                              width:
                                                  220 * _radarController.value,
                                              height:
                                                  220 * _radarController.value,
                                            );
                                          },
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(25),
                                          decoration: BoxDecoration(
                                            color: primaryColor.withOpacity(
                                              0.1,
                                            ),
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
                                    'Mencari perangkat...',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 50),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.only(bottom: 250),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 290),
                                TextButton.icon(
                                  onPressed: () => homeC.setupRealtimeIoT(),
                                  icon: const Icon(
                                    Icons.refresh,
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
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          if (Navigator.canPop(context))
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 8),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.black87),
                ),
              ),
            ),

          // TATA LETAK BARU: Column menampung Tombol Zoom & Panel Bawah
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // TOMBOL ZOOM CUSTOM
                Padding(
                  padding: const EdgeInsets.only(right: 16.0, bottom: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton.small(
                        heroTag: "zoom_in",
                        backgroundColor: Colors.white,
                        onPressed: () {
                          _mapController?.animateCamera(CameraUpdate.zoomIn());
                        },
                        child: const Icon(Icons.add, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: "zoom_out",
                        backgroundColor: Colors.white,
                        onPressed: () {
                          _mapController?.animateCamera(CameraUpdate.zoomOut());
                        },
                        child: const Icon(Icons.remove, color: Colors.black87),
                      ),
                    ],
                  ),
                ),

                // PANEL BAWAH
                Obx(
                  () => _buildBottomPanel(
                    primaryColor,
                    homeC.hasTunanetraData.value,
                    homeC.tunanetraData,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealGoogleMap() {
    return Obx(() {
      LatLng targetLoc = (homeC.latitude.value != 0.0)
          ? LatLng(homeC.latitude.value, homeC.longitude.value)
          : _currentDeviceLocation;

      if (!_isUserInteracting &&
          _mapController != null &&
          homeC.latitude.value != 0.0 &&
          !homeC.isShowingRoute.value) {
        _animateToDevice();
      }

      return GoogleMap(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10,
          bottom: 250,
        ),
        initialCameraPosition: CameraPosition(target: targetLoc, zoom: 16),
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        compassEnabled: false,

        onMapCreated: (controller) => _mapController = controller,
        onCameraMoveStarted: () => _onUserInteraction(),

        polylines: Set<Polyline>.of(homeC.polylines),

        markers: {
          if (homeC.latitude.value != 0.0)
            Marker(
              markerId: const MarkerId("iot_device"),
              position: targetLoc,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                homeC.isDeviceOff.value
                    ? BitmapDescriptor.hueRed
                    : HSVColor.fromColor(const Color(0xFF70CAB0)).hue,
              ),
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
          GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity! > 0) {
                // Geser ke bawah
                setState(() {
                  _isPanelExpanded = false;
                });
              } else if (details.primaryVelocity! < 0) {
                // Geser ke atas
                setState(() {
                  _isPanelExpanded = true;
                });
              }
            },
            onTap: () {
              setState(() {
                _isPanelExpanded = !_isPanelExpanded;
              });
            },
            child: Container(
              color: Colors.transparent,
              width: double.infinity,
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
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
                          "Silakan hubungkan perangkat Sensational Glasses \ndi menu input data terlebih dahulu.",
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
                          ClipOval(
                            child:
                                (data?['foto_url'] != null &&
                                    data?['foto_url'] != "")
                                ? CachedNetworkImage(
                                    imageUrl: data!['foto_url'],
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    fadeInDuration: Duration.zero,
                                    fadeOutDuration: Duration.zero,
                                    placeholder: (context, url) =>
                                        Container(color: Colors.transparent),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.person),
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
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          color: dotColor,
                                          size: 10,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          homeC.iotStatus.value,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          Obx(() {
                            Color bgColor = primaryColor;
                            Widget content = const Icon(
                              Icons.notifications_active,
                              color: Colors.white,
                              size: 22,
                            );
                            VoidCallback? onTap = () => homeC.toggleAlarm();

                            // 1. Desain Jika Alat Belum Terhubung
                            if (!homeC.hasTunanetraData.value) {
                              bgColor = Colors.grey.shade200;
                              content = Icon(
                                Icons.notifications_off,
                                color: Colors.grey.shade500,
                                size: 22,
                              );
                            }
                            // 2. Desain Jika Alat Offline / Mati
                            else if (homeC.isDeviceOff.value) {
                              bgColor = Colors.grey.shade400;
                              content = const Icon(
                                Icons.notifications_off,
                                color: Colors.white,
                                size: 22,
                              );
                            }
                            // 3. Desain Normal
                            else {
                              switch (homeC.alarmState.value) {
                                case AlarmState.idle:
                                  bgColor = primaryColor;
                                  content = const Icon(
                                    Icons.notifications_active,
                                    color: Colors.white,
                                    size: 22,
                                  );
                                  break;
                                case AlarmState.loadingOn:
                                  bgColor = Colors.grey;
                                  content = const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  );
                                  onTap = null;
                                  break;
                                case AlarmState.countdown:
                                  bgColor = Colors.orange;
                                  content = Text(
                                    "${homeC.countdownTimer.value}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  );
                                  onTap = null;
                                  break;
                                case AlarmState.active:
                                  bgColor = Colors.redAccent;
                                  content = const Icon(
                                    Icons.stop_circle,
                                    color: Colors.white,
                                    size: 22,
                                  );
                                  break;
                                case AlarmState.loadingOff:
                                  bgColor = Colors.grey;
                                  content = const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  );
                                  onTap = null;
                                  break;
                              }
                            }

                            return GestureDetector(
                              onTap: onTap,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    // Hilangkan bayangan jika sedang disable
                                    if (homeC.hasTunanetraData.value &&
                                        !homeC.isDeviceOff.value)
                                      BoxShadow(
                                        color: bgColor.withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                  ],
                                ),
                                child: Center(child: content),
                              ),
                            );
                          }),
                        ],
                      ),

                      // ============================================
                      // ANIMASI HIDE/SHOW LOKASI & DROPDOWN
                      // ============================================
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        child: _isPanelExpanded
                            ? Column(
                                children: [
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.grey.shade100,
                                      ),
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
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
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.grey.shade100,
                                      ),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<TravelMode>(
                                        value: homeC.selectedTravelMode.value,
                                        isExpanded: true,
                                        icon: const Icon(
                                          Icons.keyboard_arrow_down,
                                          color: AppColors.mint,
                                        ),
                                        items: const [
                                          DropdownMenuItem(
                                            value: TravelMode.driving,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.directions_car,
                                                  color: AppColors.mint,
                                                  size: 22,
                                                ),
                                                SizedBox(width: 12),
                                                Text(
                                                  "Kendaraan (Motor/Mobil)",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: TravelMode.walking,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.directions_walk,
                                                  color: AppColors.mint,
                                                  size: 22,
                                                ),
                                                SizedBox(width: 12),
                                                Text(
                                                  "Jalan Kaki",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        onChanged: (TravelMode? newValue) {
                                          if (newValue != null) {
                                            homeC.selectedTravelMode.value =
                                                newValue;
                                            if (homeC.isShowingRoute.value) {
                                              _getPolylineRoute();
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              )
                            : const SizedBox(height: 16),
                      ),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: Obx(
                          () => ElevatedButton(
                            onPressed: () {
                              if (homeC.isShowingRoute.value) {
                                homeC.clearRoute();
                                _animateToDevice();
                              } else {
                                if (!_isPanelExpanded) {
                                  setState(() {
                                    _isPanelExpanded = true;
                                  });
                                }
                                _getPolylineRoute();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: homeC.isShowingRoute.value
                                  ? Colors.redAccent
                                  : primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: homeC.isLoadingRoute.value
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        homeC.isShowingRoute.value
                                            ? "Tutup Rute"
                                            : "Rute",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        homeC.isShowingRoute.value
                                            ? Icons.close
                                            : Icons.directions,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
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
