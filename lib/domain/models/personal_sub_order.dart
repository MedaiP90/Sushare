class PersonalSubOrder {
  final String id;
  final String sessionId;
  final String userId;
  final String? userName;
  final String? userFullName;
  final int? userAvatarIconCodePoint;
  final int? userAvatarColorValue;
  final List<SubOrderEntry> entries;
  final List<ChecklistEntry> checklist;
  final bool locked;
  final DateTime updatedAt;

  PersonalSubOrder({
    required this.id,
    required this.sessionId,
    required this.userId,
    this.userName,
    this.userFullName,
    this.userAvatarIconCodePoint,
    this.userAvatarColorValue,
    required this.entries,
    required this.checklist,
    required this.locked,
    required this.updatedAt,
  });

  factory PersonalSubOrder.fromJson(Map<String, dynamic> json) {
    return PersonalSubOrder(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String?,
      userFullName: json['userFullName'] as String?,
      userAvatarIconCodePoint: json['userAvatarIconCodePoint'] as int?,
      userAvatarColorValue: json['userAvatarColorValue'] as int?,
      entries: (json['entries'] as List<dynamic>)
          .map((e) => SubOrderEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      checklist: (json['checklist'] as List<dynamic>)
          .map((e) => ChecklistEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      locked: json['locked'] as bool,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'userId': userId,
      'userName': userName,
      'userFullName': userFullName,
      'userAvatarIconCodePoint': userAvatarIconCodePoint,
      'userAvatarColorValue': userAvatarColorValue,
      'entries': entries.map((e) => e.toJson()).toList(),
      'checklist': checklist.map((e) => e.toJson()).toList(),
      'locked': locked,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  PersonalSubOrder copyWith({
    String? id,
    String? sessionId,
    String? userId,
    String? userName,
    String? userFullName,
    int? userAvatarIconCodePoint,
    int? userAvatarColorValue,
    List<SubOrderEntry>? entries,
    List<ChecklistEntry>? checklist,
    bool? locked,
    DateTime? updatedAt,
  }) {
    return PersonalSubOrder(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userFullName: userFullName ?? this.userFullName,
      userAvatarIconCodePoint: userAvatarIconCodePoint ?? this.userAvatarIconCodePoint,
      userAvatarColorValue: userAvatarColorValue ?? this.userAvatarColorValue,
      entries: entries ?? this.entries,
      checklist: checklist ?? this.checklist,
      locked: locked ?? this.locked,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SubOrderEntry {
  final String menuItemId;
  final String name;
  final int quantity;

  SubOrderEntry({
    required this.menuItemId,
    required this.name,
    required this.quantity,
  });

  factory SubOrderEntry.fromJson(Map<String, dynamic> json) {
    return SubOrderEntry(
      menuItemId: json['menuItemId'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'quantity': quantity,
    };
  }

  SubOrderEntry copyWith({
    String? menuItemId,
    String? name,
    int? quantity,
  }) {
    return SubOrderEntry(
      menuItemId: menuItemId ?? this.menuItemId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
    );
  }
}

class ChecklistEntry {
  final String menuItemId;
  final String name;
  final int orderedQuantity;
  final int arrivedCount;

  ChecklistEntry({
    required this.menuItemId,
    required this.name,
    required this.orderedQuantity,
    required this.arrivedCount,
  });

  factory ChecklistEntry.fromJson(Map<String, dynamic> json) {
    return ChecklistEntry(
      menuItemId: json['menuItemId'] as String,
      name: json['name'] as String,
      orderedQuantity: json['orderedQuantity'] as int,
      arrivedCount: json['arrivedCount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'orderedQuantity': orderedQuantity,
      'arrivedCount': arrivedCount,
    };
  }

  ChecklistEntry copyWith({
    String? menuItemId,
    String? name,
    int? orderedQuantity,
    int? arrivedCount,
  }) {
    return ChecklistEntry(
      menuItemId: menuItemId ?? this.menuItemId,
      name: name ?? this.name,
      orderedQuantity: orderedQuantity ?? this.orderedQuantity,
      arrivedCount: arrivedCount ?? this.arrivedCount,
    );
  }
}
