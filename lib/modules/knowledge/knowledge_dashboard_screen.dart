import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/providers/knowledge_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/models/knowledge/merchant_knowledge.dart';

/// Knowledge Dashboard - View and manage what Nexus has learned
class KnowledgeDashboardScreen extends StatefulWidget {
  const KnowledgeDashboardScreen({super.key});

  @override
  State<KnowledgeDashboardScreen> createState() => _KnowledgeDashboardScreenState();
}

class _KnowledgeDashboardScreenState extends State<KnowledgeDashboardScreen> {
  String _searchQuery = '';
  String _filterType = 'all'; // all, active, disabled

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final knowledgeProvider = KnowledgeProvider(
      firestore: FirebaseFirestore.instance,
      userId: userId,
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBlack,
        elevation: 0,
        title: Text(
          'What Nexus Knows',
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppColors.textSecondary),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter
          _buildSearchAndFilter(knowledgeProvider),
          
          // Stats Summary
          _buildStatsSummary(knowledgeProvider),
          
          // Merchant List
          Expanded(
            child: _buildMerchantList(knowledgeProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddManualKnowledgeDialog(knowledgeProvider),
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Teach Nexus', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildSearchAndFilter(KnowledgeProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search merchants...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
              filled: true,
              fillColor: AppColors.cardSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          
          // Filter Chips
          Row(
            children: [
              _FilterChip(
                label: 'All',
                isSelected: _filterType == 'all',
                onTap: () => setState(() => _filterType = 'all'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Active',
                isSelected: _filterType == 'active',
                onTap: () => setState(() => _filterType = 'active'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Disabled',
                isSelected: _filterType == 'disabled',
                onTap: () => setState(() => _filterType = 'disabled'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary(KnowledgeProvider provider) {
    return FutureBuilder<KnowledgeStats>(
      future: provider.getStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        
        final stats = snapshot.data!;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryBlue.withOpacity(0.2), AppColors.accentTeal.withOpacity(0.2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: 'Merchants',
                value: stats.merchantCount.toString(),
                icon: Icons.store,
                color: AppColors.primaryBlue,
              ),
              _StatItem(
                label: 'Auto-Approval',
                value: '${stats.recognitionRate}%',
                icon: Icons.auto_awesome,
                color: AppColors.success,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMerchantList(KnowledgeProvider provider) {
    return StreamBuilder<List<MerchantKnowledge>>(
      stream: provider.watchAllMerchants(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Error loading knowledge', style: AppTypography.bodyLarge.copyWith(color: AppColors.error)),
              ],
            ),
          );
        }

        var merchants = snapshot.data ?? [];

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          merchants = merchants.where((m) {
            return m.name.toLowerCase().contains(query) ||
                   m.normalizedName.contains(query);
          }).toList();
        }

        // Apply type filter
        if (_filterType == 'active') {
          merchants = merchants.where((m) => !m.isDisabled).toList();
        } else if (_filterType == 'disabled') {
          merchants = merchants.where((m) => m.isDisabled).toList();
        }

        if (merchants.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lightbulb_outline, size: 64, color: AppColors.textTertiary),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty 
                    ? 'Nexus hasn\'t learned any merchants yet'
                    : 'No merchants found',
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.textTertiary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Use the app normally and Nexus will learn automatically',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: merchants.length,
          itemBuilder: (context, index) {
            final merchant = merchants[index];
            return _MerchantCard(
              merchant: merchant,
              onToggle: () => provider.toggleMerchantKnowledge(merchant.id, !merchant.isDisabled),
              onDelete: () => _confirmDelete(context, provider, merchant),
              onEdit: () => _showEditKnowledgeDialog(context, provider, merchant),
            );
          },
        );
      },
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('How Nexus Learns', style: AppTypography.titleLarge.copyWith(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _InfoItem(
                icon: Icons.auto_awesome,
                title: 'Automatic Learning',
                description: 'Nexus learns from every transaction you approve. Over time, it recognizes patterns and auto-categorizes.',
              ),
              const SizedBox(height: 16),
              _InfoItem(
                icon: Icons.edit,
                title: 'Manual Teaching',
                description: 'You can manually teach Nexus about merchants using the + button. This is useful for new merchants.',
              ),
              const SizedBox(height: 16),
              _InfoItem(
                icon: Icons.visibility_off,
                title: 'Disable Knowledge',
                description: 'Toggle off any learned knowledge that\'s incorrect. Nexus will stop using it for auto-categorization.',
              ),
              const SizedBox(height: 16),
              _InfoItem(
                icon: Icons.delete_outline,
                title: 'Delete Knowledge',
                description: 'Remove incorrect knowledge entirely. This doesn\'t delete transactions, just what Nexus learned.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it', style: AppTypography.labelLarge.copyWith(color: AppColors.primaryBlue)),
          ),
        ],
      ),
    );
  }

  void _showAddManualKnowledgeDialog(KnowledgeProvider provider) {
    final nameController = TextEditingController();
    String? selectedCategory;
    bool isRecurring = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Teach Nexus', style: AppTypography.titleLarge.copyWith(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Enter a merchant name to teach Nexus:', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Merchant Name',
                    hintText: 'e.g., Starbucks, Netflix, Amazon',
                    filled: true,
                    fillColor: AppColors.backgroundBlack,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                Text('Is this a recurring payment?', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: Text('Recurring', style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
                  value: isRecurring,
                  onChanged: (value) => setDialogState(() => isRecurring = value),
                  activeColor: AppColors.primaryBlue,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                
                final knowledge = MerchantKnowledge(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  normalizedName: nameController.text.trim().toLowerCase(),
                  category: selectedCategory ?? 'Uncategorized',
                  isRecurring: isRecurring,
                  confidenceScores: {'merchant': 100, 'category': 80},
                  lastSeen: Timestamp.now(),
                  occurrenceCount: 1,
                  createdAt: Timestamp.now(),
                  updatedAt: Timestamp.now(),
                );
                
                await provider.saveMerchantKnowledge(knowledge);
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Save', style: AppTypography.labelLarge.copyWith(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditKnowledgeDialog(BuildContext context, KnowledgeProvider provider, MerchantKnowledge merchant) {
    // Simplified edit dialog - can be enhanced later
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: Text('Edit: ${merchant.name}', style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Category: ${merchant.category}', style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text('Recurring: ${merchant.isRecurring ? "Yes" : "No"}', style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text('Times seen: ${merchant.occurrenceCount}', style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: AppTypography.labelLarge.copyWith(color: AppColors.primaryBlue)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, KnowledgeProvider provider, MerchantKnowledge merchant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: Text('Delete Knowledge?', style: AppTypography.titleMedium.copyWith(color: AppColors.error)),
        content: Text(
          'This will remove what Nexus learned about "${merchant.name}". Transactions will not be deleted.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              await provider.deleteMerchantKnowledge(merchant.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Delete', style: AppTypography.labelLarge.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, style: AppTypography.labelSmall.copyWith(
        color: isSelected ? Colors.white : AppColors.textSecondary,
      )),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: AppColors.cardSurface,
      selectedColor: AppColors.primaryBlue,
      checkmarkColor: Colors.white,
      labelStyle: AppTypography.labelSmall,
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(value, style: AppTypography.headlineMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary)),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoItem({required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primaryBlue, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(description, style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _MerchantCard extends StatelessWidget {
  final MerchantKnowledge merchant;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _MerchantCard({
    required this.merchant,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: merchant.isDisabled 
            ? AppColors.textTertiary.withOpacity(0.3)
            : AppColors.primaryBlue.withOpacity(0.3),
        ),
        opacity: merchant.isDisabled ? 0.6 : 1.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                merchant.isRecurring ? Icons.repeat : Icons.store,
                color: merchant.isDisabled ? AppColors.textTertiary : AppColors.primaryBlue,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      merchant.name,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            merchant.category,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (merchant.isRecurring) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentTeal.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Recurring',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.accentTeal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Switch(
                value: !merchant.isDisabled,
                onChanged: (_) => onToggle(),
                activeColor: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 18),
                label: Text('Edit', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text('Delete', style: AppTypography.labelSmall.copyWith(color: AppColors.error)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
