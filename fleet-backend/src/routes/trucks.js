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

module.exports = router;
