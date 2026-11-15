# Portfolio 1 — Database Design and Modelling (RemoteFund)

## The case study

**RemoteFund** is a data-loan fintech for remote workers. A remote employee applies for
a short-term loan; a loan officer approves or rejects it; an approved loan is **disbursed**
to the worker through a payout channel; and the worker repays it over a schedule.

- **Users of the database:** remote employees (applicants), loan officers (who approve and
  disburse), and finance/reporting staff.
- **Major data stored:** employees and their income, loan applications and their lifecycle
  status, disbursements (money paid out), and repayment schedules.
- **Key operations:** register an employee, submit an application, approve/reject it,
  disburse an approved loan, record repayments, and report on outstanding balances.

## Entities and why they are separate

| Table | What it holds | Why it is its own table |
| --- | --- | --- |
| `employee` | the remote worker | their details must not be repeated on every application (3NF) |
| `loan_application` | one request for a loan | many per employee, each with its own lifecycle |
| `disbursement` | money paid out for an approved loan | exists only once a loan is approved; 1:1 with the application |
| `repayment` | scheduled/actual instalments | many per loan, each with a due date |

## Keys and constraints (implemented in `P1_Schema.sql`)

- **Primary keys:** surrogate `BIGINT … GENERATED ALWAYS AS IDENTITY` on each table — stable, compact, and independent of changing business values.
- **Foreign keys:** `loan_application.employee_id → employee`, `disbursement.application_id → loan_application`, `repayment.application_id → loan_application` — these preserve referential integrity (you cannot disburse a loan that does not exist).
- **Unique constraints:** `employee.work_email`; `loan_application.application_ref`; `disbursement.application_id` (one payout per loan); and a **composite** `repayment (application_id, due_date)` (no two instalments on the same date).
- **Check constraints:** positive money amounts (`monthly_income`, `requested_amount`, `amount_due`, `disbursed_amount`), a simple email-format check, `term_months BETWEEN 1 AND 36`, and **enumerations** for `status` and `channel` so only valid lifecycle/payout values are stored.
- **Partial unique index** `uq_one_open_application_per_employee`: an employee may have at most one application that is still `submitted` or `approved`. This is a business rule a plain UNIQUE cannot express — it only applies to *open* applications — and PostgreSQL's partial index expresses it exactly.

## Evidence

- `P1_Schema.sql` — the full DDL (run once on a fresh database).
- `P1_SampleData.sql` — realistic sample rows.
- `P1_ConstraintTests.sql` — **12 deliberately invalid inserts, every one rejected** by the constraints above, with the valid sample rows left untouched. See `screenshots/P1_output.txt`.
- `P1_ERDiagram.md` and `images/ERDiagram.png` — the entity-relationship diagram.
- `P1_Normalisation.md` — UNF → 1NF → 2NF → 3NF walk-through for this case.
