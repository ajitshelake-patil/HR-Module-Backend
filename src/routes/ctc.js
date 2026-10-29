/**
 * STEP 2 - Candidate Selection & CTC Breakup (HR Executive)
 * STEP 3 - CTC Approval: semi-approval by Manager, then final approval by Super Admin
 *
 *   HR saves / submits  ->  SUBMITTED         (waiting for Manager)
 *   Manager approves    ->  MANAGER_APPROVED  (waiting for Super Admin)
 *   Super Admin approves->  APPROVED          (offer letter / agreement can be generated)
 *   Reject or Send Back at either level goes back to HR.
 * Surgeons (CONSULTANT) follow the same flow with fee terms instead of salary breakup.
 */
const router = require('express').Router();
const { pool, withTransaction } = require('../config/db');
const { ah, httpError } = require('../utils/httpError');
const { allow } = require('../middleware/auth');
const { STATUS, getCandidateForUpdate, assertStatus, setStatus } = require('../utils/status');
const fs = require('fs');
const { uploader, relPath, SIGNATURE_MAX_KB, SIGNATURE_TYPES, isImageFile } = require('../middleware/upload');

// Super Admin signature, uploaded with the final approval (PNG / JPG, max 10 KB)
const signatureUpload = uploader('signatures', { maxBytes: SIGNATURE_MAX_KB * 1024, allowed: SIGNATURE_TYPES });
const acceptSignature = (req, res, next) =>
  signatureUpload.single('signature')(req, res, (err) => {
    if (!err) return next();
    if (err.code === 'LIMIT_FILE_SIZE') return next(httpError(400, `Signature must be ${SIGNATURE_MAX_KB} KB or smaller.`));
    return next(httpError(400, 'Signature must be an image (PNG or JPG).'));
  });

const round2 = (n) => Math.round(Number(n || 0) * 100) / 100;
const num = (v) => (v === '' || v === null || v === undefined ? null : Number(v));

const PROPOSAL_DETAIL_SQL = `
  SELECT p.*, c.candidate_code, c.first_name, c.last_name, c.candidate_type, c.current_ctc, c.expected_ctc,
         c.specialization, c.total_experience_years,
         d.name AS department_name, g.name AS designation_name, l.name AS location_name,
         rm.name AS reporting_manager_name,
         (SELECT GROUP_CONCAT(iu.name ORDER BY iu.name SEPARATOR ', ')
            FROM rec_ctc_interviewers ri JOIN users iu ON iu.id = ri.user_id
           WHERE ri.ctc_proposal_id = p.id) AS interviewed_by_names,
         sb.name AS submitted_by_name, mb.name AS manager_action_by_name, ab.name AS approved_by_name
    FROM rec_ctc_proposals p
    JOIN rec_candidates c ON c.id = p.candidate_id
    LEFT JOIN departments d ON d.id = p.department_id
    LEFT JOIN designations g ON g.id = p.designation_id
    LEFT JOIN locations l ON l.id = p.location_id
    LEFT JOIN users rm ON rm.id = p.reporting_manager_id
    LEFT JOIN users sb ON sb.id = p.submitted_by
    LEFT JOIN users mb ON mb.id = p.manager_action_by
    LEFT JOIN users ab ON ab.id = p.approved_by`;

async function loadProposal(conn, id) {
  const [[p]] = await conn.query(`${PROPOSAL_DETAIL_SQL} WHERE p.id = ?`, [id]);
  if (!p) return null;
  const [components] = await conn.query(
    `SELECT pc.component_id, pc.monthly_amount, pc.annual_amount, sc.component_code, sc.component_name, sc.component_group
       FROM rec_ctc_proposal_components pc JOIN rec_salary_components sc ON sc.id = pc.component_id
      WHERE pc.ctc_proposal_id = ? ORDER BY sc.display_order`,
    [id]
  );
  const [log] = await conn.query(
    `SELECT a.*, u.name AS action_by_name FROM rec_ctc_approval_log a JOIN users u ON u.id = a.action_by
      WHERE a.ctc_proposal_id = ? ORDER BY a.id`,
    [id]
  );
  const [interviewers] = await conn.query(
    `SELECT u.id, u.name FROM rec_ctc_interviewers ri JOIN users u ON u.id = ri.user_id
      WHERE ri.ctc_proposal_id = ? ORDER BY u.name`,
    [id]
  );
  return { ...p, interviewers: interviewers.map((u) => u.id), interviewerList: interviewers, components, approvalLog: log };
}

/** Which approval level a user acts on: Manager -> SUBMITTED, Super Admin -> MANAGER_APPROVED */
const STAGE_FOR_ROLE = { MANAGER: 'SUBMITTED', SUPER_ADMIN: 'MANAGER_APPROVED' };

/** Approval list (Step 3). ?status=  default: the level this user approves */
router.get(
  '/',
  ah(async (req, res) => {
    const status = req.query.status || STAGE_FOR_ROLE[req.user.role] || 'SUBMITTED';
    const [rows] = await pool.query(
      `${PROPOSAL_DETAIL_SQL} WHERE p.status = ? ORDER BY p.submitted_at DESC, p.id DESC`,
      [status]
    );
    res.json(rows);
  })
);

/** All versions for a candidate + latest with components */
router.get(
  '/candidate/:candidateId',
  ah(async (req, res) => {
    const [versions] = await pool.query(
      'SELECT id, version_no, status, ctc_annual, submitted_at, manager_remarks, approval_remarks FROM rec_ctc_proposals WHERE candidate_id = ? ORDER BY version_no DESC',
      [req.params.candidateId]
    );
    const latest = versions.length ? await loadProposal(pool, versions[0].id) : null;
    res.json({ versions, latest });
  })
);

router.get(
  '/:id',
  ah(async (req, res) => {
    const p = await loadProposal(pool, req.params.id);
    if (!p) throw httpError(404, 'CTC proposal not found');
    res.json(p);
  })
);

/**
 * HR Executive saves selection details + CTC breakup (draft) or submits it to the Manager.
 * body: { ...proposal fields, interviewers: [userId, ...], components: [{component_id, monthly_amount}], submit }
 */
router.post(
  '/candidate/:candidateId',
  allow('HR'),
  ah(async (req, res) => {
    const b = req.body || {};
    const candidateId = Number(req.params.candidateId);

    const result = await withTransaction(async (conn) => {
      const cand = await getCandidateForUpdate(conn, candidateId);
      assertStatus(cand, [STATUS.REGISTERED, STATUS.SELECTED, STATUS.CTC_REJECTED], 'enter CTC');

      const isConsultant = cand.candidate_type === 'CONSULTANT';
      for (const f of ['department_id', 'designation_id', 'location_id']) {
        if (!b[f]) throw httpError(400, `${f.replace('_id', '').replace('_', ' ')} is required`);
      }

      // Interviewed By - one or more users
      const interviewerIds = [...new Set((Array.isArray(b.interviewers) ? b.interviewers : []).map(Number).filter(Boolean))];
      if (interviewerIds.length) {
        const [found] = await conn.query('SELECT id FROM users WHERE id IN (?)', [interviewerIds]);
        if (found.length !== interviewerIds.length) throw httpError(400, 'Invalid interviewer selected');
      }

      if (b.reporting_manager_id) {
        const [[rm]] = await conn.query(
          "SELECT id FROM users WHERE id = ? AND is_active = 1 AND role IN ('SUPER_ADMIN','MANAGER','REPORTING MANAGER')",
          [b.reporting_manager_id]
        );
        if (!rm) throw httpError(400, 'Reporting manager must be the Super Admin, a Manager or a Reporting Manager');
      }

      const data = {
        interview_date: b.interview_date || null,
        selection_remarks: b.selection_remarks || null,
        department_id: b.department_id,
        designation_id: b.designation_id,
        location_id: b.location_id,
        reporting_manager_id: b.reporting_manager_id || null,
        employment_type: isConsultant ? 'CONSULTANT' : b.employment_type || 'PROBATION',
        probation_months: !isConsultant && (b.employment_type || 'PROBATION') === 'PROBATION' ? num(b.probation_months) : null,
        proposed_joining_date: b.proposed_joining_date || null,
        compensation_type: isConsultant ? 'CONSULTANT_FEE' : 'SALARY',
      };

      let componentRows = [];
      if (isConsultant) {
        if (!b.fee_type) throw httpError(400, 'Fee type is required');
        Object.assign(data, {
          fee_type: b.fee_type,
          fixed_monthly_fee: num(b.fixed_monthly_fee),
          per_case_fee: num(b.per_case_fee),
          revenue_share_percent: num(b.revenue_share_percent),
          minimum_guarantee: num(b.minimum_guarantee),
        });
        const need = {
          FIXED_MONTHLY: ['fixed_monthly_fee'],
          PER_CASE: ['per_case_fee'],
          REVENUE_SHARE: ['revenue_share_percent'],
          HYBRID: [],
        }[b.fee_type];
        if (!need) throw httpError(400, 'Invalid fee type');
        for (const f of need) if (!data[f]) throw httpError(400, `${f.replace(/_/g, ' ')} is required`);
        if (b.fee_type === 'HYBRID' && !data.fixed_monthly_fee && !data.per_case_fee && !data.revenue_share_percent) {
          throw httpError(400, 'Enter at least one fee component for Hybrid');
        }
        Object.assign(data, { wage_state: null, wage_zone: null, wage_category: null, min_wage_monthly: null });
        const monthly = data.fixed_monthly_fee || data.minimum_guarantee || 0;
        data.gross_monthly = round2(monthly);
        data.employer_contrib_monthly = 0;
        data.ctc_monthly = round2(monthly);
        data.ctc_annual = round2(num(b.ctc_annual) || monthly * 12);
        data.net_take_home_monthly = null;
      } else {
        // State / Zone / Category decide the minimum wage the Basic + DA must meet
        for (const [f, label] of [['wage_state', 'State'], ['wage_zone', 'Zone'], ['wage_category', 'Category']]) {
          if (!b[f]) throw httpError(400, `${label} is required for the CTC breakup`);
        }
        const [[wage]] = await conn.query(
          'SELECT monthly_amount FROM rec_min_wages WHERE state = ? AND zone = ? AND category = ? AND is_active = 1',
          [b.wage_state, b.wage_zone, b.wage_category]
        );
        if (!wage) throw httpError(400, 'No minimum wage found for the selected State / Zone / Category');
        Object.assign(data, {
          wage_state: b.wage_state,
          wage_zone: b.wage_zone,
          wage_category: b.wage_category,
          min_wage_monthly: wage.monthly_amount,
        });

        const [master] = await conn.query('SELECT id, component_code, component_group FROM rec_salary_components WHERE is_active = 1');
        const groupOf = Object.fromEntries(master.map((m) => [m.id, m.component_group]));
        componentRows = (b.components || [])
          .filter((c) => groupOf[c.component_id])
          .map((c) => ({ component_id: Number(c.component_id), monthly: round2(c.monthly_amount) }));
        const sum = (g) => round2(componentRows.filter((c) => groupOf[c.component_id] === g).reduce((s, c) => s + c.monthly, 0));
        const gross = sum('EARNING');
        if (gross <= 0) throw httpError(400, 'Enter the salary breakup (gross must be more than 0)');
        const basicId = master.find((m) => m.component_code === 'BASIC')?.id;
        const basic = componentRows.find((c) => c.component_id === basicId)?.monthly || 0;
        // Excel rounds Basic + DA to the rupee, so allow up to 50 paise below the table amount
        if (basic + 0.5 < Number(wage.monthly_amount)) {
          throw httpError(
            400,
            `Basic + DA (₹${basic}) is below the minimum wage ₹${wage.monthly_amount} for ${b.wage_state} / ${b.wage_zone} / ${b.wage_category}`
          );
        }
        const employer = sum('EMPLOYER_CONTRIBUTION');
        const deductions = sum('EMPLOYEE_DEDUCTION');
        Object.assign(data, {
          gross_monthly: gross,
          employer_contrib_monthly: employer,
          ctc_monthly: round2(gross + employer),
          ctc_annual: round2((gross + employer) * 12),
          net_take_home_monthly: round2(gross - deductions),
          fee_type: null, fixed_monthly_fee: null, per_case_fee: null, revenue_share_percent: null, minimum_guarantee: null,
        });
      }

      // Decide: update current draft, or create a new version
      const [[latest]] = await conn.query(
        'SELECT id, version_no, status FROM rec_ctc_proposals WHERE candidate_id = ? ORDER BY version_no DESC LIMIT 1 FOR UPDATE',
        [candidateId]
      );
      let proposalId;
      if (latest && latest.status === 'DRAFT') {
        proposalId = latest.id;
        await conn.query('UPDATE rec_ctc_proposals SET ? WHERE id = ?', [data, proposalId]);
        await conn.query('DELETE FROM rec_ctc_proposal_components WHERE ctc_proposal_id = ?', [proposalId]);
      } else if (!latest || ['REJECTED', 'SENT_BACK'].includes(latest.status)) {
        data.candidate_id = candidateId;
        data.version_no = latest ? latest.version_no + 1 : 1;
        data.created_by = req.user.id;
        data.status = 'DRAFT';
        const [r] = await conn.query('INSERT INTO rec_ctc_proposals SET ?', [data]);
        proposalId = r.insertId;
      } else {
        const state = { SUBMITTED: 'waiting for Manager approval', MANAGER_APPROVED: 'waiting for Super Admin approval', APPROVED: 'approved' }[latest.status] || latest.status.toLowerCase();
        throw httpError(400, `CTC is ${state}; it cannot be edited`);
      }

      await conn.query('DELETE FROM rec_ctc_interviewers WHERE ctc_proposal_id = ?', [proposalId]);
      if (interviewerIds.length) {
        await conn.query('INSERT INTO rec_ctc_interviewers (ctc_proposal_id, user_id) VALUES ?', [
          interviewerIds.map((u) => [proposalId, u]),
        ]);
      }

      if (componentRows.length) {
        await conn.query(
          'INSERT INTO rec_ctc_proposal_components (ctc_proposal_id, component_id, monthly_amount, annual_amount) VALUES ?',
          [componentRows.map((c) => [proposalId, c.component_id, c.monthly, round2(c.monthly * 12)])]
        );
      }

      let newStatus = cand.status === STATUS.REGISTERED ? STATUS.SELECTED : cand.status;
      if (b.submit) {
        await conn.query(
          "UPDATE rec_ctc_proposals SET status = 'SUBMITTED', submitted_by = ?, submitted_at = NOW() WHERE id = ?",
          [req.user.id, proposalId]
        );
        await conn.query(
          "INSERT INTO rec_ctc_approval_log (ctc_proposal_id, action, remarks, action_by) VALUES (?, 'SUBMITTED', ?, ?)",
          [proposalId, b.selection_remarks || null, req.user.id]
        );
        newStatus = STATUS.CTC_PENDING_APPROVAL;
      }
      if (newStatus !== cand.status) {
        await setStatus(conn, candidateId, cand.status, newStatus, req.user.id, b.submit ? 'CTC submitted for approval' : 'Candidate selected');
      }
      return { proposalId, submitted: Boolean(b.submit) };
    });

    res.json({ ...result, message: result.submitted ? 'CTC submitted to Manager for approval' : 'CTC saved as draft' });
  })
);

/**
 * APPROVE | REJECT | SEND_BACK
 *   Manager      acts on SUBMITTED         (semi-approval  -> MANAGER_APPROVED)
 *   Super Admin  acts on MANAGER_APPROVED  (final approval -> APPROVED)
 */
router.post(
  '/:id/action',
  allow('MANAGER'), // Manager + Super Admin
  acceptSignature, // optional multipart field "signature" (Super Admin final approval)
  ah(async (req, res) => {
    const removeUpload = () => req.file && fs.unlink(req.file.path, () => {});
    try {
      await handleAction(req, res);
    } catch (e) {
      removeUpload(); // nothing is kept when the action fails
      throw e;
    }
  })
);

async function handleAction(req, res) {
    const { action, remarks } = req.body || {};
    if (!['APPROVE', 'REJECT', 'SEND_BACK'].includes(action)) throw httpError(400, 'Invalid action');
    if (action !== 'APPROVE' && !remarks) throw httpError(400, 'Remarks are required to reject or send back');

    const level = req.user.role === 'SUPER_ADMIN' ? 'FINAL' : 'MANAGER';

    // Final approval needs a signature uploaded NOW, with this approval - a saved / earlier signature is never reused
    let signaturePath = null;
    if (req.file) {
      if (level !== 'FINAL' || action !== 'APPROVE') {
        fs.unlink(req.file.path, () => {});
        req.file = null; // a signature is only used with the final approval
      } else if (!isImageFile(req.file.path)) {
        throw httpError(400, 'Signature must be an image (PNG or JPG).');
      } else {
        signaturePath = relPath('signatures', req.file.filename);
      }
    }
    if (level === 'FINAL' && action === 'APPROVE' && !signaturePath) {
      throw httpError(400, 'Upload your signature to give the final approval (it is asked every time).');
    }

    let message;
    await withTransaction(async (conn) => {
      const [[p]] = await conn.query('SELECT * FROM rec_ctc_proposals WHERE id = ? FOR UPDATE', [req.params.id]);
      if (!p) throw httpError(404, 'CTC proposal not found');
      const expected = level === 'FINAL' ? 'MANAGER_APPROVED' : 'SUBMITTED';
      if (p.status !== expected) {
        const why = {
          SUBMITTED: 'It is waiting for Manager approval first.',
          MANAGER_APPROVED: 'It is already approved by the Manager and waiting for Super Admin.',
        }[p.status] || `It is ${p.status.toLowerCase().replace('_', ' ')}.`;
        throw httpError(400, `You cannot act on this CTC now. ${why}`);
      }
      const cand = await getCandidateForUpdate(conn, p.candidate_id);
      const who = level === 'FINAL' ? 'Super Admin' : 'Manager';

      let proposalStatus;
      let logAction;
      let candStatus;
      if (action === 'APPROVE') {
        proposalStatus = level === 'FINAL' ? 'APPROVED' : 'MANAGER_APPROVED';
        logAction = proposalStatus;
        candStatus = level === 'FINAL' ? STATUS.CTC_APPROVED : cand.status; // stays CTC_PENDING_APPROVAL until final
        message = level === 'FINAL' ? 'CTC approved (final)' : 'CTC approved by Manager and sent to Super Admin for final approval';
      } else if (action === 'REJECT') {
        proposalStatus = logAction = 'REJECTED';
        candStatus = STATUS.CTC_REJECTED;
        message = `CTC rejected by ${who}`;
      } else {
        proposalStatus = logAction = 'SENT_BACK';
        candStatus = STATUS.SELECTED;
        message = 'CTC sent back to HR for revision';
      }

      if (level === 'MANAGER') {
        await conn.query(
          'UPDATE rec_ctc_proposals SET status = ?, manager_action_by = ?, manager_action_at = NOW(), manager_remarks = ? WHERE id = ?',
          [proposalStatus, req.user.id, remarks || null, p.id]
        );
      } else {
        await conn.query(
          'UPDATE rec_ctc_proposals SET status = ?, approved_by = ?, approved_at = NOW(), approval_remarks = ?, approval_signature_path = ? WHERE id = ?',
          [proposalStatus, req.user.id, remarks || null, action === 'APPROVE' ? signaturePath : null, p.id]
        );
      }
      await conn.query('INSERT INTO rec_ctc_approval_log (ctc_proposal_id, action, remarks, action_by) VALUES (?, ?, ?, ?)', [
        p.id,
        logAction,
        remarks || null,
        req.user.id,
      ]);
      const note = {
        MANAGER_APPROVED: 'CTC approved by Manager',
        APPROVED: 'CTC final approval by Super Admin',
        REJECTED: `CTC rejected by ${who}`,
        SENT_BACK: `CTC sent back to HR by ${who}`,
      }[logAction];
      if (candStatus !== cand.status) {
        await setStatus(conn, cand.id, cand.status, candStatus, req.user.id, `${note}${remarks ? ': ' + remarks : ''}`);
      } else {
        // no candidate status change (Manager semi-approval) - still record it on the timeline
        await conn.query(
          'INSERT INTO rec_candidate_status_log (candidate_id, from_status, to_status, remarks, changed_by) VALUES (?, ?, ?, ?, ?)',
          [cand.id, cand.status, cand.status, `${note}${remarks ? ': ' + remarks : ''}`.slice(0, 255), req.user.id]
        );
      }
    });
    res.json({ message });
}

module.exports = router;
