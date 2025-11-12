class ChecklistItem {
  final String id;
  final String? userId;
  final String itemName;
  final String? emoji;
  final bool isDefault;
  final String? context;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;

  ChecklistItem({
    required this.id,
    this.userId,
    required this.itemName,
    this.emoji,
    this.isDefault = false,
    this.context,
    this.displayOrder = 0,
    this.isActive = true,
    required this.createdAt,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'],
      userId: json['user_id'],
      itemName: json['item_name'],
      emoji: json['emoji'],
      isDefault: json['is_default'] ?? false,
      context: json['context'],
      displayOrder: json['display_order'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'item_name': itemName,
      'emoji': emoji,
      'is_default': isDefault,
      'context': context,
      'display_order': displayOrder,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
