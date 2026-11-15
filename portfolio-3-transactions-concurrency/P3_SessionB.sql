-- ============================================================================
-- Portfolio 3 - Concurrency, SESSION B  (run alongside P3_SessionA.sql)
-- Follow the numbered order, alternating with Session A.
-- ============================================================================
SET search_path TO remotefund;

-- ===== PART 1: THE LOST UPDATE (no locking) =====

-- 2. (B) Read the current balance BEFORE A commits (still 2000).
BEGIN;
SELECT loan_balance FROM loan_application WHERE application_ref = 'APP-1004';   -- reads 2000

-- 4. (B) Write 2000 - 100 = 1900 from B's stale read, then commit.
UPDATE loan_application SET loan_balance = 1900 WHERE application_ref = 'APP-1004';
COMMIT;
SELECT loan_balance FROM loan_application WHERE application_ref = 'APP-1004';   -- shows 1900, not 1800
-- Both officers recorded a 100 repayment, but the balance only dropped by 100. One update was LOST.

-- ===== PART 2: THE FIX (SELECT ... FOR UPDATE) =====

-- 7. (B) Request the SAME row with FOR UPDATE. A holds the lock, so this WAITS.
BEGIN;
SELECT loan_balance FROM loan_application WHERE application_ref = 'APP-1004' FOR UPDATE;
-- This statement blocks until A commits in step 8, then returns A's committed value (1900).

-- 9. (B) B now reads 1900, subtracts its 100 (1800) and commits. No update is lost.
UPDATE loan_application SET loan_balance = 1800 WHERE application_ref = 'APP-1004';
COMMIT;
SELECT loan_balance FROM loan_application WHERE application_ref = 'APP-1004';   -- shows 1800
