// ============================================================================
// Portfolio 4 - NoSQL and Advanced Data Models (RemoteFund)
// Document model: loan_event collection in MongoDB.
//
// Why a document model here: a loan moves through many event types (submitted,
// approved, disbursed, repayment_made, closed). Each event type carries DIFFERENT
// details. In the relational design this would need several tables or nullable
// columns; as documents, each event embeds exactly the fields it needs, and the
// whole history of a loan is a simple query on application_ref.
//
// Run:  mongosh "mongodb://127.0.0.1:27017/remotefund" P4_MongoDB.js
// ============================================================================

const dbx = db.getSiblingDB("remotefund");
dbx.loan_event.drop();

// ---- Schema validation: enforce shape even in a schemaless store -----------
dbx.createCollection("loan_event", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["event_id", "application_ref", "event_type", "occurred_at"],
      properties: {
        event_id:        { bsonType: "string",  description: "unique event id" },
        application_ref: { bsonType: "string",  description: "links to the SQL loan_application" },
        event_type:      { enum: ["submitted", "approved", "rejected", "disbursed", "repayment_made", "closed"] },
        occurred_at:     { bsonType: "date" },
        details:         { bsonType: "object" }   // flexible, varies by event_type
      }
    }
  }
});
// One event_id should never repeat.
dbx.loan_event.createIndex({ event_id: 1 }, { unique: true });
dbx.loan_event.createIndex({ application_ref: 1, occurred_at: 1 });

print("=== Inserting the event history for two loans ===");
dbx.loan_event.insertMany([
  { event_id: "EV-001", application_ref: "APP-1004", event_type: "submitted",
    occurred_at: ISODate("2026-03-20T08:45:00Z"), details: { requested_amount: 2500, term_months: 9 } },
  { event_id: "EV-002", application_ref: "APP-1004", event_type: "approved",
    occurred_at: ISODate("2026-03-22T09:00:00Z"), details: { approved_by: "officer_7", risk_band: "B" } },
  { event_id: "EV-003", application_ref: "APP-1004", event_type: "disbursed",
    occurred_at: ISODate("2026-03-22T12:00:00Z"), details: { amount: 2500, channel: "mobile_money" } },
  { event_id: "EV-004", application_ref: "APP-1004", event_type: "repayment_made",
    occurred_at: ISODate("2026-04-21T10:00:00Z"), details: { amount: 300, method: "wallet" } },
  { event_id: "EV-005", application_ref: "APP-1005", event_type: "submitted",
    occurred_at: ISODate("2026-04-01T10:00:00Z"), details: { requested_amount: 4000, term_months: 18 } },
  { event_id: "EV-006", application_ref: "APP-1005", event_type: "closed",
    occurred_at: ISODate("2026-04-03T09:00:00Z"), details: { reason: "fully_repaid" } }
]);
print("Inserted " + dbx.loan_event.countDocuments() + " events.\n");

print("=== Query 1: the full timeline of loan APP-1004 (sorted) ===");
printjson(dbx.loan_event.find({ application_ref: "APP-1004" }).sort({ occurred_at: 1 }).toArray());

print("\n=== Query 2: all disbursement events, projected ===");
printjson(dbx.loan_event.find(
  { event_type: "disbursed" },
  { _id: 0, application_ref: 1, "details.amount": 1, "details.channel": 1 }
).toArray());

print("\n=== Query 3 (aggregation): total repaid per loan ===");
printjson(dbx.loan_event.aggregate([
  { $match: { event_type: "repayment_made" } },
  { $group: { _id: "$application_ref", total_repaid: { $sum: "$details.amount" }, payments: { $sum: 1 } } },
  { $sort: { _id: 1 } }
]).toArray());

print("\n=== Query 4 (aggregation): event count by type ===");
printjson(dbx.loan_event.aggregate([
  { $group: { _id: "$event_type", count: { $sum: 1 } } },
  { $sort: { count: -1 } }
]).toArray());

print("\n=== Validation test 1: reject an invalid event_type ===");
try {
  dbx.loan_event.insertOne({ event_id: "EV-BAD1", application_ref: "APP-1004",
    event_type: "cancelled_by_alien", occurred_at: new Date() });
  print("  UNEXPECTED: invalid event_type was accepted.");
} catch (e) { print("  Rejected as expected: " + e.code + " (document validation)"); }

print("\n=== Validation test 2: reject a wrong type for occurred_at ===");
try {
  dbx.loan_event.insertOne({ event_id: "EV-BAD2", application_ref: "APP-1004",
    event_type: "approved", occurred_at: "not-a-date" });
  print("  UNEXPECTED: string date was accepted.");
} catch (e) { print("  Rejected as expected: " + e.code + " (document validation)"); }

print("\n=== Validation test 3: reject a duplicate event_id ===");
try {
  dbx.loan_event.insertOne({ event_id: "EV-001", application_ref: "APP-1004",
    event_type: "approved", occurred_at: new Date() });
  print("  UNEXPECTED: duplicate event_id was accepted.");
} catch (e) { print("  Rejected as expected: " + e.code + " (duplicate key)"); }

print("\n=== Final document count (unchanged by the rejected inserts) ===");
print("  " + dbx.loan_event.countDocuments() + " events.");
