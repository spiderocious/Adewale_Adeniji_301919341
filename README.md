# MIT 8103 Advanced Database Systems — Portfolio

**Student:** Adewale Adeniji · **ID:** 301919341
**Case study:** RemoteFund — a data-loan fintech for remote workers.

This repository is my practical portfolio for the MIT 8103 Continuous Assessment. Every
portfolio uses the same RemoteFund case study, and the technical portfolios were run locally
on **PostgreSQL 18.1** and **MongoDB 7.0**, with the output captured in each folder's
`screenshots/`.

## How to navigate

| Folder | Portfolio | What's inside |
| --- | --- | --- |
| [`portfolio-1-database-design/`](portfolio-1-database-design/) | 1 — Design & Modelling | schema, sample data, 12 constraint tests, ER diagram, normalisation |
| [`portfolio-2-query-optimisation/`](portfolio-2-query-optimisation/) | 2 — Query & Optimisation | business queries + `EXPLAIN`; index before/after on 50k rows |
| [`portfolio-3-transactions-concurrency/`](portfolio-3-transactions-concurrency/) | 3 — Transactions & Concurrency | COMMIT/ROLLBACK/isolation; two-session lost-update + `FOR UPDATE` fix |
| [`portfolio-4-nosql/`](portfolio-4-nosql/) | 4 — NoSQL | MongoDB event model, queries, aggregation, schema validation |
| [`portfolio-5-distributed-cloud/`](portfolio-5-distributed-cloud/) | 5 — Distributed & Cloud | replication, sharding, CAP and deployment discussion |
| [`Adewale_Adeniji_301919341_FinalSummary.md`](Adewale_Adeniji_301919341_FinalSummary.md) | Final docs | 2–3 page summary, reflection, AI declaration, references |

## How to reproduce the technical work

```bash
# PostgreSQL (Portfolios 1–3)
createdb remotefund
psql -d remotefund -f portfolio-1-database-design/P1_Schema.sql
psql -d remotefund -f portfolio-1-database-design/P1_SampleData.sql
psql -d remotefund -f portfolio-1-database-design/P1_ConstraintTests.sql
psql -d remotefund -f portfolio-2-query-optimisation/P2_Queries.sql
psql -d remotefund -f portfolio-2-query-optimisation/P2_Optimisation.sql
psql -d remotefund -f portfolio-3-transactions-concurrency/P3_Transactions.sql
# (Portfolio 3 concurrency uses two psql terminals — see its README)

# MongoDB (Portfolio 4)
mongosh "mongodb://127.0.0.1:27017/remotefund" portfolio-4-nosql/P4_MongoDB.js
```

Each portfolio folder has its own README with the detail and the captured results.
