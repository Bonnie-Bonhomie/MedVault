# Medora

Flutter + Firebase mobile app covering the functional requirements in the
project proposal: authentication, medicine management, categories, suppliers,
stock-in and stock-out, stock-level and expiry monitoring, notifications,
search and filtering, transaction history, reports and a dashboard.

## Colour identity

The interface is built on a deep pharmacy green, defined once in
`lib/app_theme.dart`:

| Token | Hex | Used for |
|---|---|---|
| `deepGreen` | `#0B3D2E` | App bar, sign-in hero, stock panel |
| `primary` | `#14603F` | Buttons, selected states, progress bars |
| `primaryLight` | `#1E7A52` | Secondary emphasis |
| `accent` | `#2E9E6B` | Healthy stock, stock-in entries |
| `mist` | `#E8F1EC` | Tinted cards and chips |
| `surface` | `#F6F9F7` | Screen background |
| `warning` | `#B8860B` | Low stock, expiring soon |
| `danger` | `#A32C2C` | Out of stock, expired, destructive actions |

Change any of these in one place and the whole app follows.

## Setup

1. `flutter create . --project-name pharmacy_inventory` inside this folder if
   you need the `android/` and `ios/` runners.
2. Create a Firebase project, then run `flutterfire configure` to generate
   `firebase_options.dart`, or drop in `google-services.json` and
   `GoogleService-Info.plist` manually.
3. Enable **Email/Password** under Firebase Authentication.
4. Create a Cloud Firestore database.
5. `flutter pub get` then `flutter run`.

Built against Flutter 3.24 or newer.

## Firestore collections

- `users` — profile and role (`owner`, `pharmacist`, `staff`)
- `categories` — name, description
- `suppliers` — name, phone, email, address
- `medicines` — name, generic name, brand, category, supplier, batch, unit,
  cost price, selling price, quantity, minimum level, expiry date, notes
- `transactions` — medicine, type, quantity, unit price, party, performed by,
  timestamp

Stock quantities are adjusted inside a Firestore transaction, so two staff
members recording sales at the same time cannot overwrite each other, and a
sale larger than the quantity on hand is rejected.

## Security rules

Paste into Firestore Rules so inventory data is never readable without an
account:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function signedIn() { return request.auth != null; }

    match /users/{uid} {
      allow read: if signedIn();
      allow write: if signedIn() && request.auth.uid == uid;
    }

    match /{collection}/{docId} {
      allow read, write: if signedIn()
        && collection in ['medicines', 'categories', 'suppliers', 'transactions'];
    }
  }
}
```

## Required index

The per-medicine history query needs a composite index on `transactions`:
`medicineId` ascending, `timestamp` descending. Firestore prints a one-click
link to create it the first time the query runs.

## File map

```
lib/
  main.dart                     Firebase init, auth gate
  app_theme.dart                Dark green tokens and Material 3 theme
  models/models.dart            AppUser, Category, Supplier, Medicine, Transaction
  services/auth_service.dart    Sign in, register, reset, readable errors
  services/inventory_service.dart  CRUD, atomic stock movement, filters, summary
  services/notification_service.dart  Low-stock and expiry alerts, FCM topic
  widgets/common.dart           Stat tiles, status pills, empty states, medicine tile
  screens/login_screen.dart
  screens/register_screen.dart
  screens/home_shell.dart       Bottom navigation
  screens/dashboard_screen.dart Summary counts and "needs attention" list
  screens/medicines_screen.dart Search and filter chips
  screens/medicine_form_screen.dart  Add and edit
  screens/medicine_detail_screen.dart  Details, history, stock buttons
  screens/stock_movement_sheet.dart    Stock in / stock out entry
  screens/transactions_screen.dart     Full movement history
  screens/reports_screen.dart          Valuation, monthly totals, reorder list
  screens/settings_screen.dart         Profile, categories, suppliers
```

## Scope note

The app manages inventory only. It does not diagnose, prescribe, or replace a
pharmacist's professional judgement.
