/**
 * Seeds masters, demo users, salary components, document checklist,
 * employee code sequences and default letter templates.
 * Safe to run more than once (uses INSERT IGNORE / existence checks).
 */
require('dotenv').config();
const bcrypt = require('bcryptjs');
const { pool } = require('../src/config/db');

const USERS = [
  ['Super Admin', 'superadmin@hhc.local', 'Admin@123', 'SUPER_ADMIN'],
  ['HR Executive', 'hr@hhc.local', 'Hr@12345', 'HR'],
  ['Unit Manager', 'manager@hhc.local', 'Manager@123', 'MANAGER'],
];

const DEPARTMENTS = ['Surgery', 'Nursing', 'OPD', 'Operation Theatre', 'Front Office', 'Billing & Accounts', 'Marketing', 'Human Resources', 'Pharmacy', 'Housekeeping'];
const DESIGNATIONS = ['Consultant Surgeon', 'Resident Medical Officer', 'Staff Nurse', 'OT Technician', 'Front Office Executive', 'Patient Counsellor', 'Billing Executive', 'Accountant', 'HR Executive', 'Unit Manager', 'Marketing Executive', 'Pharmacist'];
const LOCATIONS = ['Pune - Sangamvadi', 'Ahmedabad - Ellisbridge', 'Ahmedabad - Bopal'];

// code, name, group, calc_type, calc_value, order
const COMPONENTS = [
  ['BASIC', 'Basic Salary', 'EARNING', 'PERCENT_OF_GROSS', 50, 1],
  ['HRA', 'House Rent Allowance', 'EARNING', 'PERCENT_OF_BASIC', 40, 2],
  ['CONV', 'Conveyance Allowance', 'EARNING', 'FIXED', 1600, 3],
  ['SPECIAL', 'Special Allowance', 'EARNING', 'BALANCE', null, 4],
  ['PF_ER', 'Employer PF Contribution', 'EMPLOYER_CONTRIBUTION', 'PERCENT_OF_BASIC', 12, 10],
  ['ESIC_ER', 'Employer ESIC Contribution', 'EMPLOYER_CONTRIBUTION', 'PERCENT_OF_GROSS', 3.25, 11],
  ['GRATUITY', 'Gratuity', 'EMPLOYER_CONTRIBUTION', 'PERCENT_OF_BASIC', 4.81, 12],
  ['PF_EE', 'Employee PF Contribution', 'EMPLOYEE_DEDUCTION', 'PERCENT_OF_BASIC', 12, 20],
  ['ESIC_EE', 'Employee ESIC Contribution', 'EMPLOYEE_DEDUCTION', 'PERCENT_OF_GROSS', 0.75, 21],
  ['PT', 'Professional Tax', 'EMPLOYEE_DEDUCTION', 'FIXED', 200, 22],
];

// name, applicable_to, mandatory, requires_number, order
const DOC_TYPES = [
  ['Aadhaar Card', 'BOTH', 1, 1, 1],
  ['PAN Card', 'BOTH', 1, 1, 2],
  ['Passport Size Photograph', 'BOTH', 1, 0, 3],
  ['10th Marksheet', 'EMPLOYEE', 1, 0, 4],
  ['12th / Diploma Marksheet', 'EMPLOYEE', 0, 0, 5],
  ['Graduation / Highest Qualification Certificate', 'EMPLOYEE', 1, 0, 6],
  ['Experience / Relieving Letter', 'EMPLOYEE', 0, 0, 7],
  ['Last 3 Months Salary Slips', 'EMPLOYEE', 0, 0, 8],
  ['Bank Passbook / Cancelled Cheque', 'BOTH', 1, 1, 9],
  ['MBBS Degree Certificate', 'CONSULTANT', 1, 0, 20],
  ['MS / MD / DNB Degree Certificate', 'CONSULTANT', 1, 0, 21],
  ['Medical Council Registration Certificate', 'CONSULTANT', 1, 1, 22],
  ['Professional Indemnity Insurance', 'CONSULTANT', 0, 1, 23],
];

const HEADER = `<div class="hdr"><div class="co">{{company_name}}</div><div class="ad">{{company_address}}</div></div>`;

const OFFER_TEMPLATE = `${HEADER}
<p><b>Ref:</b> {{offer_letter_no}}<br/><b>Date:</b> {{offer_date}}</p>
<p>To,<br/>{{salutation}} {{candidate_name}}<br/>{{candidate_address}}</p>
<h2>Offer of Employment</h2>
<p>Dear {{candidate_name}},</p>
<p>We are pleased to offer you the position of <b>{{designation}}</b> in the <b>{{department}}</b> department at our <b>{{location}}</b> unit. Your total Cost to Company (CTC) will be <b>₹ {{ctc_annual}} per annum</b>, as detailed in the annexure below.</p>
<p>You are requested to join on or before <b>{{joining_date}}</b>. You will report to <b>{{reporting_manager}}</b>. You will be on probation for {{probation_months}} months from your date of joining.</p>
<p>This offer is valid till <b>{{offer_valid_till}}</b>. Please accept the offer through the link shared with you. On joining, you will be required to submit the documents listed by HR for verification. A detailed appointment letter will be issued after joining formalities are complete.</p>
<p>We look forward to welcoming you to the team.</p>
<div class="sign"><p>For {{company_name}}<br/><br/><br/>Authorised Signatory<br/>Human Resources</p></div>
<div class="pb"></div>
<h3>Annexure - CTC Breakup</h3>
{{ctc_annexure_html}}`;

const AGREEMENT_TEMPLATE = `${HEADER}
<p><b>Agreement No:</b> {{agreement_no}}<br/><b>Date:</b> {{today}}</p>
<h2>Consultant Surgeon Agreement</h2>
<p>This Agreement is made between <b>{{company_name}}</b>, {{company_address}} (hereinafter "the Hospital") and <b>Dr. {{candidate_name}}</b>, {{speciality}}, Medical Council Registration No. <b>{{medical_council_reg_no}}</b>, residing at {{candidate_address}} (hereinafter "the Consultant").</p>
<h3>1. Engagement</h3>
<p>The Hospital engages the Consultant as <b>{{designation}}</b> on a professional, non-employee basis at its <b>{{location}}</b> unit, effective <b>{{agreement_start_date}}</b> and valid {{agreement_end_date}}.</p>
<h3>2. Professional Fees</h3>
<p>The Consultant shall be paid professional fees as per the terms below, subject to deduction of TDS as applicable under the Income Tax Act.</p>
{{ctc_annexure_html}}
<h3>3. Duties</h3>
<p>The Consultant shall provide consultation, surgical and follow-up care to patients as per the Hospital's clinical protocols, maintain proper medical records, and follow the Hospital's policies.</p>
<h3>4. Termination</h3>
<p>Either party may terminate this Agreement by giving {{notice_period_days}} days' written notice.</p>
<h3>5. Confidentiality</h3>
<p>The Consultant shall keep all patient and Hospital information confidential during and after the term of this Agreement.</p>
<table style="width:100%;margin-top:50px"><tr>
<td>For {{company_name}}<br/><br/><br/>Authorised Signatory</td>
<td style="text-align:right">Consultant<br/><br/><br/>Dr. {{candidate_name}}</td></tr></table>`;

const APPOINTMENT_TEMPLATE = `${HEADER}
<p><b>Ref:</b> {{appointment_letter_no}}<br/><b>Date:</b> {{letter_date}}</p>
<p>To,<br/>{{salutation}} {{candidate_name}}<br/>Employee Code: <b>{{employee_code}}</b><br/>{{candidate_address}}</p>
<h2>Letter of Appointment</h2>
<p>Dear {{candidate_name}},</p>
<p>With reference to your joining on <b>{{date_of_joining}}</b>, we are pleased to confirm your appointment as <b>{{designation}}</b> in the <b>{{department}}</b> department at our <b>{{location}}</b> unit, effective <b>{{effective_date}}</b>.</p>
<h3>1. Compensation</h3>
<p>Your annual compensation will be <b>₹ {{ctc_annual}}</b>, as detailed in the annexure attached to this letter.</p>
<h3>2. Reporting</h3>
<p>You will report to {{reporting_manager}} or any other person designated by the management.</p>
<h3>3. Probation</h3>
<p>Your employment type is {{employment_type}}. Where applicable, your probation period ends on {{probation_end_date}}.</p>
<h3>4. Rules &amp; Policies</h3>
<p>You will be governed by the rules, policies and code of conduct of the organisation as amended from time to time.</p>
<p>Please sign and return a copy of this letter as a token of your acceptance.</p>
<div class="sign"><p>For {{company_name}}<br/><br/><br/>Authorised Signatory<br/>Human Resources</p></div>
<p style="margin-top:30px">I accept the terms and conditions of this appointment.<br/><br/>Signature: ____________________ &nbsp; Date: __________</p>
{{annexure_section_html}}`;

async function insertNames(table, names) {
  for (const n of names) await pool.query(`INSERT IGNORE INTO ${table} (name) VALUES (?)`, [n]);
}

(async () => {
  for (const [name, email, pwd, role] of USERS) {
    const hash = await bcrypt.hash(pwd, 10);
    await pool.query('INSERT IGNORE INTO users (name, email, password_hash, role) VALUES (?, ?, ?, ?)', [name, email, hash, role]);
  }
  await insertNames('departments', DEPARTMENTS);
  await insertNames('designations', DESIGNATIONS);
  await insertNames('locations', LOCATIONS);

  for (const c of COMPONENTS) {
    await pool.query(
      `INSERT IGNORE INTO rec_salary_components (component_code, component_name, component_group, calc_type, calc_value, display_order)
       VALUES (?, ?, ?, ?, ?, ?)`,
      c
    );
  }

  const [[{ n: docCount }]] = await pool.query('SELECT COUNT(*) AS n FROM rec_document_types');
  if (!docCount) {
    for (const d of DOC_TYPES) {
      await pool.query(
        'INSERT INTO rec_document_types (document_name, applicable_to, is_mandatory, requires_number, display_order) VALUES (?, ?, ?, ?, ?)',
        d
      );
    }
  }

  await pool.query(
    `INSERT IGNORE INTO employee_code_sequences (code_type, prefix, padding, last_number)
     VALUES ('EMPLOYEE','HHCPL',4,1630), ('CONSULTANT','HHCPL',4,1630)`
  );

  const [[{ id: adminId }]] = await pool.query("SELECT id FROM users WHERE role = 'SUPER_ADMIN' ORDER BY id LIMIT 1");
  for (const [type, name, body] of [
    ['OFFER_LETTER', 'Standard Offer Letter', OFFER_TEMPLATE],
    ['CONSULTANT_AGREEMENT', 'Consultant Surgeon Agreement', AGREEMENT_TEMPLATE],
    ['APPOINTMENT_LETTER', 'Standard Appointment Letter', APPOINTMENT_TEMPLATE],
  ]) {
    const [[exists]] = await pool.query('SELECT id FROM rec_letter_templates WHERE template_type = ? LIMIT 1', [type]);
    if (!exists) {
      await pool.query(
        'INSERT INTO rec_letter_templates (template_type, template_name, body_html, is_default, created_by) VALUES (?, ?, ?, 1, ?)',
        [type, name, body, adminId]
      );
    }
  }

  console.log('Seed complete. Demo logins:');
  USERS.forEach(([, e, p, r]) => console.log(`  ${r.padEnd(12)} ${e} / ${p}`));
  await pool.end();
})().catch((e) => {
  console.error('Seed failed:', e.message);
  process.exit(1);
});
