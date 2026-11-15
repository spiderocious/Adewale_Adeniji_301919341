# Portfolio 1 — Entity Relationship Diagram (RemoteFund)

The RemoteFund data-loan platform has four entities. An **employee** (remote worker)
submits **loan_application**s; an approved application receives exactly one
**disbursement** and a schedule of **repayment**s.

```mermaid
erDiagram
    employee ||--o{ loan_application : "submits"
    loan_application ||--o| disbursement : "paid out by"
    loan_application ||--o{ repayment : "repaid through"

    employee {
        bigint   employee_id PK
        text     full_name
        text     work_email UK
        text     employment_country
        date     hired_date
        numeric  monthly_income
        boolean  is_active
    }
    loan_application {
        bigint     application_id PK
        bigint     employee_id FK
        text       application_ref UK
        numeric    requested_amount
        int        term_months
        timestamptz submitted_at
        text       status
        date       decision_date
    }
    disbursement {
        bigint     disbursement_id PK
        bigint     application_id FK,UK
        numeric    disbursed_amount
        timestamptz disbursed_at
        text       channel
    }
    repayment {
        bigint   repayment_id PK
        bigint   application_id FK
        date     due_date
        numeric  amount_due
        timestamptz paid_at
        text     status
    }
```

**Key**: PK = primary key, FK = foreign key, UK = unique.

**Relationships**
- `employee (1) —— (many) loan_application` — one worker can submit many applications over time (but only one *open* at a time, enforced by a partial unique index).
- `loan_application (1) —— (0 or 1) disbursement` — an application is paid out at most once; `disbursement.application_id` is unique.
- `loan_application (1) —— (many) repayment` — a loan is repaid over a schedule; `(application_id, due_date)` is unique so there are no duplicate instalments on the same date.
