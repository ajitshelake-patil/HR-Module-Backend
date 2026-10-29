const jwt = require('jsonwebtoken');
const { pool } = require('../config/db');

async function authenticate(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : req.query.token;
  if (!token) return res.status(401).json({ message: 'Not logged in' });
  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET);
  } catch {
    return res.status(401).json({ message: 'Session expired, please log in again' });
  }
  // a deactivated user (users.is_active = 0) is signed out straight away, not only at the next login
  try {
    const [[u]] = await pool.query('SELECT is_active FROM users WHERE id = ?', [req.user.id]);
    if (!u || !u.is_active) return res.status(401).json({ message: 'Your account is deactivated. Please contact HR.' });
  } catch (err) {
    return next(err);
  }
  return next();
}

/** allow('HR','MANAGER') - SUPER_ADMIN always passes */
function allow(...roles) {
  return (req, res, next) => {
    if (req.user.role === 'SUPER_ADMIN' || roles.includes(req.user.role)) return next();
    return res.status(403).json({ message: 'You do not have access to this action' });
  };
}

module.exports = { authenticate, allow };
