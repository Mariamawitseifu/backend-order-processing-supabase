# backend-order-processing-supabase
Safe, concurrent, multi-tenant order processing using Supabase (PostgreSQL).

## Overview

This project demonstrates a safe, multi-tenant backend design for processing
credit-based product purchases using **Supabase (PostgreSQL)**.

The focus of this implementation is on:
- Correct data modeling
- Atomic purchase processing
- Concurrency safety
- Tenant isolation

No frontend is included
---

## Technology

- **Database:** PostgreSQL (Supabase)
- **Backend Logic:** PostgreSQL functions (Supabase RPC)
- **Architecture:** Backend-only, transactional design

---

## Database Schema

The database schema is defined in `schema.sql` and includes the following
core tables:

- **businesses**  
  Represents a tenant. All other tables reference a business.

- **customers**  
  Customers belong to a business and have a credit limit and current
  credit usage.

- **products**  
  Products belong to a business and track available stock.

- **orders**  
  Records a purchase made by a customer.

- **order_items**  
  Line items associated with an order.

- **credit_ledger**  
  Tracks unpaid credit balances associated with orders.

All tenant-specific tables include a `business_id` column to support
multi-tenancy.

---

## Purchase Processing

Purchases are handled by a PostgreSQL function (`process_purchase`)
defined in `purchase.sql`. This function encapsulates all business logic
required to safely process a purchase.

### Purchase Flow

1. Start a database transaction
2. Lock the customer row to prevent concurrent credit modifications
3. Lock all involved product rows to prevent concurrent stock updates
4. Validate product stock availability
5. Validate customer credit limit
6. Create an order and associated order items
7. Deduct product stock
8. Update customer credit usage
9. Record the unpaid balance in the credit ledger
10. Commit the transaction

If any step fails, the transaction is automatically rolled back, ensuring
the system never enters an inconsistent state.

---

## Concurrency Handling

Concurrency is handled at the database level using **row-level locking**:

- `SELECT ... FOR UPDATE` is used to lock customer and product rows
- Concurrent purchase requests targeting the same data are serialized
  by PostgreSQL
- This prevents race conditions such as overselling stock or exceeding
  customer credit limits

Database transactions ensure atomicity and consistency even under
concurrent requests.

---

## Tenant Isolation

Tenant isolation is enforced through:

- A `business_id` column on all tenant-scoped tables
- Query-level filtering by `business_id`
- Foreign key constraints preventing cross-tenant access

In a real Supabase environment, **Row Level Security (RLS)** policies
would further restrict access so authenticated users can only read and
write data belonging to their business.

---

## Overdue Customers

The query defined in `overdue.sql` returns customers with unpaid balances
older than 30 days.

It aggregates unpaid credit ledger entries per customer to identify
overdue balances accurately.

---

## Supabase Integration

This solution is designed specifically for **Supabase’s PostgreSQL backend**.

The `process_purchase` function is intended to be exposed as a Supabase
RPC and called from server-side Next.js or any backend client.

No deployed Supabase project or frontend is required for this submission.

---
