/// API константы для Xray-core и внешних сервисов
class ApiConstants {
  ApiConstants._();

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Xray-core HTTP API эндпоинты
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const String xrayBaseUrl = 'http://127.0.0.1:10085';
  
  // Handlers API (добавление/удаление inbound/outbound)
  static const String xrayAddHandler = '/handler/add';
  static const String xrayRemoveHandler = '/handler/remove';
  
  // Stats API (статистика трафика)
  static const String xrayGetStats = '/stats/get';
  static const String xrayQueryStats = '/stats/query';
  
  // Routing API (управление маршрутизацией)
  static const String xrayAddRule = '/routing/add';
  static const String xrayRemoveRule = '/routing/remove';
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Внешние API для GeoIP/GeoSite
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const String geoipDownloadUrl = 
      'https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat';
  static const String geositeDownloadUrl = 
      'https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat';
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Проверка соединения
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const String connectivityCheckUrl = 'https://www.gstatic.com/generate_204';
  static const String ipCheckUrl = 'https://api.ipify.org?format=json';
  static const String ipCheckUrlBackup = 'https://httpbin.org/ip';
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // GitHub (обновления приложения)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const String githubApiReleases = 
      'https://api.github.com/repos/Eclipse-vpn/Eclipse-vpn/releases/latest';
  static const String githubDownloadBase = 
      'https://github.com/Eclipse-vpn/Eclipse-vpn/releases/download';
}