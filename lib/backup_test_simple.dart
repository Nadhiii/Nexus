import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/services/backup_service.dart';

class BackupTestSimple extends StatefulWidget {
  const BackupTestSimple({super.key});

  @override
  State<BackupTestSimple> createState() => _BackupTestSimpleState();
}

class _BackupTestSimpleState extends State<BackupTestSimple> {
  final BackupService _backupService = BackupService();
  String _result = 'Ready to test backup';
  bool _isLoading = false;

  Future<void> _testBackup() async {
    if (FirebaseAuth.instance.currentUser == null) {
      setState(() {
        _result = '❌ Error: No user logged in';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _result = 'Creating backup...';
    });

    try {
      // Create backup and check what was found
      final backup = await _backupService.createBackup();

      final accountsCount = (backup['accounts'] as List?)?.length ?? 0;
      final transactionsCount = (backup['transactions'] as List?)?.length ?? 0;
      final debtsCount = (backup['debts'] as List?)?.length ?? 0;
      final budgetsCount = (backup['budgets'] as List?)?.length ?? 0;
      final investmentsCount = (backup['investments'] as List?)?.length ?? 0;
      final investmentTransactionsCount =
          (backup['investmentTransactions'] as List?)?.length ?? 0;
      final goalsCount = (backup['goals'] as List?)?.length ?? 0;
      final hasProfile = backup['userProfile'] != null;

      setState(() {
        _result =
            '''✅ Backup completed successfully!

Found data:
• Accounts: $accountsCount
• Transactions: $transactionsCount  
• Debts: $debtsCount
• Budgets: $budgetsCount
• Investments: $investmentsCount
• Investment Transactions: $investmentTransactionsCount
• Goals: $goalsCount
• User Profile: ${hasProfile ? 'Yes' : 'No'}

Expected: 3 accounts, 1 investment, 1 subscription, 1 budget, 1 debt
Note: Subscriptions are stored as recurring transactions''';
      });
    } catch (e) {
      setState(() {
        _result = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Current User: ${FirebaseAuth.instance.currentUser?.email ?? 'Not logged in'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _testBackup,
              child: _isLoading
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Creating Backup...'),
                      ],
                    )
                  : const Text('Test Backup Now'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _result,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
