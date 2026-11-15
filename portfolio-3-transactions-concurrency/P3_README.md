# Portfolio 3 — Transactions and Concurrency

Case study: **RemoteFund.** Demonstrates COMMIT, ROLLBACK, isolation, and a real
concurrency anomaly with its fix, using a `loan_balance` helper column added only for
this exercise (the Portfolio 1 business columns are left unchanged).

## Files
- `P3_Transactions.sql` — single-session demo of **COMMIT**, **ROLLBACK**, and READ COMMITTED isolation.
- `P3_SessionA.sql` / `P3_SessionB.sql` — a **two-terminal** demonstration of the lost-update anomaly and its fix. Run the numbered steps in order, alternating between two psql sessions on the same database.
- `screenshots/P3_output.txt` — captured results.

## How to run
Part A (single session):
```bash
psql -d remotefund -f P3_Transactions.sql
```
Part B (two psql terminals on `remotefund`, following the numbered steps):
```bash
# terminal 1:  psql -d remotefund  -> run Session A steps 0,1,3,5,6,8
# terminal 2:  psql -d remotefund  -> run Session B steps 2,4,7,9
```

## Result
- **COMMIT** made a repayment permanent (balance 2500 → 2000).
- **ROLLBACK** undid a mistaken −9999 update; the committed value (2000) was restored.
- **Lost update (no locking):** two officers each read 2000 and each wrote 1900, so the final
  balance was **1900** — one 100-repayment was silently **lost**.
- **Fix with `SELECT … FOR UPDATE`:** session B's locked read **blocked ~1.16 s** until session A
  committed, then read the up-to-date 1900 and wrote 1800. Final balance **1800** — nothing lost.

The anomaly is a classic lost update; row-level locking before reading serialises the two
updates so both repayments are counted.
