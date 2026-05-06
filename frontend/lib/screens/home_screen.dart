import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import 'market_analysis_screen.dart';
import '../services/market_service.dart';
import 'varieties_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onScanPressed;
  final VoidCallback onViewHistoryPressed;

  const HomeScreen({
    super.key,
    required this.onScanPressed,
    required this.onViewHistoryPressed,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _totalScans = 0;
  String _userName = "Jeshua";
  String _healthyRatio = "0%";
  List<Map<String, dynamic>> _recentScans = [];
  bool _isLoading = true;
  bool _isMarketLoading = true;
  String _selectedTown = "Tagbilaran City";
  Map<String, List<Map<String, dynamic>>> _townMarketData = {};

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
    _syncMarketData();
  }

  Future<void> _syncMarketData() async {
    setState(() => _isMarketLoading = true);
    final data = await MarketService.fetchMarketData();
    if (mounted) {
      setState(() {
        _townMarketData = data;
        _isMarketLoading = false;
      });
    }
  }

  Future<void> _loadHistoryData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load Profile Data
      final savedName = prefs.getString('user_name') ?? "Jeshua";
      final savedTown = prefs.getString('selected_town') ?? "Tagbilaran City";

      final List<String> historyJson =
          prefs.getStringList('mangotrack_history') ?? [];

      if (historyJson.isEmpty) {
        if (mounted) {
          setState(() {
            _userName = savedName;
            _selectedTown = savedTown;
            _totalScans = 0;
            _healthyRatio = "0%";
            _recentScans = [];
            _isLoading = false;
          });
        }
        return;
      }

      final history = historyJson
          .map((e) => jsonDecode(e) as Map<String, dynamic>)
          .toList();

      int healthyCount = 0;
      for (var item in history) {
        final title = item['title'].toString().toLowerCase();
        if (title.contains('healthy')) {
          healthyCount++;
        }
      }

      if (mounted) {
        setState(() {
          _userName = savedName;
          _selectedTown = savedTown;
          _totalScans = history.length;
          _healthyRatio =
              "${((healthyCount / history.length) * 100).toStringAsFixed(0)}%";
          _recentScans = history.take(5).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading home data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showNotificationCenter() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: mangoSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.notifications_active_rounded, color: mangoPrimary),
            SizedBox(width: 12),
            Text("Notifications", style: TextStyle(color: mangoText)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNotificationItem(
              "System Ready",
              "AI models are loaded and ready for scanning.",
              "Just now",
            ),
            const Divider(),
            _buildNotificationItem(
              "Scan Tip",
              "Try scanning in bright daylight for 99% accuracy.",
              "2h ago",
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: mangoPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(String title, String body, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: mangoText,
                ),
              ),
              Text(
                time,
                style: const TextStyle(fontSize: 10, color: Colors.black45),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  void _showVarietyInfo(String name) {
    HapticFeedback.lightImpact();
    String description = "";
    if (name == "Carabao") {
      description =
          "The world-famous Philippine Mango. Known for its extreme sweetness and rich flavor.";
    } else if (name == "Pico") {
      description =
          "Smaller than Carabao with a more pointed end. Fibrous but very sweet when fully ripe.";
    } else if (name == "Indian") {
      description =
          "Commonly eaten green and crunchy with salt or shrimp paste. Tart and refreshing.";
    } else if (name == "Apple") {
      description =
          "Round shape like an apple. Has a distinct reddish blush and a tangy-sweet flavor profile.";
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: mangoSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "$name Mango",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: mangoText,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: mangoPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Got it!",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mangoBackground,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: mangoPrimary),
              )
            : RefreshIndicator(
                onRefresh: _loadHistoryData,
                color: mangoPrimary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Top Header ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_rounded,
                                      color: Colors.red,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedTown,
                                        icon: const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 16,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        onChanged: (String? newValue) {
                                          if (newValue != null) {
                                            HapticFeedback.selectionClick();
                                            setState(() {
                                              _selectedTown = newValue;
                                            });
                                          }
                                        },
                                        items: _townMarketData.keys
                                            .map<DropdownMenuItem<String>>((
                                              String value,
                                            ) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value),
                                              );
                                            })
                                            .toList(),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  "$_userName!",
                                  style: const TextStyle(
                                    color: mangoText,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            _buildTopActionIcons(),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // --- Statistics Section ---
                        _buildSectionHeader("Insights Dashboard"),
                        const SizedBox(height: 16),
                        _buildStatsRow(),
                        const SizedBox(height: 32),

                        // --- Hero Scan Card ---
                        _buildHeroCard(widget.onScanPressed),
                        const SizedBox(height: 32),

                        // --- Recent Activity ---
                        _buildSectionHeader(
                          "Recent Scans",
                          "View All",
                          widget.onViewHistoryPressed,
                        ),
                        const SizedBox(height: 16),
                        _buildRecentScansList(),
                        const SizedBox(height: 32),

                        // --- Mango Education / Varieties ---
                        _buildSectionHeader("Common Varieties", "View All", () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const VarietiesScreen(),
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                        _buildVarietiesGrid(),
                        const SizedBox(height: 32),

                        // --- Live Market Price Index ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader("Market Price Index"),
                                const Text(
                                  "Region: Central Visayas (Bohol)",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.black45,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.red.withAlpha(100),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    "LIVE • 2m ago",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _isMarketLoading
                            ? SizedBox(
                                height: 110,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.red,
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        "Syncing live prices...",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black38,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : SizedBox(
                                height: 110,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  children: _townMarketData[_selectedTown]!
                                      .map(
                                        (data) => _buildPriceCard(
                                          data['name'],
                                          data['price'],
                                          data['up'],
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                        const SizedBox(height: 32),

                        // --- Expert Scanning Tips (Modernized) ---
                        _buildSectionHeader("Expert Scanning Tips"),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 170,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _buildModernTipCard(
                                "Golden Hour",
                                "Scan under natural sunlight for the most accurate color detection.",
                                Icons.wb_sunny_rounded,
                                const Color(0xFFF59E0B),
                              ),
                              _buildModernTipCard(
                                "Steady Hands",
                                "Hold your phone still for 2 seconds to let the AI focus on the peel.",
                                Icons.pan_tool_rounded,
                                const Color(0xFF3B82F6),
                              ),
                              _buildModernTipCard(
                                "Clear View",
                                "Wipe your camera lens to avoid blurry ripeness predictions.",
                                Icons.camera_rounded,
                                const Color(0xFF10B981),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 100), // Bottom padding
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTopActionIcons() {
    return Row(
      children: [
        GestureDetector(
          onTap: _showNotificationCenter,
          child: _buildIconButton(Icons.notifications_none_rounded),
        ),
        const SizedBox(width: 12),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: mangoPrimary.withAlpha(40),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(color: Colors.white, width: 2),
            image: const DecorationImage(
              image: AssetImage('assets/icon.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: mangoSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: mangoBorder.withAlpha(30)),
      ),
      child: Icon(icon, color: mangoText, size: 22),
    );
  }

  Widget _buildSectionHeader(
    String title, [
    String? actionText,
    VoidCallback? onTap,
  ]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: mangoText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (actionText != null)
          GestureDetector(
            onTap: onTap,
            child: Text(
              actionText,
              style: const TextStyle(
                color: mangoPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            _totalScans.toString(),
            "Total Scans",
            Icons.bar_chart_rounded,
            Colors.grey,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            _healthyRatio,
            "Healthy Ratio",
            Icons.favorite_rounded,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String val, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: mangoSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            val,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: mangoText,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: mangoText.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(VoidCallback onScan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color.fromARGB(255, 247, 188, 121), Color(0xFFFFDFA8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 247, 188, 121).withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showPremiumGradeInfo(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(100),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withAlpha(150)),
                  ),
                  child: const Text(
                    "PREMIUM GRADE",
                    style: TextStyle(
                      color: Color(0xFF956214),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            "Market Quality Hub",
            style: TextStyle(
              color: Color(0xFF2D3436),
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Analyze your harvest to ensure every mango meets export standards and peak market value.",
            style: TextStyle(color: Colors.black87, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE08641),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: Colors.black26,
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MarketAnalysisScreen(),
                ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  "Access Analytics",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPremiumGradeInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFF59E0B),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  "Premium Grade",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "What does it mean?",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2D3436),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "\"Premium Grade\" (or Export Grade) refers to mangoes that meet the highest international agricultural standards. These mangoes are fully mature, blemish-free, perfectly shaped, and show no signs of disease or pest damage.",
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Why it matters:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2D3436),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Premium Grade mangoes command the highest market value and are prioritized for export markets like Japan, South Korea, and the US.",
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D3436),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Got it",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24), // Extra padding for bottom safe area
          ],
        ),
      ),
    );
  }

  Widget _buildRecentScansList() {
    if (_recentScans.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: mangoSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: mangoBorder.withAlpha(10)),
        ),
        child: const Center(
          child: Text(
            "No recent scans yet.",
            style: TextStyle(color: Colors.black38),
          ),
        ),
      );
    }

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _recentScans.length,
        itemBuilder: (context, index) {
          final item = _recentScans[index];
          final title = item['title'] ?? 'Unknown';
          final status = item['status'] ?? 'Checked';
          final colorHex = item['colorHex'] ?? 'F4A261';
          final color = Color(int.parse("0xFF$colorHex"));

          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: mangoSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withAlpha(40)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: mangoText,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVarietiesGrid() {
    final varieties = [
      {'name': 'Carabao', 'image': 'assets/carabao_mango.png'},
      {'name': 'Pico', 'image': 'assets/pico_mango.png'},
      {'name': 'Indian', 'image': 'assets/indian_mango.png'},
      {'name': 'Apple', 'image': 'assets/apple_mango.png'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: varieties.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (context, index) {
        final name = varieties[index]['name']!;
        final imagePath = varieties[index]['image']!;
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5FBFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: mangoBorder.withAlpha(20)),
          ),
          child: Stack(
            children: [
              // Fullscreen icon at top-right (now the only clickable part)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _showVarietyInfo(name),
                  behavior:
                      HitTestBehavior.opaque, // Ensures the hit area works well
                  child: Padding(
                    padding: const EdgeInsets.all(4.0), // Extra hit area
                    child: Image.asset(
                      'assets/fullscreen_icon.png',
                      width: 18,
                      height: 18,
                    ),
                  ),
                ),
              ),
              // Image and text at bottom-left
              Positioned(
                left: 14,
                bottom: 14,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      imagePath,
                      width: 45,
                      height: 45,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: mangoText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernTipCard(
    String title,
    String desc,
    IconData icon,
    Color accent,
  ) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(180),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: accent.withAlpha(20),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withAlpha(30),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Pro Tip",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: mangoText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: TextStyle(
              fontSize: 13,
              color: mangoText.withAlpha(180),
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(String name, String price, bool isUp) {
    return Container(
      width: 155,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black.withAlpha(5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                color: isUp ? Colors.green : Colors.red,
                size: 14,
              ),
            ],
          ),
          const Spacer(),
          Text(
            price,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: mangoText,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Source: DA Agromart",
            style: TextStyle(fontSize: 9, color: Colors.black38),
          ),
        ],
      ),
    );
  }
}
