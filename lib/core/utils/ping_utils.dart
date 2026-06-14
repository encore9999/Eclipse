import 'dart:async';
import 'dart:io';
import '../constants/app_constants.dart';

/// Утилита для проверки доступности серверов (пинг)
class PingUtils {
  PingUtils._();

  /// Измеряет задержку до сервера в миллисекундах
  /// Возвращает null если сервер недоступен
  static Future<int?> ping(String host, {Duration timeout = AppConstants.pingTimeout}) async {
    try {
      final stopwatch = Stopwatch()..start();
      
      final result = await Process.run(
        Platform.isWindows ? 'ping' : 'ping',
        Platform.isWindows
            ? ['-n', '1', '-w', timeout.inMilliseconds.toString(), host]
            : ['-c', '1', '-W', timeout.inSeconds.toString(), host],
        runInShell: true,
      ).timeout(timeout + const Duration(seconds: 2));

      stopwatch.stop();

      if (result.exitCode == 0) {
        return stopwatch.elapsedMilliseconds;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Проверяет, доступен ли сервер по TCP (порт открыт)
  static Future<bool> isTcpReachable(String host, int port, {Duration timeout = AppConstants.pingTimeout}) async {
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: timeout,
      );
      socket.destroy();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Проверяет общую доступность интернета через HTTP
  static Future<bool> isInternetAvailable() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      
      final request = await client.getUrl(
        Uri.parse('https://www.gstatic.com/generate_204'),
      );
      final response = await request.close().timeout(const Duration(seconds: 5));
      
      return response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  /// Пингует несколько серверов параллельно и возвращает отсортированный список
  static Future<List<ServerPingResult>> pingMultiple(
    List<ServerPingTarget> targets, {
    int concurrency = 10,
  }) async {
    final results = <ServerPingResult>[];
    
    // Разбиваем на чанки для ограничения конкуренции
    for (var i = 0; i < targets.length; i += concurrency) {
      final chunk = targets.skip(i).take(concurrency).toList();
      final chunkResults = await Future.wait(
        chunk.map((target) async {
          final ping = await PingUtils.ping(target.host);
          return ServerPingResult(
            id: target.id,
            host: target.host,
            ping: ping,
          );
        }),
      );
      results.addAll(chunkResults);
    }

    // Сортируем: сначала доступные по пингу, потом недоступные
    results.sort((a, b) {
      if (a.ping == null && b.ping == null) return 0;
      if (a.ping == null) return 1;
      if (b.ping == null) return -1;
      return a.ping!.compareTo(b.ping!);
    });

    return results;
  }

  /// Проверяет, жив ли процесс по PID
  static bool isProcessAlive(int pid) {
    try {
      final process = Process.runSync(
        Platform.isWindows ? 'tasklist' : 'ps',
        Platform.isWindows ? ['/FI', 'PID eq $pid'] : ['-p', pid.toString()],
      );
      return process.exitCode == 0 && process.stdout.toString().contains(pid.toString());
    } catch (e) {
      return false;
    }
  }
}

/// Модель для передачи цели пингования
class ServerPingTarget {
  final String id;
  final String host;

  const ServerPingTarget({
    required this.id,
    required this.host,
  });
}

/// Результат пингования
class ServerPingResult {
  final String id;
  final String host;
  final int? ping; // в миллисекундах, null если недоступен

  const ServerPingResult({
    required this.id,
    required this.host,
    required this.ping,
  });

  bool get isReachable => ping != null;
}