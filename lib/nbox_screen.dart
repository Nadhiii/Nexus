import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/nbox_provider.dart';
import 'core/services/sms_inbox_service.dart';
import 'core/widgets/translucent_app_bar.dart';
import 'nbox_item_detail_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class NBoxScreen extends StatelessWidget {
  const NBoxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: TranslucentAppBar(
        title: const Text('NBox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Scan SMS',
            onPressed: () async {
              // Request permission if needed
              final status = await Permission.sms.request();
              if (!status.isGranted && !status.isLimited) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('SMS permission denied.')),
                  );
                }
                return;
              }

              // Fetch recent SMS and simulate detections (hook real parser later)
              final service = SmsInboxService();
              final detected = await service.detectTransactions(days: 14);
              if (detected.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No transactions detected in recent SMS.'),
                    ),
                  );
                }
              } else {
                context.read<NBoxProvider>().addDetectedAll(detected);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.checklist_rtl),
            tooltip: 'Approve All',
            onPressed: () {
              context.read<NBoxProvider>().approveAll();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear',
            onPressed: () {
              context.read<NBoxProvider>().clearAll();
            },
          ),
        ],
      ),
      body: Consumer<NBoxProvider>(
        builder: (context, nbox, _) {
          if (nbox.pending.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  MediaQuery.of(context).padding.top +
                      kToolbarHeight +
                      16, // Safe area + app bar + extra padding
                  24,
                  MediaQuery.of(context).padding.bottom +
                      90 +
                      16, // Safe area + nav bar (70) + margin (20) + extra padding
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.inbox_outlined, size: 64),
                    const SizedBox(height: 12),
                    const Text(
                      'No pending items',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap Scan SMS to import recent messages and detect transactions.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () async {
                        final status = await Permission.sms.request();
                        if (!status.isGranted && !status.isLimited) return;
                        final service = SmsInboxService();
                        final detected = await service.detectTransactions(
                          days: 14,
                        );
                        if (detected.isNotEmpty) {
                          context.read<NBoxProvider>().addDetectedAll(detected);
                        }
                      },
                      icon: const Icon(Icons.sync),
                      label: const Text('Scan SMS'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top +
                  kToolbarHeight +
                  16, // Safe area + app bar + extra padding
              16,
              MediaQuery.of(context).padding.bottom +
                  90 +
                  16, // Safe area + nav bar (70) + margin (20) + extra padding
            ),
            itemCount: nbox.pending.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = nbox.pending[index];
              return Dismissible(
                key: Key(item.id),
                background: Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Approve',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                secondaryBackground: Container(
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
                        'Reject',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.cancel, color: Colors.white),
                    ],
                  ),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    // Approve action
                    context.read<NBoxProvider>().approve(item.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Transaction "${item.title}" approved'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    return true;
                  } else {
                    // Reject action
                    context.read<NBoxProvider>().reject(item.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Transaction "${item.title}" rejected'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return true;
                  }
                },
                child: Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                      child: const Icon(Icons.sms, color: Colors.blue),
                    ),
                    title: Text(item.title),
                    subtitle: Text(
                      'Amount ₹${item.amount.toStringAsFixed(2)} • ${item.source}',
                    ),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          tooltip: 'Approve',
                          icon: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                          onPressed: () {
                            context.read<NBoxProvider>().approve(item.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Transaction "${item.title}" approved',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                        ),
                        IconButton(
                          tooltip: 'Reject',
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () {
                            context.read<NBoxProvider>().reject(item.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Transaction "${item.title}" rejected',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    onTap: () async {
                      final result = await Navigator.of(context).push<String>(
                        MaterialPageRoute(
                          builder: (context) => NBoxItemDetailScreen(
                            itemId: item.id,
                            title: item.title,
                            amount: item.amount,
                            source: item.source,
                          ),
                        ),
                      );

                      if (result == 'approved') {
                        context.read<NBoxProvider>().approve(item.id);
                      } else if (result == 'rejected') {
                        context.read<NBoxProvider>().reject(item.id);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
