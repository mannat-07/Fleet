const router = require('express').Router();
const { body, param } = require('express-validator');
const { validate } = require('../middleware/validate');
const { authenticate } = require('../middleware/auth');
const ctrl = require('../controllers/mlController');

router.use(authenticate);

// POST /api/ml/predict/driver — Get ML prediction for a driver
router.post('/predict/driver',
  [
    body('driverId').notEmpty().withMessage('driverId is required'),
  ],
  validate,
  ctrl.predictDriver
);

// POST /api/ml/predict/truck — Get ML prediction for a truck
router.post('/predict/truck',
  [
    body('truckId').notEmpty().withMessage('truckId is required'),
  ],
  validate,
  ctrl.predictTruck
);

// GET /api/ml/recommendations/drivers — Get top recommended drivers
router.get('/recommendations/drivers', ctrl.getDriverRecommendations);

// GET /api/ml/recommendations/trucks — Get top recommended trucks
router.get('/recommendations/trucks', ctrl.getTruckRecommendations);

// POST /api/ml/train/driver — Trigger driver model retraining
router.post('/train/driver', ctrl.trainDriverModel);

// POST /api/ml/train/truck — Trigger truck model retraining
router.post('/train/truck', ctrl.trainTruckModel);

module.exports = router;
