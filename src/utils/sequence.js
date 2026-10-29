/**
 * Running numbers. All functions must be called with a connection that is
 * inside a transaction, so SELECT ... FOR UPDATE prevents duplicates.
 */

async function nextYearly(conn, key) {
  const year = new Date().getFullYear();
  await conn.query(
    'INSERT IGNORE INTO doc_number_sequences (seq_key, seq_year, last_number) VALUES (?, ?, 0)',
    [key, year]
  );
  const [[row]] = await conn.query(
    'SELECT last_number FROM doc_number_sequences WHERE seq_key = ? AND seq_year = ? FOR UPDATE',
    [key, year]
  );
  const next = row.last_number + 1;
  await conn.query(
    'UPDATE doc_number_sequences SET last_number = ? WHERE seq_key = ? AND seq_year = ?',
    [next, key, year]
  );
  return { year, next };
}

async function nextCandidateCode(conn) {
  const { year, next } = await nextYearly(conn, 'CANDIDATE');
  return `CAND-${year}-${String(next).padStart(5, '0')}`;
}

/** type: OL (offer letter), CA (consultant agreement), AL (appointment letter) */
async function nextLetterNo(conn, type) {
  const { year, next } = await nextYearly(conn, type);
  return `HHC/${type}/${year}/${String(next).padStart(4, '0')}`;
}

/**
 * Step 6 - unique Employee Code: ONE continuous series for EMPLOYEE and CONSULTANT.
 *   last issued HHCPL1630 -> HHCPL1631 (consultant) -> HHCPL1632 (employee) -> HHCPL1633 (consultant) ...
 * The candidate type never changes the prefix or the counter.
 *
 * The counter lives in the 'EMPLOYEE' row of employee_code_sequences (the 'CONSULTANT' row is not used).
 * Next number = 1 + the highest of:
 *   - the counter in that row (only if it is already an HHCPL counter),
 *   - EMPLOYEE_CODE_START_AFTER (last code in the old register, default 1630),
 *   - the highest HHCPL code already in the Employee Master.
 * So it works even if `npm run db:upgrade` was never run, and never re-issues or goes backwards.
 * The row is locked FOR UPDATE inside the caller's transaction, so two HR users can't get the same code.
 */
const SHARED_CODE_ROW = 'EMPLOYEE';
const CODE_PREFIX = 'HHCPL';
const CODE_DIGITS = 4; // HHCPL1631; grows to 5 digits after HHCPL9999 automatically
const startAfter = () => Number(process.env.EMPLOYEE_CODE_START_AFTER || 1630);

// eslint-disable-next-line no-unused-vars
async function nextEmployeeCode(conn, _candidateType) {
  // make sure the shared counter row exists, then lock it
  await conn.query(
    'INSERT IGNORE INTO employee_code_sequences (code_type, prefix, padding, last_number) VALUES (?, ?, ?, ?)',
    [SHARED_CODE_ROW, CODE_PREFIX, CODE_DIGITS, startAfter()]
  );
  const [[row]] = await conn.query(
    'SELECT prefix, last_number FROM employee_code_sequences WHERE code_type = ? FOR UPDATE',
    [SHARED_CODE_ROW]
  );
  const [[used]] = await conn.query(
    `SELECT MAX(CAST(SUBSTRING(employee_code, ?) AS UNSIGNED)) AS n
       FROM employees WHERE employee_code REGEXP ?`,
    [CODE_PREFIX.length + 1, `^${CODE_PREFIX}[0-9]+$`]
  );
  const counter = row.prefix === CODE_PREFIX ? Number(row.last_number) : 0;
  const next = Math.max(counter, startAfter(), Number(used?.n || 0)) + 1;

  await conn.query(
    'UPDATE employee_code_sequences SET prefix = ?, padding = ?, last_number = ? WHERE code_type = ?',
    [CODE_PREFIX, CODE_DIGITS, next, SHARED_CODE_ROW]
  );
  return `${CODE_PREFIX}${String(next).padStart(CODE_DIGITS, '0')}`;
}

module.exports = { nextCandidateCode, nextLetterNo, nextEmployeeCode };
