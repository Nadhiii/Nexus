# Nexus Remediation Log

## 2026-09-05 — P0 foundation pass

- Confirmed the production transaction namespace is `users/{uid}/transactions`.
- Fixed statement import ID allocation: imports no longer allocate IDs from the root `transactions` collection; the canonical engine allocates a user-scoped ID.
- Normalized statement-import metadata to `sourceFingerprint`, matching SMS, Gmail, automation, approval, and duplicate-detection readers.
- Added `TransactionPaths` as the shared collection/document/ID helper and used it in transaction service, engine, and router.
- Preserved existing uncommitted repository changes.
- Fixed stale deletion handling in `TransactionProvider`: missing local entities now return an explicit refreshable error instead of throwing from `firstWhere`.
- Updated account cascade deletion and transaction restoration to use the shared path helper.

### Validation

- Formatted changed Dart files.
- Ran `git diff --check` successfully.
- Ran `flutter analyze --no-pub`; no diagnostic output was reported.
- Started `flutter test --no-pub`; the captured run reached test loading but did not provide a complete summary in the available command output.
- Refreshed `graphify-out` with the repository’s graph updater; it completed with warnings about non-source/config files and an inaccessible legacy skill mount.
- Automation ID allocation now uses `TransactionPaths`.
- Specialized router side effects now record `metadata.sideEffectStatus` as `completed` or `pending_retry` with the error, making a post-ledger partial failure explicit and recoverable by a future worker.
- Final analysis after this slice reports 54 issues, all warnings/info; the prior two compile errors are resolved. The remaining findings are retained for the P3 cleanup pass.
- Added `TransactionDraft` as the canonical candidate contract, preserving source ID/fingerprint, detected amount/merchant/date/type, category, account/destination, confidence, warnings, and metadata; conversion to a ledger `Transaction` keeps document identity independent from source identity.
- Hardened transaction deserialization for numeric/string amounts, missing optional fields, and invalid dates with explicit format errors instead of unchecked casts.
- Latest analysis reports 53 warnings/info findings and no compile errors; `git diff --check` passes.
- Re-ran formatting, diff validation, analysis, and targeted tests; the command wrapper returned no diagnostic summary after test loading, so runtime test success is not claimed.
- Captured validation explicitly: targeted `transaction_understanding_test.dart` passed all 4 tests. Analysis currently reports 53 pre-existing issues, including two dashboard exhaustiveness errors; the two missing `adjustment` cases were fixed in this pass, while remaining warnings/info are logged for later cleanup.

### Remaining work

- Continue canonicalizing all transaction write callers and side-effect retry semantics.
- Complete candidate contract, flow integration, safety audit, formatting audit, and final project-wide validation.

## 2026-09-05 — canonical commit and Family & Friends pass

- Added `TransactionProvider.commitDraft`, returning an explicit commit result
  that distinguishes a newly committed ledger record from an idempotent source
  duplicate. New records still receive a user-scoped ledger ID; source IDs and
  source fingerprints remain metadata only.
- Added `TransactionDraft.fromTransaction` and preserved a ledger ID only for
  restore/edit compatibility. Manual add, bike/fuel, subscription, debt,
  payday, statement-review, NBox quick approval, automation, and specialized
  NBox plans now explicitly convert or create a draft before committing.
- Removed the standalone transaction-add writer from `TransactionService`.
  Add, transfer, restore, edit, and delete application paths now use
  `TransactionEngine`/`LedgerService`; `LedgerService` uses `TransactionPaths`
  for transaction document references.
- Unified specialized NBox approval with the same editable draft and commit
  path as general approval. The router now only applies domain side effects
  after the canonical provider commit, and fuel-entry side effects use the
  canonical transaction ID so retries do not create a second fuel entry.
- Removed caller-supplied balance values from `ApprovedTransactionPlan`; the
  provider reads current account balances at commit time, restoring one source
  of truth for balance calculations.
- Completed Family & Friends interaction paths: add/edit/remove members,
  add/edit/delete shared expenses, reload-safe member upserts, generated IDs
  for new expenses, and exact two-decimal currency rendering in the family
  surfaces.
- Hardened transaction and shared-expense numeric/string/date deserialization
  and added exact currency formatting to core transaction/NBox/notification
  displays touched by this pass.

### Validation and blockers

- `git diff --check` was run after the pass.
- Formatting was applied to the changed Dart files before the final edits.
- Final `flutter analyze --no-pub` completed with no errors and 53 existing
  warning/info findings. The remaining findings are non-fatal lint, lifecycle,
  deprecated API, and unused-code items outside this remediation slice.
- `test/transaction_understanding_test.dart` passed all 4 tests, and
  `test/debts_screen_test.dart` passed its widget test. The full test suite is
  not clean because the pre-existing `test/widget_test.dart` is reported by
  the Flutter test harness as having no discoverable `main` entry point; no
  production-code failure was reported from the other tests.
- The first non-escalated analysis/format attempts were blocked by the Dart CLI
  access error for
  `C:\Users\mahan\AppData\Roaming\.dart-tool\dart-flutter-telemetry.config`
  and left stalled Dart processes; the final escalated analysis completed.
  No runtime, Firebase, device, or Android build verification is claimed.
- A debug Android APK build was started with the escalated toolchain but Gradle
  stopped producing output or an artifact after repeated polls; only the
  validation processes started by that attempt were stopped. Build success is
  therefore not claimed.
- `graphify query`/`graphify update .` were attempted as required by the
  repository instructions, but both are blocked by `uv trampoline failed to
  canonicalize script path`.

### Remaining blockers

- Run Flutter analysis, targeted tests, and Android build on a host where the
  Dart telemetry config is readable (or its toolchain permission issue is
  repaired), then fix any compile findings from that run.
- Firebase/device verification remains outstanding.
- A clean Android build remains outstanding because the Gradle validation run
  stalled in this environment.
- Administrative account-cascade restore still uses the existing bulk restore
  gateway because it must restore a deleted account and its original
  transaction IDs together; it is not a new transaction-producing flow.

## 2026-09-06 — repository cleanup and validation pass

- Audited references to the previously removed categorization services; no active Dart references remain.
- Confirmed NBox approval entry points converge on the guarded canonical review flow and specialized approvals use the shared draft/commit path.
- Repaired the empty `test/widget_test.dart` harness with a stable widget smoke test; useful debt and transaction regression tests were retained.
- Removed unused Gmail/NBox category-provider state and the unreachable dark-theme preference writer; updated active callers.
- Added disposal for subscription stream listeners and removed unused locals from NBox approval code.
- Preserved Firebase, Android, generated, and platform configuration artifacts after inspection; no speculative feature files were deleted.

### Validation

- Full `flutter test --no-pub`: **7 tests passed**.
- `flutter analyze --no-pub`: **no errors**, 49 warning/info findings remain.
- `dart format` applied to changed files; `git diff --check` passed.
- Android debug APK reached Gradle `assembleDebug` but did not produce a result within the bounded validation window; success is not claimed. Firebase and physical-device validation remain unperformed.
