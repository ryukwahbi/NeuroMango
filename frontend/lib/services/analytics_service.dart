import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'market_service.dart';

/// Central analytics engine that computes real insights
/// from scan history and market data.
class AnalyticsService {
  /// Aggregated scan grade data
  static Future<Map<String, dynamic>> computeGradeBreakdown() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('mangotrack_history') ?? [];

    if (historyJson.isEmpty) {
      return {
        'totalScans': 0,
        'gradeA': 0.0,
        'gradeB': 0.0,
        'gradeC': 0.0,
        'gradeACount': 0,
        'gradeBCount': 0,
        'gradeCCount': 0,
        'readiness': 0.0,
        'isEmpty': true,
      };
    }

    final history = historyJson
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();

    int gradeACount = 0; // Ripe & Healthy
    int gradeBCount = 0; // Unripe but Healthy
    int gradeCCount = 0; // Diseased (Ripe but Diseased + Unripe & Diseased)

    for (var item in history) {
      final title = (item['title'] ?? '').toString().toLowerCase();
      if (title.contains('ripe') && title.contains('healthy') && !title.contains('unripe')) {
        gradeACount++;
      } else if (title.contains('unripe') && title.contains('healthy')) {
        gradeBCount++;
      } else {
        // Diseased or unknown
        gradeCCount++;
      }
    }

    final total = history.length;
    final gradeA = (gradeACount / total) * 100;
    final gradeB = (gradeBCount / total) * 100;
    final gradeC = (gradeCCount / total) * 100;

    // Overall readiness = weighted score (Grade A fully ready, Grade B partially, Grade C not)
    final readiness = (gradeA * 1.0) + (gradeB * 0.5) + (gradeC * 0.0);
    final readinessNormalized = readiness.clamp(0.0, 100.0);

    return {
      'totalScans': total,
      'gradeA': gradeA,
      'gradeB': gradeB,
      'gradeC': gradeC,
      'gradeACount': gradeACount,
      'gradeBCount': gradeBCount,
      'gradeCCount': gradeCCount,
      'readiness': readinessNormalized,
      'isEmpty': false,
    };
  }

  /// Compute demand summary from market price trends for a specific town
  static Future<Map<String, dynamic>> computeDemandSummary(String town) async {
    final marketData = await MarketService.fetchMarketData();
    final townData = marketData[town] ?? marketData.values.first;

    int upCount = 0;
    int downCount = 0;
    String highestVariety = '';
    String highestPrice = '₱0';

    for (var item in townData) {
      if (item['up'] == true) {
        upCount++;
      } else {
        downCount++;
      }
      // Track the highest priced variety
      final priceStr = (item['price'] as String).replaceAll('₱', '').replaceAll(',', '');
      final currentHighest = highestPrice.replaceAll('₱', '').replaceAll(',', '');
      if (double.tryParse(priceStr) != null && double.tryParse(currentHighest) != null) {
        if (double.parse(priceStr) > double.parse(currentHighest)) {
          highestPrice = item['price'];
          highestVariety = item['name'];
        }
      }
    }

    String demandLevel;
    String demandDescription;
    bool isPositive;

    if (upCount > downCount) {
      demandLevel = 'High Demand';
      demandDescription =
          '$upCount out of ${townData.length} mango varieties are trending up in $town. '
          '$highestVariety leads at $highestPrice/kg.';
      isPositive = true;
    } else if (upCount == downCount) {
      demandLevel = 'Moderate Demand';
      demandDescription =
          'Mixed market signals in $town. '
          '$highestVariety is the top earner at $highestPrice/kg.';
      isPositive = true;
    } else {
      demandLevel = 'Low Demand';
      demandDescription =
          '$downCount out of ${townData.length} varieties are declining in $town. '
          'Consider holding stock or processing.';
      isPositive = false;
    }

    return {
      'level': demandLevel,
      'description': demandDescription,
      'isPositive': isPositive,
      'upCount': upCount,
      'downCount': downCount,
      'total': townData.length,
    };
  }

  /// Generate smart recommendations based on scan data + market conditions
  static Future<List<Map<String, String>>> getRecommendations(
    Map<String, dynamic> grades,
    Map<String, dynamic> demand,
  ) async {
    final List<Map<String, String>> recommendations = [];
    final totalScans = grades['totalScans'] as int;
    final gradeA = grades['gradeA'] as double;
    final gradeB = grades['gradeB'] as double;
    final gradeC = grades['gradeC'] as double;
    final isHighDemand = demand['isPositive'] as bool;

    if (totalScans == 0) {
      recommendations.add({
        'title': 'Start Scanning',
        'desc': 'Scan your first mango to unlock personalized harvest insights.',
      });
      recommendations.add({
        'title': 'Check Market Prices',
        'desc': 'Review current prices in your area before harvest.',
      });
      return recommendations;
    }

    // Grade A dominant (>60%)
    if (gradeA > 60) {
      recommendations.add({
        'title': 'Export-Ready Harvest',
        'desc':
            '${gradeA.toStringAsFixed(0)}% of your scans are Grade A. Your harvest meets export quality standards.',
      });
      if (isHighDemand) {
        recommendations.add({
          'title': 'Sell Now — Prices Rising',
          'desc':
              'Market demand is high. Consider selling this week for maximum profit.',
        });
      }
    }

    // Grade B dominant (>40%)
    if (gradeB > 40) {
      recommendations.add({
        'title': 'Monitor Ripeness',
        'desc':
            '${gradeB.toStringAsFixed(0)}% of your harvest is unripe. Allow 2-3 days at room temperature before selling.',
      });
      recommendations.add({
        'title': 'Optimize Storage',
        'desc': 'Store unripe mangos at 20-25°C to accelerate even ripening.',
      });
    }

    // Grade C is concerning (>20%)
    if (gradeC > 20) {
      recommendations.add({
        'title': 'Disease Alert',
        'desc':
            '${gradeC.toStringAsFixed(0)}% of scans show disease. Inspect trees for anthracnose or stem-end rot.',
      });
      recommendations.add({
        'title': 'Process Damaged Fruit',
        'desc':
            'Consider processing Grade C mangos into dried mango, juice, or puree to recover value.',
      });
    }

    // Low demand advice
    if (!isHighDemand && totalScans > 0) {
      recommendations.add({
        'title': 'Hold & Store',
        'desc':
            'Market prices are declining. Store at 13°C to extend shelf life until prices recover.',
      });
    }

    // General advice based on scan volume
    if (totalScans < 5) {
      recommendations.add({
        'title': 'Scan More Samples',
        'desc':
            'Only $totalScans scans recorded. Scan at least 10 mangos for more accurate harvest insights.',
      });
    } else if (totalScans >= 10) {
      recommendations.add({
        'title': 'Reliable Dataset',
        'desc':
            '$totalScans scans analyzed. Your grade breakdown is statistically reliable.',
      });
    }

    // Always cap at 4 recommendations
    if (recommendations.length > 4) {
      return recommendations.sublist(0, 4);
    }

    return recommendations;
  }

  /// Get price comparison across all towns for a given variety
  static Future<List<Map<String, dynamic>>> getPriceComparison(
    String userTown,
  ) async {
    final marketData = await MarketService.fetchMarketData();
    final List<Map<String, dynamic>> comparison = [];

    // Calculate average Carabao price across all towns
    double totalCarabao = 0;
    int carabaoCount = 0;

    for (var entry in marketData.entries) {
      for (var item in entry.value) {
        if (item['name'] == 'Carabao') {
          final price = double.tryParse(
            (item['price'] as String).replaceAll('₱', '').replaceAll(',', ''),
          );
          if (price != null) {
            totalCarabao += price;
            carabaoCount++;
          }
        }
      }
    }

    final avgCarabao = carabaoCount > 0 ? totalCarabao / carabaoCount : 0.0;

    for (var entry in marketData.entries) {
      final town = entry.key;
      final varieties = entry.value;

      // Get Carabao price for this town (primary indicator)
      String carabaoPrice = '₱0';
      bool isUp = false;
      double priceVal = 0;

      for (var v in varieties) {
        if (v['name'] == 'Carabao') {
          carabaoPrice = v['price'];
          isUp = v['up'];
          priceVal = double.tryParse(
                (v['price'] as String).replaceAll('₱', '').replaceAll(',', ''),
              ) ??
              0;
        }
      }

      String performance;
      if (priceVal > avgCarabao * 1.03) {
        performance = 'Above Avg';
      } else if (priceVal < avgCarabao * 0.97) {
        performance = 'Below Avg';
      } else {
        performance = 'Average';
      }

      comparison.add({
        'town': town,
        'price': carabaoPrice,
        'isUp': isUp,
        'performance': performance,
        'isUserTown': town == userTown,
        'varietyCount': varieties.length,
      });
    }

    // Sort: user's town first, then by price descending
    comparison.sort((a, b) {
      if (a['isUserTown']) return -1;
      if (b['isUserTown']) return 1;
      final priceA = double.tryParse(
            (a['price'] as String).replaceAll('₱', '').replaceAll(',', ''),
          ) ??
          0;
      final priceB = double.tryParse(
            (b['price'] as String).replaceAll('₱', '').replaceAll(',', ''),
          ) ??
          0;
      return priceB.compareTo(priceA);
    });

    return comparison;
  }
}
