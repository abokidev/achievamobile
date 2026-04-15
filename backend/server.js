const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');

const authRoutes = require('./routes/auth');
const ninRoutes = require('./routes/nin');
const faceRoutes = require('./routes/face');
const examRoutes = require('./routes/exam');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ extended: true, limit: '50mb' }));

// Request logging
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} ${req.method} ${req.url}`);
  next();
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/nin', ninRoutes);
app.use('/api/face', faceRoutes);
app.use('/api/exam', examRoutes);
app.use('/api/proctor', examRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'achieva-backend' });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ message: 'Endpoint not found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Server error:', err);
  res.status(500).json({ message: 'Internal server error' });
});

app.listen(PORT, () => {
  console.log(`
  ╔═══════════════════════════════════════════════╗
  ║         Achieva Mock Backend Server           ║
  ║                                               ║
  ║  Running on: http://localhost:${PORT}            ║
  ║                                               ║
  ║  Test Credentials:                            ║
  ║    Email:    test@achieva.ng                  ║
  ║    Password: test1234                         ║
  ║                                               ║
  ║  Endpoints:                                   ║
  ║    POST /api/auth/login                       ║
  ║    POST /api/nin/verify                       ║
  ║    POST /api/face/verify                      ║
  ║    GET  /api/exam/info                        ║
  ║    GET  /api/exam/questions                   ║
  ║    POST /api/exam/submit                      ║
  ║    POST /api/proctor/snapshot                 ║
  ║    POST /api/proctor/event                    ║
  ║    GET  /health                               ║
  ╚═══════════════════════════════════════════════╝
  `);
});

module.exports = app;
