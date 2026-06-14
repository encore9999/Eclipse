import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/servers/presentation/providers/servers_provider.dart';
import '../../../features/subscriptions/presentation/providers/subscriptions_provider.dart';
import '../../../features/servers/domain/entities/server.dart';
import '../../../features/subscriptions/domain/entities/subscription.dart';

class ServerListPanel extends ConsumerWidget {
  final String? currentServer;
  final Function(Server) onServerSelected;
  const ServerListPanel({super.key, this.currentServer, required this.onServerSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serversState = ref.watch(serversProvider);
    final subsState = ref.watch(subscriptionsProvider);
    final orphanServers = serversState.servers.where((s) => s.subscriptionId == null || s.subscriptionId!.isEmpty).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      children: [
        ...subsState.subscriptions.map((sub) => SubscriptionTile(
          subscription: sub,
          servers: serversState.servers.where((s) => s.subscriptionId == sub.id).toList(),
          currentServer: currentServer,
          onServerSelected: onServerSelected,
          onUpdate: () => ref.read(subscriptionsProvider.notifier).updateSubscription(sub.id),
          onDelete: () => _confirmDelete(context, ref, sub),
          onRename: () => _showRenameDialog(context, ref, sub),
        )),
        if (orphanServers.isNotEmpty)
          OrphanServersTile(servers: orphanServers, currentServer: currentServer, onServerSelected: onServerSelected),
        if (serversState.servers.isEmpty)
          Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('no_servers'.tr()))),
      ],
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Subscription sub) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete_confirm'.tr()),
        content: Text('delete_confirm_desc'.tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr())),
          FilledButton(onPressed: () { ref.read(subscriptionsProvider.notifier).deleteSubscription(sub.id); Navigator.pop(ctx); }, style: FilledButton.styleFrom(backgroundColor: AppColors.error), child: Text('delete'.tr())),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, Subscription sub) {
    final controller = TextEditingController(text: sub.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr())),
          FilledButton(onPressed: () { ref.read(subscriptionsProvider.notifier).renameSubscription(sub.id, controller.text); Navigator.pop(ctx); }, child: Text('save'.tr())),
        ],
      ),
    );
  }
}

class SubscriptionTile extends StatefulWidget {
  final Subscription subscription;
  final List<Server> servers;
  final String? currentServer;
  final Function(Server) onServerSelected;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;
  final VoidCallback onRename;
  const SubscriptionTile({required this.subscription, required this.servers, this.currentServer, required this.onServerSelected, required this.onUpdate, required this.onDelete, required this.onRename});
  @override
  State<SubscriptionTile> createState() => _SubscriptionTileState();
}

class _SubscriptionTileState extends State<SubscriptionTile> {
  bool _expanded = false;

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.edit), title: Text('rename'.tr()), onTap: () { Navigator.pop(ctx); widget.onRename(); }),
          ListTile(leading: Icon(Icons.delete, color: AppColors.error), title: Text('delete'.tr(), style: TextStyle(color: AppColors.error)), onTap: () { Navigator.pop(ctx); widget.onDelete(); }),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: isDark ? AppColors.darkCard : AppColors.lightSurface),
      child: Column(children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          onSecondaryTap: () => _showContextMenu(context),
          child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
            Icon(_expanded ? Icons.keyboard_arrow_down_rounded : Icons.chevron_right_rounded, color: AppColors.primary[400]),
            const SizedBox(width: 8),
            Expanded(child: Text(widget.subscription.name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
            Text('${widget.servers.length}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary[400])),
            const SizedBox(width: 8),
            GestureDetector(onTap: widget.onUpdate, child: Icon(Icons.refresh_rounded, size: 18, color: AppColors.primary[400])),
          ])),
        ),
        if (_expanded) ...widget.servers.map((s) => ServerTile(server: s, isSelected: s.name == widget.currentServer, onTap: () => widget.onServerSelected(s))),
      ]),
    );
  }
}

class OrphanServersTile extends StatefulWidget {
  final List<Server> servers;
  final String? currentServer;
  final Function(Server) onServerSelected;
  const OrphanServersTile({required this.servers, this.currentServer, required this.onServerSelected});
  @override
  State<OrphanServersTile> createState() => _OrphanServersTileState();
}

class _OrphanServersTileState extends State<OrphanServersTile> {
  bool _expanded = true;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: isDark ? AppColors.darkCard : AppColors.lightSurface),
      child: Column(children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
            Icon(_expanded ? Icons.keyboard_arrow_down_rounded : Icons.chevron_right_rounded, color: AppColors.warning),
            const SizedBox(width: 8),
            Expanded(child: Text('Manual', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
            Text('${widget.servers.length}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.warning)),
          ])),
        ),
        if (_expanded) ...widget.servers.map((s) => ServerTile(server: s, isSelected: s.name == widget.currentServer, onTap: () => widget.onServerSelected(s))),
      ]),
    );
  }
}

class ServerTile extends StatelessWidget {
  final Server server;
  final bool isSelected;
  final VoidCallback onTap;
  const ServerTile({required this.server, this.isSelected = false, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Container(width: 24, height: 24, decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: AppColors.getProtocolColor(server.protocol.name).withOpacity(0.2)), child: Center(child: Text(server.protocol.displayName[0], style: TextStyle(color: AppColors.getProtocolColor(server.protocol.name), fontSize: 10, fontWeight: FontWeight.w700)))),
          const SizedBox(width: 10),
          Expanded(child: Text(server.name, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
          Text(server.formattedPing, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          if (isSelected) ...[const SizedBox(width: 8), Icon(Icons.check_circle, size: 16, color: AppColors.primary[400])],
        ]),
      ),
    );
  }
}