import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/order.dart';
import '../services/firestore_service.dart';

class OrderProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  FirestoreService get firestoreService => _firestoreService;
  final Uuid _uuid = const Uuid();

  String _restaurantId = '';
  List<OrderModel> _orders = [];
  List<OrderItem> _cart = [];
  OrderType _currentOrderType = OrderType.dineIn;
  String _currentTableId = '';
  String _currentTableName = '';
  String _currentCustomerName = '';
  String _statusFilter = 'all';
  bool _isLoading = false;
  double _lastTaxRate = 0.1;
  double _lastDiscount = 0;

  List<OrderModel> get orders => _orders;
  List<OrderItem> get cart => _cart;
  OrderType get currentOrderType => _currentOrderType;
  String get currentTableId => _currentTableId;
  String get currentTableName => _currentTableName;
  String get currentCustomerName => _currentCustomerName;
  String get statusFilter => _statusFilter;
  bool get isLoading => _isLoading;
  double get currentTaxRate => _lastTaxRate;
  double get currentDiscount => _lastDiscount;

  double get cartSubtotal =>
      _cart.fold(0, (sum, item) => sum + item.subtotal);

  double get cartTax => cartSubtotal * 0.1;

  double get cartTotal => cartSubtotal + cartTax;

  int get cartItemCount =>
      _cart.fold(0, (sum, item) => sum + item.quantity);

  List<OrderModel> get activeOrders => _orders
      .where((o) =>
          o.status != OrderStatus.completed &&
          o.status != OrderStatus.cancelled)
      .toList();

  List<OrderModel> get completedOrders =>
      _orders.where((o) => o.status == OrderStatus.completed).toList();

  List<OrderModel> get filteredOrders {
    if (_statusFilter == 'all') return _orders;
    if (_statusFilter == 'active') return activeOrders;
    if (_statusFilter == 'completed') return completedOrders;
    try {
      final status = OrderStatus.values.firstWhere((e) => e.name == _statusFilter);
      return _orders.where((o) => o.status == status).toList();
    } catch (_) {
      return _orders;
    }
  }

  void setRestaurantId(String id) {
    _restaurantId = id;
    _firestoreService.setRestaurantId(id);
  }

  void init() {
    _firestoreService.streamOrders().listen((orders) {
      _orders = orders;
      notifyListeners();
    });
  }

  void setStatusFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  void setOrderType(OrderType type) {
    _currentOrderType = type;
    notifyListeners();
  }

  void setTable(String id, String name) {
    _currentTableId = id;
    _currentTableName = name;
    notifyListeners();
  }

  void setCustomerName(String name) {
    _currentCustomerName = name;
    notifyListeners();
  }

  void addToCart(OrderItem item) {
    final existing = _cart.indexWhere((e) => e.menuItemId == item.menuItemId);
    if (existing >= 0) {
      _cart[existing].quantity += 1;
    } else {
      _cart.add(item);
    }
    notifyListeners();
  }

  void removeFromCart(String menuItemId) {
    _cart.removeWhere((e) => e.menuItemId == menuItemId);
    notifyListeners();
  }

  void updateCartItemQuantity(String menuItemId, int quantity) {
    final index = _cart.indexWhere((e) => e.menuItemId == menuItemId);
    if (index >= 0) {
      if (quantity <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index].quantity = quantity;
      }
    }
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _currentTableId = '';
    _currentTableName = '';
    _currentCustomerName = '';
    _currentOrderType = OrderType.dineIn;
    notifyListeners();
  }

  Future<String> submitOrder({double? taxRate, double? discount, double? serviceCharge}) async {
    if (taxRate != null) _lastTaxRate = taxRate;
    if (discount != null) _lastDiscount = discount;

    final orderNumber =
        'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final order = OrderModel(
      id: '',
      orderNumber: orderNumber,
      tableId: _currentTableId,
      tableName: _currentTableName,
      customerName: _currentCustomerName,
      orderType: _currentOrderType,
      items: List.from(_cart),
      taxRate: _lastTaxRate,
      serviceCharge: serviceCharge ?? 0.02,
      discount: _lastDiscount,
    );
    final id = await _firestoreService.createOrder(order);
    clearCart();
    return id;
  }

  Future<void> updateOrder(OrderModel order) async {
    await _firestoreService.updateOrder(order);
  }

  Future<void> deleteOrder(String id) async {
    await _firestoreService.deleteOrder(id);
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      final order = _orders.firstWhere((o) => o.id == orderId);
      final updated = order.copyWith(
        status: status,
        paymentStatus: status == OrderStatus.completed
            ? PaymentStatus.paid
            : order.paymentStatus,
      );
      await _firestoreService.updateOrder(updated);
    } catch (_) {}
  }

  Future<void> processPayment(
    String orderId,
    PaymentMethod method,
    double amountPaid,
  ) async {
    try {
      final order = _orders.firstWhere((o) => o.id == orderId);
      final updated = order.copyWith(
        paymentStatus: PaymentStatus.paid,
        paymentMethod: method,
        amountPaid: amountPaid,
        status: OrderStatus.completed,
      );
      await _firestoreService.updateOrder(updated);
    } catch (_) {}
  }
}
