/// Конфигурационные константы всего приложения
class AppConstants {
  AppConstants._();

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Приложение
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const String appName = 'encoreVPN';
  static const String appVersion = '1.0.0';
  static const String appPackageName = 'com.Eclipse.vpn';
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Xray-core
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const String xrayBinaryName = 'xray';
  static const String xrayConfigFileName = 'config.json';
  static const String xrayLogFileName = 'xray.log';
  
  // Xray API порты
  static const int xrayApiPort = 10085;
  static const int xraySocksPort = 2080;
  static const int xrayHttpPort = 2081;
  static const int xrayDnsPort = 5353;
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Сеть
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration pingTimeout = Duration(seconds: 5);
  static const Duration connectionCheckInterval = Duration(seconds: 2);
  
  // DNS серверы по умолчанию
  static const List<String> defaultDnsServers = [
    '1.1.1.1',
    '8.8.8.8',
    '9.9.9.9',
  ];
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Подписки
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const Duration defaultAutoUpdateInterval = Duration(hours: 6);
  static const int maxSubscriptionRetries = 3;
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Безопасность
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const String secureStorageKey = 'Eclipse_secure_storage';
  static const String encryptionKeyAlias = 'Eclipse_master_key';
  static const int aesKeySize = 256;
  static const int chachaNonceSize = 12;
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // UI
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const double sidebarWidth = 280.0;
  static const double connectionButtonSize = 200.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration pageTransitionDuration = Duration(milliseconds: 250);
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Локализация
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const List<String> supportedLocales = ['en', 'ru', 'zh', 'fa'];
  static const String defaultLocale = 'en';
  static const String translationsPath = 'assets/translations';
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Системный трей
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const String trayIconConnected = 'assets/icons/tray_connected.ico';
  static const String trayIconDisconnected = 'assets/icons/tray_disconnected.ico';
  static const String trayTooltip = 'Eclipse';
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Ограничения
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const int maxSavedServers = 100;
  static const int maxSubscriptions = 20;
  static const int maxLogLines = 5000;
}