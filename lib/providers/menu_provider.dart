import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/menu_category.dart';
import '../models/menu_item.dart';
import '../services/firestore_service.dart';

class MenuProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final Uuid _uuid = const Uuid();

  String _userId = '';
  List<MenuCategory> _categories = [];
  List<MenuItem> _items = [];
  String _selectedCategoryId = '';
  bool _isLoading = false;

  List<MenuCategory> get categories => _categories;
  List<MenuItem> get items => _items;
  String get selectedCategoryId => _selectedCategoryId;
  bool get isLoading => _isLoading;

  List<MenuItem> get filteredItems {
    if (_selectedCategoryId.isEmpty || _selectedCategoryId == 'all') {
      return _items;
    }
    return _items.where((i) => i.categoryId == _selectedCategoryId).toList();
  }

  MenuCategory? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  void setUserId(String uid) {
    _userId = uid;
    _firestoreService.setUserId(uid);
  }

  void init() {
    _firestoreService.streamCategories().listen((cats) {
      _categories = cats;
      notifyListeners();
    });
    _firestoreService.streamMenuItems().listen((items) {
      _items = items;
      notifyListeners();
    });
  }

  void setSelectedCategory(String id) {
    _selectedCategoryId = id;
    notifyListeners();
  }

  Future<void> addCategory(String name) async {
    await _firestoreService.addCategory(name);
  }

  Future<void> updateCategory(MenuCategory category) async {
    await _firestoreService.updateCategory(category);
  }

  Future<void> deleteCategory(String id) async {
    await _firestoreService.deleteCategory(id);
  }

  Future<void> addItem(String name, String categoryId, String categoryName,
      double price, String description, {String imageUrl = ''}) async {
    final item = MenuItem(
      id: _uuid.v4(),
      name: name,
      categoryId: categoryId,
      categoryName: categoryName,
      price: price,
      description: description,
      imageUrl: imageUrl,
    );
    await _firestoreService.addMenuItem(item);
  }

  Future<void> updateItem(MenuItem item) async {
    await _firestoreService.updateMenuItem(item);
  }

  Future<void> deleteItem(String id) async {
    await _firestoreService.deleteMenuItem(id);
  }
}
