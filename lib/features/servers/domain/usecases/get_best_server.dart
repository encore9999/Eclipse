import '../../../../core/utils/result.dart';
import '../../../../core/errors/failures.dart';
import '../entities/server.dart';
import '../repositories/server_repository.dart';
import '../../../../core/utils/ping_utils.dart';

class GetBestServer {
  final ServerRepository _repository;

  GetBestServer(this._repository);

  Future<Result<Server>> call({
    String? preferredCountry,
    String? preferredProtocol,
    bool forceRefresh = false,
  }) async {
    final serversResult = await _repository.getServers();

    if (serversResult is FailureResult) {
      final f = serversResult as FailureResult;
      return Result.failure(f.failure);
    }

    final successResult = serversResult as Success<List<Server>>;
    var servers = successResult.data;

    if (servers.isEmpty) {
      return Result.failure(Failure(message: 'No servers available', code: 'NO_SERVERS'));
    }

    if (preferredProtocol != null) {
      servers = servers
          .where((s) => s.protocol.name == preferredProtocol.toLowerCase())
          .toList();
      if (servers.isEmpty) {
        return Result.failure(
          Failure(message: 'No servers with protocol: $preferredProtocol', code: 'NO_SERVERS_FOR_PROTOCOL'),
        );
      }
    }

    if (preferredCountry != null) {
      final filtered = servers
          .where((s) => s.countryCode?.toLowerCase() == preferredCountry.toLowerCase())
          .toList();
      if (filtered.isNotEmpty) servers = filtered;
    }

    servers.sort((a, b) {
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;
      final aPing = a.ping ?? 9999;
      final bPing = b.ping ?? 9999;
      if (aPing != bPing) return aPing.compareTo(bPing);
      return b.usageCount.compareTo(a.usageCount);
    });

    var bestServer = servers.first;

    if (forceRefresh || bestServer.ping == null) {
      final ping = await PingUtils.ping(bestServer.address);
      if (ping != null) {
        bestServer = bestServer.copyWith(ping: ping);
        await _repository.updatePing(bestServer.id, ping);
      }
    }

    return Result.success(bestServer);
  }
}