import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseSetup {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> setupAll({required String restaurantName}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Harus login dulu');

    final uid = user.uid;

    await _firestore.collection('restaurants').doc(uid).set({
      'name': restaurantName,
      'address': '',
      'phone': '',
      'email': user.email ?? '',
      'taxRate': 0.11,
      'serviceCharge': 0.02,
      'currency': 'IDR',
    });

    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'name': user.displayName ?? 'Admin',
      'email': user.email ?? '',
      'phone': '',
      'restaurantName': restaurantName,
      'role': 'superadmin',
      'restaurantId': uid,
    }, SetOptions(merge: true));

    await _firestore.collection('users').doc(uid).update({
      'role': 'superadmin',
      'restaurantId': uid,
    });
  }

  Future<bool> needsSetup(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) return true;

    final data = userDoc.data()!;
    final role = data['role'] ?? '';
    final restaurantId = data['restaurantId'] ?? '';

    if (role != 'superadmin' || restaurantId.isEmpty) return true;

    final restoDoc =
        await _firestore.collection('restaurants').doc(restaurantId).get();
    return !restoDoc.exists;
  }
}
