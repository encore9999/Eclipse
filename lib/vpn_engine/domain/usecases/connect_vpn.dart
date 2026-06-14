import '../../../../core/utils/result.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/vpn_engine_repository.dart';
import '../../../../features/servers/domain/entities/server.dart';
import '../entities/vpn_protocol.dart';

class ConnectVpn {
  final VpnEngineRepository _engineRepository;
  ConnectVpn(this._engineRepository);

  Future<Result<void>> call(Server server) async {
    final currentStatus = await _engineRepository.currentStatus;
    if (currentStatus.isConnected) {
      await _engineRepository.disconnect();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (server.address.isEmpty) {
      return Result.failure(Failure(message: 'Server address is empty', code: 'INVALID_SERVER'));
    }

    if (server.port <= 0 || server.port > 65535) {
      return Result.failure(Failure(message: 'Invalid port: ${server.port}', code: 'INVALID_PORT'));
    }

    final validationResult = _validateProtocolSettings(server);
    if (validationResult != null) {
      return Result.failure(validationResult);
    }

    try {
      await _engineRepository.connect(server);
      await Future.delayed(const Duration(seconds: 1));

      final newStatus = await _engineRepository.currentStatus;
      if (newStatus.isConnected) {
        return Result.success(null);
      }

      if (newStatus.isError) {
        return Result.failure(VpnConnectionFailure(message: newStatus.errorMessage ?? 'Connection failed'));
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(VpnConnectionFailure(message: 'Connection error: $e'));
    }
  }

  Failure? _validateProtocolSettings(Server server) {
    switch (server.protocol) {
      case VpnProtocol.vless:
      case VpnProtocol.vmess:
      case VpnProtocol.trojan:
        final uuid = server.protocolSettings['uuid'] as String?;
        if (uuid == null || uuid.isEmpty) {
          return Failure(message: 'UUID is required for this protocol', code: 'MISSING_UUID');
        }
        break;

      case VpnProtocol.shadowsocks:
        final password = server.protocolSettings['password'] as String?;
        final method = server.protocolSettings['method'] as String?;
        if (password == null || password.isEmpty) {
          return Failure(message: 'Password is required for Shadowsocks', code: 'MISSING_PASSWORD');
        }
        if (method == null || method.isEmpty) {
          return Failure(message: 'Encryption method is required for Shadowsocks', code: 'MISSING_METHOD');
        }
        break;

      case VpnProtocol.wireguard:
        final privateKey = server.protocolSettings['privateKey'] as String?;
        if (privateKey == null || privateKey.isEmpty) {
          return Failure(message: 'Private key is required for WireGuard', code: 'MISSING_PRIVATE_KEY');
        }
        break;

      case VpnProtocol.hysteria2:
      case VpnProtocol.tuic:
        final password = server.protocolSettings['password'] as String?;
        if (password == null || password.isEmpty) {
          return Failure(message: 'Password is required for this protocol', code: 'MISSING_PASSWORD');
        }
        break;
    }

    return null;
  }
}