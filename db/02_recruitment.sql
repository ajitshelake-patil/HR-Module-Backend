-- =====================================================================
-- RECRUITMENT MODULE - MySQL 8 schema
-- Assumes existing masters: users, departments, designations, locations
-- (adjust FK names if your tables differ)
-- =====================================================================

-- ---------------------------------------------------------------------
-- STEP 1 : Candidate Registration & Resume Upload
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS rec_candidates (
  id                     BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  candidate_code         VARCHAR(20)  NOT NULL UNIQUE,          -- e.g. CAND-2026-00001
  candidate_type         ENUM('EMPLOYEE','CONSULTANT') NOT NULL DEFAULT 'EMPLOYEE',
  first_name             VARCHAR(60)  NOT NULL,
  middle_name            VARCHAR(60)  NULL,
  last_name              VARCHAR(60)  NOT NULL,
  gender                 ENUM('MALE','FEMALE','OTHER') NULL,
  date_of_birth          DATE NULL,
  mobile_no              VARCHAR(15)  NOT NULL,
  alternate_mobile_no    VARCHAR(15)  NULL,
  email                  VARCHAR(120) NOT NULL,
  address                VARCHAR(255) NULL,
  city                   VARCHAR(60)  NULL,
  state                  VARCHAR(60)  NULL,
  pincode                VARCHAR(10)  NULL,
  highest_qualification  VARCHAR(100) NULL,
  specialization         VARCHAR(100) NULL,              -- e.g. MS General Surgery
  total_experience_years DECIMAL(4,1) NULL,
  current_employer       VARCHAR(150) NULL,
  current_ctc            DECIMAL(12,2) NULL,
  expected_ctc           DECIMAL(12,2) NULL,
  notice_period_days     SMALLINT NULL,
  applied_department_id  INT UNSIGNED NULL,
  applied_designation_id INT UNSIGNED NULL,
  applied_location_id    INT UNSIGNED NULL,
  source                 ENUM('REFERRAL','JOB_PORTAL','WALK_IN','CONSULTANCY','WEBSITE','OTHER') NULL,
  source_remarks         VARCHAR(150) NULL,
  resume_file_path       VARCHAR(255) NULL,
  resume_original_name   VARCHAR(150) NULL,
  status ENUM(
    'REGISTERED','SELECTED','CTC_PENDING_APPROVAL','CTC_APPROVED','CTC_REJECTED',
    'OFFER_SENT','OFFER_ACCEPTED','OFFER_DECLINED',
    'AGREEMENT_GENERATED','DOCS_PENDING','DOCS_VERIFIED','ONBOARDED'
  ) NOT NULL DEFAULT 'REGISTERED',
  created_by             INT UNSIGNED NOT NULL,
  created_at             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_by             INT UNSIGNED NULL,
  updated_at             DATETIME NULL ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_cand_status (status),
  INDEX idx_cand_mobile (mobile_no),
  INDEX idx_cand_email (email)
);

-- Audit of every status change (drives the timeline on candidate view)
CREATE TABLE IF NOT EXISTS rec_candidate_status_log (
  id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  candidate_id  BIGINT UNSIGNED NOT NULL,
  from_status   VARCHAR(30) NULL,
  to_status     VARCHAR(30) NOT NULL,
  remarks       VARCHAR(255) NULL,
  changed_by    INT UNSIGNED NULL,           -- NULL when candidate acts via portal
  changed_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (candidate_id) REFERENCES rec_candidates(id)
);

-- ---------------------------------------------------------------------
-- STEP 2 : Candidate Selection & CTC Entry   (Manager)
-- STEP 3 : CTC Approval                       (Super Admin)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS rec_ctc_proposals (
  id                      BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  candidate_id            BIGINT UNSIGNED NOT NULL,
  version_no              TINYINT UNSIGNED NOT NULL DEFAULT 1,   -- increments on re-submission after rejection
  interview_date          DATE NULL,
  interviewed_by          INT UNSIGNED NULL,
  selection_remarks       VARCHAR(500) NULL,
  department_id           INT UNSIGNED NOT NULL,
  designation_id          INT UNSIGNED NOT NULL,
  location_id             INT UNSIGNED NOT NULL,
  reporting_manager_id    INT UNSIGNED NULL,
  employment_type         ENUM('PERMANENT','PROBATION','CONTRACT','CONSULTANT') NOT NULL DEFAULT 'PROBATION',
  probation_months        TINYINT UNSIGNED NULL,
  proposed_joining_date   DATE NULL,
  -- SALARY  = employee (uses component breakup below)
  -- CONSULTANT_FEE = surgeon (uses fee fields below)
  compensation_type       ENUM('SALARY','CONSULTANT_FEE') NOT NULL DEFAULT 'SALARY',
  gross_monthly           DECIMAL(12,2) NOT NULL DEFAULT 0,
  employer_contrib_monthly DECIMAL(12,2) NOT NULL DEFAULT 0,
  ctc_monthly             DECIMAL(12,2) NOT NULL DEFAULT 0,
  ctc_annual              DECIMAL(14,2) NOT NULL DEFAULT 0,
  net_take_home_monthly   DECIMAL(12,2) NULL,
  -- Consultant (surgeon) fee terms - approved by Super Admin same as CTC
  fee_type                ENUM('FIXED_MONTHLY','PER_CASE','REVENUE_SHARE','HYBRID') NULL,
  fixed_monthly_fee       DECIMAL(12,2) NULL,
  per_case_fee            DECIMAL(12,2) NULL,
  revenue_share_percent   DECIMAL(5,2)  NULL,
  minimum_guarantee       DECIMAL(12,2) NULL,
  status ENUM('DRAFT','SUBMITTED','APPROVED','REJECTED','SENT_BACK') NOT NULL DEFAULT 'DRAFT',
  submitted_by            INT UNSIGNED NULL,
  submitted_at            DATETIME NULL,
  approved_by             INT UNSIGNED NULL,
  approved_at             DATETIME NULL,
  approval_remarks        VARCHAR(500) NULL,
  created_by              INT UNSIGNED NOT NULL,
  created_at              DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at              DATETIME NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_cand_version (candidate_id, version_no),
  INDEX idx_ctc_status (status),
  FOREIGN KEY (candidate_id) REFERENCES rec_candidates(id)
);

-- Salary component master (Basic, HRA, Conveyance, PF, ESIC, Gratuity...)
CREATE TABLE IF NOT EXISTS rec_salary_components (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  component_code  VARCHAR(20)  NOT NULL UNIQUE,
  component_name  VARCHAR(80)  NOT NULL,
  component_group ENUM('EARNING','EMPLOYER_CONTRIBUTION','EMPLOYEE_DEDUCTION') NOT NULL,
  calc_type       ENUM('FIXED','PERCENT_OF_BASIC','PERCENT_OF_GROSS','BALANCE') NOT NULL DEFAULT 'FIXED',
  calc_value      DECIMAL(8,2) NULL,
  display_order   SMALLINT NOT NULL DEFAULT 0,
  is_active       TINYINT(1) NOT NULL DEFAULT 1
);

-- Component-wise breakup -> becomes the CTC Annexure
CREATE TABLE IF NOT EXISTS rec_ctc_proposal_components (
  id               BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  ctc_proposal_id  BIGINT UNSIGNED NOT NULL,
  component_id     INT UNSIGNED NOT NULL,
  monthly_amount   DECIMAL(12,2) NOT NULL DEFAULT 0,
  annual_amount    DECIMAL(14,2) NOT NULL DEFAULT 0,
  UNIQUE KEY uq_prop_comp (ctc_proposal_id, component_id),
  FOREIGN KEY (ctc_proposal_id) REFERENCES rec_ctc_proposals(id) ON DELETE CASCADE,
  FOREIGN KEY (component_id)    REFERENCES rec_salary_components(id)
);

-- Approval history (every submit / approve / reject / send-back)
CREATE TABLE IF NOT EXISTS rec_ctc_approval_log (
  id               BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  ctc_proposal_id  BIGINT UNSIGNED NOT NULL,
  action           ENUM('SUBMITTED','APPROVED','REJECTED','SENT_BACK') NOT NULL,
  remarks          VARCHAR(500) NULL,
  action_by        INT UNSIGNED NOT NULL,
  action_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (ctc_proposal_id) REFERENCES rec_ctc_proposals(id)
);

-- ---------------------------------------------------------------------
-- Letter templates (Offer / Consultant Agreement / Appointment)
-- body uses placeholders like {{candidate_name}}, {{designation}}, {{ctc_annual}}
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS rec_letter_templates (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  template_type   ENUM('OFFER_LETTER','CONSULTANT_AGREEMENT','APPOINTMENT_LETTER') NOT NULL,
  template_name   VARCHAR(100) NOT NULL,
  body_html       MEDIUMTEXT NOT NULL,
  is_default      TINYINT(1) NOT NULL DEFAULT 0,
  is_active       TINYINT(1) NOT NULL DEFAULT 1,
  created_by      INT UNSIGNED NOT NULL,
  created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME NULL ON UPDATE CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------------
-- STEP 4a : Offer Letter (Employee)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS rec_offer_letters (
  id                   BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  offer_letter_no      VARCHAR(30) NOT NULL UNIQUE,       -- e.g. HHC/OL/2026/0001
  candidate_id         BIGINT UNSIGNED NOT NULL,
  ctc_proposal_id      BIGINT UNSIGNED NOT NULL,          -- must be APPROVED
  template_id          INT UNSIGNED NOT NULL,
  offer_date           DATE NOT NULL,
  joining_date         DATE NOT NULL,
  offer_valid_till     DATE NOT NULL,
  pdf_file_path        VARCHAR(255) NULL,
  access_token         CHAR(64) NOT NULL UNIQUE,          -- secure link for candidate to view/accept
  token_expires_at     DATETIME NOT NULL,
  sent_via             SET('EMAIL','SMS','WHATSAPP') NULL,
  sent_by              INT UNSIGNED NULL,
  sent_at              DATETIME NULL,
  candidate_response   ENUM('PENDING','ACCEPTED','DECLINED','EXPIRED') NOT NULL DEFAULT 'PENDING',
  response_at          DATETIME NULL,
  response_ip          VARCHAR(45) NULL,
  decline_reason       VARCHAR(500) NULL,
  created_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (candidate_id)    REFERENCES rec_candidates(id),
  FOREIGN KEY (ctc_proposal_id) REFERENCES rec_ctc_proposals(id),
  FOREIGN KEY (template_id)     REFERENCES rec_letter_templates(id)
);

-- ---------------------------------------------------------------------
-- STEP 4b : Consultant Agreement (Surgeon)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS rec_consultant_agreements (
  id                     BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  agreement_no           VARCHAR(30) NOT NULL UNIQUE,     -- e.g. HHC/CA/2026/0001
  candidate_id           BIGINT UNSIGNED NOT NULL,
  ctc_proposal_id        BIGINT UNSIGNED NOT NULL,   -- must be APPROVED; fee terms come from here
  template_id            INT UNSIGNED NOT NULL,
  speciality             VARCHAR(100) NULL,
  medical_council_reg_no VARCHAR(50)  NULL,
  location_id            INT UNSIGNED NOT NULL,
  agreement_start_date   DATE NOT NULL,
  agreement_end_date     DATE NULL,
  notice_period_days     SMALLINT NULL,
  pdf_file_path          VARCHAR(255) NULL,
  status ENUM('DRAFT','GENERATED','SENT','SIGNED','CANCELLED') NOT NULL DEFAULT 'DRAFT',
  signed_copy_path       VARCHAR(255) NULL,
  signed_on              DATE NULL,
  generated_by           INT UNSIGNED NOT NULL,
  generated_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (candidate_id)    REFERENCES rec_candidates(id),
  FOREIGN KEY (ctc_proposal_id) REFERENCES rec_ctc_proposals(id),
  FOREIGN KEY (template_id)     REFERENCES rec_letter_templates(id)
);

-- ---------------------------------------------------------------------
-- STEP 5 : Document Verification
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS rec_document_types (
  id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  document_name       VARCHAR(100) NOT NULL,            -- Aadhaar, PAN, Degree, Relieving Letter...
  applicable_to       ENUM('EMPLOYEE','CONSULTANT','BOTH') NOT NULL DEFAULT 'BOTH',
  is_mandatory        TINYINT(1) NOT NULL DEFAULT 1,
  requires_number     TINYINT(1) NOT NULL DEFAULT 0,    -- capture doc number (PAN no, reg no)
  display_order       SMALLINT NOT NULL DEFAULT 0,
  is_active           TINYINT(1) NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS rec_candidate_documents (
  id                   BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  candidate_id         BIGINT UNSIGNED NOT NULL,
  document_type_id     INT UNSIGNED NOT NULL,
  document_number      VARCHAR(60) NULL,                 -- store masked/encrypted for Aadhaar
  file_path            VARCHAR(255) NOT NULL,
  original_file_name   VARCHAR(150) NULL,
  uploaded_by_type     ENUM('HR','CANDIDATE') NOT NULL DEFAULT 'HR',
  uploaded_by          INT UNSIGNED NULL,
  uploaded_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  verification_status  ENUM('PENDING','VERIFIED','REJECTED') NOT NULL DEFAULT 'PENDING',
  verified_by          INT UNSIGNED NULL,
  verified_at          DATETIME NULL,
  verification_remarks VARCHAR(255) NULL,
  INDEX idx_doc_cand (candidate_id),
  FOREIGN KEY (candidate_id)     REFERENCES rec_candidates(id),
  FOREIGN KEY (document_type_id) REFERENCES rec_document_types(id)
);

-- ---------------------------------------------------------------------
-- STEP 6 : Employee ID Generation
-- Use SELECT ... FOR UPDATE inside a transaction to avoid duplicate codes
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS employee_code_sequences (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code_type     ENUM('EMPLOYEE','CONSULTANT') NOT NULL UNIQUE,
  prefix        VARCHAR(10) NOT NULL,                  -- HHCPL (shared series)
  padding       TINYINT UNSIGNED NOT NULL DEFAULT 5,   -- HHCPL1631
  last_number   INT UNSIGNED NOT NULL DEFAULT 0,
  updated_at    DATETIME NULL ON UPDATE CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------------
-- STEP 7 : Employee Master
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS employees (
  id                    BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employee_code         VARCHAR(20) NOT NULL UNIQUE,
  candidate_id          BIGINT UNSIGNED NOT NULL UNIQUE,
  employee_category     ENUM('EMPLOYEE','CONSULTANT') NOT NULL,
  first_name            VARCHAR(60)  NOT NULL,
  middle_name           VARCHAR(60)  NULL,
  last_name             VARCHAR(60)  NOT NULL,
  gender                ENUM('MALE','FEMALE','OTHER') NULL,
  date_of_birth         DATE NULL,
  mobile_no             VARCHAR(15)  NOT NULL,
  official_email        VARCHAR(120) NULL,
  personal_email        VARCHAR(120) NULL,
  address               VARCHAR(255) NULL,
  city                  VARCHAR(60)  NULL,
  state                 VARCHAR(60)  NULL,
  pincode               VARCHAR(10)  NULL,
  department_id         INT UNSIGNED NOT NULL,
  designation_id        INT UNSIGNED NOT NULL,
  location_id           INT UNSIGNED NOT NULL,
  reporting_manager_id  INT UNSIGNED NULL,               -- users.id
  employment_type       ENUM('PERMANENT','PROBATION','CONTRACT','CONSULTANT') NOT NULL,
  date_of_joining       DATE NOT NULL,
  probation_end_date    DATE NULL,
  ctc_proposal_id       BIGINT UNSIGNED NOT NULL,      -- approved CTC / consultant fee
  offer_letter_id       BIGINT UNSIGNED NULL,          -- employees
  consultant_agreement_id BIGINT UNSIGNED NULL,        -- consultants
  ctc_annual            DECIMAL(14,2) NULL,
  status ENUM('ACTIVE','INACTIVE','RESIGNED','TERMINATED') NOT NULL DEFAULT 'ACTIVE',
  created_by            INT UNSIGNED NOT NULL,
  created_at            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at            DATETIME NULL ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_emp_status (status),
  FOREIGN KEY (candidate_id)            REFERENCES rec_candidates(id),
  FOREIGN KEY (ctc_proposal_id)         REFERENCES rec_ctc_proposals(id),
  FOREIGN KEY (offer_letter_id)         REFERENCES rec_offer_letters(id),
  FOREIGN KEY (consultant_agreement_id) REFERENCES rec_consultant_agreements(id)
);

-- ---------------------------------------------------------------------
-- STEP 8 : Appointment Letter with CTC Annexure
-- Annexure rows come from rec_ctc_proposal_components via ctc_proposal_id
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS rec_appointment_letters (
  id                    BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  appointment_letter_no VARCHAR(30) NOT NULL UNIQUE,     -- e.g. HHC/AL/2026/0001
  employee_id           BIGINT UNSIGNED NOT NULL,
  ctc_proposal_id       BIGINT UNSIGNED NOT NULL,
  template_id           INT UNSIGNED NOT NULL,
  letter_date           DATE NOT NULL,
  effective_date        DATE NOT NULL,
  pdf_file_path         VARCHAR(255) NULL,
  include_ctc_annexure  TINYINT(1) NOT NULL DEFAULT 1,
  issued_by             INT UNSIGNED NOT NULL,
  issued_at             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  emailed_at            DATETIME NULL,
  FOREIGN KEY (employee_id)     REFERENCES employees(id),
  FOREIGN KEY (ctc_proposal_id) REFERENCES rec_ctc_proposals(id),
  FOREIGN KEY (template_id)     REFERENCES rec_letter_templates(id)
);

