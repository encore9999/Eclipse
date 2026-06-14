import 'dart:convert';

/// Утилиты для работы с Base64 (специфичные для VPN-протоколов)
class Base64Utils {
  Base64Utils._();

  /// Стандартное декодирование Base64 строки
  static String decode(String encoded) {
    try {
      // Добавляем padding если нужно
      final normalized = _normalizeBase64(encoded);
      final bytes = base64.decode(normalized);
      return utf8.decode(bytes);
    } catch (e) {
      throw FormatException('Failed to decode Base64: $e');
    }
  }

  /// Стандартное кодирование строки в Base64
  static String encode(String plainText) {
    final bytes = utf8.encode(plainText);
    return base64.encode(bytes);
  }

  /// Декодирование Base64 URL-safe
  static String decodeUrlSafe(String encoded) {
    try {
      final normalized = encoded
          .replaceAll('-', '+')
          .replaceAll('_', '/');
      return decode(normalized);
    } catch (e) {
      throw FormatException('Failed to decode URL-safe Base64: $e');
    }
  }

  /// Кодирование в Base64 URL-safe
  static String encodeUrlSafe(String plainText) {
    final standard = encode(plainText);
    return standard
        .replaceAll('+', '-')
        .replaceAll('/', '_')
        .replaceAll('=', '');
  }

  /// Пытается декодировать строку в Base64 с авто-определением формата
  static String? tryDecode(String input) {
    try {
      return decode(input);
    } catch (e) {
      try {
        return decodeUrlSafe(input);
      } catch (e) {
        return null;
      }
    }
  }

  /// Проверяет, является ли строка валидной Base64
  static bool isValidBase64(String input) {
    try {
      decode(input);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Нормализует Base64 строку (добавляет padding)
  static String _normalizeBase64(String input) {
    // Убираем пробелы и переносы строк
    var normalized = input.replaceAll(RegExp(r'\s'), '');
    
    // Добавляем недостающий padding
    final remainder = normalized.length % 4;
    if (remainder > 0) {
      normalized += '=' * (4 - remainder);
    }
    
    return normalized;
  }

  /// Декодирует VMess конфигурацию (двойной Base64)
  static Map<String, dynamic> decodeVmessConfig(String vmessLink) {
    try {
      // vmess://base64encodedjson
      final uri = Uri.parse(vmessLink);
      final base64Config = uri.host; // Вся конфигурация в "host" части
      final jsonString = decode(base64Config);
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Failed to decode VMess config: $e');
    }
  }

  /// Кодирует JSON конфигурацию в VMess ссылку
  static String encodeVmessConfig(Map<String, dynamic> config) {
    final jsonString = json.encode(config);
    final base64Config = encode(jsonString);
    return 'vmess://$base64Config';
  }
}