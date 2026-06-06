import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appName.
  ///
  /// In id, this message translates to:
  /// **'Resto POS'**
  String get appName;

  /// No description provided for @login.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get login;

  /// No description provided for @register.
  ///
  /// In id, this message translates to:
  /// **'Daftar'**
  String get register;

  /// No description provided for @email.
  ///
  /// In id, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In id, this message translates to:
  /// **'Kata Sandi'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi Kata Sandi'**
  String get confirmPassword;

  /// No description provided for @name.
  ///
  /// In id, this message translates to:
  /// **'Nama'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In id, this message translates to:
  /// **'Telepon'**
  String get phone;

  /// No description provided for @restaurantName.
  ///
  /// In id, this message translates to:
  /// **'Nama Restoran'**
  String get restaurantName;

  /// No description provided for @forgotPassword.
  ///
  /// In id, this message translates to:
  /// **'Lupa Kata Sandi?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In id, this message translates to:
  /// **'Belum punya akun? '**
  String get dontHaveAccount;

  /// No description provided for @haveAccount.
  ///
  /// In id, this message translates to:
  /// **'Sudah punya akun? '**
  String get haveAccount;

  /// No description provided for @dashboard.
  ///
  /// In id, this message translates to:
  /// **'Beranda'**
  String get dashboard;

  /// No description provided for @menu.
  ///
  /// In id, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @orders.
  ///
  /// In id, this message translates to:
  /// **'Pesanan'**
  String get orders;

  /// No description provided for @tables.
  ///
  /// In id, this message translates to:
  /// **'Meja'**
  String get tables;

  /// No description provided for @reports.
  ///
  /// In id, this message translates to:
  /// **'Laporan'**
  String get reports;

  /// No description provided for @settings.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get logout;

  /// No description provided for @search.
  ///
  /// In id, this message translates to:
  /// **'Cari'**
  String get search;

  /// No description provided for @save.
  ///
  /// In id, this message translates to:
  /// **'Simpan'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In id, this message translates to:
  /// **'Ubah'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In id, this message translates to:
  /// **'Tambah'**
  String get add;

  /// No description provided for @totalRevenue.
  ///
  /// In id, this message translates to:
  /// **'Total Pendapatan'**
  String get totalRevenue;

  /// No description provided for @totalOrders.
  ///
  /// In id, this message translates to:
  /// **'Total Pesanan'**
  String get totalOrders;

  /// No description provided for @totalTables.
  ///
  /// In id, this message translates to:
  /// **'Total Meja'**
  String get totalTables;

  /// No description provided for @activeOrders.
  ///
  /// In id, this message translates to:
  /// **'Pesanan Aktif'**
  String get activeOrders;

  /// No description provided for @todaySales.
  ///
  /// In id, this message translates to:
  /// **'Penjualan Hari Ini'**
  String get todaySales;

  /// No description provided for @categories.
  ///
  /// In id, this message translates to:
  /// **'Kategori'**
  String get categories;

  /// No description provided for @addCategory.
  ///
  /// In id, this message translates to:
  /// **'Tambah Kategori'**
  String get addCategory;

  /// No description provided for @editCategory.
  ///
  /// In id, this message translates to:
  /// **'Ubah Kategori'**
  String get editCategory;

  /// No description provided for @categoryName.
  ///
  /// In id, this message translates to:
  /// **'Nama Kategori'**
  String get categoryName;

  /// No description provided for @addItem.
  ///
  /// In id, this message translates to:
  /// **'Tambah Item'**
  String get addItem;

  /// No description provided for @editItem.
  ///
  /// In id, this message translates to:
  /// **'Ubah Item'**
  String get editItem;

  /// No description provided for @itemName.
  ///
  /// In id, this message translates to:
  /// **'Nama Item'**
  String get itemName;

  /// No description provided for @itemPrice.
  ///
  /// In id, this message translates to:
  /// **'Harga Item'**
  String get itemPrice;

  /// No description provided for @itemCategory.
  ///
  /// In id, this message translates to:
  /// **'Kategori Item'**
  String get itemCategory;

  /// No description provided for @description.
  ///
  /// In id, this message translates to:
  /// **'Deskripsi'**
  String get description;

  /// No description provided for @image.
  ///
  /// In id, this message translates to:
  /// **'Gambar'**
  String get image;

  /// No description provided for @newOrder.
  ///
  /// In id, this message translates to:
  /// **'Pesanan Baru'**
  String get newOrder;

  /// No description provided for @orderNumber.
  ///
  /// In id, this message translates to:
  /// **'No. Pesanan'**
  String get orderNumber;

  /// No description provided for @tableNumber.
  ///
  /// In id, this message translates to:
  /// **'No. Meja'**
  String get tableNumber;

  /// No description provided for @customerName.
  ///
  /// In id, this message translates to:
  /// **'Nama Pelanggan'**
  String get customerName;

  /// No description provided for @orderType.
  ///
  /// In id, this message translates to:
  /// **'Tipe Pesanan'**
  String get orderType;

  /// No description provided for @dineIn.
  ///
  /// In id, this message translates to:
  /// **'Makan di Tempat'**
  String get dineIn;

  /// No description provided for @takeAway.
  ///
  /// In id, this message translates to:
  /// **'Bawa Pulang'**
  String get takeAway;

  /// No description provided for @delivery.
  ///
  /// In id, this message translates to:
  /// **'Antar'**
  String get delivery;

  /// No description provided for @pending.
  ///
  /// In id, this message translates to:
  /// **'Menunggu'**
  String get pending;

  /// No description provided for @preparing.
  ///
  /// In id, this message translates to:
  /// **'Disiapkan'**
  String get preparing;

  /// No description provided for @ready.
  ///
  /// In id, this message translates to:
  /// **'Siap'**
  String get ready;

  /// No description provided for @served.
  ///
  /// In id, this message translates to:
  /// **'Disajikan'**
  String get served;

  /// No description provided for @completed.
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get completed;

  /// No description provided for @cancelled.
  ///
  /// In id, this message translates to:
  /// **'Dibatalkan'**
  String get cancelled;

  /// No description provided for @paid.
  ///
  /// In id, this message translates to:
  /// **'Lunas'**
  String get paid;

  /// No description provided for @unpaid.
  ///
  /// In id, this message translates to:
  /// **'Belum Lunas'**
  String get unpaid;

  /// No description provided for @addToCart.
  ///
  /// In id, this message translates to:
  /// **'Tambah ke Keranjang'**
  String get addToCart;

  /// No description provided for @checkout.
  ///
  /// In id, this message translates to:
  /// **'Bayar'**
  String get checkout;

  /// No description provided for @printReceipt.
  ///
  /// In id, this message translates to:
  /// **'Cetak Struk'**
  String get printReceipt;

  /// No description provided for @subtotal.
  ///
  /// In id, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @tax.
  ///
  /// In id, this message translates to:
  /// **'Pajak'**
  String get tax;

  /// No description provided for @total.
  ///
  /// In id, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @quantity.
  ///
  /// In id, this message translates to:
  /// **'Jumlah'**
  String get quantity;

  /// No description provided for @noData.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada data'**
  String get noData;

  /// No description provided for @confirmDelete.
  ///
  /// In id, this message translates to:
  /// **'Yakin ingin menghapus?'**
  String get confirmDelete;

  /// No description provided for @language.
  ///
  /// In id, this message translates to:
  /// **'Bahasa'**
  String get language;

  /// No description provided for @indonesian.
  ///
  /// In id, this message translates to:
  /// **'Bahasa Indonesia'**
  String get indonesian;

  /// No description provided for @english.
  ///
  /// In id, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @darkMode.
  ///
  /// In id, this message translates to:
  /// **'Mode Gelap'**
  String get darkMode;

  /// No description provided for @about.
  ///
  /// In id, this message translates to:
  /// **'Tentang'**
  String get about;

  /// No description provided for @addTable.
  ///
  /// In id, this message translates to:
  /// **'Tambah Meja'**
  String get addTable;

  /// No description provided for @tableName.
  ///
  /// In id, this message translates to:
  /// **'Nama Meja'**
  String get tableName;

  /// No description provided for @capacity.
  ///
  /// In id, this message translates to:
  /// **'Kapasitas'**
  String get capacity;

  /// No description provided for @available.
  ///
  /// In id, this message translates to:
  /// **'Tersedia'**
  String get available;

  /// No description provided for @occupied.
  ///
  /// In id, this message translates to:
  /// **'Terisi'**
  String get occupied;

  /// No description provided for @reserved.
  ///
  /// In id, this message translates to:
  /// **'Dipesan'**
  String get reserved;

  /// No description provided for @dailyReport.
  ///
  /// In id, this message translates to:
  /// **'Laporan Harian'**
  String get dailyReport;

  /// No description provided for @weeklyReport.
  ///
  /// In id, this message translates to:
  /// **'Laporan Mingguan'**
  String get weeklyReport;

  /// No description provided for @monthlyReport.
  ///
  /// In id, this message translates to:
  /// **'Laporan Bulanan'**
  String get monthlyReport;

  /// No description provided for @exportReport.
  ///
  /// In id, this message translates to:
  /// **'Ekspor Laporan'**
  String get exportReport;

  /// No description provided for @startDate.
  ///
  /// In id, this message translates to:
  /// **'Tanggal Mulai'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In id, this message translates to:
  /// **'Tanggal Akhir'**
  String get endDate;

  /// No description provided for @filter.
  ///
  /// In id, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @clearFilter.
  ///
  /// In id, this message translates to:
  /// **'Hapus Filter'**
  String get clearFilter;

  /// No description provided for @loading.
  ///
  /// In id, this message translates to:
  /// **'Memuat...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In id, this message translates to:
  /// **'Terjadi kesalahan'**
  String get error;

  /// No description provided for @success.
  ///
  /// In id, this message translates to:
  /// **'Berhasil'**
  String get success;

  /// No description provided for @welcome.
  ///
  /// In id, this message translates to:
  /// **'Selamat Datang'**
  String get welcome;

  /// No description provided for @welcomeBack.
  ///
  /// In id, this message translates to:
  /// **'Selamat Datang Kembali'**
  String get welcomeBack;

  /// No description provided for @appSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Sistem Kasir Restoran'**
  String get appSubtitle;

  /// No description provided for @appDescription.
  ///
  /// In id, this message translates to:
  /// **'Kelola restoran Anda dengan mudah dan efisien'**
  String get appDescription;

  /// No description provided for @totalItems.
  ///
  /// In id, this message translates to:
  /// **'Total Item'**
  String get totalItems;

  /// No description provided for @recentOrders.
  ///
  /// In id, this message translates to:
  /// **'Pesanan Terbaru'**
  String get recentOrders;

  /// No description provided for @popularItems.
  ///
  /// In id, this message translates to:
  /// **'Menu Populer'**
  String get popularItems;

  /// No description provided for @orderDetails.
  ///
  /// In id, this message translates to:
  /// **'Detail Pesanan'**
  String get orderDetails;

  /// No description provided for @paymentMethod.
  ///
  /// In id, this message translates to:
  /// **'Metode Pembayaran'**
  String get paymentMethod;

  /// No description provided for @cash.
  ///
  /// In id, this message translates to:
  /// **'Tunai'**
  String get cash;

  /// No description provided for @card.
  ///
  /// In id, this message translates to:
  /// **'Kartu'**
  String get card;

  /// No description provided for @qris.
  ///
  /// In id, this message translates to:
  /// **'QRIS'**
  String get qris;

  /// No description provided for @change.
  ///
  /// In id, this message translates to:
  /// **'Kembalian'**
  String get change;

  /// No description provided for @amountPaid.
  ///
  /// In id, this message translates to:
  /// **'Jumlah Dibayar'**
  String get amountPaid;

  /// No description provided for @amountDue.
  ///
  /// In id, this message translates to:
  /// **'Jumlah Tagihan'**
  String get amountDue;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
