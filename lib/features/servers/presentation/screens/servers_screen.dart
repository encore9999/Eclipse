import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/servers_provider.dart';
import '../widgets/server_card.dart';
import '../widgets/server_filter_bar.dart';
import '../widgets/server_sort_options.dart';
import '../widgets/server_group_header.dart';
import '../../domain/entities/server.dart';

class ServersScreen extends ConsumerStatefulWidget {
  const ServersScreen({super.key});

  @override
  ConsumerState<ServersScreen> createState() => _ServersScreenState();
}

class _ServersScreenState extends ConsumerState<ServersScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(serversProvider);
    final filteredServers = state.filteredServers;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: isDark ? AppColors.backgroundGradient : [const Color(0xFFF8F7FF), const Color(0xFFF0EEFF)])),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Row(children: [
                  Text('servers'.tr(), style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(icon: Icon(_showSearch ? Icons.close : Icons.search_rounded), onPressed: () {
                    setState(() { _showSearch = !_showSearch; if (!_showSearch) { _searchController.clear(); ref.read(serversProvider.notifier).setSearchQuery(''); } });
                  }),
                ]),
              ),
              const ServerFilterBar(),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  Text('servers_count'.tr(args: ['${filteredServers.length}']), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                  const Spacer(),
                  ServerSortOptions(currentSort: state.sortBy, currentOrder: state.sortOrder, onChanged: (s) => ref.read(serversProvider.notifier).setSortBy(s)),
                ]),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : filteredServers.isEmpty
                        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.dns_outlined, size: 64, color: AppColors.primary[300]),
                            const SizedBox(height: 16),
                            Text('no_servers'.tr(), style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 8),
                            Text('add_subscription'.tr(), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                          ]))
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            physics: const BouncingScrollPhysics(),
                            itemCount: filteredServers.length,
                            itemBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ServerCard(
                                server: filteredServers[index],
                                isTesting: state.testingServerId == filteredServers[index].id,
                                testResult: state.testResults[filteredServers[index].id],
                                onTap: () {},
                                onFavorite: () => ref.read(serversProvider.notifier).toggleFavorite(filteredServers[index].id),
                                onTest: () => ref.read(serversProvider.notifier).testSingleServer(filteredServers[index].id),
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ref.read(serversProvider.notifier).testAllServers(),
        backgroundColor: AppColors.primary[600],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.speed_rounded),
        label: Text('test_all'.tr()),
      ),
    );
  }
}