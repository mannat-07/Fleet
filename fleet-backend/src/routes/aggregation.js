const router = require('express').Router();
const { body, query } = require('express-validator');
const { validate } = require('../middleware/validate');
const { authenticate } = require('../middleware/auth');
const ctrl = require('../controllers/aggregationController');

router.use(authenticate);

// GET /api/fleet/summary
router.get('/summary', ctrl.getFleetSummary);

// GET /api/fleet/active-trucks
router.get('/active-trucks', ctrl.getActiveTrucks);

// GET /api/fleet/earnings?period=daily|weekly|monthly
router.get('/earnings',
  [query('period').optional().isIn(['daily', 'weekly', 'monthly'])],
  validate,
  ctrl.getEarnings
);

// POST /api/fleet/earnings
router.post('/earnings',
  [
    body('truckId').notEmpty().withMessage('truckId is required'),
    body('amount').isFloat({ min: 0 }).withMessage('amount must be a positive number'),
    body('description').optional().trim(),
    body('tripId').optional().trim(),
  ],
  validate,
  ctrl.recordEarning
);

module.exports = router;
