import '../entities/connection_status.dart';
import '../entities/traffic_stats.dart';
import '../../../../features/servers/domain/entities/server.dart';

/// Интерфейс репозитория VPN-движка
/// Определяет контракт для управления Xray-core
abstract class VpnEngineRepository {
  /// Подключиться к указанному серверу
  Future<void> connect(Server server);

  /// Отключиться от текущего сервера
  Future<void> disconnect();

  /// Переподключиться (при смене сервера или обрыве)
  Future<void> reconnect();

  /// Быстрое подключение к лучшему серверу
  Future<void> quickConnect();

  /// Получить текущий статус соединения
  Stream<ConnectionStatus> get connectionStatusStream;

  /// Получить текущий статус (разово)
  Future<ConnectionStatus> get currentStatus;

  /// Получить статистику трафика в реальном времени
  Stream<TrafficStats> get trafficStatsStream;

  /// Получить текущую статистику (разово)
  Future<TrafficStats> get currentTrafficStats;

  /// Проверить, запущен ли Xray-core процесс
  Future<bool> isXrayRunning();

  /// Проверить доступность сервера (пинг + TCP)
  Future<bool> testServer(Server server);

  /// Измерить пинг до сервера
  Future<int?> pingServer(String host);

  /// Включить/выключить Kill Switch
  Future<void> setKillSwitch(bool enabled);

  /// Включить/выключить защиту от DNS-утечек
  Future<void> setDnsLeakProtection(bool enabled);

  /// Включить/выключить защиту IPv6
  Future<void> setIpv6Protection(bool enabled);

  /// Настроить Split Tunneling (список приложений/доменов в обход VPN)
  Future<void> setSplitTunneling({List<String>? apps, List<String>? domains});

  /// Обновить конфигурацию Xray-core без перезапуска
  Future<void> updateConfig(Map<String, dynamic> configPatch);

  /// Получить путь к файлу конфигурации Xray
  Future<String> get configPath;

  /// Получить путь к бинарнику Xray
  Future<String> get binaryPath;

  /// Получить версию Xray-core
  Future<String> get xrayVersion;

  /// Очистить все логи и кэш
  Future<void> clearLogs();

  /// Освободить ресурсы
  void dispose();
}