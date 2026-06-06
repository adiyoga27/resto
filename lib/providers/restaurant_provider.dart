import 'package:flutter/material.dart';
import '../models/restaurant_settings.dart';
import '../services/settings_service.dart';

class RestaurantProvider extends ChangeNotifier {
  RestaurantSettings _settings = RestaurantSettings();
  final _svc = SettingsService();

  RestaurantSettings get settings => _settings;
  double get taxRate => _settings.taxRate;
  double get serviceCharge => _settings.serviceCharge;

  void load(String restaurantId) {
    if (restaurantId.isEmpty) return;
    _svc.fetchSettings(restaurantId).then((s) {
      _settings = s;
      notifyListeners();
    }).catchError((_) {});
  }

  Future<void> update(RestaurantSettings s, String restaurantId) async {
    await _svc.saveSettings(restaurantId, s);
    _settings = s;
    notifyListeners();
  }
}
