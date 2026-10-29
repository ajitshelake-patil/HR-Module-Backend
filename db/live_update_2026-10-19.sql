-- =====================================================================
-- HHC Recruitment - LIVE SERVER UPDATE (19 Oct 2026)
-- Offer Letter -> new letterhead (HCO_Letter_Head_Template_1: "Curing with Care"
-- logo at the top, city strip with NABH seal at the bottom).
-- Appointment Letter and Consultant Agreement are NOT changed.
-- Safe on a database that already has data: only the text of the ACTIVE offer-letter
-- template is replaced. Offer letters already generated keep their PDFs.
-- Take a backup first:  mysqldump -u root -p hhc_recruitment > backup_before_update.sql
-- If your database has another name, change the USE line below.
-- =====================================================================
USE hhc_recruitment;
SET NAMES utf8mb4;

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
<div class="gap" style="height:13.9pt"></div>
<div class="gap" style="height:13.9pt"></div>
<div class="gap" style="height:13.9pt"></div>
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
<div class="gap" style="height:13.9pt"></div>
<div class="gap" style="height:13.9pt"></div>
<div class="gap" style="height:13.9pt"></div>
<p style="margin-bottom:3.0pt"><b>{{hr_signatory_name}}</b></p>
<p style="margin-bottom:3.0pt"><b>{{hr_signatory_designation}}</b></p>
</div>
<img class="lh-screen lh-foot" src="{{letterhead2_footer_src}}" alt="">
</div>
'
 WHERE template_type = 'OFFER_LETTER' AND is_active = 1;

-- Check: OFFER_LETTER -> letterhead 'hco'; the others stay 'hhc'
SELECT id, template_type, template_name,
       CASE WHEN body_html LIKE '%data-letterhead="hco"%' THEN 'hco (new)'
            WHEN body_html LIKE '%data-letterhead="hhc"%' THEN 'hhc' ELSE 'none' END AS letterhead
  FROM rec_letter_templates WHERE is_active = 1 ORDER BY template_type;
