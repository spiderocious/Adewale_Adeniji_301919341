# MIT 8103 Advanced Database Systems — Portfolio

**RemoteFund: a data-loan fintech for remote workers** · Adewale Adeniji · Student ID 301919341

## Case study

I chose **RemoteFund**, a fintech that gives short-term "data loans" to remote workers. A
remote employee submits a loan application; a loan officer approves or rejects it; an
approved loan is disbursed through a payout channel; and the worker repays it on a schedule.
I designed four tables for this — `employee`, `loan_application`, `disbursement` and
`repayment` — and used the same case consistently across all five portfolios. The users are
remote employees, loan officers and finance staff; the key operations are registering an
employee, submitting and deciding an application, disbursing a loan, recording repayments,
and reporting on outstanding balances. I picked a fintech because loans give natural money
transactions (Portfolio 3), a clear event history (Portfolio 4), and a real availability
need across countries (Portfolio 5).

## Portfolio 1 — Database Design and Modelling

I modelled the four entities in PostgreSQL with surrogate identity primary keys, foreign
keys linking each application to its employee and each disbursement/repayment to its
application, and constraints that enforce the business rules: positive money amounts, a term
of 1–36 months, valid status and channel values, a unique email and application reference,
a composite unique `(application_id, due_date)` so a loan can't have two instalments on the
same date, and a **partial unique index** so an employee can only have one *open* application
at a time. I then wrote 12 deliberately invalid inserts; PostgreSQL rejected every one while
leaving the valid sample rows untouched, which is the evidence that the constraints actually
hold. I also walked the design from an un-normalised sheet through 1NF, 2NF and 3NF to show
why each table exists.

## Portfolio 2 — Query Processing and Optimisation

I wrote three business queries — a three-table join of disbursed loans, an aggregate of
outstanding vs repaid amount per loan, and a date-range filter — and captured each one's
plan with `EXPLAIN (ANALYZE, BUFFERS)`. For the optimisation test I built a 50,000-row
performance table and measured a selective lookup by reference. **Before** adding an index
the planner used a sequential scan and discarded 49,999 rows, taking about **1.76 ms**;
**after** a B-tree index the same lookup became an index scan at about **0.03 ms** — roughly
a 60× improvement. The point I took from this is that the same correct answer can cost very
different amounts of work, so I need to read the execution plan, not just the result.

## Portfolio 3 — Transactions and Concurrency

Using a `loan_balance` helper column (added only for this exercise), I showed COMMIT making
a repayment permanent and ROLLBACK undoing a mistaken −9999 update so the committed value
returned. I then ran two concurrent psql sessions to reproduce a **lost update**: both
officers read a balance of 2000 and both wrote 1900, so the final balance was 1900 and one
repayment vanished. Fixing it with `SELECT … FOR UPDATE`, the second session's locked read
**blocked for about 1.16 seconds** until the first committed, then read the up-to-date value
and wrote 1800 — nothing lost. Locking the row before reading serialises the two updates.

## Portfolio 4 — NoSQL and Advanced Data Models

I modelled the loan **event history** as MongoDB documents, because each event type carries
different details that fit awkwardly in fixed relational columns. I created the collection
with `$jsonSchema` validation and a unique `event_id` index, inserted six events for two
loans, and ran four operations: a loan's full timeline, a projection of disbursements, and
two aggregations ("total repaid per loan" and "events by type"). Three validation tests —
an invalid event type, a wrong data type for the date, and a duplicate event id — were all
rejected, and the document count was unchanged. This complements the relational store rather
than replacing it: PostgreSQL keeps the authoritative balances; MongoDB keeps the append-only
trail.

## Portfolio 5 — Distributed and Cloud Database Exercise

I took the discussion option (no live deployment). I proposed a primary plus two standby
replicas for the PostgreSQL ledger across three availability zones with synchronous
replication for durability, and a three-member MongoDB replica set with `w: "majority"`
writes for the event history. For scale I would shard the Mongo events on a hashed
`application_ref` and partition the SQL tables by date or customer, noting the trade-off that
sharding by customer keeps per-customer queries fast but makes cross-shard reports a
scatter-gather. On CAP I keep the ledger consistent (CP) — I would rather refuse a write
during a partition than let two sides approve loans against the same balance — while allowing
slightly staler reads from Mongo secondaries. I also noted that replication is availability,
not recovery, so RemoteFund still needs backups and point-in-time recovery.

## Individual reflection

The clearest lesson for me was from Portfolio 3: it is easy to assume a correct-looking
`UPDATE` is safe, but two of them running at once can silently lose data, and the only reason
I could prove it was by running the two sessions and watching the final balance come out
wrong. Locking the row before reading fixed it. Portfolio 2 reinforced the same habit from a
different angle — the query returned the right rows both times, but only the plan showed that
one version did 60× more work. Designing the schema also made me think harder about rules
that a plain `UNIQUE` can't state: "one *open* application per employee" needed a partial
index, and getting the 12 constraint tests to all fail (in the good way) was what convinced
me the rules were really enforced rather than just written down. If I extended this, I would
add the repayment-balance logic as a trigger so the balance can never drift from the
repayment rows.

## Repository and evidence

GitHub: **https://github.com/spiderocious/Adewale_Adeniji_301919341**

Each `portfolio-*` folder holds its SQL or JavaScript, a README explaining what it does and
how it was run, and a `screenshots/` folder with the captured output from running it locally
on PostgreSQL 18.1 and MongoDB 7.0.

## AI-use declaration

I used an AI assistant (and reviewed the MIT 8103 portfolio generator) to help draft the
database schema, SQL and MongoDB scripts, and the explanations. I personally ran every script
on my own PostgreSQL and MongoDB installations, checked that the outputs were correct,
designed the ER diagram, and reviewed and rewrote the documentation in my own words. I remain
fully responsible for the accuracy, originality and understanding of everything submitted, and
I can explain any part of it if asked.

## References

- PostgreSQL — Constraints: https://www.postgresql.org/docs/current/ddl-constraints.html
- PostgreSQL — Using EXPLAIN: https://www.postgresql.org/docs/current/using-explain.html
- PostgreSQL — Transaction Isolation: https://www.postgresql.org/docs/current/transaction-iso.html
- PostgreSQL — Explicit Locking (FOR UPDATE): https://www.postgresql.org/docs/current/explicit-locking.html
- PostgreSQL — Streaming Replication: https://www.postgresql.org/docs/current/warm-standby.html
- MongoDB — Data Modelling: https://www.mongodb.com/docs/manual/data-modeling/
- MongoDB — Schema Validation: https://www.mongodb.com/docs/manual/core/schema-validation/
- MongoDB — Replication: https://www.mongodb.com/docs/manual/replication/
- MongoDB — Sharding: https://www.mongodb.com/docs/manual/sharding/
