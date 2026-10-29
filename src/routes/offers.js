/**
 * STEP 4a - Offer Letter (Employee). HR generates & shares; candidate accepts via portal link.
 * Offer letter always shows the total annual CTC and never the CTC breakup.
 */
const router = require('express').Router();
const crypto = require('crypto');
const { pool, withTransaction } = require('../config/db');
const { ah, httpError } = require('../utils/httpError');
const { allow } = require('../middleware/auth');
const { STATUS, getCandidateForUpdate, assertStatus, setStatus } = require('../utils/status');
const { nextLetterNo } = require('../utils/sequence');
const { writeLetterFile, fmtDate, ensurePdf, isPdfPath } = require('../utils/letters');
const { buildOfferHtml } = require('../utils/offerLetter');
const { sendMail } = require('../utils/mailer');
const { offerEmail } = require('../utils/emailTemplates');

const offerLink = (token) => `${process.env.FRONTEND_URL || 'http://localhost:5173'}/offer/${token}`;
const SEND_VIA = ['EMAIL', 'WHATSAPP'];

async function approvedProposal(conn, candidateId) {
  const [[p]] = await conn.query(
    "SELECT id FROM rec_ctc_proposals WHERE candidate_id = ? AND status = 'APPROVED' ORDER BY version_no DESC LIMIT 1",
    [candidateId]
  );
  if (!p) throw httpError(400, 'No approved CTC found for this candidate');
  return p.id;
}

function validateDates(b) {
  for (const f of ['offer_date', 'joining_date', 'offer_valid_till']) {
    if (!b[f]) throw httpError(400, `${f.replace(/_/g, ' ')} is required`);
  }
  if (b.offer_valid_till < b.offer_date) throw httpError(400, 'Offer valid till must be on/after offer date');
}

/** Emails the offer (PDF attached + accept link) and records emailed_at */
async function emailOffer(offerId, userId) {
  const [[o]] = await pool.query(
    `SELECT o.*, c.first_name, c.middle_name, c.last_name, c.email, g.name AS designation_name, l.name AS location_name
       FROM rec_offer_letters o
       JOIN rec_candidates c ON c.id = o.candidate_id
       JOIN rec_ctc_proposals p ON p.id = o.ctc_proposal_id
       LEFT JOIN designations g ON g.id = p.designation_id
       LEFT JOIN locations l ON l.id = p.location_id
      WHERE o.id = ?`,
    [offerId]
  );
  if (!o) throw httpError(404, 'Offer letter not found');
  // never email an HTML fallback as ".pdf" (it opens blank) - convert it first, or stop with a clear message
  const pdfPath = await ensurePdf(o.pdf_file_path);
  if (pdfPath !== o.pdf_file_path) {
    await pool.query('UPDATE rec_offer_letters SET pdf_file_path = ? WHERE id = ?', [pdfPath, o.id]);
    o.pdf_file_path = pdfPath;
  }
  if (!isPdfPath(o.pdf_file_path)) return { sent: false, error: 'The letter PDF could not be created on the server (Chromium did not start), so it was not emailed - an HTML file would open blank as a PDF. See the [letters] lines in pm2 logs.' };
  const name = [o.first_name, o.middle_name, o.last_name].filter(Boolean).join(' ');
  const mail = offerEmail({
    name,
    designation: o.designation_name || '',
    location: o.location_name || '',
    joiningDate: fmtDate(o.joining_date),
    validTill: fmtDate(o.offer_valid_till),
    link: offerLink(o.access_token),
  });
  const result = await sendMail({
    to: o.email,
    subject: mail.subject,
    html: mail.html,
    attachmentRelPath: o.pdf_file_path,
    attachmentName: `Offer_Letter_${name.replace(/\s+/g, '_')}.pdf`,
    relatedType: 'OFFER_LETTER',
    relatedId: o.id,
    sentBy: userId,
  });
  if (result.sent) await pool.query('UPDATE rec_offer_letters SET emailed_at = NOW() WHERE id = ?', [o.id]);
  return result;
}

router.get(
  '/',
  ah(async (req, res) => {
    const [rows] = await pool.query(
      `SELECT o.*, c.candidate_code, c.first_name, c.last_name, c.mobile_no, c.email, u.name AS sent_by_name,
              p.ctc_annual
         FROM rec_offer_letters o JOIN rec_candidates c ON c.id = o.candidate_id
         LEFT JOIN rec_ctc_proposals p ON p.id = o.ctc_proposal_id
         LEFT JOIN users u ON u.id = o.sent_by
        ORDER BY o.id DESC`
    );
    rows.forEach((r) => (r.offer_link = offerLink(r.access_token)));
    res.json(rows);
  })
);

router.post(
  '/preview',
  allow('HR'),
  ah(async (req, res) => {
    validateDates(req.body);
    const proposalId = await approvedProposal(pool, req.body.candidate_id);
    const { html } = await buildOfferHtml(pool, { ...req.body, ctc_proposal_id: proposalId });
    res.json({ html });
  })
);

/** Generate PDF + secure link, mark OFFER_SENT, email the candidate if "Email" is ticked */
router.post(
  '/',
  allow('HR'),
  ah(async (req, res) => {
    const b = req.body || {};
    validateDates(b);
    const days = Number(process.env.OFFER_LINK_VALID_DAYS || 15);
    const sendVia = Array.isArray(b.send_via) ? b.send_via.filter((v) => SEND_VIA.includes(v)) : [];
    const includeCtc = 1; // total CTC is always printed in the offer letter (never the breakup)

    const out = await withTransaction(async (conn) => {
      const cand = await getCandidateForUpdate(conn, b.candidate_id);
      if (cand.candidate_type !== 'EMPLOYEE') throw httpError(400, 'Use Consultant Agreement for surgeons');
      assertStatus(cand, [STATUS.CTC_APPROVED], 'send offer letter');

      const offerNo = await nextLetterNo(conn, 'OL');
      const proposalId = await approvedProposal(conn, cand.id);
      const { html, tpl } = await buildOfferHtml(conn, {
        ...b,
        offer_letter_no: offerNo,
        ctc_proposal_id: proposalId,
        include_ctc: includeCtc,
      });
      const token = crypto.randomBytes(32).toString('hex');

      const [r] = await conn.query('INSERT INTO rec_offer_letters SET ?', [
        {
          offer_letter_no: offerNo,
          candidate_id: cand.id,
          ctc_proposal_id: proposalId,
          template_id: tpl.id,
          offer_date: b.offer_date,
          joining_date: b.joining_date,
          offer_valid_till: b.offer_valid_till,
          include_ctc: includeCtc,
          pdf_file_path: null, // PDF is made after the DB work is saved (see below)
          access_token: token,
          token_expires_at: new Date(Date.now() + days * 86400000),
          sent_via: sendVia.join(',') || null,
          sent_by: req.user.id,
          sent_at: new Date(),
        },
      ]);
      await setStatus(conn, cand.id, cand.status, STATUS.OFFER_SENT, req.user.id, `Offer letter ${offerNo} sent`);
      return { id: r.insertId, offerNo, token, html };
    });

    // Make the PDF outside the database transaction: Chromium can take several seconds,
    // and the DB rows must not stay locked while it runs.
    const pdfPath = await writeLetterFile(`offer_${out.offerNo}`, out.html);
    await pool.query('UPDATE rec_offer_letters SET pdf_file_path = ? WHERE id = ?', [pdfPath, out.id]);

    let mail = null;
    if (sendVia.includes('EMAIL')) mail = await emailOffer(out.id, req.user.id);

    res.status(201).json({
      id: out.id,
      offer_letter_no: out.offerNo,
      offer_link: offerLink(out.token),
      pdf_created: isPdfPath(pdfPath),
      emailed: Boolean(mail?.sent),
      email_error: mail && !mail.sent ? mail.error : null,
      message: mail?.sent
        ? 'Offer letter generated and emailed to the candidate'
        : 'Offer letter generated. Share the link with the candidate.',
    });
  })
);

/** Letter file for the Preview button (HR / Super Admin): makes sure it is a PDF, returns its path */
router.get(
  '/:id/file',
  allow('HR'),
  ah(async (req, res) => {
    const [[l]] = await pool.query('SELECT id, pdf_file_path FROM rec_offer_letters WHERE id = ?', [req.params.id]);
    if (!l) throw httpError(404, 'Offer letter not found');
    if (!l.pdf_file_path) throw httpError(404, 'The letter file is not ready yet');
    const fixed = await ensurePdf(l.pdf_file_path);
    if (fixed !== l.pdf_file_path) await pool.query('UPDATE rec_offer_letters SET pdf_file_path = ? WHERE id = ?', [fixed, l.id]);
    res.json({ path: fixed, is_pdf: isPdfPath(fixed) });
  })
);

/** Send / re-send the offer email */
router.post(
  '/:id/email',
  allow('HR'),
  ah(async (req, res) => {
    const r = await emailOffer(req.params.id, req.user.id);
    if (!r.sent) throw httpError(400, `Email not sent: ${r.error}`);
    res.json({ message: 'Offer letter emailed to the candidate' });
  })
);

module.exports = router;
