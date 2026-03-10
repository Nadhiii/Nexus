# Nexus – GitHub Copilot Instructions

## What is Nexus?
Nexus is a personal life-tracker Flutter app used by 1–2 people. It is a **zero-cost, privacy-first** app — no paid APIs, no open banking, no third-party data brokers. All data lives in Firebase Firestore under `users/{uid}/...`.

The app is **mostly complete and in polishing phase**. When suggesting code, always fit into the existing architecture — never introduce new patterns unless asked.

---

## Tech Stack
- **Flutter** (Dart) — mobile-first, Android primary
- **Firebase**: Firestore, Auth, Storage, Crashlytics, Messaging, Analytics
- **State Management**: `provider` (ChangeNotifier pattern) — never suggest Riverpod, Bloc, or GetX
- **Navigation**: `go_router`
- **AI**: `google_generative_ai` (Gemini) + `flutter_gemma` (on-device)
- **Charts**: `fl_chart` + `syncfusion_flutter_charts`
- **Auth**: Firebase Auth + `local_auth` (biometric)

---

## Project Structure
```
lib/
  core/
    models/         # Data models — all have fromFirestore, fromMap, toMap, copyWith
    providers/      # ChangeNotifier providers — one per domain
    services/       # Business logic — stateless, called by providers
    repositories/   # Firestore access layer
    theme/          # AppColors, AppTypography, AppSpacing, AppAnimations
    widgets/        # Shared reusable widgets
    utils/          # Parsers, extensions, helpers
    auth/           # Auth gate + biometric wrapper
    router/         # app_router.dart (go_router)
  modules/
    accounts/       # Bank accounts
    bike/           # Garage — vehicles, fuel logs, mileage, trips
    budgets/        # Budget tracking per category
    debts/          # Loans + credit cards (liabilities)
    dashboard/      # Home screen
    family/         # Shared expenses, family debt (IOUs)
    goals/          # Savings goals
    investments/    # Mutual funds, stocks, crypto, gold
    nbox/           # Smart transaction inbox (SMS + Gmail detection)
    Nex/            # AI assistant (Gemini-powered)
    notifications/  # In-app notification centre
    pdf_import/     # PDF bank statement parser
    subscriptions/  # Recurring payments tracker
    transactions/   # Transaction add/edit/detail screens
    Wallet/         # Wallet overview
    more/           # Settings, reports, export
  screens/
    login_screen.dart
    main_screen.dart
```

---

## Firestore Schema
All user data lives under: `users/{userId}/{collection}/{docId}`

| Collection | Key Fields |
|---|---|
| `accounts` | id, name, type (AccountType), balance, currency, bankName, isActive |
| `transactions` | id, type (income/expense/transfer), amount, accountId, toAccountId, categoryId, date, metadata, description |
| `bikes` | id, name, make, model, registrationNumber, currentOdometer, fuelType, isActive |
| `bikes/{bikeId}/entries` | id, odometerReading, fuelQuantity, fuelAmount, mileage, isFullTank, category |
| `bikes/{bikeId}/trips` | id, distanceKm, date, notes |
| `subscriptions` | id, name, amount, frequency, nextDueDate, categoryId, accountId, isActive |
| `investments` | id, name, type (InvestmentType), investedAmount, currentAmount, quantity, sipAmount, sipDay |
| `debts` | id, name, type (DebtType), originalAmount, currentBalance, monthlyEMI, nextPaymentDate, lenderName |
| `goals` | id, name, targetAmount, currentAmount, targetDate, linkedAccountId, isCompleted |
| `budgets` | id, categoryId, categoryName, allocatedAmount, spentAmount, period, startDate, endDate |
| `family_debts` | IOUs between people (separate from formal Debt) |
| `shared_expenses` | Expenses split between family members |

---

## Core Models — Key Rules
- **Transaction**: `metadata: Map<String, dynamic>?` — use this for cross-module data (e.g. `metadata['bikeId']`, `metadata['fuelLiters']`, `metadata['odometerReading']`)
- **Bike / BikeEntry**: `BikeEntry` has `odometerReading`, `fuelQuantity`, `fuelAmount`, `mileage`, `isFullTank`
- **Debt**: covers formal liabilities only (loans, credit cards). Personal IOUs go in `family_debts`
- **DebtType**: stored as `int` index in Firestore (backward compat)
- All models have `fromFirestore(DocumentSnapshot)`, `fromMap(Map)`, `toMap()`, `copyWith()`
- Always handle both `Timestamp` and `String` when parsing dates from Firestore

---

## Naming Conventions
| Thing | Convention | Example |
|---|---|---|
| Model files | snake_case | `transaction.dart` |
| Model classes | PascalCase | `Transaction`, `BikeEntry` |
| Provider files | `{domain}_provider.dart` | `bike_provider.dart` |
| Service files | `{domain}_service.dart` | `bike_service.dart` |
| Screen files | `{name}_screen.dart` | `garage_screen.dart` |
| Widget files | `{name}_widget.dart` or `{name}_dialog.dart` | `add_entry_dialog.dart` |
| Enum values | camelCase | `TransactionType.expense` |

---

## State Management Pattern
```dart
// Provider (ChangeNotifier)
class BikeProvider extends ChangeNotifier {
  final BikeService _bikeService = BikeService();
  List<Bike> _bikes = [];
  List<Bike> get bikes => _bikes;

  Future<void> addBike(String userId, Bike bike) async {
    await _bikeService.addBike(userId, bike);
    notifyListeners();
  }
}

// In widgets — always use:
context.read<BikeProvider>()  // for actions
context.watch<BikeProvider>() // for reactive UI
Consumer<BikeProvider>()      // for scoped rebuilds
```

---

## Theme System — Always Use These
```dart
// Colors
AppColors.backgroundBlack     // #0F172A — main background
AppColors.cardSurface         // card backgrounds
AppColors.cardElevated        // elevated cards
AppColors.primaryBlue         // primary actions
AppColors.textPrimary         // main text
AppColors.textSecondary       // secondary text
AppColors.textTertiary        // hints, labels
AppColors.pastelGreen         // income / positive
AppColors.error               // delete / negative
AppColors.accentTeal          // highlights
AppColors.pastelOrange        // warnings

// Typography
AppTypography.headlineMedium
AppTypography.bodyMedium
// etc.

// Animations
AppAnimations.standard        // Duration for most transitions
AppAnimations.slow            // For expand/collapse
AppAnimations.smoothCurve     // Curve for AnimatedSize
```

---

## Smart Transaction Routing — The NBox Approval Flow

### Overview
When a `DetectedTransaction` is approved in NBox, it goes through a **multi-step routing pipeline** that creates records across multiple modules simultaneously.

### Transaction Intent Classification
Classify by `DetectedTransaction.merchant` + `detectedCategory` + amount:

| Intent | Keywords / Signals | Modules Affected |
|---|---|---|
| `fuel` | petrol, diesel, fuel, HP, Indian Oil, BPCL, Shell, Nayara, pump | Finance + Garage (BikeEntry) |
| `emi_payment` | EMI, loan, HDFC, ICICI, SBI, Bajaj Finance, matches existing Debt | Finance + Debt (paidMonths++) |
| `subscription_payment` | Netflix, Spotify, Amazon Prime, matches existing Subscription | Finance + Subscription (nextDueDate update) |
| `investment_sip` | SIP, mutual fund, Zerodha, Groww, Kuvera, PPFAS | Finance + Investment |
| `salary` | salary, credited, payroll | Finance (income) |
| `food` | Zomato, Swiggy, restaurant, hotel | Finance only |
| `shopping` | Amazon, Flipkart, Myntra, mall | Finance only |
| `transfer` | NEFT, IMPS, UPI transfer to self | Finance (transfer type) |

### Side Effect Rules
```
fuel transaction:
  → create Transaction (expense, category: fuel)
  → create BikeEntry (odometerReading from user input, fuelAmount, fuelQuantity)
  → update Bike.currentOdometer
  → store bikeId + fuelLiters + odometer in Transaction.metadata

emi_payment transaction:
  → create Transaction (expense, category: emi/loan)
  → update Debt.paidMonths += 1
  → update Debt.currentBalance -= principal portion
  → update Debt.nextPaymentDate (advance by 1 month)

subscription_payment transaction:
  → create Transaction (expense, category: subscription)
  → update Subscription.nextDueDate (advance by frequency)

investment_sip transaction:
  → create Transaction (expense, category: investment)
  → update Investment.investedAmount += amount
  → update Investment.quantity (if NAV available)
```

### Key Service: `TransactionMatchService`
Already exists at `lib/core/services/transaction_match_service.dart`. Use `analyzeTransaction()` to pre-match a `DetectedTransaction` against existing subscriptions and debts before showing the approval UI.

### Key Service: `CrossModuleNotificationHub`
Already exists at `lib/core/services/cross_module_notification_hub.dart`. Add new notification types here when new cross-module events are created.

---

## Critical Do's and Don'ts

### ✅ DO
- Use `Transaction.metadata` to attach cross-module context to transactions
- Use `WriteBatch` for any operation that touches multiple Firestore documents atomically
- Use `copyWith()` when updating models
- Handle both `Timestamp` and `String` when parsing Firestore dates
- Use `debugPrint()` for development logs (never `print()`)
- Always check `mounted` before calling `setState()` after async operations
- Use `context.read<>()` for actions, `context.watch<>()` for reactive UI
- Use `AppColors.*`, `AppTypography.*`, `AppAnimations.*` for all theming

### ❌ DON'T
- Never use `dynamic` types where avoidable
- Never bypass the service layer (no direct Firestore calls from widgets)
- Never use `setState()` after `dispose()`
- Never introduce Riverpod, Bloc, GetX, or other state management
- Never add paid APIs or third-party services (zero-cost project)
- Never store CVV in Firestore (it uses `SecureCardService` + `flutter_secure_storage`)
- Never use `IntrinsicHeight` in list items (causes performance issues — use `Stack` instead)
- Never skip `isActive` checks when querying subscriptions or bikes
- Don't use personal IOUs in the `Debt` model — those belong in `family_debts`

---

## Common Patterns

### Atomic multi-document write
```dart
final batch = FirebaseFirestore.instance.batch();
batch.set(transactionRef, transaction.toMap());
batch.update(bikeRef, {'currentOdometer': newOdometer});
batch.set(bikeEntryRef, bikeEntry.toMap());
await batch.commit();
```

### Adding cross-module metadata to a transaction
```dart
final transaction = Transaction(
  // ...core fields...
  metadata: {
    'bikeId': selectedBike.id,
    'bikeName': selectedBike.name,
    'fuelLiters': fuelQuantity,
    'odometerReading': odometer,
    'pricePerLiter': amount / fuelQuantity,
  },
);
```

### Provider access in services
Services are stateless. Pass userId and required data as parameters. Never access providers from services.

---

## Module Relationships Map
```
Transaction ──metadata──► BikeEntry (fuel)
Transaction ──triggers──► Debt.paidMonths update (EMI)
Transaction ──triggers──► Subscription.nextDueDate update
Transaction ──triggers──► Investment.investedAmount update
Budget ◄──reads──────────  Transaction (by categoryId)
Goal ◄───linked──────────  Account (linkedAccountId)
Goal ◄───linked──────────  Investment (SIP linking via GoalSipLinkingService)
Debt ◄───linked──────────  Account (linkedAccountId)
Notification ◄──generated─ CrossModuleNotificationHub (reads all modules)
```

---

## Files to Know
| File | Purpose |
|---|---|
| `lib/core/services/cascade_service.dart` | Atomic deletion across related documents |
| `lib/core/services/cross_module_notification_hub.dart` | Generates smart notifications from all module data |
| `lib/core/services/transaction_match_service.dart` | Matches transactions to subscriptions/EMIs |
| `lib/core/services/ai_categorization_service.dart` | AI-powered transaction categorization |
| `lib/core/utils/new_sms_parser.dart` | SMS parsing into DetectedTransaction |
| `lib/core/utils/gmail_parser.dart` | Gmail parsing into DetectedTransaction |
| `lib/modules/nbox/new_modern_nbox_screen.dart` | Transaction inbox UI |
| `lib/modules/Nex/` | Nex AI assistant module |