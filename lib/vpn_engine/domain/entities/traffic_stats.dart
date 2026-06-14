import 'package:equatable/equatable.dart';

/// Статистика трафика VPN-соединения
class TrafficStats extends Equatable {
  final int totalUpload;      // Всего отправлено (байты)
  final int totalDownload;    // Всего получено (байты)
  final int uploadSpeed;      // Текущая скорость отдачи (байт/с)
  final int downloadSpeed;    // Текущая скорость загрузки (байт/с)
  final DateTime? lastUpdate;
  final List<TrafficSnapshot> history; // История для графиков

  const TrafficStats({
    this.totalUpload = 0,
    this.totalDownload = 0,
    this.uploadSpeed = 0,
    this.downloadSpeed = 0,
    this.lastUpdate,
    this.history = const [],
  });

  factory TrafficStats.zero() => const TrafficStats();

  /// Общий трафик (upload + download)
  int get totalTraffic => totalUpload + totalDownload;

  /// Форматированный общий трафик
  String get formattedTotal {
    return _formatBytes(totalTraffic);
  }

  /// Форматированная скорость загрузки
  String get formattedDownloadSpeed {
    return '${_formatBytes(downloadSpeed)}/s';
  }

  /// Форматированная скорость отдачи
  String get formattedUploadSpeed {
    return '${_formatBytes(uploadSpeed)}/s';
  }

  /// Обновляет скорости на основе новых данных
  TrafficStats updateSpeeds(int newDownloadSpeed, int newUploadSpeed) {
    final now = DateTime.now();
    final snapshot = TrafficSnapshot(
      timestamp: now,
      downloadSpeed: newDownloadSpeed,
      uploadSpeed: newUploadSpeed,
    );

    // Храним последние 300 точек (5 минут при обновлении раз в секунду)
    final newHistory = [...history, snapshot];
    if (newHistory.length > 300) {
      newHistory.removeAt(0);
    }

    return copyWith(
      uploadSpeed: newUploadSpeed,
      downloadSpeed: newDownloadSpeed,
      lastUpdate: now,
      history: newHistory,
    );
  }

  TrafficStats copyWith({
    int? totalUpload,
    int? totalDownload,
    int? uploadSpeed,
    int? downloadSpeed,
    DateTime? lastUpdate,
    List<TrafficSnapshot>? history,
  }) {
    return TrafficStats(
      totalUpload: totalUpload ?? this.totalUpload,
      totalDownload: totalDownload ?? this.totalDownload,
      uploadSpeed: uploadSpeed ?? this.uploadSpeed,
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      history: history ?? this.history,
    );
  }

  /// Форматирует байты в читаемый вид
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  List<Object?> get props => [
        totalUpload,
        totalDownload,
        uploadSpeed,
        downloadSpeed,
        lastUpdate,
      ];
}

/// Снимок скорости в конкретный момент времени
class TrafficSnapshot extends Equatable {
  final DateTime timestamp;
  final int downloadSpeed;
  final int uploadSpeed;

  const TrafficSnapshot({
    required this.timestamp,
    required this.downloadSpeed,
    required this.uploadSpeed,
  });

  @override
  List<Object?> get props => [timestamp, downloadSpeed, uploadSpeed];
}