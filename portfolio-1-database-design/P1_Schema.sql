-- ============================================================================
-- MIT 8103 Advanced Database Systems - Portfolio 1
-- Case study: RemoteFund - a data-loan fintech for remote workers
-- Relational schema: tables, keys, and business constraints (PostgreSQL)
-- Run once against a fresh database:  createdb remotefund && psql -d remotefund -f P1_Schema.sql
-- ============================================================================

BEGIN;

-- A dedicated schema keeps the case tables separate from anything else.
CREATE SCHEMA IF NOT EXISTS remotefund;
SET search_path TO remotefund;

-- ----------------------------------------------------------------------------
-- employee: the remote worker who applies for a data loan.
-- ----------------------------------------------------------------------------
CREATE TABLE employee (
    employee_id       BIGINT       GENERATED ALWAYS AS IDENTITY,
    full_name         TEXT         NOT NULL,
    work_email        TEXT         NOT NULL,
    employment_country TEXT        NOT NULL,
    hired_date        DATE         NOT NULL,
    monthly_income    NUMERIC(14,2) NOT NULL,
    is_active         BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_employee PRIMARY KEY (employee_id),
    CONSTRAINT uq_employee_work_email UNIQUE (work_email),
    CONSTRAINT ck_employee_income_positive CHECK (monthly_income > 0),
    CONSTRAINT ck_employee_email_format CHECK (work_email LIKE '%@%.%')
);

-- ----------------------------------------------------------------------------
-- loan_application: a request for a data loan from an employee.
-- status drives the lifecycle: submitted -> approved/rejected -> disbursed -> closed
-- ----------------------------------------------------------------------------
CREATE TABLE loan_application (
    application_id    BIGINT        GENERATED ALWAYS AS IDENTITY,
    employee_id       BIGINT        NOT NULL,
    application_ref   TEXT          NOT NULL,
    requested_amount  NUMERIC(14,2) NOT NULL,
    term_months       INTEGER       NOT NULL,
    submitted_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    status            TEXT          NOT NULL DEFAULT 'submitted',
    decision_date     DATE,
    CONSTRAINT pk_loan_application PRIMARY KEY (application_id),
    CONSTRAINT uq_loan_application_ref UNIQUE (application_ref),
    CONSTRAINT fk_loan_application_employee
        FOREIGN KEY (employee_id) REFERENCES employee (employee_id),
    CONSTRAINT ck_loan_amount_positive CHECK (requested_amount > 0),
    CONSTRAINT ck_loan_term_valid CHECK (term_months BETWEEN 1 AND 36),
    CONSTRAINT ck_loan_status_valid
        CHECK (status IN ('submitted','approved','rejected','disbursed','closed'))
);

-- Business rule: an employee may have at most ONE application that is still in
-- flight (submitted or approved). A partial unique index expresses this cleanly.
CREATE UNIQUE INDEX uq_one_open_application_per_employee
    ON loan_application (employee_id)
    WHERE status IN ('submitted','approved');

-- ----------------------------------------------------------------------------
-- disbursement: the money actually paid out for an approved application.
-- One disbursement per application (a 1:1 that only exists once approved).
-- ----------------------------------------------------------------------------
CREATE TABLE disbursement (
    disbursement_id   BIGINT        GENERATED ALWAYS AS IDENTITY,
    application_id    BIGINT        NOT NULL,
    disbursed_amount  NUMERIC(14,2) NOT NULL,
    disbursed_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    channel           TEXT          NOT NULL,
    CONSTRAINT pk_disbursement PRIMARY KEY (disbursement_id),
    CONSTRAINT uq_disbursement_application UNIQUE (application_id),
    CONSTRAINT fk_disbursement_application
        FOREIGN KEY (application_id) REFERENCES loan_application (application_id),
    CONSTRAINT ck_disbursement_amount_positive CHECK (disbursed_amount > 0),
    CONSTRAINT ck_disbursement_channel
        CHECK (channel IN ('bank_transfer','mobile_money','wallet'))
);

-- ----------------------------------------------------------------------------
-- repayment: the scheduled / actual repayments against a loan.
-- ----------------------------------------------------------------------------
CREATE TABLE repayment (
    repayment_id      BIGINT        GENERATED ALWAYS AS IDENTITY,
    application_id    BIGINT        NOT NULL,
    due_date          DATE          NOT NULL,
    amount_due        NUMERIC(14,2) NOT NULL,
    paid_at           TIMESTAMPTZ,
    status            TEXT          NOT NULL DEFAULT 'scheduled',
    CONSTRAINT pk_repayment PRIMARY KEY (repayment_id),
    -- a loan cannot have two repayments on the same due date
    CONSTRAINT uq_repayment_schedule UNIQUE (application_id, due_date),
    CONSTRAINT fk_repayment_application
        FOREIGN KEY (application_id) REFERENCES loan_application (application_id),
    CONSTRAINT ck_repayment_amount_positive CHECK (amount_due > 0),
    CONSTRAINT ck_repayment_status_valid
        CHECK (status IN ('scheduled','paid','overdue'))
);

COMMIT;

-- Quick confirmation that the four tables now exist.
\echo '--- Tables created in schema remotefund ---'
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'remotefund'
ORDER BY table_name;
