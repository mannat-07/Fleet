require('dotenv').config();

const http    = require('http');
const app     = require('./app');
const logger  = require('./utils/logger');
const { initFirebase, getFirebaseStatus } = require('./config/firebase');
const { initWebSocket } = require('./services/wsService');
const { initMqtt }      = require('./services/mqttService');

const PORT = parseInt(process.env.PORT) || 3000;

async function bootstrap() {
  // 1. Init Firebase — never throws, stores error internally
  initFirebase();

  const fbStatus = getFirebaseStatus();
  if (!fbStatus.initialized) {
    logger.warn('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    logger.warn('  Firebase is NOT connected. Database routes will return 503.');
    logger.warn('  To connect, add your credentials to .env:');
    logger.warn('    FIREBASE_PROJECT_ID=your-project-id');
    logger.warn('    FIREBASE_CLIENT_EMAIL=your-sa@project.iam.gserviceaccount.com');
    logger.warn('    FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\\n...\\n-----END PRIVATE KEY-----\\n"');
    logger.warn('  OR set FIREBASE_SERVICE_ACCOUNT_PATH=/path/to/serviceAccount.json');
    logger.warn('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  // 2. Create HTTP server
  const server = http.createServer(app);

  // 3. Init WebSocket
  initWebSocket(server);

  // 4. Init MQTT (optional)
  try { initMqtt(); } catch (err) {
    logger.warn('MQTT init skipped:', err.message);
  }

  // 5. Start listening
  server.listen(PORT, () => {
    logger.info(`🚀 FleetOS API running on http://localhost:${PORT}`);
    logger.info(`📡 WebSocket: ws://localhost:${PORT}/ws`);
    logger.info(`🔥 Firebase: ${fbStatus.initialized ? 'connected ✅' : 'not connected ⚠️'}`);
    logger.info(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
  });

  server.on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
      logger.error(`Port ${PORT} is already in use. Change PORT in .env or stop the other process.`);
    } else {
      logger.error('Server error:', err.message);
    }
    process.exit(1);
  });

  // 6. Graceful shutdown
  const shutdown = (signal) => {
    logger.info(`${signal} received — shutting down`);
    server.close(() => {
      logger.info('HTTP server closed');
      process.exit(0);
    });
    setTimeout(() => process.exit(1), 10_000);
  };

  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT',  () => shutdown('SIGINT'));

  // 7. Catch unhandled rejections — log but don't crash
  process.on('unhandledRejection', (reason) => {
    logger.error('Unhandled rejection:', reason);
  });
}

bootstrap().catch((err) => {
  logger.error('Fatal bootstrap error:', err.message);
  process.exit(1);
});
