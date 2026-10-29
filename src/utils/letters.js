const path = require('path');
const fs = require('fs');
const { UPLOAD_ROOT, imageDataUri } = require('../middleware/upload');

const LETTER_DIR = 'letters';

const inr = (n) =>
  n === null || n === undefined || n === ''
    ? '-'
    : Number(n).toLocaleString('en-IN', { minimumFractionDigits: 0, maximumFractionDigits: 2 });

const fmtDate = (d) => {
  if (!d) return '';
  const dt = new Date(String(d).slice(0, 10) + 'T00:00:00');
  return dt.toLocaleDateString('en-IN', { day: '2-digit', month: 'long', year: 'numeric' });
};

const esc = (s) =>
  String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

/**
 * Fills a letter template.
 *  {{key}}                          -> value (HTML-escaped unless the key ends with _html)
 *  {{#if key}} ... {{/if}}          -> kept only when data[key] is truthy
 *  {{#unless key}} ... {{/unless}}  -> kept only when data[key] is falsy
 */
function renderTemplate(body, data) {
  body = body
    .replace(/\{\{#if\s+([a-z0-9_]+)\s*\}\}([\s\S]*?)\{\{\/if\}\}/gi, (m, key, inner) => (data[key] ? inner : ''))
    .replace(/\{\{#unless\s+([a-z0-9_]+)\s*\}\}([\s\S]*?)\{\{\/unless\}\}/gi, (m, key, inner) => (data[key] ? '' : inner));
  return body.replace(/\{\{\s*([a-z0-9_]+)\s*\}\}/gi, (m, key) => {
    if (!(key in data)) return m;
    return key.endsWith('_html') ? data[key] : esc(data[key]);
  });
}

const MONTH_WORDS = ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten', 'eleven', 'twelve'];

const FEE_TYPE_LABEL = {
  FIXED_MONTHLY: 'Fixed Monthly Fee',
  PER_CASE: 'Per Case Fee',
  REVENUE_SHARE: 'Revenue Share',
  HYBRID: 'Hybrid (Fixed + Per Case / Revenue Share)',
};

/** CTC Annexure table for salaried employees */
function salaryAnnexureHtml(proposal, components) {
  const groups = [
    ['EARNING', 'A. Earnings'],
    ['EMPLOYER_CONTRIBUTION', 'B. Employer Contributions'],
    ['EMPLOYEE_DEDUCTION', 'C. Employee Deductions'],
  ];
  let rows = '';
  for (const [g, label] of groups) {
    const items = components.filter((c) => c.component_group === g && Number(c.monthly_amount) !== 0);
    if (!items.length) continue;
    rows += `<tr class="grp"><td colspan="3">${label}</td></tr>`;
    for (const c of items) {
      rows += `<tr><td>${esc(c.component_name)}</td><td class="r">${inr(c.monthly_amount)}</td><td class="r">${inr(
        c.annual_amount
      )}</td></tr>`;
    }
  }
  rows += `<tr class="tot"><td>Gross Salary (A)</td><td class="r">${inr(proposal.gross_monthly)}</td><td class="r">${inr(
    proposal.gross_monthly * 12
  )}</td></tr>`;
  rows += `<tr class="tot"><td>Cost to Company (A + B)</td><td class="r">${inr(proposal.ctc_monthly)}</td><td class="r">${inr(
    proposal.ctc_annual
  )}</td></tr>`;
  if (proposal.net_take_home_monthly !== null) {
    rows += `<tr class="tot"><td>Net Take Home (A - C)</td><td class="r">${inr(
      proposal.net_take_home_monthly
    )}</td><td class="r">${inr(proposal.net_take_home_monthly * 12)}</td></tr>`;
  }
  return `<table class="annex"><thead><tr><th>Component</th><th class="r">Monthly (₹)</th><th class="r">Annual (₹)</th></tr></thead><tbody>${rows}</tbody></table>`;
}

/** Fee terms table for consultants (surgeons) */
function feeAnnexureHtml(p) {
  const rows = [['Fee Type', FEE_TYPE_LABEL[p.fee_type] || p.fee_type]];
  if (p.fixed_monthly_fee) rows.push(['Fixed Monthly Fee (₹)', inr(p.fixed_monthly_fee)]);
  if (p.per_case_fee) rows.push(['Per Case Fee (₹)', inr(p.per_case_fee)]);
  if (p.revenue_share_percent) rows.push(['Revenue Share (%)', `${p.revenue_share_percent}%`]);
  if (p.minimum_guarantee) rows.push(['Minimum Guarantee per Month (₹)', inr(p.minimum_guarantee)]);
  if (p.ctc_annual) rows.push(['Estimated Annual Professional Fee (₹)', inr(p.ctc_annual)]);
  return `<table class="annex"><tbody>${rows
    .map(([k, v]) => `<tr><td>${esc(k)}</td><td class="r">${esc(v)}</td></tr>`)
    .join('')}</tbody></table>`;
}

function annexureHtml(proposal, components) {
  return proposal.compensation_type === 'CONSULTANT_FEE'
    ? feeAnnexureHtml(proposal)
    : salaryAnnexureHtml(proposal, components);
}

/** Loads everything a letter might need for a candidate + approved proposal */
async function loadLetterData(conn, candidateId, proposalId) {
  const [[c]] = await conn.query('SELECT * FROM rec_candidates WHERE id = ?', [candidateId]);
  const [[p]] = await conn.query(
    `SELECT p.*, d.name AS department_name, g.name AS designation_name, l.name AS location_name,
            u.name AS reporting_manager_name
       FROM rec_ctc_proposals p
       LEFT JOIN departments d ON d.id = p.department_id
       LEFT JOIN designations g ON g.id = p.designation_id
       LEFT JOIN locations l ON l.id = p.location_id
       LEFT JOIN users u ON u.id = p.reporting_manager_id
      WHERE p.id = ?`,
    [proposalId]
  );
  const [components] = await conn.query(
    `SELECT pc.*, sc.component_name, sc.component_group, sc.display_order
       FROM rec_ctc_proposal_components pc
       JOIN rec_salary_components sc ON sc.id = pc.component_id
      WHERE pc.ctc_proposal_id = ?
      ORDER BY sc.display_order`,
    [proposalId]
  );
  const fullName = [c.first_name, c.middle_name, c.last_name].filter(Boolean).join(' ');
  const salutation = c.gender === 'FEMALE' ? 'Ms.' : c.gender === 'MALE' ? 'Mr.' : '';
  const months = Number(p.probation_months) || 6;
  return {
    candidate: c,
    proposal: p,
    components,
    data: {
      ...letterheadData(), // {{letterhead_header_src}} / {{letterhead_footer_src}} for the on-screen preview of letterhead letters
      // Super Admin signature uploaded at the final CTC approval -> printed above the HHC signatory
      signature_html: signatureHtml(p.approval_signature_path),
      company_name: process.env.COMPANY_NAME || 'Healing Hands Clinic',
      company_address: process.env.COMPANY_ADDRESS || '',
      candidate_name: fullName,
      salutation: c.candidate_type === 'CONSULTANT' ? 'Dr.' : salutation,
      candidate_address: [c.address, c.city, c.state, c.pincode].filter(Boolean).join(', '),
      candidate_email: c.email,
      candidate_mobile: c.mobile_no,
      candidate_code: c.candidate_code,
      designation: p.designation_name || '',
      department: p.department_name || '',
      location: p.location_name || '',
      reporting_manager: p.reporting_manager_name || '',
      employment_type: p.employment_type,
      probation_months: p.probation_months || '',
      probation_period: `${MONTH_WORDS[months] || months} month${months === 1 ? '' : 's'}`,
      last_name: c.last_name,
      hr_signatory_name: process.env.HR_SIGNATORY_NAME || 'Mr. Sagar Shekhar',
      hr_signatory_designation: process.env.HR_SIGNATORY_DESIGNATION || 'Head – Human Resources',
      ctc_annual: inr(p.ctc_annual),
      ctc_monthly: inr(p.ctc_monthly),
      gross_monthly: inr(p.gross_monthly),
      fee_type: FEE_TYPE_LABEL[p.fee_type] || '',
      ctc_annexure_html: annexureHtml(p, components),
      today: fmtDate(new Date().toISOString()),
    },
  };
}

const PAGE_CSS = `
  body{font-family:Arial,Helvetica,sans-serif;font-size:12.5px;line-height:1.55;color:#222;margin:0}
  .page{padding:10px 6px}
  h1,h2,h3{margin:0 0 8px} h2{font-size:17px} h3{font-size:14px;margin-top:18px}
  .hdr{border-bottom:2px solid #0b6e6e;padding-bottom:8px;margin-bottom:18px}
  .hdr .co{font-size:19px;font-weight:bold;color:#0b6e6e} .hdr .ad{font-size:11px;color:#555}
  table.annex{width:100%;border-collapse:collapse;margin-top:8px}
  table.annex th,table.annex td{border:1px solid #bbb;padding:5px 8px}
  table.annex th{background:#eef5f5;text-align:left}
  .r{text-align:right} tr.grp td{background:#f6f6f6;font-weight:bold} tr.tot td{font-weight:bold}
  .pb{page-break-before:always} .sign{margin-top:40px}
`;

/**
 * Full HTML page for a letter. Templates that carry their own design
 * (class="letter" + their own <style>/@page, e.g. the HHC offer and
 * appointment letters) are used as they are; older simple templates
 * get the default PAGE_CSS.
 */
function wrapHtml(inner) {
  if (/class="letter"/.test(inner)) {
    return `<!doctype html><html><head><meta charset="utf-8"><style>body{margin:0}</style></head><body>${inner}</body></html>`;
  }
  return `<!doctype html><html><head><meta charset="utf-8"><style>${PAGE_CSS}</style></head><body><div class="page">${inner}</div></body></html>`;
}

const PDF_TIMEOUT_MS = Number(process.env.PDF_TIMEOUT_SECONDS || 60) * 1000;
const FOOTER_TEXT = () => process.env.LETTER_FOOTER_TEXT || 'Healing Hands Clinic Private Limited | Confidential';

/** Prints one full HTML page to a PDF file with Chromium (puppeteer). Throws when no valid PDF comes out. */
async function renderPdf(full, outFull) {
  const ownDesign = /class="letter"/.test(full);
  const letterhead = letterheadKind(full); // letterhead header + footer on every page (hhc / hco), or null
  let browser = null;
  const makePdf = async () => {
    const puppeteer = require('puppeteer');
    browser = await puppeteer.launch({
      headless: true,
      timeout: PDF_TIMEOUT_MS, // browser start
      protocolTimeout: PDF_TIMEOUT_MS, // each Chromium command
      args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage', '--disable-gpu', ...(process.platform === 'linux' ? ['--no-zygote'] : [])],
    });
    const page = await browser.newPage();
    page.setDefaultTimeout(PDF_TIMEOUT_MS);
    await page.setContent(full, { waitUntil: 'load' });
    await page.emulateMediaType('print');
    const tmp = `${outFull}.part`; // write to a temp name first: a half-written PDF never takes the real name
    await page.pdf({
      path: tmp,
      printBackground: true,
      // HHC letters define page size + margins in their own @page rule (US Letter, same as the Word originals)
      ...(ownDesign ? { preferCSSPageSize: true } : { format: 'A4', margin: { top: '18mm', bottom: '18mm', left: '16mm', right: '16mm' } }),
      displayHeaderFooter: true,
      ...(letterhead
        ? letterheadPdfTemplates(letterhead)
        : {
            headerTemplate: '<div></div>',
            footerTemplate: `<div style="width:100%;text-align:center;font-family:Arial,sans-serif;font-size:8pt;color:#000;padding-bottom:0.25in">${esc(FOOTER_TEXT())}</div>`,
          }),
    });
    if (!isValidPdf(tmp)) {
      fs.rmSync(tmp, { force: true });
      throw new Error('Chromium returned an empty / invalid PDF');
    }
    fs.renameSync(tmp, outFull);
  };
  try {
    // hard stop: never let a stuck Chromium hold the request (and the user's screen) for ever
    let timer;
    await Promise.race([
      makePdf(),
      new Promise((_, reject) => {
        timer = setTimeout(() => reject(new Error(`PDF took longer than ${PDF_TIMEOUT_MS / 1000}s`)), PDF_TIMEOUT_MS + 5000);
      }),
    ]).finally(() => clearTimeout(timer));
  } finally {
    if (browser) {
      const b = browser;
      await Promise.race([b.close(), new Promise((r) => setTimeout(r, 5000))]).catch(() => {});
      try {
        b.process()?.kill('SIGKILL'); // make sure no Chromium is left running (no-op if already closed)
      } catch {
        /* already gone */
      }
    }
  }
}

/** A real PDF: starts with %PDF and is not tiny */
function isValidPdf(file) {
  try {
    if (!fs.existsSync(file) || fs.statSync(file).size < 1024) return false;
    const fd = fs.openSync(file, 'r');
    const b = Buffer.alloc(5);
    fs.readSync(fd, b, 0, 5, 0);
    fs.closeSync(fd);
    return b.toString('latin1') === '%PDF-';
  } catch {
    return false;
  }
}

const isPdfPath = (rel) => /\.pdf$/i.test(rel || '');

/**
 * Writes the letter as PDF (via puppeteer), trying twice. If Chromium still fails, saves an
 * HTML copy so the flow does not stop - that copy is never emailed as a PDF (see ensurePdf).
 * Returns path relative to uploads root.
 */
async function writeLetterFile(baseName, html) {
  const dir = path.join(UPLOAD_ROOT, LETTER_DIR);
  fs.mkdirSync(dir, { recursive: true });
  const safe = baseName.replace(/[^a-z0-9_-]+/gi, '_');
  const full = wrapHtml(html);
  const outPdf = path.join(dir, `${safe}.pdf`);
  let lastErr = null;
  for (let attempt = 1; attempt <= 2; attempt++) {
    const started = Date.now();
    try {
      await renderPdf(full, outPdf);
      console.log(`[letters] ${safe}.pdf created in ${((Date.now() - started) / 1000).toFixed(1)}s`);
      return `${LETTER_DIR}/${safe}.pdf`;
    } catch (err) {
      lastErr = err;
      console.warn(`[letters] PDF attempt ${attempt} for ${safe} failed: ${err.message}`);
    }
  }
  console.warn('[letters] PDF generation failed, saving HTML instead:', lastErr && lastErr.message);
  fs.writeFileSync(path.join(dir, `${safe}.html`), full);
  return `${LETTER_DIR}/${safe}.html`;
}

/**
 * Makes sure a saved letter is a real PDF before it is emailed / downloaded:
 * an older HTML fallback copy is converted now. Returns the (possibly new) relative path;
 * still ends in .html when Chromium cannot run on this server.
 */
async function ensurePdf(rel) {
  if (!rel) return rel;
  const full = path.join(UPLOAD_ROOT, rel);
  if (isPdfPath(rel)) return rel; // already a PDF
  if (!/\.html$/i.test(rel) || !fs.existsSync(full)) return rel;
  const relPdf = rel.replace(/\.html$/i, '.pdf');
  try {
    await renderPdf(fs.readFileSync(full, 'utf8'), path.join(UPLOAD_ROOT, relPdf));
    console.log(`[letters] ${relPdf} created from the saved HTML copy`);
    return relPdf;
  } catch (err) {
    console.warn(`[letters] could not convert ${rel} to PDF: ${err.message}`);
    return rel;
  }
}

/**
 * Returns the one letter format in use for a type (the attached HHC Offer / HHCPL Appointment Letter).
 * There is no "Default / Standard" choice any more - the newest active template of that type is used.
 */
async function getTemplate(conn, type) {
  const [[t]] = await conn.query(
    'SELECT * FROM rec_letter_templates WHERE template_type = ? AND is_active = 1 ORDER BY is_default DESC, id DESC LIMIT 1',
    [type]
  );
  if (!t) {
    const e = new Error(`No active ${type} template found`);
    e.status = 400;
    throw e;
  }
  return t;
}

/* ------------------------------------------------------------------
 * Letterheads, printed on every PDF page (the template shows them once on screen / preview).
 * A template picks one with  <div class="letter" data-letterhead="...">
 *   hhc - from the Surgeon Service Agreement Word file: full-width logo band + helpline / address band
 *         (consultant agreement, appointment letter)
 *   hco - from HCO_Letter_Head_Template_1.docx: centred "Curing with Care" logo + city strip with NABH seal,
 *         images 7.4in wide, 0.5in from the top / bottom page edge (offer letter)
 * ------------------------------------------------------------------ */
const ASSET_DIR = path.join(__dirname, '..', '..', 'assets');
const LETTERHEADS = {
  hhc: { header: 'letterhead-header.png', footer: 'letterhead-footer.png', width: '8.5in', edgeGap: '0' },
  hco: { header: 'letterhead2-header.jpg', footer: 'letterhead2-footer.jpg', width: '7.396in', edgeGap: '0.5in' },
};
const letterheadCache = {};
function letterheadImages(kind = 'hhc') {
  if (!letterheadCache[kind]) {
    const cfg = LETTERHEADS[kind] || LETTERHEADS.hhc;
    const read = (f) => {
      const p = path.join(ASSET_DIR, f);
      const mime = /\.jpe?g$/i.test(f) ? 'image/jpeg' : 'image/png';
      return fs.existsSync(p) ? `data:${mime};base64,${fs.readFileSync(p).toString('base64')}` : '';
    };
    letterheadCache[kind] = { header: read(cfg.header), footer: read(cfg.footer) };
  }
  return letterheadCache[kind];
}

/** Which letterhead a filled template asks for ('hhc' / 'hco'), or null */
function letterheadKind(html) {
  const m = /data-letterhead="([a-z0-9]+)"/.exec(html);
  return m && LETTERHEADS[m[1]] ? m[1] : null;
}

/**
 * Image sources for the on-screen preview:
 *   {{letterhead_header_src}}  / {{letterhead_footer_src}}   -> hhc
 *   {{letterhead2_header_src}} / {{letterhead2_footer_src}}  -> hco
 */
function letterheadData() {
  const hhc = letterheadImages('hhc');
  const hco = letterheadImages('hco');
  return {
    letterhead_header_src: hhc.header,
    letterhead_footer_src: hhc.footer,
    letterhead2_header_src: hco.header,
    letterhead2_footer_src: hco.footer,
  };
}

/** Chromium header/footer templates for a letterhead (placed in the page's top / bottom margin) */
function letterheadPdfTemplates(kind = 'hhc') {
  const cfg = LETTERHEADS[kind] || LETTERHEADS.hhc;
  const { header, footer } = letterheadImages(kind);
  const wrap = (src, edge) =>
    `<div style="width:100%;margin:0;padding:0;font-size:0;-webkit-print-color-adjust:exact;position:absolute;${edge}:${cfg.edgeGap};left:0;right:0">` +
    (src ? `<img src="${src}" style="display:block;width:${cfg.width};height:auto;margin:0 auto">` : '') +
    '</div>';
  return { headerTemplate: wrap(header, 'top'), footerTemplate: wrap(footer, 'bottom') };
}

/** <img> of the approval signature for {{signature_html}} ('' when none, so old letters print as before) */
function signatureHtml(rel) {
  const src = imageDataUri(rel);
  return src
    ? `<img class="sig-img" src="${src}" alt="Signature" style="display:block;max-height:0.6in;max-width:2in;height:auto;width:auto;margin:2pt 0">`
    : '';
}

/** Indian number format with words, e.g. 300000 -> { amount: '3,00,000', words: 'Three Lakh' } */
const ONES = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen',
  'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'];
const TENS = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];
function upto99(n) {
  return n < 20 ? ONES[n] : `${TENS[Math.floor(n / 10)]}${n % 10 ? ' ' + ONES[n % 10] : ''}`;
}
function upto999(n) {
  const h = Math.floor(n / 100);
  const r = n % 100;
  return [h ? `${ONES[h]} Hundred` : '', r ? upto99(r) : ''].filter(Boolean).join(' ');
}
function rupeesInWords(value) {
  let n = Math.round(Number(value) || 0);
  if (!n) return 'Zero';
  const parts = [];
  const crore = Math.floor(n / 10000000); n %= 10000000;
  const lakh = Math.floor(n / 100000); n %= 100000;
  const thousand = Math.floor(n / 1000); n %= 1000;
  if (crore) parts.push(`${crore > 99 ? rupeesInWords(crore) : upto99(crore)} Crore`);
  if (lakh) parts.push(`${upto99(lakh)} Lakh`);
  if (thousand) parts.push(`${upto99(thousand)} Thousand`);
  if (n) parts.push(upto999(n));
  return parts.join(' ');
}
const inrPlain = (n) => Math.round(Number(n) || 0).toLocaleString('en-IN');

module.exports = {
  renderTemplate, loadLetterData, writeLetterFile, getTemplate, wrapHtml, annexureHtml, fmtDate, inr, esc,
  letterheadData, letterheadPdfTemplates, letterheadKind, rupeesInWords, inrPlain, ensurePdf, isPdfPath,
};
