const router  = require('express').Router();
const http    = require('http');
const { authenticate } = require('../middleware/auth');

const ESP32_URL = process.env.ESP32_URL || 'http://192.168.4.1/data';

/**
 * GET /api/esp32/data
 * Proxies the ESP32 sensor JSON to the Flutter app.
 * The PC running this backend must be connected to the ESP32 WiFi ("TruckSystem").
 */
router.get('/data', authenticate, (req, res) => {
  const request = http.get(ESP32_URL, { timeout: 5000 }, (esp32Res) => {
    let raw = '';
    esp32Res.on('data', chunk => { raw += chunk; });
    esp32Res.on('end', () => {
      if (res.headersSent) return;
      try {
        const json = JSON.parse(raw);
        res.json({ success: true, data: json });
      } catch {
        res.status(502).json({ success: false, message: 'ESP32 returned invalid JSON', raw });
      }
    });
  });

  request.on('timeout', () => {
    if (res.headersSent) return;
    request.destroy();
    res.status(504).json({
      success: false,
      message: 'ESP32 timed out. Make sure your PC is connected to "TruckSystem" WiFi.',
    });
  });

  request.on('error', (err) => {
    if (res.headersSent) return;
    res.status(503).json({
      success: false,
      message: `Cannot reach ESP32 at ${ESP32_URL}. Connect your PC to "TruckSystem" WiFi. Error: ${err.message}`,
    });
  });
});

/**
 * GET /api/esp32/status
 * Quick connectivity check — no auth needed so the app can test before login.
 */
router.get('/status', (req, res) => {
  const request = http.get(ESP32_URL, { timeout: 3000 }, (esp32Res) => {
    esp32Res.resume(); // drain response
    if (!res.headersSent) {
      res.json({ success: true, reachable: true, url: ESP32_URL });
    }
  });
  request.on('timeout', () => {
    request.destroy();
    if (!res.headersSent) {
      res.json({ success: true, reachable: false, reason: 'timeout' });
    }
  });
  request.on('error', (err) => {
    if (!res.headersSent) {
      res.json({ success: true, reachable: false, reason: err.message });
    }
  });
});

module.exports = router;
