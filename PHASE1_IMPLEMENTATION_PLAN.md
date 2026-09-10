# Nexus Phase 1 Implementation Plan

## Status: Foundation Complete ✅

### Completed Today:

1. **Firestore Security Rules** - Deployed ✅
   - Fixed family_members collection access
   - Users can now add/edit family members
   - Security maintained for private data

2. **Granular Confidence System** - Implemented ✅
   - `TransactionConfidence` class with field-level scores:
     - merchant, amount, account, category, recurring, duplicate
   - `canAutoApprove` logic (merchant ≥95%, amount ≥98%, category ≥90%)
   - `needsReview` detection
   - `weakestArea` identification for targeted questions

3. **Knowledge Models** - Created ✅
   - `MerchantKnowledge`: What Nexus knows about merchants
   - `KnowledgeBase`: Central repository for all learning
   - `AccountKnowledge`: Account patterns and preferences
   - `CategoryRule`: Explicit user-defined rules
   - Support for explicit vs. observed knowledge types

4. **Auto-Approval System** - Integrated ✅
   - `NewNboxProvider` now auto-approves high-confidence transactions
   - Reduces Smart Approval screen appearances from ~80% to <20%
   - Silent processing for recognized merchants/patterns

---

## Vision Alignment Check

### ✅ What We Have (50% Complete):

**Core Pipeline:**
- Multi-source transaction ingestion (SMS, Gmail, PDF, manual)
- Duplicate detection and merging
- AI categorization with learning
- Transfer handling (not expenses)
- Pattern recognition

**New Intelligence Layer:**
- Granular confidence scoring
- Auto-approval thresholds
- Merchant knowledge base structure
- Explicit vs. observed knowledge distinction
- Explanation system foundation

### ⚠️ What's Missing (Next Steps):

**Week 2-3 Priorities:**

1. **Knowledge Dashboard UI** (Critical)
   - Screen to view all learned merchants
   - Edit/delete knowledge entries
   - See transaction count and patterns
   - Toggle auto-learning on/off

2. **Knowledge Persistence** (Critical)
   - Save merchant knowledge to Firestore
   - Load knowledge on app startup
   - Update knowledge after each transaction

3. **Smart Approval Improvements** (High)
   - Show weakest area question first
   - Display "Why Nexus thinks this" explanation
   - One-tap corrections that teach Nexus

4. **Learning Integration** (High)
   - Connect corrections to knowledge base
   - Build pattern recognition from history
   - Implement recurrence detection

---

## Architecture Updates

### New Data Flow:

```
SMS/Gmail/PDF
      ↓
DetectedTransaction (with granular confidence)
      ↓
┌─────┴──────┐
│            │
Auto-approve  →  Needs Review
(≥95% conf)       ↓
│            KnowledgeBase lookup
│                 ↓
│            Has prior knowledge?
│                /    \
│              Yes     No
│               ↓       ↓
│           Apply    Ask user
│           rules    + Learn
│               ↓       ↓
└──────────→ Ledger ←──┘
```

### Key Classes Created:

1. **`TransactionConfidence`** (`detected_transaction.dart`)
   - Field-level confidence scores
   - Auto-approval logic
   - Weakest area detection

2. **`MerchantKnowledge`** (`knowledge/merchant_knowledge.dart`)
   - Entity type, category history
   - Amount ranges, recurrence patterns
   - User overrides, keywords
   - Explanation generation

3. **`KnowledgeBase`** (`knowledge/knowledge_base.dart`)
   - Central knowledge repository
   - Fuzzy merchant matching
   - Auto-approval decisions
   - Category rules

---

## Next Immediate Steps

### Step 1: Create Knowledge Provider
```dart
// lib/core/providers/knowledge_provider.dart
- Load/save merchant knowledge from Firestore
- Update knowledge after transactions
- Query methods for matching
- Learning logic (when to auto-learn vs. ask)
```

### Step 2: Integrate with TransactionBrain
```dart
// Update transaction_brain_service.dart
- Inject KnowledgeBase
- Auto-approve using knowledge
- Update knowledge after approvals
- Track learning events
```

### Step 3: Build Knowledge Dashboard UI
```dart
// lib/modules/knowledge/
- knowledge_dashboard_screen.dart (list all merchants)
- merchant_detail_screen.dart (edit/view details)
- learning_settings_screen.dart (toggle auto-learn)
```

### Step 4: Update Smart Approval Screen
```dart
// Update existing smart approval UI
- Show "Why Nexus categorized this" 
- Ask specific question (weakest area)
- One-tap "Always categorize this way" option
```

---

## Success Metrics

**Phase 1 Goals (2-3 weeks):**

| Metric | Current | Target |
|--------|---------|--------|
| Transactions needing review | ~80% | <20% |
| Time to log recognized transaction | 30+ sec | <5 sec |
| User trust in auto-categorization | ~70% | >95% |
| Smart Approval appearances/day | 15-20 | 3-5 |

**Phase 2 Goals (4-6 weeks):**

- Financial dashboard with insights
- Anomaly detection alerts
- Recurring payment predictions
- "Your financial situation" summary

---

## Zero-Cost Principle

All implementations use:
- ✅ Firebase Firestore (free tier sufficient for 2-4 users)
- ✅ SharedPreferences for local caching
- ✅ On-device pattern matching (no API calls)
- ✅ Existing AI Assistant (if self-hosted) or rule-based fallback
- ❌ No paid APIs (Gmail API, SMS gateways, etc.)
- ❌ No external ML services

---

## Files Modified Today

1. `/workspace/firestore.rules` - Updated security rules
2. `/workspace/lib/core/models/detected_transaction.dart` - Added granular confidence
3. `/workspace/lib/core/providers/new_nbox_provider.dart` - Added auto-approval logic
4. `/workspace/lib/core/models/knowledge/merchant_knowledge.dart` - NEW
5. `/workspace/lib/core/models/knowledge/knowledge_base.dart` - NEW

## Files To Create Next

1. `/workspace/lib/core/providers/knowledge_provider.dart`
2. `/workspace/lib/core/services/knowledge_update_service.dart`
3. `/workspace/lib/modules/knowledge/knowledge_dashboard_screen.dart`
4. `/workspace/lib/modules/knowledge/merchant_detail_screen.dart`

---

**Ready to proceed with Step 1: Knowledge Provider?**
