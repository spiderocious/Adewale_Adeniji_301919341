# Portfolio 2 — Query Processing and Optimisation

Case study: **RemoteFund.** Realistic business queries over the Portfolio 1 schema, each
shown with its execution plan, plus a before/after indexing demonstration.

## Files
- `P2_Queries.sql` — three business queries with `EXPLAIN (ANALYZE, BUFFERS)`:
  1. a 3-table **join** (employee → loan_application → disbursement) listing disbursed loans;
  2. an **aggregate** (outstanding vs repaid per loan) using `SUM … FILTER`;
  3. a **range filter** on `submitted_at` (Q1 2026 applications).
- `P2_Optimisation.sql` — builds a 50,000-row performance table and measures a selective
  lookup **before vs after** adding a B-tree index.
- `screenshots/P2_output.txt` — captured plans and timings.

## How to run
```bash
psql -d remotefund -f P2_Queries.sql
psql -d remotefund -f P2_Optimisation.sql
```

## Result (measured on PostgreSQL 18.1, 50,000 rows)
| | Plan | Execution time |
| --- | --- | --- |
| **Before index** | `Seq Scan` — 49,999 rows removed by filter | **1.756 ms** |
| **After index** | `Index Scan using idx_perf_app_ref` | **0.028 ms** |

Adding the index changed the plan from a sequential scan to an index scan and cut the
lookup time by roughly **60×**. The lesson: the same correct answer can cost very different
amounts of work, so the execution plan matters as much as the result.
