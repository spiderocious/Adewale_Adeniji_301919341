-- ============================================================================
-- Portfolio 2 - Indexing / optimisation demonstration (RemoteFund)
-- We build a larger, realistic table of loan applications (50,000 rows) and show
-- how adding a B-tree index on the column we filter by changes the execution
-- plan from a sequential scan to an index scan, and the measured time with it.
-- Run after P2_Queries.sql:  psql -d remotefund -f P2_Optimisation.sql
-- ============================================================================

SET search_path TO remotefund;

-- A performance table that mirrors the real loan_application shape but holds
-- enough rows to make an index matter. Business constraints stay in Portfolio 1.
DROP TABLE IF EXISTS perf_loan_application;
CREATE TABLE perf_loan_application (
    application_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id      BIGINT NOT NULL,
    application_ref  TEXT   NOT NULL,
    requested_amount NUMERIC(14,2) NOT NULL,
    status           TEXT   NOT NULL
);

-- 50,000 synthetic applications across 5,000 employees.
INSERT INTO perf_loan_application (employee_id, application_ref, requested_amount, status)
SELECT (g % 5000) + 1,
       'REF-' || g,
       ((g % 90) + 10) * 100.0,
       (ARRAY['submitted','approved','rejected','disbursed','closed'])[(g % 5) + 1]
FROM generate_series(1, 50000) AS g;

ANALYZE perf_loan_application;
\echo 'Loaded 50,000 rows into perf_loan_application.'

\echo ''
\echo '=== BEFORE INDEX: lookup by application_ref (expect a sequential scan) ==='
-- warm up once (not measured), then measure.
SELECT application_id, requested_amount FROM perf_loan_application WHERE application_ref = 'REF-42042';
EXPLAIN (ANALYZE, BUFFERS)
SELECT application_id, requested_amount FROM perf_loan_application WHERE application_ref = 'REF-42042';

\echo ''
\echo '=== Creating a B-tree index on application_ref ==='
CREATE INDEX idx_perf_app_ref ON perf_loan_application (application_ref);
ANALYZE perf_loan_application;

\echo ''
\echo '=== AFTER INDEX: same lookup (expect an index scan, much faster) ==='
SELECT application_id, requested_amount FROM perf_loan_application WHERE application_ref = 'REF-42042';
EXPLAIN (ANALYZE, BUFFERS)
SELECT application_id, requested_amount FROM perf_loan_application WHERE application_ref = 'REF-42042';
