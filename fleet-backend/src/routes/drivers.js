const router = require('express').Router();
const { body, param } = require('express-validator');
const { validate } = require('../middleware/validate');
const { authenticate } = require('../middleware/auth');
const ctrl = require('../controllers/driverController');

router.use(authenticate);

// GET /api/drivers/me  — driver fetches their own data (must be before /:driverId)
router.get('/me', ctrl.getMyProfile);

// POST /api/drivers
router.post('/',
  [
    body('name').trim().notEmpty().withMessage('Driver name is required'),
    body('email').isEmail().normalizeEmail().withMessage('Valid email is required'),
    body('password').optional().isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
    body('phone').optional(),
    body('licenseNumber').optional().trim(),
    body('licenseExpiry').optional().isISO8601().withMessage('licenseExpiry must be a valid date'),
  ],
  validate,
  ctrl.addDriver
);

// GET /api/drivers
router.get('/', ctrl.getDrivers);

// GET /api/drivers/:driverId
router.get('/:driverId',
  [param('driverId').notEmpty()],
  validate,
  ctrl.getDriver
);

// DELETE /api/drivers/:driverId
router.delete('/:driverId',
  [param('driverId').notEmpty()],
  validate,
  ctrl.deleteDriver
);

// POST /api/drivers/:driverId/assign
router.post('/:driverId/assign',
  [
    param('driverId').notEmpty(),
    body('truckId').notEmpty().withMessage('truckId is required'),
  ],
  validate,
  ctrl.assignDriver
);

// POST /api/drivers/:driverId/unassign
router.post('/:driverId/unassign',
  [param('driverId').notEmpty()],
  validate,
  ctrl.unassignDriver
);

module.exports = router;
