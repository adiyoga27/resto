import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/restaurant_settings.dart';
import '../models/user.dart';

class SettingsService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  RestaurantSettings _settings = RestaurantSettings();
  List<UserModel> _users = [];
  String _restaurantId = '';

  RestaurantSettings get settings => _settings;
  List<UserModel> get users => _users;
  String get restaurantId => _restaurantId;

  void init(String restaurantId) {
    _restaurantId = restaurantId;
    _listenSettings();
    _listenUsers();
  }

  void _listenSettings() {
    _firestore
        .collection('restaurants')
        .doc(_restaurantId)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        _settings = RestaurantSettings.fromMap(doc.data()!);
      } else {
        _firestore
            .collection('restaurants')
            .doc(_restaurantId)
            .set(RestaurantSettings().toMap());
      }
      notifyListeners();
    });
  }

  void _listenUsers() {
    _firestore
        .collection('users')
        .where('restaurantId', isEqualTo: _restaurantId)
        .snapshots()
        .listen((snap) {
      _users = snap.docs.map((d) => UserModel.fromMap(d.data())).toList();
      notifyListeners();
    });
  }

  Future<void> updateSettings(RestaurantSettings settings) async {
    await _firestore
        .collection('restaurants')
        .doc(_restaurantId)
        .update(settings.toMap());
  }

  Future<String?> createUser(String name, String email, String password,
      String phone, String role) async {
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
        restaurantName: _settings.name,
        role: role,
        restaurantId: _restaurantId,
      );

      await _firestore
          .collection('users')
          .doc(cred.user!.uid)
          .set(user.toMap());

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Gagal membuat user';
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }

  Future<void> updateUserRole(String uid, String role) async {
    await _firestore.collection('users').doc(uid).update({'role': role});
  }

  Future<RestaurantSettings> fetchSettings(String restaurantId) async {
    final doc = await _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .get();
    if (doc.exists) {
      return RestaurantSettings.fromMap(doc.data()!);
    }
    return RestaurantSettings();
  }

  Future<void> saveSettings(
      String restaurantId, RestaurantSettings settings) async {
    await _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .update(settings.toMap());
  }
}
