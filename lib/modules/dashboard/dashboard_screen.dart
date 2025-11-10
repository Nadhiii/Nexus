import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/dashboard_preferences_provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/widgets/dashboard/dashboard_widget_renderer.dart';
import '../../core/theme/app_theme.dart';
import '../../dashboard_widget_preferences.dart';
import '../notifications/notifications_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DashboardPreferencesProvider()..loadPreferences(),
      child: const DashboardScreenContent(),
    );
  }
}

class DashboardScreenContent extends StatelessWidget {
  const DashboardScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<DashboardPreferencesProvider>(
      builder: (context, dashboardProvider, child) {
        return Scaffold(
          backgroundColor: colorScheme.background,
          body: RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(seconds: 1));
            },
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(context, dashboardProvider, colorScheme),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final widget = dashboardProvider.visibleWidgets[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: dashboardProvider.isEditMode
                              ? _buildEditableWidget(context, widget, dashboardProvider)
                              : DashboardWidgetRenderer(widget: widget, isEditMode: false),
                        );
                      },
                      childCount: dashboardProvider.visibleWidgets.length,
                    ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: dashboardProvider.isEditMode
              ? FloatingActionButton(
                  heroTag: 'fab-dashboard',
                  onPressed: () => _showWidgetSelector(context, dashboardProvider),
                  child: const Icon(Icons.add),
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  SliverAppBar _buildSliverAppBar(
      BuildContext context, DashboardPreferencesProvider dashboardProvider, ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: colorScheme.background.withAlpha(220), // Translucency
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text(
          _getGreeting(),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: colorScheme.onBackground,
          ),
        ),
      ),
      actions: [
        // Edit mode toggle
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: Material(
            color: dashboardProvider.isEditMode ? colorScheme.primary : colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => dashboardProvider.toggleEditMode(),
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  dashboardProvider.isEditMode ? Icons.check : Icons.edit,
                  color: dashboardProvider.isEditMode ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        // Notification bell
        Container(
          margin: const EdgeInsets.only(right: 20),
          child: Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Material(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: Icon(Icons.notifications_outlined, color: colorScheme.onSurfaceVariant, size: 20),
                      ),
                    ),
                  ),
                  if (notificationProvider.hasUnread)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: colorScheme.error, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '${notificationProvider.unreadCount}',
                          style: TextStyle(color: colorScheme.onError, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildEditableWidget(
      BuildContext context, dynamic widget, DashboardPreferencesProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        DashboardWidgetRenderer(widget: widget, isEditMode: true),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _showWidgetOptions(context, widget, provider),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: colorScheme.secondaryContainer,
                  child: Icon(Icons.settings, size: 16, color: colorScheme.onSecondaryContainer),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => provider.hideWidget(widget.id),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: colorScheme.errorContainer,
                  child: Icon(Icons.visibility_off, size: 16, color: colorScheme.onErrorContainer),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showWidgetSelector(BuildContext context, DashboardPreferencesProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add Widget', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 20),
              if (provider.hiddenWidgets.isNotEmpty)
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12),
                    itemCount: provider.hiddenWidgets.length,
                    itemBuilder: (context, index) {
                      final widget = provider.hiddenWidgets[index];
                      return InkWell(
                        onTap: () {
                          provider.showWidget(widget.id);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(widget.icon, size: 24, color: colorScheme.onSecondaryContainer),
                              const SizedBox(height: 8),
                              Text(widget.title, style: theme.textTheme.titleSmall?.copyWith(
                                color: colorScheme.onSecondaryContainer
                              )),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline, size: 48, color: colorScheme.onSurface.withOpacity(0.4)),
                      const SizedBox(height: 12),
                      Text('All widgets are visible', style: theme.textTheme.titleMedium),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWidgetOptions(
      BuildContext context, dynamic widget, DashboardPreferencesProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.title} Options', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 24),
            Text('Widget Size', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: DashboardWidgetSize.values.map((size) {
                return ChoiceChip(
                  label: Text(size.name[0].toUpperCase() + size.name.substring(1)),
                  selected: widget.size == size,
                  onSelected: (selected) {
                    if (selected) {
                      provider.updateWidgetSize(widget.id, size.name);
                      Navigator.pop(context);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  provider.hideWidget(widget.id);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.visibility_off),
                label: const Text('Hide Widget'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.errorContainer,
                  foregroundColor: colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
