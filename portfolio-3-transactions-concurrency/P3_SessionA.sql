-- ============================================================================
-- Portfolio 3 - Concurrency, SESSION A
-- Open TWO psql terminals on the remotefund database and run the numbered steps
-- in order, alternating between Session A and Session B.
--
-- Scenario: two loan officers each record a 100 repayment on APP-1004 at the same
-- time. Without locking, one update is lost. With SELECT ... FOR UPDATE it is not.
-- ============================================================================
SET search_path TO remotefund;

-- 0. (A) Reset the balance to a known starting point: 2000.
UPDATE loan_application SET loan_balance = 2000 WHERE application_ref = 'APP-1004';

-- ===== PART 1: THE LOST UPDATE (no locking) =====

-- 1. (A) Read the current balance (2000).
BEGIN;
SELECT loan_balance FROM loan_application WHERE application_ref = 'APP-1004';   -- reads 2000

-- 3. (A) Write 2000 - 100 = 1900 based on the value A read, then commit.
UPDATE loan_application SET loan_balance = 1900 WHERE application_ref = 'APP-1004';
COMMIT;
-- Final value after both commit is 1900, so B's 100 repayment was LOST.

-- ===== PART 2: THE FIX (SELECT ... FOR UPDATE) =====

-- 5. (A) Reset the balance to 2000 again (run outside a transaction).
UPDATE loan_application SET loan_balance = 2000 WHERE application_ref = 'APP-1004';

-- 6. (A) Lock the row, then read it (2000).
BEGIN;
SELECT loan_balance FROM loan_application WHERE application_ref = 'APP-1004' FOR UPDATE;  -- reads 2000

-- 8. (A) Apply A's 100 repayment (1900) and commit to release the lock.
UPDATE loan_application SET loan_balance = 1900 WHERE application_ref = 'APP-1004';
COMMIT;
-- Now B's locked SELECT unblocks and sees 1900, so B subtracts to 1800. Nothing lost.
