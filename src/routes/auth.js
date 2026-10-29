const router = require('express').Router();
const jwt = require('jsonwebtoken');
const { pool } = require('../config/db');
const { ah, httpError } = require('../utils/httpError');
const { authenticate } = require('../middleware/auth');

/** Simple login: email + password checked as plain text against the users table */
router.post(
  '/login',
  ah(async (req, res) => {
    const { email, password } = req.body || {};
    if (!email || !password) throw httpError(400, 'Email and password are required');
    const [[user]] = await pool.query(
      'SELECT id, name, email, role FROM users WHERE email = ? AND BINARY password = ? AND is_active = 1',
      [email.trim(), password]
    );
    if (!user) throw httpError(401, 'Invalid email or password');
    const payload = { id: user.id, name: user.name, email: user.email, role: user.role };
    const token = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || '12h' });
    res.json({ token, user: payload });
  })
);

router.get('/me', authenticate, (req, res) => res.json({ user: req.user }));

module.exports = router;
