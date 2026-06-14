import '../errors/failures.dart';

/// Типобезопасный Result тип для всех операций в приложении.
/// Аналог Either из функционального программирования.
/// 
/// Использование:
/// ```dart
/// Result<String> result = await someOperation();
/// result.when(
///   success: (data) => print('Успех: $data'),
///   failure: (failure) => print('Ошибка: ${failure.message}'),
/// );
/// ```
sealed class Result<T> {
  const Result();

  /// Создать успешный результат
  factory Result.success(T data) = Success<T>;

  /// Создать ошибочный результат
  factory Result.failure(Failure failure) = FailureResult<T>;

  /// Проверяет, успешный ли результат
  bool get isSuccess => this is Success<T>;

  /// Проверяет, ошибочный ли результат
  bool get isFailure => this is FailureResult<T>;

  /// Получить данные, если успех (иначе null)
  T? get dataOrNull => this is Success<T> ? (this as Success<T>).data : null;

  /// Получить ошибку, если failure (иначе null)
  Failure? get failureOrNull => this is FailureResult<T> ? (this as FailureResult<T>).failure : null;

  /// Получить данные или бросить исключение
  T getOrThrow() {
    if (this is Success<T>) return (this as Success<T>).data;
    throw (this as FailureResult<T>).failure;
  }

  /// Получить данные или значение по умолчанию
  T getOrElse(T defaultValue) {
    return isSuccess ? (this as Success<T>).data : defaultValue;
  }

  /// Получить данные или вычислить значение
  T getOrElseCompute(T Function(Failure failure) computation) {
    if (isSuccess) return (this as Success<T>).data;
    return computation((this as FailureResult<T>).failure);
  }

  /// Трансформировать данные в другой тип
  Result<R> map<R>(R Function(T data) transform) {
    if (this is Success<T>) {
      try {
        return Result.success(transform((this as Success<T>).data));
      } catch (e) {
        return Result.failure(
          Failure(message: 'Transform error: $e', code: 'TRANSFORM_ERROR'),
        );
      }
    }
    return Result.failure((this as FailureResult<T>).failure);
  }

  /// Асинхронная трансформация
  Future<Result<R>> asyncMap<R>(Future<R> Function(T data) transform) async {
    if (this is Success<T>) {
      try {
        final result = await transform((this as Success<T>).data);
        return Result.success(result);
      } catch (e) {
        return Result.failure(
          Failure(message: 'Async transform error: $e', code: 'ASYNC_TRANSFORM_ERROR'),
        );
      }
    }
    return Result.failure((this as FailureResult<T>).failure);
  }

  /// Выполнить действие в зависимости от результата
  void when({
    required void Function(T data) success,
    required void Function(Failure failure) failure,
  }) {
    if (this is Success<T>) {
      success((this as Success<T>).data);
    } else {
      failure((this as FailureResult<T>).failure);
    }
  }

  /// Функциональный подход: вернуть значение из when
  R whenValue<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) {
    if (this is Success<T>) {
      return success((this as Success<T>).data);
    }
    return failure((this as FailureResult<T>).failure);
  }

  /// Выполнить действие только при успехе
  Result<T> onSuccess(void Function(T data) action) {
    if (this is Success<T>) {
      action((this as Success<T>).data);
    }
    return this;
  }

  /// Выполнить действие только при ошибке
  Result<T> onFailure(void Function(Failure failure) action) {
    if (this is FailureResult<T>) {
      action((this as FailureResult<T>).failure);
    }
    return this;
  }

  /// Преобразовать в nullable значение
  T? toNullable() => isSuccess ? (this as Success<T>).data : null;

  @override
  String toString() {
    return whenValue(
      success: (data) => 'Success($data)',
      failure: (failure) => 'Failure(${failure.message})',
    );
  }
}

/// Успешный результат
class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Success<T> && other.data == data;
  }

  @override
  int get hashCode => data.hashCode;
}

/// Ошибочный результат
class FailureResult<T> extends Result<T> {
  final Failure failure;

  const FailureResult(this.failure);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FailureResult<T> && other.failure == failure;
  }

  @override
  int get hashCode => failure.hashCode;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Расширения для удобной работы с Future
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension FutureResultExt<T> on Future<Result<T>> {
  /// Обработать результат асинхронно
  Future<void> when({
    required Future<void> Function(T data) success,
    required Future<void> Function(Failure failure) failure,
  }) async {
    final result = await this;
    if (result is Success<T>) {
      await success(result.data);
    } else if (result is FailureResult<T>) {
      await failure(result.failure);
    }
  }

  /// Получить данные или бросить исключение
  Future<T> getOrThrow() async {
    final result = await this;
    return result.getOrThrow();
  }

  /// Трансформировать данные
  Future<Result<R>> map<R>(R Function(T data) transform) async {
    final result = await this;
    return result.map(transform);
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Утилиты для создания Result
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Обёртка для try-catch, возвращающая Result
Future<Result<T>> runCatching<T>(Future<T> Function() operation) async {
  try {
    final data = await operation();
    return Result.success(data);
  } on Exception catch (e) {
    final failure = FailureMapper.mapExceptionToFailure(e);
    return Result.failure(failure);
  } catch (e) {
    return Result.failure(
      Failure(message: e.toString(), code: 'UNKNOWN_ERROR'),
    );
  }
}

/// Синхронная версия
Result<T> runCatchingSync<T>(T Function() operation) {
  try {
    final data = operation();
    return Result.success(data);
  } on Exception catch (e) {
    final failure = FailureMapper.mapExceptionToFailure(e);
    return Result.failure(failure);
  } catch (e) {
    return Result.failure(
      Failure(message: e.toString(), code: 'UNKNOWN_ERROR'),
    );
  }
}