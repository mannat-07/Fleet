const router = require('express').Router();
const { body, param } = require('express-validator');
const { validate } = require('../middleware/validate');
const { authenticate } = require('../middleware/auth');
const ctrl = require('../controllers/truckController');

// All truck routes require auth
router.use(authenticate);

// POST /api/trucks
router.post('/',
  [
    body('plate').trim().notEmpty().withMessage('Plate number is required'),
    body('model').optional().trim(),
    body('type').optional().isIn(['heavy', 'medium', 'light', 'tanker', 'flatbed']),
    body('year').optional().isInt({ min: 1990, max: new Date().getFullYear() + 1 }),
  ],
  validate,
  ctrl.addTruck
);

// GET /api/trucks
router.get('/', ctrl.getTrucks);

// GET /api/trucks/:truckId
router.get('/:truckId',
  [param('truckId').notEmpty()],
  validate,
  ctrl.getTruck
);

// PATCH /api/trucks/:truckId/status
router.patch('/:truckId/status',
  [
    param('truckId').notEmpty(),
    body('status').isIn(['active', 'on_trip', 'idle', 'maintenance']).withMessage('Invalid status'),
  ],
  validate,
  ctrl.updateStatus
);

// DELETE /api/trucks/:truckId
router.delete('/:truckId',
  [param('truckId').notEmpty()],
  validate,
  ctrl.deleteTruck
);

// PATCH /api/trucks/:truckId/metrics — Update ML performance metrics
router.patch('/:truckId/metrics',
  [
    param('truckId').notEmpty(),
    body('maintenance_score').optional().isFloat({ min: 0, max: 100 }),
    body('fuel_efficiency').optional().isFloat({ min: 0, max: 20 }),
    body('breakdown_count').optional().isInt({ min: 0 }),
    body('age_years').optional().isFloat({ min: 0 }),
    body('total_trips').optional().isInt({ min: 0 }),
    body('avg_load_capacity_used').optional().isFloat({ min: 0, max: 100 }),
  ],
  validate,
  ctrl.updateTruckMetrics
);

module.exports = router;
