/** npm run mail:test you@example.com  -> checks SMTP login and sends a test email */
require('dotenv').config();
const { verifySmtp, sendMail } = require('../src/utils/mailer');
const { testEmail } = require('../src/utils/emailTemplates');
const { pool } = require('../src/config/db');

(async () => {
  const to = process.argv[2];
  const check = await verifySmtp();
  if (!check.ok) throw new Error(`SMTP check failed: ${check.error}`);
  console.log('SMTP login OK');
  if (to) {
    const m = testEmail();
    const r = await sendMail({ to, subject: m.subject, html: m.html, relatedType: 'TEST' });
    if (!r.sent) throw new Error(r.error);
    console.log(`Test email sent to ${to}`);
  }
  await pool.end();
})().catch(async (e) => {
  console.error(e.message);
  process.exit(1);
});
