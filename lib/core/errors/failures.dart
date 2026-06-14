import 'package:equatable/equatable.dart';

/// Базовый Failure (НЕ абстрактный)
class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

// Сетевые
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'Network error', super.code = 'NETWORK_FAILURE'});
}

class ServerUnreachableFailure extends NetworkFailure {
  const ServerUnreachableFailure({required String server, super.code = 'SERVER_UNREACHABLE'})
      : super(message: 'Server unreachable: $server');
}

class ConnectionTimeoutFailure extends NetworkFailure {
  const ConnectionTimeoutFailure({super.message = 'Connection timed out', super.code = 'CONNECTION_TIMEOUT'});
}

class NoInternetFailure extends NetworkFailure {
  const NoInternetFailure({super.message = 'No internet connection', super.code = 'NO_INTERNET'});
}

// VPN
class VpnFailure extends Failure {
  const VpnFailure({required super.message, super.code = 'VPN_FAILURE'});
}

class VpnConnectionFailure extends VpnFailure {
  const VpnConnectionFailure({required super.message, super.code = 'VPN_CONNECTION_FAILURE'});
}

// Подписки
class SubscriptionFailure extends Failure {
  const SubscriptionFailure({required super.message, super.code = 'SUBSCRIPTION_FAILURE'});
}

class SubscriptionFetchFailure extends SubscriptionFailure {
  const SubscriptionFetchFailure({required super.message, super.code = 'SUBSCRIPTION_FETCH_FAILURE'});
}

class SubscriptionParseFailure extends SubscriptionFailure {
  const SubscriptionParseFailure({required super.message, super.code = 'SUBSCRIPTION_PARSE_FAILURE'});
}

// Кэш
class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Cache error', super.code = 'CACHE_FAILURE'});
}

class SecureStorageFailure extends Failure {
  const SecureStorageFailure({super.message = 'Secure storage error', super.code = 'SECURE_STORAGE_FAILURE'});
}

// Сервер
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code = 'SERVER_FAILURE'});
}

// Маппер
class FailureMapper {
  static Failure mapExceptionToFailure(Exception exception) {
    return Failure(message: exception.toString(), code: 'UNKNOWN_ERROR');
  }
}