import 'package:flutter/material.dart';

class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('id'),
    Locale('en'),
  ];

  String get appName => _get('Resto POS', 'Resto POS');
  String get login => _get('Masuk', 'Login');
  String get register => _get('Daftar', 'Register');
  String get email => _get('Email', 'Email');
  String get password => _get('Kata Sandi', 'Password');
  String get confirmPassword => _get('Konfirmasi Kata Sandi', 'Confirm Password');
  String get name => _get('Nama', 'Name');
  String get phone => _get('Telepon', 'Phone');
  String get restaurantName => _get('Nama Restoran', 'Restaurant Name');
  String get forgotPassword => _get('Lupa Kata Sandi?', 'Forgot Password?');
  String get dontHaveAccount => _get('Belum punya akun? ', "Don't have an account? ");
  String get haveAccount => _get('Sudah punya akun? ', 'Already have an account? ');
  String get dashboard => _get('Beranda', 'Dashboard');
  String get menu => _get('Menu', 'Menu');
  String get orders => _get('Pesanan', 'Orders');
  String get tables => _get('Meja', 'Tables');
  String get reports => _get('Laporan', 'Reports');
  String get settings => _get('Pengaturan', 'Settings');
  String get logout => _get('Keluar', 'Logout');
  String get search => _get('Cari', 'Search');
  String get save => _get('Simpan', 'Save');
  String get cancel => _get('Batal', 'Cancel');
  String get delete => _get('Hapus', 'Delete');
  String get edit => _get('Ubah', 'Edit');
  String get add => _get('Tambah', 'Add');
  String get totalRevenue => _get('Total Pendapatan', 'Total Revenue');
  String get totalOrders => _get('Total Pesanan', 'Total Orders');
  String get totalTables => _get('Total Meja', 'Total Tables');
  String get activeOrders => _get('Pesanan Aktif', 'Active Orders');
  String get todaySales => _get('Penjualan Hari Ini', 'Today Sales');
  String get categories => _get('Kategori', 'Categories');
  String get addCategory => _get('Tambah Kategori', 'Add Category');
  String get editCategory => _get('Ubah Kategori', 'Edit Category');
  String get categoryName => _get('Nama Kategori', 'Category Name');
  String get addItem => _get('Tambah Item', 'Add Item');
  String get editItem => _get('Ubah Item', 'Edit Item');
  String get itemName => _get('Nama Item', 'Item Name');
  String get itemPrice => _get('Harga Item', 'Item Price');
  String get itemCategory => _get('Kategori Item', 'Item Category');
  String get description => _get('Deskripsi', 'Description');
  String get image => _get('Gambar', 'Image');
  String get newOrder => _get('Pesanan Baru', 'New Order');
  String get orderNumber => _get('No. Pesanan', 'Order No.');
  String get tableNumber => _get('No. Meja', 'Table No.');
  String get customerName => _get('Nama Pelanggan', 'Customer Name');
  String get orderType => _get('Tipe Pesanan', 'Order Type');
  String get dineIn => _get('Makan di Tempat', 'Dine In');
  String get takeAway => _get('Bawa Pulang', 'Take Away');
  String get delivery => _get('Antar', 'Delivery');
  String get pending => _get('Menunggu', 'Pending');
  String get preparing => _get('Disiapkan', 'Preparing');
  String get ready => _get('Siap', 'Ready');
  String get served => _get('Disajikan', 'Served');
  String get completed => _get('Selesai', 'Completed');
  String get cancelled => _get('Dibatalkan', 'Cancelled');
  String get paid => _get('Lunas', 'Paid');
  String get unpaid => _get('Belum Lunas', 'Unpaid');
  String get addToCart => _get('Tambah ke Keranjang', 'Add to Cart');
  String get checkout => _get('Bayar', 'Checkout');
  String get printReceipt => _get('Cetak Struk', 'Print Receipt');
  String get subtotal => _get('Subtotal', 'Subtotal');
  String get tax => _get('Pajak', 'Tax');
  String get total => _get('Total', 'Total');
  String get quantity => _get('Jumlah', 'Quantity');
  String get noData => _get('Tidak ada data', 'No data available');
  String get confirmDelete => _get('Yakin ingin menghapus?', 'Are you sure you want to delete?');
  String get language => _get('Bahasa', 'Language');
  String get indonesian => _get('Bahasa Indonesia', 'Bahasa Indonesia');
  String get english => _get('English', 'English');
  String get darkMode => _get('Mode Gelap', 'Dark Mode');
  String get about => _get('Tentang', 'About');
  String get addTable => _get('Tambah Meja', 'Add Table');
  String get tableName => _get('Nama Meja', 'Table Name');
  String get capacity => _get('Kapasitas', 'Capacity');
  String get available => _get('Tersedia', 'Available');
  String get occupied => _get('Terisi', 'Occupied');
  String get reserved => _get('Dipesan', 'Reserved');
  String get dailyReport => _get('Laporan Harian', 'Daily Report');
  String get weeklyReport => _get('Laporan Mingguan', 'Weekly Report');
  String get monthlyReport => _get('Laporan Bulanan', 'Monthly Report');
  String get exportReport => _get('Ekspor Laporan', 'Export Report');
  String get startDate => _get('Tanggal Mulai', 'Start Date');
  String get endDate => _get('Tanggal Akhir', 'End Date');
  String get filter => _get('Filter', 'Filter');
  String get clearFilter => _get('Hapus Filter', 'Clear Filter');
  String get loading => _get('Memuat...', 'Loading...');
  String get error => _get('Terjadi kesalahan', 'An error occurred');
  String get success => _get('Berhasil', 'Success');
  String get welcome => _get('Selamat Datang', 'Welcome');
  String get welcomeBack => _get('Selamat Datang Kembali', 'Welcome Back');
  String get appSubtitle => _get('Sistem Kasir Restoran', 'Restaurant POS System');
  String get appDescription => _get('Kelola restoran Anda dengan mudah dan efisien', 'Manage your restaurant easily and efficiently');
  String get totalItems => _get('Total Item', 'Total Items');
  String get recentOrders => _get('Pesanan Terbaru', 'Recent Orders');
  String get popularItems => _get('Menu Populer', 'Popular Items');
  String get orderDetails => _get('Detail Pesanan', 'Order Details');
  String get paymentMethod => _get('Metode Pembayaran', 'Payment Method');
  String get cash => _get('Tunai', 'Cash');
  String get card => _get('Kartu', 'Card');
  String get qris => _get('QRIS', 'QRIS');
  String get change => _get('Kembalian', 'Change');
  String get amountPaid => _get('Jumlah Dibayar', 'Amount Paid');
  String get amountDue => _get('Jumlah Tagihan', 'Amount Due');

  String _get(String id, String en) {
    if (languageCode == 'id') return id;
    return en;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.contains(locale);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale.languageCode);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
