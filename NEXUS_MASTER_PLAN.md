# Nexus Master Plan

**Status:** Active scope narrowed to Nexus Core refinement; companion apps deferred  
**Date:** 2026-09-05  
**Workspace:** `E:\Github\Nexus`

## Purpose

Nexus is the Core/Finance product in a larger ecosystem. Future companion products should feel like separate focused experiences backed by the same identity, data, notification, and design foundations.

This plan is the execution contract for finishing Nexus Core. Work proceeds in order and advances only when the active phase's acceptance criteria and verification gates pass.

The previously discussed Wants and Tasks ecosystem remains valid context, but it is not active work. No companion foundation, cross-app integration, or child-app implementation should be started while Nexus Core remains unfinished.

## Guardrails

- Preserve existing business logic, persistence, authentication, sync, and performance architecture unless repository evidence justifies a change.
- Treat the current working-tree changes as pre-existing user work. Do not reset, overwrite, or fold them into unrelated changes.
- Make ordinary implementation decisions autonomously.
- Do not invent major product direction or expand a phase because an adjacent idea is attractive.
- Record new ideas in the backlog and implement them only in their planned phase unless required by an active acceptance criterion.
- Stop for a product decision only when the choice changes user-facing direction, data ownership, migration semantics, privacy/security posture, or an external dependency that cannot be verified.
- Run verification after every implementation batch and create a checkpoint only for changes owned by that batch.

## Verification loop

`inspect → implement smallest safe batch → format/lint → tests → flutter analyze → build → review diff → checkpoint`

Known failures must be fixed and reverified before advancing. If a failure is unrelated pre-existing work, document it with exact evidence and do not mask it.

## Repository baseline (Phase 0 inspection)

### Technology and runtime

- Flutter application, Dart SDK `^3.8.1`.
- Firebase Core/Auth/Firestore/Analytics/Messaging/Crashlytics/Storage.
- Provider for state management.
- GoRouter exists as a gradual standalone-route migration, while the primary app still uses the existing navigation flow.
- Shared preferences, secure storage, local auth, local notifications, Google Sign-In, SMS/Gmail ingestion, and background services are present.

### Current structural seams

- `lib/core/models/` contains shared domain models such as transactions, accounts, categories, goals, debts, subscriptions, notifications, and transaction-understanding/relationship models.
- `lib/core/providers/` owns user-facing state and wires providers together from `lib/main.dart`.
- `lib/core/repositories/` contains a generic repository contract and a user-scoped Firestore implementation under `users/{userId}/{collection}`.
- `lib/core/services/` contains authentication, notifications, navigation/intent handling, sync, backup, categorization, transaction intelligence, and domain services.
- `lib/core/auth/` contains the auth gate and biometric protection.
- `lib/core/router/app_router.dart` provides standalone routes but is not yet the sole navigation authority.
- `lib/modules/` contains feature UI modules; the current app is broader than finance and includes goals, debts, subscriptions, family, bike, Gmail/Nbox, investments, and more.
- `docs/UI_TOKENS.md` is the existing design-token reference.

### Persistence and identity

The reusable persistence boundary is `FirestoreRepository<T>`, which scopes data beneath the authenticated Firebase user. New Wants and Tasks storage must reuse this boundary or provide a repository with equivalent user scoping, serialization, and testability. Child modules must not create parallel authentication or user records.

### Authentication

`AuthService` owns Firebase auth state, Google sign-in, anonymous sign-in, and sign-out. `AuthGate` controls the entry boundary. This remains shared infrastructure.

### Notifications and navigation

Notification providers/services and the cross-module notification hub already exist. `IntentNavigationService` and `nav_service.dart` provide intent/navigation seams. New child links should use registered routes or intents with safe fallback rather than passing sensitive data through URLs.

### Existing child-app context

`E:\Github\Nexus_Tasks` exists as a workspace path but currently has no source files. Tasks therefore remain a contract/foundation phase until its actual code is available.

### Working-tree risk

The checkout is dirty with extensive modified and untracked files, including transaction-intelligence additions and recovery artifacts. This plan does not assume those changes are complete or correct. Baseline verification must be run before Phase 0 implementation decisions are made.

## Deferred ecosystem context — not active work

The Core/Wants/Tasks boundaries and proposed contracts below are retained for future reference only. They must not drive current implementation or justify architectural changes in Nexus Core.

## Phase 0 — Nexus Core baseline and stabilization

### Objectives

1. Establish a reproducible Flutter/Dart/Git baseline.
2. Inventory the existing Nexus Core architecture and current user-facing flows.
3. Triage compiler, analyzer, test, persistence, auth, navigation, and performance problems.
4. Make the smallest safe fixes needed to restore a verifiable Core.
5. Record decisions and risks without expanding into companion products.

### Product boundaries

**Nexus Core / Finance owns:** financial accounts, transactions, categories, budgets, debts, subscriptions, goals, financial intelligence, identity, auth, persistence, sync, shared notifications, and the finance experience.

**Nexus Wants owns:** things the user wants to own; captured price, optional product metadata/URL, category, notes, want state, saving intent, and eventual price history.

Wants is not a second finance app. Retailer scraping, variant/region matching, scheduled price checks, and marketplace discovery are deferred.

**Nexus Tasks owns:** personal tasks, due dates, reminders, recurrence, organization, and relationships to Core/Wants records.

Tasks is not an unconstrained generic productivity suite.

### Phase 0 acceptance criteria

- Current Core architecture and major user flows are documented.
- A reproducible analyzer, test, and build baseline exists.
- Critical Core failures are triaged with evidence.
- No existing business behavior is changed solely to prepare for future products.
- Baseline and post-change analyzer/tests/build results are recorded.

## Phase 1 — Nexus Core refinement

1. Triage current defects and incomplete areas by criticality.
2. Resolve structural/parser/compiler blockers first.
3. Verify navigation and UX flows, then persistence/auth/sync, notifications, performance, intelligence, and edge cases.
4. Improve visual consistency, loading/error states, navigation, and interaction quality.
5. Keep companion ideas in their backlogs.

**Gate:** critical/important issues resolved or explicitly blocked; tests, analysis, and debug build pass for the repository's supported targets.

## Future only — Nexus Wants foundation

Initial V1 scope:

- Create/edit a want with name, price at capture, optional URL, category, notes, timestamps, and status.
- Statuses: Want, Saving, Bought, Dropped.
- Persist, sync, filter/sort, and show totals.
- Keep the module boundary suitable for a future standalone child app.
- Allow an explicit, reviewable link between a want and a Core transaction.

Defer automated retailer scraping, price-drop detection, broad product discovery, and autonomous purchase matching until the necessary product and data decisions are made.

**Gate:** data survives reload/auth boundaries, follows user scoping, has tests, and the Core link is explicit and reversible.

## Future only — Nexus Tasks foundation

Initial V1 scope:

- Create, edit, complete, archive, and organize tasks.
- Due dates and reminders through shared notification infrastructure.
- Recurrence only where existing platform support is reliable.
- References to Core entities or Wants without duplicating ownership.

The empty `Nexus_Tasks` checkout is a blocker for implementation there, but not for defining the contract.

**Gate:** persistence/sync, reminder behavior, references, tests, analysis, and build pass.

## Future reference — cross-app integration contracts (v1 proposal)

These are retained as future reference only. They are not permission to add a new event bus, backend, child module, or Core integration during the current Nexus-focused scope.

### Identity and authorization

All products use the same Firebase user identity and authorization rules. No companion creates a parallel account or bypasses Core security rules.

### Entity references

References contain an opaque entity ID, source/module type, and schema version. The owning module remains authoritative. References must tolerate a missing/deleted target.

### Events and idempotency

Use versioned, user-scoped events only where an existing service boundary requires communication. Candidate event names: `WantCreated`, `WantPurchaseLinked`, `TransactionCreated`, `TaskDue`, and `FinancialObligationDetected`. Each event needs an event ID/idempotency key, occurred-at timestamp, actor/source, schema version, and minimal payload. Do not introduce a new event infrastructure without evidence.

### Navigation/deep links

Use named routes or the existing intent navigation mechanism. Links must have an authenticated fallback and must not expose sensitive financial payloads.

### Notifications

Children submit notification intent through shared notification services/hub. Delivery, permission handling, deduplication, and platform scheduling stay centralized.

### Categories/settings

Reuse shared categories/settings only when ownership is clear. Child-specific metadata stays child-owned; shared category IDs must be stable and migration-aware.

### Persistence/sync

Reuse user-scoped Firestore repositories and the current sync strategy. New writes must be idempotent and conflict behavior must be specified before multiple clients can edit the same record.

### Privacy/security

Apply least privilege. Keep financial details out of URLs, logs, notification previews where inappropriate, and cross-module payloads that do not need them.

## Backlog

- Wants naming decision (Wants/Wishlist/other) — defer until the product boundary is better understood.
- Price tracking and retailer integrations — future, external dependency and reliability risk.
- Automated transaction-to-want matching — future, requires reviewable confidence and product decision.
- Tasks dashboard widget in Core — future refinement item; existing status says it is not implemented.
- Standalone child-app packaging and shared backend deployment — future, requires repository/deployment evidence.

## Status log

### 2026-09-05 — execution handoff audit

- The canonical financial write path is `TransactionProvider` → `TransactionEngine` → `LedgerService`, with Firestore data scoped to `users/{uid}/transactions` and account/budget updates committed with the ledger write.
- Manual entry, account entry, bike/fuel entry, subscription payment, debt repayment, payday income, PDF review, NBox, and Smart Approval ultimately call `TransactionProvider.addTransaction`; source imports additionally carry a `metadata.sourceFingerprint` for idempotency.
- `TransactionIntelligenceService` is the deterministic interpretation layer. It combines explicit/correction Knowledge, historical merchant/entity matches, parser signals, recurring intervals, transfer/refund/special-intent heuristics, anomaly observations, and per-dimension confidence. `KnowledgeLearningService` updates reusable rules instead of duplicating transaction records.
- Specialized modules remain separate projections/side effects: fuel creates a linked bike entry, while EMI, subscription, and investment plans update their specialized records after the canonical ledger commit. Reports, budgets, dashboard, and insights consume `TransactionProvider.transactions`.
- Two goal implementations exist (`GoalsScreen` and `ModernGoalsScreen`); both remain in place pending a product-safe comparison. The same intentional audit is still required for the two plan surfaces and legacy debt/IOU naming.
- Fixed a source-idempotency defect: fingerprint lookup now preserves the Firestore document ID instead of reconstructing it as an empty model ID. Hardened JSON transaction restore compatibility for numeric/string enum types and malformed optional scalar values without changing Firestore schema.
- One-time validation: `dart analyze` stalled without useful output; `flutter test` likewise stalled before reporting results. Per the established environment constraint, these are recorded as blockers and were not repeatedly retried. Targeted source inspection and diff validation remain available.

### 2026-09-05 — approved execution pass

- Bounded runtime diagnostics resolved `dart` to `E:\Flutter\bin\dart.bat` and `flutter` to `E:\Flutter\bin\flutter.bat`. `dart --version` timed out after 8 seconds and `flutter --version` timed out after 10 seconds before producing output.
- A second bounded `dart analyze --format=machine` attempt with `DART_SUPPRESS_ANALYTICS=true` timed out after 15 seconds. This materially changed diagnostic conditions and reproduced the blocker; no further SDK retries are justified without an environment change.
- Static inventory confirms source-backed transaction flows converge on `TransactionProvider.addTransaction`; direct Firestore transaction references are limited to ID generation, fingerprint lookup, ledger services, cascade/account maintenance, and the deprecated service writer.
- Added focused confidence-gating tests in `test/transaction_understanding_test.dart` covering high-confidence auto-recording, duplicate review, and unresolved-transfer review. They are syntactically prepared but cannot be executed while Flutter tooling is stalled.
- Current implementation gate remains open: Smart Approval UX, goal/plan duplication decisions, navigation verification, broader tests, and APK validation still require execution and/or working Flutter tooling.

### 2026-09-05 — execution continuation

- Static Smart Approval/NBox review confirms the approval sheet has a scrollable core form, compact intent chips, stable save action, guarded single-screen dispatch, and distinct focus/bulk paths. No safe evidence currently justifies deleting or replacing that UI while it cannot be widget-tested.
- Fixed a bulk-approval provenance gap: `_quickApprove` now writes source, source ID, source fingerprint, entity, purpose, and confidence metadata through the canonical provider, preserving rescan idempotency and historical intelligence.
- Fixed the equivalent payday provenance gap: detected salary approvals now retain source/fingerprint/entity/purpose/confidence metadata on the canonical income transaction.
- Specialized flows verified statically: EMI/debt, investment/SIP, subscription, bike/fuel, family/shared expenses, and payday all call `TransactionProvider.addTransaction`; specialized metadata and/or side effects remain module-owned. No destructive consolidation was performed.
- Goal reconciliation: `goals_screen.dart` (45,563 bytes) is routed by `AppRouter`; `modern_goals_screen.dart` (38,927 bytes) is directly opened by Insights. Both define the same `ModernGoalsScreen` symbol but are separate libraries. They are intentionally retained pending compile/widget comparison; no caller was silently redirected.
- No plan-screen implementation was found under `lib`; current plan references are transaction approval plans and UI copy only. This is recorded as an unresolved scope/documentation mismatch, not evidence for inventing a new plan screen.
- Static validation after this batch: `git diff --check` passed with expected LF/CRLF warnings. Flutter/Dart execution remains blocked by the previously recorded SDK timeouts.

### Final static pass — 2026-09-05

#### A. Implemented and statically verified

- Smart Approval suggestions are wrapped in tap handlers; account/category/intent selectors and specialized entity selectors expose state-changing callbacks.
- Smart Approval has explicit classification state, save-state/error recovery, a `Flexible` bounded scroll region, and a stable primary save button. NBox has separate list, focus, and bulk paths with a single-flight approval guard.
- Bulk and payday source-backed writes preserve provenance and fingerprints.
- Active navigation is `MaterialApp(home: AuthGate())` → biometric wrapper → `MainScreen`; the six main surfaces are dashboard, finance, insights, bike, NBox, and more. Notification/intent approval events route to NBox index 4.
- No destructive migration, transaction-ID rewrite, fingerprint rewrite, bulk deletion, or unsafe persistence schema change was introduced in the completed work.
- Focused tests are written for confidence gating, duplicate/transfer review, and transaction JSON compatibility.

#### B. Implemented but runtime-unverified

- Smart Approval visual compactness, click hit targets, loading resolution, single/multi/bundled presentation, non-shrinking behavior, and real-data scrolling require widget/device execution.
- Specialized side effects require runtime verification against Firestore/account balances: EMI, investments, subscriptions, fuel/bike, family/shared expenses, and payday.
- The two `ModernGoalsScreen` implementations remain intentionally intact. `AppRouter` uses `goals_screen.dart`; Insights directly imports `modern_goals_screen.dart`. Their behavior cannot safely be compared without compilation/widget execution.
- Standalone `AppRouter` routes are statically present but are not the active root navigation authority. Its home route is an intentional placeholder for gradual migration, not evidence of an active dead route.

#### C. Blocked by the Dart/Flutter SDK stall

- `dart analyze`, `flutter test`, formatter execution, runtime/widget tests, integration tests, and APK build cannot be completed because the resolved SDK wrappers stall before useful output. The blocker was bounded and documented; no repeated retries were made.

#### Release gate

The smallest required post-blocker action set is: restore executable Dart/Flutter commands; run the focused tests; run analyzer and broader tests; compare the duplicate goal screens in widget/runtime context; exercise Smart Approval and specialized flows; build and inspect the APK; then update this document with actual results. Definition of Done remains **NOT MET** until those results exist.

### 2026-09-05

- Inspected repository, `pubspec.yaml`, source layout, existing integration status, repository/auth/navigation seams, and graph report.
- Graphify is intentionally treated as unavailable and non-blocking per user direction. No Graphify troubleshooting, removal, or modification is in scope; `GRAPH_REPORT.md` remains the only graph context used.
- Created this master plan from repository evidence and the existing Nexus product context.
- No production code changed by this Phase 0 pass.
- Git `diff --check` completed successfully with expected LF/CRLF warnings.
- Direct Dart 3.11.5 execution works, but `dart analyze` cannot initialize its analytics config because `C:\Users\mahan\AppData\Roaming\.dart-tool` is access-denied in this environment. The Flutter wrapper also stalls before reporting a version or analyzer result.
- The older `INTEGRATION_STATUS.md` reports 1,065 analyzer issues and a failed debug APK, but its named blocker `lib/modules/payday/payday_checklist_sheet.dart` is absent from the current checkout; that report is stale and not treated as current evidence.
- No production code changed. Phase 0 is sufficiently documented, but its verification gate remains open until Flutter/Dart analysis, tests, and build can run reproducibly.
- Active scope was explicitly narrowed to Nexus Core. Wants, Tasks, and cross-app integration work are deferred until Core is finished and the user reopens that direction.
