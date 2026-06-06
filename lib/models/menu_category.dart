class MenuCategory {
  final String id;
  final String name;
  final int order;
  final DateTime createdAt;

  MenuCategory({
    required this.id,
    required this.name,
    this.order = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'order': order,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MenuCategory.fromMap(Map<String, dynamic> map) {
    return MenuCategory(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      order: map['order'] ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  MenuCategory copyWith({String? name, int? order}) {
    return MenuCategory(
      id: id,
      name: name ?? this.name,
      order: order ?? this.order,
      createdAt: createdAt,
    );
  }
}
