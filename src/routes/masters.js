const router = require('express').Router();
const { pool } = require('../config/db');
const { ah, httpError } = require('../utils/httpError');
const { allow } = require('../middleware/auth');
const { mailStatus, verifySmtp, sendMail } = require('../utils/mailer');
const { testEmail } = require('../utils/emailTemplates');

/** Dropdown data used across screens */
router.get(
  '/',
  ah(async (req, res) => {
    const [departments] = await pool.query('SELECT id, name FROM departments WHERE is_active = 1 ORDER BY name');
    const [designations] = await pool.query('SELECT id, name FROM designations WHERE is_active = 1 ORDER BY name');
    const [locations] = await pool.query('SELECT id, name FROM locations WHERE is_active = 1 ORDER BY name');
    const [users] = await pool.query('SELECT id, name, role FROM users WHERE is_active = 1 ORDER BY name');
    const [salaryComponents] = await pool.query(
      'SELECT * FROM rec_salary_components WHERE is_active = 1 ORDER BY display_order'
    );
    const [documentTypes] = await pool.query('SELECT * FROM rec_document_types WHERE is_active = 1 ORDER BY display_order');
    const [templates] = await pool.query(
      'SELECT id, template_type, template_name, is_default FROM rec_letter_templates WHERE is_active = 1 ORDER BY template_type, is_default DESC'
    );
    // CTC breakup rules: minimum wage per State / Zone / Category + percentages
    const [minWages] = await pool.query(
      'SELECT state, zone, category, monthly_amount FROM rec_min_wages WHERE is_active = 1 ORDER BY state, zone, monthly_amount'
    );
    const [ruleRows] = await pool.query('SELECT setting_key, setting_value FROM rec_ctc_rule_settings');
    const ctcRules = Object.fromEntries(ruleRows.map((r) => [r.setting_key, Number(r.setting_value)]));
    res.json({ departments, designations, locations, users, salaryComponents, documentTypes, templates, minWages, ctcRules });
  })
);

/** Dashboard counts by status */
router.get(
  '/dashboard',
  ah(async (req, res) => {
    const [byStatus] = await pool.query('SELECT status, COUNT(*) AS count FROM rec_candidates GROUP BY status');
    const [[pending]] = await pool.query(
      `SELECT SUM(status = 'SUBMITTED') AS manager, SUM(status = 'MANAGER_APPROVED') AS final
         FROM rec_ctc_proposals WHERE status IN ('SUBMITTED','MANAGER_APPROVED')`
    );
    const [[employees]] = await pool.query("SELECT COUNT(*) AS count FROM employees WHERE status = 'ACTIVE'");
    const managerCount = Number(pending.manager || 0);
    const finalCount = Number(pending.final || 0);
    // Manager sees what waits for them, Super Admin what waits for final approval, HR sees both
    const pendingApprovals = { MANAGER: managerCount, SUPER_ADMIN: finalCount }[req.user.role] ?? managerCount + finalCount;
    res.json({ byStatus, pendingApprovals, pendingManager: managerCount, pendingFinal: finalCount, activeEmployees: employees.count });
  })
);

/** Email set-up status (shown on offer / appointment screens) */
router.get('/mail-status', (req, res) => res.json(mailStatus()));

/** Super Admin: check SMTP login and optionally send a test email */
router.post(
  '/test-mail',
  allow(),
  ah(async (req, res) => {
    const check = await verifySmtp();
    if (!check.ok) throw httpError(400, `SMTP check failed: ${check.error}`);
    const to = (req.body?.to || '').trim();
    if (!to) return res.json({ message: 'SMTP login OK' });
    const mail = testEmail();
    const r = await sendMail({ to, subject: mail.subject, html: mail.html, relatedType: 'TEST', sentBy: req.user.id });
    if (!r.sent) throw httpError(400, `Test email failed: ${r.error}`);
    res.json({ message: `Test email sent to ${to}` });
  })
);

/** Last 100 emails (Super Admin) */
router.get(
  '/email-log',
  allow(),
  ah(async (req, res) => {
    const [rows] = await pool.query(
      `SELECT l.*, u.name AS sent_by_name FROM rec_email_log l LEFT JOIN users u ON u.id = l.sent_by
        ORDER BY l.id DESC LIMIT 100`
    );
    res.json(rows);
  })
);

module.exports = router;
