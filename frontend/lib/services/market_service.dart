import 'dart:async';

class MarketService {
  // This simulates a real API call. In a real app, you would use the 'http' package
  // to fetch data from a URL like https://api.mangotrack.com/v1/prices
  static Future<Map<String, List<Map<String, dynamic>>>> fetchMarketData() async {
    // Simulate a network delay (e.g., 1.5 seconds) to make it feel real
    await Future.delayed(const Duration(milliseconds: 1500));

    // This is the data that would eventually come from your server/database
    return {
      "Tagbilaran City": [
        {"name": "Carabao", "price": "₱124.50", "up": true},
        {"name": "Pico", "price": "₱82.00", "up": false},
        {"name": "Indian", "price": "₱61.25", "up": true},
      ],
      "Ubay": [
        {"name": "Carabao", "price": "₱118.00", "up": false},
        {"name": "Pico", "price": "₱78.50", "up": true},
        {"name": "Indian", "price": "₱55.00", "up": false},
      ],
      "Carmen": [
        {"name": "Carabao", "price": "₱121.75", "up": true},
        {"name": "Pico", "price": "₱80.25", "up": true},
        {"name": "Indian", "price": "₱58.90", "up": false},
      ],
      "Jagna": [
        {"name": "Carabao", "price": "₱126.00", "up": true},
        {"name": "Pico", "price": "₱84.50", "up": false},
        {"name": "Indian", "price": "₱63.00", "up": true},
      ],
      "Talibon": [
        {"name": "Carabao", "price": "₱119.50", "up": false},
        {"name": "Pico", "price": "₱77.00", "up": true},
        {"name": "Indian", "price": "₱54.25", "up": true},
      ],
    };
  }
}
