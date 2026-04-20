const authService = require('../services/authService');
const { success, created, error } = require('../utils/response');

async function register(req, res, next) {
  try {
    const result = await authService.register(req.body);
    return created(res, result, 'Account created successfully');
  } catch (err) { next(err); }
}

async function login(req, res, next) {
  try {
    const result = await authService.login(req.body);
    return success(res, result, 'Login successful');
  } catch (err) { next(err); }
}

async function getProfile(req, res, next) {
  try {
    const profile = await authService.getProfile(req.user.uid);
    return success(res, profile);
  } catch (err) { next(err); }
}

module.exports = { register, login, getProfile };
