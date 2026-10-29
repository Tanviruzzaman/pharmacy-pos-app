# Pharmacy POS (v1, offline)

A simple Flutter point-of-sale app for small pharmacies. **Version 1 is fully offline**:
all data is stored on the phone in SQLite. No server, no monthly cost.

## Features (v1)

1. **Quick sale**: search a medicine, add it to the cart, apply a discount, save. Stock is taken
   First-Expiry-First-Out, and expired batches are never sold.
2. **Stock with expiry**: medicines with batches (batch no, expiry, buy and sell price), plus an
   expiry alert for 30/60/90/180 days and the stock value at risk.
3. **Baki khata**: customer credit. Unpaid amounts on a sale go to the customer's ledger
   automatically, and you can record payments received or add old baki by hand.
4. **Daily report**: sales, discount, cost, profit, cash in hand, baki given and baki collected,
   with the list of invoices.
5. **Backup**: export everything as one JSON file through the share sheet (choose Google Drive),
   and restore it on a new phone.

## Run

```bash
flutter create . --platforms=android,ios --org com.softifybd   # generates android/ios folders once
flutter pub get
flutter test
flutter run
```

## Project layout

```
lib/
  core/      db.dart (schema), money.dart (poisha), ids.dart (UUID + sync columns)
  models/    plain data classes
  data/      repositories: medicine, sale, customer, report, backup, sync_outbox
  screens/   UI
docs/
  BACKEND_SYNC.md   contract for the future backend / cloud sync (v2)
```

## Design decisions

- Money is stored as **integer poisha**, never float.
- Every row has a **UUID**, `created_at`, `updated_at`, a `deleted` soft-delete flag and a local
  `synced` flag. Cloud sync can be added later without migrating data. See
  [docs/BACKEND_SYNC.md](docs/BACKEND_SYNC.md).
- Each sale is saved in a single SQLite transaction (stock, sale, items, baki), so it either
  saves completely or not at all.

## Roadmap

- v2 (paid): cloud sync and multiple devices, using the backend contract in `docs/`
- Bangla UI, receipt printing (Bluetooth thermal), barcode scanning, purchase/supplier dues
