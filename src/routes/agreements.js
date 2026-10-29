/**
 * STEP 4b - Consultant Agreement (Surgeon). Generated after Super Admin approves the fee terms.
 */
const router = require('express').Router();
const { pool, withTransaction } = require('../config/db');
const { ah, httpError } = require('../utils/httpError');
const { allow } = require('../middleware/auth');
const { uploader, relPath } = require('../middleware/upload');
const { STATUS, getCandidateForUpdate, assertStatus, setStatus } = require('../utils/status');
const { nextLetterNo } = require('../utils/sequence');
const {
  renderTemplate, loadLetterData, writeLetterFile, getTemplate, fmtDate, rupeesInWords, inrPlain,
} = require('../utils/letters');
const { ensureDocsToken, docsLink } = require('../utils/docsLink');

const upload = uploader('agreements');

async function buildHtml(conn, b, agreementNo) {
  const [[p]] = await conn.query(
    "SELECT id, location_id FROM rec_ctc_proposals WHERE candidate_id = ? AND status = 'APPROVED' ORDER BY version_no DESC LIMIT 1",
    [b.candidate_id]
  );
  if (!p) throw httpError(400, 'Fee terms are not approved by Super Admin yet');
  // Only one agreement format is used: the HHC Surgeon Service Agreement (db/templates/consultant_agreement.html)
  const tpl = await getTemplate(conn, 'CONSULTANT_AGREEMENT');
  const { data, candidate, proposal: fees } = await loadLetterData(conn, b.candidate_id, p.id);

  // Fee clause 2.1 / Annexure A2: "INR <monthly retainer> per month or INR <per-surgery fee> per surgery, whichever is higher"
  const blank = '____________';
  const money = (v) => (Number(v) > 0 ? { amount: inrPlain(v), words: rupeesInWords(v) } : { amount: blank, words: blank });
  const retainer = money(fees.fixed_monthly_fee || fees.minimum_guarantee);
  const perCase = money(fees.per_case_fee);
  const speciality = b.speciality || candidate.specialization || '';

  Object.assign(data, {
    agreement_no: agreementNo,
    speciality,
    medical_council_reg_no: b.medical_council_reg_no || '',
    agreement_start_date: fmtDate(b.agreement_start_date),
    agreement_end_date: b.agreement_end_date ? fmtDate(b.agreement_end_date) : 'until terminated by either party',
    notice_period_days: b.notice_period_days || '30',
    // Surgeon Service Agreement fields
    place_of_execution: (data.location || '').split(' - ')[0] || 'Pune', // "Pune - Sangamvadi" -> "Pune"
    reporting_to: data.reporting_manager || 'Mr. Pankaj Porwal',
    qualification: [candidate.highest_qualification, speciality].filter(Boolean).join(', '),
    retainer_amount: retainer.amount,
    retainer_words: retainer.words,
    per_case_amount: perCase.amount,
    per_case_words: perCase.words,
  });
  return { html: renderTemplate(tpl.body_html, data), tpl, proposal: p };
}

function validate(b) {
  if (!b.candidate_id) throw httpError(400, 'Select a surgeon');
  if (!b.agreement_start_date) throw httpError(400, 'Agreement start date is required');
  if (b.agreement_end_date && b.agreement_end_date < b.agreement_start_date) {
    throw httpError(400, 'Agreement end date must be after start date');
  }
}

router.get(
  '/',
  ah(async (req, res) => {
    const [rows] = await pool.query(
      `SELECT a.*, c.candidate_code, c.first_name, c.last_name, c.mobile_no, l.name AS location_name,
              p.fee_type, p.fixed_monthly_fee, p.per_case_fee, p.revenue_share_percent
         FROM rec_consultant_agreements a
         JOIN rec_candidates c ON c.id = a.candidate_id
         JOIN rec_ctc_proposals p ON p.id = a.ctc_proposal_id
         LEFT JOIN locations l ON l.id = a.location_id
        ORDER BY a.id DESC`
    );
    res.json(rows);
  })
);

router.post(
  '/preview',
  allow('HR'),
  ah(async (req, res) => {
    validate(req.body);
    const { html } = await buildHtml(pool, req.body, '(generated on save)');
    res.json({ html });
  })
);

router.post(
  '/',
  allow('HR'),
  ah(async (req, res) => {
    const b = req.body || {};
    validate(b);
    const out = await withTransaction(async (conn) => {
      const cand = await getCandidateForUpdate(conn, b.candidate_id);
      if (cand.candidate_type !== 'CONSULTANT') throw httpError(400, 'Consultant agreement is only for surgeons / consultants');
      assertStatus(cand, [STATUS.CTC_APPROVED], 'generate agreement');

      const agreementNo = await nextLetterNo(conn, 'CA');
      const { html, tpl, proposal } = await buildHtml(conn, b, agreementNo);
      const [r] = await conn.query('INSERT INTO rec_consultant_agreements SET ?', [
        {
          agreement_no: agreementNo,
          candidate_id: cand.id,
          ctc_proposal_id: proposal.id,
          template_id: tpl.id,
          speciality: b.speciality || cand.specialization || null,
          medical_council_reg_no: b.medical_council_reg_no || null,
          location_id: proposal.location_id,
          agreement_start_date: b.agreement_start_date,
          agreement_end_date: b.agreement_end_date || null,
          notice_period_days: b.notice_period_days || null,
          pdf_file_path: null, // PDF is made after the DB work is saved
          status: 'GENERATED',
          generated_by: req.user.id,
        },
      ]);
      await setStatus(conn, cand.id, cand.status, STATUS.AGREEMENT_GENERATED, req.user.id, `Agreement ${agreementNo} generated`);
      return { id: r.insertId, agreementNo, html };
    });
    const pdfPath = await writeLetterFile(`agreement_${out.agreementNo}`, out.html);
    await pool.query('UPDATE rec_consultant_agreements SET pdf_file_path = ? WHERE id = ?', [pdfPath, out.id]);
    res.status(201).json({ id: out.id, agreementNo: out.agreementNo, message: `Agreement ${out.agreementNo} generated` });
  })
);

/** Upload surgeon-signed copy. Signing = acceptance, so the surgeon now gets the document upload link. */
router.post(
  '/:id/signed',
  allow('HR'),
  upload.single('signed_copy'),
  ah(async (req, res) => {
    if (!req.file) throw httpError(400, 'Upload the signed agreement');
    const token = await withTransaction(async (conn) => {
      const [r] = await conn.query(
        "UPDATE rec_consultant_agreements SET status = 'SIGNED', signed_copy_path = ?, signed_on = ? WHERE id = ? AND status IN ('GENERATED','SENT')",
        [relPath('agreements', req.file.filename), req.body.signed_on || new Date().toISOString().slice(0, 10), req.params.id]
      );
      if (!r.affectedRows) throw httpError(400, 'Agreement not found or already signed / cancelled');
      const [[a]] = await conn.query('SELECT candidate_id FROM rec_consultant_agreements WHERE id = ?', [req.params.id]);
      return ensureDocsToken(conn, a.candidate_id);
    });
    res.json({
      message: 'Signed copy uploaded. Share the document upload link with the surgeon (Document Verification screen).',
      docs_link: docsLink(token),
    });
  })
);

module.exports = router;
