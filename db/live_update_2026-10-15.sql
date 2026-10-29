-- =====================================================================
-- HHC Recruitment - LIVE SERVER UPDATE (15 Oct 2026)
-- Safe on a database that already has data:
--   * no table is dropped, created or altered
--   * no candidate / employee / offer / agreement data is changed or deleted
-- It changes only two settings:
--   1. Employee code series  -> HHCPL (shared by EMPLOYEE + CONSULTANT), next code HHCPL1631
--   2. Consultant Agreement template -> HHC Surgeon Service Agreement (the only active one)
-- Take a backup first, e.g.:  mysqldump -u root -p hhc_recruitment > backup_before_update.sql
-- If your database has another name, change the USE line below.
-- =====================================================================
USE hhc_recruitment;
SET NAMES utf8mb4;

-- ---------------------------------------------------------------------
-- 1. Employee codes: HHCPL series continuing after HHCPL1630
--    (the new sequence.js also does this by itself; this just makes the setting visible in the table)
--    If HR has issued codes after HHCPL1630, change 1630 below to the last number used.
-- ---------------------------------------------------------------------
UPDATE employee_code_sequences
   SET last_number = GREATEST(1630, IF(prefix = 'HHCPL', last_number, 0)),
       prefix = 'HHCPL',
       padding = 4
 WHERE code_type IN ('EMPLOYEE', 'CONSULTANT');

-- ---------------------------------------------------------------------
-- 2. Consultant Agreement template
--    Old agreement templates are only switched off (not deleted), because agreements
--    already generated still refer to them.
-- ---------------------------------------------------------------------
UPDATE rec_letter_templates
   SET is_active = 0, is_default = 0
 WHERE template_type = 'CONSULTANT_AGREEMENT';

INSERT INTO rec_letter_templates (template_type, template_name, body_html, is_default, is_active, created_by)
SELECT 'CONSULTANT_AGREEMENT', 'HHC Surgeon Service Agreement', '<!-- Consultant (Surgeon) Service Agreement - Healing Hands Clinic. Wording as in Surgeon_agreement_draft.docx.
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
<tr><td class="shade"><b class="t">For Healing Hands Clinic Pvt. Ltd.</b><br><span class="muted">(Party of the First Part)</span><div class="gap6"></div>Authorised Signatory<br>Name: Mr. Sagar Shekhar<br>Designation: HR Head<br>Date: ___________________<div class="gap6"></div>Seal:<div class="sealspace"></div></td>
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
<tr><td><b class="t">For HHC:</b><br>Signature: ___________________<br>Name: Mr. Sagar Shekhar<br>Date: ___________________</td>
<td><b class="t">Surgeon:</b><br>Signature: ___________________<br>Name: Dr. {{candidate_name}}<br>Date:………………………………..</td></tr>
</table>
<img class="lh-screen lh-foot" src="{{letterhead_footer_src}}" alt="">
</div>
', 1, 1,
       COALESCE((SELECT id FROM users WHERE role = 'SUPER_ADMIN' ORDER BY id LIMIT 1), 1);

-- ---------------------------------------------------------------------
-- Check (should show exactly ONE active CONSULTANT_AGREEMENT row, and HHCPL / 1630 for EMPLOYEE)
-- ---------------------------------------------------------------------
SELECT id, template_type, template_name, is_active, is_default FROM rec_letter_templates WHERE template_type = 'CONSULTANT_AGREEMENT';
SELECT code_type, prefix, padding, last_number FROM employee_code_sequences;
