require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const apiRoutes = require('./routes/api');

const app = express();
const PORT = process.env.PORT || 5050;

// Security HTTP headers
app.use(
  helmet({
    crossOriginResourcePolicy: { policy: 'cross-origin' },
  })
);

// CORS configuration
const allowedOrigins = process.env.CORS_ORIGIN
  ? process.env.CORS_ORIGIN.split(',').map((o) => o.trim())
  : ['*'];

app.use(
  cors({
    origin: (origin, callback) => {
      // Allow requests with no origin (like mobile apps, curl, postman) or if wildcard is allowed
      if (!origin || allowedOrigins.includes('*') || allowedOrigins.includes(origin)) {
        return callback(null, true);
      }
      return callback(null, true); // Permissive in development
    },
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
    credentials: true,
  })
);

// Rate Limiting to prevent API abuse
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX, 10) || 300,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: 'Too many requests from this IP address, please try again after 15 minutes.',
  },
});
app.use('/api/', limiter);

// Body parser
app.use(express.json({ limit: '5mb' }));
app.use(express.urlencoded({ extended: true, limit: '5mb' }));

// Simple sanitized request logger
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    // Do not log sensitive bodies (service account keys, tokens)
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.originalUrl} - ${res.statusCode} (${duration}ms)`);
  });
  next();
});

const path = require('path');
const fs = require('fs');

// Mount API routes first
app.use('/api', apiRoutes);

// Serve Flutter Web static build if present
const candidatePaths = [path.join(__dirname, 'public'), path.join(__dirname, '../build/web')];
const webBuildPath = candidatePaths.find(function(p) { return fs.existsSync(p); });
if (webBuildPath) {
  app.use(express.static(webBuildPath));

  // SPA Fallback: serve index.html for all non-API web routes
  app.get('*', (req, res, next) => {
    if (req.path.startsWith('/api')) return next();
    res.sendFile(path.join(webBuildPath, 'index.html'));
  });
} else {
  // Fallback API welcome if web is not yet compiled
  app.get('/', (req, res) => {
    res.json({
      name: 'PushPilot Backend API',
      status: 'online',
      description: 'Firebase Cloud Messaging (FCM) v1 Push Notification Service',
      endpoints: {
        health: '/api/health',
        connect: 'POST /api/project/connect',
        disconnect: 'POST /api/project/disconnect',
        send: 'POST /api/notifications/send',
        test: 'POST /api/notifications/test',
        history: 'GET /api/notifications/history',
        stats: 'GET /api/stats',
      },
    });
  });
}

// 404 handler for unmatched API routes
app.use('/api', (req, res) => {
  res.status(404).json({
    success: false,
    error: `API route not found: ${req.method} ${req.originalUrl}`,
  });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Unhandled server error:', err.message);
  res.status(err.status || 500).json({
    success: false,
    error: err.message || 'Internal server error occurred.',
  });
});

const server = app.listen(PORT, () => {
  console.log(`=============================================`);
  console.log(`🚀 PushPilot Server running on port ${PORT}`);
  console.log(`📡 Website: http://localhost:${PORT}`);
  console.log(`📡 Healthcheck: http://localhost:${PORT}/api/health`);
  console.log(`=============================================`);
});

// Handle graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
  });
});

module.exports = app;
