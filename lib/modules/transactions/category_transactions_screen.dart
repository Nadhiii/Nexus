import 'package:flutter/material.dart';
import '../../core/widgets/translucent_app_bar.dart';
import 'transaction_detail_screen.dart';
import 'transactions_screen.dart';

class CategoryTransactionsScreen extends StatefulWidget {
  final String categoryName;
  final List<Transaction> transactions;
  final Color categoryColor;
  final IconData categoryIcon;

  const CategoryTransactionsScreen({
    super.key,
    required this.categoryName,
    required this.transactions,
    required this.categoryColor,
    required this.categoryIcon,
  });

  @override
  State<CategoryTransactionsScreen> createState() =>
      _CategoryTransactionsScreenState();
}

class _CategoryTransactionsScreenState
    extends State<CategoryTransactionsScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedTransactions = <String>{};
  late List<Transaction> _transactions;

  @override
  void initState() {
    super.initState();
    _transactions = List.from(widget.transactions);
  }

  void _toggleSelection(String transactionId) {
    setState(() {
      if (_selectedTransactions.contains(transactionId)) {
        _selectedTransactions.remove(transactionId);
        if (_selectedTransactions.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedTransactions.add(transactionId);
        _isSelectionMode = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedTransactions.clear();
      _isSelectionMode = false;
    });
  }

  void _deleteSelected() {
    final transactionsToDelete = _transactions
        .where((t) => _selectedTransactions.contains(t.id))
        .toList();

    setState(() {
      _transactions.removeWhere((t) => _selectedTransactions.contains(t.id));
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${transactionsToDelete.length} transaction(s) deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _transactions.addAll(transactionsToDelete);
            });
          },
        ),
      ),
    );
    _clearSelection();
  }

  void _editTransaction(Transaction transaction) async {
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (context) => TransactionDetailScreen(
          transactionId: transaction.id,
          title: transaction.title,
          category: transaction.category,
          date: transaction.date,
          amount: transaction.amount,
          isExpense: transaction.isExpense,
          icon: transaction.icon,
          color: transaction.color,
        ),
      ),
    );

    if (result != null) {
      if (result == 'deleted') {
        setState(() {
          _transactions.removeWhere((t) => t.id == transaction.id);
        });
      } else if (result is Map<String, dynamic>) {
        setState(() {
          final index = _transactions.indexWhere((t) => t.id == transaction.id);
          if (index != -1) {
            _transactions[index] = Transaction(
              id: result['id'],
              title: result['title'],
              category: result['category'],
              date: transaction.date,
              amount: result['amount'],
              isExpense: result['isExpense'],
              icon: transaction.icon,
              color: transaction.color,
            );
          }
        });
      }
    }
  }

  void _deleteTransaction(Transaction transaction) {
    final originalIndex = _transactions.indexOf(transaction);

    setState(() {
      _transactions.remove(transaction);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Transaction "${transaction.title}" deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _transactions.insert(originalIndex, transaction);
            });
          },
        ),
      ),
    );
  }

  double get _totalAmount {
    return _transactions.fold(0.0, (sum, transaction) {
      return sum +
          (transaction.isExpense ? -transaction.amount : transaction.amount);
    });
  }

  int get _transactionCount => _transactions.length;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Return the modified transaction list when navigating back
        Navigator.of(context).pop(_transactions);
        return false; // We handle the pop ourselves
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: TranslucentAppBar(
          title: _isSelectionMode
              ? Text('${_selectedTransactions.length} selected')
              : Text(widget.categoryName),
          leading: _isSelectionMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clearSelection,
                )
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(_transactions),
                ),
          actions: _isSelectionMode
              ? [
                  IconButton(
                    icon: const Icon(Icons.select_all),
                    onPressed: () {
                      setState(() {
                        if (_selectedTransactions.length ==
                            _transactions.length) {
                          _selectedTransactions.clear();
                          _isSelectionMode = false;
                        } else {
                          _selectedTransactions.addAll(
                            _transactions.map((t) => t.id),
                          );
                        }
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _deleteSelected,
                  ),
                ]
              : [
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () {
                      // TODO: Filter transactions within category
                    },
                  ),
                ],
        ),
        body: Column(
          children: [
            // Category Summary Header
            Container(
              margin: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                16,
                16,
              ),
              child: Card(
                color: widget.categoryColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: widget.categoryColor.withOpacity(0.2),
                        child: Icon(
                          widget.categoryIcon,
                          color: widget.categoryColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.categoryName,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_transactionCount transaction${_transactionCount != 1 ? 's' : ''}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_totalAmount >= 0 ? '+' : ''}₹${_totalAmount.abs().toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _totalAmount >= 0
                                      ? Colors.green
                                      : Colors.red,
                                ),
                          ),
                          Text(
                            'Total',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.7),
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Transactions List
            Expanded(
              child: _transactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No transactions in this category',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.7),
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = _transactions[index];
                        final isSelected = _selectedTransactions.contains(
                          transaction.id,
                        );

                        return Dismissible(
                          key: Key(transaction.id),
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            child: const Row(
                              children: [
                                Icon(Icons.edit, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Edit',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          secondaryBackground: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.delete, color: Colors.white),
                              ],
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.startToEnd) {
                              _editTransaction(transaction);
                              return false;
                            } else {
                              return await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Transaction'),
                                      content: Text(
                                        'Are you sure you want to delete "${transaction.title}"?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  ) ??
                                  false;
                            }
                          },
                          onDismissed: (direction) {
                            if (direction == DismissDirection.endToStart) {
                              _deleteTransaction(transaction);
                            }
                          },
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer
                                      .withOpacity(0.3)
                                : null,
                            child: ListTile(
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isSelectionMode)
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (_) =>
                                          _toggleSelection(transaction.id),
                                    )
                                  else
                                    CircleAvatar(
                                      backgroundColor: transaction.color
                                          .withOpacity(0.1),
                                      child: Icon(
                                        transaction.icon,
                                        color: transaction.color,
                                      ),
                                    ),
                                ],
                              ),
                              title: Text(transaction.title),
                              subtitle: Text(transaction.date),
                              trailing: Text(
                                '${transaction.isExpense ? '-' : '+'}₹${transaction.amount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: transaction.isExpense
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                              onTap: () {
                                if (_isSelectionMode) {
                                  _toggleSelection(transaction.id);
                                } else {
                                  _editTransaction(transaction);
                                }
                              },
                              onLongPress: () {
                                if (!_isSelectionMode) {
                                  _toggleSelection(transaction.id);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
