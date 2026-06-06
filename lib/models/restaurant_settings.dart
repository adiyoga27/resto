class RestaurantSettings {
  String name;
  String logo;
  String address;
  String phone;
  String email;
  double taxRate;
  double serviceCharge;
  String currency;
  List<Map<String, String>> printers;

  RestaurantSettings({
    this.name = 'Restoran Saya',
    this.logo = '',
    this.address = '',
    this.phone = '',
    this.email = '',
    this.taxRate = 0.11,
    this.serviceCharge = 0.02,
    this.currency = 'IDR',
    List<Map<String, String>>? printers,
  }) : printers = printers ?? [];

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
      'printers': printers,
    };
  }

  factory RestaurantSettings.fromMap(Map<String, dynamic> map) {
    final printersRaw = map['printers'];
    List<Map<String, String>> printers = [];
    if (printersRaw is List) {
      printers = printersRaw
          .map((e) => {
                'name': (e['name'] ?? '').toString(),
                'address': (e['address'] ?? '').toString(),
              })
          .toList();
    } else {
      final oldName = (map['printerName'] ?? '').toString();
      final oldAddr = (map['printerAddress'] ?? '').toString();
      if (oldName.isNotEmpty && oldAddr.isNotEmpty) {
        printers = [{'name': oldName, 'address': oldAddr}];
      }
    }

    return RestaurantSettings(
      name: map['name'] ?? 'Restoran Saya',
      logo: map['logo'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      taxRate: (map['taxRate'] ?? 0.11).toDouble(),
      serviceCharge: (map['serviceCharge'] ?? 0.02).toDouble(),
      currency: map['currency'] ?? 'IDR',
      printers: printers,
    );
  }
}
