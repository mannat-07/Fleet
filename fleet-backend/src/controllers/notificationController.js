const notificationService = require('../services/notificationService');
const { success } = require('../utils/response');

async function getNotifications(req, res, next) {
  try {
    const result = await notificationService.getNotifications(req.user.uid);
    return success(res, result);
  } catch (err) { next(err); }
}

module.exports = { getNotifications };
