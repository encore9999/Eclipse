import '../../../../core/utils/result.dart';
import '../../../../core/errors/failures.dart';
import '../entities/server.dart';
import '../repositories/server_repository.dart';
import '../../../../core/utils/ping_utils.dart';

/// Use Case: Тестирование доступности сервера
class TestServer {
  final ServerRepository _repository;

  TestServer(this._repository);

  /// Проверяет доступность сервера:
  /// - ICMP пинг
  /// - TCP подключение к порту
  /// - Обновляет пинг в репозитории
  Future<Result<ServerTestResult>> call(Server server) async {
    if (server.address.isEmpty) {
      return Result.failure(
        const Failure(message: 'Server address is empty', code: 'EMPTY_ADDRESS'),
      );
    }

    if (server.port <= 0 || server.port > 65535) {
      return Result.failure(
        Failure(message: 'Invalid port: ${server.port}', code: 'INVALID_PORT'),
      );
    }

    // Измеряем ICMP пинг
    final ping = await PingUtils.ping(server.address);

    // Проверяем TCP доступность
    final isTcpReachable = await PingUtils.isTcpReachable(
      server.address,
      server.port,
    );

    // Обновляем пинг в репозитории
    if (ping != null) {
      await _repository.updatePing(server.id, ping);
    }

    final result = ServerTestResult(
      serverId: server.id,
      isReachable: isTcpReachable && ping != null,
      ping: ping,
      tcpReachable: isTcpReachable,
      testedAt: DateTime.now(),
    );

    return Result.success(result);
  }

  /// Массовое тестирование списка серверов
  Future<Result<List<ServerTestResult>>> testMultiple(
    List<Server> servers, {
    int concurrency = 10,
  }) async {
    final pingTargets = servers.map((s) => ServerPingTarget(
      id: s.id,
      host: s.address,
    )).toList();

    final pingResults = await PingUtils.pingMultiple(pingTargets);

    final results = <ServerTestResult>[];
    for (final pingResult in pingResults) {
      final server = servers.firstWhere((s) => s.id == pingResult.id);
      
      // Проверяем TCP только если пинг прошёл
      bool tcpReachable = false;
      if (pingResult.isReachable) {
        tcpReachable = await PingUtils.isTcpReachable(
          server.address,
          server.port,
        );
      }

      // Обновляем пинг
      await _repository.updatePing(server.id, pingResult.ping);

      results.add(ServerTestResult(
        serverId: server.id,
        isReachable: pingResult.isReachable && tcpReachable,
        ping: pingResult.ping,
        tcpReachable: tcpReachable,
        testedAt: DateTime.now(),
      ));
    }

    return Result.success(results);
  }
}

/// Результат тестирования сервера
class ServerTestResult {
  final String serverId;
  final bool isReachable;
  final int? ping;
  final bool tcpReachable;
  final DateTime testedAt;

  const ServerTestResult({
    required this.serverId,
    required this.isReachable,
    this.ping,
    required this.tcpReachable,
    required this.testedAt,
  });

  String get statusText {
    if (!isReachable) return 'Unreachable';
    if (ping != null && ping! < 100) return 'Excellent';
    if (ping != null && ping! < 200) return 'Good';
    if (ping != null && ping! < 300) return 'Fair';
    return 'Slow';
  }
}