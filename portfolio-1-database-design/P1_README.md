# Portfolio 1 — Database Design and Modelling

Case study: **RemoteFund — a data-loan fintech for remote workers.**

## Files
- `P1_Design.md` — case study, entities, keys and constraints explained.
- `P1_Schema.sql` — the PostgreSQL DDL (4 tables, PK/FK/UNIQUE/CHECK + a partial unique index).
- `P1_SampleData.sql` — realistic sample rows for the later portfolios.
- `P1_ConstraintTests.sql` — 12 invalid inserts that the constraints reject.
- `P1_Normalisation.md` — UNF → 1NF → 2NF → 3NF for this case.
- `P1_ERDiagram.md` + `../images/ERDiagram.png` — the ER diagram.
- `screenshots/P1_output.txt` — captured output of the live run.

## How to run
```bash
createdb remotefund
psql -d remotefund -f P1_Schema.sql
psql -d remotefund -f P1_SampleData.sql
psql -d remotefund -f P1_ConstraintTests.sql   # every test should FAIL (rejected) — that is the pass
```

## Result
All 4 tables created; 5 employees / 5 applications / 2 disbursements / 4 repayments loaded;
all 12 constraint tests rejected their invalid rows; valid data unchanged.
