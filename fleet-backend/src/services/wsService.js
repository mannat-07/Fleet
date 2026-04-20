const WebSocket = require('ws');
const logger = require('../utils/logger');

let wss;
const clients = new Set();

function initWebSocket(server) {
  wss = new WebSocket.Server({ server, path: '/ws' });

  wss.on('connection', (ws, req) => {
    clients.add(ws);
    logger.info(`WebSocket client connected. Total: ${clients.size}`);

    ws.on('message', (msg) => {
      try {
        const data = JSON.parse(msg);
        logger.debug('WS message received:', data);
        // Handle client messages if needed (e.g., subscribe to specific trucks)
      } catch (err) {
        logger.warn('Invalid WS message:', msg);
      }
    });

    ws.on('close', () => {
      clients.delete(ws);
      logger.info(`WebSocket client disconnected. Total: ${clients.size}`);
    });

    ws.on('error', (err) => logger.error('WebSocket error:', err.message));

    // Send welcome message
    ws.send(JSON.stringify({ event: 'connected', message: 'FleetOS WebSocket' }));
  });

  logger.info('✅ WebSocket server initialized on /ws');
}

function broadcast(data) {
  if (!wss) return;
  const message = JSON.stringify(data);
  clients.forEach((client) => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(message);
    }
  });
}

module.exports = { initWebSocket, broadcast };
