/// Базовый класс для всех исключений приложения
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException: $message (code: $code)';
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Сетевые исключения
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

class ServerUnreachableException extends NetworkException {
  const ServerUnreachableException({
    required String serverAddress,
    super.code = 'SERVER_UNREACHABLE',
  }) : super(message: 'Server unreachable: $serverAddress');
}

class ConnectionTimeoutException extends NetworkException {
  const ConnectionTimeoutException({
    super.message = 'Connection timed out',
    super.code = 'CONNECTION_TIMEOUT',
  });
}

class DnsResolutionException extends NetworkException {
  const DnsResolutionException({
    required String hostname,
    super.code = 'DNS_RESOLUTION_FAILED',
  }) : super(message: 'Failed to resolve hostname: $hostname');
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Исключения Xray-core
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class XrayCoreException extends AppException {
  const XrayCoreException({
    required super.message,
    super.code = 'XRAY_CORE_ERROR',
    super.originalError,
  });
}

class XrayProcessException extends XrayCoreException {
  const XrayProcessException({
    required super.message,
    super.code = 'XRAY_PROCESS_ERROR',
  });
}

class XrayConfigException extends XrayCoreException {
  const XrayConfigException({
    required super.message,
    super.code = 'XRAY_CONFIG_ERROR',
  });
}

class XrayApiException extends XrayCoreException {
  const XrayApiException({
    required super.message,
    super.code = 'XRAY_API_ERROR',
  });
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Исключения подписок
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class SubscriptionException extends AppException {
  const SubscriptionException({
    required super.message,
    super.code = 'SUBSCRIPTION_ERROR',
  });
}

class SubscriptionFetchException extends SubscriptionException {
  const SubscriptionFetchException({
    required super.message,
    super.code = 'SUBSCRIPTION_FETCH_ERROR',
  });
}

class SubscriptionParseException extends SubscriptionException {
  const SubscriptionParseException({
    required super.message,
    super.code = 'SUBSCRIPTION_PARSE_ERROR',
  });
}

class InvalidSubscriptionUrlException extends SubscriptionException {
  const InvalidSubscriptionUrlException({
    required String url,
    super.code = 'INVALID_SUBSCRIPTION_URL',
  }) : super(message: 'Invalid subscription URL: $url');
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Исключения безопасности
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class SecurityException extends AppException {
  const SecurityException({
    required super.message,
    super.code = 'SECURITY_ERROR',
  });
}

class EncryptionException extends SecurityException {
  const EncryptionException({
    required super.message,
    super.code = 'ENCRYPTION_ERROR',
  });
}

class SecureStorageException extends SecurityException {
  const SecureStorageException({
    required super.message,
    super.code = 'SECURE_STORAGE_ERROR',
  });
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Исключения конфигурации сервера
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class ServerConfigException extends AppException {
  const ServerConfigException({
    required super.message,
    super.code = 'SERVER_CONFIG_ERROR',
  });
}

class InvalidProtocolException extends ServerConfigException {
  const InvalidProtocolException({
    required String protocol,
    super.code = 'INVALID_PROTOCOL',
  }) : super(message: 'Unsupported protocol: $protocol');
}

class InvalidPortException extends ServerConfigException {
  const InvalidPortException({
    required int port,
    super.code = 'INVALID_PORT',
  }) : super(message: 'Invalid port number: $port');
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Исключения файловой системы
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class FileSystemException extends AppException {
  const FileSystemException({
    required super.message,
    super.code = 'FILE_SYSTEM_ERROR',
  });
}

class ConfigFileNotFoundException extends FileSystemException {
  const ConfigFileNotFoundException({
    required String path,
    super.code = 'CONFIG_FILE_NOT_FOUND',
  }) : super(message: 'Configuration file not found: $path');
}