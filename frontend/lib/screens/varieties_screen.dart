import 'package:flutter/material.dart';
import '../theme.dart';

class VarietiesScreen extends StatelessWidget {
  const VarietiesScreen({super.key});

  final List<Map<String, dynamic>> _allVarieties = const [
    {"name": "Carabao", "icon": "🥭", "desc": "The most famous Philippine mango. Sweet, juicy, and perfect for export."},
    {"name": "Pico", "icon": "🍈", "desc": "Longer and flatter than Carabao. Has a distinct, rich sweetness."},
    {"name": "Indian", "icon": "🍏", "desc": "Best eaten green. Crunchy with a signature sour/tangy taste."},
    {"name": "Apple Mango", "icon": "🍎", "desc": "Rounder shape like an apple. Has a unique reddish tint when ripe."},
    {"name": "Katchamita", "icon": "🍐", "desc": "Also known as 'Pahutan'. Smaller but very sweet and aromatic."},
    {"name": "Horse Mango", "icon": "🍌", "desc": "Large variety with a strong pungent smell and very fibrous flesh."},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mangoBackground,
      appBar: AppBar(
        title: const Text("Mango Varieties", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: mangoText,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _allVarieties.length,
        itemBuilder: (context, index) {
          final v = _allVarieties[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: mangoSurface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                Text(v['icon'], style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: mangoText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        v['desc'],
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
