import 'package:equatable/equatable.dart';

/// Группа серверов (по подписке, стране, протоколу или пользовательская)
class ServerGroup extends Equatable {
  final String id;
  final String name;
  final GroupType type;
  final String? filterValue; // Значение для автоматической группировки
  final List<String> serverIds; // ID серверов в группе
  final bool isExpanded; // Развёрнута ли группа в UI
  final int sortOrder;

  const ServerGroup({
    required this.id,
    required this.name,
    required this.type,
    this.filterValue,
    this.serverIds = const [],
    this.isExpanded = true,
    this.sortOrder = 0,
  });

  ServerGroup copyWith({
    String? id,
    String? name,
    GroupType? type,
    String? filterValue,
    List<String>? serverIds,
    bool? isExpanded,
    int? sortOrder,
  }) {
    return ServerGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      filterValue: filterValue ?? this.filterValue,
      serverIds: serverIds ?? this.serverIds,
      isExpanded: isExpanded ?? this.isExpanded,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// Количество серверов в группе
  int get serverCount => serverIds.length;

  @override
  List<Object?> get props => [id, name, type, filterValue, serverIds, isExpanded, sortOrder];
}

/// Тип группировки
enum GroupType {
  subscription, // По подписке
  country,      // По стране
  protocol,     // По протоколу
  custom,       // Пользовательская группа
  favorites,    // Избранное
  recent,       // Недавние
}