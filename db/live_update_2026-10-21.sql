-- =====================================================================
-- HHC Recruitment - LIVE SERVER UPDATE (21 Oct 2026)
-- Super Admin signature at final CTC approval, printed on the
-- Offer Letter, Appointment Letter and Surgeon Service Agreement.
-- Safe on a database that already has data:
--   * adds 2 empty columns (existing rows are not changed)
--   * replaces the text of the 3 ACTIVE letter templates (same wording + signature spot)
--   * letters already generated keep their existing PDFs
-- RUN ONCE. (Running the ALTER lines again gives "Duplicate column" - that is harmless,
--  it just means they were already added; the rest of the file still needs to run.)
-- Take a backup first:  mysqldump -u root -p hhc_recruitment > backup_before_update.sql
-- If your database has another name, change the USE line below.
-- =====================================================================
USE hhc_recruitment;
SET NAMES utf8mb4;

ALTER TABLE users ADD COLUMN signature_path VARCHAR(255) NULL;
ALTER TABLE rec_ctc_proposals ADD COLUMN approval_signature_path VARCHAR(255) NULL AFTER approval_remarks;

UPDATE rec_letter_templates
   SET body_html = '<!-- Offer Letter (Healing Hands Clinic) - edit wording here; values in double curly braces are filled by the system. HHC letterhead (HCO_Letter_Head_Template_1: "Curing with Care" logo + city strip) is added on every PDF page. -->
<style>
@page { size: Letter; margin: 1.75in 0.5in 1.625in 0.5in; }
.letter { font-family: Arial, ''Liberation Sans'', Helvetica, sans-serif; font-size: 9.5pt; line-height: 1.21; color: #000; }
.letter p, .letter h1, .letter h2, .letter ul { margin-top: 0; }
.letter h1 { font-size: 15pt; font-weight: bold; text-align: center; margin-bottom: 6pt; line-height: 1.15; }
.letter h2 { font-size: 10pt; font-weight: bold; }
.letter .j { text-align: justify; }
.letter .c { text-align: center; }
.letter ul { margin-bottom: 0; padding-left: 0.42in; }
.letter li { padding-left: 2pt; }
.letter .pb { page-break-before: always; break-before: page; }
.letter table.annex { width: 100%; border-collapse: collapse; margin: 4pt 0 8pt; font-size: 9.5pt; }
.letter table.annex th, .letter table.annex td { border: 0.75pt solid #000; padding: 3pt 6pt; }
.letter table.annex th { background: #f2f2f2; text-align: left; }
.letter table.annex .r { text-align: right; }
.letter table.annex tr.grp td { font-weight: bold; background: #fafafa; }
.letter table.annex tr.tot td { font-weight: bold; }
.letter h2 { page-break-after: avoid; break-after: avoid; }
.letter, .letter * { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
.letter .lh-screen { display: none; }
.letter .keep { page-break-inside: avoid; break-inside: avoid; }
@media print { .letter .pb { padding-top: 16pt; } }
@media screen {
  body { background: #e9eef2; margin: 0; padding: 16px 0; }
  .letter { background: #fff; width: 8.5in; max-width: 100%; box-sizing: border-box; padding: 0.5in 0.5in 0.5in; margin: 0 auto; box-shadow: 0 2px 12px rgba(0,0,0,.12); }
  .letter .lh-screen { display: block; width: 7.396in; max-width: 100%; margin: 0 auto 0.4in; }
  .letter .lh-screen.lh-foot { margin: 0.4in auto 0; }
  .letter .pb { border-top: 1px dashed #b8c4cc; margin-top: 28pt; padding-top: 28pt; }
}
</style>
<div class="letter" data-letterhead="hco">
<img class="lh-screen" src="{{letterhead2_header_src}}" alt="">
<div class="gap" style="height:23.2pt"></div>
<h1>OFFER OF EMPLOYMENT</h1>
<div class="gap" style="height:15.9pt"></div>
<p style="margin-bottom:5.0pt">Date: {{offer_date}}</p>
<div class="gap" style="height:15.9pt"></div>
<p style="margin-bottom:5.0pt">Dear {{salutation}} {{candidate_name}},</p>
<div class="gap" style="height:13.9pt"></div>
<p class="j" style="margin-bottom:3.0pt">We are pleased to offer you the position of {{designation}} with Healing Hands Clinic Private Limited (“HHC” or the “Company”), based at {{location}} and reporting to {{reporting_manager}}, on the terms and conditions set out in this Offer Letter and its annexures. This offer is made in reliance on the information, qualifications, experience, declarations and documents provided by you during the recruitment process.</p>
<p class="j" style="margin-bottom:3.0pt">Your proposed date of joining is {{joining_date}}. This Offer Letter constitutes an offer of employment and, upon your acceptance and commencement of employment, the applicable terms herein, together with HHC’s policies and applicable law, will govern your employment. This offer does not by itself create any entitlement to employment where any condition of this offer remains unsatisfied.</p>
<div class="gap" style="height:13.5pt"></div>
<h2 style="margin-top:4.0pt;margin-bottom:2.0pt">1. CONDITIONS OF THIS OFFER</h2>
<p class="j" style="margin-bottom:3.0pt">This offer is conditional upon your:</p>
<ul>
<li style="margin-bottom:1.0pt">Accepting this Offer Letter within the prescribed acceptance period and joining HHC on the proposed date of joining, unless an alternative date is confirmed in writing by HHC;</li>
<li style="margin-bottom:1.0pt">Satisfactory completion of background, employment, education, professional qualification, reference and credential verification, as applicable to your role;</li>
<li style="margin-bottom:1.0pt">Submission of all documents and information required by HHC, including those listed in Annexure {{docs_annexure}};</li>
<li style="margin-bottom:1.0pt">Providing complete, accurate and truthful information and making no material omission or misrepresentation;</li>
<li style="margin-bottom:1.0pt">Confirming that your employment with HHC will not violate any enforceable obligation owed to any current or former employer or any other person; and</li>
<li style="margin-bottom:1.0pt">Satisfying any other lawful and role-specific condition communicated by HHC in writing.</li>
</ul>
<div class="gap" style="height:13.9pt"></div>
<p class="j" style="margin-bottom:3.0pt">HHC may withdraw or cancel this offer before your joining, without liability for future employment, if any of the above conditions are not satisfied, if material information is found to be false, incomplete or misleading, if verification is unsatisfactory, or if you fail to join as agreed. Any such action will be subject to applicable law.</p>
<div class="gap" style="height:13.5pt"></div>
<h2 style="margin-top:4.0pt;margin-bottom:2.0pt">2. PROBATION</h2>
<p class="j" style="margin-bottom:3.0pt">Your employment, upon commencement, will be subject to an initial probationary period of <b>{{probation_period}}</b>. During probation, HHC will assess your performance, conduct, attendance, capability, role suitability, adherence to policies and overall alignment with the requirements of the position.</p>
<p class="j" style="margin-bottom:3.0pt">Confirmation is not automatic upon expiry of the probationary period. You will be treated as confirmed only upon receipt of written confirmation from HHC. HHC may, subject to applicable law and its policies, extend the probationary period where additional assessment is considered necessary.</p>
<p class="j" style="margin-bottom:3.0pt">During probation, HHC may discontinue your employment for unsatisfactory performance, lack of role suitability, misconduct, breach of policy, loss of confidence based on legitimate employment-related grounds, or other lawful reasons, subject to applicable notice/pay-in-lieu requirements and applicable law. Where the circumstances constitute misconduct or another matter warranting disciplinary action, HHC may take appropriate action in accordance with applicable law and its disciplinary process.</p>
<div class="gap" style="height:13.5pt"></div>
<h2 style="margin-top:4.0pt;margin-bottom:2.0pt">3. POSITION, DUTIES AND REPORTING</h2>
<p class="j" style="margin-bottom:3.0pt">You shall perform the duties and responsibilities assigned to you from time to time, including duties reasonably incidental to your position. You are expected to devote your professional time, attention and skills to HHC and to perform your responsibilities diligently, ethically and in accordance with lawful instructions.</p>
<p class="j" style="margin-bottom:3.0pt">Your designation, reporting relationship, responsibilities and place of work may be modified by HHC from time to time in accordance with business requirements, your role and applicable law.</p>
<p style="margin-bottom:10pt"><b>4. LOCATION, TRANSFER AND DEPLOYMENT</b></p>
<p class="j" style="margin-bottom:3.0pt">Your initial place of work will be <b>{{location}}</b>. HHC may, based on business requirements, operational needs, patient-care requirements, organisational restructuring or other legitimate business reasons, transfer, deploy or assign you to another HHC branch, clinic, unit, department, function or location, subject to your role and applicable law.</p>
<div class="gap" style="height:13.5pt"></div>
<h2 style="margin-top:4.0pt;margin-bottom:2.0pt">5. WORKING HOURS AND BUSINESS REQUIREMENTS</h2>
<p class="j" style="margin-bottom:3.0pt">You will work according to the duty schedule, roster and working hours applicable to your role and location, as determined by HHC from time to time in accordance with applicable law and Company policy. Depending on the nature of your role and business requirements, you may be required to work shifts, weekends, holidays or additional hours where lawfully permissible. Overtime, compensatory off or other applicable arrangements will be governed by applicable law and HHC policy.</p>
<div class="gap" style="height:13.5pt"></div>
<h2 style="margin-top:4.0pt;margin-bottom:2.0pt">6. COMPENSATION</h2>
<p class="j" style="margin-bottom:3.0pt">Your total annual <b>Cost to Company (“CTC”)</b> will be <b>₹ {{ctc_annual}},</b> inclusive of employer statutory contributions.</p>
<p class="j" style="margin-bottom:3.0pt">Your compensation will be subject to applicable statutory deductions, taxes, contributions and Company policies. Any variable pay, incentive, bonus, reimbursement or performance-linked component will be governed by the applicable scheme/policy and will not constitute a guaranteed or vested entitlement unless expressly stated otherwise in writing.</p>
<p class="j" style="margin-bottom:3.0pt">Any future revision to compensation or compensation structure will be determined by HHC based on applicable policy, individual performance, organisational performance, business requirements and applicable law.</p>
<div class="gap" style="height:13.5pt"></div>
<h2 style="margin-top:4.0pt;margin-bottom:2.0pt">{{sec_7}}. BENEFITS AND STATUTORY ENTITLEMENTS</h2>
<p class="j" style="margin-bottom:3.0pt">You will be eligible for leave, statutory benefits and other employee benefits applicable to your role and category, in accordance with HHC’s policies as amended from time to time and applicable law. Eligibility for any benefit will be subject to the conditions of the relevant policy and applicable statutory requirements.</p>
<div class="gap" style="height:13.5pt"></div>
<h2 style="margin-top:4.0pt;margin-bottom:2.0pt">{{sec_8}}. BACKGROUND VERIFICATION AND REFERENCES</h2>
<p class="j" style="margin-bottom:3.0pt">HHC may conduct, directly or through authorised service providers, background and reference verification relating to your identity, address, education, qualifications, professional registrations, employment history, experience, references and other information relevant to your employment, subject to applicable law.</p>
<p class="j" style="margin-bottom:3.0pt">You authorise HHC to verify information provided by you and to contact relevant institutions, employers, references or verification agencies for legitimate employment-related purposes. You must cooperate fully and provide information reasonably required for such verification.</p>
<p class="j" style="margin-bottom:3.0pt">If any material discrepancy, falsification, concealment, misrepresentation or adverse information relevant to your employment is identified, HHC may withdraw this offer before joining or take appropriate action after joining, including disciplinary action or termination, subject to applicable law and due process.</p>
<div class="gap" style="height:13.5pt"></div>
<h2 style="margin-top:4.0pt;margin-bottom:2.0pt">{{sec_9}}. DOCUMENTS AND CANDIDATE DECLARATIONS</h2>
<p style="margin-bottom:3.0pt">You are required to submit the documents listed in Annexure {{docs_annexure}} and any additional documents reasonably required for statutory, payroll, compliance, credentialing or role-specific purposes.</p>
<p style="margin-bottom:3.0pt">By accepting this offer, you confirm that:</p>
<ul>
<li style="margin-bottom:1.0pt">all information provided by you during recruitment is true, accurate, complete and not misleading;</li>
<li style="margin-bottom:1.0pt">all certificates, licences, registrations, experience documents and other credentials submitted by you are genuine and valid, to the best of your knowledge;</li>
<li style="margin-bottom:1.0pt">you have disclosed material facts that may reasonably affect your eligibility or ability to perform the role;</li>
<li style="margin-bottom:1.0pt">you are not subject to any undisclosed restriction that prevents you from accepting or performing the offered role; and</li>
<li style="margin-bottom:1.0pt">you will promptly notify HHC if any material information provided by you changes before joining.</li>
</ul>
<div class="gap" style="height:13.9pt"></div>
<p style="margin-bottom:3.0pt">Any materially false statement, concealment, fabrication or misrepresentation may result in withdrawal of the offer or, after commencement of employment, appropriate disciplinary action, including termination, subject to applicable law.</p>
<div class="gap" style="height:13.5pt"></div>
<h2 style="margin-top:4.0pt;margin-bottom:2.0pt">{{sec_10}}. COMPANY POLICIES AND CODE OF CONDUCT</h2>
<p class="j" style="margin-bottom:3.0pt">Upon joining, you will be required to comply with HHC’s Code of Conduct, HR policies, clinical and operational protocols applicable to your role, information-security requirements, patient-safety requirements, anti-harassment and anti-discrimination requirements, POSH framework, attendance and leave rules, and other policies, SOPs, circulars and instructions issued by HHC from time to time.</p>
<p class="j" style="margin-bottom:3.0pt">HHC may introduce, amend, replace or withdraw policies and procedures from time to time to reflect business requirements, legal requirements or organisational changes. Such policies will apply to you to the extent applicable to your role and subject to applicable law.</p>
<p class="j" style="margin-bottom:3.0pt">Violation of applicable policies, lawful instructions or the Code of Conduct may result in corrective or disciplinary action in accordance with HHC’s applicable process and law.</p>
<div class="gap" style="height:13.5pt"></div>
<h2 style="margin-top:4.0pt;margin-bottom:2.0pt">{{sec_11}}. CONFIDENTIALITY AND NON-DISCLOSURE</h2>
<p class="j" style="margin-bottom:3.0pt">During and after your employment, you shall maintain strict confidentiality regarding all confidential or proprietary information of HHC and its group entities, branches, franchisees, patients, employees, doctors, vendors and business partners that comes to your knowledge through your association with HHC.</p>
<p class="j" style="margin-bottom:3.0pt">Confidential information includes, without limitation, patient and employee information, medical or clinical information, personal data, salary and compensation information, business plans, financial information, pricing, vendor information, franchisee information, contracts, recruitment information, databases, passwords, access credentials, systems, processes, SOPs, reports, training material, trade secrets and other non-public information.</p>
<p class="j" style="margin-bottom:3.0pt">You shall use such information only for authorised HHC purposes and shall not copy, disclose, publish, transmit, remove, misuse or permit unauthorised access to such information, except where required by law or expressly authorised by HHC.</p>
<p class="j" style="margin-bottom:3.0pt">These obligations shall survive cessation of employment for so long as the information remains confidential or protected by law.</p>
<div class="gap" style="height:13.5pt"></div>
<h2 style="margin-top:4.0pt;margin-bottom:2.0pt">{{sec_12}}. DATA PROTECTION AND INFORMATION SECURITY</h2>
<p class="j" style="margin-bottom:3.0pt">You acknowledge that HHC may collect, use, store, process and share personal information relating to you for legitimate employment, payroll, statutory, compliance, security, benefits, verification and administrative purposes, in accordance with applicable law and HHC’s privacy and information-security practices.</p>
<p class="j" style="margin-bottom:3.0pt">You shall comply with HHC’s information-security requirements and shall protect all credentials, devices, records, systems and data entrusted to you. Any suspected loss, unauthorised access, disclosure or data-security incident must be reported immediately to HHC through the prescribed channel.</p>
<div class="gap" style="height:13.5pt"></div>
<h2 style="margin-top:4.0pt;margin-bottom:2.0pt">{{sec_13}}. INTELLECTUAL PROPERTY AND WORK PRODUCT</h2>
<p class="j" style="margin-bottom:3.0pt">All documents, reports, presentations, training material, policies, processes, templates, designs, databases, content, analyses, inventions, improvements, systems, software configurations and other work product created, developed or contributed to by you in the course of your employment or using HHC resources or confidential information shall belong to HHC to the extent permitted by applicable law.</p>
<p class="j" style="margin-bottom:3.0pt">You agree to execute such further documents and provide such assistance as may reasonably be required to record, protect or enforce HHC’s rights in such work product. You shall not use or reproduce HHC’s proprietary material for unauthorised personal or external purposes.</p>
<div class="gap" style="height:13.5pt"></div>
<h2 style="margin-top:4.0pt;margin-bottom:2.0pt">{{sec_14}}. CONFLICT OF INTEREST AND OUTSIDE ACTIVITIES</h2>
<p class="j" style="margin-bottom:3.0pt">You shall avoid any actual, potential or perceived conflict between your personal interests and the interests of HHC. You must promptly disclose to HHC any material conflict of interest or circumstance that may reasonably affect your objectivity, duties or ability to perform your role.</p>
<p class="j" style="margin-bottom:3.0pt">During your employment, you shall not undertake any other employment, consultancy, professional engagement, business activity, directorship, partnership or similar activity that conflicts with HHC’s interests, interferes with your duties or is otherwise prohibited by HHC policy, without prior written approval from HHC.</p>
<p class="j" style="margin-bottom:3.0pt">You shall not misuse HHC information, relationships, resources or position for personal benefit or for the benefit of any third party.</p>
<div class="gap" style="height:13.5pt"></div>
<h2 style="margin-top:4.0pt;margin-bottom:2.0pt">{{sec_15}}. PATIENT, EMPLOYEE AND BUSINESS INFORMATION</h2>
<p class="j" style="margin-bottom:3.0pt">Where your role provides access to patient, employee, doctor, vendor, franchisee or other sensitive information, you shall access and use such information strictly on a need-to-know and authorised basis. You shall not access records merely because access is technically available to you.</p>
<p class="j" style="margin-bottom:3.0pt">Any unauthorised access, extraction, sharing, alteration, copying or use of such information may constitute a serious breach of Company policy and may result in disciplinary and/or legal action, subject to applicable law.</p>
<div class="gap" style="height:13.5pt"></div>
<h2 style="margin-top:4.0pt;margin-bottom:2.0pt">{{sec_16}}. COMPANY PROPERTY, SYSTEMS AND ACCESS</h2>
<p class="j" style="margin-bottom:3.0pt">All laptops, phones, ID cards, access cards, keys, documents, files, records, equipment, software, credentials, data and other property provided by HHC remain the property of HHC unless expressly stated otherwise.</p>
<p class="j" style="margin-bottom:3.0pt">You shall use Company property only for authorised purposes, protect it from loss or misuse and return it immediately upon request or cessation of employment. HHC may restrict or withdraw access to its systems, premises, records and information whenever reasonably required for security, business continuity, investigation or other legitimate purposes.</p>
<div class="gap" style="height:13.5pt"></div>
<h2 style="margin-top:4.0pt;margin-bottom:2.0pt">{{sec_17}}. NOTICE PERIOD AND SEPARATION</h2>
<p class="j" style="margin-bottom:3.0pt">Upon commencement of employment, separation from service shall be governed by the notice-period provisions applicable to your role and HHC policy, as amended from time to time, subject to applicable law. Where permitted, HHC may accept payment in lieu of notice, waive or reduce notice, or release an employee earlier, subject to applicable law and Company policy.</p>
<p class="j" style="margin-bottom:3.0pt">During any notice period, you shall continue to perform your duties, complete handover, return Company property, protect confidential information and cooperate with transition requirements. HHC may, where lawfully permissible and in accordance with policy, relieve you from active duties, restrict access to systems or premises, or place you on garden leave while continuing applicable pay and benefits.</p>
<p class="j" style="margin-bottom:3.0pt">Nothing in this clause limits HHC’s rights in cases of misconduct, fraud, material breach, abandonment of employment or other circumstances where applicable law permits a different course of action.</p>
<div class="gap" style="height:13.5pt"></div>
<h2 style="margin-top:4.0pt;margin-bottom:2.0pt">{{sec_18}}. DISCIPLINARY ACTION</h2>
<p class="j" style="margin-bottom:3.0pt">HHC may take appropriate corrective or disciplinary action in response to misconduct, fraud, dishonesty, material misrepresentation, breach of confidentiality, violation of policy, insubordination, conflict of interest, unauthorised absence, misuse of Company property or systems, serious negligence, or other violation of applicable employment obligations.</p>
<p class="j" style="margin-bottom:3.0pt">Any disciplinary action will be taken in accordance with applicable law, the nature of the matter and HHC’s applicable disciplinary process. Depending on the circumstances, action may include counselling, warning, suspension, recovery where lawfully permissible, or termination of employment.</p>
<div class="gap" style="height:13.5pt"></div>
<div class="gap" style="height:13.5pt"></div>
<h2 style="margin-top:4.0pt;margin-bottom:2.0pt">{{sec_19}}. OFFER WITHDRAWAL, LAPSE AND NON-JOINING</h2>
<p class="j" style="margin-bottom:3.0pt">This offer is personal to you and is not transferable. It will remain valid until the date specified by HHC and will lapse if not accepted within the prescribed period or if you do not join on the agreed date without written approval from HHC.</p>
<p class="j" style="margin-bottom:3.0pt">HHC may withdraw this offer before joining if any condition of the offer is not satisfied, if verification is unsatisfactory, if material information is found to be false or misleading, if required documents are not provided, if the candidate is unable to satisfy a lawful role requirement, or if business circumstances require HHC to discontinue the recruitment process. Such withdrawal will be subject to applicable law.</p>
<div class="gap" style="height:13.5pt"></div>
<h2 style="margin-top:4.0pt;margin-bottom:2.0pt">{{sec_20}}. NO ASSURANCE OF FUTURE EMPLOYMENT TERMS</h2>
<p class="j" style="margin-bottom:3.0pt">This offer is based on the position and compensation stated herein. Any discussion during recruitment regarding future promotion, increments, designation changes, transfers, variable pay, benefits or career progression is indicative only unless expressly confirmed in writing by an authorised representative of HHC.</p>
<p class="j" style="margin-bottom:3.0pt">No verbal representation or assurance shall modify this Offer Letter unless confirmed in writing by an authorised representative of HHC.</p>
<div class="gap" style="height:13.5pt"></div>
<h2 style="margin-top:4.0pt;margin-bottom:2.0pt">{{sec_21}}. STATUTORY AND LEGAL COMPLIANCE</h2>
<p class="j" style="margin-bottom:3.0pt">Nothing in this Offer Letter is intended to exclude, waive or contract out of any mandatory right or obligation under applicable law. If any provision of this Offer Letter conflicts with a mandatory statutory requirement, the mandatory legal requirement will prevail to the extent of the conflict, and the remaining provisions will continue to apply.</p>
<div class="gap" style="height:13.5pt"></div>
<h2 style="margin-top:4.0pt;margin-bottom:2.0pt">{{sec_22}}. GOVERNING LAW, JURISDICTION AND DISPUTE RESOLUTION</h2>
<p class="j" style="margin-bottom:3.0pt">This Offer Letter shall be governed by the laws applicable in India. Subject to any mandatory statutory forum, authority, conciliation or dispute-resolution mechanism applicable to the employment relationship, disputes arising out of or relating to this Offer Letter shall be subject to the jurisdiction of the competent courts/authorities at Pune, Maharashtra.</p>
<div class="gap" style="height:13.5pt"></div>
<h2 style="margin-top:4.0pt;margin-bottom:2.0pt">{{sec_23}}. SEVERABILITY</h2>
<p class="j" style="margin-bottom:3.0pt">If any provision of this Offer Letter is held to be invalid, unlawful or unenforceable, that provision shall be modified or limited to the minimum extent necessary to make it lawful and enforceable, and the remaining provisions shall continue in full force to the extent permitted by law.</p>
<div class="gap" style="height:13.5pt"></div>
<h2 style="margin-top:4.0pt;margin-bottom:2.0pt">{{sec_24}}. ENTIRE UNDERSTANDING</h2>
<p class="j" style="margin-bottom:3.0pt">This Offer Letter together with its annexures and the HHC policies applicable to your employment constitutes the written understanding regarding the offer described herein and supersedes prior written or oral communications concerning the same subject matter, to the extent legally permissible.</p>
<p class="j" style="margin-bottom:3.0pt">Any amendment to the material terms of this Offer Letter must be made in writing by an authorised representative of HHC.</p>
<div class="gap" style="height:13.5pt"></div>
<div class="gap" style="height:13.5pt"></div>
<div class="gap" style="height:13.5pt"></div>
<h2 style="margin-top:4.0pt;margin-bottom:2.0pt">{{sec_25}}. ACCEPTANCE</h2>
<p class="j" style="margin-bottom:3.0pt">If the above terms and conditions are acceptable to you, please sign and return a copy of this Offer Letter as confirmation of your acceptance. Your acceptance confirms that you have read, understood and agreed to the terms stated herein and that the information and documents provided by you during the recruitment process are true and complete.</p>
<p class="j" style="margin-bottom:3.0pt">We look forward to welcoming you to Healing Hands Clinic and to a successful professional association.</p>
<div class="gap" style="height:22.9pt"></div>
<div class="keep">
<p style="margin-bottom:12.0pt"><b>For Healing Hands Clinic Private Limited</b></p>
{{#if signature_html}}{{signature_html}}{{/if}}{{#unless signature_html}}<div class="gap" style="height:13.9pt"></div>
<div class="gap" style="height:13.9pt"></div>
<div class="gap" style="height:13.9pt"></div>
{{/unless}}
<p style="margin-bottom:3.0pt"><b>{{hr_signatory_name}}</b></p>
<p style="margin-bottom:12.0pt"><b>{{hr_signatory_designation}}</b></p>
</div>
<div class="gap" style="height:15.9pt"></div>
<div class="gap" style="height:15.9pt"></div>
<div class="gap" style="height:15.9pt"></div>
<div class="gap" style="height:15.9pt"></div>
<div class="gap" style="height:15.9pt"></div>
<div class="gap" style="height:15.9pt"></div>
<div class="gap" style="height:15.9pt"></div>
<div class="keep">
<p class="c" style="margin-bottom:5.0pt"><b>CANDIDATE ACCEPTANCE</b></p>
<p class="j" style="margin-bottom:3.0pt">I, <b>{{candidate_name}},</b> acknowledge that I have read and understood this Offer Letter and its annexures. I accept the offer on the terms and conditions stated herein and confirm that the information and documents submitted by me are true, accurate and complete to the best of my knowledge.</p>
<p class="j" style="margin-bottom:3.0pt">I understand that this offer is conditional upon satisfaction of the conditions stated in this Offer Letter and that commencement of employment and confirmation are subject to the applicable terms, policies and law.</p>
<div class="gap" style="height:13.9pt"></div>
<div class="gap" style="height:13.9pt"></div>
<p style="margin-bottom:3.0pt">Signature: ___________________________&nbsp;&nbsp;&nbsp;&nbsp;Date: ______________</p>
</div>
<p class="c pb" style="margin-bottom:4.0pt"><b>ANNEXURE {{docs_annexure}} – DOCUMENTS REQUIRED ON JOINING</b></p>
<ul>
<li style="margin-bottom:1.0pt">PAN card and Aadhaar card / other legally acceptable identity document</li>
<li style="margin-bottom:1.0pt">3 passport photographs</li>
<li style="margin-bottom:1.0pt">Address and date-of-birth proof, where required or where different from the identity document</li>
<li style="margin-bottom:1.0pt">All education and additional qualification certificates</li>
<li style="margin-bottom:1.0pt">Professional registration/licence/certification, where applicable to the role</li>
<li style="margin-bottom:1.0pt">Bank details (cancelled cheque/passbook/bank account proof)</li>
<li style="margin-bottom:1.0pt">Last 3 months’ salary slips and/or bank statement, where applicable</li>
<li style="margin-bottom:1.0pt">Relieving letter / acceptance of resignation / experience certificate from previous employer, where applicable</li>
<li style="margin-bottom:1.0pt">Any other document reasonably required for statutory, payroll, background-verification, credentialing or role-specific purposes</li>
</ul>
<div class="gap" style="height:15.9pt"></div>
<p style="margin-bottom:5.0pt">The offer is subject to satisfactory verification of credentials and the authenticity of all documents submitted, as well as timely submission of required records. Any material discrepancy, misrepresentation, concealment, falsification or failure to provide required documentation may result in withdrawal of the offer or, after commencement of employment, appropriate action in accordance with applicable law and Company policy.</p>
<div class="gap" style="height:15.9pt"></div>
<div class="gap" style="height:15.9pt"></div>
<div class="keep">
<p style="margin-bottom:5.0pt"><b>For Healing Hands Clinic Private Limited</b></p>
{{#if signature_html}}{{signature_html}}{{/if}}{{#unless signature_html}}<div class="gap" style="height:13.9pt"></div>
<div class="gap" style="height:13.9pt"></div>
<div class="gap" style="height:13.9pt"></div>
{{/unless}}
<p style="margin-bottom:3.0pt"><b>{{hr_signatory_name}}</b></p>
<p style="margin-bottom:3.0pt"><b>{{hr_signatory_designation}}</b></p>
</div>
<img class="lh-screen lh-foot" src="{{letterhead2_footer_src}}" alt="">
</div>
'
 WHERE template_type = 'OFFER_LETTER' AND is_active = 1;

UPDATE rec_letter_templates
   SET body_html = '<!-- Appointment Letter (Healing Hands Clinic) - edit wording here; values in double curly braces are filled by the system. HHC letterhead header/footer are added on every PDF page. -->
<style>
@page { size: Letter; margin: 1.7in 0.7in 1.75in 0.7in; }
.letter { font-family: Arial, ''Liberation Sans'', Helvetica, sans-serif; font-size: 9pt; line-height: 1.18; color: #000; }
.letter p, .letter h1, .letter h2, .letter ul { margin-top: 0; }
.letter h1 { font-size: 15pt; font-weight: bold; text-align: center; margin-bottom: 6pt; line-height: 1.15; }
.letter h2 { font-size: 9.5pt; font-weight: bold; }
.letter .j { text-align: justify; }
.letter .c { text-align: center; }
.letter ul { margin-bottom: 0; padding-left: 0.42in; }
.letter li { padding-left: 2pt; }
.letter .pb { page-break-before: always; break-before: page; }
.letter table.annex { width: 100%; border-collapse: collapse; margin: 4pt 0 8pt; font-size: 9pt; }
.letter table.annex th, .letter table.annex td { border: 0.75pt solid #000; padding: 3pt 6pt; }
.letter table.annex th { background: #f2f2f2; text-align: left; }
.letter table.annex .r { text-align: right; }
.letter table.annex tr.grp td { font-weight: bold; background: #fafafa; }
.letter table.annex tr.tot td { font-weight: bold; }
.letter h2 { page-break-after: avoid; break-after: avoid; }
.letter, .letter * { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
.letter .lh-screen { display: none; }
.letter .keep { page-break-inside: avoid; break-inside: avoid; }
@media print { .letter .pb { padding-top: 16pt; } }
@media screen {
  body { background: #e9eef2; margin: 0; padding: 16px 0; }
  .letter { background: #fff; width: 8.5in; max-width: 100%; box-sizing: border-box; padding: 0 0.7in 0.2in; margin: 0 auto; box-shadow: 0 2px 12px rgba(0,0,0,.12); }
  .letter .lh-screen { display: block; width: calc(100% + 2 * 0.7in); margin: 0 -0.7in 12pt; }
  .letter .lh-screen.lh-foot { margin: 24pt -0.7in -0.2in; }
  .letter .pb { border-top: 1px dashed #b8c4cc; margin-top: 28pt; padding-top: 28pt; }
}
</style>
<div class="letter" data-letterhead="hhc">
<img class="lh-screen" src="{{letterhead_header_src}}" alt="">
<h1>APPOINTMENT LETTER</h1>
<p style="margin-bottom:2.0pt">Ref: HHC/HR/{{employee_code}}</p>
<p style="margin-bottom:3.0pt">Date: {{letter_date}}</p>
<div class="gap" style="height:12.3pt"></div>
<p style="margin-bottom:2.0pt">To,</p>
<p style="margin-bottom:3.0pt">{{candidate_name}}<br>{{designation}}<br>{{location}}</p>
<div class="gap" style="height:13.3pt"></div>
<p style="margin-bottom:3.0pt"><b>Subject: Appointment as {{designation}}</b></p>
<div class="gap" style="height:13.3pt"></div>
<p style="margin-bottom:3.0pt">Dear {{salutation}} {{last_name}},</p>
<div class="gap" style="height:12.3pt"></div>
<p class="j" style="margin-bottom:2.0pt">We are pleased to confirm your appointment as <b>{{designation}} </b>with Healing Hands Clinic Private Limited (“HHCPL” or the “Company”), effective <b>{{date_of_joining}}</b>, pursuant to your having joined the services of the Company on the said date.</p>
<p class="j" style="margin-bottom:2.0pt">This Appointment Letter sets out the principal terms and conditions governing your employment with HHCPL and, together with the applicable Company policies and Annexure A, constitutes the employment framework applicable to you. It supersedes prior communications concerning the appointment to the extent of any inconsistency, subject always to applicable law.</p>
<div class="gap" style="height:11.9pt"></div>
<h2 style="margin-top:3.0pt;margin-bottom:1.0pt">1. ROLE, REPORTING AND DUTIES</h2>
<div class="gap" style="height:2.1pt"></div>
<p style="margin-bottom:2.0pt">1.1 You are appointed as <b>{{designation}}</b> within the <b>{{department}}.</b></p>
<p style="margin-bottom:2.0pt">1.2 You will report to <b>{{reporting_manager}}</b> or to such other person as HHCPL may designate from time to time.</p>
<p style="margin-bottom:2.0pt">1.3 Your duties, responsibilities, authority and scope of work shall be aligned to your role and may reasonably evolve in accordance with organisational requirements, business needs, restructuring, technology, patient-care requirements, regulatory requirements or other legitimate business considerations.</p>
<p style="margin-bottom:2.0pt">1.4 You shall perform your duties diligently, honestly, professionally and in accordance with lawful and reasonable instructions, and devote your working time and professional attention to HHCPL.</p>
<div class="gap" style="height:11.9pt"></div>
<h2 style="margin-top:3.0pt;margin-bottom:1.0pt">2. PLACE OF POSTING, TRANSFER AND DEPLOYMENT</h2>
<div class="gap" style="height:2.1pt"></div>
<p class="j" style="margin-bottom:2.0pt">2.1 Your initial place of posting shall be <b>{{location}}.</b></p>
<p class="j" style="margin-bottom:2.0pt">2.2 HHCPL may, based on legitimate business and operational requirements, transfer, deploy, rotate or assign you to another HHCPL clinic, office, unit, department, function or worksite in India, subject to your role and applicable law.</p>
<p class="j" style="margin-bottom:2.0pt">2.3 Any assignment involving a separate legal entity shall be subject to appropriate legal/contractual documentation and shall not automatically transfer your employment to that entity.</p>
<div class="gap" style="height:11.9pt"></div>
<h2 style="margin-top:3.0pt;margin-bottom:1.0pt">3. EMPLOYMENT STATUS</h2>
<div class="gap" style="height:2.1pt"></div>
<p style="margin-bottom:2.0pt">3.1 Your employment is full-time and continuous, subject to applicable law and this Letter.</p>
<p style="margin-bottom:2.0pt">3.2 Your employment is personal to you and may not be assigned or subcontracted.</p>
<div class="gap" style="height:11.9pt"></div>
<h2 style="margin-top:3.0pt;margin-bottom:1.0pt">4. PROBATION AND CONFIRMATION</h2>
<div class="gap" style="height:3.1pt"></div>
<p style="margin-bottom:2.0pt">4.1 Unless otherwise stated in writing, your initial employment shall be probationary for <b>{{probation_period}}</b> from the Date of Joining.</p>
<p style="margin-bottom:2.0pt">4.2 During probation HHCPL will assess performance, conduct, attendance, capability, suitability, role alignment and adherence to Company standards.</p>
<p style="margin-bottom:2.0pt">4.3 Completion of probation does not by itself constitute confirmation. Confirmation shall take effect only upon written confirmation issued by HHCPL.</p>
<p style="margin-bottom:2.0pt">4.4 HHCPL may extend probation where additional assessment is reasonably required, subject to applicable law.</p>
<p style="margin-bottom:2.0pt">4.5 During probation, HHCPL may discontinue employment for unsatisfactory performance, lack of role suitability, misconduct, breach of policy, failure to meet role requirements or other lawful grounds, subject to applicable notice/pay-in-lieu requirements and law.</p>
<div class="gap" style="height:11.9pt"></div>
<h2 style="margin-top:3.0pt;margin-bottom:1.0pt">5. COMPENSATION AND BENEFITS</h2>
<div class="gap" style="height:4.3pt"></div>
<p class="j" style="margin-bottom:2.0pt">5.1 Your compensation structure is detailed in <b>Annexure A</b>.</p>
<p class="j" style="margin-bottom:2.0pt">5.2 Salary and other payments are subject to statutory deductions, taxes, contributions and lawful recoveries.</p>
<p class="j" style="margin-bottom:2.0pt">5.3 Benefits, reimbursements and statutory contributions shall be governed by HHCPL policy and applicable law.</p>
<p class="j" style="margin-bottom:2.0pt">5.4 Variable pay, incentives, bonuses and performance-linked payments, where applicable, are governed by the relevant scheme/policy and are not guaranteed except where expressly provided or legally required.</p>
<p class="j" style="margin-bottom:2.0pt">5.5 Compensation information shall be treated as confidential, except where disclosure is required or protected by law.</p>
<div class="gap" style="height:11.9pt"></div>
<h2 style="margin-top:3.0pt;margin-bottom:1.0pt">6. WORKING HOURS, ATTENDANCE, WEEKLY OFF AND LEAVE</h2>
<div class="gap" style="height:3.1pt"></div>
<p class="j" style="margin-bottom:2.0pt">6.1 Working hours, shifts, roster, weekly off, attendance and leave shall be governed by applicable HHCPL policies and law.</p>
<p class="j" style="margin-bottom:2.0pt">6.2 You may be required to work shifts, weekends, holidays or additional hours where lawfully permissible. Overtime/compensatory arrangements shall follow applicable law and policy.</p>
<p class="j" style="margin-bottom:2.0pt">6.3 You must accurately record attendance and comply with HRIS, biometric and roster processes.</p>
<p class="j" style="margin-bottom:2.0pt">6.4 Unauthorised absence may attract disciplinary action under applicable policy and law.</p>
<div class="gap" style="height:11.9pt"></div>
<h2 style="margin-top:3.0pt;margin-bottom:1.0pt">7. CONFIDENTIALITY AND NON-DISCLOSURE</h2>
<div class="gap" style="height:4.3pt"></div>
<p class="j" style="margin-bottom:2.0pt">7.1 During and after employment, you shall maintain strict confidentiality of confidential, proprietary or non-public information relating to HHCPL, its patients, employees, doctors, vendors, franchisees/business partners and operations.</p>
<p class="j" style="margin-bottom:2.0pt">7.2 Confidential information includes patient/clinical information, personal data, employee information, compensation data, medical records, financial information, business plans, pricing, contracts, vendor/franchisee information, recruitment data, databases, credentials, systems, processes, SOPs, reports, training material, intellectual property and trade secrets.</p>
<p class="j" style="margin-bottom:2.0pt">7.3 You shall use such information only for authorised Company purposes and shall not copy, disclose, publish, transmit, remove, misuse or permit unauthorised access.</p>
<p class="j" style="margin-bottom:2.0pt">7.4 These obligations survive separation for so long as the information remains confidential or protected by law.</p>
<p class="j" style="margin-bottom:2.0pt">7.5 Nothing prevents disclosure required or protected by law.</p>
<div class="gap" style="height:11.9pt"></div>
<h2 style="margin-top:3.0pt;margin-bottom:1.0pt">8. DATA PROTECTION AND INFORMATION SECURITY</h2>
<div class="gap" style="height:3.1pt"></div>
<p class="j" style="margin-bottom:2.0pt">8.1 You shall comply with applicable privacy, data-protection, cyber-security and information-security laws and HHCPL policies.</p>
<p class="j" style="margin-bottom:2.0pt">8.2 HHCPL may collect, use, store, process and share your personal information for legitimate employment, payroll, benefits, statutory, compliance, verification, security and administrative purposes in accordance with law.</p>
<p class="j" style="margin-bottom:2.0pt">8.3 Access to patient, employee, clinical, financial and other sensitive information shall be strictly authorised and need-to-know.</p>
<p class="j" style="margin-bottom:2.0pt">8.4 You shall safeguard Company devices, passwords and information and immediately report suspected loss, unauthorised access, disclosure or data breach.</p>
<div class="gap" style="height:11.9pt"></div>
<h2 style="margin-top:3.0pt;margin-bottom:1.0pt">9. INTELLECTUAL PROPERTY AND WORK PRODUCT</h2>
<div class="gap" style="height:3.1pt"></div>
<p class="j" style="margin-bottom:2.0pt">9.1 To the extent permitted by law, work product, documents, reports, presentations, training material, policies, processes, templates, designs, databases, content, analyses, inventions, improvements, systems, software configurations and other material created/developed in the course of employment or using HHCPL resources/confidential information shall belong to HHCPL.</p>
<p class="j" style="margin-bottom:2.0pt">9.2 You shall execute reasonable documents required to record or protect HHCPL’s rights in such work product.</p>
<p class="j" style="margin-bottom:2.0pt">9.3 You shall not use or commercialise HHCPL proprietary material for unauthorised purposes.</p>
<div class="gap" style="height:11.9pt"></div>
<h2 style="margin-top:3.0pt;margin-bottom:1.0pt">10. CODE OF CONDUCT AND COMPANY POLICIES</h2>
<div class="gap" style="height:4.3pt"></div>
<p class="j" style="margin-bottom:2.0pt">10.1 You shall comply with all applicable HHCPL policies, SOPs, circulars, codes and lawful instructions, including:</p>
<ul>
<li style="margin-bottom:0.0pt">Code of Conduct</li>
<li style="margin-bottom:0.0pt">POSH and workplace-dignity requirements</li>
<li style="margin-bottom:0.0pt">Conflict of Interest and Outside Engagement Policy</li>
<li style="margin-bottom:0.0pt">IT, Information Security and Data Protection policies</li>
<li style="margin-bottom:0.0pt">Attendance, Leave and Working Hours policies</li>
<li style="margin-bottom:0.0pt">Patient-safety, clinical and operational protocols applicable to your role</li>
<li style="margin-bottom:0.0pt">Grievance and disciplinary policies</li>
</ul>
<div class="gap" style="height:12.3pt"></div>
<p class="j pb" style="margin-bottom:2.0pt">10.2 HHCPL may introduce, amend, replace or withdraw operational, procedural and administrative policies from time to time, subject to applicable law.</p>
<div class="gap" style="height:11.9pt"></div>
<h2 style="margin-top:3.0pt;margin-bottom:1.0pt">11. CONFLICT OF INTEREST AND OUTSIDE ENGAGEMENT</h2>
<div class="gap" style="height:4.3pt"></div>
<p class="j" style="margin-bottom:2.0pt">11.1 You shall avoid actual, potential or perceived conflicts and promptly disclose material conflicts.</p>
<p class="j" style="margin-bottom:2.0pt">11.2 During employment, you shall not undertake other employment, consultancy, professional engagement, business activity, directorship, partnership or similar engagement that conflicts with HHCPL’s interests, interferes with your duties or is prohibited by policy, without prior written approval.</p>
<p class="j" style="margin-bottom:2.0pt">11.3 You shall not use HHCPL information, relationships, resources or position for unauthorised personal or third-party benefit.</p>
<div class="gap" style="height:11.9pt"></div>
<h2 style="margin-top:3.0pt;margin-bottom:1.0pt">12. PROFESSIONAL LICENCES, REGISTRATIONS AND CREDENTIALS</h2>
<div class="gap" style="height:4.3pt"></div>
<p class="j" style="margin-bottom:2.0pt">Where your role requires a licence, registration, certification or statutory credential, you shall maintain it in valid status and immediately disclose suspension, expiry, restriction or cancellation. You shall not undertake duties for which a mandatory credential is required unless the requirement is satisfied. </p>
<div class="gap" style="height:11.9pt"></div>
<h2 style="margin-top:3.0pt;margin-bottom:1.0pt">13. NOTICE PERIOD AND TERMINATION</h2>
<div class="gap" style="height:3.1pt"></div>
<p class="j" style="margin-bottom:2.0pt">13.1 Either party may terminate employment by the applicable written notice prescribed for the employee’s category under HHCPL policy/terms in force from time to time, subject to applicable law.</p>
<p class="j" style="margin-bottom:2.0pt">13.2 During probation, the applicable notice period shall be 30 days unless a different period is expressly stated in writing for the role, subject to law.</p>
<p class="j" style="margin-bottom:2.0pt">13.3 After confirmation, the applicable notice period shall be the period specified in the employee’s applicable HHCPL terms/policy, subject to law.</p>
<p class="j" style="margin-bottom:2.0pt">13.4 Where permitted by law and policy, HHCPL may waive/reduce notice, accept payment in lieu, or release an employee earlier, confirmed in writing.</p>
<p class="j" style="margin-bottom:2.0pt">13.5 During notice you shall continue duties, complete handover and return Company property unless otherwise directed.</p>
<p class="j" style="margin-bottom:2.0pt">13.6 Where lawfully permissible, HHCPL may relieve you from active duties, restrict access or place you on garden leave during notice while continuing applicable pay/benefits.</p>
<p class="j" style="margin-bottom:2.0pt">13.7 Nothing limits HHCPL’s right to take lawful disciplinary action for misconduct, fraud, material breach, unauthorised absence or other grounds warranting termination.</p>
<div class="gap" style="height:11.9pt"></div>
<h2 style="margin-top:3.0pt;margin-bottom:1.0pt">14. DISCIPLINARY ACTION</h2>
<div class="gap" style="height:3.1pt"></div>
<p class="j" style="margin-bottom:2.0pt">14.1 HHCPL may take corrective/disciplinary action for misconduct, fraud, dishonesty, material misrepresentation, confidentiality breach, unauthorised access/disclosure, serious negligence, wilful disobedience, insubordination, conflict of interest, unauthorised absence, misuse of Company property/systems or policy breach.</p>
<p class="j" style="margin-bottom:2.0pt">14.2 Measures may include counselling, warning, suspension, lawful recovery or termination, as applicable.</p>
<p class="j" style="margin-bottom:2.0pt">14.3 Where misconduct proceedings are required, HHCPL shall follow applicable law, standing orders where applicable, Company process and principles of natural justice.</p>
<div class="gap" style="height:11.9pt"></div>
<h2 style="margin-top:3.0pt;margin-bottom:1.0pt">15. ABSENCE, ABANDONMENT AND ABSENCE WITHOUT AUTHORISATION</h2>
<div class="gap" style="height:4.3pt"></div>
<p class="j" style="margin-bottom:2.0pt">15.1 Absence without approval/sufficient cause, failure to report for duty, or leaving employment without completing the applicable separation process may constitute unauthorised absence or abandonment, as applicable.</p>
<p class="j" style="margin-bottom:2.0pt">15.2 Where an employee remains absent without approval/intimation for the period prescribed by HHCPL policy, HHCPL may initiate its absence/abandonment process and issue notices through recorded contact details.</p>
<p class="j" style="margin-bottom:2.0pt">15.3 The employee shall be given a reasonable opportunity to explain the absence where required by law or Company process.</p>
<p class="j" style="margin-bottom:2.0pt">15.4 If no satisfactory explanation is received within the period specified in the notice, HHCPL may take an appropriate decision regarding continuation or cessation of employment in accordance with law and procedure.</p>
<p class="j" style="margin-bottom:2.0pt">15.5 No salary or benefit shall be payable for unauthorised absence except where required by law. HHCPL may recover notice-period pay or other amounts lawfully recoverable, subject to law.</p>
<p class="j" style="margin-bottom:2.0pt">15.6 Employment/service records and separation documents shall accurately reflect the factual status and manner of separation.</p>
<p class="j" style="margin-bottom:2.0pt">15.7 Re-employment following abandonment/absconding is not an entitlement and remains subject to prevailing HHCPL policy and management approval.</p>
<div class="gap" style="height:11.9pt"></div>
<div class="gap" style="height:11.9pt"></div>
<h2 style="margin-top:3.0pt;margin-bottom:1.0pt">16. COMPANY PROPERTY, RECORDS AND ACCESS</h2>
<div class="gap" style="height:3.1pt"></div>
<p class="j" style="margin-bottom:2.0pt">All Company devices, ID/access cards, keys, documents, records, equipment, software, credentials and data shall be protected and returned on request or separation. You shall not retain copies of Company confidential information except where legally required.</p>
<div class="gap" style="height:11.9pt"></div>
<h2 style="margin-top:3.0pt;margin-bottom:1.0pt">17. HANDOVER AND FULL &amp;amp; FINAL SETTLEMENT</h2>
<div class="gap" style="height:3.1pt"></div>
<p class="j" style="margin-bottom:2.0pt">17.1 On separation you shall complete proper handover of responsibilities, records, assets, pending matters and other Company property.</p>
<p class="j" style="margin-bottom:2.0pt">17.2 Full and final settlement shall be processed in accordance with applicable law and HHCPL process, after lawful deductions/recoveries.</p>
<p class="j" style="margin-bottom:2.0pt">17.3 Nothing in this Letter authorises forfeiture or deduction contrary to applicable law. </p>
<div class="gap" style="height:11.9pt"></div>
<h2 style="margin-top:3.0pt;margin-bottom:1.0pt">18. BACKGROUND VERIFICATION AND CONTINUING DISCLOSURE</h2>
<div class="gap" style="height:3.1pt"></div>
<p class="j" style="margin-bottom:2.0pt">HHCPL may conduct or commission background, reference, credential, employment, education, identity and professional-registration verification relevant to employment, subject to law. You shall cooperate and provide accurate information. Material falsification, concealment or misrepresentation may result in appropriate action, including termination where legally permissible and procedurally required.</p>
<div class="gap" style="height:11.9pt"></div>
<h2 style="margin-top:3.0pt;margin-bottom:1.0pt">19. EMPLOYEE DECLARATIONS AND UNDERTAKINGS</h2>
<div class="gap" style="height:3.1pt"></div>
<p style="margin-bottom:2.0pt">By accepting this Letter, you confirm that:</p>
<ul>
<li style="margin-bottom:0.0pt">information/documents provided are true, accurate and complete to the best of your knowledge</li>
<li style="margin-bottom:0.0pt">qualifications, experience, registrations and credentials submitted are genuine and valid</li>
<li style="margin-bottom:0.0pt">you have disclosed material restrictions affecting your ability to perform the role</li>
<li style="margin-bottom:0.0pt">you are not knowingly accepting employment in breach of an enforceable obligation owed to another person/organisation</li>
<li style="margin-bottom:0.0pt">you will promptly notify HHCPL of any material change in the information provided</li>
</ul>
<div class="gap" style="height:11.9pt"></div>
<h2 style="margin-top:3.0pt;margin-bottom:1.0pt">20. MEDICAL FITNESS AND ROLE-RELATED REQUIREMENTS</h2>
<div class="gap" style="height:3.1pt"></div>
<p class="j" style="margin-bottom:2.0pt">Where reasonably required for occupational safety, patient safety, insurance, statutory, regulatory or role-specific purposes, HHCPL may require appropriate fitness or role-related assessments in accordance with applicable law. Such information shall be handled confidentially and without unlawful discrimination.</p>
<div class="gap" style="height:11.9pt"></div>
<h2 style="margin-top:3.0pt;margin-bottom:1.0pt">21. WORKPLACE DIGNITY, POSH AND NON-DISCRIMINATION</h2>
<div class="gap" style="height:3.1pt"></div>
<p class="j" style="margin-bottom:2.0pt">HHCPL is committed to a safe, respectful and professional workplace. You shall comply with applicable anti-harassment, POSH, anti-discrimination and workplace-dignity requirements and cooperate with authorised investigations. Complaints shall be handled through mechanisms prescribed by law and Company policy.</p>
<div class="gap" style="height:11.9pt"></div>
<h2 style="margin-top:3.0pt;margin-bottom:1.0pt">22. COMMUNICATIONS AND OFFICIAL RECORDS</h2>
<div class="gap" style="height:3.1pt"></div>
<p class="j" style="margin-bottom:2.0pt">22.1 Official employment communications may be issued through Company email, HRIS, registered address, recorded mobile/electronic channels or other authorised means, subject to law.</p>
<p class="j" style="margin-bottom:2.0pt">22.2 You shall keep contact, bank, address and other employment records accurate and promptly report changes.</p>
<div class="gap" style="height:11.9pt"></div>
<h2 style="margin-top:3.0pt;margin-bottom:1.0pt">23. GOVERNING LAW AND JURISDICTION</h2>
<div class="gap" style="height:4.3pt"></div>
<p class="j" style="margin-bottom:2.0pt">23.1 This Letter is governed by the laws applicable in India.</p>
<p class="j" style="margin-bottom:2.0pt">23.2 Subject to any mandatory statutory forum, authority, conciliation, tribunal or other dispute-resolution mechanism, courts/competent authorities having jurisdiction at Pune, Maharashtra shall have jurisdiction over matters arising from or relating to this Letter.</p>
<p class="j" style="margin-bottom:2.0pt">23.3 Nothing limits any non-waivable statutory right or mandatory forum.</p>
<div class="gap" style="height:11.9pt"></div>
<h2 style="margin-top:3.0pt;margin-bottom:1.0pt">24. SEVERABILITY</h2>
<div class="gap" style="height:3.1pt"></div>
<p class="j" style="margin-bottom:2.0pt">If any provision is held invalid, unlawful or unenforceable, it shall be modified/limited to the minimum extent necessary, and the remaining provisions shall continue to apply to the extent permitted by law.</p>
<div class="gap" style="height:11.9pt"></div>
<h2 style="margin-top:3.0pt;margin-bottom:1.0pt">25. ENTIRE UNDERSTANDING AND PRECEDENCE</h2>
<div class="gap" style="height:3.1pt"></div>
<p class="j" style="margin-bottom:2.0pt">This Letter, Annexure A and applicable HHCPL policies constitute the written employment framework, subject to law. In case of inconsistency, mandatory law prevails; thereafter, the specific written terms of this Letter prevail over general policy language to the extent of inconsistency, unless the policy provision is mandatory by law or expressly incorporated as controlling.</p>
<div class="gap" style="height:11.9pt"></div>
<h2 style="margin-top:3.0pt;margin-bottom:1.0pt">26. POLICY AMENDMENTS</h2>
<div class="gap" style="height:3.1pt"></div>
<p class="j" style="margin-bottom:2.0pt">HHCPL may amend operational, administrative, procedural and benefit policies prospectively to reflect business or legal requirements, subject to applicable law. No amendment shall remove a mandatory statutory entitlement.</p>
<div class="gap" style="height:11.9pt"></div>
<h2 style="margin-top:3.0pt;margin-bottom:1.0pt">27. ACCEPTANCE</h2>
<div class="gap" style="height:3.1pt"></div>
<p class="j" style="margin-bottom:2.0pt">Please sign and return a copy of this Letter as acknowledgment of your appointment and acceptance. By signing, you confirm that you have read and understood the terms and had an opportunity to seek clarification.</p>
<p class="j" style="margin-bottom:2.0pt">We welcome you to Healing Hands Clinic Private Limited and look forward to a professional and mutually beneficial association.</p>
<div class="gap" style="height:16.4pt"></div>
<div class="gap" style="height:16.4pt"></div>
<div class="keep">
<p style="margin-bottom:6.0pt">Yours sincerely,</p>
<p style="margin-bottom:6.0pt"><b>For Healing Hands Clinic Private Limited</b></p>
{{#if signature_html}}{{signature_html}}{{/if}}{{#unless signature_html}}<div class="gap" style="height:16.4pt"></div>
<div class="gap" style="height:16.4pt"></div>
{{/unless}}
<p style="margin-bottom:2.0pt"><b>{{hr_signatory_name}}</b></p>
<p style="margin-bottom:10pt"><b>{{hr_signatory_designation}}</b></p>
</div>
<div class="gap" style="height:14.5pt"></div>
<div class="gap" style="height:14.5pt"></div>
<div class="gap" style="height:14.5pt"></div>
<div class="gap" style="height:14.5pt"></div>
<div class="keep">
<p class="c" style="margin-bottom:3.0pt"><b>EMPLOYEE ACCEPTANCE</b></p>
<div class="gap" style="height:13.3pt"></div>
<p class="j" style="margin-bottom:2.0pt">I, <b>{{candidate_name}},</b> acknowledge that I have read and understood this Appointment Letter and Annexure A and accept the terms and conditions governing my employment with Healing Hands Clinic Private Limited.</p>
<div class="gap" style="height:12.3pt"></div>
<div class="gap" style="height:12.3pt"></div>
<p style="margin-bottom:2.0pt">Signature: ___________________________&nbsp;&nbsp;&nbsp;&nbsp;Date: ______________</p>
</div>
<div class="gap" style="height:18.4pt"></div>
<p style="margin-bottom:8.0pt">Employee Code: <b>{{employee_code}}</b>&nbsp;&nbsp;&nbsp;&nbsp;Place: ______________</p>
<div class="gap" style="height:14.5pt"></div>
<div class="gap" style="height:14.5pt"></div>
<p class="c pb" style="margin-bottom:3.0pt"><b>ANNEXURE A – COMPENSATION STATEMENT</b></p>
<div class="gap" style="height:12.3pt"></div>
<div class="gap" style="height:12.3pt"></div>
<p class="j" style="margin-bottom:2.0pt">Detailed salary/CTC structure: {{#unless include_ctc}}To be attached / inserted as applicable.{{/unless}}</p>{{#if include_ctc}}{{ctc_annexure_html}}{{/if}}
<div class="gap" style="height:12.3pt"></div>
<p class="j" style="margin-bottom:2.0pt">All salary components are subject to applicable statutory deductions, taxes, contributions and applicable HHCPL policies/schemes.</p>
{{#unless include_ctc}}<div class="gap" style="height:12.3pt"></div>
<div class="gap" style="height:12.3pt"></div>
<div class="gap" style="height:12.3pt"></div>
<div class="gap" style="height:12.3pt"></div>
<div class="gap" style="height:12.3pt"></div>
<div class="gap" style="height:12.3pt"></div>
<div class="gap" style="height:12.3pt"></div>
<div class="gap" style="height:12.3pt"></div>
<div class="gap" style="height:12.3pt"></div>
<div class="gap" style="height:12.3pt"></div>
<div class="gap" style="height:12.3pt"></div>
<div class="gap" style="height:12.3pt"></div>
<div class="gap" style="height:12.3pt"></div>
<div class="gap" style="height:12.3pt"></div>
<div class="gap" style="height:12.3pt"></div>
<div class="gap" style="height:12.3pt"></div>
<div class="gap" style="height:12.3pt"></div>
<div class="gap" style="height:12.3pt"></div>
<div class="gap" style="height:12.3pt"></div>
<div class="gap" style="height:12.3pt"></div>
<div class="gap" style="height:12.3pt"></div>
<div class="gap" style="height:12.3pt"></div>
<div class="gap" style="height:12.3pt"></div>
<div class="gap" style="height:12.3pt"></div>
<div class="gap" style="height:12.3pt"></div>
<div class="gap" style="height:12.3pt"></div>
<div class="gap" style="height:12.3pt"></div>
{{/unless}}{{#if include_ctc}}<div class="gap" style="height:36pt"></div>{{/if}}
<div class="keep">
<p style="margin-bottom:6.0pt">Yours sincerely,</p>
<p style="margin-bottom:6.0pt"><b>For Healing Hands Clinic Private Limited</b></p>
{{#if signature_html}}{{signature_html}}{{/if}}{{#unless signature_html}}<div class="gap" style="height:16.4pt"></div>
<div class="gap" style="height:16.4pt"></div>
{{/unless}}
<p style="margin-bottom:2.0pt"><b>{{hr_signatory_name}}</b></p>
<p style="margin-bottom:10pt"><b>{{hr_signatory_designation}}</b></p>
</div>
<div class="gap" style="height:12.3pt"></div>
<img class="lh-screen lh-foot" src="{{letterhead_footer_src}}" alt="">
</div>
'
 WHERE template_type = 'APPOINTMENT_LETTER' AND is_active = 1;

UPDATE rec_letter_templates
   SET body_html = '<!-- Consultant (Surgeon) Service Agreement - Healing Hands Clinic. Wording as in Surgeon_agreement_draft.docx.
     Values in double curly braces are filled by the system. Letterhead header/footer are added on every PDF page. -->
<style>
@page { size: Letter; margin: 1.7in 1in 1.75in 1in; }
.letter { font-family: Arial, ''Liberation Sans'', Helvetica, sans-serif; font-size: 10pt; line-height: 1.33; color: #1C2833; }
.letter p { margin: 4pt 0; }
.letter .j { text-align: justify; }
.letter .c { text-align: center; }
.letter .title { text-align: center; color: #1B4F72; margin: 0 0 14pt; }
.letter h1 { font-size: 10pt; font-weight: bold; color: #1B4F72; margin: 18pt 0 6pt; padding-bottom: 6pt; border-bottom: 0.5pt solid #2874A6; line-height: 1.2; page-break-after: avoid; break-after: avoid; }
.letter h2 { font-size: 10pt; font-weight: bold; color: #2874A6; margin: 12pt 0 4pt; line-height: 1.2; page-break-after: avoid; break-after: avoid; }
.letter ul { margin: 0; padding-left: 0.5in; list-style: none; }
.letter li { position: relative; margin: 3pt 0; line-height: 1.25; }
.letter li::before { content: ''\\2022''; position: absolute; left: -0.25in; }
.letter .sp { height: 10pt; }
.letter .pb { page-break-before: always; break-before: page; }
.letter table { width: 100%; border-collapse: collapse; margin: 6pt 0 10pt; font-size: 10pt; line-height: 1.3; page-break-inside: avoid; break-inside: avoid; }
.letter table td, .letter table th { border: 0.5pt solid #BDC3C7; padding: 4pt 6pt; vertical-align: top; text-align: left; }
.letter table.cover th { width: 30%; background: #D6EAF8; color: #1B4F72; font-weight: bold; }
.letter table.twin td { width: 50%; padding: 6pt 8pt; }
.letter table.sign td { border: 0; }
.letter .shade { background: #D6EAF8; }
.letter .grey { background: #F8F9F9; }
.letter b.t { color: #1B4F72; }
.letter .muted { color: #7F8C8D; }
.letter .gap6 { height: 6pt; }
.letter .sealspace { height: 22pt; }
.letter, .letter * { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
.letter .lh-screen { display: none; }
@media screen {
  body { background: #e9eef2; margin: 0; padding: 16px 0; }
  .letter { background: #fff; width: 8.5in; max-width: 100%; box-sizing: border-box; padding: 0 1in 0.2in; margin: 0 auto; box-shadow: 0 2px 12px rgba(0,0,0,.12); }
  .letter .lh-screen { display: block; width: calc(100% + 2in); margin: 0 -1in 12pt; }
  .letter .lh-screen.lh-foot { margin: 24pt -1in -0.2in; }
  .letter .pb { border-top: 1px dashed #b8c4cc; margin-top: 28pt; padding-top: 20pt; }
}
</style>
<div class="letter" data-letterhead="hhc">
<img class="lh-screen" src="{{letterhead_header_src}}" alt="">
<p class="title"><b>SERVICE AGREEMENT</b></p>
<table class="cover">
<tr><th>Agreement Date</th><td>{{agreement_start_date}}</td></tr>
<tr><th>Place of Execution</th><td>{{place_of_execution}}</td></tr>
<tr><th>Party of the First Part</th><td>Healing Hands Clinic Pvt. Ltd. Second Floor, Millenium Star, Balkrishna Sakharam Dhole Patil Rd, Extension, Sangamvadi, Pune, Maharashtra 411001 (hereinafter referred to as "HHC")</td></tr>
<tr><th>Party of the Second Part</th><td>Dr. {{candidate_name}}{{#if candidate_address}}, {{candidate_address}}{{/if}}</td></tr>
<tr><th>Primary Work Location</th><td>{{location}}</td></tr>
<tr><th>Contract Duration</th><td>2 (Two) Years from the Date of Execution</td></tr>
</table>
<h1>RECITALS</h1>
<p class="j">WHEREAS, Healing Hands Clinic Pvt. Ltd. (&quot;HHC&quot;) is a company duly incorporated and registered under the Companies Act, having its registered office at Flat No. 105, Mangalmurti Complex, Shukrawar Peth, Tilak Road, Pune – 411002, and is engaged in the business of operating hospitals, surgical centres, and allied healthcare activities, with branch clinics pan-India;</p>
<div class="sp"></div>
<p class="j">WHEREAS, the Surgeon is a qualified medical professional holding a valid registration with the National Medical Commission / Medical Council of India (NMC/MCI) and possesses the requisite professional skill, training, and experience to perform surgical procedures and provide clinical services;</p>
<div class="sp"></div>
<p class="j">AND WHEREAS, HHC desires to engage the Surgeon to render surgical and clinical services at its branches, and the Surgeon is willing to provide such services, on the terms and conditions set forth herein;</p>
<div class="sp"></div>
<p class="j">NOW, THEREFORE, in consideration of the mutual covenants, representations, warranties, and agreements contained herein, and for other good and valuable consideration, the receipt and sufficiency of which are hereby acknowledged, the parties agree as follows:</p>
<div class="pb"></div>
<h1>1. ENGAGEMENT AND SCOPE OF SERVICES</h1>
<h2>1.1 Engagement</h2>
<p class="j">HHC hereby engages the Surgeon as an independent Consultant Surgeon, and the Surgeon hereby accepts such engagement, strictly on a non-employment, principal-to-principal basis. Nothing in this Agreement shall be construed as creating a partnership, joint venture, or agency relationship.</p>
<h2>1.2 Primary Duties</h2>
<p class="j">The Surgeon agrees to provide the following services at HHC&#x27;s branches as assigned by HHC from time to time:</p>
<ul>
<li>Perform surgical procedures including but not limited to proctology, hernia, varicose veins, and allied laparoscopic surgeries;</li>
<li>Conduct pre-operative evaluations and post-operative follow-up care for all patients operated upon;</li>
<li>Conduct OPD consultations as per the schedule assigned by HHC;</li>
<li>Maintain accurate, complete, and timely clinical records, operation notes, and patient documentation as per HHC&#x27;s protocols;</li>
<li>Adhere to all clinical protocols, standard operating procedures (SOPs), quality benchmarks, and ethical standards established by HHC;</li>
<li>Participate in clinical audits, departmental meetings, training programmes, and quality improvement initiatives as required by HHC;</li>
<li>Provide any other clinical or administrative support as reasonably required by HHC.</li>
</ul>
<h2>1.3 Work Schedule</h2>
<p class="j">The Surgeon shall render full-time services at Healing Hands Clinic for the time 5.30 PM to 09.00 PM per day. The Surgeon shall be entitled to one (1) weekly off, which shall be scheduled on any day of the week as mutually decided by the Management based on operational requirements. The Surgeon shall remain available for emergency clinical duties and additional responsibilities, if required, in the interest of patient care and hospital operations.</p>
<h2>1.4 Multi-Branch Deployment</h2>
<p class="j">The Surgeon acknowledges and agrees that HHC operates clinics Pan-India across multiple states. HHC reserves the right, to move the surgeon to different HHC units to provide their services. The Surgeon&#x27;s primary work location is specified in the cover sheet, but this does not limit HHC&#x27;s right to deploy across branches.</p>
<h2>1.5 Reporting Authority</h2>
<p class="j">The Surgeon shall report to <b>{{reporting_to}}</b>, or such other officer as HHC may designate in writing from time to time, and shall follow all lawful directions, guidance, and instructions issued by the reporting authority.</p>
<h2>1.6 HHC&#x27;s Obligations</h2>
<p class="j">In support of the Surgeon&#x27;s duties, HHC shall:</p>
<ul>
<li>Provide a functional operation theatre, OPD space, and clinical equipment reasonably required to perform surgical procedures;</li>
<li>Ensure availability of support staff including anaesthetists, scrub nurses, and ward assistants during scheduled surgeries;</li>
<li>Comply with all applicable laws, regulatory requirements, and licensing obligations applicable to the clinic.</li>
</ul>
<h1>2. COMPENSATION AND PAYMENT</h1>
<h2>2.1 Monthly Compensation — Higher of Two</h2>
<p class="j">The Surgeon shall be compensated on a monthly basis by the higher of the following two amounts:</p>
<div class="sp"></div>
<p><b>Option A — Monthly Retainer</b></p>
<p class="j">The professional fee payable shall be INR {{retainer_amount}}/- (Indian Rupees {{retainer_words}} Only) per month or INR {{per_case_amount}}/- (Indian Rupees {{per_case_words}} Only) per surgery, whichever is higher. The amount payable shall be calculated by comparing the monthly retainer with the total fee calculated at the per-surgery rate, and the higher amount shall be paid for the relevant month. Applicable TDS shall be deducted at 10% or at such other rate as may be applicable under the Income Tax Act, 1961.</p>
<h2>2.2 Payment Terms</h2>
<ul>
<li>All payments shall be made monthly in arrears on or before the 10th working day of the following month.</li>
<li>HHC shall deduct TDS and other applicable statutory deductions at source and shall issue Form 16A / TDS certificate as required under applicable law.</li>
</ul>
<h1>3. TERM AND RENEWAL</h1>
<h2>3.1 Term</h2>
<p class="j">This Agreement shall commence on the date of execution and shall remain in force for a period of 2 (Two) years (&quot;Term&quot;), unless terminated earlier in accordance with Clause 5 hereof.</p>
<h2>3.2 Lock-In Period</h2>
<p class="j">The first 12 (twelve) months from the date of execution shall be a lock-in period. The Surgeon shall not be entitled to terminate this Agreement during the lock-in period under any circumstance, except in the event of a material breach by HHC that remains unremedied for 30 (thirty) days after written notice.</p>
<h2>3.3 Renewal</h2>
<p class="j">This Agreement may be renewed for further periods upon mutual written consent of both parties, executed not less than 30 (thirty) days before the expiry of the then-current Term. Renewal shall not be deemed automatic under any circumstances.</p>
<h1>5. TERMINATION</h1>
<h2>5.1 Termination by Either Party — Notice</h2>
<p class="j">Subject to Clause 3.2 (lock-in), either party may terminate this Agreement by providing 90 (ninety) days&#x27; prior written notice to the other party. The Surgeon must deliver notice of termination by registered post or email with delivery confirmation to HHC&#x27;s registered office. HHC may, at its discretion, waive all or part of the notice period.</p>
<h2>5.2 Immediate Termination by HHC</h2>
<p class="j">HHC may terminate this Agreement with immediate effect, without notice and without any obligation of payment in lieu of notice, in any of the following circumstances:</p>
<ul>
<li>The Surgeon commits any act of dishonesty, fraud, misrepresentation, or financial impropriety, whether relating to HHC, its patients, staff, or third parties;</li>
<li>The Surgeon is guilty of gross misconduct, professional negligence, or any serious breach of obligations under this Agreement;</li>
<li>The Surgeon violates the exclusivity obligation under Clause 4;</li>
<li>The Surgeon breaches the confidentiality obligations under Clause 7 or the non-compete obligations under Clause 9;</li>
<li>The Surgeon is convicted of any criminal offence or any offence involving moral turpitude;</li>
<li>The Surgeon&#x27;s NMC/MCI registration is suspended, cancelled, or revoked for any reason;</li>
<li>The Surgeon is declared insolvent or an insolvency resolution application is filed against the Surgeon;</li>
<li>The Surgeon is found to have issued false, misleading, or inflated invoices;</li>
<li>The Surgeon is incapacitated and unable to perform surgical duties for a continuous period exceeding 30 (thirty) days;</li>
<li>The Surgeon fails to comply with applicable laws, regulations, or the directives of any statutory healthcare body;</li>
<li>The Surgeon&#x27;s conduct, in the reasonable opinion of HHC, brings HHC or its reputation into disrepute.</li>
</ul>
<h2>5.3 Suspension Pending Investigation</h2>
<p class="j">HHC reserves the right to suspend the Surgeon during the pendency of any investigation into alleged misconduct. During suspension, the Surgeon shall not attend HHC premises, contact HHC&#x27;s patients or staff, or represent themselves as associated with HHC. HHC is under no obligation to pay any compensation during the suspension period unless the investigation concludes in the Surgeon&#x27;s favour. The Surgeon shall immediately return all HHC property upon suspension.</p>
<h2>5.4 Handover Obligations</h2>
<p class="j">Irrespective of the mode of termination, the Surgeon shall complete a full clinical and administrative handover during the notice period (or, in the case of immediate termination, within 7 days), including transfer of all patient records, operation notes, HHC property, and digital access credentials to the person(s) designated by HHC.</p>
<h2>5.5 Failure to Serve Notice Period — Compensation in Lieu</h2>
<p class="j">Notwithstanding any other provision of this Agreement, in the event the Surgeon fails to serve the full 90 (ninety) day notice period as required under Clause 5.1, the Surgeon shall be liable to pay HHC a sum equivalent to thrice the monthly professional fees for each remaining month (or part thereof) of the unserved notice period (&quot;Notice Pay&quot;). HHC shall be entitled, at its sole discretion, to recover such Notice Pay by deducting or withholding the same from any dues, incentives, or amounts payable by HHC to the Surgeon, or by encashing the post-dated cheque of INR [3,00,000/-] [(Rupees Three Lakh Only)] furnished by the Surgeon at the time of execution of this Agreement, or by initiating appropriate legal proceedings for recovery of such amounts. The foregoing obligations shall not apply where the Surgeon&#x27;s failure to serve the notice period is directly and solely caused by a force majeure event, act of God, or a catastrophic illness certified by a registered medical practitioner, provided the Surgeon notifies HHC of such circumstance in writing without undue delay.</p>
<h1>6. PROFESSIONAL QUALIFICATIONS AND CONDUCT</h1>
<h2>6.1 Registration</h2>
<p class="j">The Surgeon represents, warrants, and undertakes that throughout the Term of this Agreement, the Surgeon shall maintain a valid and unrestricted registration with the National Medical Commission (NMC) or relevant State Medical Council, and shall promptly notify HHC in writing of any suspension, enquiry, or adverse action taken by any regulatory or disciplinary body.</p>
<h2>6.2 Professional Standards</h2>
<p class="j">The Surgeon shall at all times:</p>
<ul>
<li>Adhere to the Code of Medical Ethics issued by the NMC / Indian Medical Association (IMA) and all applicable guidelines;</li>
<li>Perform all surgeries and clinical procedures in accordance with internationally accepted standards of surgical practice;</li>
<li>Obtain valid and documented informed consent from patients or their legal guardians before all surgical procedures;</li>
<li>Maintain accurate, legible, and contemporaneous clinical records for every patient;</li>
<li>Promptly report any adverse event, near-miss, or patient safety incident to the HHC management and comply with HHC&#x27;s incident reporting protocols.</li>
</ul>
<h1>7. CONFIDENTIALITY</h1>
<h2>7.1 Definition of Confidential Information</h2>
<p class="j">&quot;Confidential Information&quot; means all non-public information of any nature acquired by the Surgeon during the course of this engagement, including but not limited to:</p>
<ul>
<li>Patient identities, medical histories, diagnoses, treatment data, and clinical records (including data governed by the Digital Personal Data Protection Act, 2023 and applicable health data regulations);</li>
<li>HHC&#x27;s proprietary surgical techniques, clinical protocols, standard operating procedures (SOPs), quality benchmarks, and training materials;</li>
<li>HHC&#x27;s business strategies, pricing structures, fee schedules, expansion plans, and commercial terms with third parties;</li>
<li>HHC&#x27;s technology systems, software, electronic medical records (EMR), and IT infrastructure;</li>
<li>Financial data, employee information, supplier and vendor contracts, and investor information;</li>
<li>Any information expressly designated by HHC as confidential.</li>
</ul>
<h2>7.2 Obligations</h2>
<p class="j">The Surgeon shall:</p>
<ul>
<li>Hold all Confidential Information in strict confidence and not disclose it to any third party without HHC&#x27;s prior written consent;</li>
<li>Use Confidential Information exclusively for the performance of duties under this Agreement and for no other purpose;</li>
<li>Not copy, reproduce, publish, transmit, or make any derivative work from Confidential Information;</li>
<li>Immediately notify HHC upon becoming aware of any actual or threatened unauthorised disclosure.</li>
</ul>
<h2>7.3 Exceptions</h2>
<p class="j">Confidentiality obligations shall not apply to information that: (a) is or becomes publicly available other than through the Surgeon&#x27;s breach; (b) was independently known to the Surgeon prior to this engagement and can be evidenced in writing; (c) is disclosed pursuant to a valid court order or statutory requirement, provided the Surgeon notifies HHC promptly and co-operates in limiting the scope of such disclosure.</p>
<h2>7.4 Survival</h2>
<p class="j">The obligations under this Clause 7 shall survive the expiry or termination of this Agreement for a period of 5 (five) years, and indefinitely with respect to patient data.</p>
<h2>7.5 Remedies</h2>
<p class="j">The Surgeon acknowledges that breach of confidentiality obligations may cause irreparable harm to HHC for which monetary damages alone would be an inadequate remedy. HHC shall be entitled to seek injunctive relief, specific performance, and any other equitable remedy available in addition to monetary damages.</p>
<h1>8. INTELLECTUAL PROPERTY</h1>
<h2>8.1 Ownership</h2>
<p class="j">All intellectual property rights, including but not limited to surgical techniques, clinical protocols, SOPs, training manuals, software, databases, content, and any other work product created, developed, or contributed to by the Surgeon in the course of performing services under this Agreement (&quot;Work Product&quot;) shall be the exclusive property of HHC from the moment of creation.</p>
<h2>8.2 Assignment</h2>
<p class="j">To the extent any Work Product does not automatically vest in HHC by operation of law, the Surgeon hereby irrevocably and unconditionally assigns to HHC all right, title, and interest in such Work Product, including all associated intellectual property rights, worldwide and in perpetuity, without any additional compensation.</p>
<h2>8.3 Moral Rights</h2>
<p class="j">The Surgeon waives, to the fullest extent permitted by applicable law, all moral rights, rights of attribution, and rights of integrity in any Work Product assigned to HHC.</p>
<h2>8.4 Pre-Existing IP</h2>
<p class="j">The Surgeon shall not incorporate any pre-existing intellectual property owned by the Surgeon or any third party into HHC&#x27;s Work Product without HHC&#x27;s prior written consent and, if required by HHC, a separate written licence agreement.</p>
<h1>9. NON-COMPETE AND NON-SOLICITATION</h1>
<h2>9.1 Non-Compete</h2>
<p class="j">The Surgeon undertakes that during the Term of this Agreement and for a period of 2 (two) years following the expiry or termination of this Agreement (&quot;Restricted Period&quot;), the Surgeon shall not, without the prior written consent of HHC:</p>
<ul>
<li>Directly or indirectly carry on, own, manage, operate, join, consult for, or provide services to any hospital, clinic, surgical centre, or healthcare business that is competitive with HHC&#x27;s core areas of practice (including proctology and related minimally invasive procedures) within any city or state in which HHC operates at the time of termination;</li>
<li>Set up an independent surgical practice in any of HHC&#x27;s operational cities during the Restricted Period.</li>
</ul>
<p class="j">HHC shall respond to any request for consent from the Surgeon within 7 (seven) working days of receipt.</p>
<h2>9.2 Non-Solicitation of Patients</h2>
<p class="j">During the Term and for a period of 2 (two) years thereafter, the Surgeon shall not directly or indirectly solicit, divert, or entice away any patient of HHC to receive treatment at any other facility.</p>
<h2>9.3 Non-Solicitation of Staff</h2>
<p class="j">During the Term and for a period of 1 (one) year thereafter, the Surgeon shall not, directly or indirectly, solicit, induce, or hire any employee, consultant, or contractor of HHC.</p>
<h2>9.4 Reasonableness</h2>
<p class="j">The Surgeon acknowledges that the restrictions in this Clause 9 are reasonable and necessary to protect HHC&#x27;s legitimate business interests, goodwill, trade secrets, and patient relationships, and that HHC would not have entered into this Agreement but for such restrictions.</p>
<h1>10. INDEMNITY AND LIABILITY</h1>
<h2>10.1 Indemnification by Surgeon</h2>
<p class="j">The Surgeon shall indemnify, defend, and hold harmless HHC, its directors, officers, employees, and agents (collectively &quot;HHC Indemnitees&quot;) from and against all claims, actions, damages, losses, liabilities, costs, and expenses (including reasonable legal fees) arising from or in connection with:</p>
<ul>
<li>Any act or omission of the Surgeon constituting medical negligence, professional misconduct, or violation of applicable clinical standards;</li>
<li>Any patient complaint, medico-legal claim, or consumer forum proceeding attributable to the Surgeon&#x27;s surgical or clinical conduct;</li>
<li>Any breach by the Surgeon of any representation, warranty, or obligation under this Agreement;</li>
<li>Any claim by any third party arising from the Surgeon&#x27;s unauthorised disclosure of Confidential Information;</li>
<li>Any liability arising from the Surgeon&#x27;s violation of applicable laws or regulatory requirements.</li>
</ul>
<h2>10.2 Limitation of HHC Liability</h2>
<p class="j">HHC&#x27;s aggregate liability to the Surgeon under this Agreement shall not exceed the total compensation paid to the Surgeon in the 3 (three) months immediately preceding the event giving rise to the claim. HHC shall not be liable for any indirect, consequential, special, or punitive damages.</p>
<h2>10.3 Force Majeure</h2>
<p class="j">Neither party shall be liable for any failure or delay in performance caused by circumstances beyond its reasonable control, including acts of God, pandemic, government action, natural disasters, or regulatory prohibitions, provided the affected party notifies the other in writing within 7 days and uses reasonable endeavours to mitigate the impact.</p>
<h2>10.4 Insurance</h2>
<p class="j">The Surgeon shall maintain professional indemnity insurance in an amount not less than INR 25 lakhs/- per claim (or such amount as HHC may notify from time to time) and shall provide HHC with evidence of such coverage on request. HHC shall additionally maintain institutional liability insurance covering the Surgeon&#x27;s activities within HHC premises.</p>
<h1>11. RELATIONSHIP OF PARTIES</h1>
<p class="j">The relationship between HHC and the Surgeon under this Agreement is that of an independent contractor (principal-to-principal). This Agreement does not and shall not be construed to create any relationship of employer-employee, partnership, joint venture, or agency. The Surgeon shall have no authority to bind, represent, or incur any liability on behalf of HHC. The Surgeon shall be solely responsible for all income tax, professional tax, GST, and other statutory liabilities arising from payments received under this Agreement.</p>
<h1>12. NOTICES</h1>
<p class="j">All notices, communications, or demands required or permitted under this Agreement shall be in writing and shall be deemed duly delivered when:</p>
<ul>
<li>hand-delivered to the receiving party;</li>
<li>transmitted by email with delivery and read receipt, to the addresses specified below.</li>
</ul>
<table class="twin">
<tr><td class="shade"><b class="t">If to HHC:</b><br>Healing Hands Clinic Pvt. Ltd.<br>Flat No. 105, Mangalmurti Complex,<br>Shukrawar Peth, Tilak Road, Pune – 411002<br>Attn: Mr. Roshan Porwal, Director<br>Email: rosh@healinghandsclinic.co.in</td>
<td><b class="t">If to Surgeon:</b><br>Dr. {{candidate_name}}<br>Address: {{candidate_address}}<br>Mobile: {{candidate_mobile}}<br>Email: {{candidate_email}}</td></tr>
</table>
<h1>13. GENERAL PROVISIONS</h1>
<h2>13.1 Governing Law and Jurisdiction</h2>
<p class="j">This Agreement shall be governed by and construed in accordance with the laws of India. The parties irrevocably submit to the exclusive jurisdiction of the courts at Pune, Maharashtra for resolution of any dispute or claim arising under or in connection with this Agreement.</p>
<h2>13.2 Entire Agreement</h2>
<p class="j">This Agreement, together with its Annexures, constitutes the entire agreement between the parties with respect to its subject matter and supersedes all prior negotiations, representations, understandings, and agreements, whether oral or written.</p>
<h2>13.3 Amendments</h2>
<p class="j">No amendment, modification, or variation to this Agreement shall be valid or binding unless made in writing and signed by authorised representatives of both parties.</p>
<h2>13.4 Severability</h2>
<p class="j">If any provision of this Agreement is held to be invalid, illegal, or unenforceable by a court of competent jurisdiction, such provision shall be modified to the minimum extent necessary to make it enforceable, and the remaining provisions shall continue in full force and effect.</p>
<h2>13.5 Waiver</h2>
<p class="j">No failure or delay by either party in exercising any right or remedy shall operate as a waiver thereof. A waiver of any breach shall not be deemed to be a waiver of any subsequent breach of the same or any other provision.</p>
<h2>13.6 Assignment</h2>
<p class="j">The Surgeon shall not assign, sub-contract, or transfer any rights or obligations under this Agreement without the prior written consent of HHC. HHC may assign this Agreement to any entity that controls, is controlled by, or is under common control with HHC, or to any successor entity acquiring all or substantially all of HHC&#x27;s business, without the Surgeon&#x27;s consent.</p>
<h2>13.7 Headings</h2>
<p class="j">Clause headings are for convenience of reference only and shall not affect the interpretation of this Agreement.</p>
<h2>13.8 Counterparts</h2>
<p class="j">This Agreement may be executed in counterparts, each of which shall be deemed an original, and all of which together shall constitute one and the same instrument. Electronic signatures and scanned copies shall be treated as valid originals.</p>
<div class="pb"></div>
<h1>14. EXECUTION</h1>
<p class="j">IN WITNESS WHEREOF, the parties have executed this Surgeon Service Agreement on the date and at the place first mentioned above.</p>
<table class="twin sign">
<tr><td class="shade"><b class="t">For Healing Hands Clinic Pvt. Ltd.</b><br><span class="muted">(Party of the First Part)</span><div class="gap6"></div>{{signature_html}}Authorised Signatory<br>Name: Mr. Sagar Shekhar<br>Designation: HR Head<br>Date: ___________________<div class="gap6"></div>Seal:<div class="sealspace"></div></td>
<td class="grey"><b class="t">By the Surgeon</b><br><span class="muted">(Party of the Second Part)</span><div class="gap6"></div>Name: Dr. {{candidate_name}}<br>Qualification: {{qualification}}<br>Date: ………………………………..<br>Signature:</td></tr>
</table>
<div class="sp"></div>
<p class="c"><b>WITNESSES</b></p>
<table class="twin box">
<tr><td><b class="t">Witness 1</b><br>Name: ___________________<br>Address: ___________________<br>Signature: ___________________</td>
<td><b class="t">Witness 2</b><br>Name: ___________________<br>Address: ___________________<br>Signature: ___________________</td></tr>
</table>
<div class="pb"></div>
<p class="c"><b>ANNEXURE A</b></p>
<p class="c"><b>SCHEDULE OF SERVICES AND COMPENSATION</b></p>
<div class="sp"></div>
<p><b>A1. Services to be Rendered</b></p>
<ul>
<li>Proctology surgeries</li>
<li>Hernia repair surgeries</li>
<li>Varicose vein treatments</li>
<li>General laparoscopic and minimally invasive surgeries as may be required by HHC</li>
<li>OPD consultations, pre-operative assessments, and post-operative reviews</li>
<li>Any other surgical or clinical duty assigned by HHC within the Surgeon&#x27;s specialty</li>
</ul>
<p><b>A2. Monthly Retainer</b></p>
<ul>
<li><b>The professional fee payable shall be INR {{retainer_amount}}/- (Indian Rupees {{retainer_words}} Only) per month or INR {{per_case_amount}}/- (Indian Rupees {{per_case_words}} Only) per surgery, whichever is higher.</b> The amount payable shall be calculated by comparing the monthly retainer with the total fee calculated at the per-surgery rate, and the higher amount shall be paid for the relevant month. Applicable TDS shall be deducted at 10% or at such other rate as may be applicable under the Income Tax Act, 1961.</li>
</ul>
<p class="j">The Surgeon shall receive whichever is higher — the Monthly Retainer or the Surgery Incentive total computed under for the relevant month.</p>
<div class="sp"></div>
<p><b>A3. Payment Cycle</b></p>
<p class="j">Professional fees will be paid on or before the 10th working day of the following month</p>
<div class="sp"></div>
<p><b>Signed on behalf of both parties as part of the Agreement:</b></p>
<table class="twin box">
<tr><td><b class="t">For HHC:</b><br>Signature: {{#if signature_html}}{{signature_html}}{{/if}}{{#unless signature_html}}___________________<br>{{/unless}}Name: Mr. Sagar Shekhar<br>Date: ___________________</td>
<td><b class="t">Surgeon:</b><br>Signature: ___________________<br>Name: Dr. {{candidate_name}}<br>Date:………………………………..</td></tr>
</table>
<img class="lh-screen lh-foot" src="{{letterhead_footer_src}}" alt="">
</div>
'
 WHERE template_type = 'CONSULTANT_AGREEMENT' AND is_active = 1;

-- Check: the 3 templates should show has_signature_spot = 1, and the 2 new columns should be listed
SELECT template_type, template_name, body_html LIKE '%signature_html%' AS has_signature_spot
  FROM rec_letter_templates WHERE is_active = 1 ORDER BY template_type;
SHOW COLUMNS FROM users LIKE 'signature_path';
SHOW COLUMNS FROM rec_ctc_proposals LIKE 'approval_signature_path';
