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
6. **English / বাংলা**: chosen on first launch, changeable in Settings. Strings live in
   `lib/l10n/app_en.arb` and `app_bn.arb`.
7. **Receipts**: print on a 58/80mm Bluetooth thermal printer, or share as PDF (WhatsApp etc.).
8. **Box / strip / tablet**: stock is counted in the smallest unit; buy and sell by strip or box.
9. **Low-stock alert**: per-medicine level, a "what to order" list you can share.
10. **Sale return / cancel**: stock goes back to its batch; the value comes off the customer's
    baki first, the rest is cash given back. Reports count returns on the day they happen.
11. **PIN lock**: 4-digit PIN on start and after 30 seconds in the background.

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
  core/      db.dart (schema + migrations), money.dart (poisha), ids.dart (UUID + sync columns)
  models/    plain data classes
  data/      repositories: medicine, sale, customer, report, backup, sync_outbox, shop settings, PIN
  l10n/      English + Bangla strings (.arb) and helpers
  receipt/   receipt layout: ESC/POS for thermal printers, PDF for sharing
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
- Barcode scanning, purchase/supplier dues, Bangla on printed receipts (needs image printing)
