# MangoTrack - Mango Ripeness Detection App

Organized project structure with **frontend** (Flutter app) and **backend** (REST API).

## 📁 Project Structure

```
MangoTrackApp/
├── frontend/               # Flutter mobile app (Dart)
│   ├── lib/               # Dart code
│   ├── android/           # Android native
│   ├── ios/               # iOS native
│   ├── pubspec.yaml       # Flutter dependencies
│   └── ...
│
├── backend/               # Node.js/Express REST API
│   ├── server.js          # Main server file
│   ├── package.json       # npm dependencies
│   ├── .env.example       # Environment variables template
│   └── ...
│
└── README.md              # This file
```

## 🚀 Getting Started

### Frontend (Flutter)
```bash
cd frontend
flutter pub get
flutter run
```

### Backend (Node.js)
```bash
cd backend
npm install
npm start  # or npm run dev for development
```

## 📝 API Endpoints

- `GET /api/health` - Check API status
- `POST /api/analyze` - Upload mango image and analyze ripeness (TODO)
- `GET /api/history` - Get analysis history (TODO)
- `POST /api/save-result` - Save analysis result (TODO)

## 🔗 Frontend-Backend Communication

Update Flutter app to call backend API:
```
Backend URL: http://localhost:5000/api
```

For production, update API endpoint in Flutter app accordingly.
