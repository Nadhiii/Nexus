# NEXUS_CONTEXT.md — Living Specification

> **How to use this file**: Reference it in Copilot Chat by saying *"see NEXUS_CONTEXT.md"*. Keep it updated as the app evolves. This is the single source of truth for architecture decisions, data models, and routing rules.

---

## App Identity
- **Name**: Nexus
- **Type**: Personal life tracker — finances, garage, health, goals
- **Users**: 1–2 people (personal use)
- **Cost constraint**: Zero-cost. No paid APIs. No open banking.
- **Platform**: Flutter (Android primary), Firebase backend
- **State**: Mostly complete, polishing phase

---

## Module Registry

| Module | Folder | Provider | Service | Key Model(s) |
|---|---|---|---|---|
| Finance – Accounts | `modules/accounts/` | `AccountProvider` | `AccountService` | `Account` |
| Finance – Transactions | `modules/transactions/` | `TransactionProvider` | `TransactionService` | `Transaction` |
| Finance – Budgets | `modules/budgets/` | `BudgetProvider` | `BudgetService` | `Budget` |
| Garage | `modules/bike/` | `BikeProvider`, `VehicleManagementProvider` | `BikeService` | `Bike`, `BikeEntry`, `Trip` |
| Subscriptions | `modules/subscriptions/` | `SubscriptionProvider` | `SubscriptionService` | `Subscription` |
| Investments | `modules/investments/` | `InvestmentProvider` | `InvestmentService` | `Investment` |
| Liabilities | `modules/debts/` | `DebtProvider` | `DebtService` | `Debt` |
| Goals | `modules/goals/` | `GoalProvider` | `GoalService` | `Goal` |
| Family | `modules/family/` | `FamilyDebtProvider`, `SharedExpenseProvider` | — | `FamilyDebt`, `SharedExpense` |
| NBox | `modules/nbox/` | `NewNboxProvider` | SMS/Gmail parsers | `DetectedTransaction` |
| Nex (AI) | `modules/Nex/` | `NexAssistantProvider` | `NexService` | `NexConversation`, `NexMessage` |
| Notifications | `modules/notifications/` | `NotificationProvider` | `NotificationService` | `AppNotification` |

---

## Firestore Collection Hierarchy

```
users/
  {userId}/
    accounts/          {accountId}
    transactions/      {transactionId}
    bikes/             {bikeId}
      entries/         {entryId}      ← fuel/service logs
      trips/           {tripId}       ← trip records
    subscriptions/     {subscriptionId}
    investments/       {investmentId}
    debts/             {debtId}
    goals/             {goalId}
    budgets/           {budgetId}
    categories/        {categoryId}
    family_debts/      {debtId}
    shared_expenses/   {expenseId}
    notifications/     {notificationId}
    recurring_templates/ {templateId}
    vehicle_documents/ {docId}
    challan/           {challanId}
    payday_checklist/  {itemId}
    user_profile/      (single doc)
    backup_metadata/   (single doc)
    nbox_settings/     (single doc)
    gmail_sync_settings/ (single doc)
    dashboard_widget_preferences/ (single doc)
```

---

## Transaction.metadata — Extended Schema

The `metadata` field on `Transaction` is used to attach cross-module context. These are the defined schemas by intent:

### Fuel Transaction
```dart
metadata: {
  'intent': 'fuel',
  'bikeId': String,
  'bikeName': String,
  'bikeEntryId': String,      // ID of created BikeEntry
  'fuelLiters': double,
  'odometerReading': double,
  'previousOdometer': double,
  'pricePerLiter': double,
  'isFullTank': bool,
  'mileage': double?,         // calculated if previous full-tank entry exists
}
```

### EMI Payment
```dart
metadata: {
  'intent': 'emi_payment',
  'debtId': String,
  'debtName': String,
  'paidMonthIndex': int,      // which month this payment covers
  'principalComponent': double?,
  'interestComponent': double?,
}
```

### Subscription Payment
```dart
metadata: {
  'intent': 'subscription_payment',
  'subscriptionId': String,
  'subscriptionName': String,
  'previousDueDate': String,  // ISO8601
  'newDueDate': String,       // ISO8601
}
```

### SIP / Investment
```dart
metadata: {
  'intent': 'investment_sip',
  'investmentId': String,
  'investmentName': String,
  'units': double?,
  'nav': double?,
}
```

---

## Smart Transaction Router — Full Specification

### Pipeline Flow
```
DetectedTransaction (from NBox)
    │
    ▼
[1] IntentClassifier.classify(merchant, category, amount, body)
    │   → returns TransactionIntent enum + confidence
    │
    ▼
[2] SideEffectPlanner.plan(intent, detectedTx)
    │   → returns List<SideEffect> (what will be created/updated)
    │
    ▼
[3] ApprovalBottomSheet (UI)
    │   → shows detected intent + planned side effects
    │   → user can override intent, select specific linked record
    │   → user provides any missing data (odometer, fuel liters, etc.)
    │
    ▼
[4] TransactionRouter.execute(approvedPlan)
    │   → uses WriteBatch for atomic commit
    │   → creates Transaction + all side effects
    │
    ▼
[5] CrossModuleNotificationHub notified
    └─── generates relevant notifications
```

### TransactionIntent Enum
```dart
enum TransactionIntent {
  fuel,               // → Finance + BikeEntry
  emiPayment,         // → Finance + Debt update
  subscriptionPayment,// → Finance + Subscription nextDueDate
  investmentSip,      // → Finance + Investment update
  salary,             // → Finance income
  transfer,           // → Finance transfer (between accounts)
  food,               // → Finance only
  shopping,           // → Finance only
  entertainment,      // → Finance only
  medical,            // → Finance only
  general,            // → Finance only (fallback)
}
```

### Intent Classification Rules
```dart
// File: lib/core/services/transaction_intent_classifier.dart (TO CREATE)

// FUEL signals
keywords: ['petrol', 'diesel', 'fuel', 'hpcl', 'bpcl', 'iocl',
           'indian oil', 'hp petrol', 'shell', 'nayara', 'essar',
           'pump', 'filling station']
category_match: 'fuel', 'transport', 'vehicle'

// EMI signals
keywords: ['emi', 'loan emi', 'loan payment', 'equated']
merchant_match: existing Debt.lenderName (fuzzy)
amount_match: within 5% of existing Debt.monthlyEMI

// SUBSCRIPTION signals
merchant_match: existing Subscription.name (fuzzy)
amount_match: within 5% of existing Subscription.amount
known_merchants: ['netflix', 'spotify', 'amazon prime', 'hotstar',
                  'zee5', 'sonyliv', 'youtube premium', 'apple',
                  'microsoft', 'google one', 'adobe', 'notion']

// SIP signals
keywords: ['sip', 'systematic', 'mutual fund', 'mf purchase']
merchant_match: ['zerodha', 'groww', 'kuvera', 'paytm money',
                 'coin', 'ppfas', 'axis mf', 'sbi mf', 'hdfc mf']

// SALARY signals
keywords: ['salary', 'sal credit', 'payroll', 'stipend']
type_override: always income

// TRANSFER signals
keywords: ['neft', 'imps', 'rtgs', 'transfer to', 'self transfer']
```

---

## Approval UI — Step Definitions

### Step 1: Intent Confirmation
Show detected intent with confidence badge. Allow user to override.
```
"We think this is a FUEL transaction"   [✓ High Confidence]
[Fuel ✓] [EMI] [Subscription] [Other]
```

### Step 2: Intent-Specific Form
Shown only for intents that need extra data:

**Fuel**:
- Select bike (dropdown of user's bikes, default: last used)
- Odometer reading (text field, numeric, shows last known odometer as hint)
- Fuel quantity in liters (text field, numeric)
- Full tank? (toggle, default: true)

**EMI**:
- Select debt (dropdown, pre-selected if high-confidence match)
- Confirm amount matches EMI

**Subscription**:
- Select subscription (dropdown, pre-selected if match found)

**SIP**:
- Select investment (dropdown, pre-selected if match found)

### Step 3: Preview Side Effects
Show exactly what will be created/updated:
```
✓ Transaction: ₹850 expense (Fuel)
✓ Garage log: Honda Activa — 47,230 km
✓ Mileage calculated: 42.3 km/L
✓ Odometer updated: 47,230 km
```
"Confirm & Save" button → atomic write

---

## Services To Create

### `lib/core/services/transaction_intent_classifier.dart`
```dart
class TransactionIntentClassifier {
  static ClassificationResult classify({
    required String merchant,
    required String? category,
    required double amount,
    required String? body,
    required List<Subscription> subscriptions,
    required List<Debt> debts,
    required List<Investment> investments,
  });
}

class ClassificationResult {
  final TransactionIntent intent;
  final double confidence;
  final String? matchedEntityId;   // ID of matched Subscription/Debt/Investment
  final String? matchedEntityName;
}
```

### `lib/core/services/transaction_router.dart`
```dart
class TransactionRouter {
  Future<void> execute({
    required ApprovedTransactionPlan plan,
    required String userId,
    required BuildContext context,
  });
}

class ApprovedTransactionPlan {
  final DetectedTransaction source;
  final TransactionIntent intent;
  final Transaction transaction;       // pre-built transaction model
  final List<SideEffect> sideEffects;  // what else to write
  final Map<String, dynamic> extraData; // odometer, liters, etc.
}
```

### `lib/core/models/transaction_intent.dart`
New model file for the intent enum and related classes.

---

## Existing Services — Do Not Duplicate

| Need | Use This |
|---|---|
| Detect recurring patterns | `TransactionMatchService.detectRecurringPatterns()` |
| Match tx to subscription/EMI | `TransactionMatchService.analyzeTransaction()` |
| Cross-module notifications | `CrossModuleNotificationHub.generateNotifications()` |
| Atomic account + tx delete | `CascadeService.deleteAccountAndTransactions()` |
| Goal ↔ SIP analysis | `GoalSipLinkingService.analyze()` |

---

## Copilot Prompt Templates

Use these when asking Copilot for help:

### Building a new service
```
See NEXUS_CONTEXT.md. Create lib/core/services/transaction_intent_classifier.dart
following the spec in the "Services To Create" section. Use the existing
TransactionMatchService as a reference for code style. Use provider pattern,
no direct Firestore calls from this service.
```

### Building a new screen/widget
```
See NEXUS_CONTEXT.md and copilot-instructions.md. Create the ApprovalBottomSheet
widget for the NBox approval flow. It should:
- Accept a DetectedTransaction and ClassificationResult
- Use AppColors.*, AppTypography.*, AppAnimations.*
- Follow the step-by-step UI defined in "Approval UI — Step Definitions"
- Use WriteBatch for the final commit via TransactionRouter
```

### Fixing a bug
```
See NEXUS_CONTEXT.md. In [file path], [describe bug]. 
The model involved is [ModelName]. Always use copyWith() for updates.
Handle both Timestamp and String for date fields.
```

### Adding a field to a model
```
See NEXUS_CONTEXT.md. Add field [fieldName]: [Type] to the [ModelName] model.
Update fromFirestore, fromMap, toMap, copyWith. Make it nullable with a
sensible default for backward compatibility with existing Firestore documents.
```

---

## Known Technical Debt / Notes
- `new_nbox_screen.dart` and `new_modern_nbox_screen.dart` appear to be duplicates — the modern version (`new_modern_nbox_screen.dart`) is the active one
- `CascadeService` currently only handles account deletion — extend it for other cascade operations
- `metadata` field on `Transaction` is `Map<String, dynamic>?` — always null-check before reading
- `DebtType` is stored as `int` index in Firestore — do not change to string without a migration
- Budget `toMap()` uses `toIso8601String()` for dates but `fromMap()` handles both Timestamp and String — keep this pattern consistent

---

## Version
Last updated: March 2026
App version: 1.0.1+3