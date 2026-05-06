import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../services/analytics_service.dart';

class MarketAnalysisScreen extends StatefulWidget {
  /// Optional: pass from a specific scan result for context
  final double? lastScanReadiness;
  final String? lastScanTitle;

  const MarketAnalysisScreen({
    super.key,
    this.lastScanReadiness,
    this.lastScanTitle,
  });

  @override
  State<MarketAnalysisScreen> createState() => _MarketAnalysisScreenState();
}

class _MarketAnalysisScreenState extends State<MarketAnalysisScreen> {
  bool _isLoading = true;
  String _userTown = "Tagbilaran City";

  // Real computed data
  Map<String, dynamic> _grades = {};
  Map<String, dynamic> _demand = {};
  List<Map<String, String>> _recommendations = [];
  List<Map<String, dynamic>> _priceComparison = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userTown = prefs.getString('selected_town') ?? "Tagbilaran City";

      // Compute all analytics in parallel
      final grades = await AnalyticsService.computeGradeBreakdown();
      final demand = await AnalyticsService.computeDemandSummary(_userTown);
      final recommendations = await AnalyticsService.getRecommendations(
        grades,
        demand,
      );
      final priceComparison = await AnalyticsService.getPriceComparison(
        _userTown,
      );

      if (mounted) {
        setState(() {
          _grades = grades;
          _demand = demand;
          _recommendations = recommendations;
          _priceComparison = priceComparison;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading analytics: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mangoBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Market Analysis",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black54),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() => _isLoading = true);
              _loadAllData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: mangoPrimary),
                  SizedBox(height: 16),
                  Text(
                    "Crunching your data...",
                    style: TextStyle(
                      color: Colors.black45,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAllData,
              color: mangoPrimary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Readiness Score Header ---
                    _buildReadinessHeader(),
                    const SizedBox(height: 28),

                    // --- Quality Grade Breakdown (Real Data) ---
                    _buildSectionTitle(
                      "Quality Grade Breakdown",
                      Icons.pie_chart_rounded,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Based on ${_grades['totalScans']} scan${_grades['totalScans'] == 1 ? '' : 's'}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black38,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildGradeBreakdown(),
                    const SizedBox(height: 28),

                    // --- Market Demand (Real Data) ---
                    _buildSectionTitle(
                      "Market Demand — $_userTown",
                      Icons.trending_up_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildDemandCard(),
                    const SizedBox(height: 28),

                    // --- Smart Recommendations ---
                    _buildSectionTitle(
                      "Smart Recommendations",
                      Icons.lightbulb_rounded,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Personalized based on your scans & market data",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black38,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRecommendationsList(),
                    const SizedBox(height: 28),

                    // --- Price Comparison Across Towns ---
                    _buildSectionTitle(
                      "Regional Price Comparison",
                      Icons.location_on_rounded,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Carabao mango prices across Bohol towns",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black38,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPriceComparisonList(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  // ═══════════════════════════════════════════════════
  // READINESS HEADER
  // ═══════════════════════════════════════════════════
  Widget _buildReadinessHeader() {
    final isEmpty = _grades['isEmpty'] == true;
    final readiness = isEmpty ? 0.0 : (_grades['readiness'] as double);
    final totalScans = _grades['totalScans'] as int;

    String qualityLabel;
    Color qualityColor;
    if (isEmpty) {
      qualityLabel = "NO DATA YET";
      qualityColor = Colors.grey;
    } else if (readiness >= 80) {
      qualityLabel = "EXCELLENT QUALITY";
      qualityColor = Colors.green;
    } else if (readiness >= 50) {
      qualityLabel = "GOOD QUALITY";
      qualityColor = Colors.orange;
    } else {
      qualityLabel = "NEEDS ATTENTION";
      qualityColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withAlpha(15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.analytics_rounded, color: qualityColor, size: 16),
              const SizedBox(width: 6),
              Text(
                "Overall Market Readiness",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isEmpty)
            Column(
              children: [
                const Icon(
                  Icons.bar_chart_rounded,
                  color: Colors.black26,
                  size: 48,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Start scanning mangos to\nsee your readiness score",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black38, fontSize: 14),
                ),
              ],
            )
          else
            Column(
              children: [
                Text(
                  "${readiness.toStringAsFixed(0)}%",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "from $totalScans mango scan${totalScans == 1 ? '' : 's'}",
                  style: const TextStyle(color: Colors.black38, fontSize: 12),
                ),
              ],
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: qualityColor.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: qualityColor.withAlpha(60)),
            ),
            child: Text(
              qualityLabel,
              style: TextStyle(
                color: qualityColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // SECTION TITLE
  // ═══════════════════════════════════════════════════
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: mangoPrimary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: mangoText,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // QUALITY GRADE BREAKDOWN (Real Data)
  // ═══════════════════════════════════════════════════
  Widget _buildGradeBreakdown() {
    final isEmpty = _grades['isEmpty'] == true;

    if (isEmpty) {
      return _buildEmptyState(
        "No scan data available",
        "Scan mangos to see your quality grade breakdown.",
        Icons.document_scanner_rounded,
      );
    }

    return Column(
      children: [
        _buildGradeRow(
          "Grade A — Export Quality",
          _grades['gradeA'],
          _grades['gradeACount'],
          Colors.green,
          "Ripe & Healthy",
        ),
        const SizedBox(height: 16),
        _buildGradeRow(
          "Grade B — Local Market",
          _grades['gradeB'],
          _grades['gradeBCount'],
          Colors.orange,
          "Unripe but Healthy",
        ),
        const SizedBox(height: 16),
        _buildGradeRow(
          "Grade C — Processing",
          _grades['gradeC'],
          _grades['gradeCCount'],
          Colors.red,
          "Diseased",
        ),
      ],
    );
  }

  Widget _buildGradeRow(
    String label,
    double percent,
    int count,
    Color color,
    String scanType,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(30)),
      ),
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
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: mangoText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "$count scan${count == 1 ? '' : 's'} • $scanType",
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${percent.toStringAsFixed(1)}%",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: color.withAlpha(20),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // MARKET DEMAND (Real Data)
  // ═══════════════════════════════════════════════════
  Widget _buildDemandCard() {
    final level = _demand['level'] as String;
    final description = _demand['description'] as String;
    final upCount = _demand['upCount'] as int;
    final total = _demand['total'] as int;

    Color demandColor;
    IconData demandIcon;
    if (level == 'High Demand') {
      demandColor = Colors.green;
      demandIcon = Icons.trending_up_rounded;
    } else if (level == 'Moderate Demand') {
      demandColor = Colors.orange;
      demandIcon = Icons.trending_flat_rounded;
    } else {
      demandColor = Colors.red;
      demandIcon = Icons.trending_down_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: demandColor.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: demandColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(demandIcon, color: demandColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: demandColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "$upCount of $total varieties trending up",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: demandColor.withAlpha(8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              description,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // SMART RECOMMENDATIONS (Real Data)
  // ═══════════════════════════════════════════════════
  Widget _buildRecommendationsList() {
    if (_recommendations.isEmpty) {
      return _buildEmptyState(
        "No recommendations yet",
        "Scan more mangos to get personalized advice.",
        Icons.lightbulb_outline_rounded,
      );
    }

    return Column(
      children: _recommendations.asMap().entries.map((entry) {
        final index = entry.key;
        final rec = entry.value;
        return _buildRecommendationItem(index + 1, rec['title']!, rec['desc']!);
      }).toList(),
    );
  }

  Widget _buildRecommendationItem(int num, String title, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withAlpha(8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: mangoPrimary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: mangoText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // PRICE COMPARISON ACROSS TOWNS (Real Data)
  // ═══════════════════════════════════════════════════
  Widget _buildPriceComparisonList() {
    if (_priceComparison.isEmpty) {
      return _buildEmptyState(
        "No market data",
        "Market prices are currently unavailable.",
        Icons.storefront_rounded,
      );
    }

    return Column(
      children: _priceComparison.map((item) {
        final isUserTown = item['isUserTown'] as bool;
        final isUp = item['isUp'] as bool;
        final performance = item['performance'] as String;

        Color perfColor;
        if (performance == 'Above Avg') {
          perfColor = Colors.green;
        } else if (performance == 'Below Avg') {
          perfColor = Colors.red;
        } else {
          perfColor = Colors.blue;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isUserTown ? mangoPrimary.withAlpha(12) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUserTown
                  ? mangoPrimary.withAlpha(60)
                  : Colors.black.withAlpha(8),
              width: isUserTown ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Town info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item['town'],
                          style: TextStyle(
                            fontWeight: isUserTown
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: 14,
                            color: mangoText,
                          ),
                        ),
                        if (isUserTown) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: mangoPrimary.withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "YOU",
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: mangoPrimary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${item['varietyCount']} varieties tracked",
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),

              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUp
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 14,
                        color: isUp ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item['price'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: mangoText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: perfColor.withAlpha(15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      performance,
                      style: TextStyle(
                        color: perfColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════
  // EMPTY STATE HELPER
  // ═══════════════════════════════════════════════════
  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withAlpha(8)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.black26, size: 36),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
