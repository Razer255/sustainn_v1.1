/// Action Point model representing a recommendation or alert for the farmer.
/// Maps to `actionPoints/{id}` in Firestore.
/// Action points surface at every level: farmer, field, and crop.
class ActionPointModel {
  final String id;
  final ActionScope scope;
  final String refId; // userId, fieldId, or cropId depending on scope
  final String message;
  final ActionPriority priority;
  final DateTime? dueDate;
  final bool resolved;
  final String? category; // e.g. 'weather', 'fertilizer', 'irrigation', 'pest'
  final DateTime createdAt;

  const ActionPointModel({
    required this.id,
    required this.scope,
    required this.refId,
    required this.message,
    required this.priority,
    this.dueDate,
    this.resolved = false,
    this.category,
    required this.createdAt,
  });

  factory ActionPointModel.fromMap(Map<String, dynamic> map, String id) {
    return ActionPointModel(
      id: id,
      scope: ActionScope.fromString(map['scope'] ?? 'farmer'),
      refId: map['refId'] ?? '',
      message: map['message'] ?? '',
      priority: ActionPriority.fromString(map['priority'] ?? 'medium'),
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'])
          : null,
      resolved: map['resolved'] ?? false,
      category: map['category'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'scope': scope.value,
      'refId': refId,
      'message': message,
      'priority': priority.value,
      'dueDate': dueDate?.toIso8601String(),
      'resolved': resolved,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ActionPointModel copyWith({
    String? id,
    ActionScope? scope,
    String? refId,
    String? message,
    ActionPriority? priority,
    DateTime? dueDate,
    bool? resolved,
    String? category,
    DateTime? createdAt,
  }) {
    return ActionPointModel(
      id: id ?? this.id,
      scope: scope ?? this.scope,
      refId: refId ?? this.refId,
      message: message ?? this.message,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      resolved: resolved ?? this.resolved,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isOverdue {
    if (dueDate == null || resolved) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  @override
  String toString() =>
      'ActionPointModel(id: $id, scope: ${scope.value}, priority: ${priority.value})';
}

/// Scope at which an action point applies.
enum ActionScope {
  farmer('farmer'),
  field('field'),
  crop('crop');

  const ActionScope(this.value);
  final String value;

  static ActionScope fromString(String value) {
    return ActionScope.values.firstWhere(
      (s) => s.value == value,
      orElse: () => ActionScope.farmer,
    );
  }
}

/// Priority levels for action points.
enum ActionPriority {
  high('high', '🔴'),
  medium('medium', '🟡'),
  low('low', '🟢');

  const ActionPriority(this.value, this.emoji);
  final String value;
  final String emoji;

  static ActionPriority fromString(String value) {
    return ActionPriority.values.firstWhere(
      (p) => p.value == value,
      orElse: () => ActionPriority.medium,
    );
  }
}
