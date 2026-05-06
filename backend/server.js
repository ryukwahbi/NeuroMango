const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.get('/api/health', (req, res) => {
  res.json({ status: 'MangoTrack API is running' });
});

// TODO: Add mango detection endpoints
// POST /api/analyze - Upload image and get ripeness analysis
// GET /api/history - Get analysis history
// POST /api/save-result - Save analysis result

// Start server
app.listen(PORT, () => {
  console.log(`MangoTrack API running on http://localhost:${PORT}`);
});
