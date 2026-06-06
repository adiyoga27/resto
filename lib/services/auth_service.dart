import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  String get userId => _currentUser?.uid ?? '';
  String get userName => _currentUser?.name ?? '';
  String get restaurantName => _currentUser?.restaurantName ?? '';

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _loadUserData();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(
    String name,
    String email,
    String password,
    String phone,
    String restaurantName,
    String role,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = UserModel(
        uid: cred.user!.uid,
        name: name,
        email: email,
        phone: phone,
        restaurantName: restaurantName,
        role: role,
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set(user.toMap());
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data()!);
      }
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> init() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _loadUserData();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }
}
