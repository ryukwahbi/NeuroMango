import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    List<String> saved = prefs.getStringList('mangotrack_history') ?? [];
    
    // Simulate minor delay for premium feel
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() {
        _history = saved
            .map((e) => jsonDecode(e) as Map<String, dynamic>)
            .toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('mangotrack_history');
    setState(() => _history = []);
    HapticFeedback.heavyImpact();
  }

  Color _hexToColor(String hexString) => Color(int.parse("0xFF$hexString"));

  @override
  Widget build(BuildContext context) {
    int healthyCount = _history.where((item) => item['title'].toString().toLowerCase().contains('healthy')).length;
    double healthyPercent = _history.isEmpty ? 0 : (healthyCount / _history.length);

    return Scaffold(
      backgroundColor: mangoBackground,
      appBar: AppBar(
        title: const Text(
          "Scan Analytics",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: mangoText,
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
              onPressed: () {
                _showDeleteConfirm();
              },
            ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: mangoPrimary))
        : RefreshIndicator(
            onRefresh: _loadHistory,
            color: mangoPrimary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                // --- Analytics Summary Card ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _buildAnalyticsSummary(healthyCount, healthyPercent),
                  ),
                ),

                // --- History List ---
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  sliver: _history.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = _history[index];
                            final color = _hexToColor(item['colorHex']);
                            return _buildHistoryItem(item, color);
                          },
                          childCount: _history.length,
                        ),
                      ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
    );
  }

  Widget _buildAnalyticsSummary(int healthy, double percent) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3436),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Yield Quality",
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${(percent * 100).toStringAsFixed(0)}% Healthy",
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildSimpleStat("Total", _history.length.toString(), Icons.analytics_rounded),
              const Spacer(),
              _buildSimpleStat("Healthy", healthy.toString(), Icons.check_circle_rounded),
              const Spacer(),
              _buildSimpleStat("Warning", (_history.length - healthy).toString(), Icons.warning_rounded),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            "Health Distribution",
            style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.white.withAlpha(20),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
              minHeight: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(String label, String val, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white24, size: 20),
        const SizedBox(height: 8),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: mangoSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withAlpha(30)),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.qr_code_scanner_rounded, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: mangoText),
                ),
                const SizedBox(height: 4),
                Text(
                  item['status'],
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  item['date'],
                  style: const TextStyle(color: Colors.black26, fontSize: 10),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.black12),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.history_toggle_off_rounded, size: 80, color: Colors.black12),
        SizedBox(height: 16),
        Text(
          "No Harvest Data Found",
          style: TextStyle(color: Colors.black38, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          "Start scanning your mangos to build your quality report.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black26, fontSize: 14),
        ),
      ],
    );
  }

  void _showDeleteConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Clear History?"),
        content: const Text("This will permanently delete all your scan records from this device."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              _clearHistory();
              Navigator.pop(context);
            }, 
            child: const Text("Delete All", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
