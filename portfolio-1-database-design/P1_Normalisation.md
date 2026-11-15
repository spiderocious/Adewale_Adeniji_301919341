# Portfolio 1 — Normalisation (RemoteFund)

Normalisation removes redundancy and update anomalies by making each fact depend on
the whole key and nothing but the key. Below I take a deliberately messy, un-normalised
record for RemoteFund and walk it to Third Normal Form (3NF), which is the form the
Portfolio 1 schema is already in.

## Unnormalised (UNF) — the problem

Imagine a single flat "loan sheet" where each row crams the employee, their application,
the disbursement and all repayments together, with repayments stuffed into one cell:

| emp_name | emp_email | country | application_ref | amount | disbursed_channel | repayments (due:amount) |
| --- | --- | --- | --- | --- | --- | --- |
| Tunde Bello | tunde.bello@…| Nigeria | APP-1004 | 2500 | mobile_money | 2026-04-22:300, 2026-05-22:300 |

Problems: the repayments column is **not atomic**; the employee's name/email/country are
**repeated** on every application they make; if Tunde changes email we must update many rows
(update anomaly); and we cannot record a repayment for a loan that has no row yet
(insert anomaly).

## 1NF — atomic values, no repeating groups

Give every value its own cell and every repayment its own row:

| application_ref | emp_name | emp_email | country | amount | channel | due_date | repay_amount |
| --- | --- | --- | --- | --- | --- | --- | --- |
| APP-1004 | Tunde Bello | tunde.bello@… | Nigeria | 2500 | mobile_money | 2026-04-22 | 300 |
| APP-1004 | Tunde Bello | tunde.bello@… | Nigeria | 2500 | mobile_money | 2026-05-22 | 300 |

Now atomic, but the employee and loan facts are still repeated on each repayment row.

## 2NF — remove partial dependencies

The candidate key of that 1NF table is `(application_ref, due_date)`. But `emp_name`,
`emp_email`, `country`, `amount`, `channel` depend only on `application_ref`, i.e. on
**part** of the key — a partial dependency. We split them out:

- **loan** `(application_ref → employee, amount, channel, …)`
- **repayment** `((application_ref, due_date) → repay_amount)`

## 3NF — remove transitive dependencies

In the loan table, `emp_name`, `emp_email`, `country` are not attributes of the *loan* —
they are attributes of the *employee*, reached transitively through `employee_id`
(`application_ref → employee_id → emp_name`). That transitive dependency is removed by
giving the employee its own table:

- **employee** `(employee_id → full_name, work_email, employment_country, hired_date, monthly_income, is_active)`
- **loan_application** `(application_id → employee_id, application_ref, requested_amount, term_months, submitted_at, status, decision_date)`
- **disbursement** `(disbursement_id → application_id, disbursed_amount, disbursed_at, channel)`
- **repayment** `(repayment_id → application_id, due_date, amount_due, paid_at, status)`

## Result

Each table now has a single key that determines all its non-key attributes, with no
partial and no transitive dependencies — this is **3NF** (and, since every determinant is
a candidate key, effectively BCNF for this design). The decomposition is **lossless**:
joining the four tables back on their foreign keys reproduces the original records
exactly, and each fact (an employee's email, a loan's amount, a repayment's due date) is
now stored in exactly one place, so there are no update, insert or delete anomalies. This
is precisely the structure implemented in `P1_Schema.sql`.
