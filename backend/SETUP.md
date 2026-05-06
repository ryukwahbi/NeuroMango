# Backend Setup Guide

## Prerequisites
1. Install [Node.js](https://nodejs.org/) (v16 or higher)
2. Verify installation:
```bash
node --version
npm --version
```

## Installation

1. Navigate to backend folder:
```bash
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. Create `.env` file (copy from `.env.example`):
```bash
copy .env.example .env
```

4. Start the server:
```bash
npm start
```

Server will run on `http://localhost:5000`

## Test API

Check if server is running:
```bash
curl http://localhost:5000/api/health
```

Should return:
```json
{"status":"MangoTrack API is running"}
```

## API Endpoints

- `GET /api/health` - Health check
- `POST /api/analyze` - Analyze mango ripeness (implement with TFLite)
- `GET /api/history` - Get analysis history
- `POST /api/save-result` - Save result to database

## Development Mode

For automatic restart on file changes:
```bash
npm run dev
```

(Requires `nodemon` - already installed)
