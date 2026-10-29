/**
 * STEP 1 - Candidate Registration & Resume Upload (HR Executive)
 */
const router = require('express').Router();
const { pool, withTransaction } = require('../config/db');
const { ah, httpError } = require('../utils/httpError');
const { allow } = require('../middleware/auth');
const { uploader, relPath } = require('../middleware/upload');
const { nextCandidateCode } = require('../utils/sequence');
const { STATUS } = require('../utils/status');

const upload = uploader('resumes');

const FIELDS = [
  'candidate_type', 'first_name', 'middle_name', 'last_name', 'gender', 'date_of_birth',
  'mobile_no', 'alternate_mobile_no', 'email', 'address', 'city', 'state', 'pincode',
  'highest_qualification', 'specialization', 'total_experience_years', 'current_employer',
  'current_ctc', 'expected_ctc', 'notice_period_days', 'applied_department_id',
  'applied_designation_id', 'applied_location_id', 'source', 'source_remarks',
];

function pickFields(body) {
  const out = {};
  for (const f of FIELDS) {
    if (body[f] === undefined) continue;
    out[f] = body[f] === '' ? null : body[f];
  }
  return out;
}

function validate(data, isNew) {
  const required = ['first_name', 'last_name', 'mobile_no', 'email'];
  if (isNew) {
    for (const f of required) if (!data[f]) throw httpError(400, `${f.replace(/_/g, ' ')} is required`);
  }
  if (data.mobile_no && !/^[6-9]\d{9}$/.test(data.mobile_no)) throw httpError(400, 'Enter a valid 10-digit mobile number');
  if (data.email && !/^\S+@\S+\.\S+$/.test(data.email)) throw httpError(400, 'Enter a valid email ID');
  if (data.pincode && !/^\d{6}$/.test(data.pincode)) throw httpError(400, 'Pincode must be 6 digits');
}

const LIST_SQL = `
  SELECT c.id, c.candidate_code, c.candidate_type, c.first_name, c.last_name, c.mobile_no, c.email,
         c.status, c.created_at, d.name AS department_name, g.name AS designation_name, l.name AS location_name
    FROM rec_candidates c
    LEFT JOIN departments d ON d.id = c.applied_department_id
    LEFT JOIN designations g ON g.id = c.applied_designation_id
    LEFT JOIN locations l ON l.id = c.applied_location_id`;

router.get(
  '/',
  ah(async (req, res) => {
    const { status, type, q } = req.query;
    const where = [];
    const params = [];
    if (status) {
      where.push(`c.status IN (${status.split(',').map(() => '?').join(',')})`);
      params.push(...status.split(','));
    }
    if (type) {
      where.push('c.candidate_type = ?');
      params.push(type);
    }
    if (q) {
      where.push("(CONCAT(c.first_name,' ',c.last_name) LIKE ? OR c.mobile_no LIKE ? OR c.candidate_code LIKE ? OR c.email LIKE ?)");
      params.push(`%${q}%`, `%${q}%`, `%${q}%`, `%${q}%`);
    }
    const sql = `${LIST_SQL} ${where.length ? 'WHERE ' + where.join(' AND ') : ''} ORDER BY c.id DESC LIMIT 500`;
    const [rows] = await pool.query(sql, params);
    res.json(rows);
  })
);

router.get(
  '/:id',
  ah(async (req, res) => {
    const [[cand]] = await pool.query(
      `SELECT c.*, d.name AS department_name, g.name AS designation_name, l.name AS location_name
         FROM rec_candidates c
         LEFT JOIN departments d ON d.id = c.applied_department_id
         LEFT JOIN designations g ON g.id = c.applied_designation_id
         LEFT JOIN locations l ON l.id = c.applied_location_id
        WHERE c.id = ?`,
      [req.params.id]
    );
    if (!cand) throw httpError(404, 'Candidate not found');
    const [timeline] = await pool.query(
      `SELECT s.*, u.name AS changed_by_name FROM rec_candidate_status_log s
         LEFT JOIN users u ON u.id = s.changed_by
        WHERE s.candidate_id = ? ORDER BY s.id`,
      [req.params.id]
    );
    const [[latestProposal]] = await pool.query(
      'SELECT id, version_no, status, ctc_annual, compensation_type FROM rec_ctc_proposals WHERE candidate_id = ? ORDER BY version_no DESC LIMIT 1',
      [req.params.id]
    );
    const [[offer]] = await pool.query(
      'SELECT id, offer_letter_no, candidate_response, pdf_file_path FROM rec_offer_letters WHERE candidate_id = ? ORDER BY id DESC LIMIT 1',
      [req.params.id]
    );
    const [[agreement]] = await pool.query(
      'SELECT id, agreement_no, status, pdf_file_path FROM rec_consultant_agreements WHERE candidate_id = ? ORDER BY id DESC LIMIT 1',
      [req.params.id]
    );
    const [[employee]] = await pool.query('SELECT id, employee_code FROM employees WHERE candidate_id = ?', [req.params.id]);
    res.json({ ...cand, timeline, latestProposal: latestProposal || null, offer: offer || null, agreement: agreement || null, employee: employee || null });
  })
);

router.post(
  '/',
  allow('HR'),
  upload.single('resume'),
  ah(async (req, res) => {
    const data = pickFields(req.body);
    validate(data, true);
    const [[dup]] = await pool.query(
      "SELECT candidate_code FROM rec_candidates WHERE (mobile_no = ? OR email = ?) AND status <> 'ONBOARDED' LIMIT 1",
      [data.mobile_no, data.email]
    );
    if (dup) throw httpError(409, `A candidate with this mobile / email already exists (${dup.candidate_code})`);

    const id = await withTransaction(async (conn) => {
      data.candidate_code = await nextCandidateCode(conn);
      data.created_by = req.user.id;
      data.status = STATUS.REGISTERED;
      if (req.file) {
        data.resume_file_path = relPath('resumes', req.file.filename);
        data.resume_original_name = req.file.originalname;
      }
      const [r] = await conn.query('INSERT INTO rec_candidates SET ?', [data]);
      await conn.query(
        'INSERT INTO rec_candidate_status_log (candidate_id, from_status, to_status, remarks, changed_by) VALUES (?, NULL, ?, ?, ?)',
        [r.insertId, STATUS.REGISTERED, 'Candidate registered', req.user.id]
      );
      return r.insertId;
    });
    res.status(201).json({ id, message: 'Candidate registered' });
  })
);

router.put(
  '/:id',
  allow('HR'),
  upload.single('resume'),
  ah(async (req, res) => {
    const [[cand]] = await pool.query('SELECT status FROM rec_candidates WHERE id = ?', [req.params.id]);
    if (!cand) throw httpError(404, 'Candidate not found');
    if (cand.status === STATUS.ONBOARDED) throw httpError(400, 'Candidate is already onboarded; edit in Employee Master');
    const data = pickFields(req.body);
    validate(data, false);
    // Candidate type cannot change once CTC process has started
    if (data.candidate_type && cand.status !== STATUS.REGISTERED) delete data.candidate_type;
    if (req.file) {
      data.resume_file_path = relPath('resumes', req.file.filename);
      data.resume_original_name = req.file.originalname;
    }
    data.updated_by = req.user.id;
    await pool.query('UPDATE rec_candidates SET ? WHERE id = ?', [data, req.params.id]);
    res.json({ message: 'Candidate updated' });
  })
);

module.exports = router;
