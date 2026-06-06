class RestaurantSettings {
  String name;
  String logo;
  String address;
  String phone;
  String email;
  double taxRate;
  double serviceCharge;
  String currency;

  RestaurantSettings({
    this.name = 'Restoran Saya',
    this.logo = '',
    this.address = '',
    this.phone = '',
    this.email = '',
    this.taxRate = 0.11,
    this.serviceCharge = 0.02,
    this.currency = 'IDR',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'logo': logo,
      'address': address,
      'phone': phone,
      'email': email,
      'taxRate': taxRate,
      'serviceCharge': serviceCharge,
      'currency': currency,
    };
  }

  factory RestaurantSettings.fromMap(Map<String, dynamic> map) {
    return RestaurantSettings(
      name: map['name'] ?? 'Restoran Saya',
      logo: map['logo'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      taxRate: (map['taxRate'] ?? 0.11).toDouble(),
      serviceCharge: (map['serviceCharge'] ?? 0.02).toDouble(),
      currency: map['currency'] ?? 'IDR',
    );
  }
}
