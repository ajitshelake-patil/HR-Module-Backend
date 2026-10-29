/**
 * Candidate document upload link (Step 5).
 * The candidate gets a secret link only after accepting the offer letter (employee)
 * or after the signed agreement is uploaded (surgeon). HR shares / the offer page shows it.
 */
const crypto = require('crypto');

const docsLink = (token) => `${process.env.FRONTEND_URL || 'http://localhost:5173'}/upload-documents/${token}`;

/** Returns the candidate's upload token, creating it the first time */
async function ensureDocsToken(conn, candidateId) {
  const [[c]] = await conn.query('SELECT docs_token FROM rec_candidates WHERE id = ?', [candidateId]);
  if (c?.docs_token) return c.docs_token;
  const token = crypto.randomBytes(32).toString('hex');
  await conn.query('UPDATE rec_candidates SET docs_token = ? WHERE id = ?', [token, candidateId]);
  return token;
}

module.exports = { docsLink, ensureDocsToken };
