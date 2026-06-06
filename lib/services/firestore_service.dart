import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../models/menu_category.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/table.dart' as table_model;

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  String _restaurantId = '';

  void setRestaurantId(String id) {
    _restaurantId = id;
  }

  // ─── Menu Categories ───────────────────────────────────────────

  Stream<List<MenuCategory>> streamCategories() {
    if (_restaurantId.isEmpty) return Stream.value([]);
    return _firestore
        .collection('restaurants')
        .doc(_restaurantId)
        .collection('categories')
        .orderBy('order')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => MenuCategory.fromMap(d.data())).toList());
  }

  Future<void> addCategory(String name) async {
    final id = _uuid.v4();
    final category = MenuCategory(id: id, name: name);
    await _firestore
        .collection('restaurants')
        .doc(_restaurantId)
        .collection('categories')
        .doc(id)
        .set(category.toMap());
  }

  Future<void> updateCategory(MenuCategory category) async {
    await _firestore
        .collection('restaurants')
        .doc(_restaurantId)
        .collection('categories')
        .doc(category.id)
        .update(category.toMap());
  }

  Future<void> deleteCategory(String id) async {
    await _firestore
        .collection('restaurants')
        .doc(_restaurantId)
        .collection('categories')
        .doc(id)
        .delete();
  }

  // ─── Menu Items ────────────────────────────────────────────────

  Stream<List<MenuItem>> streamMenuItems({String? categoryId}) {
    if (_restaurantId.isEmpty) return Stream.value([]);
    Query<Map<String, dynamic>> query = _firestore
        .collection('restaurants')
        .doc(_restaurantId)
        .collection('menuItems');
    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }
    return query.orderBy('name').snapshots().map(
          (snap) => snap.docs.map((d) => MenuItem.fromMap(d.data())).toList(),
        );
  }

  Future<void> addMenuItem(MenuItem item) async {
    await _firestore
        .collection('restaurants')
        .doc(_restaurantId)
        .collection('menuItems')
        .doc(item.id)
        .set(item.toMap());
  }

  Future<void> updateMenuItem(MenuItem item) async {
    await _firestore
        .collection('restaurants')
        .doc(_restaurantId)
        .collection('menuItems')
        .doc(item.id)
        .update(item.toMap());
  }

  Future<void> deleteMenuItem(String id) async {
    await _firestore
        .collection('restaurants')
        .doc(_restaurantId)
        .collection('menuItems')
        .doc(id)
        .delete();
  }

  // ─── Orders ────────────────────────────────────────────────────

  Stream<List<OrderModel>> streamOrders({String? statusFilter}) {
    if (_restaurantId.isEmpty) return Stream.value([]);
    Query<Map<String, dynamic>> query = _firestore
        .collection('restaurants')
        .doc(_restaurantId)
        .collection('orders')
        .orderBy('createdAt', descending: true);
    if (statusFilter != null && statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }
    return query.snapshots().map(
          (snap) =>
              snap.docs.map((d) => OrderModel.fromMap(d.data())).toList(),
        );
  }

  Future<String> createOrder(OrderModel order) async {
    final id = _uuid.v4();
    await _firestore
        .collection('restaurants')
        .doc(_restaurantId)
        .collection('orders')
        .doc(id)
        .set(order.toMap()..['id'] = id);
    return id;
  }

  Future<void> updateOrder(OrderModel order) async {
    await _firestore
        .collection('restaurants')
        .doc(_restaurantId)
        .collection('orders')
        .doc(order.id)
        .update(order.toMap());
  }

  Future<void> deleteOrder(String id) async {
    await _firestore
        .collection('restaurants')
        .doc(_restaurantId)
        .collection('orders')
        .doc(id)
        .delete();
  }

  // ─── Tables ────────────────────────────────────────────────────

  Stream<List<table_model.TableModel>> streamTables() {
    if (_restaurantId.isEmpty) return Stream.value([]);
    return _firestore
        .collection('restaurants')
        .doc(_restaurantId)
        .collection('tables')
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => table_model.TableModel.fromMap(d.data()))
            .toList());
  }

  Future<void> addTable(table_model.TableModel table) async {
    await _firestore
        .collection('restaurants')
        .doc(_restaurantId)
        .collection('tables')
        .doc(table.id)
        .set(table.toMap());
  }

  Future<void> updateTable(table_model.TableModel table) async {
    await _firestore
        .collection('restaurants')
        .doc(_restaurantId)
        .collection('tables')
        .doc(table.id)
        .update(table.toMap());
  }

  Future<void> deleteTable(String id) async {
    await _firestore
        .collection('restaurants')
        .doc(_restaurantId)
        .collection('tables')
        .doc(id)
        .delete();
  }
}

