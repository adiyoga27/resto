enum TableStatus { available, occupied, reserved }

class TableModel {
  final String id;
  final String name;
  final int capacity;
  final TableStatus status;
  final String currentOrderId;
  final int floor;

  TableModel({
    required this.id,
    required this.name,
    this.capacity = 4,
    this.status = TableStatus.available,
    this.currentOrderId = '',
    this.floor = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'capacity': capacity,
      'status': status.name,
      'currentOrderId': currentOrderId,
      'floor': floor,
    };
  }

  factory TableModel.fromMap(Map<String, dynamic> map) {
    return TableModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      capacity: map['capacity'] ?? 4,
      status: TableStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TableStatus.available,
      ),
      currentOrderId: map['currentOrderId'] ?? '',
      floor: map['floor'] ?? 1,
    );
  }

  TableModel copyWith({
    String? name,
    int? capacity,
    TableStatus? status,
    String? currentOrderId,
    int? floor,
  }) {
    return TableModel(
      id: id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      floor: floor ?? this.floor,
    );
  }

  bool get isAvailable => status == TableStatus.available;
  bool get isOccupied => status == TableStatus.occupied;
  bool get isReserved => status == TableStatus.reserved;
}
