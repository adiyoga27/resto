enum OrderStatus { pending, preparing, ready, served, completed, cancelled }

enum OrderType { dineIn, takeAway, delivery }

enum PaymentStatus { unpaid, paid }

enum PaymentMethod { cash, card, qris }

class OrderItem {
  final String menuItemId;
  final String name;
  final double price;
  int quantity;
  final String notes;

  OrderItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.notes = '',
  });

  double get subtotal => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'notes': notes,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      menuItemId: map['menuItemId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
      notes: map['notes'] ?? '',
    );
  }
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String tableId;
  final String tableName;
  final String customerName;
  final OrderType orderType;
  final List<OrderItem> items;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final PaymentMethod paymentMethod;
  final double taxRate;
  final double serviceCharge;
  final double discount;
  final double amountPaid;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderModel({
    required this.id,
    required this.orderNumber,
    this.tableId = '',
    this.tableName = '',
    this.customerName = '',
    this.orderType = OrderType.dineIn,
    this.items = const [],
    this.status = OrderStatus.pending,
    this.paymentStatus = PaymentStatus.unpaid,
    this.paymentMethod = PaymentMethod.cash,
    this.taxRate = 0.11,
    this.serviceCharge = 0.02,
    this.discount = 0,
    this.amountPaid = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double _round(double value) => (value * 100).roundToDouble() / 100;

  double get subtotal =>
      _round(items.fold(0.0, (sum, item) => sum + item.subtotal));

  double get taxAmount => _round(subtotal * taxRate);

  double get serviceAmount => _round(subtotal * serviceCharge);

  double get total => _round(subtotal + taxAmount + serviceAmount - discount);

  double get change => amountPaid - total;

  int get totalItems =>
      items.fold(0, (sum, item) => sum + item.quantity);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'tableId': tableId,
      'tableName': tableName,
      'customerName': customerName,
      'orderType': orderType.name,
      'items': items.map((e) => e.toMap()).toList(),
      'status': status.name,
      'paymentStatus': paymentStatus.name,
      'paymentMethod': paymentMethod.name,
      'taxRate': taxRate,
      'serviceCharge': serviceCharge,
      'discount': discount,
      'amountPaid': amountPaid,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] ?? '',
      orderNumber: map['orderNumber'] ?? '',
      tableId: map['tableId'] ?? '',
      tableName: map['tableName'] ?? '',
      customerName: map['customerName'] ?? '',
      orderType: OrderType.values.firstWhere(
        (e) => e.name == map['orderType'],
        orElse: () => OrderType.dineIn,
      ),
      items: (map['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromMap(e))
              .toList() ??
          [],
      status: OrderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == map['paymentStatus'],
        orElse: () => PaymentStatus.unpaid,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == map['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      taxRate: (map['taxRate'] ?? 0.11).toDouble(),
      serviceCharge: (map['serviceCharge'] ?? 0.02).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(),
      amountPaid: (map['amountPaid'] ?? 0).toDouble(),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  OrderModel copyWith({
    String? tableId,
    String? tableName,
    String? customerName,
    OrderType? orderType,
    List<OrderItem>? items,
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    PaymentMethod? paymentMethod,
    double? taxRate,
    double? serviceCharge,
    double? discount,
    double? amountPaid,
  }) {
    return OrderModel(
      id: id,
      orderNumber: orderNumber,
      tableId: tableId ?? this.tableId,
      tableName: tableName ?? this.tableName,
      customerName: customerName ?? this.customerName,
      orderType: orderType ?? this.orderType,
      items: items ?? this.items,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      taxRate: taxRate ?? this.taxRate,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      discount: discount ?? this.discount,
      amountPaid: amountPaid ?? this.amountPaid,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
