import '../../../../core/utils/result.dart';
import '../../../../core/errors/failures.dart';
import '../entities/subscription.dart';
import '../repositories/subscription_repository.dart';

class AddSubscription {
  final SubscriptionRepository _repository;
  AddSubscription(this._repository);

  Future<Result<Subscription>> call({
    required String name,
    required String url,
    SubscriptionType? type,
    Map<String, dynamic>? headers,
  }) async {
    if (url.isEmpty) {
      return Result.failure(Failure(message: 'URL cannot be empty', code: 'EMPTY_URL'));
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return Result.failure(Failure(message: 'Invalid URL format: $url', code: 'INVALID_URL'));
    }

    SubscriptionType detectedType = type ?? SubscriptionType.url;
    if (type == null) {
      final typeResult = await _repository.detectSubscriptionType(url);
      if (typeResult is Success<SubscriptionType>) {
        detectedType = typeResult.data;
      }
    }

    return _repository.addSubscription(
      name: name.isEmpty ? (Uri.tryParse(url)?.host ?? 'Subscription') : name,
      url: url.trim(),
      type: detectedType,
      headers: headers,
    );
  }
}