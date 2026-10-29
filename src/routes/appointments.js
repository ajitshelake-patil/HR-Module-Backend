/**
 * STEP 8 - Appointment Letter with CTC Annexure (after onboarding)
 */
const router = require('express').Router();
const { pool, withTransaction } = require('../config/db');
const { ah, httpError } = require('../utils/httpError');
const { allow } = require('../middleware/auth');
const { nextLetterNo } = require('../utils/sequence');
const { renderTemplate, loadLetterData, writeLetterFile, getTemplate, fmtDate, esc, ensurePdf, isPdfPath } = require('../utils/letters');
const { sendMail } = require('../utils/mailer');
const { appointmentEmail } = require('../utils/emailTemplates');

async function buildHtml(conn, b, letterNo) {
  const [[e]] = await conn.query('SELECT * FROM employees WHERE id = ?', [b.employee_id]);
  if (!e) throw httpError(404, 'Employee not found');
  if (e.status !== 'ACTIVE') throw httpError(400, 'Appointment letter can be generated only for active employees');
  const tpl = await getTemplate(conn, 'APPOINTMENT_LETTER');
  const { data } = await loadLetterData(conn, e.candidate_id, e.ctc_proposal_id);
  // CTC is printed only when HR ticks "Include CTC"
  const flag = b.include_ctc ?? b.include_ctc_annexure;
  const include = flag === true || flag === 'true' || Number(flag) === 1;
  Object.assign(data, {
    appointment_letter_no: letterNo,
    employee_code: e.employee_code,
    letter_date: fmtDate(b.letter_date),
    effective_date: fmtDate(b.effective_date),
    date_of_joining: fmtDate(e.date_of_joining),
    probation_end_date: e.probation_end_date ? fmtDate(e.probation_end_date) : '',
    include_ctc: include,
    // used only by older simple templates
    annexure_section_html: include
      ? `<div class="pb"></div><h3>Annexure - ${e.employee_category === 'CONSULTANT' ? 'Professional Fee Terms' : 'CTC Breakup'}</h3>
         <p>Name: ${esc(data.salutation)} ${esc(data.candidate_name)} &nbsp; | &nbsp; Employee Code: ${esc(e.employee_code)} &nbsp; | &nbsp; Designation: ${esc(data.designation)}</p>
         ${data.ctc_annexure_html}`
      : '',
  });
  return { html: renderTemplate(tpl.body_html, data), tpl, employee: e, include };
}

async function emailAppointment(letterId, userId) {
  const [[a]] = await pool.query(
    `SELECT a.*, e.first_name, e.middle_name, e.last_name, e.employee_code, e.official_email, e.personal_email,
            g.name AS designation_name
       FROM rec_appointment_letters a
       JOIN employees e ON e.id = a.employee_id
       LEFT JOIN designations g ON g.id = e.designation_id
      WHERE a.id = ?`,
    [letterId]
  );
  if (!a) throw httpError(404, 'Appointment letter not found');
  // never email an HTML fallback as ".pdf" (it opens blank) - convert it first, or stop with a clear message
  const pdfPath = await ensurePdf(a.pdf_file_path);
  if (pdfPath !== a.pdf_file_path) {
    await pool.query('UPDATE rec_appointment_letters SET pdf_file_path = ? WHERE id = ?', [pdfPath, a.id]);
    a.pdf_file_path = pdfPath;
  }
  if (!isPdfPath(a.pdf_file_path)) return { sent: false, error: 'The letter PDF could not be created on the server (Chromium did not start), so it was not emailed - an HTML file would open blank as a PDF. See the [letters] lines in pm2 logs.' };
  const name = [a.first_name, a.middle_name, a.last_name].filter(Boolean).join(' ');
  const mail = appointmentEmail({
    name,
    designation: a.designation_name || '',
    employeeCode: a.employee_code,
    effectiveDate: fmtDate(a.effective_date),
    includeCtc: Boolean(a.include_ctc_annexure),
  });
  const result = await sendMail({
    to: a.official_email || a.personal_email,
    subject: mail.subject,
    html: mail.html,
    attachmentRelPath: a.pdf_file_path,
    attachmentName: `Appointment_Letter_${a.employee_code}.pdf`,
    relatedType: 'APPOINTMENT_LETTER',
    relatedId: a.id,
    sentBy: userId,
  });
  if (result.sent) await pool.query('UPDATE rec_appointment_letters SET emailed_at = NOW() WHERE id = ?', [a.id]);
  return result;
}

function validate(b) {
  if (!b.employee_id) throw httpError(400, 'Select an employee');
  if (!b.letter_date || !b.effective_date) throw httpError(400, 'Letter date and effective date are required');
}

router.get(
  '/',
  ah(async (req, res) => {
    const [rows] = await pool.query(
      `SELECT a.*, e.employee_code, e.first_name, e.last_name, e.employee_category, u.name AS issued_by_name
         FROM rec_appointment_letters a
         JOIN employees e ON e.id = a.employee_id
         LEFT JOIN users u ON u.id = a.issued_by
        ORDER BY a.id DESC`
    );
    res.json(rows);
  })
);

/** Employees onboarded but without an appointment letter yet */
router.get(
  '/pending',
  ah(async (req, res) => {
    const [rows] = await pool.query(
      `SELECT e.id, e.employee_code, e.first_name, e.last_name, e.employee_category, e.date_of_joining
         FROM employees e
        WHERE e.status = 'ACTIVE' AND NOT EXISTS (SELECT 1 FROM rec_appointment_letters a WHERE a.employee_id = e.id)
        ORDER BY e.id DESC`
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
      const letterNo = await nextLetterNo(conn, 'AL');
      const { html, tpl, employee, include } = await buildHtml(conn, b, letterNo);
      const [r] = await conn.query('INSERT INTO rec_appointment_letters SET ?', [
        {
          appointment_letter_no: letterNo,
          employee_id: employee.id,
          ctc_proposal_id: employee.ctc_proposal_id,
          template_id: tpl.id,
          letter_date: b.letter_date,
          effective_date: b.effective_date,
          pdf_file_path: null, // PDF is made after the DB work is saved
          include_ctc_annexure: include ? 1 : 0,
          issued_by: req.user.id,
        },
      ]);
      return { id: r.insertId, letterNo, employee, html };
    });
    out.pdfPath = await writeLetterFile(`appointment_${out.letterNo}`, out.html);
    await pool.query('UPDATE rec_appointment_letters SET pdf_file_path = ? WHERE id = ?', [out.pdfPath, out.id]);

    let mail = null;
    if (b.send_email) mail = await emailAppointment(out.id, req.user.id);
    res.status(201).json({
      id: out.id,
      appointment_letter_no: out.letterNo,
      pdf_file_path: out.pdfPath,
      pdf_created: isPdfPath(out.pdfPath),
      emailed: Boolean(mail?.sent),
      email_error: mail && !mail.sent ? mail.error : null,
      message: `Appointment letter ${out.letterNo} generated${mail?.sent ? ' and emailed' : ''}`,
    });
  })
);

/** Letter file for the Preview button (HR / Super Admin): makes sure it is a PDF, returns its path */
router.get(
  '/:id/file',
  allow('HR'),
  ah(async (req, res) => {
    const [[l]] = await pool.query('SELECT id, pdf_file_path FROM rec_appointment_letters WHERE id = ?', [req.params.id]);
    if (!l) throw httpError(404, 'Appointment letter not found');
    if (!l.pdf_file_path) throw httpError(404, 'The letter file is not ready yet');
    const fixed = await ensurePdf(l.pdf_file_path);
    if (fixed !== l.pdf_file_path) await pool.query('UPDATE rec_appointment_letters SET pdf_file_path = ? WHERE id = ?', [fixed, l.id]);
    res.json({ path: fixed, is_pdf: isPdfPath(fixed) });
  })
);

/** Send / re-send the appointment letter email */
router.post(
  '/:id/email',
  allow('HR'),
  ah(async (req, res) => {
    const r = await emailAppointment(req.params.id, req.user.id);
    if (!r.sent) throw httpError(400, `Email not sent: ${r.error}`);
    res.json({ message: 'Appointment letter emailed' });
  })
);

module.exports = router;
