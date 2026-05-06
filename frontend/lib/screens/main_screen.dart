import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';
import 'camera_screen.dart';
import 'history_screen.dart';
import 'guide_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        onScanPressed: () {
          HapticFeedback.lightImpact();
          setState(() => _currentIndex = 1);
        },
        onViewHistoryPressed: () {
          HapticFeedback.lightImpact();
          setState(() => _currentIndex = 2);
        },
      ),
      const CameraScreen(),
      const HistoryScreen(),
      const GuideScreen(),
      const ProfileScreen(),
    ];

    // Sandy/Tan color from the reference image
    const Color sandyNavBackground = Color(0xFFE6BE94);
    const Color darkNavInactive = Color(0xFF2C1B18);

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: SizedBox(
        height: 85 + MediaQuery.of(context).padding.bottom,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // --- Main Nav Bar ---
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 75 + MediaQuery.of(context).padding.bottom,
                decoration: const BoxDecoration(
                  color: sandyNavBackground,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Left side items
                      _buildNavItem(
                        Icons.home_rounded,
                        "Home",
                        0,
                        darkNavInactive,
                      ),
                      _buildNavItem(
                        Icons.history_rounded,
                        "History",
                        2,
                        darkNavInactive,
                      ),
                      // Center gap for the floating Scan button
                      const SizedBox(width: 70),
                      // Right side items
                      _buildNavItem(
                        Icons.menu_book_rounded,
                        "Guide",
                        3,
                        darkNavInactive,
                      ),
                      _buildNavItem(
                        Icons.person_rounded,
                        "Profile",
                        4,
                        darkNavInactive,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- Floating Scan Button ---
            Positioned(
              bottom: 40 + MediaQuery.of(context).padding.bottom,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    setState(() => _currentIndex = 1);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _currentIndex == 1
                          ? const Color(0xFF2C1B18)
                          : sandyNavBackground,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(50),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.document_scanner_rounded,
                          color: _currentIndex == 1
                              ? Colors.white
                              : const Color(0xFF2C1B18),
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // --- Scan Label below the floating button ---
            Positioned(
              bottom: 18 + MediaQuery.of(context).padding.bottom,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "Scan",
                  style: TextStyle(
                    color: _currentIndex == 1
                        ? Colors.white
                        : const Color(0xFF2C1B18),
                    fontWeight: _currentIndex == 1
                        ? FontWeight.bold
                        : FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    Color inactiveColor,
  ) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _currentIndex = index);
      },
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : inactiveColor,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : inactiveColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
