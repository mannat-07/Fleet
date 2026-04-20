const router  = require('express').Router();
const rateLimit = require('express-rate-limit');
const { body, param, query } = require('express-validator');
const { validate } = require('../middleware/validate');
const { authenticate, authenticateDevice } = require('../middleware/auth');
const ctrl = require('../controllers/iotController');

// Higher rate limit for IoT ingestion
const iotLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: parseInt(process.env.IOT_RATE_LIMIT_MAX) || 500,
  message: { success: false, message: 'Too many requests from this device' },
});

// POST /api/iot/data  — device-authenticated
router.post('/data',
  iotLimiter,
  authenticateDevice,
  [
    body('truckId').trim().notEmpty().withMessage('truckId is required'),
    body('location.lat').optional().isFloat({ min: -90,  max: 90  }),
    body('location.lng').optional().isFloat({ min: -180, max: 180 }),
    body('temperature').optional().isFloat(),
    body('fuelLevel').optional().isFloat({ min: 0, max: 100 }),
    body('loadStatus').optional().isIn(['loaded', 'empty', 'partial']),
    body('doorStatus').optional().isIn(['open', 'closed', 'locked']),
    body('speed').optional().isFloat({ min: 0 }),
    body('engineOn').optional().isBoolean(),
  ],
  validate,
  ctrl.ingestData
);

// GET /api/iot/trucks/:truckId/latest  — user-authenticated
router.get('/trucks/:truckId/latest',
  authenticate,
  [param('truckId').notEmpty()],
  validate,
  ctrl.getLatest
);

// GET /api/iot/trucks/:truckId/history  — user-authenticated
router.get('/trucks/:truckId/history',
  authenticate,
  [
    param('truckId').notEmpty(),
    query('limit').optional().isInt({ min: 1, max: 200 }),
  ],
  validate,
  ctrl.getHistory
);

module.exports = router;
