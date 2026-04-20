const logger = require('../utils/logger');

// eslint-disable-next-line no-unused-vars
function errorHandler(err, req, res, next) {
  logger.error(err.message, { stack: err.stack, path: req.path });

  // Firebase errors
  if (err.code && err.code.startsWith('firestore/')) {
    return res.status(503).json({ success: false, message: 'Database error', code: err.code });
  }

  const statusCode = err.statusCode || err.status || 500;
  const message    = process.env.NODE_ENV === 'production' && statusCode === 500
    ? 'Internal server error'
    : err.message;

  res.status(statusCode).json({ success: false, message });
}

function notFoundHandler(req, res) {
  res.status(404).json({ success: false, message: `Route ${req.method} ${req.path} not found` });
}

module.exports = { errorHandler, notFoundHandler };
