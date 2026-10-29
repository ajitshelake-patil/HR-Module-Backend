/**
 * Branded HTML emails (table layout + inline styles so they render in Gmail / Outlook).
 * The logo is embedded as an inline attachment (cid:hhc-logo) by mailer.js.
 */
const { esc } = require('./letters');

const BRAND = '#178aae';
const COMPANY = () => process.env.COMPANY_LEGAL_NAME || 'Healing Hands Clinic Private Limited';

function layout({ preheader, body }) {
  return `<!doctype html><html><body style="margin:0;padding:0;background:#f1f5f8;font-family:Arial,Helvetica,sans-serif;color:#1d2b36">
<span style="display:none;max-height:0;overflow:hidden">${esc(preheader || '')}</span>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#f1f5f8;padding:24px 12px">
 <tr><td align="center">
  <table role="presentation" width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background:#ffffff;border-radius:10px;overflow:hidden;border:1px solid #e3eaef">
   <tr><td style="padding:20px 28px;border-bottom:3px solid ${BRAND}">
     <img src="cid:hhc-logo" alt="Healing Hands Clinic" height="46" style="display:block;height:46px;border:0">
   </td></tr>
   <tr><td style="padding:26px 28px;font-size:14px;line-height:1.6">${body}</td></tr>
   <tr><td style="padding:16px 28px;background:#f7fafc;font-size:11.5px;color:#6b7a86;line-height:1.5;border-top:1px solid #e3eaef">
     ${esc(COMPANY())} · Human Resources<br>
     This email and its attachments are confidential and intended only for the addressee.
   </td></tr>
  </table>
 </td></tr>
</table></body></html>`;
}

const button = (href, label) =>
  `<table role="presentation" cellpadding="0" cellspacing="0" style="margin:22px 0"><tr><td style="border-radius:8px;background:${BRAND}">
     <a href="${esc(href)}" style="display:inline-block;padding:12px 26px;font-size:14px;font-weight:bold;color:#ffffff;text-decoration:none;border-radius:8px">${esc(label)}</a>
   </td></tr></table>`;

const row = (k, v) =>
  `<tr><td style="padding:6px 12px 6px 0;color:#6b7a86;font-size:13px;white-space:nowrap">${esc(k)}</td><td style="padding:6px 0;font-size:13px;font-weight:bold">${esc(v)}</td></tr>`;

function offerEmail({ name, designation, location, joiningDate, validTill, link }) {
  return {
    subject: `Offer of Employment – ${designation} | Healing Hands Clinic`,
    html: layout({
      preheader: `Your offer letter for the position of ${designation}`,
      body: `
        <p style="margin:0 0 14px">Dear ${esc(name)},</p>
        <p style="margin:0 0 14px">Congratulations! We are pleased to offer you the position of <b>${esc(designation)}</b> with ${esc(COMPANY())}.
        Your offer letter is attached to this email as a PDF.</p>
        <table role="presentation" cellpadding="0" cellspacing="0" style="margin:6px 0 4px">
          ${row('Position', designation)}${location ? row('Location', location) : ''}${row('Proposed joining date', joiningDate)}${row('Please respond by', validTill)}
        </table>
        <p style="margin:14px 0 0">Please review the offer and confirm your acceptance online using the button below:</p>
        ${button(link, 'Review & Accept Offer')}
        <p style="margin:0 0 14px;font-size:12px;color:#6b7a86">If the button does not work, copy this link into your browser:<br><a href="${esc(link)}" style="color:${BRAND};word-break:break-all">${esc(link)}</a></p>
        <p style="margin:0">For any questions, simply reply to this email.</p>
        <p style="margin:18px 0 0">Warm regards,<br><b>Human Resources</b><br>${esc(COMPANY())}</p>`,
    }),
  };
}

function appointmentEmail({ name, designation, employeeCode, effectiveDate, includeCtc }) {
  return {
    subject: `Appointment Letter – ${designation} (${employeeCode}) | Healing Hands Clinic`,
    html: layout({
      preheader: `Your appointment letter as ${designation}`,
      body: `
        <p style="margin:0 0 14px">Dear ${esc(name)},</p>
        <p style="margin:0 0 14px">Welcome to ${esc(COMPANY())}! Please find attached your <b>Appointment Letter</b>${
          includeCtc ? ' along with the compensation statement (Annexure A)' : ''
        }.</p>
        <table role="presentation" cellpadding="0" cellspacing="0" style="margin:6px 0 4px">
          ${row('Employee Code', employeeCode)}${row('Designation', designation)}${row('Effective from', effectiveDate)}
        </table>
        <p style="margin:14px 0 0">Please sign a copy of the letter and return it to the HR department as your acknowledgement.</p>
        <p style="margin:18px 0 0">Warm regards,<br><b>Human Resources</b><br>${esc(COMPANY())}</p>`,
    }),
  };
}

function testEmail() {
  return {
    subject: 'Test email – Healing Hands Recruitment',
    html: layout({
      preheader: 'Email settings are working',
      body: `<p style="margin:0">This is a test email from the Healing Hands Recruitment module. If you received it, email sending is set up correctly.</p>`,
    }),
  };
}

module.exports = { offerEmail, appointmentEmail, testEmail };
