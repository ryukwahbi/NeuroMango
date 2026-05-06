# MangoTrack - Frontend & Backend Integration Guide

## 📁 Project Structure
```
MangoTrackApp/
├── frontend/              # Flutter app (updated with API integration)
│   ├── lib/main.dart     # Updated with API functions
│   ├── pubspec.yaml      # Added http package
│   └── ...
│
├── backend/               # Node.js/Express REST API
│   ├── server.js         # Main server
│   ├── package.json      # Dependencies
│   ├── SETUP.md          # Backend setup guide
│   └── ...
│
└── README.md
```

---

## 🚀 Quick Start

### Step 1: Frontend Setup (Flutter)
```bash
cd frontend
flutter pub get
flutter run
```

**What's been added:**
- ✅ `http` package for API calls
- ✅ `API_BASE_URL` constant pointing to backend
- ✅ `saveAnalysisResult()` function - saves mango analysis to backend
- ✅ `getAnalysisHistory()` function - fetches past analyses

### Step 2: Backend Setup (Node.js)

First, install [Node.js](https://nodejs.org/) if not already installed.

```bash
cd backend
npm install
npm start
```

The backend will run on: `http://localhost:5000`

---

## 🔗 API Integration

### Available Functions in Flutter

#### Save Analysis Result
```dart
final result = {
  'timestamp': DateTime.now().toIso8601String(),
  'ripeness': 'ripe',
  'health': 'healthy',
  'confidence': 0.92,
  'image_path': '/path/to/image',
};

bool success = await saveAnalysisResult(result);
if (success) {
  print('Result saved to backend!');
}
```

#### Get Analysis History
```dart
final history = await getAnalysisHistory();
if (history != null) {
  print('History: $history');
}
```

---

## 🔄 How to Use in Your Code

### Example: Saving Analysis After Camera Scan

In your `CameraScreen` widget, after analyzing mango ripeness:

```dart
// After getting ripeness prediction
final analysisResult = {
  'timestamp': DateTime.now().toIso8601String(),
  'ripeness': predictedRipeness,  // e.g., 'unripe', 'ripe', 'overripe'
  'health': healthStatus,
  'confidence': confidence,
};

// Save to backend
bool saved = await saveAnalysisResult(analysisResult);

if (saved) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Analysis saved to cloud!')),
  );
}
```

---

## 📡 Backend API Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/health` | GET | Check if server is running |
| `/api/analyze` | POST | Send image for analysis |
| `/api/history` | GET | Get all past analyses |
| `/api/save-result` | POST | Save analysis result |

---

## 🔧 Configuration

### Change API URL
Update in `frontend/lib/main.dart`:

```dart
// Local development
const String API_BASE_URL = 'http://localhost:5000/api';

// Production
const String API_BASE_URL = 'https://your-production-server.com/api';
```

### Android/Emulator Testing
If running Flutter on Android emulator, use:
```dart
const String API_BASE_URL = 'http://10.0.2.2:5000/api';  // 10.0.2.2 = localhost from emulator
```

---

## ✅ Verification Steps

1. **Backend Running?**
   ```bash
   curl http://localhost:5000/api/health
   # Should return: {"status":"MangoTrack API is running"}
   ```

2. **Frontend Dependencies?**
   ```bash
   cd frontend
   flutter pub get
   # Should show "http" package installed
   ```

3. **Run Flutter App**
   ```bash
   flutter run
   # App should compile without errors
   ```

---

## 🚨 Troubleshooting

### "Connection refused" error in Flutter
- Make sure backend is running: `npm start`
- Check backend is on `http://localhost:5000`
- For Android emulator: Use `http://10.0.2.2:5000` instead

### `http` package not found
```bash
cd frontend
flutter pub get
```

### Backend won't start
```bash
# Check if port 5000 is in use
# Kill the process or change PORT in .env file
```

---

## 📚 Next Steps

1. ✅ Setup both frontend and backend
2. ⏳ Implement actual database in backend (MongoDB, PostgreSQL, etc.)
3. ⏳ Add image upload endpoint in backend
4. ⏳ Add user authentication
5. ⏳ Deploy to production server

---

**Happy Coding! 🥭🚀**
