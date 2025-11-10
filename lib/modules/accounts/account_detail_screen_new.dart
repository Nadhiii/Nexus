import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/models/account.dart';
import '../../core/models/transaction.dart';
import '../../core/providers/account_provider.dart';
import '../../core/providers/transaction_provider.dart';
import '../transactions/widgets/add_transaction_modal.dart';
import 'widgets/add_account_modal.dart';

class AccountDetailScreenNew extends StatefulWidget {
  final Account account;

  const AccountDetailScreenNew({super.key, required this.account});

  @override
  State<AccountDetailScreenNew> createState() => _AccountDetailScreenNewState();
}

class _AccountDetailScreenNewState extends State<AccountDetailScreenNew> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.account.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEditAccount(context),
          ),
        ],
      ),
      body: Consumer2<AccountProvider, TransactionProvider>(
        builder: (context, accountProvider, transactionProvider, child) {
          // Get the latest account data
          final currentAccount =
              accountProvider.getAccountById(widget.account.id) ??
              widget.account;
          final transactions = transactionProvider.getTransactionsForAccount(
            widget.account.id,
          );
          final summary = transactionProvider.getSummary(
            accountId: widget.account.id,
          );

          return Column(
            children: [
              // Account Balance Card
              _buildAccountBalanceCard(currentAccount, summary),

              // Quick Actions
              _buildQuickActions(context, currentAccount),

              // Transactions Section
              Expanded(
                child: _buildTransactionsSection(
                  context,
                  transactions,
                  transactionProvider,
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-account-detail-new-${widget.account.id}',
        onPressed: () => _navigateToAddTransaction(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
        backgroundColor: widget.account.color,
      ),
    );
  }

  Widget _buildAccountBalanceCard(
    Account account,
    Map<String, double> summary,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [account.color, account.color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: account.color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account Header
          Row(
            children: [
              Icon(account.icon, color: Colors.white, size: 28),
              const Spacer(),
              if (account.accountNumber != null)
                Text(
                  '****${account.accountNumber}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Account Name and Bank
          Text(
            account.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (account.bankName != null) ...[
            const SizedBox(height: 4),
            Text(
              account.bankName!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Current Balance
          Text(
            'Current Balance',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${account.balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          // Summary Row
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Income',
                  summary['income'] ?? 0,
                  Colors.green.shade300,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Expense',
                  summary['expense'] ?? 0,
                  Colors.red.shade300,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Net',
                  summary['balance'] ?? 0,
                  Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, Account account) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              'Add Income',
              Icons.trending_up,
              Colors.green,
              () => _navigateToAddTransaction(context, TransactionType.income),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              'Add Expense',
              Icons.trending_down,
              Colors.red,
              () => _navigateToAddTransaction(context, TransactionType.expense),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              'Transfer',
              Icons.swap_horiz,
              Colors.blue,
              () =>
                  _navigateToAddTransaction(context, TransactionType.transfer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color.withOpacity(0.1),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsSection(
    BuildContext context,
    List<Transaction> transactions,
    TransactionProvider transactionProvider,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${transactions.length} transactions',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: transactions.isEmpty
                ? _buildEmptyTransactions()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return _buildTransactionItem(
                        context,
                        transaction,
                        transactionProvider,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first transaction to see it here',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    Transaction transaction,
    TransactionProvider transactionProvider,
  ) {
    final isIncome = transaction.type == TransactionType.income;
    final isExpense = transaction.type == TransactionType.expense;
    final isTransfer = transaction.type == TransactionType.transfer;

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 24),
      ),
      confirmDismiss: (direction) => _confirmDelete(context, transaction),
      onDismissed: (direction) =>
          _deleteTransaction(context, transaction, transactionProvider),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          onTap: () => _editTransaction(context, transaction),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  (isIncome
                          ? Colors.green
                          : isExpense
                          ? Colors.red
                          : Colors.blue)
                      .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isIncome
                  ? Icons.trending_up
                  : isExpense
                  ? Icons.trending_down
                  : Icons.swap_horiz,
              color: isIncome
                  ? Colors.green
                  : isExpense
                  ? Colors.red
                  : Colors.blue,
              size: 20,
            ),
          ),
          title: Text(
            transaction.description ?? 'No description',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                transaction.categoryId ?? 'Uncategorized',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('MMM dd, yyyy • h:mm a').format(transaction.date),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ],
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${isIncome
                    ? '+'
                    : isExpense
                    ? '-'
                    : ''}₹${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isIncome
                      ? Colors.green
                      : isExpense
                      ? Colors.red
                      : Colors.blue,
                ),
              ),
              if (isTransfer && transaction.toAccountId != null) ...[
                const SizedBox(height: 2),
                Icon(
                  Icons.arrow_forward,
                  size: 12,
                  color: Colors.grey.shade500,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, Transaction transaction) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
          'Are you sure you want to delete "${transaction.description ?? 'this transaction'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteTransaction(
    BuildContext context,
    Transaction transaction,
    TransactionProvider transactionProvider,
  ) async {
    final success = await transactionProvider.deleteTransaction(transaction.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _editTransaction(BuildContext context, Transaction transaction) {
    showAddTransactionModal(
      context,
      accountId: widget.account.id,
      transactionToEdit: transaction,
    );
  }

  void _navigateToAddTransaction(
    BuildContext context, [
    TransactionType? type,
  ]) {
    showAddTransactionModal(
      context,
      accountId: widget.account.id,
      initialType: type,
    );
  }

  void _navigateToEditAccount(BuildContext context) {
    showAddAccountModal(
      context,
      accountToEdit: widget.account,
    );
  }
}
