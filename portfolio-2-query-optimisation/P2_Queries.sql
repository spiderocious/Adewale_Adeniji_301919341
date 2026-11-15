-- ============================================================================
-- Portfolio 2 - Query Processing and Optimisation (RemoteFund)
-- Realistic business queries over the Portfolio 1 schema, each shown with its
-- execution plan via EXPLAIN (ANALYZE, BUFFERS).
-- Run against the loaded database:  psql -d remotefund -f P2_Queries.sql
-- ============================================================================

SET search_path TO remotefund;

\echo '================================================================'
\echo 'Query 1: Every disbursed loan with the employee who received it'
\echo '         (join across employee -> loan_application -> disbursement)'
\echo '================================================================'
SELECT e.full_name,
       e.employment_country,
       la.application_ref,
       la.requested_amount,
       d.disbursed_amount,
       d.channel
FROM employee e
JOIN loan_application la ON la.employee_id = e.employee_id
JOIN disbursement d      ON d.application_id = la.application_id
ORDER BY d.disbursed_at;

EXPLAIN (ANALYZE, BUFFERS)
SELECT e.full_name, la.application_ref, d.disbursed_amount
FROM employee e
JOIN loan_application la ON la.employee_id = e.employee_id
JOIN disbursement d      ON d.application_id = la.application_id
ORDER BY d.disbursed_at;

\echo ''
\echo '================================================================'
\echo 'Query 2: Total amount still outstanding per loan'
\echo '         (aggregate: sum of scheduled repayments grouped by loan)'
\echo '================================================================'
SELECT la.application_ref,
       la.status,
       COALESCE(SUM(r.amount_due) FILTER (WHERE r.status = 'scheduled'), 0) AS outstanding,
       COALESCE(SUM(r.amount_due) FILTER (WHERE r.status = 'paid'), 0)      AS repaid
FROM loan_application la
LEFT JOIN repayment r ON r.application_id = la.application_id
GROUP BY la.application_ref, la.status
ORDER BY outstanding DESC;

\echo ''
\echo '================================================================'
\echo 'Query 3: Applications submitted in 2026 Q1, newest first'
\echo '         (range filter on a timestamp)'
\echo '================================================================'
SELECT application_ref, employee_id, requested_amount, submitted_at, status
FROM loan_application
WHERE submitted_at >= TIMESTAMPTZ '2026-01-01'
  AND submitted_at <  TIMESTAMPTZ '2026-04-01'
ORDER BY submitted_at DESC;
