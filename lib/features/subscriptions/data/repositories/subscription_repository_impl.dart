import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/base64_utils.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../../servers/domain/entities/server.dart';
import '../../../servers/domain/repositories/server_repository.dart';
import '../../../servers/data/models/server_model.dart';
import '../datasources/subscription_local_datasource.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionLocalDataSource _localDataSource;
  final ServerRepository _serverRepository;
  final Dio _dio;
  final Uuid _uuid;

  SubscriptionRepositoryImpl({
    required SubscriptionLocalDataSource localDataSource,
    required ServerRepository serverRepository,
    required Dio dio,
    Uuid? uuid,
  })  : _localDataSource = localDataSource,
        _serverRepository = serverRepository,
        _dio = dio,
        _uuid = uuid ?? const Uuid();

  @override
  Future<Result<List<Subscription>>> getSubscriptions() async {
    try { return Result.success(_localDataSource.getSubscriptions()); } catch (e) { return Result.failure(CacheFailure(message: '$e')); }
  }

  @override
  Future<Result<Subscription>> getSubscriptionById(String id) async {
    final s = _localDataSource.getSubscriptionById(id);
    if (s == null) return Result.failure(Failure(message: 'Not found'));
    return Result.success(s);
  }

  @override
  Future<Result<Subscription>> addSubscription({required String name, required String url, SubscriptionType? type, Map<String, dynamic>? headers}) async {
    try {
      SubscriptionType dt = type ?? SubscriptionType.url;
      if (type == null) { final tr = await detectSubscriptionType(url); if (tr is Success<SubscriptionType>) dt = tr.data; }
      final sub = Subscription(id: _uuid.v4(), name: name.isEmpty ? (Uri.tryParse(url)?.host ?? 'Subscription') : name, url: url, type: dt, createdAt: DateTime.now(), headers: headers);
      await _localDataSource.saveSubscription(sub);
      await updateSubscription(sub.id);
      return Result.success(sub);
    } catch (e) { return Result.failure(Failure(message: '$e')); }
  }

  @override
  Future<Result<Subscription>> updateSubscription(String id) async {
    final existing = _localDataSource.getSubscriptionById(id);
    if (existing == null) return Result.failure(Failure(message: 'Not found'));
    try {
      final updating = existing.copyWith(status: SubscriptionStatus.updating);
      await _localDataSource.saveSubscription(updating);
      final response = await _dio.get(existing.url, options: Options(responseType: ResponseType.plain));
      final servers = await _parseSubscriptionContent(response.data.toString(), existing.type, existing.id);

      final old = await _serverRepository.getServersBySubscription(existing.id);
      if (old is Success<List<Server>>) { for (final s in old.data) { await _serverRepository.deleteServer(s.id); } }
      if (servers.isNotEmpty) await _serverRepository.importServers(servers);

      final now = DateTime.now();
      final updated = existing.copyWith(name: (Uri.tryParse(existing.url)?.host ?? existing.name), status: SubscriptionStatus.active, lastUpdate: now, nextUpdate: now.add(existing.autoUpdateInterval), serverCount: servers.length, errorMessage: null, updateRetryCount: 0);
      await _localDataSource.saveSubscription(updated);
      return Result.success(updated);
    } on DioException catch (e) {
      final err = existing.copyWith(status: SubscriptionStatus.error, errorMessage: '${e.message}', updateRetryCount: existing.updateRetryCount + 1);
      await _localDataSource.saveSubscription(err);
      return Result.failure(SubscriptionFetchFailure(message: '${e.message}'));
    } catch (e) {
      final err = existing.copyWith(status: SubscriptionStatus.error, errorMessage: '$e', updateRetryCount: existing.updateRetryCount + 1);
      await _localDataSource.saveSubscription(err);
      return Result.failure(SubscriptionParseFailure(message: '$e'));
    }
  }

  @override Future<Result<List<Subscription>>> updateAllSubscriptions() async { final all = _localDataSource.getSubscriptions(); for (final s in all) await updateSubscription(s.id); return Result.success(_localDataSource.getSubscriptions()); }
  @override Future<Result<void>> deleteSubscription(String id) async { final sr = await _serverRepository.getServersBySubscription(id); if (sr is Success<List<Server>>) { for (final s in sr.data) await _serverRepository.deleteServer(s.id); } await _localDataSource.deleteSubscription(id); return Result.success(null); }
  @override Future<Result<Subscription>> toggleAutoUpdate(String id) async { final s = _localDataSource.getSubscriptionById(id); if (s == null) return Result.failure(Failure(message: 'Not found')); final u = s.copyWith(isAutoUpdate: !s.isAutoUpdate); await _localDataSource.saveSubscription(u); return Result.success(u); }
  @override Future<Result<Subscription>> setUpdateInterval(String id, Duration d) async { final s = _localDataSource.getSubscriptionById(id); if (s == null) return Result.failure(Failure(message: 'Not found')); final u = s.copyWith(autoUpdateInterval: d); await _localDataSource.saveSubscription(u); return Result.success(u); }
  @override Future<Result<Subscription>> pauseSubscription(String id) async { final s = _localDataSource.getSubscriptionById(id); if (s == null) return Result.failure(Failure(message: 'Not found')); final u = s.copyWith(status: SubscriptionStatus.paused); await _localDataSource.saveSubscription(u); return Result.success(u); }
  @override Future<Result<Subscription>> resumeSubscription(String id) async { final s = _localDataSource.getSubscriptionById(id); if (s == null) return Result.failure(Failure(message: 'Not found')); final u = s.copyWith(status: SubscriptionStatus.active); await _localDataSource.saveSubscription(u); return Result.success(u); }
  @override Future<Result<Subscription>> renameSubscription(String id, String name) async { final s = _localDataSource.getSubscriptionById(id); if (s == null) return Result.failure(Failure(message: 'Not found')); final u = s.copyWith(name: name); await _localDataSource.saveSubscription(u); return Result.success(u); }
  @override Future<Result<List<Server>>> getSubscriptionServers(String id) async => _serverRepository.getServersBySubscription(id);
  @override Future<Result<bool>> validateSubscriptionUrl(String url) async { try { final r = await _dio.head(url); return Result.success(r.statusCode == 200); } catch (_) { return Result.success(false); } }
  @override Future<Result<SubscriptionType>> detectSubscriptionType(String url) async { try { final r = await _dio.get(url, options: Options(responseType: ResponseType.plain)); final c = r.data.toString(); if (_looksLikeJson(c)) return Result.success(SubscriptionType.json); if (Base64Utils.isValidBase64(c)) { final d = Base64Utils.tryDecode(c); if (d != null && _containsVpnLinks(d)) return Result.success(SubscriptionType.base64); } if (_containsVpnLinks(c)) return Result.success(SubscriptionType.url); return Result.success(SubscriptionType.url); } catch (_) { return Result.success(SubscriptionType.url); } }
  @override Future<Result<SubscriptionStats>> getSubscriptionStats(String id) async { final s = _localDataSource.getSubscriptionById(id); if (s == null) return Result.failure(Failure(message: 'Not found')); return Result.success(SubscriptionStats(totalServers: s.serverCount, onlineServers: 0, offlineServers: 0, averagePing: 0, totalTraffic: 0)); }
  @override Future<Result<String>> exportSubscription(String id) async { final s = _localDataSource.getSubscriptionById(id); if (s == null) return Result.failure(Failure(message: 'Not found')); return Result.success(s.url); }

  Future<List<Server>> _parseSubscriptionContent(String c, SubscriptionType t, String sid) async {
    List<String> links = [];
    switch (t) {
      case SubscriptionType.base64: final d = Base64Utils.tryDecode(c); if (d != null) links = d.split('\n').where((l) => l.trim().isNotEmpty).toList(); break;
      case SubscriptionType.json: try { final j = jsonDecode(c); if (j is Map && j['proxies'] is List) links = (j['proxies'] as List).map((p) => _clashProxyToLink(p)).whereType<String>().toList(); } catch (_) {} break;
      case SubscriptionType.url: links = c.split('\n').where((l) => l.trim().isNotEmpty).toList(); break;
    }
    final servers = <Server>[];
    for (final l in links) { try { servers.add(ServerModel.fromShareLink(l.trim()).toEntity().copyWith(subscriptionId: sid)); } catch (_) {} }
    return servers;
  }

  String? _clashProxyToLink(Map<String, dynamic> p) {
    final t = p['type'] ?? ''; final s = p['server'] ?? ''; final port = p['port'] ?? 0; final n = p['name'] ?? '';
    return switch (t.toString().toLowerCase()) { 'vless' => 'vless://${p['uuid']}@$s:$port#$n', 'vmess' => 'vmess://${p['uuid']}@$s:$port#$n', 'trojan' => 'trojan://${p['password']}@$s:$port#$n', 'ss' => 'ss://${p['cipher']}:${p['password']}@$s:$port#$n', _ => null };
  }

  bool _looksLikeJson(String c) { final t = c.trim(); return (t.startsWith('{') && t.endsWith('}')) || (t.startsWith('[') && t.endsWith(']')); }
  bool _containsVpnLinks(String c) => c.contains('vless://') || c.contains('vmess://') || c.contains('trojan://') || c.contains('ss://');
}