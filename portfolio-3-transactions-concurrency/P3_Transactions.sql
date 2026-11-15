-- ============================================================================
-- Portfolio 3 - Transactions and Concurrency (RemoteFund)
-- Part A: COMMIT, ROLLBACK and isolation shown in a single session.
-- We add a small helper column, loan_balance, to loan_application so we can move
-- a value around safely. It belongs only to this exercise, not the P1 design.
-- Run against the loaded database:  psql -d remotefund -f P3_Transactions.sql
-- ============================================================================

SET search_path TO remotefund;

-- Helper column for the exercise (idempotent).
ALTER TABLE loan_application ADD COLUMN IF NOT EXISTS loan_balance NUMERIC(14,2) NOT NULL DEFAULT 0;
UPDATE loan_application SET loan_balance = requested_amount;

\echo '=== Starting balance for application APP-1004 ==='
SELECT application_ref, loan_balance FROM loan_application WHERE application_ref = 'APP-1004';

\echo ''
\echo '=== COMMIT: a repayment of 500 is applied and made permanent ==='
BEGIN;
UPDATE loan_application SET loan_balance = loan_balance - 500 WHERE application_ref = 'APP-1004'
  RETURNING application_ref, loan_balance;
COMMIT;
SELECT application_ref, loan_balance FROM loan_application WHERE application_ref = 'APP-1004';

\echo ''
\echo '=== ROLLBACK: a mistaken repayment of 9999 is undone ==='
BEGIN;
UPDATE loan_application SET loan_balance = loan_balance - 9999 WHERE application_ref = 'APP-1004'
  RETURNING application_ref, loan_balance;
\echo '(inside the transaction the balance looks changed...)'
SELECT application_ref, loan_balance FROM loan_application WHERE application_ref = 'APP-1004';
ROLLBACK;
\echo '(...but after ROLLBACK the committed value is restored)'
SELECT application_ref, loan_balance FROM loan_application WHERE application_ref = 'APP-1004';

\echo ''
\echo '=== ISOLATION (READ COMMITTED): a transaction only sees committed data ==='
\echo 'See P3_SessionA.sql and P3_SessionB.sql for the two-terminal demonstration.'
