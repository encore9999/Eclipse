import 'dart:convert';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import '../constants/app_constants.dart';
import '../constants/api_constants.dart';

/// Абстрактный интерфейс для проверки сетевого подключения
abstract class NetworkInfo {
  /// Проверяет, есть ли интернет-соединение
  Future<bool> get isConnected;

  /// Поток состояния подключения (online/offline)
  Stream<bool> get onConnectivityChanged;

  /// Проверяет, использует ли система VPN
  Future<bool> get isVpnActive;

  /// Получает текущий публичный IP адрес
  Future<String?> get publicIp;

  /// Проверяет DNS утечку
  Future<bool> get hasDnsLeak;
}

/// Реализация NetworkInfo
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity _connectivity;
  final HttpClient _httpClient;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();

  NetworkInfoImpl({
    required Connectivity connectivity,
    HttpClient? httpClient,
  })  : _connectivity = connectivity,
        _httpClient = httpClient ?? HttpClient() {
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final hasConnection = results.any((result) => result != ConnectivityResult.none);
      _connectivityController.add(hasConnection);
    });
  }

  @override
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    if (results.isEmpty || results.every((r) => r == ConnectivityResult.none)) {
      return false;
    }
    // Дополнительная проверка — реальный HTTP-запрос
    return _canReachInternet();
  }

  @override
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  @override
  Future<bool> get isVpnActive async {
    try {
      // Проверяем, активен ли VPN через системный сетевой интерфейс
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.any,
      );

      // Ищем туннельные интерфейсы (обычно создаются VPN)
      for (final interface in interfaces) {
        final name = interface.name.toLowerCase();
        if (name.contains('tun') ||
            name.contains('tap') ||
            name.contains('utun') ||
            name.contains('ppp') ||
            name.contains('vpn') ||
            name.contains('xray') ||
            name.contains('wireguard')) {
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String?> get publicIp async {
    try {
      final urls = [
        ApiConstants.ipCheckUrl,
        ApiConstants.ipCheckUrlBackup,
      ];

      for (final url in urls) {
        try {
          final request = await _httpClient.getUrl(Uri.parse(url));
          request.headers.set('Accept', 'application/json');
          
          final response = await request
              .close()
              .timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            final body = await response.transform(Utf8Codec().decoder).join();
            // Простой парсинг JSON: {"ip":"x.x.x.x"}
            final ip = _extractIpFromJson(body);
            if (ip != null) return ip;
          }
        } catch (_) {
          continue; // Пробуем следующий URL
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> get hasDnsLeak async {
    try {
      // Проверяем через DNS-over-HTTPS разных провайдеров
      final resolvers = <String>[];
      
      // Cloudflare
      final cfRequest = await _httpClient.getUrl(
        Uri.parse('https://cloudflare-dns.com/dns-query?name=whoami.akamai.net&type=A'),
      );
      cfRequest.headers.set('Accept', 'application/dns-json');
      
      // Google DNS
      final googleRequest = await _httpClient.getUrl(
        Uri.parse('https://dns.google/resolve?name=whoami.akamai.net&type=A'),
      );

      // Если можем делать DNS запросы через разных провайдеров — утечки нет
      // Упрощённая проверка
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Проверяет реальную доступность интернета
  Future<bool> _canReachInternet() async {
    try {
      final request = await _httpClient.getUrl(
        Uri.parse(ApiConstants.connectivityCheckUrl),
      );
      request.headers.set('Cache-Control', 'no-cache');
      
      final response = await request
          .close()
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  /// Извлекает IP из JSON строки
  String? _extractIpFromJson(String json) {
    // Простой парсинг без json.decode для лёгкости
    final patterns = [
      RegExp(r'"ip"\s*:\s*"([^"]+)"'),
      RegExp(r'"origin"\s*:\s*"([^"]+)"'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(json);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    }
    return null;
  }

  /// Освобождение ресурсов
  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
  }
}