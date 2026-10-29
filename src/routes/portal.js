/**
 * Public candidate portal (no login, secret links)
 *   Step 4a - review & accept the offer letter          /offer/:token
 *   Step 5  - upload joining documents (after accepting) /docs/:token   (max 250 KB per file)
 */
const router = require('express').Router();
const path = require('path');
const fs = require('fs');
const { pool, withTransaction } = require('../config/db');
const { ah, httpError } = require('../utils/httpError');
const { STATUS, setStatus } = require('../utils/status');
const { UPLOAD_ROOT, uploader, relPath, DOC_MAX_KB, DOC_TYPES } = require('../middleware/upload');
const { buildOfferHtml } = require('../utils/offerLetter');
const { ensurePdf } = require('../utils/letters');
const { ensureDocsToken } = require('../utils/docsLink');

async function findOffer(conn, token, lock = false) {
  if (!/^[a-f0-9]{64}$/.test(token)) throw httpError(404, 'Invalid offer link');
  const [[o]] = await conn.query(
    `SELECT o.*, c.first_name, c.last_name, c.status AS candidate_status, c.docs_token
       FROM rec_offer_letters o JOIN rec_candidates c ON c.id = o.candidate_id
      WHERE o.access_token = ? ${lock ? 'FOR UPDATE' : ''}`,
    [token]
  );
  if (!o) throw httpError(404, 'Invalid offer link');
  return o;
}

const isExpired = (o) =>
  new Date(String(o.token_expires_at).replace(' ', 'T')) < new Date() || String(o.offer_valid_till).slice(0, 10) < new Date().toISOString().slice(0, 10);

router.get(
  '/offer/:token',
  ah(async (req, res) => {
    const o = await findOffer(pool, req.params.token);
    const { html } = await buildOfferHtml(pool, o);
    res.json({
      offer_letter_no: o.offer_letter_no,
      candidate_name: `${o.first_name} ${o.last_name}`,
      joining_date: o.joining_date,
      offer_valid_till: o.offer_valid_till,
      candidate_response: o.candidate_response === 'PENDING' && isExpired(o) ? 'EXPIRED' : o.candidate_response,
      response_at: o.response_at,
      has_pdf: Boolean(o.pdf_file_path),
      // after acceptance the same page lets the candidate upload documents
      docs_token: o.candidate_response === 'ACCEPTED' ? o.docs_token : null,
      html,
    });
  })
);

router.get(
  '/offer/:token/download',
  ah(async (req, res) => {
    const o = await findOffer(pool, req.params.token);
    const pdfPath = await ensurePdf(o.pdf_file_path); // convert an older HTML fallback copy to PDF first
    if (pdfPath !== o.pdf_file_path) {
      await pool.query('UPDATE rec_offer_letters SET pdf_file_path = ? WHERE id = ?', [pdfPath, o.id]);
      o.pdf_file_path = pdfPath;
    }
    const full = path.join(UPLOAD_ROOT, o.pdf_file_path || '');
    if (!o.pdf_file_path || !fs.existsSync(full)) throw httpError(404, 'File not available');
    res.download(full, `Offer_Letter_${o.offer_letter_no.replace(/\//g, '_')}${path.extname(full)}`);
  })
);

router.post(
  '/offer/:token/respond',
  ah(async (req, res) => {
    const { response, reason } = req.body || {};
    if (!['ACCEPT', 'DECLINE'].includes(response)) throw httpError(400, 'Invalid response');
    if (response === 'DECLINE' && !reason) throw httpError(400, 'Please share a reason for declining');

    await withTransaction(async (conn) => {
      const o = await findOffer(conn, req.params.token, true);
      if (o.candidate_response !== 'PENDING') throw httpError(400, `You have already ${o.candidate_response.toLowerCase()} this offer`);
      if (isExpired(o)) {
        await conn.query("UPDATE rec_offer_letters SET candidate_response = 'EXPIRED' WHERE id = ?", [o.id]);
        throw httpError(400, 'This offer has expired. Please contact HR.');
      }
      const accepted = response === 'ACCEPT';
      await conn.query(
        'UPDATE rec_offer_letters SET candidate_response = ?, response_at = NOW(), response_ip = ?, decline_reason = ? WHERE id = ?',
        [accepted ? 'ACCEPTED' : 'DECLINED', req.ip, accepted ? null : reason, o.id]
      );
      if (accepted) await ensureDocsToken(conn, o.candidate_id);
      await setStatus(
        conn,
        o.candidate_id,
        o.candidate_status,
        accepted ? STATUS.OFFER_ACCEPTED : STATUS.OFFER_DECLINED,
        null,
        accepted ? 'Offer accepted by candidate' : `Offer declined by candidate: ${reason}`
      );
    });
    res.json({
      message:
        response === 'ACCEPT'
          ? 'Thank you! Your acceptance has been recorded. Please upload your joining documents below.'
          : 'Your response has been recorded.',
    });
  })
);

/* ------------------------------------------------------------------
 * Step 5 - candidate uploads joining documents (HR only verifies)
 * ------------------------------------------------------------------ */
const DOC_OPEN = [STATUS.OFFER_ACCEPTED, STATUS.AGREEMENT_GENERATED, STATUS.DOCS_PENDING];
const docUpload = uploader('documents', { maxBytes: DOC_MAX_KB * 1024, allowed: DOC_TYPES });
const mask = (v) => (v ? (String(v).length > 4 ? `XXXX${String(v).slice(-4)}` : v) : null);

async function findCandidateByDocsToken(conn, token, lock = false) {
  if (!/^[a-f0-9]{64}$/.test(token || '')) throw httpError(404, 'Invalid document upload link');
  const [[c]] = await conn.query(
    `SELECT id, candidate_code, candidate_type, first_name, middle_name, last_name, status
       FROM rec_candidates WHERE docs_token = ? ${lock ? 'FOR UPDATE' : ''}`,
    [token]
  );
  if (!c) throw httpError(404, 'Invalid document upload link');
  return c;
}

/** Checklist with the latest upload of each document */
router.get(
  '/docs/:token',
  ah(async (req, res) => {
    const c = await findCandidateByDocsToken(pool, req.params.token);
    const [types] = await pool.query(
      `SELECT id, document_name, is_mandatory, requires_number FROM rec_document_types
        WHERE is_active = 1 AND applicable_to IN ('BOTH', ?) ORDER BY display_order`,
      [c.candidate_type]
    );
    const [docs] = await pool.query(
      `SELECT id, document_type_id, document_number, original_file_name, uploaded_at, verification_status, verification_remarks
         FROM rec_candidate_documents WHERE candidate_id = ? ORDER BY id DESC`,
      [c.id]
    );
    const open = DOC_OPEN.includes(c.status);
    const checklist = types.map((t) => {
      const d = docs.find((x) => x.document_type_id === t.id);
      return {
        ...t,
        document: d
          ? {
              id: d.id,
              status: d.verification_status,
              remarks: d.verification_remarks,
              file_name: d.original_file_name,
              uploaded_at: d.uploaded_at,
              document_number: mask(d.document_number),
            }
          : null,
        can_upload: open && (!d || d.verification_status !== 'VERIFIED'),
      };
    });
    res.json({
      candidate_name: [c.first_name, c.middle_name, c.last_name].filter(Boolean).join(' '),
      candidate_code: c.candidate_code,
      can_upload: open,
      completed: [STATUS.DOCS_VERIFIED, STATUS.ONBOARDED].includes(c.status),
      max_kb: DOC_MAX_KB,
      file_types: 'PDF, JPG, PNG',
      checklist,
    });
  })
);

/** Upload one document: multipart  document_type_id, document_number, file */
router.post(
  '/docs/:token',
  // check the link before accepting any file
  ah(async (req, res, next) => {
    const c = await findCandidateByDocsToken(pool, req.params.token);
    if (!DOC_OPEN.includes(c.status)) throw httpError(400, 'Document upload is closed. Please contact HR.');
    next();
  }),
  (req, res, next) =>
    docUpload.single('file')(req, res, (err) => {
      if (!err) return next();
      if (err.code === 'LIMIT_FILE_SIZE') {
        return next(httpError(400, `File is too large. Maximum size is ${DOC_MAX_KB} KB per document.`));
      }
      return next(httpError(400, err.message));
    }),
  ah(async (req, res) => {
    const removeFile = () => req.file && fs.unlink(req.file.path, () => {});
    try {
      if (!req.file) throw httpError(400, 'Choose a file to upload');
      if (!req.body.document_type_id) throw httpError(400, 'Document type is required');
      await withTransaction(async (conn) => {
        const c = await findCandidateByDocsToken(conn, req.params.token, true);
        if (!DOC_OPEN.includes(c.status)) throw httpError(400, 'Document upload is closed. Please contact HR.');
        const [[type]] = await conn.query(
          "SELECT * FROM rec_document_types WHERE id = ? AND is_active = 1 AND applicable_to IN ('BOTH', ?)",
          [req.body.document_type_id, c.candidate_type]
        );
        if (!type) throw httpError(400, 'Invalid document type');
        const number = String(req.body.document_number || '').trim();
        if (type.requires_number && !number) throw httpError(400, `${type.document_name} number is required`);
        const [[latest]] = await conn.query(
          'SELECT verification_status FROM rec_candidate_documents WHERE candidate_id = ? AND document_type_id = ? ORDER BY id DESC LIMIT 1',
          [c.id, type.id]
        );
        if (latest?.verification_status === 'VERIFIED') throw httpError(400, `${type.document_name} is already verified by HR`);

        await conn.query('INSERT INTO rec_candidate_documents SET ?', [
          {
            candidate_id: c.id,
            document_type_id: type.id,
            document_number: number || null,
            file_path: relPath('documents', req.file.filename),
            original_file_name: req.file.originalname.slice(0, 150),
            uploaded_by_type: 'CANDIDATE',
            uploaded_by: null,
          },
        ]);
        if (c.status !== STATUS.DOCS_PENDING) {
          await setStatus(conn, c.id, c.status, STATUS.DOCS_PENDING, null, 'Candidate started uploading documents');
        }
      });
    } catch (e) {
      removeFile();
      throw e;
    }
    res.status(201).json({ message: 'Document uploaded. HR will verify it.' });
  })
);

module.exports = router;
