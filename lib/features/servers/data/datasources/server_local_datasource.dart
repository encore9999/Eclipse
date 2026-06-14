import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/server_model.dart';
import '../../domain/entities/server_group.dart';

class ServerLocalDataSource {
  static const String _serversBoxName = 'servers';
  static const String _groupsBoxName = 'server_groups';

  late Box<String> _serversBox;
  late Box<String> _groupsBox;

  Future<void> init() async {
    _serversBox = await Hive.openBox<String>(_serversBoxName);
    _groupsBox = await Hive.openBox<String>(_groupsBoxName);
    print('[Hive] Boxes opened. Total entries: ${_serversBox.length}');
  }

  List<ServerModel> getServers() {
    final servers = <ServerModel>[];
    for (final key in _serversBox.keys) {
      if (key == 'favorites' || key == 'recent_servers') continue;
      
      final json = _serversBox.get(key);
      if (json != null) {
        try {
          final map = jsonDecode(json) as Map<String, dynamic>;
          if (map.containsKey('address') && map.containsKey('protocol')) {
            servers.add(ServerModel.fromJson(map));
          }
        } catch (e) {
          // Пропускаем невалидные записи
        }
      }
    }
    print('[Hive] getServers: ${servers.length} servers (box has ${_serversBox.length} total)');
    return servers;
  }

  ServerModel? getServerById(String id) {
    final json = _serversBox.get(id);
    if (json == null) return null;
    try {
      return ServerModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveServer(ServerModel server) async {
    final json = jsonEncode(server.toJson());
    await _serversBox.put(server.id, json);
  }

  Future<void> saveServers(List<ServerModel> servers) async {
    print('[Hive] Saving ${servers.length} servers...');
    for (final server in servers) {
      final json = jsonEncode(server.toJson());
      await _serversBox.put(server.id, json);
    }
    print('[Hive] Done! Box has ${_serversBox.length} entries');
  }

  Future<void> deleteServer(String id) async {
    await _serversBox.delete(id);
  }

  Future<void> clearAll() async {
    await _serversBox.clear();
    await _groupsBox.clear();
  }

  List<String> getFavoriteIds() => [];
  Future<void> addToFavorites(String serverId) async {}
  bool isFavorite(String serverId) => false;
  List<String> getRecentServerIds() => [];
  Future<void> addToRecent(String serverId) async {}

  List<ServerGroup> getGroups() => [];
  Future<void> saveGroup(ServerGroup group) async {}
  Future<void> deleteGroup(String id) async {}

  int getServerCount() {
    return getServers().length;
  }

  List<ServerModel> getServersBySubscription(String subscriptionId) {
    return getServers().where((s) => s.subscriptionId == subscriptionId).toList();
  }

  Future<void> close() async {
    await _serversBox.close();
    await _groupsBox.close();
  }
}