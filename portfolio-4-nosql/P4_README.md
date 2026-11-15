# Portfolio 4 — NoSQL and Advanced Data Models

Case study: **RemoteFund.** A **document model** in MongoDB for the loan event history,
chosen because each event type (`submitted`, `approved`, `disbursed`, `repayment_made`,
`closed`) carries **different details** — awkward in fixed relational columns, natural as
flexible documents.

## Why a document model fits here
- Each `loan_event` embeds exactly the fields its `event_type` needs (an `approved` event
  has `approved_by`/`risk_band`; a `disbursed` event has `amount`/`channel`).
- A loan's whole history is one query: `find({ application_ref })` sorted by time.
- This complements — it does not replace — the relational store: PostgreSQL keeps the
  authoritative balances and constraints (Portfolios 1–3); MongoDB keeps the append-only
  event trail.

## Files
- `P4_MongoDB.js` — creates the collection **with `$jsonSchema` validation**, a unique
  index on `event_id`, inserts 6 events for two loans, runs 4 queries (timeline, projection,
  and two aggregations), and runs 3 validation tests.
- `screenshots/P4_output.txt` — captured output.

## How to run
```bash
mongosh "mongodb://127.0.0.1:27017/remotefund" P4_MongoDB.js
```

## Result
- 6 events inserted across two loans.
- Timeline query, disbursement projection, "total repaid per loan" and "events by type"
  aggregations all return the expected results.
- **Validation held:** an invalid `event_type` (code 121), a wrong type for `occurred_at`
  (code 121), and a duplicate `event_id` (code 11000) were all **rejected**; the document
  count stayed at 6.

MongoDB is schemaless by default, but `$jsonSchema` validation lets us enforce the shape we
rely on — showing that flexibility and integrity are not mutually exclusive.
