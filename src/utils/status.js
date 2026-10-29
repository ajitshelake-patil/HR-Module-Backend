const { httpError } = require('./httpError');

const STATUS = {
  REGISTERED: 'REGISTERED',
  SELECTED: 'SELECTED',
  CTC_PENDING_APPROVAL: 'CTC_PENDING_APPROVAL',
  CTC_APPROVED: 'CTC_APPROVED',
  CTC_REJECTED: 'CTC_REJECTED',
  OFFER_SENT: 'OFFER_SENT',
  OFFER_ACCEPTED: 'OFFER_ACCEPTED',
  OFFER_DECLINED: 'OFFER_DECLINED',
  AGREEMENT_GENERATED: 'AGREEMENT_GENERATED',
  DOCS_PENDING: 'DOCS_PENDING',
  DOCS_VERIFIED: 'DOCS_VERIFIED',
  ONBOARDED: 'ONBOARDED',
};

/** Loads candidate row with a lock; throws 404 if missing. */
async function getCandidateForUpdate(conn, id) {
  const [[cand]] = await conn.query('SELECT * FROM rec_candidates WHERE id = ? FOR UPDATE', [id]);
  if (!cand) throw httpError(404, 'Candidate not found');
  return cand;
}

function assertStatus(cand, allowed, action) {
  if (!allowed.includes(cand.status)) {
    throw httpError(
      400,
      `Cannot ${action} while candidate is in status ${cand.status}. Allowed: ${allowed.join(', ')}`
    );
  }
}

/** Updates candidate status and writes the audit log. */
async function setStatus(conn, candidateId, fromStatus, toStatus, userId, remarks = null) {
  await conn.query('UPDATE rec_candidates SET status = ?, updated_by = ? WHERE id = ?', [
    toStatus,
    userId,
    candidateId,
  ]);
  await conn.query(
    `INSERT INTO rec_candidate_status_log (candidate_id, from_status, to_status, remarks, changed_by)
     VALUES (?, ?, ?, ?, ?)`,
    [candidateId, fromStatus, toStatus, remarks ? String(remarks).slice(0, 255) : null, userId]
  );
}

module.exports = { STATUS, getCandidateForUpdate, assertStatus, setStatus };
