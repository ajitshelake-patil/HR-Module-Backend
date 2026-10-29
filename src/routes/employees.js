/**
 * STEP 6 - Employee ID Generation
 * STEP 7 - Employee Master
 */
const router = require('express').Router();
const { pool, withTransaction } = require('../config/db');
const { ah, httpError } = require('../utils/httpError');
const { allow } = require('../middleware/auth');
const { STATUS, getCandidateForUpdate, assertStatus, setStatus } = require('../utils/status');
const { nextEmployeeCode } = require('../utils/sequence');

function addMonths(dateStr, months) {
  const d = new Date(String(dateStr).slice(0, 10) + 'T00:00:00Z');
  d.setUTCMonth(d.getUTCMonth() + Number(months));
  d.setUTCDate(d.getUTCDate() - 1);
  return d.toISOString().slice(0, 10);
}

/** Generate Employee Code and move candidate to Employee Master (single transaction) */
router.post(
  '/generate/:candidateId',
  allow('HR'),
  ah(async (req, res) => {
    const out = await withTransaction(async (conn) => {
      const cand = await getCandidateForUpdate(conn, req.params.candidateId);
      assertStatus(cand, [STATUS.DOCS_VERIFIED], 'generate Employee ID');

      const [[p]] = await conn.query(
        "SELECT * FROM rec_ctc_proposals WHERE candidate_id = ? AND status = 'APPROVED' ORDER BY version_no DESC LIMIT 1",
        [cand.id]
      );
      if (!p) throw httpError(400, 'No approved CTC found');

      let offer = null;
      let agreement = null;
      let doj;
      if (cand.candidate_type === 'EMPLOYEE') {
        [[offer]] = await conn.query(
          "SELECT * FROM rec_offer_letters WHERE candidate_id = ? AND candidate_response = 'ACCEPTED' ORDER BY id DESC LIMIT 1",
          [cand.id]
        );
        if (!offer) throw httpError(400, 'No accepted offer letter found');
        doj = offer.joining_date;
      } else {
        [[agreement]] = await conn.query(
          "SELECT * FROM rec_consultant_agreements WHERE candidate_id = ? AND status IN ('GENERATED','SENT','SIGNED') ORDER BY id DESC LIMIT 1",
          [cand.id]
        );
        if (!agreement) throw httpError(400, 'No consultant agreement found');
        doj = agreement.agreement_start_date;
      }
      if (req.body?.date_of_joining) doj = req.body.date_of_joining; // HR can correct actual joining date

      const code = await nextEmployeeCode(conn, cand.candidate_type);
      const [r] = await conn.query('INSERT INTO employees SET ?', [
        {
          employee_code: code,
          candidate_id: cand.id,
          employee_category: cand.candidate_type,
          first_name: cand.first_name,
          middle_name: cand.middle_name,
          last_name: cand.last_name,
          gender: cand.gender,
          date_of_birth: cand.date_of_birth,
          mobile_no: cand.mobile_no,
          official_email: req.body?.official_email || null,
          personal_email: cand.email,
          address: cand.address,
          city: cand.city,
          state: cand.state,
          pincode: cand.pincode,
          department_id: p.department_id,
          designation_id: p.designation_id,
          location_id: p.location_id,
          reporting_manager_id: p.reporting_manager_id,
          employment_type: p.employment_type,
          date_of_joining: doj,
          probation_end_date: p.employment_type === 'PROBATION' && p.probation_months ? addMonths(doj, p.probation_months) : null,
          ctc_proposal_id: p.id,
          offer_letter_id: offer?.id || null,
          consultant_agreement_id: agreement?.id || null,
          ctc_annual: p.ctc_annual,
          status: 'ACTIVE',
          created_by: req.user.id,
        },
      ]);
      await setStatus(conn, cand.id, cand.status, STATUS.ONBOARDED, req.user.id, `Employee Code ${code} generated; moved to Employee Master`);
      return { id: r.insertId, employee_code: code };
    });
    res.status(201).json({ ...out, message: `Employee Code ${out.employee_code} generated` });
  })
);

const EMP_SQL = `
  SELECT e.*, d.name AS department_name, g.name AS designation_name, l.name AS location_name,
         u.name AS reporting_manager_name, c.candidate_code,
         (SELECT COUNT(*) FROM rec_appointment_letters a WHERE a.employee_id = e.id) AS appointment_letters
    FROM employees e
    JOIN rec_candidates c ON c.id = e.candidate_id
    LEFT JOIN departments d ON d.id = e.department_id
    LEFT JOIN designations g ON g.id = e.designation_id
    LEFT JOIN locations l ON l.id = e.location_id
    LEFT JOIN users u ON u.id = e.reporting_manager_id`;

router.get(
  '/',
  ah(async (req, res) => {
    const { q, status, category } = req.query;
    const where = [];
    const params = [];
    if (status) { where.push('e.status = ?'); params.push(status); }
    if (category) { where.push('e.employee_category = ?'); params.push(category); }
    if (q) {
      where.push("(e.employee_code LIKE ? OR CONCAT(e.first_name,' ',e.last_name) LIKE ? OR e.mobile_no LIKE ?)");
      params.push(`%${q}%`, `%${q}%`, `%${q}%`);
    }
    const [rows] = await pool.query(`${EMP_SQL} ${where.length ? 'WHERE ' + where.join(' AND ') : ''} ORDER BY e.id DESC`, params);
    res.json(rows);
  })
);

router.get(
  '/:id',
  ah(async (req, res) => {
    const [[e]] = await pool.query(`${EMP_SQL} WHERE e.id = ?`, [req.params.id]);
    if (!e) throw httpError(404, 'Employee not found');
    const [[proposal]] = await pool.query('SELECT * FROM rec_ctc_proposals WHERE id = ?', [e.ctc_proposal_id]);
    const [components] = await pool.query(
      `SELECT pc.monthly_amount, pc.annual_amount, sc.component_name, sc.component_group
         FROM rec_ctc_proposal_components pc JOIN rec_salary_components sc ON sc.id = pc.component_id
        WHERE pc.ctc_proposal_id = ? ORDER BY sc.display_order`,
      [e.ctc_proposal_id]
    );
    const [documents] = await pool.query(
      `SELECT d.id, d.document_number, d.file_path, d.verification_status, t.document_name
         FROM rec_candidate_documents d JOIN rec_document_types t ON t.id = d.document_type_id
        WHERE d.candidate_id = ? AND d.verification_status = 'VERIFIED' ORDER BY t.display_order`,
      [e.candidate_id]
    );
    const [letters] = await pool.query(
      'SELECT id, appointment_letter_no, letter_date, pdf_file_path, issued_at FROM rec_appointment_letters WHERE employee_id = ? ORDER BY id DESC',
      [e.id]
    );
    res.json({ ...e, proposal, components, documents, appointmentLetters: letters });
  })
);

/** Limited edit in master (contact / email / status) */
router.put(
  '/:id',
  allow('HR'),
  ah(async (req, res) => {
    const allowed = ['official_email', 'mobile_no', 'address', 'city', 'state', 'pincode', 'status'];
    const data = {};
    for (const f of allowed) if (req.body[f] !== undefined) data[f] = req.body[f] || null;
    if (!Object.keys(data).length) throw httpError(400, 'Nothing to update');
    await pool.query('UPDATE employees SET ? WHERE id = ?', [data, req.params.id]);
    res.json({ message: 'Employee updated' });
  })
);

module.exports = router;
