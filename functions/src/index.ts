/**
 * Nexus Cloud Functions
 *
 * Handles push notifications for:
 * - Family member added
 * - Shared expense created
 * - Expense settled
 * - Budget warnings
 * - Subscription reminders
 * - Debt payment due
 */

import * as admin from "firebase-admin";
import {setGlobalOptions} from "firebase-functions";
import {
  onDocumentCreated,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";
import * as logger from "firebase-functions/logger";

// Initialize Firebase Admin
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// Cost control - limit concurrent instances
setGlobalOptions({maxInstances: 10});

// ============================================================
// HELPER FUNCTIONS
// ============================================================

interface ExpenseSplit {
  personId: string;
  personName: string;
  amount: number;
  isSettled: boolean;
}

/**
 * Get all FCM tokens for a user
 * @param {string} userId - The user ID to get tokens for
 * @return {Promise<string[]>} Array of FCM tokens
 */
async function getUserTokens(userId: string): Promise<string[]> {
  const tokensSnapshot = await db
    .collection("users")
    .doc(userId)
    .collection("fcmTokens")
    .get();

  return tokensSnapshot.docs.map((doc) => doc.data().token as string);
}

/**
 * Send push notification to a user
 * @param {string} userId - The user ID to send notification to
 * @param {string} title - Notification title
 * @param {string} body - Notification body text
 * @param {Record<string, string>} data - Optional data payload
 * @return {Promise<void>}
 */
async function sendNotification(
  userId: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<void> {
  try {
    const tokens = await getUserTokens(userId);

    if (tokens.length === 0) {
      logger.info(`No FCM tokens found for user ${userId}`);
      return;
    }

    const message: admin.messaging.MulticastMessage = {
      tokens,
      notification: {
        title,
        body,
      },
      data: {
        ...data,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "nexus_default_channel",
          priority: "high",
          defaultSound: true,
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    const response = await messaging.sendEachForMulticast(message);
    logger.info(
      `Sent notification to ${userId}: ` +
      `${response.successCount} success, ${response.failureCount} failed`
    );

    // Clean up invalid tokens
    if (response.failureCount > 0) {
      const tokensToRemove: string[] = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const errorCode = resp.error?.code;
          if (
            errorCode === "messaging/invalid-registration-token" ||
            errorCode === "messaging/registration-token-not-registered"
          ) {
            tokensToRemove.push(tokens[idx]);
          }
        }
      });

      // Remove invalid tokens
      for (const token of tokensToRemove) {
        await db
          .collection("users")
          .doc(userId)
          .collection("fcmTokens")
          .doc(token)
          .delete();
        logger.info(`Removed invalid token for user ${userId}`);
      }
    }
  } catch (error) {
    logger.error(`Error sending notification to ${userId}:`, error);
  }
}

/**
 * Store in-app notification in Firestore
 * @param {string} userId - The user ID to store notification for
 * @param {string} type - Notification type
 * @param {string} title - Notification title
 * @param {string} message - Notification message
 * @param {Record<string, unknown>} data - Optional data payload
 * @return {Promise<void>}
 */
async function storeInAppNotification(
  userId: string,
  type: string,
  title: string,
  message: string,
  data?: Record<string, unknown>
): Promise<void> {
  await db
    .collection("users")
    .doc(userId)
    .collection("notifications")
    .add({
      type,
      title,
      message,
      data,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
}

// ============================================================
// SHARED EXPENSE NOTIFICATIONS
// ============================================================

/**
 * Trigger: When a new shared expense is created
 * Action: Notify all participants who owe money
 */
export const onSharedExpenseCreated = onDocumentCreated(
  "users/{userId}/shared_expenses/{expenseId}",
  async (event) => {
    const expense = event.data?.data();
    if (!expense) return;

    const {description, totalAmount, paidBy, paidByName, splits} = expense;

    logger.info(
      `New shared expense created: ${description} for ₹${totalAmount}`
    );

    // Notify each person who owes (except the payer)
    const expenseSplits = splits as ExpenseSplit[];
    for (const split of expenseSplits) {
      if (split.personId !== paidBy && !split.isSettled) {
        const title = "💰 New Expense Split";
        const body =
          `${paidByName} paid ₹${totalAmount} for "${description}". ` +
          `Your share: ₹${split.amount.toFixed(0)}`;

        // Send push notification
        await sendNotification(split.personId, title, body, {
          type: "shared_expense",
          expenseId: event.params.expenseId,
          amount: split.amount.toString(),
        });

        // Store in-app notification
        await storeInAppNotification(
          split.personId,
          "shared_expense",
          title,
          body,
          {
            expenseId: event.params.expenseId,
            paidBy,
            paidByName,
            amount: split.amount,
            description,
          }
        );
      }
    }
  }
);

/**
 * Trigger: When a shared expense is updated (e.g., someone settles)
 * Action: Notify the payer when someone settles their share
 */
export const onSharedExpenseUpdated = onDocumentUpdated(
  "users/{userId}/shared_expenses/{expenseId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const beforeSplits = before.splits as ExpenseSplit[];
    const afterSplits = after.splits as ExpenseSplit[];

    // Check if any split just got settled
    for (let i = 0; i < afterSplits.length; i++) {
      const beforeSplit = beforeSplits[i];
      const afterSplit = afterSplits[i];

      if (
        !beforeSplit.isSettled &&
        afterSplit.isSettled &&
        afterSplit.personId !== after.paidBy
      ) {
        // This person just settled their share - notify the payer
        const title = "✅ Payment Settled";
        const body =
          `${afterSplit.personName} settled ` +
          `₹${afterSplit.amount.toFixed(0)} for "${after.description}"`;

        await sendNotification(after.paidBy, title, body, {
          type: "expense_settled",
          expenseId: event.params.expenseId,
          settledBy: afterSplit.personId,
          amount: afterSplit.amount.toString(),
        });

        await storeInAppNotification(
          after.paidBy,
          "expense_settled",
          title,
          body,
          {
            expenseId: event.params.expenseId,
            settledBy: afterSplit.personId,
            settledByName: afterSplit.personName,
            amount: afterSplit.amount,
          }
        );
      }
    }
  }
);

// ============================================================
// FAMILY MEMBER NOTIFICATIONS
// ============================================================

/**
 * Trigger: When a new family member is added
 * Action: Send welcome notification to the new member
 */
export const onFamilyMemberAdded = onDocumentCreated(
  "users/{userId}/family_members/{memberId}",
  async (event) => {
    const member = event.data?.data();
    if (!member) return;

    const {name} = member;
    const creatorId = event.params.userId;

    // Get creator's name
    const creatorDoc = await db.collection("users").doc(creatorId).get();
    const creatorName = creatorDoc.data()?.displayName || "Someone";

    const title = "👨‍👩‍👧‍👦 Added to Family Group";
    const body =
      `${creatorName} added you to their family expense sharing group!`;

    // Send notification to the new member (if they have app installed)
    // The memberId could be their userId if they're an app user
    if (member.userId) {
      await sendNotification(member.userId, title, body, {
        type: "family_member_added",
        addedBy: creatorId,
        addedByName: creatorName,
      });

      await storeInAppNotification(
        member.userId,
        "family_member_added",
        title,
        body,
        {
          addedBy: creatorId,
          addedByName: creatorName,
        }
      );
    }

    logger.info(`Family member ${name} added by ${creatorId}`);
  }
);

// ============================================================
// BUDGET NOTIFICATIONS
// ============================================================

/**
 * Trigger: When a transaction is added
 * Action: Check if any budget is exceeded and notify
 */
export const onTransactionCreated = onDocumentCreated(
  "users/{userId}/transactions/{transactionId}",
  async (event) => {
    const transaction = event.data?.data();
    if (!transaction || transaction.type !== "expense") return;

    const userId = event.params.userId;
    const {categoryId, date} = transaction;

    // Get user's budgets for this category
    const budgetsSnapshot = await db
      .collection("users")
      .doc(userId)
      .collection("budgets")
      .where("categoryId", "==", categoryId)
      .get();

    if (budgetsSnapshot.empty) return;

    for (const budgetDoc of budgetsSnapshot.docs) {
      const budget = budgetDoc.data();

      // Calculate spent amount for this period
      const transactionDate = date.toDate ? date.toDate() : new Date(date);
      const startOfMonth = new Date(
        transactionDate.getFullYear(),
        transactionDate.getMonth(),
        1
      );
      const endOfMonth = new Date(
        transactionDate.getFullYear(),
        transactionDate.getMonth() + 1,
        0
      );

      const transactionsSnapshot = await db
        .collection("users")
        .doc(userId)
        .collection("transactions")
        .where("categoryId", "==", categoryId)
        .where("type", "==", "expense")
        .where("date", ">=", startOfMonth)
        .where("date", "<=", endOfMonth)
        .get();

      const totalSpent = transactionsSnapshot.docs.reduce(
        (sum, doc) => sum + (doc.data().amount || 0),
        0
      );

      const percentUsed = (totalSpent / budget.amount) * 100;

      // Send warning at 80% and alert at 100%
      if (percentUsed >= 100 && budget.lastAlertPercent !== 100) {
        const title = "🚨 Budget Exceeded!";
        const body =
          `You've exceeded your ${budget.name} budget! ` +
          `Spent ₹${totalSpent.toFixed(0)} of ₹${budget.amount.toFixed(0)}`;

        await sendNotification(userId, title, body, {
          type: "budget_exceeded",
          budgetId: budgetDoc.id,
          percentUsed: percentUsed.toString(),
        });

        await storeInAppNotification(userId, "budgetWarning", title, body, {
          budgetId: budgetDoc.id,
          spent: totalSpent,
          limit: budget.amount,
        });

        // Update last alert percent
        await budgetDoc.ref.update({lastAlertPercent: 100});
      } else if (
        percentUsed >= 80 &&
        percentUsed < 100 &&
        (budget.lastAlertPercent || 0) < 80
      ) {
        const title = "⚠️ Budget Warning";
        const body =
          `You've used ${percentUsed.toFixed(0)}% of your ${budget.name} ` +
          `budget (₹${totalSpent.toFixed(0)} of ₹${budget.amount.toFixed(0)})`;

        await sendNotification(userId, title, body, {
          type: "budget_warning",
          budgetId: budgetDoc.id,
          percentUsed: percentUsed.toString(),
        });

        await storeInAppNotification(userId, "budgetWarning", title, body, {
          budgetId: budgetDoc.id,
          spent: totalSpent,
          limit: budget.amount,
        });

        await budgetDoc.ref.update({lastAlertPercent: 80});
      }
    }
  }
);

// ============================================================
// SUBSCRIPTION REMINDERS
// ============================================================

/**
 * Scheduled function: Check for upcoming subscription renewals
 * Runs daily at 9 AM IST
 */
export const checkSubscriptionReminders = onSchedule(
  {
    schedule: "0 9 * * *", // 9 AM daily
    timeZone: "Asia/Kolkata",
  },
  async () => {
    const now = new Date();
    const threeDaysFromNow = new Date(
      now.getTime() + 3 * 24 * 60 * 60 * 1000
    );

    const usersSnapshot = await db.collection("users").get();

    for (const userDoc of usersSnapshot.docs) {
      const subscriptionsSnapshot = await db
        .collection("users")
        .doc(userDoc.id)
        .collection("subscriptions")
        .where("nextBillingDate", "<=", threeDaysFromNow)
        .where("nextBillingDate", ">=", now)
        .where("isActive", "==", true)
        .get();

      for (const subDoc of subscriptionsSnapshot.docs) {
        const sub = subDoc.data();
        const daysUntil = Math.ceil(
          (sub.nextBillingDate.toDate().getTime() - now.getTime()) /
            (24 * 60 * 60 * 1000)
        );

        let title: string;
        let body: string;

        if (daysUntil === 0) {
          title = "🔔 Subscription Due Today";
          body = `${sub.name} (₹${sub.amount}) renews today!`;
        } else if (daysUntil === 1) {
          title = "🔔 Subscription Due Tomorrow";
          body = `${sub.name} (₹${sub.amount}) renews tomorrow!`;
        } else {
          title = "🔔 Upcoming Subscription";
          body = `${sub.name} (₹${sub.amount}) renews in ${daysUntil} days`;
        }

        await sendNotification(userDoc.id, title, body, {
          type: "subscription_reminder",
          subscriptionId: subDoc.id,
        });

        await storeInAppNotification(
          userDoc.id,
          "subscriptionReminder",
          title,
          body,
          {
            subscriptionId: subDoc.id,
            name: sub.name,
            amount: sub.amount,
          }
        );
      }
    }

    logger.info("Subscription reminders check completed");
  }
);

// ============================================================
// DEBT/EMI PAYMENT REMINDERS
// ============================================================

/**
 * Scheduled function: Check for upcoming EMI/debt payments
 * Runs daily at 9:30 AM IST
 */
export const checkDebtReminders = onSchedule(
  {
    schedule: "30 9 * * *", // 9:30 AM daily
    timeZone: "Asia/Kolkata",
  },
  async () => {
    const now = new Date();
    const threeDaysFromNow = new Date(
      now.getTime() + 3 * 24 * 60 * 60 * 1000
    );

    const usersSnapshot = await db.collection("users").get();

    for (const userDoc of usersSnapshot.docs) {
      // Check debts collection
      const debtsSnapshot = await db
        .collection("users")
        .doc(userDoc.id)
        .collection("debts")
        .where("nextDueDate", "<=", threeDaysFromNow)
        .where("nextDueDate", ">=", now)
        .where("currentBalance", ">", 0)
        .get();

      for (const debtDoc of debtsSnapshot.docs) {
        const debt = debtDoc.data();
        const dueDate = debt.nextDueDate.toDate();
        const daysUntil = Math.ceil(
          (dueDate.getTime() - now.getTime()) / (24 * 60 * 60 * 1000)
        );

        const emiAmount = debt.emiAmount || debt.monthlyPayment;
        const emiStr = emiAmount ? `₹${emiAmount.toFixed(0)}` : "N/A";

        let title: string;
        let body: string;

        if (daysUntil <= 0) {
          title = "⚠️ EMI Overdue!";
          body = `${debt.name} EMI of ${emiStr} was due!`;
        } else if (daysUntil === 1) {
          title = "⏰ EMI Due Tomorrow";
          body = `${debt.name} EMI of ${emiStr} is due tomorrow`;
        } else {
          title = "📅 Upcoming EMI";
          body = `${debt.name} EMI of ${emiStr} due in ${daysUntil} days`;
        }

        await sendNotification(userDoc.id, title, body, {
          type: "debt_reminder",
          debtId: debtDoc.id,
        });

        await storeInAppNotification(
          userDoc.id,
          "debtReminder",
          title,
          body,
          {
            debtId: debtDoc.id,
            name: debt.name,
            amount: debt.emiAmount || debt.monthlyPayment,
            dueDate: dueDate.toISOString(),
          }
        );
      }
    }

    logger.info("Debt/EMI reminders check completed");
  }
);

// ============================================================
// DEBT PAYOFF CELEBRATION
// ============================================================

/**
 * Trigger: When a debt is updated
 * Action: Check if debt is fully paid and store in-app notification only
 * Note: Push notifications reserved for personal debts - no push for personal
 */
export const onDebtUpdated =
  onDocumentUpdated(
    "users/{userId}/debts/{debtId}",
    async (event) => {
      const before = event.data?.before.data();
      const after = event.data?.after.data();
      if (!before || !after) return;

      const userId = event.params.userId;

      // Check if debt was just paid off
      const wasPaidOff =
      (before.currentBalance > 0 && after.currentBalance <= 0) ||
      (before.isActive === true &&
        after.isActive === false &&
        after.currentBalance <= 0);

      if (wasPaidOff) {
        const title = "🎉 Congratulations!";
        const totalPaid = after.totalAmount?.toFixed(0) || "N/A";
        const body =
          `Paid off "${after.name}"! Rs ${totalPaid}`;

        // Only store in-app notification - no push notification for personal debts
        // Push notifications are reserved for family/split debt activities
        await storeInAppNotification(
          userId,
          "debtPayoff",
          title,
          body,
          {
            debtId: event.params.debtId,
            name: after.name,
            totalPaid: after.totalAmount,
            paidOffDate: new Date().toISOString(),
          }
        );

        logger.info(`Debt ${after.name} paid off by user ${userId}!`);
      }
    }
  );

/**
 * Scheduled function: Auto-log subscription payments due today
 * Runs daily at 00:05 AM IST
 */
export const autoLogSubscriptionPayments = onSchedule(
  {
    schedule: "5 0 * * *", // 00:05 AM daily
    timeZone: "Asia/Kolkata",
  },
  async () => {
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

    const usersSnapshot = await db.collection("users").get();
    for (const userDoc of usersSnapshot.docs) {
      const subscriptionsSnapshot = await db
        .collection("users")
        .doc(userDoc.id)
        .collection("subscriptions")
        .where("nextBillingDate", "<=", today)
        .where("isActive", "==", true)
        .get();

      for (const subDoc of subscriptionsSnapshot.docs) {
        const sub = subDoc.data();
        // Create transaction
        const txnRef = db
          .collection("users")
          .doc(userDoc.id)
          .collection("transactions")
          .doc();
        await txnRef.set({
          userId: userDoc.id,
          accountId: sub.accountId || null,
          type: "expense",
          amount: sub.amount,
          description: `Subscription: ${sub.name}`,
          categoryId: sub.categoryId || "subscriptions",
          date: admin.firestore.Timestamp.fromDate(today),
          metadata: {
            source: "subscription",
            subscriptionId: subDoc.id,
            subscriptionName: sub.name,
          },
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Update nextDueDate (monthly)
        const nextDueDate = new Date(today);
        nextDueDate.setMonth(nextDueDate.getMonth() + 1);
        await subDoc.ref.update({
          nextBillingDate: admin.firestore.Timestamp.fromDate(nextDueDate),
        });

        const subName = sub.name;
        const msg =
          `Auto-logged subscription payment for ${subName} ` +
          `(user ${userDoc.id}) updated nextDueDate.`;
        logger.info(msg);
      }
    }
    logger.info("Auto-log subscription payments completed");
  }
);

logger.info("Nexus Cloud Functions initialized");
