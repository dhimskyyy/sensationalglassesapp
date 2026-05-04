import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import 'home_screen.dart';
import 'maps.dart'; 
import 'profile_screen.dart'; // Sesuaikan dengan lokasi file Anda

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  int _previousIndex = 0; // Menyimpan index sebelumnya untuk tombol back

  // List halaman
  final List<Widget> _pages = [
    const HomeScreen(),
    const MapsScreen(), // Index 1
    const ProfileScreen(),
  ];

  void _onTapNav(int index) {
    setState(() {
      _previousIndex = _currentIndex; // Simpan posisi sebelum pindah
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Logika: Sembunyikan Nav Bar jika sedang di index 1 (Maps)
    bool showNavBar = _currentIndex != 1;

    return PopScope(
      // canPop = false means we intercept ALL back gestures
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (_currentIndex == 1) {
          // On Maps page
          final homeC = Get.find<HomeController>();
          if (!homeC.hasTunanetraData.value) {
            // Blind data NOT connected → go back to previous tab
            setState(() {
              _currentIndex = _previousIndex;
            });
          }
          // Blind data IS connected → block back gesture entirely
          // User must use the custom back button in the top-left corner
          return;
        }

        // On Home or Profile page → go back to Home if not already there
        if (_currentIndex != 0) {
          setState(() {
            _previousIndex = _currentIndex;
            _currentIndex = 0;
          });
        }
        // If already on Home, do nothing (don't exit app via back gesture)
      },
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            _pages[_currentIndex],
            
            // Tombol Back Kustom (Hanya muncul di halaman Maps)
            if (_currentIndex == 1)
              Positioned(
                top: 50,
                left: 20,
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = _previousIndex),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.black),
                  ),
                ),
              ),
          ],
        ),
        
        // Bottom Nav hanya muncul jika showNavBar true
        bottomNavigationBar: showNavBar 
          ? Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(Icons.home_outlined, 0),
                    _buildNavItem(Icons.map_outlined, 1),
                    _buildNavItem(Icons.person_outline, 2),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(), // Return widget kosong jika di Maps
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTapNav(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF66C7AA).withOpacity(0.15) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? const Color(0xFF66C7AA) : Colors.grey[400],
          size: 28,
        ),
      ),
    );
  }
}