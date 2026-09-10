import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/category.dart';
import '../../core/models/knowledge_entry.dart';
import '../../core/models/transaction_relationship.dart';
import '../../core/providers/category_provider.dart';
import '../../core/providers/knowledge_provider.dart';
import '../../core/providers/transaction_relationship_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/nexus_card.dart';

class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen> {
  String _query = '';
  KnowledgeKind? _filter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<KnowledgeProvider>().refresh();
      context.read<TransactionRelationshipProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Knowledge')),
      body: Consumer2<KnowledgeProvider, TransactionRelationshipProvider>(
        builder: (context, knowledge, relationships, _) {
          final entries = knowledge.entries.where((entry) {
            final q = _query.trim().toLowerCase();
            final matchesQuery = q.isEmpty ||
                '${entry.subject} ${entry.predicate} ${entry.object}'
                    .toLowerCase()
                    .contains(q);
            return matchesQuery && (_filter == null || entry.kind == _filter);
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                'What Nexus has learned',
                style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Your rules, patterns and corrections. You can remove anything here.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
              ),
              Builder(builder: (context) {
                final conflictSubjects = <String>{};
                final grouped = <String, List<KnowledgeEntry>>{};
                for (final entry in knowledge.entries.where((e) => e.active && (e.predicate == 'category' || e.predicate == 'purpose'))) {
                  grouped.putIfAbsent('${entry.subject}|${entry.predicate}', () => []).add(entry);
                }
                for (final items in grouped.values) {
                  if (items.map((e) => e.object).toSet().length > 1 && items.isNotEmpty) {
                    conflictSubjects.add(items.first.subject);
                  }
                }
                if (conflictSubjects.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: NexusCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.warning_amber_rounded),
                      title: const Text('Conflicting rules need attention'),
                      subtitle: Text('${conflictSubjects.length} ${conflictSubjects.length == 1 ? 'entry has' : 'entries have'} different saved meanings. Nexus will ask instead of guessing.'),
                    ),
                  ),
                );
              }),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search Knowledge',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () => setState(() => _query = ''),
                        ),
                  border: OutlineInputBorder(borderRadius: AppSpacing.borderRadiusMd),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _filterChip('All', null),
                    ...KnowledgeKind.values.map((kind) => _filterChip(_kindLabel(kind), kind)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (knowledge.isLoading && entries.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: CircularProgressIndicator(),
                ))
              else if (entries.isEmpty)
                NexusCard(
                  child: Column(
                    children: [
                      Icon(Icons.psychology_alt_outlined, size: 42, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Nothing here yet', style: AppTypography.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'When you correct or teach Nexus something, it can appear here.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                )
              else
                ...entries.map((entry) => _knowledgeTile(entry)),
              if (relationships.relationships.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                Text('Transaction relationships', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.sm),
                ...relationships.relationships.map((relationship) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: NexusCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.link_rounded),
                      title: Text(_relationshipLabel(relationship.type)),
                      subtitle: Text('${relationship.transactionIds.length} transactions · ${relationship.reason}'),
                      trailing: IconButton(
                        tooltip: 'Separate',
                        icon: const Icon(Icons.link_off_rounded),
                        onPressed: () => _separateRelationship(relationship.id),
                      ),
                    ),
                  ),
                )),
              ],
              if (knowledge.entries.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                TextButton.icon(
                  onPressed: () => _confirmForgetAll(),
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Forget all Knowledge'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _filterChip(String label, KnowledgeKind? value) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: ChoiceChip(
        label: Text(label),
        selected: _filter == value,
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }

  Widget _knowledgeTile(KnowledgeEntry entry) {
    final categoryName = _categoryName(entry.object);
    final value = entry.predicate == 'category' && categoryName != null
        ? categoryName
        : entry.object;
    return NexusCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: AppColors.accentTeal.withValues(alpha: 0.12),
          child: Icon(_kindIcon(entry.kind), color: AppColors.accentTeal),
        ),
        title: Text(entry.subject.isEmpty ? 'Unknown' : entry.subject),
        subtitle: Text('${_kindLabel(entry.kind)} · ${entry.predicate}: $value'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _editKnowledge(entry);
            } else if (value == 'forget') {
              context.read<KnowledgeProvider>().forget(entry.id);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'forget', child: Text('Forget')),
          ],
        ),
      ),
    );
  }

  String? _categoryName(String id) {
    for (final Category category in context.read<CategoryProvider>().categories) {
      if (category.id == id) return '${category.emoji} ${category.name}';
    }
    return null;
  }

  Future<void> _editKnowledge(KnowledgeEntry entry) async {
    final subjectController = TextEditingController(text: entry.subject);
    final objectController = TextEditingController(text: entry.object);
    final predicateController = TextEditingController(text: entry.predicate);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Knowledge'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: subjectController, decoration: const InputDecoration(labelText: 'Subject')),
              const SizedBox(height: 10),
              TextField(controller: predicateController, decoration: const InputDecoration(labelText: 'Meaning')),
              const SizedBox(height: 10),
              TextField(controller: objectController, decoration: const InputDecoration(labelText: 'Value')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save')),
        ],
      ),
    );
    if (result == true && mounted) {
      final subject = subjectController.text.trim();
      final predicate = predicateController.text.trim();
      final object = objectController.text.trim();
      if (subject.isEmpty || predicate.isEmpty || object.isEmpty) return;
      await context.read<KnowledgeProvider>().saveEntry(
        entry.copyWith(
          subject: subject,
          predicate: predicate,
          object: object,
          source: KnowledgeSource.explicit,
          confidence: 1.0,
          updatedAt: DateTime.now(),
        ),
      );
    }
    subjectController.dispose();
    predicateController.dispose();
    objectController.dispose();
  }

  Future<void> _separateRelationship(String id) async {
    await context.read<TransactionRelationshipProvider>().separate(id);
  }

  Future<void> _confirmForgetAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forget all Knowledge?'),
        content: const Text('This removes learned rules and corrections. Your transactions are not deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Forget all')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<KnowledgeProvider>().forgetAll();
    }
  }

  String _kindLabel(KnowledgeKind kind) => switch (kind) {
        KnowledgeKind.entity => 'Entities',
        KnowledgeKind.purpose => 'Purposes',
        KnowledgeKind.relationship => 'Relationships',
        KnowledgeKind.rule => 'Rules',
        KnowledgeKind.pattern => 'Patterns',
        KnowledgeKind.exception => 'Exceptions',
      };

  IconData _kindIcon(KnowledgeKind kind) => switch (kind) {
        KnowledgeKind.entity => Icons.person_search_rounded,
        KnowledgeKind.purpose => Icons.label_outline_rounded,
        KnowledgeKind.relationship => Icons.link_rounded,
        KnowledgeKind.rule => Icons.rule_rounded,
        KnowledgeKind.pattern => Icons.repeat_rounded,
        KnowledgeKind.exception => Icons.warning_amber_rounded,
      };

  String _relationshipLabel(TransactionRelationshipType type) => switch (type) {
        TransactionRelationshipType.transferPair => 'Transfer pair',
        TransactionRelationshipType.refund => 'Refund',
        TransactionRelationshipType.recurringSeries => 'Recurring series',
        TransactionRelationshipType.relatedPayment => 'Related payment',
        TransactionRelationshipType.duplicate => 'Possible duplicate',
      };
}
