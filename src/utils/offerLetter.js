/**
 * Builds the Offer Letter HTML. Used by HR screens (preview / generate) and by the
 * candidate portal, so the candidate always sees exactly the same letter as the PDF.
 *
 * CTC rule: the offer letter ALWAYS shows the total annual CTC (clause 6 "Compensation")
 * and NEVER shows the CTC breakup. The breakup is printed only in the Appointment Letter.
 */
const { renderTemplate, loadLetterData, getTemplate, fmtDate } = require('./letters');

/**
 * @param conn  db connection / pool
 * @param o     { candidate_id, ctc_proposal_id, offer_letter_no, offer_date, joining_date, offer_valid_till }
 */
async function buildOfferHtml(conn, o) {
  const tpl = await getTemplate(conn, 'OFFER_LETTER');
  const { data, candidate, proposal } = await loadLetterData(conn, o.candidate_id, o.ctc_proposal_id);

  Object.assign(data, {
    offer_letter_no: o.offer_letter_no || '',
    offer_date: fmtDate(o.offer_date),
    joining_date: fmtDate(o.joining_date),
    offer_valid_till: fmtDate(o.offer_valid_till),
    include_ctc: true, // total CTC is always printed (kept for older templates that still use {{#if include_ctc}})
    ctc_annexure_html: '', // never print the breakup in an offer letter
    docs_annexure: 'B', // Documents annexure keeps its HHC print-format name
  });
  // clause numbers are fixed now that "6. Compensation" is always present
  for (let n = 7; n <= 40; n++) data[`sec_${n}`] = n;

  return { html: renderTemplate(tpl.body_html, data), tpl, data, candidate, proposal };
}

module.exports = { buildOfferHtml };
