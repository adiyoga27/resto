enum UserRole { superadmin, cashier, kitchen }

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String restaurantName;
  final String role;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.restaurantName = '',
    this.role = 'superadmin',
  });

  bool get isSuperAdmin => role == 'superadmin';
  bool get isCashier => role == 'cashier';
  bool get isKitchen => role == 'kitchen';

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'restaurantName': restaurantName,
      'role': role,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      restaurantName: map['restaurantName'] ?? '',
      role: map['role'] ?? 'superadmin',
    );
  }
}
