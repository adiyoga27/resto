class MenuItem {
  final String id;
  final String name;
  final String categoryId;
  final String categoryName;
  final double price;
  final String description;
  final String imageUrl;
  final bool available;
  final int orderCount;
  final DateTime createdAt;

  MenuItem({
    required this.id,
    required this.name,
    required this.categoryId,
    this.categoryName = '',
    required this.price,
    this.description = '',
    this.imageUrl = '',
    this.available = true,
    this.orderCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
      'available': available,
      'orderCount': orderCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      available: map['available'] ?? true,
      orderCount: map['orderCount'] ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  MenuItem copyWith({
    String? name,
    String? categoryId,
    String? categoryName,
    double? price,
    String? description,
    String? imageUrl,
    bool? available,
    int? orderCount,
  }) {
    return MenuItem(
      id: id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      price: price ?? this.price,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      available: available ?? this.available,
      orderCount: orderCount ?? this.orderCount,
      createdAt: createdAt,
    );
  }
}
