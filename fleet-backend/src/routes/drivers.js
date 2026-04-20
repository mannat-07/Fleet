const router = require('express').Router();
const { body, param } = require('express-validator');
const { validate } = require('../middleware/validate');
const { authenticate } = require('../middleware/auth');
const ctrl = require('../controllers/driverController');

router.use(authenticate);

// POST /api/drivers
router.post('/',
  [
    body('name').trim().notEmpty().withMessage('Driver name is required'),
    body('phone').optional().isMobilePhone(),
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
