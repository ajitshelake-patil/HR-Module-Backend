/**
 * Users (login accounts) - Manager and Super Admin
 *   GET   /api/users?page=1&limit=10   one page of users  -> { rows, total, page, limit, pages }
 *   POST  /api/users                   add a user: name, email, password, role, is_active (1 = active, 0 = inactive)
 *   PATCH /api/users/:id/status        { is_active: 0 | 1 }  - Deactivate / Activate (users.is_active)
 * A Manager can add HR Executives, Managers and Reporting Managers; only the Super Admin can add another Super Admin.
 * Note: passwords are stored the same way the current login checks them (plain text) - see the review plan.
 */
const router = require('express').Router();
const { pool } = require('../config/db');
const { ah, httpError } = require('../utils/httpError');
const { allow } = require('../middleware/auth');

const ROLES = ['HR', 'MANAGER', 'REPORTING MANAGER', 'SUPER_ADMIN'];

router.get(
  '/',
  allow('MANAGER'),
  ah(async (req, res) => {
    const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || 10, 1), 100);
    const [[{ total }]] = await pool.query('SELECT COUNT(*) AS total FROM users');
    const pages = Math.max(Math.ceil(total / limit), 1);
    const page = Math.min(Math.max(parseInt(req.query.page, 10) || 1, 1), pages);
    const [rows] = await pool.query(
      'SELECT id, name, email, role, is_active, created_at FROM users ORDER BY id DESC LIMIT ? OFFSET ?',
      [limit, (page - 1) * limit]
    );
    res.json({ rows, total, page, limit, pages });
  })
);

/** Deactivate (is_active = 0) or Activate (is_active = 1) a user */
router.patch(
  '/:id/status',
  allow('MANAGER'),
  ah(async (req, res) => {
    const id = Number(req.params.id);
    const isActive = Number(req.body?.is_active);
    if (![0, 1].includes(isActive)) throw httpError(400, 'is_active must be 0 or 1');
    const [[u]] = await pool.query('SELECT id, name, role, is_active FROM users WHERE id = ?', [id]);
    if (!u) throw httpError(404, 'User not found');
    if (id === Number(req.user.id) && isActive === 0) throw httpError(400, 'You cannot deactivate your own account');
    if (u.role === 'SUPER_ADMIN' && req.user.role !== 'SUPER_ADMIN') {
      throw httpError(403, 'Only the Super Admin can change a Super Admin account');
    }
    if (u.role === 'SUPER_ADMIN' && isActive === 0) {
      const [[{ n }]] = await pool.query("SELECT COUNT(*) AS n FROM users WHERE role = 'SUPER_ADMIN' AND is_active = 1 AND id <> ?", [id]);
      if (!n) throw httpError(400, 'At least one Super Admin must stay active');
    }
    await pool.query('UPDATE users SET is_active = ? WHERE id = ?', [isActive, id]);
    res.json({ message: `${u.name} ${isActive ? 'activated' : 'deactivated'}` });
  })
);

router.post(
  '/',
  allow('MANAGER'),
  ah(async (req, res) => {
    const b = req.body || {};
    const name = String(b.name || '').trim();
    const email = String(b.email || '').trim().toLowerCase();
    const password = String(b.password || '');
    const role = String(b.role || '');
    const isActive = b.is_active === undefined || b.is_active === '' ? 1 : Number(b.is_active);

    if (!name) throw httpError(400, 'Name is required');
    if (name.length > 100) throw httpError(400, 'Name must be 100 characters or fewer');
    if (!/^\S+@\S+\.\S+$/.test(email)) throw httpError(400, 'Enter a valid email ID');
    if (password.length < 6) throw httpError(400, 'Password must be at least 6 characters');
    if (password.length > 100) throw httpError(400, 'Password must be 100 characters or fewer');
    if (!ROLES.includes(role)) throw httpError(400, 'Select a role');
    if (role === 'SUPER_ADMIN' && req.user.role !== 'SUPER_ADMIN') {
      throw httpError(403, 'Only the Super Admin can add another Super Admin');
    }
    if (![0, 1].includes(isActive)) throw httpError(400, 'Status must be 1 (Active) or 0 (Inactive)');

    // the database must already know the role (live_update_2026-10-27.sql adds REPORTING MANAGER);
    // otherwise MySQL would refuse it, or save the user with an empty role that shows nowhere
    const [[col]] = await pool.query(
      "SELECT COLUMN_TYPE AS t FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'role'"
    );
    if (col && !String(col.t).includes(`'${role}'`)) {
      throw httpError(400, `The database does not have the role ${role} yet. Run database/live_update_2026-10-27.sql on the server, then add the user again.`);
    }

    const [[dup]] = await pool.query('SELECT id FROM users WHERE email = ?', [email]);
    if (dup) throw httpError(409, 'A user with this email already exists');

    const [r] = await pool.query('INSERT INTO users (name, email, password, role, is_active) VALUES (?, ?, ?, ?, ?)', [
      name,
      email,
      password,
      role,
      isActive,
    ]);
    const [[saved]] = await pool.query('SELECT role FROM users WHERE id = ?', [r.insertId]);
    if (saved?.role !== role) {
      await pool.query('DELETE FROM users WHERE id = ?', [r.insertId]); // never leave a user with a blank role
      throw httpError(400, `The role ${role} could not be saved. Run database/live_update_2026-10-27.sql on the server, then add the user again.`);
    }
    res.status(201).json({ id: r.insertId, message: `User ${name} added` });
  })
);

module.exports = router;
