const router = require('express').Router();
const { body, param } = require('express-validator');
const { validate } = require('../middleware/validate');
const { authenticate } = require('../middleware/auth');
const ctrl = require('../controllers/insuranceController');

router.use(authenticate);

// POST /api/insurance
router.post('/',
  [
    body('truckId').notEmpty().withMessage('truckId is required'),
    body('policyNumber').trim().notEmpty().withMessage('Policy number is required'),
    body('provider').trim().notEmpty().withMessage('Provider is required'),
    body('startDate').isISO8601().withMessage('startDate must be a valid ISO 8601 date'),
    body('expiryDate').isISO8601().withMessage('expiryDate must be a valid ISO 8601 date'),
    body('expiryDate').custom((expiryDate, { req }) => {
      if (req.body.startDate && new Date(req.body.startDate) >= new Date(expiryDate)) {
        throw new Error('Start date must be before expiry date');
      }
      return true;
    }),
  ],
  validate,
  ctrl.addInsurance
);

// GET /api/insurance
router.get('/', ctrl.getInsurances);

// GET /api/insurance/:insuranceId
router.get('/:insuranceId',
  [param('insuranceId').notEmpty()],
  validate,
  ctrl.getInsurance
);

// PATCH /api/insurance/:insuranceId
router.patch('/:insuranceId',
  [
    param('insuranceId').notEmpty(),
    body('policyNumber').optional().trim().notEmpty().withMessage('Policy number cannot be empty'),
    body('provider').optional().trim().notEmpty().withMessage('Provider cannot be empty'),
    body('startDate').optional().isISO8601().withMessage('startDate must be a valid ISO 8601 date'),
    body('expiryDate').optional().isISO8601().withMessage('expiryDate must be a valid ISO 8601 date'),
    body('expiryDate').optional().custom((expiryDate, { req }) => {
      if (req.body.startDate && new Date(req.body.startDate) >= new Date(expiryDate)) {
        throw new Error('Start date must be before expiry date');
      }
      return true;
    }),
  ],
  validate,
  ctrl.updateInsurance
);

// DELETE /api/insurance/:insuranceId
router.delete('/:insuranceId',
  [param('insuranceId').notEmpty()],
  validate,
  ctrl.deleteInsurance
);

module.exports = router;
