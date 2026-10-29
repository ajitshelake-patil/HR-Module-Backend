/**
 * Upgrades an EXISTING database (no data is deleted):
 *   - offer letters: include_ctc + emailed_at columns, SMS removed from send options
 *   - rec_email_log table
 *   - CTC two-level approval (Manager semi-approval -> Super Admin final), several interviewers
 *   - candidate document upload link (docs_token)
 *   - CTC breakup on State / Zone / Category minimum wage (rec_min_wages, rec_ctc_rule_settings)
 *   - loads the HHC Offer Letter, HHCPL Appointment Letter and HHC Surgeon Service Agreement designs from db/templates/*.html
 *
 * Safe to run more than once:   npm run db:upgrade
 * After editing db/templates/*.html, run it again to load your changes into the database.
 */
require('dotenv').config();
const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');

const TEMPLATES = [
  ['OFFER_LETTER', 'HHC Offer Letter', 'offer_letter.html'],
  ['APPOINTMENT_LETTER', 'HHCPL Appointment Letter', 'appointment_letter.html'],
  ['CONSULTANT_AGREEMENT', 'HHC Surgeon Service Agreement', 'consultant_agreement.html'],
];

(async () => {
  const db = process.env.DB_NAME || 'hhc_recruitment';
  const conn = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: db,
  });
  const hasColumn = async (table, col) => {
    const [[r]] = await conn.query(
      'SELECT COUNT(*) AS n FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? AND COLUMN_NAME = ?',
      [db, table, col]
    );
    return r.n > 0;
  };

  if (!(await hasColumn('rec_offer_letters', 'include_ctc'))) {
    await conn.query('ALTER TABLE rec_offer_letters ADD COLUMN include_ctc TINYINT(1) NOT NULL DEFAULT 0 AFTER offer_valid_till');
    console.log('+ rec_offer_letters.include_ctc');
  }
  if (!(await hasColumn('rec_offer_letters', 'emailed_at'))) {
    await conn.query('ALTER TABLE rec_offer_letters ADD COLUMN emailed_at DATETIME NULL AFTER sent_at');
    console.log('+ rec_offer_letters.emailed_at');
  }
  await conn.query(
    `UPDATE rec_offer_letters
        SET sent_via = NULLIF(TRIM(BOTH ',' FROM REPLACE(REPLACE(sent_via, 'SMS', ''), ',,', ',')), '')
      WHERE FIND_IN_SET('SMS', sent_via)`
  );
  await conn.query("ALTER TABLE rec_offer_letters MODIFY sent_via SET('EMAIL','WHATSAPP') NULL");

  await conn.query(`CREATE TABLE IF NOT EXISTS rec_email_log (
    id             BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    related_type   ENUM('OFFER_LETTER','APPOINTMENT_LETTER','TEST','OTHER') NOT NULL DEFAULT 'OTHER',
    related_id     BIGINT UNSIGNED NULL,
    to_email       VARCHAR(150) NULL,
    cc_email       VARCHAR(255) NULL,
    subject        VARCHAR(255) NOT NULL,
    status         ENUM('SENT','FAILED','SKIPPED') NOT NULL,
    error_message  VARCHAR(500) NULL,
    sent_by        INT UNSIGNED NULL,
    created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_mail_related (related_type, related_id)
  )`);

  // ---- CTC: HR prepares, Manager semi-approves, Super Admin gives final approval ----
  const [[statusCol]] = await conn.query(
    "SELECT COLUMN_TYPE AS t FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'rec_ctc_proposals' AND COLUMN_NAME = 'status'",
    [db]
  );
  const firstTwoLevelUpgrade = !statusCol.t.includes('MANAGER_APPROVED');
  await conn.query(
    "ALTER TABLE rec_ctc_proposals MODIFY status ENUM('DRAFT','SUBMITTED','MANAGER_APPROVED','APPROVED','REJECTED','SENT_BACK') NOT NULL DEFAULT 'DRAFT'"
  );
  await conn.query(
    "ALTER TABLE rec_ctc_approval_log MODIFY action ENUM('SUBMITTED','MANAGER_APPROVED','APPROVED','REJECTED','SENT_BACK') NOT NULL"
  );
  for (const [col, def] of [
    ['manager_action_by', 'INT UNSIGNED NULL AFTER submitted_at'],
    ['manager_action_at', 'DATETIME NULL AFTER manager_action_by'],
    ['manager_remarks', 'VARCHAR(500) NULL AFTER manager_action_at'],
  ]) {
    if (!(await hasColumn('rec_ctc_proposals', col))) {
      await conn.query(`ALTER TABLE rec_ctc_proposals ADD COLUMN ${col} ${def}`);
      console.log(`+ rec_ctc_proposals.${col}`);
    }
  }
  if (firstTwoLevelUpgrade) {
    // CTCs already waiting for Super Admin were entered by a Manager under the old flow,
    // so they stay with Super Admin (Manager stage counts as done).
    const [r] = await conn.query("UPDATE rec_ctc_proposals SET status = 'MANAGER_APPROVED' WHERE status = 'SUBMITTED'");
    if (r.affectedRows) console.log(`~ ${r.affectedRows} pending CTC(s) kept with Super Admin for final approval`);
  }

  // ---- Interviewed By: several interviewers per CTC ----
  await conn.query(`CREATE TABLE IF NOT EXISTS rec_ctc_interviewers (
    ctc_proposal_id  BIGINT UNSIGNED NOT NULL,
    user_id          INT UNSIGNED NOT NULL,
    PRIMARY KEY (ctc_proposal_id, user_id),
    FOREIGN KEY (ctc_proposal_id) REFERENCES rec_ctc_proposals(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id)         REFERENCES users(id)
  )`);
  if (await hasColumn('rec_ctc_proposals', 'interviewed_by')) {
    // copy the old single "Interviewed By" into the new list (old column is left as it is)
    await conn.query(
      `INSERT IGNORE INTO rec_ctc_interviewers (ctc_proposal_id, user_id)
       SELECT p.id, p.interviewed_by FROM rec_ctc_proposals p JOIN users u ON u.id = p.interviewed_by`
    );
  }

  // ---- Employee codes: one shared HHCPL series for employees + consultants ----
  // Last code already issued in the existing register is HHCPL1630, so the next one is HHCPL1631.
  // Runs once (while the prefix is still the old one); never moves the counter backwards.
  const HHCPL_LAST_ISSUED = 1630;
  const [[seq]] = await conn.query("SELECT prefix, last_number FROM employee_code_sequences WHERE code_type = 'EMPLOYEE'");
  if (!seq) {
    await conn.query(
      "INSERT INTO employee_code_sequences (code_type, prefix, padding, last_number) VALUES ('EMPLOYEE', 'HHCPL', 4, ?)",
      [HHCPL_LAST_ISSUED]
    );
    console.log(`+ employee code series HHCPL (next: HHCPL${HHCPL_LAST_ISSUED + 1})`);
  } else if (seq.prefix !== 'HHCPL') {
    const [[mx]] = await conn.query(
      "SELECT MAX(CAST(SUBSTRING(employee_code, 6) AS UNSIGNED)) AS n FROM employees WHERE employee_code REGEXP '^HHCPL[0-9]+$'"
    );
    const last = Math.max(HHCPL_LAST_ISSUED, Number(mx.n || 0));
    await conn.query(
      "UPDATE employee_code_sequences SET prefix = 'HHCPL', padding = 4, last_number = ? WHERE code_type IN ('EMPLOYEE','CONSULTANT')",
      [last]
    );
    console.log(`~ employee codes now HHCPL, shared by employees and consultants (next: HHCPL${last + 1}); existing codes unchanged`);
  }

  // ---- Reporting Manager role (can be chosen as a candidate's reporting manager in CTC entry) ----
  // stored as 'REPORTING MANAGER' (with a space); users saved earlier as 'REPORTING_MANAGER' are converted
  await conn.query("ALTER TABLE users MODIFY role ENUM('SUPER_ADMIN','HR','MANAGER','REPORTING_MANAGER','REPORTING MANAGER') NOT NULL");
  await conn.query("UPDATE users SET role = 'REPORTING MANAGER' WHERE role = 'REPORTING_MANAGER'");
  await conn.query("ALTER TABLE users MODIFY role ENUM('SUPER_ADMIN','HR','MANAGER','REPORTING MANAGER') NOT NULL");

  // ---- Super Admin signature at final approval (printed on offer / appointment letters and agreements) ----
  if (!(await hasColumn('users', 'signature_path'))) {
    await conn.query('ALTER TABLE users ADD COLUMN signature_path VARCHAR(255) NULL');
    console.log('+ users.signature_path');
  }
  if (!(await hasColumn('rec_ctc_proposals', 'approval_signature_path'))) {
    await conn.query('ALTER TABLE rec_ctc_proposals ADD COLUMN approval_signature_path VARCHAR(255) NULL AFTER approval_remarks');
    console.log('+ rec_ctc_proposals.approval_signature_path');
  }

  // ---- Candidate document upload link ----
  if (!(await hasColumn('rec_candidates', 'docs_token'))) {
    await conn.query('ALTER TABLE rec_candidates ADD COLUMN docs_token CHAR(64) NULL UNIQUE AFTER resume_original_name');
    console.log('+ rec_candidates.docs_token');
  }
  // give a link to candidates who have already accepted the offer / signed the agreement
  const [linked] = await conn.query(
    `UPDATE rec_candidates c
        SET c.docs_token = SHA2(CONCAT(c.id, '-', RAND(), '-', NOW(6), '-', UUID()), 256)
      WHERE c.docs_token IS NULL
        AND c.status IN ('OFFER_ACCEPTED','AGREEMENT_GENERATED','DOCS_PENDING')
        AND (EXISTS (SELECT 1 FROM rec_offer_letters o WHERE o.candidate_id = c.id AND o.candidate_response = 'ACCEPTED')
          OR EXISTS (SELECT 1 FROM rec_consultant_agreements a WHERE a.candidate_id = c.id AND a.status = 'SIGNED'))`
  );
  if (linked.affectedRows) console.log(`~ document upload link created for ${linked.affectedRows} candidate(s)`);

  // ---- CTC breakup on State / Zone / Category minimum wage ----
  await conn.query(`CREATE TABLE IF NOT EXISTS rec_min_wages (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    state           VARCHAR(60)  NOT NULL,
    zone            VARCHAR(30)  NOT NULL,
    category        VARCHAR(80)  NOT NULL,
    monthly_amount  DECIMAL(12,2) NOT NULL,
    is_active       TINYINT(1) NOT NULL DEFAULT 1,
    UNIQUE KEY uq_wage (state, zone, category)
  )`);
  await conn.query(`CREATE TABLE IF NOT EXISTS rec_ctc_rule_settings (
    setting_key    VARCHAR(40) PRIMARY KEY,
    setting_value  DECIMAL(12,2) NOT NULL,
    description    VARCHAR(200) NOT NULL
  )`);
  for (const [col, def] of [
    ['wage_state', 'VARCHAR(60) NULL AFTER compensation_type'],
    ['wage_zone', 'VARCHAR(30) NULL AFTER wage_state'],
    ['wage_category', 'VARCHAR(80) NULL AFTER wage_zone'],
    ['min_wage_monthly', 'DECIMAL(12,2) NULL AFTER wage_category'],
  ]) {
    if (!(await hasColumn('rec_ctc_proposals', col))) {
      await conn.query(`ALTER TABLE rec_ctc_proposals ADD COLUMN ${col} ${def}`);
      console.log(`+ rec_ctc_proposals.${col}`);
    }
  }
  // seed rows (INSERT IGNORE - wages / rules you already changed are not overwritten)
  const seedSql = fs.readFileSync(path.join(__dirname, '..', 'db', 'ctc_rules_seed.sql'), 'utf8').replace(/^--.*$/gm, '');
  for (const stmt of seedSql.split(/;\s*$/m).map((x) => x.trim()).filter(Boolean)) await conn.query(stmt);
  const [[wc]] = await conn.query('SELECT COUNT(*) AS n FROM rec_min_wages');
  console.log(`✓ minimum wage table ready (${wc.n} rows) and CTC rules loaded`);
  // same component names / order as the Excel (Basic + DA, Conveyance, HRA)
  await conn.query("UPDATE rec_salary_components SET component_name = 'Basic + DA' WHERE component_code = 'BASIC' AND component_name = 'Basic Salary'");
  await conn.query("UPDATE rec_salary_components SET display_order = 2 WHERE component_code = 'CONV' AND display_order = 3");
  await conn.query("UPDATE rec_salary_components SET display_order = 3 WHERE component_code = 'HRA' AND display_order = 2");

  const [[admin]] = await conn.query("SELECT id FROM users WHERE role = 'SUPER_ADMIN' ORDER BY id LIMIT 1");
  for (const [type, name, file] of TEMPLATES) {
    const body = fs.readFileSync(path.join(__dirname, '..', 'db', 'templates', file), 'utf8');
    const [[row]] = await conn.query(
      'SELECT id FROM rec_letter_templates WHERE template_type = ? ORDER BY is_default DESC, id LIMIT 1',
      [type]
    );
    if (row) {
      await conn.query('UPDATE rec_letter_templates SET template_name = ?, body_html = ?, is_default = 1, is_active = 1 WHERE id = ?', [
        name,
        body,
        row.id,
      ]);
    } else {
      await conn.query(
        'INSERT INTO rec_letter_templates (template_type, template_name, body_html, is_default, created_by) VALUES (?, ?, ?, 1, ?)',
        [type, name, body, admin ? admin.id : 1]
      );
    }
    // only the attached format is used: switch off any other (old "Standard") templates of this type
    await conn.query('UPDATE rec_letter_templates SET is_active = 0, is_default = 0 WHERE template_type = ? AND id <> ?', [
      type,
      row ? row.id : (await conn.query('SELECT MAX(id) AS id FROM rec_letter_templates WHERE template_type = ?', [type]))[0][0].id,
    ]);
    console.log(`✓ ${name} loaded from db/templates/${file} (other ${type} templates switched off)`);
  }
  await conn.end();
  console.log('Upgrade complete.');
})().catch((e) => {
  console.error('Upgrade failed:', e.message);
  process.exit(1);
});
