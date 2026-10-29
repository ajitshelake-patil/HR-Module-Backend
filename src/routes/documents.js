/**
 * STEP 5 - Document Verification
 * The candidate uploads documents through their secret link (routes/portal.js, max 250 KB).
 * HR Executive cannot upload - HR only verifies / rejects and completes verification.
 */
const router = require('express').Router();
const { pool, withTransaction } = require('../config/db');
const { ah, httpError } = require('../utils/httpError');
const { allow } = require('../middleware/auth');
const { STATUS, getCandidateForUpdate, assertStatus, setStatus } = require('../utils/status');
const { docsLink } = require('../utils/docsLink');
const OPEN_STATUSES = [STATUS.OFFER_ACCEPTED, STATUS.AGREEMENT_GENERATED, STATUS.DOCS_PENDING];

/** Candidates ready for / under document verification */
router.get(
  '/queue',
  ah(async (req, res) => {
    const [rows] = await pool.query(
      `SELECT c.id, c.candidate_code, c.candidate_type, c.first_name, c.last_name, c.mobile_no, c.status,
              SUM(d.verification_status = 'VERIFIED') AS verified_count,
              SUM(d.verification_status = 'PENDING') AS pending_count,
              SUM(d.verification_status = 'REJECTED') AS rejected_count
         FROM rec_candidates c
         LEFT JOIN rec_candidate_documents d ON d.candidate_id = c.id
        WHERE c.status IN (?, ?, ?, ?)
        GROUP BY c.id ORDER BY c.id DESC`,
      [...OPEN_STATUSES, STATUS.DOCS_VERIFIED]
    );
    res.json(rows);
  })
);

/** Checklist: applicable document types + latest uploaded file for each */
router.get(
  '/candidate/:candidateId',
  ah(async (req, res) => {
    const [[cand]] = await pool.query(
      'SELECT id, candidate_code, candidate_type, first_name, middle_name, last_name, mobile_no, email, status, docs_token FROM rec_candidates WHERE id = ?',
      [req.params.candidateId]
    );
    if (!cand) throw httpError(404, 'Candidate not found');
    const [types] = await pool.query(
      "SELECT * FROM rec_document_types WHERE is_active = 1 AND applicable_to IN ('BOTH', ?) ORDER BY display_order",
      [cand.candidate_type]
    );
    const [docs] = await pool.query(
      `SELECT d.*, u.name AS uploaded_by_name, v.name AS verified_by_name
         FROM rec_candidate_documents d
         LEFT JOIN users u ON u.id = d.uploaded_by
         LEFT JOIN users v ON v.id = d.verified_by
        WHERE d.candidate_id = ? ORDER BY d.id DESC`,
      [cand.id]
    );
    const checklist = types.map((t) => ({
      ...t,
      document: docs.find((d) => d.document_type_id === t.id) || null, // latest upload
      history: docs.filter((d) => d.document_type_id === t.id),
    }));
    const mandatoryPending = checklist.filter((c) => c.is_mandatory && c.document?.verification_status !== 'VERIFIED').length;
    const link = cand.docs_token ? docsLink(cand.docs_token) : null;
    delete cand.docs_token;
    res.json({
      candidate: cand,
      checklist,
      docsLink: link,
      canComplete: mandatoryPending === 0 && cand.status === STATUS.DOCS_PENDING,
    });
  })
);

/** Verify / reject a single document */
router.post(
  '/:docId/verify',
  allow('HR'),
  ah(async (req, res) => {
    const { status, remarks } = req.body || {};
    if (!['VERIFIED', 'REJECTED'].includes(status)) throw httpError(400, 'Invalid status');
    if (status === 'REJECTED' && !remarks) throw httpError(400, 'Remarks are required to reject a document');
    const [r] = await pool.query(
      `UPDATE rec_candidate_documents d JOIN rec_candidates c ON c.id = d.candidate_id
          SET d.verification_status = ?, d.verified_by = ?, d.verified_at = NOW(), d.verification_remarks = ?
        WHERE d.id = ? AND c.status = ?`,
      [status, req.user.id, remarks || null, req.params.docId, STATUS.DOCS_PENDING]
    );
    if (!r.affectedRows) throw httpError(400, 'Document not found or verification already completed');
    res.json({ message: `Document ${status.toLowerCase()}` });
  })
);

/** Complete verification -> DOCS_VERIFIED (all mandatory docs must be verified) */
router.post(
  '/candidate/:candidateId/complete',
  allow('HR'),
  ah(async (req, res) => {
    await withTransaction(async (conn) => {
      const cand = await getCandidateForUpdate(conn, req.params.candidateId);
      assertStatus(cand, [STATUS.DOCS_PENDING], 'complete verification');
      const [missing] = await conn.query(
        `SELECT t.document_name FROM rec_document_types t
          WHERE t.is_active = 1 AND t.is_mandatory = 1 AND t.applicable_to IN ('BOTH', ?)
            AND NOT EXISTS (
              SELECT 1 FROM rec_candidate_documents d
               WHERE d.candidate_id = ? AND d.document_type_id = t.id AND d.verification_status = 'VERIFIED'
                 AND d.id = (SELECT MAX(d2.id) FROM rec_candidate_documents d2 WHERE d2.candidate_id = d.candidate_id AND d2.document_type_id = t.id))`,
        [cand.candidate_type, cand.id]
      );
      if (missing.length) {
        throw httpError(400, `These mandatory documents are not verified: ${missing.map((m) => m.document_name).join(', ')}`);
      }
      await setStatus(conn, cand.id, cand.status, STATUS.DOCS_VERIFIED, req.user.id, 'All documents verified');
    });
    res.json({ message: 'Document verification completed. Employee ID can now be generated.' });
  })
);

module.exports = router;
