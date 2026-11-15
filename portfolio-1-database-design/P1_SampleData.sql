-- ============================================================================
-- Portfolio 1 - sample data for the RemoteFund case study.
-- Loads a small, realistic set of rows so the later portfolios have data to work on.
-- Run after P1_Schema.sql:  psql -d remotefund -f P1_SampleData.sql
-- ============================================================================

SET search_path TO remotefund;

-- Employees (remote workers in different countries).
INSERT INTO employee (full_name, work_email, employment_country, hired_date, monthly_income, is_active) VALUES
 ('Ava Morgan',    'ava.morgan@remotefund.test',   'Canada',    DATE '2022-03-14', 4200.00, TRUE),
 ('Liam Chen',     'liam.chen@remotefund.test',    'Singapore', DATE '2021-08-22', 5100.00, TRUE),
 ('Nora Silva',    'nora.silva@remotefund.test',   'Portugal',  DATE '2023-01-09', 3000.00, FALSE),
 ('Tunde Bello',   'tunde.bello@remotefund.test',  'Nigeria',   DATE '2023-06-30', 2600.00, TRUE),
 ('Priya Nair',    'priya.nair@remotefund.test',   'India',     DATE '2020-11-02', 3800.00, TRUE);

-- Loan applications (various lifecycle states).
INSERT INTO loan_application (employee_id, application_ref, requested_amount, term_months, submitted_at, status, decision_date) VALUES
 (1, 'APP-1001', 5000.00, 12, TIMESTAMPTZ '2026-01-15 09:30+00', 'submitted', NULL),
 (2, 'APP-1002', 3200.00,  6, TIMESTAMPTZ '2026-02-10 14:00+00', 'approved',  DATE '2026-02-15'),
 (3, 'APP-1003', 1800.00,  3, TIMESTAMPTZ '2026-03-05 11:15+00', 'rejected',  DATE '2026-03-08'),
 (4, 'APP-1004', 2500.00,  9, TIMESTAMPTZ '2026-03-20 08:45+00', 'disbursed', DATE '2026-03-22'),
 (5, 'APP-1005', 4000.00, 18, TIMESTAMPTZ '2026-04-01 10:00+00', 'closed',    DATE '2026-04-03');

-- Disbursements (only for approved/disbursed/closed loans).
INSERT INTO disbursement (application_id, disbursed_amount, disbursed_at, channel) VALUES
 (4, 2500.00, TIMESTAMPTZ '2026-03-22 12:00+00', 'mobile_money'),
 (5, 4000.00, TIMESTAMPTZ '2026-04-03 09:00+00', 'bank_transfer');

-- Repayment schedules.
INSERT INTO repayment (application_id, due_date, amount_due, paid_at, status) VALUES
 (4, DATE '2026-04-22', 300.00, TIMESTAMPTZ '2026-04-21 10:00+00', 'paid'),
 (4, DATE '2026-05-22', 300.00, NULL, 'scheduled'),
 (5, DATE '2026-05-03', 250.00, TIMESTAMPTZ '2026-05-02 09:00+00', 'paid'),
 (5, DATE '2026-06-03', 250.00, NULL, 'scheduled');

\echo '--- Row counts after load ---'
SELECT 'employee'        AS table, count(*) FROM employee
UNION ALL SELECT 'loan_application', count(*) FROM loan_application
UNION ALL SELECT 'disbursement',     count(*) FROM disbursement
UNION ALL SELECT 'repayment',        count(*) FROM repayment
ORDER BY 1;
