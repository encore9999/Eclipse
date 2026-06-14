import 'package:flutter/material.dart';

/// Тёмно-фиолетовая цветовая палитра Eclipse
/// Вдохновлена Hiddify, но с уникальным характером
class AppColors {
  AppColors._();

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Primary — глубокий фиолетовый
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const MaterialColor primary = MaterialColor(0xFF7C3AED, {
    50: Color(0xFFF5F3FF),
    100: Color(0xFFEDE9FE),
    200: Color(0xFFDDD6FE),
    300: Color(0xFFC4B5FD),
    400: Color(0xFFA78BFA),
    500: Color(0xFF8B5CF6),
    600: Color(0xFF7C3AED),
    700: Color(0xFF6D28D9),
    800: Color(0xFF5B21B6),
    900: Color(0xFF4C1D95),
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Secondary — акцентный лавандовый
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const MaterialColor secondary = MaterialColor(0xFFA78BFA, {
    50: Color(0xFFF8F7FF),
    100: Color(0xFFF0EEFF),
    200: Color(0xFFE0DCFF),
    300: Color(0xFFC4B5FD),
    400: Color(0xFFA78BFA),
    500: Color(0xFF8B5CF6),
    600: Color(0xFF7C3AED),
    700: Color(0xFF6D28D9),
    800: Color(0xFF5B21B6),
    900: Color(0xFF4C1D95),
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Status Colors — статусы подключения
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const Color connected = Color(0xFF22C55E);      // Зелёный
  static const Color connecting = Color(0xFFFBBF24);     // Золотой
  static const Color disconnected = Color(0xFF6B7280);   // Серый
  static const Color error = Color(0xFFEF4444);          // Красный
  static const Color warning = Color(0xFFF97316);        // Оранжевый

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Dark Theme — глубокая фиолетовая тьма
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const Color darkBackground = Color(0xFF0C0A1E);     // Почти чёрный с фиолетовым оттенком
  static const Color darkSurface = Color(0xFF13102B);        // Карточки
  static const Color darkSurfaceVariant = Color(0xFF1C1840); // Вариант поверхности
  static const Color darkCard = Color(0xFF1A1738);           // Карточки
  static const Color darkNavBar = Color(0xFF0F0D24);         // Нижняя навигация
  static const Color darkAppBar = Color(0xFF0F0D24);         // Верхняя панель
  static const Color darkDivider = Color(0xFF2D2860);        // Разделители
  static const Color darkInput = Color(0xFF1C1840);          // Поля ввода

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Light Theme — воздушный лавандовый
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const Color lightBackground = Color(0xFFF8F7FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF5F3FF);
  static const Color lightCard = Color(0xFFFFFFFF);

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Protocol Colors — цвета протоколов
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const Color vlessColor = Color(0xFF8B5CF6);
  static const Color vmessColor = Color(0xFF6366F1);
  static const Color trojanColor = Color(0xFFEC4899);
  static const Color shadowsocksColor = Color(0xFF10B981);
  static const Color hysteria2Color = Color(0xFFF43F5E);
  static const Color tuicColor = Color(0xFF06B6D4);
  static const Color wireguardColor = Color(0xFFF97316);

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Градиенты
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const List<Color> connectedGradient = [
    Color(0xFF7C3AED),
    Color(0xFFA78BFA),
  ];

  static const List<Color> disconnectedGradient = [
    Color(0xFF374151),
    Color(0xFF4B5563),
  ];

  static const List<Color> backgroundGradient = [
    Color(0xFF0C0A1E),
    Color(0xFF1C1840),
  ];

  static const List<Color> cardGradient = [
    Color(0xFF1A1738),
    Color(0xFF1C1840),
  ];

  static Color getProtocolColor(String protocol) {
    switch (protocol.toLowerCase()) {
      case 'vless': return vlessColor;
      case 'vmess': return vmessColor;
      case 'trojan': return trojanColor;
      case 'shadowsocks': return shadowsocksColor;
      case 'hysteria2': return hysteria2Color;
      case 'tuic': return tuicColor;
      case 'wireguard': return wireguardColor;
      default: return disconnected;
    }
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'connected': return connected;
      case 'connecting': return connecting;
      case 'reconnecting': return warning;
      case 'error': return error;
      default: return disconnected;
    }
  }
}