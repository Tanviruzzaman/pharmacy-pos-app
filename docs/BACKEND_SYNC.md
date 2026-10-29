# Backend & Sync Contract (for v2)

Version 1 of the app is **offline-only**: all data lives in SQLite on the phone,
and the owner backs up by exporting a JSON file (share sheet → Google Drive).

This document is the contract your backend should follow so that cloud sync and
multi-device support can be added later **without changing the local data model**.

---

## 1. Rules every table already follows

| Column       | Type    | Meaning                                                          |
|--------------|---------|------------------------------------------------------------------|
| `id`         | TEXT    | UUID v4 generated **on the device**. Use it as the primary key on the server too. |
| `created_at` | INTEGER | ms since epoch, UTC                                              |
| `updated_at` | INTEGER | ms since epoch, UTC. Bumped on every local change.               |
| `deleted`    | INTEGER | 0/1 soft delete. Rows are never hard-deleted.                    |
| `synced`     | INTEGER | **Local only**, never sent. 0 = needs push.                      |

* Money is always **integer poisha** (৳1 = 100). Never store floats.
* Dates used for grouping (`sale_date`, `entry_date`, `expiry_date`) are `yyyy-MM-dd` strings in the shop's local time.
* Server adds its own columns: `shop_id` (tenant), `device_id`, `server_updated_at`.

## 2. Tables (sync order = dependency order)

```
medicines       (id, name, generic_name, company, unit, sell_price, barcode)
stock_batches   (id, medicine_id, batch_no, expiry_date, qty, buy_price, sell_price)
customers       (id, name, phone, address)
sales           (id, invoice_no, customer_id?, sold_at, sale_date, subtotal, discount,
                 total, paid, due, cost, profit)
sale_items      (id, sale_id, medicine_id, batch_id, medicine_name, qty,
                 unit_price, buy_price, line_total)
credit_entries  (id, customer_id, type['due'|'payment'], amount, sale_id?, note,
                 entry_at, entry_date)
```

Customer baki balance = `SUM(due) - SUM(payment)` over non-deleted `credit_entries`.

Full DDL: `lib/core/db.dart`.

## 3. Suggested endpoints

All requests carry `Authorization: Bearer <token>` (shop owner login) and are scoped to that shop.

### `POST /api/v1/sync/push`

The app builds this body with `SyncOutbox.buildPushPayload()` (`lib/data/sync_outbox.dart`):

```json
{
  "device_id": "a1f3c9e0-...",
  "schema_version": 1,
  "sent_at": 1761710000000,
  "changes": {
    "medicines":      [ { "id": "...", "name": "Napa 500", "sell_price": 120, "created_at": 0, "updated_at": 0, "deleted": 0, ... } ],
    "stock_batches":  [ ... ],
    "sales":          [ ... ],
    "sale_items":     [ ... ],
    "credit_entries": [ ... ]
  }
}
```

Server behaviour:

1. Upsert each row by `id` inside one DB transaction.
2. **Last-write-wins**: only overwrite if incoming `updated_at` > stored `updated_at`.
3. `sales`, `sale_items`, `credit_entries` are effectively **append-only** — they are
   never edited, only soft-deleted. Safe to accept as-is.
4. Respond `200 { "accepted": <n>, "server_time": <ms> }`. The app then calls
   `SyncOutbox.markSynced(payload)`.

### `GET /api/v1/sync/pull?since=<ms>`

Return every row (from any device of this shop) with `server_updated_at > since`:

```json
{ "server_time": 1761710005000, "changes": { "medicines": [...], ... } }
```

The app applies them with `SyncOutbox.applyPulled(changes)` and stores `server_time`
as the next `since`.

### `POST /api/v1/backup/import`

Optional: accept a v1 backup file (`format: "pharmacy_pos_backup"`). Its `tables`
object has the same shape as `changes` above, so it can reuse the push handler.
This is how an existing offline shop moves to the paid cloud plan.

## 4. The one tricky part: stock quantity with multiple devices

`stock_batches.qty` is a running number. If two phones sell from the same batch while
offline, last-write-wins would lose one of the decrements.

Recommended v2 fix (server side): **don't trust pushed `qty` for existing batches**.
Compute it as

```
qty = initial_qty + adjustments - SUM(sale_items.qty WHERE batch_id = ...)
```

i.e. add an `initial_qty` column and a `stock_adjustments` table in v2 and treat
`qty` as a derived/cached value. For single-device v1 shops this is not an issue.

## 5. Invoice numbers

Format `<first 4 chars of device_id>-<6-digit sequence>`, e.g. `A1F3-000042`.
Unique per device, so they never collide across devices after sync.

## 6. Suggested server stack (your choice)

Any stack works because the contract is plain JSON + UUIDs. A cheap setup:
Postgres (same tables + `shop_id`), a small API (Laravel / Node / Django / Go),
and auth by phone OTP or Google sign-in.
