# Portfolio 5 — Distributed and Cloud Database Exercise

**Case study: RemoteFund — a data-loan fintech for remote workers.**

This portfolio takes the **discussion/design option** permitted by the brief. I did not deploy a live replica set or run a failover test; instead I describe how RemoteFund's data would be distributed for availability, how it would scale, and the trade-offs involved. The design reuses the same two stores from the earlier portfolios: **PostgreSQL** for the transactional loan ledger and **MongoDB** for the `loan_event` history.

## 1. Why RemoteFund needs a distributed design

RemoteFund serves remote workers across several countries (the sample data alone spans Canada, Singapore, Portugal, Nigeria and India). Two pressures follow from that:

- **Availability:** a loan platform that handles disbursements and repayments cannot afford a single machine being a single point of failure. If the one database server goes down, no one can apply for a loan or record a repayment.
- **Scale and locality:** as the number of applications grows into the millions (the Portfolio 2 performance table already showed 50,000 rows), reads and writes should not all land on one node, and users far from the server should not always pay the full network round-trip.

## 2. Replication — surviving a node failure

### PostgreSQL (the transactional ledger)
I would run **one primary and two standby replicas** using PostgreSQL streaming replication, placed in **three separate availability zones**.

- All writes (new applications, disbursements, repayments) go to the **primary**.
- The standbys receive the write-ahead log (WAL) and stay nearly in sync.
- If the primary fails, an automated tool (e.g. **Patroni** + etcd, or a managed service like **Amazon RDS Multi-AZ**) **promotes a standby** to become the new primary.
- Read-only reporting queries (e.g. the Portfolio 2 "outstanding per loan" report) can be routed to the standbys to take load off the primary.

**Consistency choice:** for money, I would use **synchronous replication to at least one standby** so that a committed repayment is guaranteed to survive a primary failure. This trades a little write latency for durability — the right trade-off for a financial ledger.

### MongoDB (the event history)
The `loan_event` collection fits a **3-member replica set** naturally (one primary, two secondaries across zones).

- Writes go to the primary; secondaries replicate the oplog.
- A **primary election** happens automatically if the primary becomes unreachable, as long as a **majority** of members are up.
- I would write event records with **write concern `{ w: "majority" }`** so an event is acknowledged only once a majority has it — no acknowledged loan event is lost in a failover.
- Reads of the timeline can use `readPreference: secondaryPreferred` to spread load, accepting a small **secondary lag** (a just-written event might take a moment to appear on a secondary). That is acceptable for history/audit reads but **not** for the "is this loan already disbursed?" check, which should read from the primary.

## 3. Sharding — scaling beyond one machine

When one replica set can no longer hold the write volume, I would **shard** the data.

- **MongoDB `loan_event`:** shard on a **hashed `application_ref`** (or a compound `{ application_ref, occurred_at }`). Hashing spreads writes evenly so no single shard becomes a hotspot, and all events for one loan still land together, so the common "give me this loan's timeline" query hits a single shard.
- **PostgreSQL:** native sharding is heavier, so I would either partition `loan_application`/`repayment` by **range on `submitted_at`** (old loans on cheaper storage, recent loans hot) or shard by **`employee_id` range/hash** using Citus so each customer's data stays co-located.
- **Trade-off:** sharding by customer keeps per-customer queries fast but makes **cross-shard reports** (e.g. "total disbursed across all countries this month") a scatter-gather that touches every shard. Choosing a shard key is choosing which queries stay cheap.

## 4. CAP and the trade-off I accept

By the **CAP theorem**, during a network partition a distributed store can keep only two of Consistency, Availability and Partition-tolerance; partitions are unavoidable, so the real choice is **C vs A**.

- For the **PostgreSQL ledger**, I favour **Consistency** (CP): during a partition I would rather **refuse a write** than let two sides of the split both approve loans against the same balance and later disagree. A wrong ledger is worse than a brief outage (the same judgement I'd defend for MTN's MoMo).
- For the **MongoDB event history**, I can lean slightly more toward **Availability** for *reads* (serve possibly-stale history from a reachable secondary), because a timeline that is a few seconds behind does no harm — while still requiring majority acknowledgement on *writes*.

## 5. Availability vs recovery (they are different)

- **Replication gives availability:** it keeps the system serving when a node dies.
- **Backups give recovery:** replication faithfully copies a bad write (a buggy batch job, an accidental mass delete) to every replica, so it is **not** a backup. RemoteFund still needs **regular backups and point-in-time recovery** (PostgreSQL WAL archiving; MongoDB snapshots/`mongodump`) to roll back from data corruption or human error.

## 6. A pragmatic cloud deployment for RemoteFund

- **PostgreSQL:** a managed **Amazon RDS (Multi-AZ)** or **Aurora PostgreSQL** instance — automatic standby, failover and backups, so the team doesn't hand-roll Patroni.
- **MongoDB:** **MongoDB Atlas** with a 3-node replica set across zones, scaling to a sharded cluster later.
- Keep **sensitive customer financial data in the region required by local regulation** (data sovereignty), and run the application tier in the same or nearest region to cut latency — a hybrid-cloud posture if any country mandates on-premise storage.

## Summary

RemoteFund's availability comes from **replication** (synchronous for the SQL ledger, majority write concern for the Mongo events), its scale from **sharding on a key chosen to keep per-loan and per-customer queries cheap**, and its safety from **backups separate from replicas**. The guiding rule throughout is the one the ledger forces on us: **for money, correctness and durability come before raw availability.**
