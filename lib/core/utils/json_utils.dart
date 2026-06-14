import 'dart:convert';

/// Утилиты для безопасной работы с JSON
class JsonUtils {
  JsonUtils._();

  /// Безопасное декодирование JSON строки
  static Map<String, dynamic>? tryDecode(String jsonString) {
    try {
      final decoded = json.decode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Безопасное получение строки из JSON
  static String? getString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) return value;
    if (value != null) return value.toString();
    return null;
  }

  /// Безопасное получение целого числа из JSON
  static int? getInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Безопасное получение числа с плавающей точкой из JSON
  static double? getDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Безопасное получение bool из JSON
  static bool? getBool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return null;
  }

  /// Безопасное получение списка из JSON
  static List<T>? getList<T>(Map<String, dynamic> json, String key, T Function(dynamic) converter) {
    try {
      final value = json[key];
      if (value is List) {
        return value.map((e) => converter(e)).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Безопасное получение вложенного JSON объекта
  static Map<String, dynamic>? getMap(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is Map<String, dynamic>) return value;
    return null;
  }

  /// Красивое форматирование JSON для логов
  static String prettyPrint(dynamic json) {
    if (json is String) {
      final decoded = tryDecode(json);
      if (decoded != null) {
        return const JsonEncoder.withIndent('  ').convert(decoded);
      }
      return json;
    }
    return const JsonEncoder.withIndent('  ').convert(json);
  }

  /// Глубокое слияние двух JSON объектов
  static Map<String, dynamic> deepMerge(
    Map<String, dynamic> base,
    Map<String, dynamic> override,
  ) {
    final result = Map<String, dynamic>.from(base);

    for (final key in override.keys) {
      if (result.containsKey(key) && 
          result[key] is Map<String, dynamic> && 
          override[key] is Map<String, dynamic>) {
        result[key] = deepMerge(
          result[key] as Map<String, dynamic>,
          override[key] as Map<String, dynamic>,
        );
      } else {
        result[key] = override[key];
      }
    }

    return result;
  }

  /// Маскирует чувствительные данные в JSON для логирования
  static Map<String, dynamic> maskSensitiveData(Map<String, dynamic> json) {
    final sensitiveKeys = [
      'password', 'passwd', 'secret', 'key', 'privateKey',
      'uuid', 'id', 'token', 'auth', 'psk', 'certificate',
    ];

    final masked = Map<String, dynamic>.from(json);
    _maskRecursive(masked, sensitiveKeys);
    return masked;
  }

  static void _maskRecursive(Map<String, dynamic> map, List<String> sensitiveKeys) {
    for (final key in map.keys.toList()) {
      if (sensitiveKeys.any((sk) => key.toLowerCase().contains(sk.toLowerCase()))) {
        final value = map[key];
        if (value is String && value.isNotEmpty) {
          if (value.length <= 8) {
            map[key] = '***';
          } else {
            map[key] = '${value.substring(0, 4)}...${value.substring(value.length - 4)}';
          }
        }
      } else if (map[key] is Map<String, dynamic>) {
        _maskRecursive(map[key] as Map<String, dynamic>, sensitiveKeys);
      }
    }
  }
}