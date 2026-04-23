const logger = require('../utils/logger');

// eslint-disable-next-line no-unused-vars
function errorHandler(err, req, res, next) {
  logger.error(err.message, { stack: err.stack, path: req.path });

  // Firebase/Firestore errors (code can be string or number)
  if (err.code && (typeof err.code === 'string' && err.code.startsWith('firestore/'))) {
    return res.status(503).json({ success: false, message: 'Database error', code: err.code });
  }
  // Firestore gRPC errors have numeric codes (e.g. 9 = FAILED_PRECONDITION)
  if (err.code === 9 || (err.message && err.message.includes('FAILED_PRECONDITION'))) {
    return res.status(503).json({
      success: false,
      message: 'Database index required. Check server logs for the index creation link.',
      code: 'firestore/index-required',
    });
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
