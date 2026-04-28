const express    = require('express');
const cors       = require('cors');
const helmet     = require('helmet');
const morgan     = require('morgan');
const rateLimit  = require('express-rate-limit');

const { errorHandler, notFoundHandler } = require('./middleware/errorHandler');

// Routes
const authRoutes         = require('./routes/auth');
const truckRoutes        = require('./routes/trucks');
const driverRoutes       = require('./routes/drivers');
const iotRoutes          = require('./routes/iot');
const aggregationRoutes  = require('./routes/aggregation');
const insuranceRoutes    = require('./routes/insurance');
const notificationRoutes = require('./routes/notifications');
const esp32Routes        = require('./routes/esp32');
const mlRoutes           = require('./routes/ml');
const app = express();

// ─── Security ────────────────────────────────────────────────────────────────
app.use(helmet());
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Device-Secret'],
}));

// ─── Rate limiting ────────────────────────────────────────────────────────────
const globalLimiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
  max:      parseInt(process.env.RATE_LIMIT_MAX)        || 100,
  standardHeaders: true,
  legacyHeaders:   false,
  message: { success: false, message: 'Too many requests, please try again later' },
});
app.use('/api/', globalLimiter);

// ─── Body parsing ─────────────────────────────────────────────────────────────
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));

// ─── Logging ──────────────────────────────────────────────────────────────────
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));
}

// ─── Health check ─────────────────────────────────────────────────────────────
app.get('/health', (req, res) => {
  const { getFirebaseStatus } = require('./config/firebase');
  const fb = getFirebaseStatus();
  res.status(fb.initialized ? 200 : 503).json({
    status:    fb.initialized ? 'ok' : 'degraded',
    timestamp: new Date().toISOString(),
    service:   'FleetOS API',
    firebase:  fb.initialized ? 'connected' : `disconnected — ${fb.error}`,
  });
});

// ─── API Routes ───────────────────────────────────────────────────────────────
app.use('/api/auth',          authRoutes);
app.use('/api/trucks',        truckRoutes);
app.use('/api/drivers',       driverRoutes);
app.use('/api/iot',           iotRoutes);
app.use('/api/fleet',         aggregationRoutes);
app.use('/api/insurance',     insuranceRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/esp32',         esp32Routes);
app.use('/api/ml',            mlRoutes);

// ─── Error handling ───────────────────────────────────────────────────────────
app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;
