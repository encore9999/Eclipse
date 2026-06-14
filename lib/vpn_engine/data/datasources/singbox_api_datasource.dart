import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';

/// DataSource для Sing-Box Clash API
/// Sing-box поддерживает Clash API из коробки — это проще!
class SingBoxApiDataSource {
  final Dio _dio;
  String? _secret;

  SingBoxApiDataSource({required Dio dio, String? secret})
      : _dio = dio,
        _secret = secret {
    _dio.options.baseUrl = 'http://127.0.0.1:9090'; // Clash API порт
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      if (secret != null) 'Authorization': 'Bearer $secret',
    };
  }

  void setSecret(String secret) {
    _secret = secret;
    _dio.options.headers['Authorization'] = 'Bearer $secret';
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Clash API — Основные методы
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Проверить здоровье
  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('/');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Получить версию
  Future<String?> getVersion() async {
    try {
      final response = await _dio.get('/version');
      if (response.statusCode == 200) {
        return response.data['version'] as String? ?? 
               response.data['meta'] as String? ?? 
               'unknown';
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Прокси (Servers)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Получить все прокси
  Future<Map<String, dynamic>> getProxies() async {
    try {
      final response = await _dio.get('/proxies');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw SingBoxApiException(message: 'Failed to get proxies');
    } on DioException catch (e) {
      throw SingBoxApiException(
        message: 'API error: ${e.message}',
        originalError: e,
      );
    }
  }

  /// Получить информацию о конкретном прокси
  Future<Map<String, dynamic>> getProxy(String name) async {
    try {
      final response = await _dio.get('/proxies/$name');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw SingBoxApiException(message: 'Proxy not found: $name');
    } on DioException catch (e) {
      throw SingBoxApiException(message: 'API error: ${e.message}');
    }
  }

  /// Переключиться на прокси (глобально)
  Future<void> selectProxy(String groupName, String proxyName) async {
    try {
      await _dio.put('/proxies/$groupName', data: {
        'name': proxyName,
      });
    } on DioException catch (e) {
      throw SingBoxApiException(message: 'Failed to select proxy: ${e.message}');
    }
  }

  /// Проверить задержку прокси
  Future<int?> testProxyDelay(String proxyName, {String testUrl = 'https://www.gstatic.com/generate_204', int timeout = 5000}) async {
    try {
      final response = await _dio.get(
        '/proxies/$proxyName/delay',
        queryParameters: {
          'url': testUrl,
          'timeout': timeout,
        },
      );
      if (response.statusCode == 200 && response.data['delay'] != null) {
        return response.data['delay'] as int;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Правила (Rules)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Получить все правила
  Future<Map<String, dynamic>> getRules() async {
    try {
      final response = await _dio.get('/rules');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw SingBoxApiException(message: 'Failed to get rules');
    } catch (e) {
      throw SingBoxApiException(message: 'API error: $e');
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Подключения (Connections)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Получить активные подключения
  Future<Map<String, dynamic>> getConnections() async {
    try {
      final response = await _dio.get('/connections');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw SingBoxApiException(message: 'Failed to get connections');
    } catch (e) {
      throw SingBoxApiException(message: 'API error: $e');
    }
  }

  /// Закрыть все подключения
  Future<void> closeAllConnections() async {
    try {
      await _dio.delete('/connections');
    } catch (e) {
      throw SingBoxApiException(message: 'Failed to close connections: $e');
    }
  }

  /// Закрыть конкретное подключение
  Future<void> closeConnection(String id) async {
    try {
      await _dio.delete('/connections/$id');
    } catch (e) {
      throw SingBoxApiException(message: 'Failed to close connection: $e');
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Трафик (Traffic)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Получить статистику трафика
  Future<SingBoxTraffic> getTraffic() async {
    try {
      final response = await _dio.get('/traffic');
      if (response.statusCode == 200) {
        return SingBoxTraffic.fromJson(response.data);
      }
      return const SingBoxTraffic(upload: 0, download: 0);
    } catch (e) {
      return const SingBoxTraffic(upload: 0, download: 0);
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Конфигурация
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Получить текущий конфиг
  Future<Map<String, dynamic>> getConfig() async {
    try {
      final response = await _dio.get('/configs');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw SingBoxApiException(message: 'Failed to get config');
    } catch (e) {
      throw SingBoxApiException(message: 'API error: $e');
    }
  }

  /// Перезагрузить конфиг
  Future<void> reloadConfig({String? path}) async {
    try {
      await _dio.put('/configs', data: {
        if (path != null) 'path': path,
      });
    } catch (e) {
      throw SingBoxApiException(message: 'Failed to reload config: $e');
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // DNS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Очистить кэш DNS
  Future<void> flushDns() async {
    try {
      await _dio.post('/dns/flush');
    } catch (e) {
      throw SingBoxApiException(message: 'Failed to flush DNS: $e');
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Кэш (FakeIP)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Очистить кэш FakeIP
  Future<void> clearFakeIpCache() async {
    try {
      await _dio.post('/cache/fakeip/flush');
    } catch (e) {
      throw SingBoxApiException(message: 'Failed to clear FakeIP cache: $e');
    }
  }

  void dispose() {
    _dio.close();
  }
}

// ━━━━━━━ Модели ━━━━━━━

class SingBoxTraffic {
  final int upload;
  final int download;

  const SingBoxTraffic({required this.upload, required this.download});

  factory SingBoxTraffic.fromJson(Map<String, dynamic> json) {
    return SingBoxTraffic(
      upload: json['up'] as int? ?? 0,
      download: json['down'] as int? ?? 0,
    );
  }

  int get total => upload + download;
}

class SingBoxApiException extends AppException {
  const SingBoxApiException({
    required super.message,
    super.originalError,
    super.code = 'SINGBOX_API_ERROR',
  });
}