const router = require('express').Router();
const { authenticate } = require('../middleware/auth');
const ctrl = require('../controllers/notificationController');

router.use(authenticate);

// GET /api/notifications
router.get('/', ctrl.getNotifications);

module.exports = router;
