/**
 * Email sending (SMTP via nodemailer) + email log.
 *
 * .env settings:
 *   SMTP_HOST, SMTP_PORT (587 = STARTTLS, 465 = SSL), SMTP_USER, SMTP_PASS
 *   MAIL_FROM   e.g. "Healing Hands HR <hr@healinghandsclinic.co.in>"
 *   MAIL_CC     optional, comma separated - copied on every candidate email (e.g. HR mailbox)
 *   MAIL_BCC    optional
 * If SMTP_HOST is empty, emails are skipped and HR can share the link manually.
 */
const path = require('path');
const fs = require('fs');
const { UPLOAD_ROOT } = require('../middleware/upload');
const { pool } = require('../config/db');

const LOGO_PATH = path.join(__dirname, '..', '..', 'assets', 'logo.png');
let transporter = null;

function isMailConfigured() {
  return Boolean(process.env.SMTP_HOST);
}

function mailStatus() {
  return {
    configured: isMailConfigured(),
    host: process.env.SMTP_HOST || null,
    from: process.env.MAIL_FROM || process.env.SMTP_USER || null,
    cc: process.env.MAIL_CC || null,
  };
}

function getTransporter() {
  if (!transporter) {
    const nodemailer = require('nodemailer');
    const port = Number(process.env.SMTP_PORT || 587);
    transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port,
      secure: port === 465,
      auth: process.env.SMTP_USER ? { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS } : undefined,
      connectionTimeout: 15000,
    });
  }
  return transporter;
}

async function logEmail(entry) {
  try {
    await pool.query('INSERT INTO rec_email_log SET ?', [entry]);
  } catch (e) {
    console.warn('[mail] could not write email log:', e.message);
  }
}

/**
 * Sends an email and records it in rec_email_log.
 * @returns {{ sent: boolean, skipped?: boolean, error?: string }}
 */
async function sendMail({ to, subject, html, attachmentRelPath, attachmentName, relatedType, relatedId, sentBy }) {
  const base = {
    related_type: relatedType || 'OTHER',
    related_id: relatedId || null,
    to_email: to,
    cc_email: process.env.MAIL_CC || null,
    subject,
    sent_by: sentBy || null,
  };
  if (!isMailConfigured()) {
    await logEmail({ ...base, status: 'SKIPPED', error_message: 'SMTP not configured' });
    return { sent: false, skipped: true, error: 'Email is not set up on the server (SMTP_HOST is empty)' };
  }
  if (!to) {
    await logEmail({ ...base, status: 'FAILED', error_message: 'No email address' });
    return { sent: false, error: 'Candidate / employee has no email address' };
  }
  const attachments = [];
  if (attachmentRelPath) {
    const full = path.join(UPLOAD_ROOT, attachmentRelPath);
    if (fs.existsSync(full)) {
      attachments.push({ filename: attachmentName || path.basename(attachmentRelPath), path: full });
    }
  }
  if (fs.existsSync(LOGO_PATH)) attachments.push({ filename: 'logo.png', path: LOGO_PATH, cid: 'hhc-logo' });
  try {
    await getTransporter().sendMail({
      from: process.env.MAIL_FROM || process.env.SMTP_USER,
      to,
      cc: process.env.MAIL_CC || undefined,
      bcc: process.env.MAIL_BCC || undefined,
      subject,
      html,
      attachments,
    });
    await logEmail({ ...base, status: 'SENT' });
    return { sent: true };
  } catch (err) {
    console.warn('[mail] send failed:', err.message);
    await logEmail({ ...base, status: 'FAILED', error_message: String(err.message).slice(0, 500) });
    return { sent: false, error: err.message };
  }
}

/** Checks the SMTP login without sending anything */
async function verifySmtp() {
  if (!isMailConfigured()) return { ok: false, error: 'SMTP_HOST is empty in .env' };
  try {
    await getTransporter().verify();
    return { ok: true };
  } catch (err) {
    return { ok: false, error: err.message };
  }
}

module.exports = { sendMail, isMailConfigured, mailStatus, verifySmtp };
