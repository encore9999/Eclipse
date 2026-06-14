import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/subscriptions_provider.dart';
import '../../domain/entities/subscription.dart';

class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('add_subscription'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'name'.tr(),
                hintText: 'Eclipse Subscription',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://... или vless://... или vmess://...',
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              final name = _nameController.text.trim();
              final url = _urlController.text.trim();
              if (name.isNotEmpty && url.isNotEmpty) {
                ref.read(subscriptionsProvider.notifier).addSubscription(
                      name: name,
                      url: url,
                    );
                _nameController.clear();
                _urlController.clear();
                Navigator.pop(context);
              }
            },
            child: Text('add'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscriptionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? AppColors.backgroundGradient
                : [const Color(0xFFF8F7FF), const Color(0xFFF0EEFF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Row(
                  children: [
                    Text(
                      'subscriptions'.tr(),
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: () {
                        ref.read(subscriptionsProvider.notifier).updateAll();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: state.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      )
                    : state.subscriptions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.rss_feed_rounded,
                                  size: 64,
                                  color: AppColors.primary[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'no_servers'.tr(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 24),
                                OutlinedButton.icon(
                                  onPressed: _showAddDialog,
                                  icon: const Icon(Icons.add_rounded),
                                  label: Text('add_subscription'.tr()),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            physics: const BouncingScrollPhysics(),
                            itemCount: state.subscriptions.length,
                            itemBuilder: (context, index) => _SubscriptionCard(
                              subscription: state.subscriptions[index],
                              isUpdating: state.updatingId == state.subscriptions[index].id,
                              onUpdate: () => ref
                                  .read(subscriptionsProvider.notifier)
                                  .updateSubscription(state.subscriptions[index].id),
                              onDelete: () => _showDeleteConfirmation(
                                  state.subscriptions[index]),
                              onToggleAuto: () => ref
                                  .read(subscriptionsProvider.notifier)
                                  .toggleAutoUpdate(state.subscriptions[index].id),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.primary[600],
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  void _showDeleteConfirmation(Subscription sub) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_confirm'.tr()),
        content: Text('delete_confirm_desc'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              ref.read(subscriptionsProvider.notifier).deleteSubscription(sub.id);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final Subscription subscription;
  final bool isUpdating;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;
  final VoidCallback onToggleAuto;

  const _SubscriptionCard({
    required this.subscription,
    required this.isUpdating,
    required this.onUpdate,
    required this.onDelete,
    required this.onToggleAuto,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        border: Border.all(
          color: subscription.status == SubscriptionStatus.error
              ? AppColors.error.withOpacity(0.3)
              : (isDark ? AppColors.darkDivider : Colors.transparent),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: _statusColor().withOpacity(isDark ? 0.2 : 0.1),
                ),
                child: Icon(Icons.rss_feed_rounded, size: 20, color: _statusColor()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      subscription.formattedServerCount,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: subscription.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoItem(
                label: 'last_update'.tr(),
                value: subscription.formattedLastUpdate,
              ),
              const Spacer(),
              _InfoItem(
                label: 'next_update'.tr(),
                value: subscription.formattedNextUpdate,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ActionButton(
                icon: Icons.refresh_rounded,
                label: 'update'.tr(),
                isLoading: isUpdating,
                onTap: onUpdate,
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: subscription.isAutoUpdate
                    ? Icons.sync_rounded
                    : Icons.sync_disabled_rounded,
                label: subscription.isAutoUpdate ? 'auto'.tr() : 'manual'.tr(),
                isActive: subscription.isAutoUpdate,
                onTap: onToggleAuto,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                color: AppColors.error.withOpacity(0.7),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor() {
    switch (subscription.status) {
      case SubscriptionStatus.active:
        return AppColors.connected;
      case SubscriptionStatus.updating:
        return AppColors.connecting;
      case SubscriptionStatus.error:
        return AppColors.error;
      case SubscriptionStatus.paused:
        return AppColors.warning;
      case SubscriptionStatus.expired:
        return AppColors.disconnected;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final SubscriptionStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      SubscriptionStatus.active => (AppColors.connected, 'active'.tr()),
      SubscriptionStatus.updating => (AppColors.connecting, 'updating'.tr()),
      SubscriptionStatus.error => (AppColors.error, 'error'.tr()),
      SubscriptionStatus.paused => (AppColors.warning, 'paused'.tr()),
      SubscriptionStatus.expired => (AppColors.disconnected, 'expired'.tr()),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.15),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;
  final bool isActive;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isActive
              ? AppColors.primary[600]!.withOpacity(0.15)
              : Theme.of(context).colorScheme.surfaceVariant,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            isLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    icon,
                    size: 14,
                    color: isActive ? AppColors.primary[400] : null,
                  ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isActive ? AppColors.primary[400] : null,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}