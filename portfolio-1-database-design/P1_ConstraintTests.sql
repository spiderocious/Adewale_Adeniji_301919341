-- ============================================================================
-- Portfolio 1 - constraint tests for the RemoteFund case study.
-- Each statement below BREAKS a rule on purpose and must be REJECTED by PostgreSQL.
-- We wrap each one so a failure is reported but the script keeps running, and the
-- valid sample rows from P1_SampleData.sql are never changed.
-- Run after schema + sample data:  psql -d remotefund -f P1_ConstraintTests.sql
-- ============================================================================

SET search_path TO remotefund;
\set ON_ERROR_STOP off
\echo ''
\echo '=== Each test should FAIL with a constraint violation (that is the pass). ==='
\echo ''

-- 1. PRIMARY KEY / NOT NULL: missing required full_name.
\echo 'Test 1: NOT NULL on employee.full_name'
INSERT INTO employee (full_name, work_email, employment_country, hired_date, monthly_income)
VALUES (NULL, 't1@remotefund.test', 'Kenya', DATE '2024-01-01', 2000);

-- 2. UNIQUE: duplicate work_email (ava.morgan already exists).
\echo 'Test 2: UNIQUE on employee.work_email'
INSERT INTO employee (full_name, work_email, employment_country, hired_date, monthly_income)
VALUES ('Clone Ava', 'ava.morgan@remotefund.test', 'Kenya', DATE '2024-01-01', 2000);

-- 3. CHECK: non-positive monthly_income.
\echo 'Test 3: CHECK monthly_income > 0'
INSERT INTO employee (full_name, work_email, employment_country, hired_date, monthly_income)
VALUES ('Zero Pay', 'zero@remotefund.test', 'Kenya', DATE '2024-01-01', 0);

-- 4. CHECK: malformed email (no @).
\echo 'Test 4: CHECK email format'
INSERT INTO employee (full_name, work_email, employment_country, hired_date, monthly_income)
VALUES ('Bad Email', 'not-an-email', 'Kenya', DATE '2024-01-01', 2000);

-- 5. FOREIGN KEY: application for a non-existent employee (id 999).
\echo 'Test 5: FOREIGN KEY loan_application.employee_id'
INSERT INTO loan_application (employee_id, application_ref, requested_amount, term_months)
VALUES (999, 'APP-BAD1', 1000, 6);

-- 6. CHECK: negative requested_amount.
\echo 'Test 6: CHECK requested_amount > 0'
INSERT INTO loan_application (employee_id, application_ref, requested_amount, term_months)
VALUES (1, 'APP-BAD2', -500, 6);

-- 7. CHECK: term_months out of the 1..36 range.
\echo 'Test 7: CHECK term_months BETWEEN 1 AND 36'
INSERT INTO loan_application (employee_id, application_ref, requested_amount, term_months)
VALUES (1, 'APP-BAD3', 1000, 48);

-- 8. CHECK: invalid status value.
\echo 'Test 8: CHECK status IN (...)'
INSERT INTO loan_application (employee_id, application_ref, requested_amount, term_months, status)
VALUES (1, 'APP-BAD4', 1000, 6, 'pending-review');

-- 9. PARTIAL UNIQUE: a second OPEN application for employee 1 (already has submitted APP-1001).
\echo 'Test 9: partial unique - one open application per employee'
INSERT INTO loan_application (employee_id, application_ref, requested_amount, term_months, status)
VALUES (1, 'APP-BAD5', 2000, 6, 'approved');

-- 10. UNIQUE (composite): duplicate repayment on the same application+due_date.
\echo 'Test 10: UNIQUE (application_id, due_date) on repayment'
INSERT INTO repayment (application_id, due_date, amount_due)
VALUES (4, DATE '2026-04-22', 300);

-- 11. CHECK: invalid disbursement channel.
\echo 'Test 11: CHECK disbursement.channel IN (...)'
INSERT INTO disbursement (application_id, disbursed_amount, channel)
VALUES (1, 1000, 'cash_in_hand');

-- 12. UNIQUE: a second disbursement for an application that already has one (id 4).
\echo 'Test 12: UNIQUE disbursement.application_id (one disbursement per loan)'
INSERT INTO disbursement (application_id, disbursed_amount, channel)
VALUES (4, 500, 'wallet');

\set ON_ERROR_STOP on
\echo ''
\echo '=== Control check: the valid sample rows are untouched ==='
SELECT (SELECT count(*) FROM employee)         AS employees,
       (SELECT count(*) FROM loan_application)  AS applications,
       (SELECT count(*) FROM disbursement)      AS disbursements,
       (SELECT count(*) FROM repayment)         AS repayments;
