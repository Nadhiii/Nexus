# Nexus — Claude Code Ground Rules

## What this project is
A Flutter personal finance app. Nexus Tasks is a companion 
to-do app that shares this Firebase project. Nexus is the 
source of truth for all financial data.

## Non-negotiable rules

### Schema — never change these
Transaction fields (exact names, exact types):
  userId (String), type (TransactionType enum), 
  amount (double), description (String?), 
  categoryId (String?), accountId (String), 
  toAccountId (String?), date (DateTime), 
  metadata (Map<String,dynamic>?), 
  attachments (List<String>?),
  createdAt (DateTime), updatedAt (DateTime)

Transactions from Nexus Tasks have:
  metadata['source'] == 'nexus_tasks'
Read this field — never write it from Nexus.

### Nexus Tasks integration (minimal footprint)
These are the ONLY integration touch points in Nexus:
1. "via Tasks" chip on transaction tile in wallet_screen.dart
2. "Open in Tasks →" button in add_loan_sheet.dart
3. "Open in Tasks →" button in add_subscription.dart
4. "Open in Tasks →" button in add_goal.dart
5. "Tasks Today" widget on dashboard (reads tasks collection)

DO NOT add any more Nexus Tasks integration points without 
explicit instruction. Nexus must not feel crowded by Tasks.

### Architecture
- Provider (not Riverpod) is the state management for Nexus
- Services in lib/core/services/
- Providers in lib/core/providers/
- Models in lib/core/models/
- Do not introduce Riverpod into Nexus

### Design
- ALWAYS use AppColors tokens — never hardcode colours
- ALWAYS use AppTheme styles — never hardcode font sizes
- Fonts: Rammetto One for headings, existing body font for body
- Theme: soft dark (mid-tone), background around #131427
- The NexusCard widget is the standard card

### Code quality
- NEVER use print() — always debugPrint()
- NEVER use .withOpacity() — always .withValues(alpha:)
- ALWAYS add if (!context.mounted) return; after awaits 
  followed by context usage
- ALWAYS wrap Firestore writes in try/catch

### Before marking any task complete
- Run flutter analyze — zero warnings, zero errors required
- Confirm no hardcoded colours or font sizes

## Current build status
- All core features: COMPLETE
- Nexus Tasks integration points 1-4: COMPLETE
- Tasks Today dashboard widget: COMPLETE (Task 4)
- Debts crash fix: COMPLETE (Task 1)
- Analyzer: zero errors, 36 style warnings (safe to ignore)
- Debug APK: building cleanly

## Integration status
See INTEGRATION_STATUS.md for full status.
